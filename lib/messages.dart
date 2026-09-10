import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'i18n.dart';
import 'models.dart';

/// Mirrors hooks/useMessages.svelte.ts + message-utils.ts.
class MessagesController extends ChangeNotifier {
  MessagesController({required this.api, required this.getSessionId});

  final AgentBindApi api;
  final String Function() getSessionId;

  List<ChatMessage> messages = [];
  bool sending = false;
  bool loading = false;
  bool hasMore = false;

  StreamSubscription<StreamEvent>? _sub;
  String? _streamingId;
  int _nextSeq = 1000000;
  final List<void Function(String event, Map<String, dynamic> params)>
      _sessionListeners = [];

  // Reconnect state (single long-lived SSE per active session, IM-style).
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  String? _subSid;

  // Stream dedup + run tracking. The server stamps each event with a stable
  // `eid` (dedup across the subscribe/replay overlap) and a per-turn `run_id`.
  // `_awaitingRun` is true from the moment a (re)connect is opened until the
  // first event arrives: at that point any stale streaming bubble from a
  // previous view of the session is discarded and rebuilt from the replay.
  final Set<String> _seenEids = <String>{};
  String? _activeRunId;
  bool _awaitingRun = false;

  static const int _maxReconnectAttempts = 10;
  static const Duration _initialReconnect = Duration(seconds: 1);
  static const Duration _maxReconnect = Duration(seconds: 30);
  // Idle probe cadence: refreshes the stream/server-side so a half-open
  // connection is detected before the UI can get stuck.
  static const Duration _idleProbeEvery = Duration(seconds: 30);
  Timer? _idleProbeTimer;
  DateTime _lastActivity = DateTime.now();

  List<ChatMessage> get sorted {
    final m = [...messages];
    m.sort(compareMessages);
    return m;
  }

  void Function() onSessionEvent(
      void Function(String event, Map<String, dynamic> params) cb) {
    _sessionListeners.add(cb);
    return () => _sessionListeners.remove(cb);
  }

  int _allocSeq() => _nextSeq++;

  void _bumpSeqAfter(List<ChatMessage> history) {
    var maxSeq = -1;
    for (final m in history) {
      final s = m.seq;
      if (s != null && s < _nextSeq && s > maxSeq) maxSeq = s;
    }
    if (maxSeq >= 0) _nextSeq = maxSeq + 1;
  }

  void init() {
    final sid = getSessionId();
    if (sid.isEmpty) return;
    _fetchMessages();
    _recover();
    _connect(sid);
  }

  void _markActivity() {
    _lastActivity = DateTime.now();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _idleProbeTimer?.cancel();
    _idleProbeTimer = null;
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  Future<void> _fetchMessages([String? before]) async {
    loading = true;
    notifyListeners();
    try {
      final sid = getSessionId();
      final (msgs, more) =
          await api.messages(sid, before: before, limit: 50);
      final chat = mapMessagesToChat(msgs);
      _bumpSeqAfter(chat);
      if (before != null) {
        final existing = messages.map((m) => m.id).toSet();
        messages = [...chat.where((m) => !existing.contains(m.id)), ...messages];
      } else {
        // Preserve locally-owned in-flight bubbles: the optimistic user
        // message (pending) AND any streaming assistant bubble built from the
        // live/replayed stream. Dropping the streaming one would erase the
        // replayed thinking/text accumulated before this fetch returned.
        final local = messages
            .where((m) => m.status == 'pending' || m.status == 'streaming')
            .toList();
        messages = [...local, ...chat];
      }
      hasMore = more;
    } catch (_) {}
    loading = false;
    // NOTE: no _syncIdle() here — a plain history fetch must not terminate an
    // active turn. Convergence to idle is driven by the stream's own
    // terminal events (and _onStreamClosed on drop / error).
    notifyListeners();
  }

  Future<void> _recover() async {
    try {
      final (status, _) = await api.state(getSessionId());
      if (status == 'busy' || status == 'running') {
        sending = true;
        // Don't add a second streaming bubble if the live/replayed stream
        // already created one (that would orphan it and keep a spinner
        // alongside real content).
        final hasStreaming = messages.any((m) => m.status == 'streaming');
        if (!hasStreaming) {
          _streamingId = 'recover-${DateTime.now().microsecondsSinceEpoch}';
          messages = [
            ...messages,
            ChatMessage(
                id: _streamingId!,
                role: 'assistant',
                status: 'streaming',
                parts: [],
                createdAt: DateTime.now().toIso8601String(),
                seq: _allocSeq()),
          ];
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _connect(String sid) {
    // Single long-lived SSE per active session (IM-style). Cancel any prior
    // stream + reconnect timers before opening the new one so a rapid
    // session switch never leaves a duplicate connection behind.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _subSid = sid;
    _reconnectAttempt = 0;
    _lastActivity = DateTime.now();
    _idleProbeTimer?.cancel();
    // Do NOT clear the streaming bubble here: the server may be replaying the
    // live run, and clearing before events arrive races the concurrent
    // history fetch. Instead, arm a run boundary: the FIRST event of the new
    // connection resets stale streaming state and starts building fresh.
    _seenEids.clear();
    _activeRunId = null;
    _awaitingRun = true;
    _sub = api.streamEvents(sid).listen(
      _handleEvent,
      onError: (_) => _onStreamClosed(sid),
      onDone: () => _onStreamClosed(sid),
      cancelOnError: false,
    );
    _startIdleProbe();
  }

  /// Drop the streaming bubble + its run linkage (used at a run boundary and
  /// before a revert re-fetch). History (complete) messages are untouched.
  void _clearStreaming() {
    _streamingId = null;
    _activeRunId = null;
    if (messages.any((m) => m.status == 'streaming')) {
      messages = messages.where((m) => m.status != 'streaming').toList();
    }
  }

  /// One stream closed (done/error). If it's still the active session, re-arm
  /// the SSE with exponential backoff and re-sync the conversation state so a
  /// half-open connection never leaves the UI stuck.
  void _onStreamClosed(String sid) {
    // Defensive: a stale/closed stream for a previous session must not touch
    // the current one's state.
    if (_subSid != null && _subSid != sid) return;
    _syncIdle();
    if (sid != getSessionId()) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) return;
    final delay = _initialReconnect * pow(2, _reconnectAttempt).toInt();
    final capped = delay > _maxReconnect ? _maxReconnect : delay;
    _reconnectAttempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(capped, () => _connect(sid));
  }

  void _startIdleProbe() {
    _idleProbeTimer?.cancel();
    _idleProbeTimer = Timer.periodic(_idleProbeEvery, (_) {
      if (DateTime.now().difference(_lastActivity) < _idleProbeEvery) return;
      // No events for a while: poke the session state so a half-open server
      // connection is detected / the server re-emits a status. This doubles as
      // the idle safety net now that history fetches no longer force idle: if
      // the server says the session is idle, converge the stream.
      api.state(getSessionId()).then((r) {
        final (st, _) = r;
        if (st == 'busy' || st == 'running') {
          if (!sending) {
            sending = true;
            notifyListeners();
          }
        } else {
          _syncIdle();
        }
      }).catchError((_) {});
    });
  }

  /// Converge to idle if the stream ended without a terminal `status idle` /
  /// `turn-complete`. The backend sends both; a dropped/reconnected stream is
  /// the only path that could leave `sending` stuck true.
  void _syncIdle() {
    if (!sending) return;
    _finishStreaming();
    notifyListeners();
  }

  void _handleEvent(StreamEvent ev) {
    _markActivity();
    // Dedup: the subscribe/replay handover overlaps, so the same eid can be
    // delivered twice. Drop repeats before they double-append deltas.
    if (ev.eid.isNotEmpty) {
      if (_seenEids.contains(ev.eid)) return;
      _seenEids.add(ev.eid);
      if (_seenEids.length > 20000) _seenEids.clear();
    }
    // Run boundary: the first event of a (re)connection (or the first event of
    // a NEW run) discards any stale/withdrawn streaming bubble so replay
    // rebuilds it cleanly. `status busy` is the canonical first event of a run.
    final run = ev.runId;
    if (_awaitingRun) {
      _awaitingRun = false;
      _clearStreaming();
    }
    if (run.isNotEmpty && run != _activeRunId) {
      // A different run started (or replay of the current one begins):
      // replace the previous run's placeholder bubble.
      if (_activeRunId != null) _clearStreaming();
      _activeRunId = run;
    }
    for (final cb in _sessionListeners) {
      try {
        cb(ev.event, ev.params);
      } catch (_) {}
    }
        final event = ev.event;
        final params = ev.params;
        switch (event) {
      case 'step-start':
      case 'text-start':
      case 'reasoning-start':
      case 'tool-input-start':
        final current = _streamingId != null
            ? messages.where((m) => m.id == _streamingId).firstOrNull
            : null;
        final hasToolPart =
            current?.parts.any((p) => p.type == 'tool') ?? false;
        final sid = _ensureStreamingMsg(
            event == 'step-start' || (event == 'text-start' && hasToolPart));
        if (event == 'text-start' && params['id'] != null) {
          _ensurePart(sid, params['id'] as String, 'text');
        } else if (event == 'reasoning-start' && params['id'] != null) {
          _ensurePart(sid, 'r${params['id']}', 'reasoning');
        }
        break;
      case 'text-delta':
        if (params['id'] != null && params['text'] != null) {
          final sid = _ensureStreamingMsg(false);
          _appendDelta(sid, params['id'] as String,
              params['text'] as String? ?? '', false);
        }
        break;
      case 'reasoning-delta':
        if (params['id'] != null && params['text'] != null) {
          final sid = _ensureStreamingMsg(false);
          _appendDelta(
              sid, 'r${params['id']}', params['text'] as String? ?? '', true);
        }
        break;
      case 'tool-call':
        final sid = _ensureStreamingMsg(false);
        final tcId = (params['toolCallId'] ?? params['id']) as String?;
        if (tcId != null) {
          _addToolPart(sid, tcId,
              (params['toolName'] ?? params['name'] ?? 'tool') as String,
              params['input']);
        }
        break;
      case 'tool-result':
        final tcId = (params['toolCallId'] ?? params['id']) as String?;
        if (tcId == null) break;
        _updateToolResult(tcId,
            params['formatted'] ?? params['output'] ?? params['result'],
            changeId: params['change_id'] as String?,
            diff: params['diff'] as String?,
            additions: params['additions'] as int?,
            deletions: params['deletions'] as int?);
        break;
      case 'tool-error':
        final tcId = (params['toolCallId'] ?? params['id']) as String?;
        final errObj = params['error'];
        final errMsg = errObj is String
            ? errObj
            : (errObj is Map
                ? (errObj['message'] ?? params['message'] ?? 'tool error')
                : (params['message'] ?? 'tool error')) as String;
        if (tcId != null) _updateToolResult(tcId, null, errorMsg: errMsg);
        break;
      case 'turn-complete':
        _finishStreaming();
        break;
      case 'status':
        final stype = params['type'];
        if (stype == 'busy' || stype == 'running') {
          sending = true;
          notifyListeners();
        } else {
          _finishStreaming();
        }
        break;
      case 'error':
      case 'provider-error':
        final errObj = params['error'];
        final content = errObj is String
            ? errObj
            : (errObj is Map
                ? (errObj['message'] ?? params['message'] ?? 'Unknown error')
                : (params['message'] ?? 'Unknown error')) as String;
        _addError(content);
        sending = false;
        notifyListeners();
        break;
      default:
        break;
    }
  }

  String _ensureStreamingMsg(bool forceNew) {
    // Reuse the current streaming bubble unless we are explicitly crossing a
    // step boundary AND it already holds content. This prevents orphaning an
    // empty bubble (e.g. the optimistic one from send() / recover()) when the
    // first step-start arrives — an orphaned empty bubble would keep the
    // "thinking…" spinner alive forever.
    if (_streamingId != null) {
      final idx = messages.indexWhere((m) => m.id == _streamingId);
      if (idx >= 0) {
        final existing = messages[idx];
        if (!forceNew || existing.parts.isEmpty) return _streamingId!;
      }
    }
    final id = 'm${DateTime.now().microsecondsSinceEpoch}';
    _streamingId = id;
    messages = [
      ...messages,
      ChatMessage(
          id: id,
          role: 'assistant',
          status: 'streaming',
          parts: [],
          createdAt: DateTime.now().toIso8601String(),
          seq: _allocSeq()),
    ];
    return id;
  }

  void _ensurePart(String msgId, String partId, String type) {
    final idx = messages.indexWhere((m) => m.id == msgId);
    if (idx < 0) return;
    if (messages[idx].parts.any((p) => p.id == partId)) return;
    final next = [...messages];
    next[idx] = messages[idx]
        .copyWith(parts: [...messages[idx].parts, ChatPart(id: partId, type: type)]);
    messages = next;
  }

  void _appendDelta(String msgId, String partId, String delta, bool reasoning) {
    final idx = messages.indexWhere((m) => m.id == msgId);
    if (idx < 0) return;
    final parts = [...messages[idx].parts];
    final pidx = parts.indexWhere((p) => p.id == partId);
    if (pidx >= 0) {
      parts[pidx] =
          parts[pidx].copyWith(text: (parts[pidx].text) + delta);
    } else {
      parts.add(ChatPart(id: partId, type: reasoning ? 'reasoning' : 'text', text: delta));
    }
    final next = [...messages];
    next[idx] = messages[idx].copyWith(parts: parts);
    messages = next;
    notifyListeners();
  }

  void _addToolPart(String msgId, String partId, String name, Object? input) {
    final idx = messages.indexWhere((m) => m.id == msgId);
    if (idx < 0) return;
    final parts = [...messages[idx].parts];
    final pidx = parts.indexWhere((p) => p.id == partId);
    if (pidx >= 0) {
      parts[pidx] = ChatPart(
          id: partId,
          type: 'tool',
          tool: name,
          state: ToolState(
              status: 'running', title: name, input: _asMap(input)));
    } else {
      parts.add(ChatPart(
          id: partId,
          type: 'tool',
          tool: name,
          state: ToolState(
              status: 'running', title: name, input: _asMap(input))));
    }
    final next = [...messages];
    next[idx] = messages[idx].copyWith(parts: parts);
    messages = next;
    notifyListeners();
  }

  void _updateToolResult(String partId, Object? result,
      {String? errorMsg, String? changeId, String? diff, int? additions, int? deletions}) {
    final sid = _streamingId;
    if (sid == null) return;
    final idx = messages.indexWhere((m) => m.id == sid);
    if (idx < 0) return;
    final parts = messages[idx].parts.map((p) {
      if (p.id != partId) return p;
      final old = p.state ?? ToolState();
      final output = result is String
          ? result
          : (result == null ? null : _pretty(result));
      return ChatPart(
        id: p.id,
        type: 'tool',
        tool: p.tool,
        state: ToolState(
          status: errorMsg != null ? 'error' : 'complete',
          title: old.title,
          error: errorMsg ?? old.error,
          input: old.input,
          output: output ?? old.output,
          changeId: changeId ?? old.changeId,
          diff: diff ?? old.diff,
          additions: additions ?? old.additions,
          deletions: deletions ?? old.deletions,
        ),
      );
    }).toList();
    final next = [...messages];
    next[idx] = messages[idx].copyWith(parts: parts);
    messages = next;
    notifyListeners();
  }

  void _finishStreaming() {
    // Complete EVERY streaming bubble, not just the current _streamingId:
    // defensive against any orphaned bubble left by a step boundary.
    final next = messages
        .map((m) => m.status == 'streaming' ? m.copyWith(status: 'complete') : m)
        .toList();
    messages = next;
    _streamingId = null;
    _activeRunId = null;
    sending = false;
    notifyListeners();
  }

  void _addError(String text) {
    messages = [
      ...messages.where((m) => m.status != 'streaming'),
      ChatMessage(
          id: 'err${DateTime.now().microsecondsSinceEpoch}',
          role: 'error',
          status: 'error',
          parts: [ChatPart(id: 'p${DateTime.now().microsecondsSinceEpoch}', type: 'text', text: text)],
          createdAt: DateTime.now().toIso8601String(),
          seq: _allocSeq()),
    ];
    _streamingId = null;
  }

  Future<void> send(String text, [List<UploadedFile> attachments = const []]) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && attachments.isEmpty) || sending) return;
    sending = true;
    // The platform splices attachment codes into `[附件 …file:<code>…]`
    // references; the client only sends the codes, never the rendered text.
    final codes = attachments.map((a) => a.code).toList();
    // Optimistic user message: file parts first (rendered as attachments),
    // then the text. Mirrors how the backend persists them.
    final userParts = <ChatPart>[
      for (final a in attachments)
        ChatPart(
          id: 'f${a.code}',
          type: 'file',
          code: a.code,
          name: a.name,
          mime: a.mime,
          size: a.size,
        ),
      if (trimmed.isNotEmpty)
        ChatPart(
          id: 'p${DateTime.now().microsecondsSinceEpoch}',
          type: 'text',
          text: trimmed),
    ];
    messages = [
      ...messages.where((m) => m.status != 'streaming'),
      ChatMessage(
          id: 'u${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          status: 'pending',
          parts: userParts,
          createdAt: DateTime.now().toIso8601String(),
          seq: _allocSeq()),
    ];
    final _ = _ensureStreamingMsg(true);
    notifyListeners();
    try {
      final messageId =
          await api.prompt(getSessionId(), trimmed, attachments: codes);
      if (messageId.isNotEmpty) {
        messages = messages.map((m) {
          if (m.status == 'pending' && m.role == 'user') {
            return m.copyWith(id: messageId, status: 'complete');
          }
          return m;
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      _addError(I18n.now.sendFailed('$e'));
      sending = false;
      notifyListeners();
    }
  }

  void stop() {
    api.interrupt(getSessionId()).then((_) => _finishStreaming());
  }

  Future<void> revert(String messageId) async {
    if (sending) {
      await api.interrupt(getSessionId());
    }
    // Undo moves the backend tip back (append-only chain). Drop any local
    // streaming bubble FIRST (it may hold now-withdrawn deltas) and re-fetch
    // the authoritative chain; otherwise the stale streaming bubble survives
    // the merge and keeps showing revoked content.
    await api.revert(getSessionId(), messageId);
    _clearStreaming();
    sending = false;
    await _fetchMessages();
  }

  Future<void> loadMore() async {
    if (!hasMore || loading) return;
    final first = sorted.firstOrNull;
    if (first == null) return;
    await _fetchMessages(first.id);
  }

  static Map<String, dynamic>? _asMap(Object? o) {
    if (o is Map) return o.cast<String, dynamic>();
    return null;
  }

  static String _pretty(Object o) {
    if (o is Map || o is List) {
      const enc = JsonEncoder.withIndent('  ');
      return enc.convert(o);
    }
    return o.toString();
  }
}

extension on List<ChatMessage> {
  ChatMessage? get firstOrNull => isEmpty ? null : first;
}

int compareMessages(ChatMessage a, ChatMessage b) {
  final at = a.seq ?? 1 << 60;
  final bt = b.seq ?? 1 << 60;
  if (at != bt) return at - bt;
  final apt = DateTime.tryParse(a.createdAt)?.millisecondsSinceEpoch ?? 0;
  final bpt = DateTime.tryParse(b.createdAt)?.millisecondsSinceEpoch ?? 0;
  if (apt != 0 && bpt != 0 && apt != bpt) return apt - bpt;
  return a.id.compareTo(b.id);
}

List<ChatMessage> mapMessagesToChat(List<Message> msgs) {
  return [for (var i = 0; i < msgs.length; i++) _toChat(msgs[i], i)];
}

ChatMessage _toChat(Message m, int i) {
  return ChatMessage(
    id: m.id,
    role: m.role,
    status: 'complete',
    createdAt: m.createdAt ?? '',
    seq: i,
    parts: [
      for (final p in m.parts)
        ChatPart(
          id: p.id.isNotEmpty ? p.id : 'p${DateTime.now().microsecondsSinceEpoch}$i',
          type: p.type,
          text: p.text ?? '',
          tool: p.tool ?? '',
          state: p.state,
          code: p.code,
          name: p.name,
          mime: p.mime,
          size: p.size,
        ),
    ],
  );
}

