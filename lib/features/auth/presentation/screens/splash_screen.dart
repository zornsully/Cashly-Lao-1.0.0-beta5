import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/cashly_logo_mark.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

/// Shown for the brief moment while Firebase restores a persisted session
/// before the router's redirect can decide where to send the user.
///
/// Two safety nets against getting stuck here forever — `redirect` treats
/// "loading" and "errored" identically (`!hasValue`), so without these the
/// splash screen would just hang silently:
/// - Watches [authStateChangesProvider] directly and shows [ErrorView] with
///   a retry if the stream ever throws.
/// - Falls back to a "taking longer than expected" message with a manual
///   retry after [_timeout] if the stream simply never emits at all (e.g.
///   the platform auth SDK itself hangs). A plain stream `.timeout()`
///   isn't used for this because it resets on every event — it would
///   misfire on a user who's already signed in and just sits on a screen
///   for a while, long after the first (successful) event already arrived.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _timeout = Duration(seconds: 12);

  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _armTimer();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _timedOut = false);
    _armTimer();
    ref.invalidate(authStateChangesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final Widget content;
    if (authState.hasError) {
      content = ErrorView(message: '${authState.error}', onRetry: _retry);
    } else if (_timedOut && !authState.hasValue) {
      content = ErrorView(
        message: l10n.splashTimeoutMessage,
        onRetry: _retry,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CashlyLogoMark(size: 72),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppLoadingIndicator(),
        ],
      );
    }

    return Scaffold(body: Center(child: content));
  }
}
