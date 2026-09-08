import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'agent_api.dart';

/// Holder for a session's messages + live streaming state.
class ChatController extends ChangeNotifier {
  final AgentApi api;
  final String sessionId;
  ChatController({required this.api, required this.sessionId}) {
    _connect();
  }

  List<ChatMessage> messages = [];
  bool sending = false;
  bool loading = false;
  StreamSubscription<StreamEvent>? _sub;

  Future<void> _connect() async {
    loading = true;
    notifyListeners();
    try {
      messages = await api.messages(sessionId, limit: 50);
    } catch (_) {}
    loading = false;
    notifyListeners();
    _sub = api.streamEvents(sessionId).listen(_handle, onError: (_) {}, onDone: () {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handle(StreamEvent ev) {
    final params = ev.params;
    switch (ev.event) {
      case 'text-delta':
        _append(params['id']?.toString() ?? '', params['text']?.toString() ?? '');
        break;
      case 'reasoning-delta':
        _append(params['id']?.toString() ?? '', params['text']?.toString() ?? '', reasoning: true);
        break;
      case 'tool-call':
        final id = (params['toolCallId'] ?? params['id']).toString();
        _ensureTool(id, params['toolName']?.toString() ?? 'tool');
        break;
      case 'tool-result':
      case 'tool-error':
        final id = (params['toolCallId'] ?? params['id']).toString();
        _toolResult(id, params['formatted']?.toString() ?? params['output']?.toString() ?? '');
        break;
      case 'turn-complete':
        _finish();
        break;
      case 'status':
        final t = params['type']?.toString();
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

  void _append(String pid, String text, {bool reasoning = false}) {
    final key = reasoning ? 'r$pid' : pid;
    final m = _ensureStreaming();
    var part = m.parts.where((p) => p.id == key).firstOrNull;
    if (part == null) {
      part = PartView(id: key, type: reasoning ? 'reasoning' : 'text', data: '');
      m.parts.add(part);
    }
    final i = m.parts.indexOf(part);
    m.parts[i] = PartView(id: key, type: part.type, data: part.data + text);
    messages = [...messages];
    notifyListeners();
  }

  void _ensureTool(String id, String name) {
    final m = _ensureStreaming();
    if (m.parts.any((p) => p.id == id && p.type == 'tool')) return;
    m.parts.add(PartView(id: id, type: 'tool', data: name));
    messages = [...messages];
    notifyListeners();
  }

  void _toolResult(String id, String output) {
    final m = messages.lastOrNull;
    if (m == null) return;
    for (var i = 0; i < m.parts.length; i++) {
      final p = m.parts[i];
      if (p.id == id && p.type == 'tool') {
        m.parts[i] = PartView(id: id, type: 'tool', data: output);
        break;
      }
    }
    messages = [...messages];
    notifyListeners();
  }

  ChatMessage _ensureStreaming() {
    if (messages.isNotEmpty && messages.last.status == 'streaming') {
      return messages.last;
    }
    final m = ChatMessage(
      id: 'stream-${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      status: 'streaming',
      parts: [],
      seq: messages.length,
    );
    messages = [...messages, m];
    sending = true;
    return m;
  }

  void _finish() {
    sending = false;
    final last = messages.lastOrNull;
    if (last != null && last.status == 'streaming') {
      final i = messages.indexOf(last);
      messages[i] = ChatMessage(
        id: last.id, role: last.role, status: 'done', parts: last.parts, seq: last.seq);
    }
    messages = [...messages];
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    messages = [
      ...messages,
      ChatMessage(
          id: 'u-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          status: 'done',
          parts: [PartView(id: 'text-0', type: 'text', data: text)],
          seq: messages.length),
    ];
    notifyListeners();
    try {
      await api.prompt(sessionId, text);
    } catch (_) {}
  }
}

/// Right pane: chat + a small settings bar (model/preset switch).
class ChatPane extends StatefulWidget {
  final AgentApi api;
  final String sessionId;
  const ChatPane({super.key, required this.api, required this.sessionId});

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  late ChatController? _controller;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<String> _models = [];
  List<String> _presets = [];

  @override
  void initState() {
    super.initState();
    _open(widget.sessionId);
  }

  @override
  void didUpdateWidget(covariant ChatPane old) {
    super.didUpdateWidget(old);
    if (old.sessionId != widget.sessionId) {
      _open(widget.sessionId);
    }
  }

  void _open(String sid) async {
    _controller?.dispose();
    final c = ChatController(api: widget.api, sessionId: sid);
    setState(() => _controller = c);
    await _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final models = await widget.api.listModels();
      final presets = await widget.api.listPresets();
      if (mounted) {
        setState(() {
          _models = models.map((m) => m.id).toList();
          _presets = presets.map((p) => p.id).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _controller == null) return;
    _input.clear();
    await _controller!.send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return const Center(child: Text('Select or create a session'));
    }
    return Column(
      children: [
        // Settings bar: model + preset + interrupt/compact.
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              DropdownButton<String>(
                hint: const Text('model'),
                value: null,
                items: _models
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await widget.api.switchModel(widget.sessionId, v);
                  await _loadMeta();
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                hint: const Text('preset'),
                items: _presets
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await widget.api.updateSettings(widget.sessionId, preset: v);
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.stop),
                tooltip: 'Interrupt',
                onPressed: () async => widget.api.interrupt(widget.sessionId),
              ),
              IconButton(
                icon: const Icon(Icons.compress),
                tooltip: 'Compact',
                onPressed: () async => widget.api.compact(widget.sessionId),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListenableBuilder(
            listenable: c,
            builder: (_, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scroll.hasClients) {
                  _scroll.jumpTo(_scroll.position.maxScrollExtent);
                }
              });
              if (c.messages.isEmpty && c.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: c.messages.length,
                itemBuilder: (ctx, i) {
                  final m = c.messages[i];
                  return _MessageBubble(m: m);
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(hintText: 'Message'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _controller?.sending == true ? null : _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage m;
  const _MessageBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final isUser = m.role == 'user';
    final text = m.text;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo.shade600 : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in m.parts.where((p) => p.type == 'tool'))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('[tool] ${p.data}',
                    style: const TextStyle(color: Colors.amber, fontSize: 12)),
              ),
            if (text.isNotEmpty)
              MarkdownBody(data: text),
          ],
        ),
      ),
    );
  }
}
