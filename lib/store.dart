import 'package:flutter/foundation.dart';

import 'api.dart';
import 'enums.dart';
import 'models.dart';
import 'navigation.dart';

/// Mirrors stores.svelte.ts: app-wide state + repository/file-outlook caching.
class AppStore extends ChangeNotifier {
  AppStore(this.api);

  final AgentBindApi api;

  SiderTab siderTab = SiderTab.chat;
  List<Session> sessions = [];
  String? activeSessionId;
  SessionOverlay? sessionOverlay;
  
  // timeline drill-in
  
  // files overlay drill-in
  
                
  // file history / diff

  int sessionRevision = 0;

  /// Last sessions-list load error ('' when healthy). Surfaced as a banner
  /// instead of silently showing an empty list.
  String sessionError = '';

  Session? get activeSession {
    for (final s in sessions) {
      if (s.id == activeSessionId) return s;
    }
    return null;
  }

  Session? sessionById(String id) {
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> refreshSessions() async {
    try {
      sessions = await api.listSessions();
      sessionError = '';
    } catch (e) {
      // Keep the stale list but surface the failure so the UI can show a
      // banner instead of a misleading "empty" state.
      sessionError = '$e';
    }
    notifyListeners();
  }

  List<String> get existingBranchs =>
      sessions.map((s) => s.branch).toList();

  Future<void> deleteSession(String id) async {
    await api.deleteSession(id);
    if (activeSessionId == id) activeSessionId = null;
    await refreshSessions();
  }

  Future<bool> forkSession(String branch) async {
    final id = sessionById(activeSessionId ?? '')?.id;
    if (id == null) return false;
    try {
      final s = await api.fork(id, branch);
      activeSessionId = s.id;
      await refreshSessions();
      return true;
    } catch (_) {
      return false;
    }
  }

  void pickSession(String id) {
    activeSessionId = id;
    sessionOverlay = null;
    markSessionRead(id);
    // Open the conversation as a page in the chat stack.
    pushPage(ChatSessionPage());
  }

  /// Open a repo in the code tab at the top of its stack.
  /// Optimistically clear the local badge; the platform records the read
  /// watermark server-side.
  void markSessionRead(String id) {
    sessions = sessions
        .map((s) => s.id == id ? s.copyWith(unreadCount: 0) : s)
        .toList();
    notifyListeners();
    api.markRead(id).catchError((_) {});
  }

  void openOverlay(SessionOverlay v) {
    if (activeSessionId == null) return;
    sessionOverlay = v;
    notifyListeners();
  }

  void closeOverlay() {
    sessionOverlay = null;
    notifyListeners();
  }

  void closeSession() {
    activeSessionId = null;
    sessionOverlay = null;
    notifyListeners();
  }

  void bumpSessionRevision() {
    sessionRevision += 1;
    notifyListeners();
  }

  void switchTab(SiderTab tab) {
    siderTab = tab;
    notifyListeners();
  }

  // ---- Navigation stack (per tab) ----------------------------------------

  /// Read-only view of the current tab's navigation stack. Populated lazily
  /// by [ensureRoot] on first access; phone renders the top entry, tablets the
  /// last two. Switching tabs preserves each tab's depth (never reset).
  final Map<SiderTab, List<AppPage>> _stacks = {};

  List<AppPage> _stackFor(SiderTab tab) =>
      _stacks.putIfAbsent(tab, () => [rootPageFor(tab)]);

  List<AppPage> get currentStack => _stackFor(siderTab);

  AppPage get topPage => currentStack.last;

  /// Push a page onto the current tab's stack. If a page with the same key
  /// already exists it is replaced at its existing depth (so e.g. re-opening a
  /// file doesn't grow the stack).
  void pushPage(AppPage page) {
    final list = currentStack;
    final idx = page.key == null ? -1 : list.indexWhere((p) => p.key == page.key);
    if (idx != -1) {
      // Truncate to the existing entry, then re-append a fresh one.
      list.removeRange(idx, list.length);
    }
    list.add(page);
    notifyListeners();
  }

  /// Pop the top page of the current tab's stack. Never pops below the root.
  void popPage() {
    final list = currentStack;
    if (list.length > 1) {
      list.removeLast();
      notifyListeners();
    }
  }

  /// True when the current tab stack has more than just its root page.
  bool get canPopPage => currentStack.length > 1;

  /// Public wrapper so screens can trigger a rebuild after mutating lists.
  void notifyObservers() => notifyListeners();
}
