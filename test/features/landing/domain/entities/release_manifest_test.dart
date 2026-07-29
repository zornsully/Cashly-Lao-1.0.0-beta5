import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseManifest schema v2', () {
    test('parses a stable published release and selects its latest asset', () {
      final manifest = ReleaseManifest.fromJson(_validManifest());

      expect(manifest.schemaVersion, ReleaseManifest.currentSchemaVersion);
      expect(manifest.release?.tag, 'v1.2.3');
      expect(manifest.release?.commitSha, 'abcdef1234567');
      expect(manifest.isStable, isTrue);
      expect(
        manifest.latestStableReleaseFor(ReleasePlatform.android)?.artifactName,
        'Cashly-Lao-Android-1.2.3.apk',
      );
      expect(manifest.latestStableReleaseFor(ReleasePlatform.ios), isNull);
    });

    test('keeps schema v1 manifests as a non-downloadable fallback', () {
      final manifest = ReleaseManifest.fromJson(
        _validManifest(schemaVersion: 1),
      );

      expect(manifest.release, isNull);
      expect(manifest.isStable, isTrue);
      expect(manifest.latestStableReleaseFor(ReleasePlatform.android), isNull);
    });

    test(
      'parses prereleases but excludes them from public stable selection',
      () {
        final manifest = ReleaseManifest.fromJson(
          _validManifest(version: '1.3.0-beta.1', channel: 'prerelease'),
        );

        expect(manifest.isStable, isFalse);
        expect(
          manifest.latestStableReleaseFor(ReleasePlatform.android),
          isNull,
        );
      },
    );

    test('rejects duplicate platform entries', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms[1] = Map<String, dynamic>.from(platforms.first);

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a download asset reused by multiple platforms', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms[1] = {
        ...platforms.first,
        'platform': 'ios',
        'displayName': 'iOS',
        'actionLabel': 'Download for iOS',
      };

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-HTTPS artifact URL', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first['downloadUrl'] =
          'http://example.com/Cashly-Lao-Android-1.2.3.apk';

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an available asset with a missing checksum', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first.remove('sha256');

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('allows the canonical Firebase Hosting Android asset', () {
      final source = _validManifest();

      final manifest = ReleaseManifest.fromJson(source);

      expect(manifest.release?.tag, 'v1.2.3');
      expect(
        manifest.latestStableReleaseFor(ReleasePlatform.android)?.version,
        '1.2.3',
      );
    });

    test(
      'rejects Android metadata that disagrees with the release version',
      () {
        final source = _validManifest();
        final platforms = source['platforms']! as List<Map<String, dynamic>>;
        platforms.first['version'] = '1.2.2';
        platforms.first['artifactName'] = 'Cashly-Lao-Android-1.2.2.apk';
        platforms.first['downloadUrl'] =
            'https://cashly-lao.web.app/downloads/'
            'Cashly-Lao-Android-1.2.2.apk';

        expect(
          () => ReleaseManifest.fromJson(source),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('rejects an unsafe artifact filename and a URL mismatch', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first['artifactName'] = '../Cashly-Lao-Android-1.2.3.apk';

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an HTTPS download outside Firebase Hosting', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first['downloadUrl'] =
          'https://example.com/Cashly-Lao-Android-1.2.3.apk';

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a Firebase download with a non-canonical path', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first['downloadUrl'] =
          'https://cashly-lao.web.app/downloads/extra/'
          'Cashly-Lao-Android-1.2.3.apk';

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    for (final suffix in const [
      '?source=landing',
      '#download',
      '?source=landing#download',
    ]) {
      test('rejects a Firebase Android URL with $suffix', () {
        final source = _validManifest();
        final platforms = source['platforms']! as List<Map<String, dynamic>>;
        platforms.first['downloadUrl'] =
            'https://cashly-lao.web.app/downloads/'
            'Cashly-Lao-Android-1.2.3.apk$suffix';

        expect(
          () => ReleaseManifest.fromJson(source),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final authority in const [
      'cashly-lao.web.app:443',
      'trusted@cashly-lao.web.app',
      'cashly-lao.web.app.evil.example',
    ]) {
      test('rejects a Firebase Android URL with authority $authority', () {
        final source = _validManifest();
        final platforms = source['platforms']! as List<Map<String, dynamic>>;
        platforms.first['downloadUrl'] =
            'https://$authority/downloads/Cashly-Lao-Android-1.2.3.apk';

        expect(
          () => ReleaseManifest.fromJson(source),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('rejects a Firebase Android URL with an encoded path variant', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms.first['downloadUrl'] =
          'https://cashly-lao.web.app/downloads/'
          'Cashly-Lao-Android-1.2.3%2Eapk';

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-Android public artifact in schema v2', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms[1] = {
        ...platforms.first,
        'platform': 'ios',
        'displayName': 'iOS',
        'artifactName': 'Cashly-Lao-iOS-1.2.3.ipa',
        'downloadUrl':
            'https://cashly-lao.web.app/downloads/'
            'Cashly-Lao-iOS-1.2.3.ipa',
      };

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'does not enable a manually constructed manifest with a non-canonical URL',
      () {
        final timestamp = DateTime.utc(2026, 7, 26);
        final manifest = ReleaseManifest(
          schemaVersion: ReleaseManifest.currentSchemaVersion,
          generatedAt: timestamp,
          release: ReleaseDescriptor(
            tag: 'v1.2.3',
            commitSha: 'abcdef1234567',
            channel: ReleaseChannel.stable,
            publishedAt: timestamp,
            releaseUrl: Uri.parse(
              'https://github.com/zornsully/Cashly-Lao-1.0.0-beta5/releases/'
              'tag/v1.2.3',
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
              version: '1.2.3',
              buildNumber: '3',
              releaseDate: timestamp,
              fileSizeBytes: 1048576,
              minimumOsVersion: 'Android 7.0+',
              releaseNotes: 'Signed release.',
              downloadUrl: Uri.parse(
                'https://cashly-lao.web.app/downloads/'
                'Cashly-Lao-Android-1.2.3.apk?source=manual',
              ),
              packageFormat: 'APK',
              installationNote: 'Install the signed APK.',
              sha256: 'A' * 64,
              artifactName: 'Cashly-Lao-Android-1.2.3.apk',
            ),
            _comingSoonRelease(ReleasePlatform.ios, 'iOS'),
            _comingSoonRelease(ReleasePlatform.windows, 'Windows'),
            _comingSoonRelease(ReleasePlatform.mac, 'Mac'),
          ],
        );

        expect(manifest.isTrustedForPublicDownload, isFalse);
        expect(
          manifest.latestStableReleaseFor(ReleasePlatform.android),
          isNull,
        );
      },
    );

    test('rejects an implausibly future-dated release manifest', () {
      final source = _validManifest();
      source['generatedAt'] = DateTime.now()
          .toUtc()
          .add(const Duration(days: 2))
          .toIso8601String();

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a coming-soon platform marked as the latest release', () {
      final source = _validManifest();
      final platforms = source['platforms']! as List<Map<String, dynamic>>;
      platforms[1]['isLatest'] = true;

      expect(
        () => ReleaseManifest.fromJson(source),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

PlatformRelease _comingSoonRelease(
  ReleasePlatform platform,
  String displayName,
) => PlatformRelease(
  platform: platform,
  displayName: displayName,
  availability: ReleaseAvailability.comingSoon,
  statusLabel: 'Coming soon',
  actionLabel: 'Coming soon',
  availabilityMessage: '$displayName support is coming soon.',
  isLatest: false,
);

Map<String, dynamic> _validManifest({
  int schemaVersion = 2,
  String version = '1.2.3',
  String channel = 'stable',
}) {
  final artifactName = 'Cashly-Lao-Android-$version.apk';
  return {
    'schemaVersion': schemaVersion,
    'generatedAt': '2026-07-26T00:00:00Z',
    if (schemaVersion >= ReleaseManifest.currentSchemaVersion)
      'release': {
        'tag': 'v$version',
        'commitSha': 'abcdef1234567',
        'channel': channel,
        'publishedAt': '2026-07-26T00:00:00Z',
        'releaseUrl':
            'https://github.com/zornsully/Cashly-Lao-1.0.0-beta5/releases/'
            'tag/v$version',
      },
    'platforms': [
      {
        'platform': 'android',
        'displayName': 'Android',
        'availability': 'available',
        'statusLabel': 'Latest release',
        'actionLabel': 'Download APK',
        'availabilityMessage': 'Android is ready to download.',
        'version': version,
        'buildNumber': '3',
        'releaseDate': '2026-07-26',
        'fileSizeBytes': 1048576,
        'minimumOsVersion': 'Android 7.0+',
        'releaseNotes': 'Signed release.',
        'downloadUrl': 'https://cashly-lao.web.app/downloads/$artifactName',
        'packageFormat': 'APK',
        'installationNote': 'Install the signed APK.',
        'sha256': 'A' * 64,
        if (schemaVersion >= ReleaseManifest.currentSchemaVersion)
          'artifactName': artifactName,
        if (schemaVersion >= ReleaseManifest.currentSchemaVersion)
          'isLatest': true,
      },
      _comingSoonPlatform('ios', 'iOS', schemaVersion),
      _comingSoonPlatform('windows', 'Windows', schemaVersion),
      _comingSoonPlatform('mac', 'Mac', schemaVersion),
    ],
  };
}

Map<String, dynamic> _comingSoonPlatform(
  String platform,
  String displayName,
  int schemaVersion,
) {
  return {
    'platform': platform,
    'displayName': displayName,
    'availability': 'coming_soon',
    'statusLabel': 'Coming soon',
    'actionLabel': 'Coming soon',
    'availabilityMessage': '$displayName support is coming soon.',
    if (schemaVersion >= ReleaseManifest.currentSchemaVersion)
      'isLatest': false,
  };
}
