import 'package:flutter/material.dart';

import 'agent_api.dart';

/// Left pane: list of sessions with create/delete/rename/fork.
class SessionList extends StatefulWidget {
  final AgentApi api;
  final String? active;
  final ValueChanged<String>? onSelect;
  const SessionList({super.key, required this.api, this.active, this.onSelect});

  @override
  State<SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<SessionList> {
  List<SessionView> _sessions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await widget.api.listSessions();
      if (mounted) setState(() => _sessions = s);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('load failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final name = await _promptName('New session');
    if (name == null) return;
    try {
      await widget.api.createSession(name: name);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('create failed: $e')));
      }
    }
  }

  Future<String?> _promptName(String title) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (b) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(b).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(b).pop(c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return v;
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (b) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(id),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(b).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(b).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.deleteSession(id);
      if (widget.active == id) widget.onSelect?.call('');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('delete failed: $e')));
      }
    }
  }

  Future<void> _rename(String id) async {
    final name = await _promptName('Rename session');
    if (name == null) return;
    try {
      await widget.api.renameSession(id, name);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('rename failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New session'),
          onTap: _create,
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = _sessions[i];
                    return ListTile(
                      selected: s.id == widget.active,
                      title: Text(s.title.isEmpty ? s.id : s.title),
                      subtitle:
                          s.preview.isEmpty ? null : Text(s.preview, maxLines: 1),
                      onTap: () => widget.onSelect?.call(s.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'rename') _rename(s.id);
                          if (v == 'delete') _delete(s.id);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'rename', child: Text('Rename')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
