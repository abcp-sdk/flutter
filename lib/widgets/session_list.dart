import 'package:flutter/material.dart';

import '../agent_store.dart';
import '../l10n/app_localizations.dart';

/// Session list pane (no AppBar; used in both drawer and sidebar).
class SessionListPane extends StatelessWidget {
  final AgentStore store;
  final void Function(String id) onSelect;
  final VoidCallback onCreate;
  final void Function(String id) onRename;
  final void Function(String id) onFork;
  final void Function(String id) onDelete;

  const SessionListPane({
    super.key,
    required this.store,
    required this.onSelect,
    required this.onCreate,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l.newSession),
          onTap: onCreate,
        ),
        const Divider(height: 1),
        Expanded(
          child: store.sessions.isEmpty
              ? Center(child: Text(l.noSessions))
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
                          if (v == 'fork') onFork(s.id);
                          if (v == 'rename') onRename(s.id);
                          if (v == 'delete') onDelete(s.id);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'fork', child: Text(l.fork)),
                          PopupMenuItem(value: 'rename', child: Text(l.rename)),
                          PopupMenuItem(value: 'delete', child: Text(l.delete)),
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
