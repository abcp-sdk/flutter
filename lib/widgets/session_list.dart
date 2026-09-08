import 'package:flutter/material.dart';

import '../agent_store.dart';

/// Session list pane (no AppBar; used in both drawer and sidebar).
class SessionListPane extends StatelessWidget {
  final AgentStore store;
  final void Function(String id) onSelect;
  final VoidCallback onCreate;
  final void Function(String id) onRename;
  final void Function(String id) onDelete;

  const SessionListPane({
    super.key,
    required this.store,
    required this.onSelect,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New session'),
          onTap: onCreate,
        ),
        const Divider(height: 1),
        Expanded(
          child: store.sessions.isEmpty
              ? const Center(child: Text('No sessions'))
              : ListView.builder(
                  itemCount: store.sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = store.sessions[i];
                    final active = s.id == store.activeId;
                    return ListTile(
                      selected: active,
                      title: Text(s.title.isEmpty ? s.id : s.title),
                      subtitle: s.preview.isEmpty
                          ? null
                          : Text(s.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      onTap: () => onSelect(s.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'rename') onRename(s.id);
                          if (v == 'delete') onDelete(s.id);
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
