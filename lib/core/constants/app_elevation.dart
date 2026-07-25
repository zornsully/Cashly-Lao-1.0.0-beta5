import 'package:flutter/material.dart';

/// Shared depth system. Cashly uses real soft drop-shadows rather than
/// Material 3's default flat/tonal-tint elevation — closer to the
/// Revolut/Monzo/Copilot Money benchmark than to stock Material.
///
/// [subtle]/[soft]/[lifted] are for custom `Container`-based surfaces
/// (e.g. `AppCard`) that want full control over blur/spread/offset.
/// [cardElevation]/[sheetElevation]/[dialogElevation] are for Material
/// components (`Card`, bottom sheets, dialogs) whose built-in elevation
/// already renders a real shadow — those just need `surfaceTintColor:
/// Colors.transparent` alongside them so Material doesn't *also* wash the
/// surface with a tonal tint on top of the shadow.
abstract final class AppElevation {
  static List<BoxShadow> subtle(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> soft(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> lifted(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  static const double cardElevation = 2;
  static const double sheetElevation = 6;
  static const double dialogElevation = 8;
}
