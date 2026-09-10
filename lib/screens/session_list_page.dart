import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme/app_theme.dart';
import '../i18n.dart';
import '../widgets/dialogs.dart';
import '../widgets/session_row.dart';

/// Session list page (chat tab root): AppBar title + search + "+" create, and
/// the IM-style recent-sessions list (avatar + name + relative time + preview
/// + local unread dot). Selecting a session opens the conversation.
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
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => store.refreshSessions());
    // Keep previews / unread dots fresh while the list is visible.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) store.refreshSessions();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    store.removeListener(_onStore);
    _q.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  List<Session> get _sorted {
    final all = [...store.sessions];
    all.sort((a, b) {
      final at = DateTime.tryParse(
              a.lastMessageAt.isNotEmpty ? a.lastMessageAt : a.updatedAt)
          ?.millisecondsSinceEpoch ??
          0;
      final bt = DateTime.tryParse(
              b.lastMessageAt.isNotEmpty ? b.lastMessageAt : b.updatedAt)
          ?.millisecondsSinceEpoch ??
          0;
      return bt - at;
    });
    return all;
  }

  List<Session> get _filtered {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return _sorted;
    return _sorted
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.recent,
                    style: text.micro.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: colors.mutedForeground),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => store.refreshSessions(),
              child: sessions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(context.l10n.noSessions,
                                style: text.meta
                                    .copyWith(color: colors.mutedForeground)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        final active = s.id == store.activeSessionId;
                        final preview = s.lastMessagePreview.isNotEmpty
                            ? s.lastMessagePreview
                            : s.id;
                        return SessionRow(
                          key: ValueKey(s.id),
                          session: s,
                          isActive: active,
                          subtitle: preview,
                          unread: store.isUnread(s),
                          onTap: () => store.pickSession(s.id),
                          onLongPress: () => _sessionActions(s),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Long-press bottom sheet: delete (and mark-read when unread).
  void _sessionActions(Session s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (store.isUnread(s))
              ListTile(
                leading: const Icon(Icons.done_all_rounded),
                title: Text(ctx.l10n.markRead),
                onTap: () {
                  store.markSessionRead(s.id);
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: colorsOf(ctx).destructive),
              title: Text(ctx.l10n.deleteSession,
                  style: TextStyle(color: colorsOf(ctx).destructive)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteSessionFlow(s);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSessionFlow(Session s) async {
    final ok = await confirmDialog(context,
        title: context.l10n.deleteSessionTitle,
        description: context.l10n.deleteSessionBody(s.id));
    if (ok != true) return;
    try {
      await store.deleteSession(s.id);
    } catch (_) {}
  }
}
