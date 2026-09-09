import 'package:flutter/material.dart';

/// Design tokens mirroring platform/web app.css (shadcn palette, opencode
/// theme). Every spacing / radius / color used by widgets must come from
/// here so the two frontends stay visually in sync.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Uniform self-drawn bar height across screens (chat top bar, code panel
/// headers, overlay panel header). AppBar toolbar matches.
abstract final class AppBars {
  static const double height = 48;
}

/// Minimum interactive touch target (Material accessibility guidance).
abstract final class Touch {
  static const double min = 44;
}

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
}

/// Semantic palette shared by both frontends. Values from
/// platform/web/src/lib/stores/themes/opencode.ts.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color foreground;
  final Color card;
  final Color popover;
  final Color primary;
  final Color onPrimary;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color destructive;
  final Color border;
  final Color input;
  final Color success;
  final Color warning;

  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.onPrimary,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.destructive,
    required this.border,
    required this.input,
    required this.success,
    required this.warning,
  });

  static const dark = AppColors(
    background: Color(0xFF0a0a0a),
    foreground: Color(0xFFeeeeee),
    card: Color(0xFF141414),
    popover: Color(0xFF1e1e1e),
    primary: Color(0xFFfab283),
    onPrimary: Color(0xFF000000),
    muted: Color(0xFF181818),
    mutedForeground: Color(0xFF808080),
    accent: Color(0xFF9d7cd8),
    destructive: Color(0xFFe06c75),
    border: Color(0xFF484848),
    input: Color(0xFF3c3c3c),
    success: Color(0xFF7fd88f),
    warning: Color(0xFFf5a742),
  );

  static const light = AppColors(
    background: Color(0xFFffffff),
    foreground: Color(0xFF1a1a1a),
    card: Color(0xFFfafafa),
    popover: Color(0xFFf5f5f5),
    primary: Color(0xFF3b7dd8),
    onPrimary: Color(0xFFffffff),
    muted: Color(0xFFf1f1f1),
    mutedForeground: Color(0xFF8a8a8a),
    accent: Color(0xFFd68c27),
    destructive: Color(0xFFd1383d),
    border: Color(0xFFb8b8b8),
    input: Color(0xFFd4d4d4),
    success: Color(0xFF3d9a57),
    warning: Color(0xFFd68c27),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? popover,
    Color? primary,
    Color? onPrimary,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? destructive,
    Color? border,
    Color? input,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      destructive: destructive ?? this.destructive,
      border: border ?? this.border,
      input: input ?? this.input,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

AppColors colorsOf(BuildContext context) =>
    Theme.of(context).extension<AppColors>() ?? AppColors.dark;

/// Type scale matching web text-[10px] / text-xs(12) / text-sm(14) usage.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  /// text-[10px] — captions, badges, timestamps.
  final TextStyle micro;

  /// text-xs — sidebar rows, tool cards, meta text.
  final TextStyle meta;

  /// text-sm — message body, list titles.
  final TextStyle body;

  /// Font stack for code / paths / diffs.
  final TextStyle mono;

  const AppTypography({
    required this.micro,
    required this.meta,
    required this.body,
    required this.mono,
  });

  static AppTypography of(Brightness brightness) {
    final base = TextStyle(
      fontFamily: 'NotoSansSC',
      fontFamilyFallback: const ['monospace'],
      color: brightness == Brightness.dark
          ? AppColors.dark.foreground
          : AppColors.light.foreground,
    );
    return AppTypography(
      micro: base.copyWith(fontSize: 10, height: 1.4),
      meta: base.copyWith(fontSize: 12, height: 1.45),
      body: base.copyWith(fontSize: 14, height: 1.5),
      mono: base.copyWith(
        fontSize: 12,
        height: 1.5,
        fontFamily: 'monospace',
        fontFamilyFallback: const ['NotoSansSC'],
      ),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? micro,
    TextStyle? meta,
    TextStyle? body,
    TextStyle? mono,
  }) {
    return AppTypography(
      micro: micro ?? this.micro,
      meta: meta ?? this.meta,
      body: body ?? this.body,
      mono: mono ?? this.mono,
    );
  }

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other == null) return this;
    return AppTypography(
      micro: TextStyle.lerp(micro, other.micro, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      mono: TextStyle.lerp(mono, other.mono, t)!,
    );
  }
}

AppTypography textOf(BuildContext context) =>
    Theme.of(context).extension<AppTypography>() ?? AppTypography.of(Brightness.dark);

/// Builds the MaterialApp themes from the shared tokens.
ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.accent,
    onSecondary: c.onPrimary,
    error: c.destructive,
    onError: brightness == Brightness.dark
        ? AppColors.dark.background
        : Colors.white,
    surface: c.background,
    onSurface: c.foreground,
    surfaceContainerHighest: c.muted,
    onSurfaceVariant: c.mutedForeground,
    outline: c.border,
    outlineVariant: c.border,
  );
  final ty = AppTypography.of(brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    fontFamily: 'NotoSansSC',
    extensions: [c, ty],
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: ty.body.copyWith(fontWeight: FontWeight.w600),
      toolbarHeight: AppBars.height,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      indicatorColor: c.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(ty.micro),
      height: 60,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.card,
      indicatorColor: c.primary.withValues(alpha: 0.15),
      selectedIconTheme: IconThemeData(color: c.primary),
      unselectedIconTheme: IconThemeData(color: c.mutedForeground),
      selectedLabelTextStyle: ty.meta.copyWith(color: c.primary),
      unselectedLabelTextStyle: ty.meta.copyWith(color: c.mutedForeground),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.rMd,
        side: BorderSide(color: c.border.withValues(alpha: 0.6)),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.border.withValues(alpha: 0.5), thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: c.muted,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c.border.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c.primary),
      ),
      hintStyle: ty.meta.copyWith(color: c.mutedForeground),
      labelStyle: ty.meta.copyWith(color: c.mutedForeground),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        textStyle: ty.meta.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.foreground,
        side: BorderSide(color: c.border),
        textStyle: ty.meta,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        textStyle: ty.meta,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.mutedForeground,
        highlightColor: c.muted,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.mutedForeground,
      titleTextStyle: ty.meta,
      subtitleTextStyle: ty.micro.copyWith(color: c.mutedForeground),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.muted,
      side: BorderSide.none,
      labelStyle: ty.micro,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.popover,
      contentTextStyle: ty.meta.copyWith(color: c.foreground),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.popover,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      titleTextStyle: ty.body.copyWith(fontWeight: FontWeight.w600),
      contentTextStyle: ty.meta,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.primary,
      unselectedLabelColor: c.mutedForeground,
      indicatorColor: c.primary,
      labelStyle: ty.meta.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: ty.meta,
      dividerColor: c.border.withValues(alpha: 0.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.onPrimary : c.mutedForeground,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.primary : c.input,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.popover,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      textStyle: ty.meta,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.popover),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
      ),
    ),
  );
}
