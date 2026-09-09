import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../i18n.dart';
import '../widgets/dialogs.dart';

/// Session list page (chat tab root): AppBar "会话" + search + "+" create, and
/// the recent-sessions list. Selecting a session opens the conversation.
class SessionListPage extends StatefulWidget {
  final AppStore store;
  const SessionListPage({super.key, required this.store});

  @override
  State<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends State<SessionListPage> {
  AppStore get store => widget.store;

  bool _searching = false;
  final TextEditingController _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    store.refreshSessions();
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _q.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  List<Session> get _filtered {
    final all = store.sessions;
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.id.toLowerCase().contains(q) ||
            s.lastMessagePreview.toLowerCase().contains(q))
        .toList();
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
    final sessions = _filtered;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _searching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  _q.clear();
                  setState(() => _searching = false);
                },
              )
            : null,
        title: _searching
            ? TextField(
                controller: _q,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              )
            : Text(context.l10n.tabChat),
        actions: [
          if (!_searching)
            IconButton(
              icon: Icon(Icons.search_rounded, color: colors.primary),
              tooltip: context.l10n.search,
              onPressed: () => setState(() => _searching = true),
            ),
          IconButton(
            icon: Icon(Icons.add_rounded, color: colors.primary),
            tooltip: context.l10n.newSession,
            onPressed: _create,
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child:
                        Text(context.l10n.noSessions,
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
                                value: 'fork',
                                child: Text(context.l10n.fork)),
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
      ),
    );
  }
}
