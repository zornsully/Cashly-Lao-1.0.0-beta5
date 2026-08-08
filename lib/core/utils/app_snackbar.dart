import 'package:flutter/material.dart';

/// Consistent success/error snackbar presentation used across every
/// feature so error handling reads the same everywhere in the app.
abstract final class AppSnackbar {
  static void showError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: colorScheme.error),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: colorScheme.primary),
      );
  }

  /// Neutral, non-error/non-success notice (e.g. "this isn't available
  /// yet") — uses the theme's own default `SnackBarThemeData` surface
  /// rather than a semantic color, since neither error nor success framing
  /// fits.
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
