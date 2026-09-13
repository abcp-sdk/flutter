import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart'
    show
        Clipboard,
        HardwareKeyboard,
        KeyUpEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:uuid/uuid.dart';

import '../i18n.dart';
import '../enums.dart';
import '../navigation.dart';
import '../messages.dart';
import '../api.dart' show isAuthError;
import '../auth_gate.dart';
import '../models.dart';
import '../prefs.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/media_attachment.dart';
import '../services/attachment_mime.dart';
import '../services/clipboard_media.dart';
import '../services/voice.dart';
import '../widgets/message_bubble.dart';

/// Conversation page shown when a session is open. Owns the chat header,
/// message list and composer. It reads the active session from [store]; a
/// single [MessagesController] is kept per chat-screen instance.
/// Canonical `provider_id/model_id` reference for a text model.
String modelRefOf(ModelInfo m) => '${m.providerId}/${m.id}';

/// Clipboard-media paste and file drag-and-drop are desktop + web features.
/// Android has no reachable path (a soft keyboard has no Ctrl+V key event, and
/// the vendored plugins carry no Android native side), so both are disabled
/// there to avoid dead code paths.
bool get _supportsMediaPasteDrop =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.android;

const Uuid _uuid = Uuid();

class ChatSessionPageWidget extends StatefulWidget {
  final AppStore store;
  const ChatSessionPageWidget({super.key, required this.store});

  @override
  State<ChatSessionPageWidget> createState() => _ChatSessionPageState();
}

class _ChatSessionPageState extends State<ChatSessionPageWidget> {
  AppStore get store => widget.store;

  /// Height shared by the text field (single line) and the hold-to-talk
  /// button, so toggling voice/keyboard mode never resizes the composer.
  static const double _composerFieldHeight = 42;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  MessagesController? _msg;
  Map<String, ProviderInfo> _providers = {};
  List<Preset> _presets = [];
  bool _initialScrollDone = false;
  // Whether new content should auto-scroll to the bottom. Only the user's OWN
  // scroll updates this (content growth must not): scrolling up pauses the
  // follow so streaming never fights the user reading history; returning to
  // the bottom re-arms it.
  bool _followBottom = true;
  // The session id the current _msg controller is bound to (set in _setup).
  String? _boundSid;

  /// True while a file drag hovers the conversation (shows the drop overlay).
  bool _dragging = false;

  /// Disposer for the web document `paste` listener (no-op on native).
  void Function()? _disposePasteListener;

  @override
  void initState() {
    super.initState();
    _setup();
    _loadMeta();
    store.addListener(_onStore);
    store.refreshSessions();
    _scroll.addListener(_onScroll);
    // Persist the typed text into the per-session draft as the user types, so
    // leaving/returning never loses it.
    _input.addListener(_persistDraft);
    // Hardware-keyboard behavior: Enter sends, Ctrl/Cmd+Enter inserts a newline.
    // (The on-screen soft keyboard's Enter arrives through the IME, NOT as a
    // key event, so it falls through to `TextInputAction.newline` and inserts a
    // newline — no send. That is the desired mobile behavior.)
    _inputFocus.onKeyEvent = _onComposerKey;
    // Web has no Ctrl+V key path that exposes clipboard FILES; a document-level
    // `paste` listener does (the browser grants access during the event).
    if (kIsWeb) {
      _disposePasteListener = installWebPasteListener(_onWebPaste);
    }
  }

  /// Upload a clipboard/dropped media item through the normal attachment path
  /// (upload state, retry, draft persistence, all-or-nothing send).
  void _addPastedMedia(ClipboardMedia media) {
    if (!mounted) return;
    _uploadOne(UploadedFileSource(
      name: media.name,
      mimeType: media.mime,
      bytes: media.bytes,
    ));
  }

  /// Web `paste` listener callback: only turn the clipboard into an attachment
  /// while the composer is focused, so pasting an image into some other field
  /// (e.g. a settings dialog) never silently adds an attachment.
  void _onWebPaste(ClipboardMedia media) {
    if (!mounted || !_inputFocus.hasFocus) return;
    _addPastedMedia(media);
  }

  /// Key-event handler for the composer. Returns [KeyEventResult.handled] for
  /// a bare hardware Enter (→ send), Ctrl/Cmd+Enter (→ newline) and Ctrl/Cmd+V
  /// (→ paste media as an attachment, or plain text); every other key is
  /// ignored. Only HARDWARE key events reach here — a phone's virtual keyboard
  /// Enter is an IME action, so it never triggers a send.
  KeyEventResult _onComposerKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isEnter =
        key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter;
    final isPaste = key == LogicalKeyboardKey.keyV;
    if (!isEnter && !isPaste) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    // A repeat (key held) must not spam sends / pastes.
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    final hw = HardwareKeyboard.instance;
    final modifier = hw.isControlPressed || hw.isMetaPressed;
    if (isPaste) {
      // Only a modified V is a paste; a bare "v" must type normally.
      if (!modifier) return KeyEventResult.ignored;
      // Android has no hardware Ctrl+V path (and no clipboard-media plugin);
      // fall through so the platform's own text paste handles it.
      if (!_supportsMediaPasteDrop) return KeyEventResult.ignored;
      // Web routes paste through the document `paste` listener (key events
      // there cannot expose clipboard files); let the browser handle it.
      if (kIsWeb) return KeyEventResult.ignored;
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }
    if (modifier) {
      // Ctrl/Cmd+Enter: insert a newline at the caret instead of sending.
      _insertNewline();
      return KeyEventResult.handled;
    }
    _send();
    return KeyEventResult.handled;
  }

  /// Ctrl/Cmd+V on native: if the clipboard holds an image/file it becomes an
  /// attachment; otherwise the plain text is inserted at the caret (the usual
  /// editor behaviour).
  Future<void> _pasteFromClipboard() async {
    final media = await readClipboardMedia();
    if (!mounted) return;
    if (media != null) {
      _addPastedMedia(media);
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = data?.text;
    if (txt == null || txt.isEmpty || !mounted) return;
    final sel = _input.selection;
    final text = _input.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _input.value = TextEditingValue(
      text: text.replaceRange(start, end, txt),
      selection: TextSelection.collapsed(offset: start + txt.length),
    );
    if (mounted) setState(() {});
    _persistDraft();
  }

  void _insertNewline() {
    final sel = _input.selection;
    final text = _input.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final next = text.replaceRange(start, end, '\n');
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    if (mounted) setState(() {});
    _persistDraft();
  }

  void _onScroll() {
    final m = _msg;
    if (m == null || !_scroll.hasClients) return;
    // Only a USER scroll changes follow intent. Content growth (streaming)
    // also mutates maxScrollExtent/pixels, so we must ignore those — otherwise
    // the follow would switch off as soon as a delta arrives. Return to the
    // bottom (within 8px) re-arms following.
    if (_scroll.position.userScrollDirection != ScrollDirection.idle) {
      _followBottom =
          _scroll.position.maxScrollExtent - _scroll.position.pixels <= 8;
    }
    // Near the top and there is more history → auto-load older messages.
    if (_scroll.position.pixels < 80 && m.hasMore && !m.loading) {
      m.loadMore();
    }
  }

  void _onStore() {
    final sid = store.activeSessionId;
    final m = _msg;
    if (m == null || sid == null) return;
    // re-init if session changed. Compare the CONTROLLER's bound session, not
    // the dynamic getSessionId() (which always reads the latest id and would
    // make this comparison a no-op when picking a new session).
    if (_boundSid != sid) {
      _setup();
    }
  }

  Future<void> _loadMeta() async {
    // Providers (id → ProviderInfo with its models) drive the provider → model
    // cascade in session settings. `listModels` is per-provider, so the app
    // only fetches a provider's models when it is selected.
    try {
      _providers = await widget.store.api.providers();
    } catch (e) {
      if (isAuthError(e)) showAuthExpiredDialog();
    }
    try {
      _presets = await widget.store.api.presets(
        locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh),
      );
    } catch (e) {
      if (isAuthError(e)) showAuthExpiredDialog();
    }
    if (mounted) setState(() {});
    // Do NOT hijack store.codeOrg/codeRepo here: the Code tab is an
    // independent workspace the user browses by itself. The active session's
    // repository is only bound into the code view when the user explicitly
    // opens the Files overlay below.
  }

  Future<void> _setup() async {
    final sid = store.activeSessionId;
    if (sid == null) return;
    // Same-session reuse: keep the existing MessagesController (and its
    // long-lived SSE) when the active session id hasn't actually changed.
    // Recreating would tear down and reopen the stream unnecessarily.
    if (_boundSid == sid && _msg != null) return;
    _boundSid = sid;
    // Restore this session's unsent draft (typed text + pending attachments) so
    // leaving and returning never loses it.
    _restoreDraft(sid);
    _msg?.dispose();
    final m = MessagesController(
      api: store.api,
      getSessionId: () => sid,
      local: store.local,
    );
    m.onSessionEvent((event, params) {
      if (event == 'turn-complete') {
        store.bumpSessionRevision();
      }
      if (event == 'tool-result' && params['change_id'] is String) {
        store.bumpSessionRevision();
      }
      if (event == 'status' && params['type'] == 'busy') {
        store.bumpSessionRevision();
      }
    });
    m.addListener(_onMsg);
    m.init();
    // New conversation: reset scroll so it sticks to the latest message.
    _initialScrollDone = false;
    _followBottom = true;
    setState(() => _msg = m);
  }

  void _onMsg() {
    if (!mounted) return;
    setState(() {});
    _autoScroll();
  }

  void _autoScroll() {
    if (!_scroll.hasClients) return;
    final m = _msg;
    if (m == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Pin to the newest message on first paint AND whenever we are still
      // following the bottom. Media (images / video posters) loads
      // asynchronously and grows the list AFTER the first frame, so this must
      // re-pin on every content change — not only once — or the view can end
      // up scrolled partway up with the newest message below the fold.
      if (!_initialScrollDone || _followBottom) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        _initialScrollDone = true;
      }
    });
  }

  /// Re-pin to the bottom when the list's content size changes (e.g. an async
  /// image finishes loading and makes the scrollable taller), while the user is
  /// still following the newest message.
  bool _onScrollMetrics(ScrollMetricsNotification n) {
    if (_followBottom && _scroll.hasClients && n.depth == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients || !_followBottom) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
    return false;
  }

  @override
  void dispose() {
    // The draft (text + attachments) already lives on the store, so it survives
    // this widget being torn down — just detach the listeners.
    _persistDraft();
    _disposePasteListener?.call();
    _voiceTicker?.cancel();
    _voice.dispose();
    _scroll.removeListener(_onScroll);
    store.removeListener(_onStore);
    _msg?.removeListener(_onMsg);
    _msg?.dispose();
    _input.removeListener(_persistDraft);
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Mirror the current composer state into the store's per-session draft.
  void _persistDraft() {
    final sid = _boundSid;
    if (sid == null) return;
    store.saveDraftText(sid, _input.text);
  }

  /// Mirror the pending attachments into the store's per-session draft. Called
  /// whenever the attachment list changes (add / upload-complete / error /
  /// remove / send).
  void _persistAttachments() {
    final sid = _boundSid;
    if (sid == null) return;
    store.saveDraftAttachments(sid, _pendingAttachments);
  }

  /// Re-seed the composer from the store's draft for [sid] (called when the
  /// bound session changes, e.g. re-entering a conversation).
  void _restoreDraft(String sid) {
    final d = store.chatDrafts[sid];
    if (d == null) {
      if (_input.text.isNotEmpty) _input.clear();
      _pendingAttachments = [];
      return;
    }
    if (_input.text != d.text) {
      _input.text = d.text;
      _input.selection = TextSelection.collapsed(offset: d.text.length);
    }
    _pendingAttachments = List.of(d.attachments);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    if (_sending || (_msg?.sending ?? false)) return;
    setState(() => _sending = true);
    // If any attachment is still uploading, spin the send button and WAIT for
    // every in-flight upload to finish before sending. Await a retained copy of
    // the futures directly (a plain `await` cannot be interrupted, so the
    // spinner reliably reflects a real wait); catch errors so `Future.wait`
    // itself never throws here — the per-attachment error state is inspected
    // below instead.
    if (_inflightUploads.isNotEmpty) {
      final pending = List<Future<void>>.of(_inflightUploads);
      await Future.wait(pending.map((f) => f.catchError((_) {})));
      if (!mounted) {
        _sending = false;
        return;
      }
    }
    // ALL-or-NOTHING: every pending attachment must have uploaded successfully.
    // If any failed (or is still without a code) the send is refused — the
    // batch stays so the user can retry the failed one; we never send a
    // partial batch.
    final failed = _pendingAttachments
        .where((a) => a.hasError || a.code.isEmpty)
        .toList();
    if (failed.isNotEmpty) {
      setState(() => _sending = false);
      if (mounted) {
        showToast(context, context.l10n.uploadFailedRetry('${failed.length}'));
      }
      return;
    }
    final attachments = List<UploadedFile>.of(_pendingAttachments);
    _pendingAttachments = [];
    _input.clear();
    // The draft is spent: clear it so returning to this session starts clean.
    if (_boundSid != null) store.clearDraft(_boundSid!);
    // A freshly sent message should always land at the bottom.
    _followBottom = true;
    setState(() => _sending = false);
    await _msg?.send(text, attachments);
    _inputFocus.requestFocus();
  }

  List<UploadedFile> _pendingAttachments = [];
  final ImagePicker _picker = ImagePicker();

  /// Send is in its "finishing uploads then send" state (button spins).
  bool _sending = false;

  /// Uploads currently in flight (so send can await them all first).
  final Set<Future<void>> _inflightUploads = {};

  // ---- voice recording ----------------------------------------------------
  final VoiceRecorder _voice = VoiceRecorder();
  bool _recording = false;

  /// Voice input mode (mic vs keyboard toggle in the composer).
  bool _voiceMode = false;
  Duration _voiceElapsed = Duration.zero;
  Timer? _voiceTicker;

  /// Toggle: start recording (mic permission flow) and swap the composer into
  /// recording mode; stop uploads the clip as a normal attachment.
  Future<void> _startRecording() async {
    final ok = await _voice.start();
    if (!mounted) return;
    if (!ok) {
      showToast(context, context.l10n.voicePermission);
      return;
    }
    setState(() {
      _recording = true;
      _voiceElapsed = Duration.zero;
    });
    _voiceTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_recording) return;
      setState(() => _voiceElapsed = _voice.elapsed);
    });
  }

  Future<void> _stopRecording() async {
    _voiceTicker?.cancel();
    _voiceTicker = null;
    final src = await _voice.stop();
    if (!mounted) return;
    setState(() {
      _recording = false;
    });
    if (src != null) {
      _uploadOne(src);
    } else if (mounted) {
      // Nothing recorded (too short / start raced) — tell the user instead of
      // silently doing nothing.
      showToast(context, context.l10n.voiceTooShort);
    }
  }

  void _cancelRecording() {
    _voiceTicker?.cancel();
    _voiceTicker = null;
    _voice.cancel();
    if (mounted) setState(() => _recording = false);
  }

  /// Open the attach bottom sheet: camera / gallery / files. A selected item
  /// is uploaded immediately and shown (with an uploading state) above the
  /// composer.
  Future<void> _openAttachSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(ctx.l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(ctx.l10n.chooseImage),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(ctx.l10n.chooseFile),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'camera':
        await _pickImage(ImageSource.camera);
      case 'gallery':
        await _pickImage(ImageSource.gallery);
      case 'file':
        await _pickFiles();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? x;
    try {
      x = await _picker.pickImage(source: source);
    } catch (_) {
      return;
    }
    if (x == null) return;
    // image_picker writes into a cache dir named with a UUID (e.g.
    // 5270fc2a-…-1783/image_picker_xxx.jpg) and XFile.name is the last path
    // segment — that UUID garbage. Give it a clean timestamped name.
    final name = _displayName(
      x.name,
      kind: (x.mimeType ?? '').startsWith('image/') ? 'image' : 'file',
    );
    _uploadOne(
      UploadedFileSource(
        path: x.path,
        name: name,
        mimeType: x.mimeType ?? mimeOfName(x.name),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result.isEmpty) return;
    for (final f in result) {
      final path = f.path;
      if (path == null) continue;
      _uploadOne(
        UploadedFileSource(
          path: path,
          name: _displayName(f.name, path: path),
          mimeType: mimeOfName(f.name),
        ),
      );
    }
  }

  /// A human-friendly attachment name. Drops a UUID-ish basename (image_picker
  /// temp names) in favour of `<kind>-<uuid>.<ext>`, keeping the extension.
  static String _displayName(String raw, {String? path, String kind = 'file'}) {
    final base = raw.split('/').last.split('\\').last;
    final dot = base.lastIndexOf('.');
    final ext = dot > 0 ? base.substring(dot) : _extFromPath(path) ?? '';
    // A UUID basename is 8-4-4-4-12 hex (image_picker temp files).
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(dot > 0 ? base.substring(0, dot) : base);
    if (isUuid || base.isEmpty || dot == 0) {
      return '$kind-${_uuid.v4()}$ext';
    }
    return base;
  }

  static String? _extFromPath(String? p) {
    if (p == null) return null;
    final dot = p.lastIndexOf('.');
    return dot > 0 ? p.substring(dot) : null;
  }

  /// Upload a single file and append it to the pending list. The local path
  /// is kept so an image can render a thumbnail while uploading (and before
  /// the bytes are ever needed).
  Future<void> _uploadOne(UploadedFileSource src) {
    final future = _uploadOneInner(src);
    _inflightUploads.add(future);
    return future.whenComplete(() => _inflightUploads.remove(future));
  }

  Future<void> _uploadOneInner(UploadedFileSource src) async {
    setState(() {
      _pendingAttachments = [
        ..._pendingAttachments,
        UploadedFile(
          code: '',
          name: src.name,
          mime: src.mimeType,
        ).uploading(src.path),
      ];
    });
    _persistAttachments();
    try {
      final uploaded = await store.api.uploadFile(src);
      if (!mounted) return;
      setState(() {
        _pendingAttachments = [
          for (final a in _pendingAttachments)
            if (a.code == '' && a.name == src.name) uploaded else a,
        ];
      });
      _persistAttachments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingAttachments = [
          for (final a in _pendingAttachments)
            if (a.code == '' && a.name == src.name) a.uploadError('$e') else a,
        ];
      });
      _persistAttachments();
    }
  }

  Widget _attachmentRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      // Size every tile so exactly THREE fit per line; the tiles are square and
      // identical (no filename), with slight rounding on tablets.
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.xs;
          const cols = 3;
          final dim =
              ((constraints.maxWidth - gap * (cols - 1)) / cols).clamp(40.0, 72.0);
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final a in _pendingAttachments)
                _attachmentChip(context, a, dim),
            ],
          );
        },
      ),
    );
  }

  Widget _attachmentChip(BuildContext context, UploadedFile a, double dim) {
    // A small uniform square tile: thumbnail (image) or type icon, no name. A
    // corner badge shows upload state / retry / remove; tapping opens the full
    // media (image full-screen / audio player).
    final colors = colorsOf(context);
    Widget overlay;
    if (a.isUploading) {
      overlay = const _TileBadge(
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
        ),
      );
    } else if (a.hasError) {
      overlay = _TileBadge(
        color: colors.destructive,
        onTap: () => _uploadOne(UploadedFileSource(
          path: a.localPath,
          name: a.name ?? '',
          mimeType: a.mime ?? '',
        )),
        child: const Icon(Icons.refresh_rounded, size: 12, color: Colors.white),
      );
    } else {
      overlay = _TileBadge(
        onTap: () {
          setState(() {
            _pendingAttachments =
                _pendingAttachments.where((x) => x != a).toList();
          });
          _persistAttachments();
        },
        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
      );
    }
    return AttachmentTag(
      api: store.api,
      code: a.code,
      name: a.name ?? '',
      mime: a.mime,
      size: a.size,
      localPath: a.localPath,
      dimension: dim,
      onTap: a.code.isEmpty
          ? null
          : () => showAttachment(
              context, store.api, a.code, a.name, a.mime, a.size),
      overlay: overlay,
    );
  }

  void _applySession(Session updated) {
    store.sessions = store.sessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    store.notifyObservers();
    // Rebuild the chat screen so the header (model/preset indicator) and any
    // activeSession-dependent widgets reflect the just-applied settings.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return PopScope(
      // System back inside a conversation returns to the previous chat view
      // (session list / overlay) instead of backgrounding the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (store.canPopPage) {
          store.popPage();
        } else {
          store.closeSession();
        }
      },
      child: _dropEnabled ? _wrapDropTarget(colors) : _conversationBody(colors),
    );
  }

  /// Whether this platform accepts file drag-and-drop (desktop + web only).
  bool get _dropEnabled => _supportsMediaPasteDrop;

  /// The conversation column + optional drop overlay, without any drop target.
  Widget _conversationBody(AppColors colors) {
    return Stack(
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _topBar(context),
                  Divider(
                      height: 1, color: colors.border.withValues(alpha: 0.5)),
                ],
              ),
            ),
            Expanded(child: _messageList()),
            _composer(context),
          ],
        ),
        if (_dragging) _dropOverlay(context),
      ],
    );
  }

  /// Wrap the conversation in a [DropTarget] (desktop + web): dragging files or
  /// images onto it attaches them; directories are refused with a hint.
  Widget _wrapDropTarget(AppColors colors) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDropFiles,
      child: _conversationBody(colors),
    );
  }

  /// Handle a drop on the conversation: every FILE becomes an attachment (the
  /// same upload path as a picked/clipboard file). Directories are refused —
  /// a drop that is only a directory shows a hint instead of silently doing
  /// nothing.
  Future<void> _onDropFiles(DropDoneDetails details) async {
    if (mounted) setState(() => _dragging = false);
    final accepted = <DropItem>[];
    var rejectedDir = false;
    for (final item in details.files) {
      if (item is DropItemDirectory) {
        rejectedDir = true;
        continue;
      }
      accepted.add(item);
    }
    if (rejectedDir && mounted) {
      showToast(context, context.l10n.folderNotAllowed);
    }
    for (final item in accepted) {
      final name = item.name.isNotEmpty
          ? item.name
          : 'file-${const Uuid().v4()}';
      final mime = (item.mimeType ?? '').isNotEmpty
          ? item.mimeType!
          : mimeOfName(name);
      // Dropped items carry in-memory bytes on web; on desktop a path. XFile's
      // readAsBytes covers both (native reads the file, web fetches the blob).
      Uint8List? bytes;
      try {
        bytes = await item.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) continue;
      _uploadOne(UploadedFileSource(
        path: kIsWeb ? '' : item.path,
        name: name,
        mimeType: mime,
        bytes: bytes,
      ));
    }
  }

  /// Full-area translucent overlay shown while a drag hovers the conversation.
  Widget _dropOverlay(BuildContext context) {
    final colors = colorsOf(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: colors.primary.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppRadius.rLg,
              border: Border.all(color: colors.primary, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file_rounded, size: 32, color: colors.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.dropToAttach,
                  style: textOf(context).body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Short context-size label: <10k → `X.Yk`, 10k–999k → `XXXk`,
  /// ≥1M → `X.YM`. Returns '' for 0 (nothing measured yet).
  static String _fmtContext(int tokens) {
    if (tokens <= 0) return '';
    if (tokens >= 1000000) {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
    if (tokens >= 10000) {
      final k = (tokens / 1000).round();
      return '${k}k';
    }
    return '${(tokens / 1000).toStringAsFixed(1)}k';
  }

  Widget _topBar(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final s = store.activeSession;
    final last = (s?.lastInputTokens ?? 0) + (s?.lastOutputTokens ?? 0);
    final ctxLabel = _fmtContext(last);
    final menu = PopupMenuButton<String>(
      onSelected: (v) => _menuAction(v),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'compact',
          child: Text(context.l10n.compactHistory),
        ),
        PopupMenuItem(value: 'mailbox', child: Text(context.l10n.mailbox)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'fork', child: Text(context.l10n.fork)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            context.l10n.deleteSession,
            style: TextStyle(color: colors.destructive),
          ),
        ),
      ],
    );
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: AppBars.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Session name pill — CENTERED in the bar (tap opens the info
            // dialog), independent of how wide the side controls are.
            Center(child: _SessionNamePill(session: s, onEdit: _showSettings)),
            // Left cluster: back + status lamp + context size.
            Positioned(
              left: AppSpacing.xs,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    onPressed: () => store.popPage(),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _msg?.sending == true
                          ? colors.warning
                          : colors.success,
                    ),
                  ),
                  if (ctxLabel.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      ctxLabel,
                      style: text.micro.copyWith(
                        color: colors.mutedForeground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Right cluster: menu.
            Positioned(
              right: AppSpacing.xs,
              top: 0,
              bottom: 0,
              child: menu,
            ),
          ],
        ),
      ),
    );
  }

  void _menuAction(String v) {
    switch (v) {
      case 'compact':
        _compact();
      case 'mailbox':
        _openOverlay(SessionOverlay.mailbox);
      case 'fork':
        _forkSession();
      case 'delete':
        _deleteSession();
    }
  }

  /// Open a session sub-page by pushing onto the chat tab's stack.
  void _openOverlay(SessionOverlay overlay) {
    store.pushPage(ChatOverlayPage(overlay));
  }

  Future<void> _deleteSession() async {
    final sid = store.activeSessionId;
    final s = store.activeSession;
    if (sid == null) return;
    final label = s != null && s.org.isNotEmpty
        ? '${s.org}/${s.repo}/${s.branch}'
        : sid;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteSessionTitle),
        content: Text(context.l10n.deleteSessionBody(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorsOf(ctx).destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        // Deleting the open session closes this conversation and pops the chat
        // stack back to the session list.
        await store.deleteSession(sid);
      } catch (e) {
        if (!mounted) return;
        showErrorToast(context, context.l10n.failed('$e'));
      }
    }
  }

  Future<void> _forkSession() async {
    final sid = store.activeSessionId;
    if (sid == null) return;
    final name = await promptDialog(context, title: context.l10n.fork);
    if (name == null || name.trim().isEmpty) return;
    try {
      final s = await store.api.fork(sid, name.trim());
      if (!mounted) return;
      store.activeSessionId = s.id;
      await store.refreshSessions();
    } catch (e) {
      if (!mounted) return;
      showErrorToast(context, context.l10n.failed('$e'));
    }
  }

  Future<void> _compact() async {
    final sid = store.activeSessionId;
    if (sid == null) return;
    try {
      final created = await store.api.compact(sid);
      if (!mounted) return;
      if (created) {
        // A compaction checkpoint was created: reopen the conversation so the
        // new "历史已压缩" summary message renders at the top of the tail.
        showToast(context, context.l10n.historyCompacted);
        await _setup();
      } else {
        // Nothing to fold (the agent returns {ok:false}); the current
        // conversation is unchanged.
        showToast(context, context.l10n.nothingToCompact);
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, '$e');
      }
    }
  }

  void _showSettings() {
    final sid = store.activeSessionId;
    if (sid == null) return;
    // Hold the editable model/variant/preset/locale OUTSIDE the StatefulBuilder
    // so a rebuild (e.g. tapping a dropdown) does NOT re-seed them from the
    // store and discard the user's in-progress selection.
    //
    // The session model is a canonical "provider_id/model_id" reference (a
    // bare model id is never resolved by flat lookup). A SINGLE dropdown lists
    // every text model as "provider_id/model_id", so provider and model are
    // never chosen apart.
    String selectedRef = store.activeSession?.model ?? '';
    String variant = store.activeSession?.variant ?? '';
    String preset = store.activeSession?.preset ?? '';
    String locale = store.activeSession?.locale ?? '';
    // `listModels` is per-provider, so fetch every provider's text models and
    // flatten them into one ref list.
    final providerIds = _providers.keys.toList();
    List<ModelInfo> allModels = [];
    List<ModelVariantInfo> variantsForModel = [];
    bool loadingModels = true;
    void syncVariants() {
      final sel = allModels.where((m) => modelRefOf(m) == selectedRef);
      variantsForModel = sel.isEmpty ? const [] : sel.first.variants;
      if (!variantsForModel.any((v) => v.id == variant)) variant = '';
    }

    Future<void> loadModels(void Function(void Function()) setState) async {
      setState(() => loadingModels = true);
      final out = <ModelInfo>[];
      for (final pid in providerIds) {
        try {
          out.addAll(await store.api.models(providerId: pid));
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        allModels = out;
        loadingModels = false;
        // Keep the current model if still valid, else default to the first.
        if (!out.any((m) => modelRefOf(m) == selectedRef) && out.isNotEmpty) {
          selectedRef = modelRefOf(out.first);
        }
        syncVariants();
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          if (loadingModels && allModels.isEmpty) {
            // First open: kick off the initial model load once.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (allModels.isEmpty) loadModels(setState);
            });
          }
          final presetOptions = [
            ..._presets.map((p) => p.id),
            if (preset.isNotEmpty && !_presets.any((p) => p.id == preset))
              preset,
          ];
          final localeOptions = [
            for (final (code, label) in [
              ('', ctx.l10n.agentLocaleFollow),
              ('zh', '中文'),
              ('en', 'English'),
            ])
              DropdownMenuItem(value: code, child: Text(label)),
          ];
          return AlertDialog(
            title: Text(ctx.l10n.settingsTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A SINGLE "provider_id/model_id" dropdown (text models across
                  // every provider), so provider and model are never picked apart.
                  DropdownButtonFormField<String>(
                    initialValue: selectedRef.isEmpty ? null : selectedRef,
                    isExpanded: true,
                    items: [
                      if (allModels.isEmpty)
                        DropdownMenuItem(value: '', child: Text(ctx.l10n.none)),
                      for (final m in allModels)
                        DropdownMenuItem(
                          value: modelRefOf(m),
                          child: Text(modelRefOf(m)),
                        ),
                      // Keep the session's current model selectable even if the
                      // registry no longer lists it.
                      if (selectedRef.isNotEmpty &&
                          !allModels.any((m) => modelRefOf(m) == selectedRef))
                        DropdownMenuItem(
                          value: selectedRef,
                          child: Text(selectedRef),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      selectedRef = v ?? '';
                      syncVariants();
                    }),
                    decoration: InputDecoration(labelText: ctx.l10n.modelLabel),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Reasoning variant (only when the model advertises any).
                  if (variantsForModel.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: variant.isEmpty ? '' : variant,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(ctx.l10n.variantNone),
                        ),
                        for (final v in variantsForModel)
                          DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name.isNotEmpty ? v.name : v.id),
                          ),
                      ],
                      onChanged: (v) => setState(() => variant = v ?? ''),
                      decoration: InputDecoration(
                        labelText: ctx.l10n.variantLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: preset.isEmpty ? null : preset,
                    items: [
                      for (final id in presetOptions)
                        DropdownMenuItem(value: id, child: Text(id)),
                    ],
                    onChanged: (v) => setState(() => preset = v ?? ''),
                    decoration: InputDecoration(
                      labelText: ctx.l10n.presetLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Per-session language override.
                  DropdownButtonFormField<String>(
                    initialValue: locale.isEmpty ? '' : locale,
                    items: localeOptions,
                    onChanged: (v) => setState(() => locale = v ?? ''),
                    decoration: InputDecoration(
                      labelText: ctx.l10n.agentLocale,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Max turns is governed by the preset (set when the preset is
                  // customized) — not editable per session here.
                  // System prompt is governed by the selected preset.
                  Text(
                    ctx.l10n.turnsByPreset,
                    style: textOf(ctx).micro
                        .copyWith(color: colorsOf(ctx).mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ctx.l10n.sysPromptByPreset,
                    style: textOf(ctx).micro
                        .copyWith(color: colorsOf(ctx).mutedForeground),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final updates = <String, dynamic>{};
                  // Model is the selected "provider_id/model_id" ref.
                  if (selectedRef.isNotEmpty) {
                    updates['model'] = selectedRef;
                  }
                  updates['variant'] = variant;
                  if (preset.isNotEmpty) updates['preset'] = preset;
                  // Only send the per-session locale when explicitly chosen;
                  // '' (follow) is sent as empty to clear any override.
                  updates['locale'] = locale;
                  try {
                    final updated = await store.api.settings(sid, updates);
                    _applySession(updated);
                  } catch (e) {
                    if (mounted) {
                      showErrorToast(context, '$e');
                    }
                  }
                },
                child: Text(ctx.l10n.apply),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _messageList() {
    final m = _msg;
    if (m == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // NotificationListener on ScrollMetrics: a media card that finishes loading
    // AFTER first paint makes the list taller; while following the newest
    // message, re-pin so the newest message never sits below the fold.
    //
    // NOTE: no pull-to-refresh here. In a chat, pulling down is the platform
    // convention for "load earlier history" (handled in [_onScroll]),
    // and new messages already arrive over the live stream. A manual "rebuild
    // the cache" escape hatch lives in the top-bar menu instead.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScrollMetrics,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        itemCount: m.sorted.length + (m.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0 && m.hasMore) {
            return Center(
              child: TextButton(
                onPressed: m.loading ? null : () => m.loadMore(),
                child: Text(
                  m.loading ? context.l10n.loading : context.l10n.loadEarlier,
                ),
              ),
            );
          }
          final msg = m.sorted[i - (m.hasMore ? 1 : 0)];
          return MessageBubble(
            key: ValueKey(msg.id),
            msg: msg,
            onUndo: (id) => m.revert(id),
            // Retry / edit withdraw this message (and everything after it),
            // then resend it (as-is or with edited text) keeping its
            // attachments.
            onResend: (text) => m.resendFrom(msg, text),
            onEditText: (text) => m.resendFrom(msg, text),

            api: store.api,
            org: store.activeSession?.org ?? '',
            repo: store.activeSession?.repo ?? '',
            branch: store.activeSession?.branch ?? '',
          );
        },
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final m = _msg;
    final colors = colorsOf(context);
    final text = textOf(context);
    final sending = m?.sending ?? false;
    final hasContent =
        _input.text.trim().isNotEmpty || _pendingAttachments.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pendingAttachments.isNotEmpty) _attachmentRow(context),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left: mic/keyboard toggle. In voice mode the middle becomes
                  // a press-and-hold "hold to talk" button.
                  IconButton(
                    tooltip: _voiceMode
                        ? context.l10n.keyboardMode
                        : context.l10n.voiceMode,
                    onPressed: sending
                        ? null
                        : () => setState(() => _voiceMode = !_voiceMode),
                    icon: Icon(
                      _voiceMode
                          ? Icons.keyboard_alt_outlined
                          : Icons.mic_none_rounded,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: _voiceMode
                        ? _holdToTalkButton(context)
                        : _composerBox(
                            // The SAME shell as the hold-to-talk button, so both
                            // are exactly the same height (min 42, growing with
                            // wrapped text). The TextField itself contributes no
                            // decoration padding (isCollapsed + no border), so
                            // the shell — not the field's decorator — owns the
                            // fill, radius and height.
                            child: TextField(
                              controller: _input,
                              focusNode: _inputFocus,
                              minLines: 1,
                              maxLines: 6,
                              // Use the SAME text style as the hold-to-talk
                              // label so the field and the button scale
                              // identically and line up pixel-for-pixel.
                              style: text.body,
                              textInputAction: TextInputAction.newline,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (_) {
                                setState(() {});
                                _persistDraft();
                              },
                              decoration: InputDecoration(
                                isCollapsed: true,
                                // The shared shell owns the fill/radius/border.
                                // Disable EVERY field border too, else the
                                // theme's OutlineInputBorder (enabled/focused)
                                // draws a second inner box inside the shell.
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                hintStyle: text.body.copyWith(
                                    color: colors.mutedForeground),
                                hintText: _pendingAttachments.isEmpty
                                    ? context.l10n.typeMessage
                                    : '',
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Right: one morphing button — abort (running) / spinner
                  // (finishing uploads before send) / send (has content) /
                  // plus (empty → open attach sheet).
                  sending
                      ? IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: colors.destructive,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: context.l10n.abort,
                          icon: const Icon(Icons.stop_rounded, size: 20),
                          onPressed: () => m?.stop(),
                        )
                      : _sending
                      ? IconButton.filled(
                          icon: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: null,
                        )
                      : hasContent
                      ? IconButton.filled(
                          icon: const Icon(Icons.send_rounded, size: 20),
                          onPressed: _send,
                        )
                      : IconButton.filledTonal(
                          tooltip: context.l10n.attach,
                          icon: const Icon(Icons.add_rounded, size: 22),
                          onPressed: _openAttachSheet,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The shared composer field shell: fill + radius + border + a min height of
  /// [_composerFieldHeight]. BOTH the text field and the hold-to-talk button
  /// use it, so the two are always EXACTLY the same height regardless of font
  /// scale (the field's own decorator contributes no padding — isCollapsed).
  Widget _composerBox({required Widget child, BoxDecoration? decoration}) {
    final colors = colorsOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: _composerFieldHeight),
      alignment: Alignment.center,
      decoration: decoration ??
          BoxDecoration(
            color: colors.muted,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
      child: child,
    );
  }

  /// Press-and-hold voice button (WeChat style): hold to record, release to
  /// send the clip as an attachment. Stays in voice mode afterwards.
  Widget _holdToTalkButton(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: _cancelRecording,
      child: _composerBox(
        decoration: BoxDecoration(
          // Same fill + radius as the text-field shell; only the tint/border
          // change while recording.
          color: _recording
              ? colors.destructive.withValues(alpha: 0.12)
              : colors.muted,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: _recording
                ? colors.destructive
                : colors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          _recording
              ? '${context.l10n.releaseToSend} · ${_formatDuration(_voiceElapsed)}'
              : context.l10n.holdToTalk,
          // Same style as the text field (see _composer) so the two are the
          // same height and their baselines align.
          style: text.body.copyWith(
            color: _recording ? colors.destructive : colors.mutedForeground,
            fontWeight: _recording ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Fixed-width session-name pill. Shows the session name, ellipsized when it
/// overflows; tapping opens a centered session-info dialog (provider / model /
/// preset / agent language) with an Edit action into the settings dialog.
class _SessionNamePill extends StatelessWidget {
  final Session? session;
  final VoidCallback onEdit;
  const _SessionNamePill({required this.session, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return ConstrainedBox(
      // Fixed pill length; long names get an ellipsis.
      constraints: const BoxConstraints(maxWidth: 160, minWidth: 96),
      child: Material(
        // Tinted with the app accent (not a flat grey), so the centered pill
        // reads as the chat's identity chip.
        color: colors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            child: Text(
              session?.id ?? context.l10n.chatTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.meta.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    final s = session;
    showDialog<void>(
      context: context,
      builder: (ctx) => _SessionInfoDialog(session: s, onEdit: onEdit),
    );
  }
}

/// Centered session-info dialog: a tidy label/value card with an Edit action.
class _SessionInfoDialog extends StatelessWidget {
  final Session? session;
  final VoidCallback onEdit;
  const _SessionInfoDialog({required this.session, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final s = session;
    final modelRef = s?.model ?? '';
    final locale = (s?.locale ?? '').isEmpty
        ? context.l10n.agentLocaleFollow
        : s!.locale!;

    final rows = <(String, String)>[
      (context.l10n.modelLabel, modelRef),
      (context.l10n.presetLabel, s?.preset ?? ''),
      (context.l10n.agentLocale, locale),
    ].where((r) => r.$2.isNotEmpty).toList();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      title: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s?.id ?? context.l10n.chatTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.meta.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: colors.border.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      rows[i].$1,
                      style: text.micro.copyWith(color: colors.mutedForeground),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: text.meta.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(context.l10n.edit),
        ),
      ],
    );
  }
}

/// A small corner badge for an attachment tile (upload spinner / retry /
/// remove). Sits at the tile's top-right; [onTap] makes it actionable.
class _TileBadge extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  const _TileBadge({required this.child, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.black54;
    final badge = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: child,
    );
    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
