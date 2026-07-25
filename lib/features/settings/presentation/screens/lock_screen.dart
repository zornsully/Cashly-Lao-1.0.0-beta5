import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/app_lock_state_provider.dart';
import '../../../../core/providers/local_auth_providers.dart';
import '../../../../core/widgets/cashly_logo_mark.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Shown instead of the authenticated app when app lock is on and the
/// current session hasn't been unlocked yet (`AppRoutes.lock`, gated by
/// `app_router.dart`'s redirect). Auto-prompts on first appearance —
/// `PrimaryButton` below is for retrying after a cancel/failure, not the
/// primary path.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final didAuthenticate = await ref
          .read(localAuthenticationProvider)
          .authenticate(
            localizedReason: l10n.appLockReasonMessage,
            // biometricOnly: false lets the OS fall back to the device's
            // own PIN/pattern/password when biometrics aren't enrolled —
            // this is the "PIN fallback" from CLAUDE.md's TODO.md, via the
            // OS's own credential check rather than a custom stored PIN.
            // persistAcrossBackgrounding: true keeps the auth attempt
            // alive through the biometric prompt's own system overlay
            // taking focus, rather than treating that as a cancellation.
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          );

      if (!mounted) return;
      if (didAuthenticate) {
        ref.read(isUnlockedProvider.notifier).unlock();
      } else {
        setState(() => _errorMessage = l10n.appLockFailedMessage);
      }
    } on LocalAuthException {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.appLockUnavailableMessage);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CashlyLogoMark(size: 72),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.appLockTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.appLockReasonMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.appLockUnlockButton,
                isLoading: _isAuthenticating,
                onPressed: _authenticate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
