import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';

import 'api.dart';
import 'auth_gate.dart';
import 'widgets/dialogs.dart';
import 'enums.dart';
import 'i18n.dart';
import 'app_layout.dart';
import 'page_builder.dart';
import 'prefs.dart';
import 'services/local_store.dart';
import 'store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // media_kit (audio + video, all platforms) needs its native bindings
  // initialized once before any Player is constructed.
  MediaKit.ensureInitialized();
  runApp(const EasyLabApp());
}

class EasyLabApp extends StatefulWidget {
  const EasyLabApp({super.key});

  @override
  State<EasyLabApp> createState() => _EasyLabAppState();
}

class _EasyLabAppState extends State<EasyLabApp> {
  String? _baseUrl;
  String? _token;
  bool _dark = true;
  AppStore? _store;

  @override
  void initState() {
    super.initState();
    onAuthExpired = _logout;
    _load();
  }

  @override
  void dispose() {
    onAuthExpired = null;
    super.dispose();
  }

  Future<void> _load() async {
    // Load persisted locale before the first build.
    await I18n.load();
    await Prefs.loadAgentLocale();
    await Prefs.loadReadWatermarks();
    final prefs = await Prefs.load();
    var base = prefs.baseUrl ?? '';
    var token = prefs.token ?? '';
    // Hosted-web defaults: a compile-time base URL (--dart-define) plus
    // `?base=...&token=...` query params so a link can seed the connection
    // (useful for the web build, harmless elsewhere).
    const defaultBase = String.fromEnvironment('AGENT_BASE_URL');
    if (base.isEmpty && defaultBase.isNotEmpty) base = defaultBase;
    final qp = Uri.base.queryParameters;
    if ((qp['base'] ?? '').isNotEmpty) base = qp['base']!;
    if ((qp['token'] ?? '').isNotEmpty) token = qp['token']!;
    if (base.isNotEmpty && token.isNotEmpty && base != (prefs.baseUrl ?? '')) {
      // Persist so a refresh keeps the connection.
      await Prefs.save(base, token);
    }
    if (mounted) {
      setState(() {
        _baseUrl = base;
        _token = token;
        _dark = prefs.darkMode;
      });
    }
  }

  void _setDarkMode(bool dark) {
    setState(() => _dark = dark);
    Prefs.saveDarkMode(dark);
  }

  Future<void> _logout() async {
    await Prefs.clearActive();
    if (mounted) {
      setState(() {
        _token = '';
        _store = null;
      });
    }
  }

  /// Switch to a saved backend: persist it as the active connection and
  /// rebuild the store (keeps everything else — locale, dark mode).
  Future<void> _switchBackend(BackendCfg b) async {
    await Prefs.save(b.baseUrl, b.token);
    if (mounted) {
      setState(() {
        _baseUrl = b.baseUrl;
        _token = b.token;
        _store = null;
      });
    }
  }

  /// Backend manager: a dedicated page to switch / delete saved backends, or
  /// add a new one (which lands on the setup screen). The active backend is
  /// marked. Kept as a route (not a bottom sheet) so it feels like a page.
  Future<void> _manageBackends() async {
    final backends = await Prefs.backends();
    final navCtx = rootNavKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;
    await Navigator.of(navCtx).push(
      MaterialPageRoute<void>(
        builder: (_) => _BackendsPage(
          backends: backends,
          activeBase: _baseUrl,
          onSwitch: (b) {
            _switchBackend(b);
          },
          onLogout: () {
            _logout();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
        valueListenable: I18n.notifier,
        builder: (context, locale, _) => MaterialApp(
          navigatorKey: rootNavKey,
          title: I18n.now.appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _buildHome(),
        ));
  }

  Widget _buildHome() {
    if (_baseUrl == null || _token == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_token!.isEmpty) {
      return _SetupScreen(
        initialBaseUrl: _baseUrl!,
        onSave: (base, token) async {
          await Prefs.save(base, token);
          await Prefs.upsertBackend(BackendCfg(
              name: BackendCfg.nameFor(base), baseUrl: base, token: token));
          setState(() {
            _baseUrl = base;
            _token = token;
            _store = null;
          });
        },
      );
    }
    if (_store != null) {
      return _Shell(
          store: _store!,
          darkMode: _dark,
          onDarkMode: _setDarkMode,
          onSwitchBackend: _manageBackends,
          onBackendSwitched: _switchBackend);
    }
    return FutureBuilder<AppStore>(
      future: _buildStore(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return _Shell(
            store: snap.data!,
            darkMode: _dark,
            onDarkMode: _setDarkMode,
            onSwitchBackend: _manageBackends,
            onBackendSwitched: _switchBackend);
      },
    );
  }

  Future<AppStore> _buildStore() async {
    final api = await AgentBindApi.create(baseUrl: _baseUrl!, token: _token!);
    // Open the local mirror (Drift) and hydrate drafts + read watermarks from
    // it before the first chat render, so startup is instant and offline-safe.
    LocalStore? local;
    try {
      local = await LocalStore.open();
    } catch (_) {
      local = null;
    }
    if (mounted) _store = AppStore(api, local: local);
    return _store!;
  }
}

/// App shell. Phones get a bottom navigation bar (IM-app style); tablets and
/// desktop get a compact navigation rail.
class _Shell extends StatelessWidget {
  final AppStore store;
  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final VoidCallback? onSwitchBackend;
  final void Function(BackendCfg)? onBackendSwitched;
  const _Shell({
      required this.store,
      required this.darkMode,
      required this.onDarkMode,
      this.onSwitchBackend,
      this.onBackendSwitched});

  static const _navItems = <(SiderTab, IconData, String)>[
    (SiderTab.chat, Icons.chat_bubble_outline, 'tabChat'),
    (SiderTab.config, Icons.settings_outlined, 'tabConfig'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tab = store.siderTab;
        final layout = AppLayout(MediaQuery.sizeOf(context).width);
        final hideBottomBar =
            layout.isCompact && tab == SiderTab.chat && store.activeSessionId != null;
        final body = layout.isCompact ? _phoneBody(tab) : _tabletBody(tab);
        return Scaffold(
          body: layout.isCompact
              ? body
              : Row(
                  children: [
                    AppNav(
                      layout: layout,
                      tab: tab,
                      items: _navItems,
                      onTap: (tb) => store.switchTab(tb),
                    ),
                    Expanded(child: body),
                  ],
                ),
          bottomNavigationBar: layout.isCompact && !hideBottomBar
              ? AppNav(
                  layout: layout,
                  tab: tab,
                  items: _navItems,
                  onTap: (tb) => store.switchTab(tb),
                )
              : null,
        );
      },
    );
  }

  /// Phone: a single stack-mounted page, with back-gesture pop.
  Widget _phoneBody(SiderTab tab) {
    final stack = store.currentStack;
    final pages = buildStackPages(store, stack,
        lastCount: 1,
        darkMode: darkMode,
        onDarkMode: onDarkMode,
        onSwitchBackend: onSwitchBackend,
        onBackendSwitched: onBackendSwitched);
    return PopScope(
      canPop: !store.canPopPage,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        store.popPage();
      },
      child: pages.isEmpty ? const SizedBox.shrink() : pages.last,
    );
  }

  /// Tablet: the last two pages of the stack, side by side. Always rendered
  /// inside the same Row/Expanded structure — even for a single page — so the
  /// element tree position of the left panel stays identical when a drill-in is
  /// pushed. Otherwise Flutter disposes + recreates the panel (re-running its
  /// initState → a visible reload/flicker on the settings list, unlike chat).
  Widget _tabletBody(SiderTab tab) {
    final stack = store.currentStack;
    final pages = buildStackPages(store, stack,
        lastCount: 2,
        darkMode: darkMode,
        onDarkMode: onDarkMode,
        onSwitchBackend: onSwitchBackend,
        onBackendSwitched: onBackendSwitched);
    return Row(
      children: [
        for (final p in pages) Expanded(child: p),
      ],
    );
  }
}

class _SetupScreen extends StatefulWidget {
  final String initialBaseUrl;
  final Future<void> Function(String base, String token) onSave;
  const _SetupScreen({required this.initialBaseUrl, required this.onSave});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}
class _SetupScreenState extends State<_SetupScreen> {
  late final TextEditingController _base =
      TextEditingController(text: widget.initialBaseUrl);
  late final TextEditingController _token = TextEditingController();

  bool _busy = false;
  bool _showToken = false;

  @override
  void dispose() {
    _base.dispose();
    _token.dispose();
    super.dispose();
  }

  bool get _canConnect =>
      _base.text.trim().isNotEmpty && _token.text.trim().isNotEmpty && !_busy;

  /// Verify the gateway + token before saving so a typo can't land the user
  /// in a silently-empty app.
  Future<void> _connect() async {
    final base = _base.text.trim();
    final token = _token.text.trim();
    if (base.isEmpty || token.isEmpty) return;
    setState(() => _busy = true);
    try {
      final api = await AgentBindApi.create(baseUrl: base, token: token);
      await api.listSessions();
      if (!mounted) return;
      await widget.onSave(base, token);
    } catch (e) {
      showErrorToast(context, I18n.now.loadError('$e'));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('EasyLab',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _base,
                      enabled: !_busy,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          labelText: context.l10n.gatewayUrl),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _token,
                      obscureText: !_showToken,
                      enabled: !_busy,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.l10n.tokenLabel,
                        suffixIcon: IconButton(
                          icon: Icon(_showToken
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _showToken = !_showToken),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _canConnect ? _connect : null,
                      child: Text(_busy
                          ? context.l10n.connecting
                          : context.l10n.connect),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dedicated page for managing saved backends (switch / delete / add). Unlike
/// a bottom sheet, it's a full route so it reads as its own screen.
class _BackendsPage extends StatefulWidget {
  final List<BackendCfg> backends;
  final String? activeBase;
  final void Function(BackendCfg) onSwitch;
  final VoidCallback onLogout;
  const _BackendsPage({
    required this.backends,
    required this.activeBase,
    required this.onSwitch,
    required this.onLogout,
  });

  @override
  State<_BackendsPage> createState() => _BackendsPageState();
}

class _BackendsPageState extends State<_BackendsPage> {
  late List<BackendCfg> _backends;

  @override
  void initState() {
    super.initState();
    _backends = [...widget.backends];
  }

  Future<void> _delete(BackendCfg b) async {
    await Prefs.removeBackend(b.baseUrl);
    if (!mounted) return;
    setState(() => _backends.removeWhere((e) => e.baseUrl == b.baseUrl));
    showToast(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final text = textOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.backendsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_backends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(context.l10n.noSavedBackends,
                  style: TextStyle(color: colors.mutedForeground)),
            ),
          for (final b in _backends)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(
                  widget.activeBase == b.baseUrl
                      ? Icons.radio_button_checked
                      : Icons.dns_outlined,
                  color: widget.activeBase == b.baseUrl
                      ? colors.primary
                      : colors.mutedForeground,
                ),
                title: Text(b.name.isNotEmpty ? b.name : b.baseUrl),
                subtitle: Text(b.baseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        text.micro.copyWith(color: colors.mutedForeground)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: colors.mutedForeground),
                  tooltip: context.l10n.deleteBackend,
                  onPressed: () => _delete(b),
                ),
                onTap: () {
                  widget.onSwitch(b);
                  Navigator.pop(context);
                },
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: Text(context.l10n.addBackend),
            onTap: () {
              Navigator.pop(context);
              widget.onLogout();
            },
          ),
        ],
      ),
    );
  }
}
