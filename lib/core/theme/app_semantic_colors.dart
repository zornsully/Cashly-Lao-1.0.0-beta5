import 'package:flutter/material.dart';

/// Colors that need a value distinct from anything in [ColorScheme] because
/// the closest scheme role fails contrast for the way this app actually uses
/// it. Looked up the same way as any other theme data:
/// `Theme.of(context).extension<AppSemanticColors>()`.
///
/// Currently just [positiveForeground]: `colorScheme.secondary` (the brand
/// green, pinned to `#10B981` per `CLAUDE.md`) is used directly as the text/
/// icon color for income figures (see `transaction_tile.dart`,
/// `stat_card.dart` via Dashboard, `_SummaryFigure` in `reports_screen.dart`,
/// `income_expense_trend_chart.dart`) — but at that exact hex, against this
/// app's light-mode surface, it only reaches ~2.3:1 contrast, well under
/// WCAG AA's 4.5:1 (text) / 3:1 (icons, graphical objects) minimums. Dark
/// mode's navy surface has no such problem (~7:1) so only light mode needs a
/// different value here. The brand's actual `secondary` role in
/// [ColorScheme] is left untouched — this is additive, not a palette change.
///
/// [primaryForeground] exists for the same reason: `colorScheme.primary`
/// (brand blue, `#2563EB`) is used directly as small (14sp), bold body text
/// in one real place — Reports' "net" summary figure when net ≥ 0 (see
/// `reports_screen.dart`) — where it only reaches ~3.45:1 against the dark
/// surface, short of AA's 4.5:1 (14sp bold doesn't meet WCAG's "large text"
/// exception, which needs ~18.66px bold). `colorScheme.primary` itself is
/// untouched — every other use of it in the app (icons, borders, chip/fill
/// accents) is non-text and already clears the 3:1 bar those need.
///
/// [negativeForeground] is the same fix for `colorScheme.error` (Tailwind
/// red-600), used directly as expense-figure text/button-label text in
/// several places (`transaction_tile.dart`, `account_card.dart`,
/// `budget_progress_tile.dart`, `DestructiveButton`, Reports) — it clears
/// 4.5:1 in light mode by only a hair's breadth (~4.41:1, technically
/// failing) and misses it more clearly in dark mode (~3.7:1). Every
/// non-text use of `colorScheme.error` (icons, progress-bar fill, borders)
/// is unaffected and stays on the pinned brand red.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.positiveForeground,
    required this.primaryForeground,
    required this.negativeForeground,
  });

  /// The light-mode-safe values, for contexts with no [AppSemanticColors]
  /// registered on their theme (a bare `MaterialApp()` in a widget test,
  /// which every existing widget test in this project deliberately uses
  /// instead of [AppTheme] to keep widget tests decoupled from theme
  /// construction details). The real app always has the real one via
  /// [AppTheme]; this only matters for tests and is never reached in
  /// production.
  static const AppSemanticColors fallback = AppSemanticColors(
    positiveForeground: Color(0xFF047857),
    primaryForeground: Color(0xFF2563EB),
    negativeForeground: Color(0xFFB91C1C),
  );

  /// Looks up this theme's [AppSemanticColors], falling back to
  /// [fallback] rather than throwing when none is registered.
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? fallback;

  final Color positiveForeground;
  final Color primaryForeground;
  final Color negativeForeground;

  @override
  AppSemanticColors copyWith({
    Color? positiveForeground,
    Color? primaryForeground,
    Color? negativeForeground,
  }) => AppSemanticColors(
    positiveForeground: positiveForeground ?? this.positiveForeground,
    primaryForeground: primaryForeground ?? this.primaryForeground,
    negativeForeground: negativeForeground ?? this.negativeForeground,
  );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      positiveForeground:
          Color.lerp(positiveForeground, other.positiveForeground, t) ??
          positiveForeground,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t) ??
          primaryForeground,
      negativeForeground:
          Color.lerp(negativeForeground, other.negativeForeground, t) ??
          negativeForeground,
    );
  }
}
