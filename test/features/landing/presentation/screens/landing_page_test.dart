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
    expect(find.text('Explore features'), findsOneWidget);
    expect(find.text('View screenshots'), findsOneWidget);
    expect(find.text('Get Cashly Lao'), findsOneWidget);
    expect(find.text('Expense Tracking'), findsNothing);
    expect(find.text('Where can I download the latest release?'), findsNothing);
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
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows verified version history when the manifest has it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage.download(
          releaseManifestService: _StaticReleaseManifestService(
            history: [
              ReleaseHistoryEntry(
                release: ReleaseDescriptor(
                  tag: 'v1.0.0',
                  commitSha: 'a9234493d7f92b32f191c87ac4b2988e24f9ca7b',
                  channel: ReleaseChannel.stable,
                  publishedAt: DateTime.utc(2026, 7, 1),
                  distributionRepository: 'zornsully/Cashly-Lao-Releases',
                  releaseUrl: Uri.parse(
                    'https://github.com/zornsully/Cashly-Lao-Releases/'
                    'releases/tag/v1.0.0',
                  ),
                ),
                platformRelease: PlatformRelease(
                  platform: ReleasePlatform.android,
                  displayName: 'Android',
                  availability: ReleaseAvailability.available,
                  statusLabel: 'Latest release',
                  actionLabel: 'Download APK',
                  availabilityMessage: 'Android is ready to download.',
                  version: '1.0.0',
                  buildNumber: '1',
                  releaseDate: DateTime.utc(2026, 6, 30),
                  fileSizeBytes: 38000000,
                  minimumOsVersion: 'Android 7.0+',
                  releaseNotes: 'Signed release.',
                  downloadUrl: Uri.parse(
                    'https://github.com/zornsully/Cashly-Lao-Releases/'
                    'releases/download/v1.0.0/Cashly-Lao-Android-1.0.0.apk',
                  ),
                  packageFormat: 'APK package',
                  installationNote: 'Install the signed APK.',
                  sha256:
                      'A4D7E620ADC232342C2B52EDAE1D1EE6D291C00BC807FB86D6D8ACB1CEBFD772',
                  artifactName: 'Cashly-Lao-Android-1.0.0.apk',
                  isLatest: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // The version history section only mounts once the release manifest
    // future resolves, so its own _FadeInUp delay timer is created mid-pump
    // — an extra zero-duration pump lets that resolution/rebuild happen
    // before the following duration pump tries to flush the new timer.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('RELEASE HISTORY'), findsOneWidget);
    expect(find.text('Cashly Lao v1.0.0'), findsOneWidget);
    expect(find.text('Download APK'), findsWidgets);
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders each marketing detail page independently', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LandingPage.features()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Expense Tracking'), findsOneWidget);
    expect(
      find.text('A beautiful view of your everyday finances.'),
      findsNothing,
    );

    await tester.pumpWidget(const MaterialApp(home: LandingPage.screenshots()));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('A beautiful view of your everyday finances.'),
      findsOneWidget,
    );
    expect(find.text('Expense Tracking'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: LandingPage.privacy()));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Your financial life is private by design.'),
      findsOneWidget,
    );
  });
}

class _StaticReleaseManifestService implements ReleaseManifestService {
  _StaticReleaseManifestService({
    this.source = ReleaseManifestSource.unknown,
    this.history = const [],
  });

  final ReleaseManifestSource source;
  final List<ReleaseHistoryEntry> history;

  @override
  Future<ReleaseManifest> loadLatest() {
    return Future.value(
      ReleaseManifest(
        schemaVersion: ReleaseManifest.currentSchemaVersion,
        generatedAt: DateTime.utc(2026, 7, 26),
        source: source,
        history: history,
        distributionPolicy: ReleaseDistributionPolicy.fromJson(const {
          'schemaVersion': 1,
          'repository': 'zornsully/Cashly-Lao-Releases',
        }),
        release: ReleaseDescriptor(
          tag: 'v1.0.1',
          commitSha: 'b9234493d7f92b32f191c87ac4b2988e24f9ca7b',
          channel: ReleaseChannel.stable,
          publishedAt: DateTime.utc(2026, 7, 26),
          distributionRepository: 'zornsully/Cashly-Lao-Releases',
          releaseUrl: Uri.parse(
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
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
              'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
              'download/v1.0.1/Cashly-Lao-Android-1.0.1.apk',
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
