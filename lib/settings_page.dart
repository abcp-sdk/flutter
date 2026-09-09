import 'package:flutter/material.dart';

import 'widgets/settings_pane.dart';

/// Full-page configuration screen (first run, or the "edit config" push).
/// Builds the settings form with a back affordance.
class SettingsPage extends StatefulWidget {
  final String? baseUrl;
  final String? token;
  final Future<void> Function(String baseUrl, String token)? onSaved;
  const SettingsPage({super.key, this.baseUrl, this.token, this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SettingsPane(
          baseUrl: widget.baseUrl,
          token: widget.token,
          onSaved: widget.onSaved,
        ),
      ),
    );
  }
}
