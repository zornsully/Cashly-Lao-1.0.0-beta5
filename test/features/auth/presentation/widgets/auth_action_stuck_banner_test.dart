import 'package:cashly_lao/features/auth/presentation/providers/auth_controller.dart';
import 'package:cashly_lao/features/auth/presentation/widgets/auth_action_stuck_banner.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never resolves on its own -- mirrors the still-unexplained production
/// bug this banner defends against, where `AuthController`'s state is
/// loading from the very first frame with no in-flight `_run()` call ever
/// completing it.
class _AlwaysLoadingAuthController extends AuthController {
  @override
  AsyncValue<void> build() => const AsyncLoading();
}

/// Resolves to data on its own after a short delay, like a normal,
/// healthy sign-in attempt well within `_run()`'s own 30-second timeout.
class _BrieflyLoadingAuthController extends AuthController {
  @override
  AsyncValue<void> build() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      state = const AsyncData(null);
    });
    return const AsyncLoading();
  }
}

Future<void> _pumpBanner(
  WidgetTester tester,
  AuthController Function() controller,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(controller)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AuthActionStuckBanner()),
      ),
    ),
  );
}

void main() {
  testWidgets('shows nothing while an action is only briefly loading', (
    tester,
  ) async {
    await _pumpBanner(tester, _BrieflyLoadingAuthController.new);

    expect(find.byType(AuthActionStuckBanner), findsOneWidget);
    expect(find.text('This is taking longer than expected.'), findsNothing);

    // Resolves well before the stuck threshold; still nothing shown.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('This is taking longer than expected.'), findsNothing);
  });

  testWidgets(
    'shows a retry banner once loading outlives the stuck threshold',
    (tester) async {
      await _pumpBanner(tester, _AlwaysLoadingAuthController.new);

      expect(find.text('This is taking longer than expected.'), findsNothing);

      await tester.pump(const Duration(seconds: 40));

      expect(find.text('This is taking longer than expected.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets('tapping retry hides the banner immediately', (tester) async {
    await _pumpBanner(tester, _AlwaysLoadingAuthController.new);
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('This is taking longer than expected.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.text('This is taking longer than expected.'), findsNothing);
  });
}
