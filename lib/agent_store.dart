import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:agent_client_sdk/agent_client_sdk.dart' as sdk;

import 'agent_api.dart';

/// A display message the shell renders (kept free of SDK types).
class MessageDisplay {
  final String id;
  final String role;
  final String text;
  final String reasoning;
  final List<ToolDisplay> tools;
  final bool streaming;
  MessageDisplay({
    required this.id,
    required this.role,
    required this.text,
    required this.reasoning,
    required this.tools,
    required this.streaming,
  });
  MessageDisplay copyWith({String? text, String? reasoning, List<ToolDisplay>? tools}) =>
      MessageDisplay(
        id: id,
        role: role,
        text: text ?? this.text,
        reasoning: reasoning ?? this.reasoning,
        tools: tools ?? this.tools,
        streaming: streaming,
      );
}

class ToolDisplay {
  final String id;
  final String name;
  final String output;
  ToolDisplay(this.id, this.name, this.output);
}

/// Single agent store: sessions + active chat + watchSession stream + theme.
/// No polling — streaming drives updates.
class AgentStore extends ChangeNotifier {
  AgentStore({required this.api}) {
    refreshSessions();
    _loadMeta();
    _platformMe();
  }

  final AgentApi api;

  List<SessionView> sessions = [];
  String activeId = '';
  List<MessageDisplay> messages = [];
  bool sending = false;
  bool loading = false;

  StreamSubscription<StreamEvent>? _sub;

  // ---- responsive ----
  bool? isCompact;
  void setViewport(bool value) {
    if (isCompact == value) return;
    isCompact = value;
    notifyListeners();
  }

  // ---- theme: light | dark | system ----
  String _theme = 'system';
  String get theme => _theme;
  void setTheme(String t) {
    _theme = t;
    notifyListeners();
  }
  void _platformMe() {} // platform brightness read by the shell via MediaQuery

  Future<void> _loadMeta() async {
    try {
      await api.health();
    } catch (_) {}
  }

  Future<void> refreshSessions() async {
    try {
      sessions = await api.listSessions();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> selectSession(String id) async {
    activeId = id;
    loading = true;
    stopStream();
    notifyListeners();
    try {
      final chat = await api.messages(id, limit: 50);
      messages = chat.map(_toDisplay).toList();
    } finally {
      loading = false;
      notifyListeners();
    }
    startStream(id);
  }

  void startStream(String id) {
    stopStream();
    _sub = api.streamEvents(id).listen(_handleEvent,
        onError: (_) {}, onDone: () {});
  }

  void stopStream() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleEvent(StreamEvent ev) {
    final p = ev.params;
    switch (ev.event) {
      case 'text-delta':
        _appendDelta(p['id']?.toString() ?? '', p['text']?.toString() ?? '', false);
        break;
      case 'reasoning-delta':
        _appendDelta(p['id']?.toString() ?? '', p['text']?.toString() ?? '', true);
        break;
      case 'tool-call':
        _ensureTool((p['toolCallId'] ?? p['id'] ?? '').toString(),
            (p['toolName'] ?? p['name'] ?? 'tool').toString());
        break;
      case 'tool-result':
      case 'tool-error':
        _toolResult((p['toolCallId'] ?? p['id'] ?? '').toString(),
            (p['formatted'] ?? p['output'] ?? p['result'] ?? '').toString());
        break;
      case 'turn-complete':
        _finish();
        break;
      case 'status':
        final t = p['type']?.toString();
        if (t == 'busy' || t == 'running') {
          sending = true;
          notifyListeners();
        } else {
          _finish();
        }
        break;
      case 'error':
      case 'provider-error':
        _finish();
        break;
      default:
        break;
    }
  }

  MessageDisplay _toDisplay(ChatMessage m) {
    var text = '';
    var reasoning = '';
    final tools = <ToolDisplay>[];
    for (final part in m.parts) {
      if (part.type == 'text') {
        text += part.data;
      } else if (part.type == 'reasoning') {
        reasoning += part.data;
      } else if (part.type == 'tool') {
        var name = part.data;
        var output = '';
        try {
          final j = jsonDecode(part.data);
          name = (j is Map ? j['toolName'] ?? j['name'] ?? name : name).toString();
          output =
              (j is Map ? j['formatted'] ?? j['output'] ?? j['result'] ?? '' : '').toString();
        } catch (_) {}
        tools.add(ToolDisplay(part.id, name, output));
      }
    }
    return MessageDisplay(
        id: m.id, role: m.role, text: text, reasoning: reasoning, tools: tools, streaming: false);
  }

  void _ensureStreaming() {
    if (messages.isNotEmpty && messages.last.streaming) return;
    messages = [
      ...messages,
      MessageDisplay(id: '__stream', role: 'assistant', text: '', reasoning: '', tools: [], streaming: true)
    ];
    sending = true;
    notifyListeners();
  }

  void _appendDelta(String pid, String text, bool reasoning) {
    _ensureStreaming();
    final last = messages.last;
    messages = [
      ...messages.sublist(0, messages.length - 1),
      reasoning ? last.copyWith(reasoning: last.reasoning + text) : last.copyWith(text: last.text + text)
    ];
    notifyListeners();
  }

  void _ensureTool(String id, String name) {
    _ensureStreaming();
    final last = messages.last;
    if (last.tools.any((t) => t.id == id)) {
      return;
    }
    messages = [
      ...messages.sublist(0, messages.length - 1),
      last.copyWith(tools: [...last.tools, ToolDisplay(id, name, '')])
    ];
    notifyListeners();
  }

  void _toolResult(String id, String output) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      final idx = m.tools.indexWhere((t) => t.id == id);
      if (idx >= 0) {
        final tools = [...m.tools];
        tools[idx] = ToolDisplay(id, m.tools[idx].name, output);
        messages = [...messages.sublist(0, i), m.copyWith(tools: tools), ...messages.sublist(i + 1)];
        notifyListeners();
        return;
      }
    }
  }

  void _finish() {
    sending = false;
    messages = messages.where((m) => !m.streaming).toList();
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (activeId.isEmpty) return;
    final t = text.trim();
    if (t.isEmpty) return;
    sending = true;
    messages = [
      ...messages,
      MessageDisplay(id: '__user', role: 'user', text: t, reasoning: '', tools: [], streaming: false)
    ];
    notifyListeners();
    try {
      await api.prompt(activeId, t);
    } catch (_) {}
  }

  Future<void> createSession({String? name}) async {
    await api.createSession(name: name);
    await refreshSessions();
  }

  Future<void> deleteSession(String id) async {
    await api.deleteSession(id);
    if (activeId == id) {
      stopStream();
      activeId = '';
      messages = [];
    }
    await refreshSessions();
  }

  Future<void> renameSession(String id, String next) async {
    await api.renameSession(id, next);
    if (activeId == id) activeId = next;
    await refreshSessions();
  }

  Future<List<sdk.ModelInfo>> models() => api.listModels();
  Future<List<sdk.Preset>> presets() => api.listPresets();
  Future<void> switchModel(String m) => api.switchModel(activeId, m);
  Future<void> setPreset(String p) => api.updateSettings(activeId, preset: p);
  Future<void> interrupt() => api.interrupt(activeId);
  Future<void> compact() => api.compact(activeId);

  @override
  void dispose() {
    stopStream();
    super.dispose();
  }
}
