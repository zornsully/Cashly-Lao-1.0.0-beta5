import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_symbols.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

const int _resendCooldownSeconds = 30;

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsRemaining = _resendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendEmailVerification();

    if (!mounted) return;

    if (success) {
      _startCooldown();
      AppSnackbar.showSuccess(context, l10n.verificationEmailSentMessage);
    } else {
      final message =
          ref.read(authControllerProvider.notifier).failure?.message ??
          l10n.resendFailedMessage;
      AppSnackbar.showError(context, message);
    }
  }

  Future<void> _checkVerified() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(authControllerProvider.notifier)
        .reloadUser();

    if (!mounted || success) return;

    final message =
        ref.read(authControllerProvider.notifier).failure?.message ??
        l10n.notVerifiedYetMessage;
    AppSnackbar.showError(context, message);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final email = ref.watch(authStateChangesProvider).value?.email ?? '';
    final l10n = AppLocalizations.of(context)!;

    return AuthScaffold(
      title: l10n.verifyEmailTitle,
      subtitle: l10n.verifyEmailSubtitle(email),
      children: [
        Icon(
          AppSymbols.markEmailUnread,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: l10n.verifiedButton,
          isLoading: isLoading,
          onPressed: _checkVerified,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: (isLoading || _secondsRemaining > 0) ? null : _resend,
          child: Text(
            _secondsRemaining > 0
                ? l10n.resendEmailCountdownButton(_secondsRemaining)
                : l10n.resendEmailButton,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isLoading ? null : _signOut,
          child: Text(l10n.signOutButton),
        ),
      ],
    );
  }
}
