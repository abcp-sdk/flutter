import 'package:flutter/material.dart';

import 'prefs.dart';

/// Configuration page: baseUrl (https://) + bearer token. Save persists via
/// SharedPreferences; onSaved returns the config to the shell.
class SettingsPage extends StatefulWidget {
  final String? baseUrl;
  final String? token;
  final Future<void> Function(String baseUrl, String token)? onSaved;
  const SettingsPage({super.key, this.baseUrl, this.token, this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _url = TextEditingController(text: widget.baseUrl ?? '');
  late final TextEditingController _token = TextEditingController(text: widget.token ?? '');

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('baseUrl is required')));
      return;
    }
    await Prefs.save(url, _token.text.trim());
    await widget.onSaved?.call(url, _token.text.trim());
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Agent base URL (https://...)'),
            const SizedBox(height: 8),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://agent.example.com',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bearer token'),
            const SizedBox(height: 8),
            TextField(
              controller: _token,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'devtoken',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
