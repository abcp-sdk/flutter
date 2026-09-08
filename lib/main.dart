import 'package:flutter/material.dart';

import 'app.dart';
import 'prefs.dart';
import 'settings_page.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgentApp());
}

class AgentApp extends StatefulWidget {
  const AgentApp({super.key});

  @override
  State<AgentApp> createState() => _AgentAppState();
}

class _AgentAppState extends State<AgentApp> {
  String? _baseUrl;
  String? _token;
  Locale _locale = const Locale('zh');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await Prefs.load();
    if (mounted) {
      setState(() {
        _baseUrl = p.baseUrl;
        _token = p.token;
        _locale = Locale(p.locale);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: _baseUrl == null || _baseUrl!.isEmpty
          ? SettingsPage(
              onSaved: (b, t) {
                setState(() {
                  _baseUrl = b;
                  _token = t;
                });
                return Future.value();
              },
            )
          : HomeShell(locale: _locale, baseUrl: _baseUrl!, token: _token ?? ''),
    );
  }
}
