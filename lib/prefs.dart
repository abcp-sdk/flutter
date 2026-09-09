import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kBase = 'base_url';
const _kToken = 'token';
const _kDark = 'dark_mode';
const _kBackends = 'backends';
const _kAgentLocale = 'agent_locale';

/// Agent prompt/tool language preference. 'follow' uses the UI language;
/// otherwise an explicit 'zh'/'en'.
String agentLocaleValue = 'follow';

/// A saved backend (gateway) the app can switch between.
class BackendCfg {
  final String name;
  final String baseUrl;
  final String token;
  const BackendCfg({
    required this.name,
    required this.baseUrl,
    required this.token,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'baseUrl': baseUrl, 'token': token};
  factory BackendCfg.fromJson(Map<String, dynamic> j) => BackendCfg(
        name: j['name'] as String? ?? '',
        baseUrl: j['baseUrl'] as String? ?? '',
        token: j['token'] as String? ?? '',
      );

  /// Human label derived from the host when no explicit name exists.
  static String nameFor(String baseUrl) =>
      Uri.tryParse(baseUrl)?.host ?? baseUrl;
}

class Prefs {
  final String? baseUrl;
  final String? token;
  final bool darkMode;
  const Prefs({this.baseUrl, this.token, this.darkMode = true});

  static Future<Prefs> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return Prefs(
        baseUrl: p.getString(_kBase),
        token: p.getString(_kToken),
        darkMode: p.getBool(_kDark) ?? true,
      );
    } catch (_) {
      return const Prefs();
    }
  }

  static Future<void> save(String base, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBase, base);
    await p.setString(_kToken, token);
  }

  static Future<void> saveDarkMode(bool dark) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kDark, dark);
    } catch (_) {}
  }

  /// Resolve the effective agent locale for a request: explicit 'zh'/'en',
  /// else follow provided UI language.
  static Future<void> loadAgentLocale() async {
    try {
      final p = await SharedPreferences.getInstance();
      agentLocaleValue = p.getString(_kAgentLocale) ?? 'follow';
    } catch (_) {}
  }

  static Future<void> saveAgentLocale(String v) async {
    agentLocaleValue = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kAgentLocale, v);
    } catch (_) {}
  }

  /// Effective locale string to send to the agent ('zh'/'en').
  static String effectiveAgentLocale({required bool uiZh}) {
    return agentLocaleValue == 'follow' ? (uiZh ? 'zh' : 'en') : agentLocaleValue;
  }

  /// Log out of the ACTIVE backend only (locale, dark mode and the saved
  /// backend list stay so switching back is one tap).
  static Future<void> clearActive() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kBase);
      await p.remove(_kToken);
    } catch (_) {}
  }

  /// All saved backends (name+url+token), order preserved.
  static Future<List<BackendCfg>> backends() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kBackends);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List? ?? [];
      return list
          .map((e) => BackendCfg.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Upserts [b] (keyed by baseUrl) into the saved list.
  static Future<void> upsertBackend(BackendCfg b) async {
    final list = [...await backends()];
    list.removeWhere((x) => x.baseUrl == b.baseUrl);
    list.insert(0, b);
    await _writeBackends(list);
  }

  static Future<void> removeBackend(String baseUrl) async {
    final list = [...await backends()];
    list.removeWhere((x) => x.baseUrl == baseUrl);
    await _writeBackends(list);
  }

  static Future<void> _writeBackends(List<BackendCfg> list) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _kBackends, jsonEncode(list.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }
}
