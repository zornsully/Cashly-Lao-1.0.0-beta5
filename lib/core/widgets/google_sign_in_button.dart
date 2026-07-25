import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import 'google_logo_mark.dart';

/// "Continue with Google" button shared by Login and Register — an
/// [OutlinedButton] rather than [PrimaryButton] since Google's own
/// branding guidelines call for a neutral, secondary-looking button that
/// doesn't compete visually with the app's own primary action.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogoMark(),
                const SizedBox(width: AppSpacing.sm),
                Text(label),
              ],
            ),
    );
  }
}
