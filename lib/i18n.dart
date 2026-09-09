import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/generated/app_localizations.dart';

export 'l10n/generated/app_localizations.dart';

/// Lightweight locale state + the typed l10n accessor.
///
/// Two supported locales (zh, en); zh is the default. The selected locale is
/// persisted and any change notifies [I18n.notifier] so the root `MaterialApp`
/// rebuilds with the right AppLocalizations.
class I18n {
  static const _kLocale = 'locale';
  static const Locale fallback = Locale('zh');
  static final ValueNotifier<Locale> notifier = ValueNotifier(fallback);

  static Locale get locale => notifier.value;
  static bool get isZh => locale.languageCode == 'zh';

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final code = p.getString(_kLocale);
      if (code == 'zh' || code == 'en') {
        notifier.value = Locale(code!);
      }
    } catch (_) {}
  }

  static Future<void> save(Locale l) async {
    notifier.value = l;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLocale, l.languageCode);
    } catch (_) {}
  }

  /// The current localizations instance, for non-widget code (controllers,
  /// helpers, snackbars resolved without a BuildContext).
  static AppLocalizations get now => lookupAppLocalizations(notifier.value);
}

/// `context.l10n.appTitle` — the typed accessor used throughout the UI.
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Resolve a localized string for the current locale given a key (used at the
/// few sites that pick a key dynamically). [name] must map to an
/// AppLocalizations getter; an unknown key returns the raw key so the
/// developer notices immediately.
String l10nString(String key) {
  final l = I18n.now;
  for (final m in _resolve.entries) {
    if (m.key == key) return m.value(l);
  }
  return key;
}

/// Dynamic-key -> getter resolver for the handful of call sites that choose a
/// label at runtime (nav tabs, section headers, overlay panel tabs).
final Map<String, String Function(AppLocalizations)> _resolve = {
  'recent': (l) => l.recent,
  'allRepos': (l) => l.allRepos,
  'back': (l) => l.back,
  'loading': (l) => l.loading,
  'tabChat': (l) => l.tabChat,
  'tabCode': (l) => l.tabCode,
  'tabContainers': (l) => l.tabContainers,
  'tabConfig': (l) => l.tabConfig,
  'appearance': (l) => l.appearance,
  'providers': (l) => l.providers,
  'presets': (l) => l.presets,
  'tools': (l) => l.tools,
  'language': (l) => l.language,
  'agentLocale': (l) => l.agentLocale,
  'switchBackend': (l) => l.switchBackend,
  'timeline': (l) => l.timeline,
  'files': (l) => l.files,
  'mailbox': (l) => l.mailbox,
  'container': (l) => l.container,
};
