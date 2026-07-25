import 'package:flutter/material.dart';

import '../constants/app_motion.dart';

/// Shared confirmation-dialog helper. Every list screen (Accounts, Budget,
/// Categories, Transactions, Dashboard's transaction delete) hand-rolled an
/// identical "Delete X?" `AlertDialog` with a Cancel/Delete action pair —
/// this centralizes that pattern so the button styling can't drift between
/// screens. General dialog chrome (elevation, shape) already comes from
/// `AppTheme`'s `dialogTheme`, so a plain `AlertDialog` is still the right
/// choice for one-off content (e.g. a dialog with a form field inside).
abstract final class AppDialog {
  /// Shows a Cancel/confirm dialog and returns `true` only if the user
  /// tapped the confirm action — `false` for cancel, dismissal, or the
  /// context being unmounted by the time the dialog closes.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AnimationStyle(
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
        duration: AppMotion.normal,
      ),
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
