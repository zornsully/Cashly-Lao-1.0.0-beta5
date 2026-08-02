import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/providers/app_lock_state_provider.dart';
import 'core/providers/presence_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
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
        (_) {
          if (mounted) ref.invalidate(authStateChangesProvider);
        },
        // Failure is logged by main.dart. The public shell and login page
        // remain available with their own recoverable service states.
        onError: (Object error, StackTrace stackTrace) {},
      );
    }
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
    final preferences = kIsWeb ? null : ref.watch(userPreferencesProvider).value;
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
    );
  }
}
