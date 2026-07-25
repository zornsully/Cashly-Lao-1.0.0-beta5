import 'package:cashly_lao/core/providers/connectivity_providers.dart';
import 'package:cashly_lao/core/widgets/sync_status_banner.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Stream<bool> isOnlineStream) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isOnlineProvider.overrideWith((ref) => isOnlineStream)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SyncStatusBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows nothing while online', (tester) async {
    await pump(tester, Stream.value(true));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.offlineBannerMessage), findsNothing);
  });

  testWidgets('shows the offline message while offline', (tester) async {
    await pump(tester, Stream.value(false));

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.offlineBannerMessage), findsOneWidget);
  });

  testWidgets('shows nothing while the connectivity stream is still loading', (
    tester,
  ) async {
    await pump(tester, const Stream.empty());

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.offlineBannerMessage), findsNothing);
  });
}
