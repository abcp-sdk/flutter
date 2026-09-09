import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../i18n.dart';
import '../widgets/dialogs.dart';

/// Session list page (chat tab root): session list + create/fork/delete.
/// Selecting a session opens the conversation.
class SessionListPage extends StatefulWidget {
  final AppStore store;
  const SessionListPage({super.key, required this.store});

  @override
  State<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends State<SessionListPage> {
  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    store.refreshSessions();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final name = await promptDialog(context, title: context.l10n.newSession);
    if (name == null || name.trim().isEmpty) return;
    await store.api.createSession({'name': name.trim()});
    await store.refreshSessions();
  }

  Future<void> _fork(Session s) async {
    final name = await promptDialog(context, title: context.l10n.fork);
    if (name == null || name.trim().isEmpty) return;
    await store.api.fork(s.id, name.trim());
    await store.refreshSessions();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    final sessions = store.sessions;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: OutlinedButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(context.l10n.newSession),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Text(context.l10n.noSessions,
                      style: text.meta
                          .copyWith(color: colors.mutedForeground)))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (ctx, i) {
                    final s = sessions[i];
                    final active = s.id == store.activeSessionId;
                    return ListTile(
                      selected: active,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(s.id, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: s.lastMessagePreview.isEmpty
                          ? null
                          : Text(s.lastMessagePreview,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'fork') _fork(s);
                          if (v == 'delete') {
                            store.deleteSession(s.id);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'fork', child: Text(context.l10n.fork)),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.deleteSession)),
                        ],
                      ),
                      onTap: () => store.pickSession(s.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
