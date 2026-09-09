import 'package:flutter/material.dart';

import '../prefs.dart';

/// A reusable settings editor: base URL (https://) + bearer token. Used both
/// as the in-tab settings pane and (wrapped in a Scaffold) as the full-page
/// first-run / "edit config" screen.
class SettingsPane extends StatelessWidget {
  final String? baseUrl;
  final String? token;
  final Future<void> Function(String baseUrl, String token)? onSaved;
  const SettingsPane({
    super.key,
    this.baseUrl,
    this.token,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final url = TextEditingController(text: baseUrl ?? '');
    final tok = TextEditingController(text: token ?? '');
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Agent base URL (https://...)'),
            const SizedBox(height: 8),
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'https://standalone-agent.temp.nip.io',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bearer token'),
            const SizedBox(height: 8),
            TextField(
              controller: tok,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'devtoken',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final u = url.text.trim();
                if (u.isEmpty) return;
                await onSaved?.call(u, tok.text.trim());
                await Prefs.save(u, tok.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
