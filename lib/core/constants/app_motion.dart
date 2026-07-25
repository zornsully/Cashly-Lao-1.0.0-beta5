import 'package:flutter/animation.dart';

/// Shared motion system. Every deliberate transition/micro-interaction
/// (bottom-nav tab switches, value changes, sheet/dialog open-close) pulls
/// its timing from here instead of a screen picking its own duration —
/// same rationale as `AppSpacing`/`AppRadius`/`AppElevation`. Route-level
/// transitions are handled separately by `AppTheme`'s `PageTransitionsTheme`,
/// which uses Flutter's own tuned durations rather than these.
abstract final class AppMotion {
  /// Small, contained changes: an icon swap, a selection highlight.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default for most micro-interactions: tab switches, value changes,
  /// sheet/dialog open-close.
  static const Duration normal = Duration(milliseconds: 250);

  /// Larger surface changes, e.g. a full section expanding.
  static const Duration slow = Duration(milliseconds: 400);

  /// A one-off celebratory moment (e.g. a savings goal completion burst) —
  /// deliberately longer than `slow`, since it's a standalone payoff
  /// animation rather than a UI-state transition.
  static const Duration celebratory = Duration(milliseconds: 1600);

  /// For content entering (fading/sliding in).
  static const Curve enter = Curves.easeOutCubic;

  /// For content leaving (fading/sliding out).
  static const Curve exit = Curves.easeInCubic;
}
