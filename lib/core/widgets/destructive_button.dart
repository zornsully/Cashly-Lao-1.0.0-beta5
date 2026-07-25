import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

/// Which Material button shape a [DestructiveButton] renders as — both
/// exist elsewhere in the app for adjacent irreversible actions (e.g.
/// "Sign out" outlined, "Delete account" text-only), so this covers both
/// instead of forcing one shape.
enum DestructiveButtonVariant { outlined, text }

/// Error-colored button for irreversible/destructive actions (sign out,
/// delete account, delete data). Screens previously hand-rolled this via
/// `OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error, ...)`
/// — this centralizes it so the error color and loading treatment stay
/// consistent everywhere.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.variant = DestructiveButtonVariant.outlined,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final DestructiveButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    // Uses the accessible-foreground variant, not colorScheme.error raw,
    // since this colors the button's label text (see AppSemanticColors'
    // doc comment) — the border/icon/spinner share it too, for one
    // cohesive "error identity" on the button rather than two shades.
    final error = AppSemanticColors.of(context).negativeForeground;
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: error),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return switch (variant) {
      DestructiveButtonVariant.outlined => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error),
        ),
        child: child,
      ),
      DestructiveButtonVariant.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: error,
          minimumSize: const Size.fromHeight(52),
        ),
        child: child,
      ),
    };
  }
}
