import 'package:flutter/material.dart' show Locale;

/// A curated, stable language preference users can pick in Settings.
///
/// We persist [AppLanguage.name] to Firestore — same reasoning as
/// [AppThemeModePreference]/[AppIconKey]/[AppColorKey]: an enum name is
/// stable across app versions in a way a raw locale/index isn't.
enum AppLanguage {
  english(Locale('en')),
  lao(Locale('lo'));

  const AppLanguage(this.locale);

  final Locale locale;
}
