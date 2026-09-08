import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app config: the agent base URL (https://...) + bearer token.
class Prefs {
  static const _kBase = 'agent.baseUrl';
  static const _kToken = 'agent.token';

  static Future<({String baseUrl, String token})> load() async {
    final p = await SharedPreferences.getInstance();
    return (
      baseUrl: p.getString(_kBase) ?? '',
      token: p.getString(_kToken) ?? '',
    );
  }

  static Future<void> save(String baseUrl, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBase, baseUrl.trim());
    await p.setString(_kToken, token.trim());
  }
}
