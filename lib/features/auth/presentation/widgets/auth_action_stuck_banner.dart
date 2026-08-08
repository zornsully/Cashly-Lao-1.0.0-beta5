import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_controller.dart';

/// Drop into any screen that drives [PrimaryButton]/[GoogleSignInButton]
/// loading state from [authControllerProvider]. `AuthController._run()`
/// already bounds any action it actually starts to 30 seconds, but a rare,
/// still-unexplained production issue has left that loading state on
/// indefinitely without `_run()` ever having been entered, permanently
/// disabling every auth control on the screen with no way to recover short
/// of a full page reload. This is a safety net, not a fix for that root
/// cause: past a window longer than `_run()` itself would ever legitimately
/// take, offer a way to force the provider back to a clean state.
class AuthActionStuckBanner extends ConsumerStatefulWidget {
  const AuthActionStuckBanner({super.key});

  @override
  ConsumerState<AuthActionStuckBanner> createState() =>
      _AuthActionStuckBannerState();
}

class _AuthActionStuckBannerState extends ConsumerState<AuthActionStuckBanner> {
  // Comfortably longer than _run()'s own 30-second timeout so this never
  // fires for a real, still-in-flight action -- only for loading state that
  // outlived every legitimate way `_run()` itself would have cleared it.
  static const _stuckThreshold = Duration(seconds: 40);

  Timer? _timer;
  bool _stuck = false;

  @override
  void initState() {
    super.initState();
    final alreadyLoading = ref.read(authControllerProvider).isLoading;
    debugPrint(
      'AuthActionStuckBanner: mounted, alreadyLoading=$alreadyLoading',
    );
    if (alreadyLoading) _startTimer();
  }

  void _startTimer() {
    debugPrint(
      'AuthActionStuckBanner: starting ${_stuckThreshold.inSeconds}s timer',
    );
    _timer?.cancel();
    _timer = Timer(_stuckThreshold, () {
      debugPrint('AuthActionStuckBanner: threshold reached, showing retry');
      if (mounted) setState(() => _stuck = true);
    });
  }

  void _cancelTimer() {
    if (_timer != null) debugPrint('AuthActionStuckBanner: cancelling timer');
    _timer?.cancel();
    _timer = null;
    if (_stuck && mounted) setState(() => _stuck = false);
  }

  void _retry() {
    debugPrint(
      'AuthActionStuckBanner: retry tapped, invalidating authControllerProvider',
    );
    ref.invalidate(authControllerProvider);
    _cancelTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      debugPrint(
        'AuthActionStuckBanner: authControllerProvider changed '
        '${previous.runtimeType} -> ${next.runtimeType}, isLoading=${next.isLoading}',
      );
      if (next.isLoading) {
        _startTimer();
      } else {
        _cancelTimer();
      }
    });

    if (!_stuck) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          Text(
            l10n.authActionStuckMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _retry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
