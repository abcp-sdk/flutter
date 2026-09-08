import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app config: agent base URL + bearer token + locale.
class Prefs {
  static const _kBase = 'agent.baseUrl';
  static const _kToken = 'agent.token';
  static const _kLocale = 'agent.lang';

  static Future<({String baseUrl, String token, String locale})> load() async {
    final p = await SharedPreferences.getInstance();
    return (
      baseUrl: p.getString(_kBase) ?? '',
      token: p.getString(_kToken) ?? '',
      locale: p.getString(_kLocale) ?? 'zh',
    );
  }

  static Future<void> save(String baseUrl, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBase, baseUrl.trim());
    await p.setString(_kToken, token.trim());
  }

  static Future<void> saveLocale(String locale) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, locale);
  }
}
