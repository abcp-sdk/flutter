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

  // Batch selection: entered via the app-bar checkmark. While active, row taps
  // toggle membership and the app bar exposes select-all + delete.
  bool _selectMode = false;
  final Set<String> _selected = {};

  // Subsession tree: parents with children are COLLAPSED by default; the set
  // holds the ids the user manually expanded (memory-only by design).
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    // The session list is driven by the store's watchSessions stream; this is
    // just a first reconciliation in case the stream hasn't emitted yet.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => store.refreshSessions(),
    );
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

  void _enterSelect() {
    setState(() {
      _selectMode = true;
      _searching = false;
      _q.clear();
      _selected.clear();
    });
  }

  void _exitSelect() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _toggleAll() {
    setState(() {
      // Select-all covers every visible row, subsessions included.
      final ids = _display.map((s) => s.id).toSet();
      if (_selected.length == ids.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final n = _selected.length;
    final ok = await confirmDialog(
      context,
      title: context.l10n.deleteSessionsTitle,
      description: context.l10n.deleteSessionsBody('$n'),
    );
    if (ok != true) return;
    final ids = _selected.toList();
    final failed = await store.deleteSessions(ids);
    if (!mounted) return;
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
    if (failed.isNotEmpty) {
      showErrorToast(context, context.l10n.failed('${failed.length}'));
    }
  }

  List<Session> get _sorted {
    final all = [...store.sessions];
    all.sort((a, b) {
      final at =
          DateTime.tryParse(
            a.lastMessageAt.isNotEmpty ? a.lastMessageAt : a.updatedAt,
          )?.millisecondsSinceEpoch ??
          0;
      final bt =
          DateTime.tryParse(
            b.lastMessageAt.isNotEmpty ? b.lastMessageAt : b.updatedAt,
          )?.millisecondsSinceEpoch ??
          0;
      return bt - at;
    });
    return all;
  }

  List<Session> get _filtered {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return _sorted;
    return _sorted
        .where(
          (s) =>
              s.id.toLowerCase().contains(q) ||
              s.lastMessagePreview.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Build the rendered list: top-level sessions ordered by recency with their
  /// subsessions (group == parent id) nested below them when expanded.
  /// Depth is 1 by protocol; children of missing parents are promoted to the
  /// top level so nothing disappears. While searching, the list stays flat so
  /// subsessions remain findable by name.
  List<Session> get _display {
    final sessions = _filtered;
    if (_searching) return sessions;
    final byId = {for (final s in sessions) s.id: s};
    final childrenOf = <String, List<Session>>{};
    final top = <Session>[];
    for (final s in sessions) {
      final parent = s.group;
      if (parent.isNotEmpty && byId.containsKey(parent)) {
        childrenOf.putIfAbsent(parent, () => []).add(s);
      } else {
        // Top-level session or an orphaned subsession (parent gone).
        top.add(s);
      }
    }
    final out = <Session>[];
    for (final s in top) {
      out.add(s);
      final kids = childrenOf[s.id];
      if (kids != null && kids.isNotEmpty && _expanded.contains(s.id)) {
        out.addAll(kids);
      }
    }
    return out;
  }

  int _childCount(String id) {
    final sessions = _filtered;
    var n = 0;
    for (final s in sessions) {
      if (s.group == id) n++;
    }
    return n;
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
    final sessions = _display;
    return PopScope(
      // Back exits selection/search instead of leaving the tab.
      canPop: !_selectMode && !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectMode) {
          _exitSelect();
        } else if (_searching) {
          _q.clear();
          setState(() => _searching = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _selectMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: context.l10n.cancel,
                  onPressed: _exitSelect,
                )
              : _searching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    _q.clear();
                    setState(() => _searching = false);
                  },
                )
              : null,
          title: _selectMode
              ? Text(context.l10n.selectedCount('${_selected.length}'))
              : _searching
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
          actions: _selectMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded),
                    tooltip: context.l10n.selectAll,
                    onPressed: _toggleAll,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: _selected.isEmpty
                          ? colors.mutedForeground
                          : colors.destructive,
                    ),
                    tooltip: context.l10n.delete,
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                ]
              : [
                  if (!_searching)
                    IconButton(
                      icon: Icon(Icons.search_rounded, color: colors.primary),
                      tooltip: context.l10n.search,
                      onPressed: () => setState(() => _searching = true),
                    ),
                  IconButton(
                    icon: Icon(Icons.checklist_rounded, color: colors.primary),
                    tooltip: context.l10n.selectSessions,
                    onPressed: _enterSelect,
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
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.recent,
                      style: text.micro.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: colors.mutedForeground,
                      ),
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
                              child: Text(
                                context.l10n.noSessions,
                                style: text.meta.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
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
                          final isChild = _searching
                              ? false
                              : s.group.isNotEmpty &&
                                    sessions.any((p) => p.id == s.group);
                          final childCount = isChild || _searching
                              ? 0
                              : _childCount(s.id);
                          final expanded = _expanded.contains(s.id);
                          return SessionRow(
                            key: ValueKey(s.id),
                            session: s,
                            isActive: active,
                            subtitle: preview,
                            unread: store.isUnread(s),
                            unreadCount: store.unreadCountFor(s),
                            selectable: _selectMode,
                            selected: _selected.contains(s.id),
                            childCount: childCount,
                            expanded: expanded,
                            isChild: isChild,
                            onToggleExpand: childCount > 0
                                ? () => setState(() {
                                    if (!_expanded.remove(s.id)) {
                                      _expanded.add(s.id);
                                    }
                                  })
                                : null,
                            onTap: _selectMode
                                ? () => _toggle(s.id)
                                : () => store.pickSession(s.id),
                            onLongPress: _selectMode
                                ? null
                                : () => _sessionActions(s),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
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
              leading: Icon(
                Icons.delete_outline_rounded,
                color: colorsOf(ctx).destructive,
              ),
              title: Text(
                ctx.l10n.deleteSession,
                style: TextStyle(color: colorsOf(ctx).destructive),
              ),
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
    final ok = await confirmDialog(
      context,
      title: context.l10n.deleteSessionTitle,
      description: context.l10n.deleteSessionBody(s.id),
    );
    if (ok != true) return;
    try {
      await store.deleteSession(s.id);
    } catch (_) {}
  }
}
