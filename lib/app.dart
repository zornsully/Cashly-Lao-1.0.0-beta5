import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/providers/app_lock_state_provider.dart';
import 'core/providers/firebase_providers.dart';
import 'core/providers/presence_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/auth_debug_log.dart';
import 'core/widgets/auth_debug_overlay.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'l10n/app_localizations.dart';

class CashlyApp extends ConsumerStatefulWidget {
  const CashlyApp({this.webServicesReady, super.key});

  /// The web app renders immediately, but Auth must be retried once Firebase
  /// completes initialization. This prevents an early Auth subscription from
  /// keeping the router on the splash route forever.
  final Future<void>? webServicesReady;

  @override
  ConsumerState<CashlyApp> createState() => _CashlyAppState();
}

class _CashlyAppState extends ConsumerState<CashlyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final webServicesReady = widget.webServicesReady;
    if (kIsWeb && webServicesReady != null) {
      webServicesReady.then(
        (_) => _recoverFirebaseProviders(),
        // Failure is logged by main.dart. The public shell and login page
        // remain available with their own recoverable service states.
        onError: (Object error, StackTrace stackTrace) {},
      );
    }
  }

  /// Router redirects read `authStateChangesProvider` from the very first
  /// frame -- before `webServicesReady` has any chance to resolve -- so
  /// `firebaseAuthProvider`/`firestoreProvider` almost always make their
  /// *first* real construction attempt while `Firebase.initializeApp()` is
  /// still in flight. Both are plain `Provider`s, so a failed attempt
  /// caches that error forever; invalidating only `authStateChangesProvider`
  /// just re-reads that same cached failure through `authRepositoryProvider`
  /// -> `authRemoteDataSourceProvider` without ever giving
  /// `FirebaseAuth.instance`/`FirebaseFirestore.instance` a fresh attempt --
  /// same fix, and same reasoning, as `AuthController._runWithRetry`.
  ///
  /// One invalidation right when `webServicesReady` resolves is not always
  /// enough on its own, confirmed directly against the live site: even
  /// *after* `Firebase.initializeApp()` reports success, the very next
  /// construction attempt can still fail once more with the same
  /// `firebase/flutterfire#18548` TypeError before a subsequent attempt
  /// succeeds -- some part of the JS SDK's own async setup evidently
  /// settles slightly later than `initializeApp()`'s own promise. Retrying
  /// a few times, a short delay apart, absorbs that instead of leaving the
  /// user stuck on an errored auth state for the rest of the page's
  /// lifetime.
  Future<void> _recoverFirebaseProviders() async {
    const maxAttempts = 4;
    const retryDelay = Duration(milliseconds: 400);
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!mounted) return;
      AuthDebugLog.log(
        '[AUTH-12] webServicesReady resolved -- invalidating '
        'firebaseAuthProvider/firestoreProvider/authStateChangesProvider '
        '(attempt $attempt/$maxAttempts)',
      );
      ref.invalidate(firebaseAuthProvider);
      ref.invalidate(firestoreProvider);
      ref.invalidate(authStateChangesProvider);
      if (!mounted) return;
      // Let the invalidated providers actually rebuild before checking --
      // invalidation marks them dirty but the rebuild itself still runs
      // asynchronously through the `ref.watch` chain.
      await Future<void>.delayed(retryDelay);
      if (!mounted) return;
      if (!ref.read(authStateChangesProvider).hasError) {
        AuthDebugLog.log('[AUTH-12] recovered on attempt $attempt');
        return;
      }
    }
    AuthDebugLog.log(
      '[AUTH-12] still erroring after $maxAttempts attempts -- giving up; '
      'AuthController._runWithRetry remains as a per-action fallback',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only a full backgrounding re-locks — not `inactive`, which also
    // fires momentarily when the biometric prompt's own system overlay
    // takes focus, which would otherwise immediately undo the very
    // authentication it's in the middle of.
    if (state == AppLifecycleState.paused) {
      ref.read(isUnlockedProvider.notifier).lock();
    }
    if (state == AppLifecycleState.resumed) {
      pingPresenceNow(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Falls back to the system theme / a null locale while preferences are
    // loading or the user isn't signed in yet (auth-gated screens render
    // before any preferences stream exists). A null locale lets
    // MaterialApp resolve from the device's own locale against
    // supportedLocales, landing on English for any device not already set
    // to Lao — the same safe default as the stored preference itself.
    final preferences = kIsWeb
        ? null
        : ref.watch(userPreferencesProvider).value;
    final themeMode = preferences?.themeMode.themeMode ?? ThemeMode.system;
    final locale = preferences?.language.locale;
    // MaterialApp's `locale:` only drives ARB-based AppLocalizations lookups
    // — raw `package:intl` calls (DateFormat, used for every month/date
    // label across the app) read from this separate global instead, so it
    // has to be kept in sync by hand or dates silently stay English even
    // once the rest of a screen is in Lao.
    if (locale != null) {
      Intl.defaultLocale = locale.toLanguageTag();
    }

    return MaterialApp.router(
      title: 'Cashly Lao',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // TEMPORARY: mirrors the [AUTH-NN] console trail directly on screen
      // (behind every route) so a plain screenshot shows exactly where a
      // login attempt stalled, without needing DevTools. Remove once the
      // live web auth investigation is closed.
      builder: kIsWeb
          ? (context, child) =>
                AuthDebugOverlay(child: child ?? const SizedBox.shrink())
          : null,
    );
  }
}
