import 'package:flutter/material.dart';

import 'agent_api.dart';
import 'chat_pane.dart';
import 'prefs.dart';
import 'session_list.dart';
import 'settings_page.dart';

/// Two-pane shell: session list (left) + chat with a settings bar (right).
/// Selecting a session in the list opens it in the chat pane. The settings
/// button opens [SettingsPage]; saving re-builds the API client.
class HomeShell extends StatefulWidget {
  final String baseUrl;
  final String token;
  const HomeShell({super.key, required this.baseUrl, required this.token});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late AgentApi _api;
  String? _active;

  @override
  void initState() {
    super.initState();
    _api = AgentApi(baseUrl: widget.baseUrl, token: widget.token);
  }

  Future<void> _editConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          baseUrl: widget.baseUrl,
          token: widget.token,
          onSaved: (b, t) async {},
        ),
      ),
    );
    final p = await Prefs.load();
    if (mounted) {
      setState(() {
        _api = AgentApi(baseUrl: p.baseUrl, token: p.token);
        _active = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _editConfig,
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: SessionList(
              api: _api,
              active: _active,
              onSelect: (id) => setState(() => _active = id.isEmpty ? null : id),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _active == null
                ? const Center(child: Text('Select or create a session'))
                : ChatPane(api: _api, sessionId: _active!),
          ),
        ],
      ),
    );
  }
}
