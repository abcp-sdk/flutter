import 'package:flutter/material.dart';

import 'agent_api.dart';
import 'agent_store.dart';
import 'app_layout.dart';
import 'prefs.dart';
import 'settings_page.dart';
import 'widgets/session_list.dart';
import 'widgets/chat_pane.dart';
import 'l10n/app_localizations.dart';

/// Responsive agent shell mirroring platform/web-app-layout.
///   - phone  (<640): single-page chat or session list + bottom NavigationBar
///   - tablet (>=640): split two panels 50/50 (session list | chat)
///   - wide   (>=1024): session list fixed panel + centered chat
class HomeShell extends StatefulWidget {
  final String baseUrl;
  final String token;
  final Locale? locale;
  const HomeShell({
    super.key,
    required this.baseUrl,
    required this.token,
    this.locale,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late AgentApi _api;
  late AgentStore _store;
  AgentTab _tab = AgentTab.chat;
  // Phone stack: null = showing session list, set = showing chat session.
  String? _phoneSession;

  @override
  void initState() {
    super.initState();
    _api = AgentApi(baseUrl: widget.baseUrl, token: widget.token);
    _store = AgentStore(api: _api);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _editConfig() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsPage(
        baseUrl: widget.baseUrl,
        token: widget.token,
        onSaved: (b, t) async {},
      ),
    ));
    final p = await Prefs.load();
    if (!mounted) return;
    setState(() {
      _api = AgentApi(baseUrl: p.baseUrl, token: p.token);
      _store.dispose();
      _store = AgentStore(api: _api);
      _phoneSession = null;
    });
  }

  Future<void> _openSettings() async {
    await _editConfig();
  }

  void _select(String id) {
    setState(() => _phoneSession = id);
    _store.selectSession(id);
  }

  Future<String?> _prompt(String title, {String? initial}) async {
    final c = TextEditingController(text: initial ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (b) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(b).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(b).pop(c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return v;
  }

  Future<void> _create() async {
    final name = await _prompt('New session');
    if (name == null) return;
    await _store.createSession(name: name);
  }

  Future<void> _rename(String id) async {
    final v = await _prompt('Rename session', initial: id);
    if (v == null || v.isEmpty) return;
    await _store.renameSession(id, v);
  }

  Future<void> _delete(String id) async {
    await _store.deleteSession(id);
    if (_phoneSession == id) setState(() => _phoneSession = null);
  }

  Future<void> _editTheme() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (b) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['system', 'light', 'dark'].map((t) {
            return ListTile(
              title: Text(t),
              trailing: _store.theme == t ? const Icon(Icons.check) : null,
              onTap: () {
                _store.setTheme(t);
                Navigator.of(b).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sessionList() {
    return SessionListPane(
      store: _store,
      onSelect: _select,
      onCreate: _create,
      onRename: _rename,
      onDelete: _delete,
    );
  }

  Widget _chat() {
    return ChatPane(store: _store);
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout(MediaQuery.sizeOf(context).width);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = _resolveDark(_store.theme, platformDark);
    final l = AppLocalizations.of(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: widget.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: isDark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
              layout.isCompact
                  ? (_tab == AgentTab.settings
                      ? l.theme
                      : (_phoneSession == null ? l.sessions : l.appName))
                  : l.appName,
              style: const TextStyle(fontSize: 18)),
          actions: [
            IconButton(icon: const Icon(Icons.palette_outlined), onPressed: _editTheme),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _openSettings),
          ],
        ),
        body: _phoneBody(layout),
        bottomNavigationBar: _nav(layout),
      ),
    );
  }

  bool _resolveDark(String theme, bool platformDark) {
    if (theme == 'dark') return true;
    if (theme == 'light') return false;
    return platformDark;
  }

  /// Single-page body for phones; the settings tab shows the settings pane.
  Widget _phoneBody(AppLayout layout) {
    if (!layout.isCompact) return _splitBody(layout);
    if (_tab == AgentTab.settings) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [const Text('Settings (theme in app bar)')]),
      );
    }
    if (_phoneSession == null) return _sessionList();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _phoneSession = null);
      },
      child: _chat(),
    );
  }

  /// Split body for tablets/desktop: session list + chat side by side.
  Widget _splitBody(AppLayout layout) {
    if (_tab == AgentTab.settings) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [const Text('Settings (theme in app bar)')]),
      );
    }
    if (_phoneSession == null) {
      // No session: full-width session list (still has the left rail).
      return _sessionList();
    }
    return Row(
      children: [
        SizedBox(width: AppLayout.panelWidth(MediaQuery.sizeOf(context).width), child: _sessionList()),
        const VerticalDivider(width: 1),
        Expanded(child: _chat()),
      ],
    );
  }

  Widget _nav(AppLayout layout) {
    return AppNav(layout: layout, tab: _tab, onTap: (t) => setState(() => _tab = t));
  }
}
