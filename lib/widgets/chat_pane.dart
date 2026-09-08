import 'package:flutter/material.dart';

import '../agent_store.dart';
import '../l10n/app_localizations.dart';

/// Chat view: settings bar (model/preset/stop/compact) + messages + composer.
class ChatPane extends StatefulWidget {
  final AgentStore store;
  const ChatPane({super.key, required this.store});

  @override
  State<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<ChatPane> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<String> _models = [];
  List<String> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final models = await widget.store.models();
      final presets = await widget.store.presets();
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
    if (text.isEmpty) return;
    _input.clear();
    await widget.store.send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final l = AppLocalizations.of(context);
        return Column(
          children: [
            // Settings bar
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: Text(l.model),
                    value: null,
                    items: _models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await store.switchModel(v);
                      await _loadMeta();
                    },
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    hint: Text(l.preset),
                    items: _presets
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) async {
                      if (v == null) return;
                      await store.setPreset(v);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.stop), tooltip: l.interrupt,
                      onPressed: () => store.interrupt()),
                  IconButton(
                      icon: const Icon(Icons.compress), tooltip: l.compact,
                      onPressed: () => store.compact()),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: store.messages.isEmpty && store.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: store.messages.length,
                      itemBuilder: (ctx, i) {
                        final m = store.messages[i];
                        return _MessageBubble(m: m);
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
                      decoration: InputDecoration(hintText: l.messagePlaceholder),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: store.sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDisplay m;
  const _MessageBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final isUser = m.role == 'user';
    final bubbleWidth = MediaQuery.of(context).size.width < 600
        ? MediaQuery.of(context).size.width * 0.86
        : 640.0;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: bubbleWidth),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in m.tools)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('[tool] ${t.name}\n${t.output}',
                    style: const TextStyle(color: Colors.amber, fontSize: 12)),
              ),
            if (m.text.isNotEmpty) SelectableText(m.text),
            if (m.streaming)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('…'),
              ),
          ],
        ),
      ),
    );
  }
}
