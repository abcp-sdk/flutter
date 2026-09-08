import 'package:flutter/material.dart';

/// Responsive app shell logic, mirroring platform/web-app-layout.
///   - compactBelow : phone  (<640) -> bottom NavigationBar
///   - wideThreshold: per-panel width (>=1024) -> split two/three panels
class AppLayout {
  final double width;
  AppLayout(this.width);

  bool get isCompact => width < compactBelow;
  bool get isTablet => width >= compactBelow;
  bool get isWide => width >= wideThreshold;

  static const double compactBelow = 640;
  static const double wideThreshold = 1024;
  static const double railWidth = 80;

  /// Left panel width for the session list in a split layout.
  static double panelWidth(double available, {bool fixed = true}) =>
      fixed ? (available * 0.30).clamp(240.0, 360.0) : available;

  /// Chat bubble max width (centered on wide screens).
  static double bubbleWidth(double available) {
    if (available >= wideThreshold) return 720;
    if (available >= compactBelow) return available * 0.7;
    return available * 0.86;
  }
}

/// Chat/settings navigation: bottom bar (phone) or rail (tablet/desktop).
enum AgentTab { chat, settings }

class AppNav extends StatelessWidget {
  final AppLayout layout;
  final AgentTab tab;
  final void Function(AgentTab) onTap;
  const AppNav(
      {super.key, required this.layout, required this.tab, required this.onTap});

  static const _items = [
    (AgentTab.chat, Icons.chat_bubble_outline, 'Chat'),
    (AgentTab.settings, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    if (layout.isCompact) {
      return NavigationBar(
        selectedIndex: _items.indexWhere((e) => e.$1 == tab),
        onDestinationSelected: (i) => onTap(_items[i].$1),
        destinations: [
          for (final (_, icon, label) in _items)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      );
    }
    return NavigationRail(
      selectedIndex: _items.indexWhere((e) => e.$1 == tab),
      onDestinationSelected: (i) => onTap(_items[i].$1),
      labelType: NavigationRailLabelType.all,
      minWidth: AppLayout.railWidth,
      destinations: [
        for (final (_, icon, label) in _items)
          NavigationRailDestination(icon: Icon(icon), label: Text(label)),
      ],
    );
  }
}
