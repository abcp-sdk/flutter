// Agent chat app.
//
// Minimal two-pane agent chat: a session list + a chat view with a settings
// bar. It talks directly to the abc agent backend over agent.v1.AgentService
// (Connect over HTTP/2 over TLS). No easylab gateway, no REST.
//
// Configuration (baseUrl + token) is persisted via SharedPreferences.
import 'package:flutter/material.dart';

import 'app.dart';
import 'prefs.dart';
import 'settings_page.dart';

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
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
          : HomeShell(baseUrl: _baseUrl!, token: _token ?? ''),
    );
  }
}
