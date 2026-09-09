import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../net/http_client_factory.dart';

/// models.dev provider templates (served by the models.opencode.ai mirror),
/// used to pre-fill the Add-Provider form: default base URL, API type (from
/// the SDK package name) and the provider's model catalogue. Mirrors the web
/// ProviderSection/AddProviderForm behaviour, including the 1h local cache.
class ModelsDev {
  static const _url = 'https://models.opencode.ai/api.json';
  static const _cacheKey = 'easylab-models-dev';
  static const _ttl = Duration(hours: 1);

  /// One model entry of a template provider.
  /// (id, display name, context limit, reasoning flag, tool-call flag).
  static Future<List<MdProvider>> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null) return cached;
    }
    final client = await platformHttpClient();
    try {
      final resp = await client
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final providers = <MdProvider>[];
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          providers.add(MdProvider.fromJson(key, value));
        }
      });
      providers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _writeCache(providers);
      return providers;
    } finally {
      client.close();
    }
  }

  static Future<List<MdProvider>?> _readCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (j['ts'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) {
        return null;
      }
      final list = (j['providers'] as List? ?? []);
      return list
          .map((e) => MdProvider.fromJson(
              (e as Map<String, dynamic>)['id'] as String? ?? '',
              e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(List<MdProvider> providers) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _cacheKey,
          jsonEncode({
            'ts': DateTime.now().millisecondsSinceEpoch,
            'providers': providers.map((p0) => p0.toJson()).toList(),
          }));
    } catch (_) {}
  }

  /// Web's npmToType: derive the platform api_type from the SDK package.
  static String npmToType(String npm) {
    if (npm.isEmpty || npm.contains('openai-compatible')) {
      return 'openai-compatible';
    }
    if (npm.contains('anthropic')) return 'anthropic';
    if (npm.contains('openai')) return 'openai';
    if (npm.contains('google') || npm.contains('gemini')) return 'gemini';
    return npm
        .replaceFirst('@ai-sdk/', '')
        .replaceFirst(RegExp(r'-ai-sdk-provider$'), '');
  }
}

class MdProvider {
  final String id;
  final String name;
  final String npm;
  final String api; // default base URL
  final List<MdModel> models;
  MdProvider({
    required this.id,
    required this.name,
    required this.npm,
    required this.api,
    required this.models,
  });

  factory MdProvider.fromJson(String key, Map<String, dynamic> j) {
    final models = <MdModel>[];
    final mj = j['models'];
    if (mj is Map<String, dynamic>) {
      mj.forEach((mid, mv) {
        if (mv is Map<String, dynamic>) {
          models.add(MdModel.fromJson(mid, mv));
        }
      });
    }
    return MdProvider(
      id: j['id'] as String? ?? key,
      name: j['name'] as String? ?? key,
      npm: j['npm'] as String? ?? '',
      api: j['api'] as String? ?? '',
      models: models,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'npm': npm,
        'api': api,
        'models': models.map((m) => m.toJson()).toList(),
      };
}

class MdModel {
  final String id;
  final String name;
  final int? contextLimit;
  MdModel({required this.id, required this.name, this.contextLimit});

  factory MdModel.fromJson(String key, Map<String, dynamic> j) => MdModel(
        id: j['id'] as String? ?? key,
        name: j['name'] as String? ?? key,
        contextLimit: (j['limit'] is Map<String, dynamic>)
            ? ((j['limit'] as Map<String, dynamic>)['context'] as num?)
                ?.toInt()
            : null,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'context_limit': contextLimit};
}
