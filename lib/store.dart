import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'enums.dart';
import 'models.dart';
import 'navigation.dart';
import 'prefs.dart';

/// Mirrors stores.svelte.ts: app-wide state + repository/file-outlook caching.
class AppStore extends ChangeNotifier {
  AppStore(this.api) {
    startSessionWatch();
  }

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

  // ---- real-time session list (watchSessions) -----------------------------
  //
  // One long-lived server stream replaces polling: an initial full snapshot,
  // then per-session upserts/removals. Reconnects with backoff on drop.
  StreamSubscription<SessionListEvent>? _sessionSub;
  Timer? _sessionReconnect;
  int _sessionAttempt = 0;
  bool _firstSnapshot = true;
  static const int _maxSessionAttempts = 20;

  void startSessionWatch() {
    _sessionReconnect?.cancel();
    _sessionReconnect = null;
    _sessionSub?.cancel();
    _sessionSub = api.watchSessions().listen(
      _applySessionEvent,
      onError: (_) => _onSessionStreamClosed(),
      onDone: _onSessionStreamClosed,
      cancelOnError: false,
    );
  }

  void _onSessionStreamClosed() {
    if (_sessionAttempt >= _maxSessionAttempts) return;
    final delay = Duration(
        seconds: min(30, 1 << min(_sessionAttempt, 5)));
    _sessionAttempt++;
    _sessionReconnect?.cancel();
    _sessionReconnect = Timer(delay, startSessionWatch);
  }

  void _applySessionEvent(SessionListEvent ev) {
    _sessionAttempt = 0;
    if (ev.snapshot) {
      sessions = [...ev.upserts];
      // First ever snapshot on this device: seed read watermarks so historical
      // sessions don't all pop up as unread. Subsequent (new) sessions start
      // unread at 0 so their messages count.
      if (_firstSnapshot) {
        _firstSnapshot = false;
        for (final s in sessions) {
          if (!readSeqs.containsKey(s.id)) {
            readSeqs[s.id] = s.messageSeq;
          }
        }
        Prefs.saveReadSeqs();
      }
    } else {
      for (final s in ev.upserts) {
        final i = sessions.indexWhere((x) => x.id == s.id);
        if (i == -1) {
          sessions = [...sessions, s];
        } else {
          sessions = [...sessions]..[i] = s;
        }
      }
      if (ev.removed.isNotEmpty) {
        sessions =
            sessions.where((s) => !ev.removed.contains(s.id)).toList();
      }
    }
    // The session currently open is being read live: advance its watermark as
    // new messages stream in so returning to the list shows no stale badge.
    final active = activeSession;
    if (active != null && (readSeqs[active.id] ?? -1) < active.messageSeq) {
      readSeqs[active.id] = active.messageSeq;
      Prefs.saveReadSeqs();
    }
    sessionError = '';
    notifyListeners();
  }

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

  /// Manual refresh (pull-to-refresh / fallback). Normally the list is driven
  /// by [startSessionWatch]; this is a one-shot reconciliation.
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
    // If the open conversation was the one deleted, close it (pops the chat
    // stack back to the list) — otherwise the chat page would be left bound to
    // a session that no longer exists. Covers the tablet case where the list
    // is visible next to an open conversation.
    if (activeSessionId == id) closeSession();
    await refreshSessions();
  }

  /// Delete several sessions, returning the ids that failed. Deletes run
  /// sequentially so a single failure does not abort the rest.
  Future<List<String>> deleteSessions(List<String> ids) async {
    final failed = <String>[];
    var closedActive = false;
    for (final id in ids) {
      try {
        await api.deleteSession(id);
        if (activeSessionId == id) {
          activeSessionId = null;
          closedActive = true;
        }
      } catch (_) {
        failed.add(id);
      }
    }
    // Reset the chat stack to the list so a deleted active session does not
    // leave its conversation page open, then reload the (now shorter) list.
    if (closedActive) closeSession();
    await refreshSessions();
    return failed;
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
  /// Optimistically clear the local badge. Read state is CLIENT-LOCAL (the
  /// agent does not track it): record a per-session read watermark so the row's
  /// unread dot clears and stays clear.
  void markSessionRead(String id) {
    final seq = sessionById(id)?.messageSeq ?? readSeqs[id] ?? 0;
    Prefs.markRead(id, DateTime.now().toUtc().toIso8601String(), readSeq: seq);
    sessions = sessions
        .map((s) => s.id == id ? s.copyWith(unreadCount: 0) : s)
        .toList();
    notifyListeners();
  }

  /// Unread message count for a session: messages appended since the client's
  /// local read watermark (`messageSeq - readSeq`). A session the client has
  /// never opened counts all of its messages from 0.
  int unreadCountFor(Session s) {
    final read = readSeqs[s.id];
    if (read == null) return s.messageSeq;
    final n = s.messageSeq - read;
    return n > 0 ? n : 0;
  }

  /// True when [s] has at least one unread message.
  bool isUnread(Session s) => unreadCountFor(s) > 0;

  void openOverlay(SessionOverlay v) {
    if (activeSessionId == null) return;
    sessionOverlay = v;
    notifyListeners();
  }

  void closeOverlay() {
    sessionOverlay = null;
    notifyListeners();
  }

  /// Close the open conversation and return the chat tab to its session list.
  /// Drops every chat page above the root (conversation + any sub-page) so the
  /// user is always back on the list — never left on a deleted session.
  void closeSession() {
    activeSessionId = null;
    sessionOverlay = null;
    final list = _stackFor(SiderTab.chat);
    if (list.length > 1) list.removeRange(1, list.length);
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

  /// Push a SIBLING page: a new drill-in at the same level replaces the current
  /// one rather than stacking. Keeps the stack at [root, current]; the tablet
  /// split never shows two parallel pages side-by-side (only a child-of-top
  /// pairing is valid). E.g. config: 1 (list) | 2 (providers) → tapping
  /// "presets" should be 1 | 3, NOT 1 | 2 | 3.
  void pushSibling(AppPage page) {
    final list = currentStack;
    if (list.length > 1) {
      list.removeRange(1, list.length); // drop the previous drill-in
    }
    pushPage(page); // this re-appends (and dedups same-key)
  }

  /// Pop the top page of the current tab's stack. Never pops below the root.
  void popPage() {
    final list = currentStack;
    if (list.length > 1) {
      list.removeLast();
      // Backing out of a conversation returns to the session list, so a
      // session is no longer open. This re-shows the bottom nav bar (which is
      // hidden while activeSessionId != null).
      if (siderTab == SiderTab.chat && list.length == 1) {
        activeSessionId = null;
        sessionOverlay = null;
      }
      notifyListeners();
    }
  }

  /// True when the current tab stack has more than just its root page.
  bool get canPopPage => currentStack.length > 1;

  /// Public wrapper so screens can trigger a rebuild after mutating lists.
  void notifyObservers() => notifyListeners();
}
