import 'package:flutter/material.dart';

import 'store.dart';
import 'navigation.dart';
import 'screens/chat.dart';
import 'screens/session_list_page.dart';
import 'screens/chat_overlay_page.dart';
import 'screens/config.dart';
import 'screens/providers.dart';
import 'prefs.dart';

/// Build the widget for a single [AppPage]. [isTablet] lets a page render its
/// own back affordance only when it is the *current* (top) page of the last-two
/// table split; the preceding page is context and shows no back.
/// The config callbacks are only used for config pages.
Widget buildPage(
  AppStore store,
  AppPage page, {
  required bool isTablet,
  required bool darkMode,
  required ValueChanged<bool> onDarkMode,
  required VoidCallback? onSwitchBackend,
  void Function(BackendCfg)? onBackendSwitched,
}) {
  switch (page) {
    case ChatListPage():
      return SessionListPage(key: ValueKey(page.key), store: store);
    case ChatSessionPage():
      return ChatSessionPageWidget(key: ValueKey(page.key), store: store);
    case ChatOverlayPage(:final overlay):
      return ChatOverlayPageWidget(
        key: ValueKey(page.key),
        store: store,
        overlay: overlay,
      );
    case ConfigRootPage():
      return ConfigScreen(
        key: ValueKey(page.key),
        store: store,
        darkMode: darkMode,
        onDarkMode: onDarkMode,
        onSwitchBackend: onSwitchBackend,
        onBackendSwitched: onBackendSwitched,
      );
    case ConfigSubPage(:final id):
      return ConfigScreen(
        key: ValueKey(page.key),
        store: store,
        darkMode: darkMode,
        onDarkMode: onDarkMode,
        onSwitchBackend: onSwitchBackend,
        onBackendSwitched: onBackendSwitched,
        initialId: id,
      );
    case ProvidersListPage():
      return ProvidersListScreen(key: ValueKey(page.key), store: store);
    case ProviderFormPage():
      return ProviderFormScreen(key: ValueKey(page.key), store: store);
    case ProviderModelsPage():
      return ProviderModelsScreen(key: ValueKey(page.key), store: store);
  }
}

/// Build the widgets for the [lastCount] newest pages of [stack], oldest→newest.
/// Phone uses 1 (the top); tablets use the last two (context + current).
List<Widget> buildStackPages(
  AppStore store,
  List<AppPage> stack, {
  required int lastCount,
  required bool darkMode,
  required ValueChanged<bool> onDarkMode,
  required VoidCallback? onSwitchBackend,
  void Function(BackendCfg)? onBackendSwitched,
}) {
  final n = stack.length;
  if (n == 0) return const [];
  // Clamp: a stack shorter than [lastCount] shows whatever it has (never blank).
  final start = (n - lastCount).clamp(0, n - 1);
  final pages = stack.sublist(start);
  return [
    for (var i = 0; i < pages.length; i++)
      buildPage(
        store,
        pages[i],
        isTablet: i == pages.length - 1,
        darkMode: darkMode,
        onDarkMode: onDarkMode,
        onSwitchBackend: onSwitchBackend,
        onBackendSwitched: onBackendSwitched,
      ),
  ];
}
