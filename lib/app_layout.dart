import 'package:flutter/material.dart';

import 'enums.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme/app_theme.dart';

/// Responsive app shell. Phones (< [compactBelow]) get a bottom
/// `NavigationBar` (IM-app style); tablets/desktop (>= [compactBelow]) get a
/// left `NavigationRail` and may split each tab's content into multiple
/// simultaneously-visible panels.
///
/// Used by the root `_Shell` (which tab is open) and by the per-tab screens
/// (how many columns to show). Keep the breakpoints tuned together:
///   - compactBelow      : phone (bottom bar)  e.g. 640
///   - wideThreshold     : per-panel width e.g. 1024  (second/third column)
class AppLayout {
  final double width;
  AppLayout(this.width);

  bool get isCompact => width < compactBelow;
  bool get isTablet => width >= compactBelow;
  /// Enough room for a fixed second/third panel (chat overlay, code content).
  bool get isWide => width >= wideThreshold;

  static const double compactBelow = 640;
  static const double wideThreshold = 1024;

  /// Standard rail width for tablets/desktop.
  static const double railWidth = 96;

  /// A single panel of a split layout.
  static double panelWidth(double available, {bool fixed = true}) =>
      fixed ? (available * 0.30).clamp(240.0, 420.0) : available;
}

/// Build the `SiderTab`-independent navigation for the shell.
///
/// Returns a `NavigationBar` when [layout.isCompact], else a `NavigationRail`.
class AppNav extends StatelessWidget {
  final AppLayout layout;
  final SiderTab tab;
  final List<(SiderTab, IconData, String)> items;
  final void Function(SiderTab) onTap;
  const AppNav({
    super.key,
    required this.layout,
    required this.tab,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (layout.isCompact) {
      return _BottomBar(tab: tab, items: items, onTap: onTap);
    }
    return _Rail(tab: tab, items: items, onTap: onTap);
  }
}

class _Rail extends StatelessWidget {
  final SiderTab tab;
  final List<(SiderTab, IconData, String)> items;
  final void Function(SiderTab) onTap;
  const _Rail(
      {required this.tab, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return NavigationRail(
      backgroundColor: colors.card,
      indicatorColor: colors.primary.withValues(alpha: 0.15),
      selectedIndex: items.indexWhere((e) => e.$1 == tab),
      onDestinationSelected: (i) => onTap(items[i].$1),
      leading: const SizedBox(height: AppSpacing.md),
      labelType: NavigationRailLabelType.all,
      minWidth: AppLayout.railWidth,
      selectedIconTheme: IconThemeData(color: colors.primary),
      unselectedIconTheme: IconThemeData(color: colors.mutedForeground),
      selectedLabelTextStyle:
          textOf(context).meta.copyWith(color: colors.primary),
      unselectedLabelTextStyle:
          textOf(context).meta.copyWith(color: colors.mutedForeground),
      destinations: [
        for (final (tb, icon, labelKey) in items)
          NavigationRailDestination(
            icon: Icon(icon, size: 22),
            label: Text(l10nString(labelKey)),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final SiderTab tab;
  final List<(SiderTab, IconData, String)> items;
  final void Function(SiderTab) onTap;
  const _BottomBar(
      {required this.tab, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: items.indexWhere((e) => e.$1 == tab),
      onDestinationSelected: (i) => onTap(items[i].$1),
      destinations: [
        for (final (tb, icon, labelKey) in items)
          NavigationDestination(
            icon: Icon(icon),
            label: l10nString(labelKey),
          ),
      ],
    );
  }
}
