import 'package:flutter/material.dart' show ThemeMode;

/// A curated, stable appearance preference users can pick in Settings.
///
/// We persist [AppThemeModePreference.name] (not Flutter's own [ThemeMode]
/// enum, whose ordering/members aren't ours to depend on across Flutter
/// versions) to Firestore — same reasoning as [AppIconKey]/[AppColorKey].
enum AppThemeModePreference {
  system(ThemeMode.system),
  light(ThemeMode.light),
  dark(ThemeMode.dark);

  const AppThemeModePreference(this.themeMode);

  final ThemeMode themeMode;
}
