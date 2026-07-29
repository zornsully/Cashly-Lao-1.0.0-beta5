import 'package:cashly_lao/features/landing/presentation/screens/landing_page.dart';
import 'package:cashly_lao/features/landing/data/services/hosted_release_manifest_service.dart';
import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart';
import 'package:cashly_lao/features/landing/domain/services/release_manifest_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Cashly Lao product page and official APK release', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage(
          releaseManifestService: _StaticReleaseManifestService(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Take Control\nof Your Money.'), findsOneWidget);
    expect(find.text('DOWNLOAD'), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    expect(find.text('iOS'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Mac'), findsOneWidget);
    expect(find.text('v1.0.1'), findsOneWidget);
    expect(find.text('Latest release'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(3));
    final androidPosition = tester.getTopLeft(find.text('Android'));
    final iosPosition = tester.getTopLeft(find.text('iOS'));
    final windowsPosition = tester.getTopLeft(find.text('Windows'));
    final macPosition = tester.getTopLeft(find.text('Mac'));
    expect(androidPosition.dy, iosPosition.dy);
    expect(iosPosition.dy, windowsPosition.dy);
    expect(windowsPosition.dy, macPosition.dy);
    expect(androidPosition.dx, lessThan(iosPosition.dx));
    expect(iosPosition.dx, lessThan(windowsPosition.dx));
    expect(windowsPosition.dx, lessThan(macPosition.dx));
    expect(find.text('Expense Tracking'), findsOneWidget);
    expect(find.text('Financial Insights'), findsOneWidget);
    expect(find.text('Budgets'), findsNWidgets(2));
    expect(find.text('Accounts'), findsNWidgets(2));
    expect(find.text('Goals'), findsNWidgets(2));
    expect(find.text('Private and Secure'), findsOneWidget);
    expect(find.text('Version 1.0.1'), findsOneWidget);
    expect(find.text('Android 7.0+'), findsOneWidget);
    expect(find.text('Is Cashly Lao free?'), findsOneWidget);
    expect(find.text('Which platforms are supported?'), findsOneWidget);
    expect(
      find.text('How is the Smart Money Score calculated?'),
      findsOneWidget,
    );
    expect(
      find.text('Where can I download the latest release?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the compact navigation safe on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage(
          releaseManifestService: _StaticReleaseManifestService(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Cashly Lao'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.text('Android'), findsOneWidget);
    expect(find.text('iOS'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Mac'), findsOneWidget);
    final androidPosition = tester.getTopLeft(find.text('Android'));
    final iosPosition = tester.getTopLeft(find.text('iOS'));
    final windowsPosition = tester.getTopLeft(find.text('Windows'));
    final macPosition = tester.getTopLeft(find.text('Mac'));
    expect(androidPosition.dy, iosPosition.dy);
    expect(windowsPosition.dy, macPosition.dy);
    expect(windowsPosition.dy, greaterThan(androidPosition.dy));
    expect(androidPosition.dx, lessThan(iosPosition.dx));
    expect(windowsPosition.dx, lessThan(macPosition.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps verified fallback details visible with a refresh action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage(
          releaseManifestService: _StaticReleaseManifestService(
            source: ReleaseManifestSource.persistentCache,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text(
        'Showing the last verified release details while the release channel reconnects.',
      ),
      findsOneWidget,
    );
    expect(find.text('Refresh release details'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a friendly retry state without unverified metadata', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: LandingPage(
          releaseManifestService: _FailingReleaseManifestService(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Release channel unavailable.'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StaticReleaseManifestService implements ReleaseManifestService {
  _StaticReleaseManifestService({this.source = ReleaseManifestSource.unknown});

  final ReleaseManifestSource source;

  @override
  Future<ReleaseManifest> loadLatest() {
    return Future.value(
      ReleaseManifest(
        schemaVersion: ReleaseManifest.currentSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 26),
        source: source,
        release: ReleaseDescriptor(
          tag: 'v1.0.1',
          commitSha: 'b9234493d7f92b32f191c87ac4b2988e24f9ca7b',
          channel: ReleaseChannel.stable,
          publishedAt: DateTime.utc(2026, 7, 26),
          releaseUrl: Uri.parse(
            'https://github.com/zornsully/Cashly-Lao-1.0.0-beta5/releases/'
            'tag/v1.0.1',
          ),
        ),
        platforms: [
          PlatformRelease(
            platform: ReleasePlatform.android,
            displayName: 'Android',
            availability: ReleaseAvailability.available,
            statusLabel: 'Latest release',
            actionLabel: 'Download APK',
            availabilityMessage: 'Android is ready to download.',
            version: '1.0.1',
            buildNumber: '2',
            releaseDate: DateTime.utc(2026, 7, 25),
            fileSizeBytes: 39425046,
            minimumOsVersion: 'Android 7.0+',
            releaseNotes: 'Signed release.',
            downloadUrl: Uri.parse(
              'https://cashly-lao.web.app/downloads/'
              'Cashly-Lao-Android-1.0.1.apk',
            ),
            packageFormat: 'APK package',
            installationNote: 'Install the signed APK.',
            sha256:
                'A4D7E620ADC232342C2B52EDAE1D1EE6D291C00BC807FB86D6D8ACB1CEBFD772',
            artifactName: 'Cashly-Lao-Android-1.0.1.apk',
            isLatest: true,
          ),
          const PlatformRelease(
            platform: ReleasePlatform.ios,
            displayName: 'iOS',
            availability: ReleaseAvailability.comingSoon,
            statusLabel: 'Coming soon',
            actionLabel: 'Coming soon',
            availabilityMessage: 'iOS support is coming soon.',
          ),
          const PlatformRelease(
            platform: ReleasePlatform.windows,
            displayName: 'Windows',
            availability: ReleaseAvailability.comingSoon,
            statusLabel: 'Coming soon',
            actionLabel: 'Coming soon',
            availabilityMessage: 'Windows support is coming soon.',
          ),
          const PlatformRelease(
            platform: ReleasePlatform.mac,
            displayName: 'Mac',
            availability: ReleaseAvailability.comingSoon,
            statusLabel: 'Coming soon',
            actionLabel: 'Coming soon',
            availabilityMessage: 'Mac support is coming soon.',
          ),
        ],
      ),
    );
  }
}

class _FailingReleaseManifestService implements ReleaseManifestService {
  const _FailingReleaseManifestService();

  @override
  Future<ReleaseManifest> loadLatest() {
    return Future<ReleaseManifest>.error(
      const ReleaseManifestFetchException('Release channel unavailable.'),
    );
  }
}
