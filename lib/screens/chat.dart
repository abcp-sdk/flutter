import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../i18n.dart';
import '../enums.dart';
import '../navigation.dart';
import '../messages.dart';
import '../models.dart';
import '../prefs.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/message_bubble.dart';

/// Conversation page shown when a session is open. Owns the chat header,
/// message list and composer. It reads the active session from [store]; a
/// single [MessagesController] is kept per chat-screen instance.
class ChatSessionPageWidget extends StatefulWidget {
  final AppStore store;
  const ChatSessionPageWidget({super.key, required this.store});

  @override
  State<ChatSessionPageWidget> createState() => _ChatSessionPageState();
}

class _ChatSessionPageState extends State<ChatSessionPageWidget> {
  AppStore get store => widget.store;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  MessagesController? _msg;
  Map<String, ProviderInfo> _providers = {};
  List<Preset> _presets = [];
  bool _initialScrollDone = false;
  // The session id the current _msg controller is bound to (set in _setup).
  String? _boundSid;

  @override
  void initState() {
    super.initState();
    _setup();
    _loadMeta();
    store.addListener(_onStore);
    store.refreshSessions();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final m = _msg;
    if (m == null || !_scroll.hasClients) return;
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
    } catch (_) {}
    try {
      _presets = await widget.store.api.presets(
          locale: Prefs.effectiveAgentLocale(uiZh: I18n.isZh));
    } catch (_) {}
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
    _msg?.dispose();
    final m = MessagesController(
        api: store.api, getSessionId: () => sid);
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
      if (!_initialScrollDone) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        _initialScrollDone = true;
      } else if (m.sending) {
        final nearBottom = _scroll.position.maxScrollExtent -
                _scroll.position.pixels <
            120;
        if (nearBottom) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    store.removeListener(_onStore);
    _msg?.removeListener(_onMsg);
    _msg?.dispose();
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    // Never send while an attachment is still uploading.
    if (_pendingAttachments.any((a) => a.isUploading)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.waitUpload)));
      }
      return;
    }
    // Drop errored attachments from the outgoing batch.
    final attachments =
        _pendingAttachments.where((a) => !a.hasError).toList();
    _pendingAttachments = [];
    _input.clear();
    setState(() {});
    await _msg?.send(text, attachments);
    _inputFocus.requestFocus();
  }

  List<UploadedFile> _pendingAttachments = [];
  final ImagePicker _picker = ImagePicker();

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
    _uploadOne(UploadedFileSource(
      path: x.path,
      name: x.name,
      mimeType: _mimeOf(x.name),
    ));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result.isEmpty) return;
    for (final f in result) {
      final path = f.path;
      if (path == null) continue;
      _uploadOne(UploadedFileSource(
        path: path,
        name: f.name,
        mimeType: _mimeOf(f.name),
      ));
    }
  }

  /// Upload a single file and append it to the pending list. The local path
  /// is kept so an image can render a thumbnail while uploading (and before
  /// the bytes are ever needed).
  Future<void> _uploadOne(UploadedFileSource src) async {
    setState(() {
      _pendingAttachments = [
        ..._pendingAttachments,
        UploadedFile(code: '', name: src.name, mime: src.mimeType)
            .uploading(src.path),
      ];
    });
    try {
      final uploaded = await store.api.uploadFile(src);
      if (!mounted) return;
      setState(() {
        _pendingAttachments = [
          for (final a in _pendingAttachments)
            if (a.code == '' && a.name == src.name) uploaded else a,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingAttachments = [
          for (final a in _pendingAttachments)
            if (a.code == '' && a.name == src.name) a.uploadError('$e') else a,
        ];
      });
    }
  }

  static String _mimeOf(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
    return 'application/octet-stream';
  }

  Widget _attachmentRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final a in _pendingAttachments) _attachmentChip(context, a),
        ],
      ),
    );
  }

  Widget _attachmentChip(BuildContext context, UploadedFile a) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final isImg = (a.mime ?? '').startsWith('image/');
    // Local thumbnails render straight from disk; remote images preview only
    // after upload (code set) via the bubble; here we show the offline thumb.
    Widget leading;
    if (isImg && a.localPath.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(a.localPath),
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.broken_image_outlined, size: 16)),
        ),
      );
    } else {
      leading = Icon(Icons.attach_file_rounded,
          size: 14, color: colors.mutedForeground);
    }
    Widget trailing;
    if (a.isUploading) {
      trailing = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2));
    } else if (a.hasError) {
      trailing = InkWell(
        onTap: () => _uploadOne(UploadedFileSource(
            path: a.localPath, name: a.name ?? '', mimeType: a.mime ?? '')),
        child: Icon(Icons.refresh_rounded, size: 16, color: colors.warning),
      );
    } else {
      trailing = InkWell(
        onTap: () {
          setState(() {
            _pendingAttachments =
                _pendingAttachments.where((x) => x != a).toList();
          });
        },
        child: Icon(Icons.cancel_rounded, size: 16, color: colors.mutedForeground),
      );
    }
    return Material(
      color: colors.muted.withValues(alpha: 0.5),
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: AppSpacing.xs),
            Text(a.name ?? a.code,
                style: text.micro.copyWith(color: colors.foreground)),
            const SizedBox(width: AppSpacing.xs),
            trailing,
          ],
        ),
      ),
    );
  }

  void _applySession(Session updated) {
    store.sessions =
        store.sessions.map((s) => s.id == updated.id ? updated : s).toList();
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
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(context),
                Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
              ],
            ),
          ),
          Expanded(child: _messageList()),
          _composer(context),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final s = store.activeSession;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: AppBars.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s != null
                      ? '${s.org}/${s.repo}'
                          '${s.branch.isNotEmpty ? '/${s.branch}' : ''}'
                      : context.l10n.chatTitle,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.mutedForeground),
                ),
              ),
              // Current model / preset — visible feedback that session
              // settings applied (the picker also re-seeds these next open).
              if (s != null && (s.model.isNotEmpty || s.preset.isNotEmpty))
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    [
                      if (s.model.isNotEmpty) s.model,
                      if (s.preset.isNotEmpty) s.preset,
                    ].join(' · '),
                    overflow: TextOverflow.ellipsis,
                    style: text.micro.copyWith(
                        color: colors.mutedForeground, fontSize: 10),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (v) => _menuAction(v),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'settings', child: Text(context.l10n.sessionSettings)),
                  PopupMenuItem(value: 'compact', child: Text(context.l10n.compactHistory)),
                  PopupMenuItem(value: 'mailbox', child: Text(context.l10n.mailbox)),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'fork',
                    child: Text(context.l10n.fork),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.deleteSession,
                        style: TextStyle(color: colors.destructive)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _menuAction(String v) {
    switch (v) {
      case 'settings':
        _showSettings();
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
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await store.deleteSession(sid);
      } catch (_) {
        await store.deleteSession(sid);
      }
      store.closeSession();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.failed('$e'))));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.historyCompacted)));
        await _setup();
      } else {
        // Nothing to fold (the agent returns {ok:false}); the current
        // conversation is unchanged.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.nothingToCompact)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
    // bare model id is never resolved by flat lookup). Split it so the
    // provider dropdown pre-selects the owner.
    final currentModel = store.activeSession?.model ?? '';
    final slash = currentModel.indexOf('/');
    String provider =
        slash > 0 ? currentModel.substring(0, slash) : '';
    String model = slash > 0 ? currentModel.substring(slash + 1) : currentModel;
    String variant = store.activeSession?.variant ?? '';
    String preset = store.activeSession?.preset ?? '';
    String locale = store.activeSession?.locale ?? '';
    // Cascading provider → model. provider_id is REQUIRED by the agent (a
    // global model list is rejected), so the provider dropdown has no "all"
    // option: pick the owner of the session's current model (else the first
    // registered provider), then load only that provider's models.
    final providerIds = _providers.keys.toList();
    if (provider.isEmpty && providerIds.isNotEmpty) provider = providerIds.first;
    List<ModelInfo> modelsForProvider = [];
    List<ModelVariantInfo> variantsForModel = [];
    bool loadingModels = true;
    void syncVariants() {
      final sel = modelsForProvider.where((m) => m.id == model);
      variantsForModel = sel.isEmpty ? const [] : sel.first.variants;
      if (!variantsForModel.any((v) => v.id == variant)) variant = '';
    }
    Future<void> loadModels(
      void Function(void Function()) setState,
    ) async {
      setState(() => loadingModels = true);
      try {
        final list = await store.api.models(providerId: provider);
        setState(() {
          modelsForProvider = list;
          loadingModels = false;
          // Keep the current model if still valid, else default to the first.
          if (!list.any((m) => m.id == model)) {
            model = list.isNotEmpty ? list.first.id : model;
          }
          syncVariants();
        });
      } catch (_) {
        if (mounted) setState(() => loadingModels = false);
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          if (loadingModels && modelsForProvider.isEmpty && provider.isNotEmpty) {
            // First open: kick off the initial model load once.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (modelsForProvider.isEmpty) loadModels(setState);
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
                  // 1) Provider. 2) Model (fetched for the chosen provider).
                  DropdownButtonFormField<String>(
                    initialValue:
                        providerIds.contains(provider) ? provider : null,
                    items: [
                      if (providerIds.isEmpty)
                        DropdownMenuItem(
                            value: '', child: Text(ctx.l10n.none)),
                      for (final pid in providerIds)
                        DropdownMenuItem(value: pid, child: Text(pid)),
                    ],
                    onChanged: (v) {
                      provider = v ?? '';
                      setState(() => modelsForProvider = []);
                      loadModels(setState);
                    },
                    decoration:
                        InputDecoration(labelText: ctx.l10n.providers),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: model.isEmpty ? null : model,
                    items: [
                      if (modelsForProvider.isEmpty)
                        DropdownMenuItem(
                            value: '', child: Text(ctx.l10n.none)),
                      for (final m in modelsForProvider)
                        DropdownMenuItem(
                            value: m.id,
                            child: Text(
                                m.name.isNotEmpty ? m.name : m.id)),
                      // Keep the session's current model selectable even if the
                      // registry no longer lists it.
                      if (model.isNotEmpty &&
                          !modelsForProvider.any((m) => m.id == model))
                        DropdownMenuItem(value: model, child: Text(model)),
                    ],
                    onChanged: (v) => setState(() {
                      model = v ?? '';
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
                            value: '', child: Text(ctx.l10n.variantNone)),
                        for (final v in variantsForModel)
                          DropdownMenuItem(
                              value: v.id,
                              child: Text(
                                  v.name.isNotEmpty ? v.name : v.id)),
                      ],
                      onChanged: (v) => setState(() => variant = v ?? ''),
                      decoration:
                          InputDecoration(labelText: ctx.l10n.variantLabel),
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
                    decoration: InputDecoration(labelText: ctx.l10n.presetLabel),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Per-session language override.
                  DropdownButtonFormField<String>(
                    initialValue: locale.isEmpty ? '' : locale,
                    items: localeOptions,
                    onChanged: (v) => setState(() => locale = v ?? ''),
                    decoration: InputDecoration(labelText: ctx.l10n.agentLocale),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Max turns is governed by the preset (set when the preset is
                  // customized) — not editable per session here.
                  // System prompt is governed by the selected preset.
                  Text(
                    ctx.l10n.turnsByPreset,
                    style: textOf(ctx)
                        .micro
                        .copyWith(color: colorsOf(ctx).mutedForeground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ctx.l10n.sysPromptByPreset,
                    style: textOf(ctx)
                        .micro
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
                  // Model is stored as a canonical provider/model reference.
                  if (model.isNotEmpty) {
                    updates['model'] = provider.isEmpty
                        ? model
                        : '$provider/$model';
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
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
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
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      itemCount: m.sorted.length + (m.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0 && m.hasMore) {
          return Center(
            child: TextButton(
              onPressed: m.loading ? null : () => m.loadMore(),
              child: Text(m.loading
                  ? context.l10n.loading
                  : context.l10n.loadEarlier),
            ),
          );
        }
        final msg = m.sorted[i - (m.hasMore ? 1 : 0)];
        return MessageBubble(
          key: ValueKey(msg.id),
          msg: msg,
          onUndo: (id) => m.revert(id),
          
          api: store.api,
          org: store.activeSession?.org ?? '',
          repo: store.activeSession?.repo ?? '',
          branch: store.activeSession?.branch ?? '',
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final m = _msg;
    final colors = colorsOf(context);
    final text = textOf(context);
    final sending = m?.sending ?? false;
    final last = ((store.activeSession?.lastInputTokens ?? 0) +
        (store.activeSession?.lastOutputTokens ?? 0));
    return Container(
      decoration: BoxDecoration(
          color: colors.card,
          border: Border(
              top: BorderSide(color: colors.border.withValues(alpha: 0.5)))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pendingAttachments.isNotEmpty)
                _attachmentRow(context),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: context.l10n.attach,
                    onPressed: sending ? null : _openAttachSheet,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      // Keep typing while the agent works (IM convention);
                      // only the send button becomes a stop button.
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            _pendingAttachments.isEmpty ? context.l10n.typeMessage : '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  sending
                      ? IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: colors.destructive,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.stop_rounded, size: 20),
                          onPressed: () => m?.stop(),
                        )
                      : IconButton.filled(
                          onPressed:
                              (_input.text.trim().isEmpty && _pendingAttachments.isEmpty)
                                  ? null
                                  : _send,
                          icon: const Icon(Icons.send_rounded, size: 20),
                        ),
                ],
              ),
              const SizedBox(height: 4),
              // Footer: right-aligned context token total (last turn's
              // request context), shown as e.g. "上下文 13.2K / Context 13.2K".
              Row(
                children: [
                  const Spacer(),
                  if (last > 0)
                    Text(
                      '${context.l10n.contextTokens} ${_k(last)}',
                      style: text.micro.copyWith(
                          color: colors.mutedForeground),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _k(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

