import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

final _approvedPolicy = ReleaseDistributionPolicy.fromJson(const {
  'schemaVersion': 1,
  'repository': 'zornsully/Cashly-Lao-Releases',
});

void main() {
  group('ReleaseManifest public distribution policy', () {
    test('parses a reviewed public release and selects its latest APK', () {
      final manifest = _parse(_validManifest());

      expect(manifest.schemaVersion, ReleaseManifest.currentSchemaVersion);
      expect(
        manifest.release?.distributionRepository,
        _approvedPolicy.repository,
      );
      expect(manifest.release?.tag, 'v1.2.3');
      expect(manifest.isStable, isTrue);
      expect(
        manifest
            .latestStableReleaseFor(ReleasePlatform.android)
            ?.downloadUrl
            .toString(),
        'https://github.com/zornsully/Cashly-Lao-Releases/releases/download/'
        'v1.2.3/Cashly-Lao-Android-1.2.3.apk',
      );
    });

    test('fails closed when no public distribution repository is approved', () {
      expect(
        () => ReleaseManifest.fromJson(_validManifest()),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'keeps legacy schema manifests informational and non-downloadable',
      () {
        final manifest = _parse(_validManifest(schemaVersion: 1));

        expect(manifest.release, isNull);
        expect(
          manifest.latestStableReleaseFor(ReleasePlatform.android),
          isNull,
        );
      },
    );

    test(
      'parses prereleases but excludes them from public stable selection',
      () {
        final manifest = _parse(
          _validManifest(version: '1.3.0-beta.1', channel: 'prerelease'),
        );

        expect(manifest.isStable, isFalse);
        expect(
          manifest.latestStableReleaseFor(ReleasePlatform.android),
          isNull,
        );
      },
    );

    test('rejects a repository not in the bundled policy', () {
      final source = _validManifest();
      final release = source['release']! as Map<String, dynamic>;
      release['distributionRepository'] = 'zornsully/Cashly-Lao-1.0.0-beta5';
      release['releaseUrl'] =
          'https://github.com/zornsully/Cashly-Lao-1.0.0-beta5/releases/'
          'tag/v1.2.3';

      expect(() => _parse(source), throwsA(isA<FormatException>()));
    });

    test(
      'rejects a source-repository APK even with a valid public release',
      () {
        final source = _validManifest();
        _android(source)['downloadUrl'] =
            'https://github.com/zornsully/Cashly-Lao-1.0.0-beta5/releases/'
            'download/v1.2.3/Cashly-Lao-Android-1.2.3.apk';

        expect(() => _parse(source), throwsA(isA<FormatException>()));
      },
    );

    for (final suffix in const [
      '?source=landing',
      '#download',
      '?source=landing#download',
      '/',
    ]) {
      test('rejects a GitHub asset URL with $suffix', () {
        final source = _validManifest();
        _android(source)['downloadUrl'] =
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
            'download/v1.2.3/Cashly-Lao-Android-1.2.3.apk$suffix';

        expect(() => _parse(source), throwsA(isA<FormatException>()));
      });
    }

    for (final authority in const [
      'github.com:443',
      'trusted@github.com',
      'github.com.evil.example',
    ]) {
      test('rejects an APK URL with authority $authority', () {
        final source = _validManifest();
        _android(source)['downloadUrl'] =
            'https://$authority/zornsully/Cashly-Lao-Releases/releases/'
            'download/v1.2.3/Cashly-Lao-Android-1.2.3.apk';

        expect(() => _parse(source), throwsA(isA<FormatException>()));
      });
    }

    for (final replacement in const [
      'download/v1.2.2/Cashly-Lao-Android-1.2.3.apk',
      'download/v1.2.3/Cashly-Lao-Android-1.2.2.apk',
      'tag/v1.2.3/Cashly-Lao-Android-1.2.3.apk',
      'download/v1.2.3/Cashly-Lao-Android-1.2.3%2Eapk',
    ]) {
      test('rejects an APK URL path variant $replacement', () {
        final source = _validManifest();
        _android(source)['downloadUrl'] =
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
            '$replacement';

        expect(() => _parse(source), throwsA(isA<FormatException>()));
      });
    }

    test('rejects a release page from another tag or with a query', () {
      final source = _validManifest();
      final release = source['release']! as Map<String, dynamic>;
      release['releaseUrl'] =
          'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
          'tag/v1.2.2?draft=true';

      expect(() => _parse(source), throwsA(isA<FormatException>()));
    });

    test(
      'rejects duplicate platforms and duplicate published artifact names',
      () {
        final duplicatePlatform = _validManifest();
        final platforms =
            duplicatePlatform['platforms']! as List<Map<String, dynamic>>;
        platforms[1] = Map<String, dynamic>.from(platforms.first);
        expect(
          () => _parse(duplicatePlatform),
          throwsA(isA<FormatException>()),
        );

        final duplicateAsset = _validManifest();
        final duplicatePlatforms =
            duplicateAsset['platforms']! as List<Map<String, dynamic>>;
        duplicatePlatforms[1] = {
          ...duplicatePlatforms.first,
          'platform': 'ios',
          'displayName': 'iOS',
        };
        expect(() => _parse(duplicateAsset), throwsA(isA<FormatException>()));
      },
    );

    test('rejects missing checksums and unsafe artifact names', () {
      final missingChecksum = _validManifest();
      _android(missingChecksum).remove('sha256');
      expect(() => _parse(missingChecksum), throwsA(isA<FormatException>()));

      final unsafeName = _validManifest();
      _android(unsafeName)['artifactName'] = '../Cashly-Lao-Android-1.2.3.apk';
      expect(() => _parse(unsafeName), throwsA(isA<FormatException>()));
    });

    test('rejects a manually constructed manifest with an unapproved policy', () {
      final timestamp = DateTime.utc(2026, 7, 26);
      final manifest = ReleaseManifest(
        schemaVersion: ReleaseManifest.currentSchemaVersion,
        generatedAt: timestamp,
        release: ReleaseDescriptor(
          tag: 'v1.2.3',
          commitSha: 'abcdef1234567',
          channel: ReleaseChannel.stable,
          publishedAt: timestamp,
          distributionRepository: 'zornsully/Cashly-Lao-Releases',
          releaseUrl: Uri.parse(
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/tag/v1.2.3',
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
              'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
              'download/v1.2.3/Cashly-Lao-Android-1.2.3.apk',
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
      expect(manifest.latestStableReleaseFor(ReleasePlatform.android), isNull);
    });

    test('rejects a future-dated manifest and coming-soon latest flag', () {
      final future = _validManifest();
      future['generatedAt'] = DateTime.now()
          .toUtc()
          .add(const Duration(days: 2))
          .toIso8601String();
      expect(() => _parse(future), throwsA(isA<FormatException>()));

      final invalidLatest = _validManifest();
      final platforms =
          invalidLatest['platforms']! as List<Map<String, dynamic>>;
      platforms[1]['isLatest'] = true;
      expect(() => _parse(invalidLatest), throwsA(isA<FormatException>()));
    });
  });

  group('ReleaseManifest history', () {
    test('parses a valid history entry as a verified past release', () {
      final source = _validManifest();
      source['history'] = [_historyEntry(version: '1.2.2')];

      final manifest = _parse(source);

      expect(manifest.history, hasLength(1));
      expect(manifest.history.single.version, '1.2.2');
      expect(
        manifest.history.single.platformRelease.downloadUrl.toString(),
        'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
        'download/v1.2.2/Cashly-Lao-Android-1.2.2.apk',
      );
    });

    test('drops a malformed history entry instead of failing the manifest', () {
      final source = _validManifest();
      final entry = _historyEntry(version: '1.2.2');
      (entry['platform']! as Map<String, dynamic>).remove('sha256');
      source['history'] = [entry];

      expect(_parse(source).history, isEmpty);
    });

    test('drops a history entry that duplicates the current release tag', () {
      final source = _validManifest();
      source['history'] = [_historyEntry(version: '1.2.3')];

      expect(_parse(source).history, isEmpty);
    });

    test('drops a prerelease history entry', () {
      final source = _validManifest();
      source['history'] = [
        _historyEntry(version: '1.3.0-beta.1', channel: 'prerelease'),
      ];

      expect(_parse(source).history, isEmpty);
    });

    test('drops a history entry incorrectly marked as latest', () {
      final source = _validManifest();
      final entry = _historyEntry(version: '1.2.2');
      (entry['platform']! as Map<String, dynamic>)['isLatest'] = true;
      source['history'] = [entry];

      expect(_parse(source).history, isEmpty);
    });

    test('sorts history newest-first and caps it at 10 entries', () {
      final source = _validManifest();
      source['history'] = List.generate(12, (index) {
        final entry = _historyEntry(version: '1.0.${index + 1}');
        (entry['release']! as Map<String, dynamic>)['publishedAt'] =
            DateTime.utc(2026, 1, index + 1).toIso8601String();
        return entry;
      });

      final manifest = _parse(source);

      expect(manifest.history, hasLength(10));
      expect(manifest.history.first.version, '1.0.12');
      expect(manifest.history.last.version, '1.0.3');
    });
  });
}

Map<String, dynamic> _historyEntry({
  required String version,
  String channel = 'stable',
}) {
  final tag = 'v$version';
  final artifactName = 'Cashly-Lao-Android-$version.apk';
  return {
    'release': {
      'tag': tag,
      'commitSha': 'abcdef1234567',
      'channel': channel,
      'publishedAt': '2026-06-01T00:00:00Z',
      'distributionRepository': 'zornsully/Cashly-Lao-Releases',
      'releaseUrl':
          'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
          'tag/$tag',
    },
    'platform': {
      'platform': 'android',
      'displayName': 'Android',
      'availability': 'available',
      'statusLabel': 'Latest release',
      'actionLabel': 'Download APK',
      'availabilityMessage': 'Android is ready to download.',
      'version': version,
      'buildNumber': '2',
      'releaseDate': '2026-06-01',
      'fileSizeBytes': 1000000,
      'minimumOsVersion': 'Android 7.0+',
      'releaseNotes': 'Signed release.',
      'downloadUrl':
          'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
          'download/$tag/$artifactName',
      'packageFormat': 'APK',
      'installationNote': 'Install the signed APK.',
      'sha256': 'B' * 64,
      'artifactName': artifactName,
      'isLatest': false,
    },
  };
}

ReleaseManifest _parse(Map<String, dynamic> source) =>
    ReleaseManifest.fromJson(source, distributionPolicy: _approvedPolicy);

Map<String, dynamic> _android(Map<String, dynamic> source) =>
    (source['platforms']! as List<Map<String, dynamic>>).first;

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
  int schemaVersion = 3,
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
        'distributionRepository': 'zornsully/Cashly-Lao-Releases',
        'releaseUrl':
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
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
        'downloadUrl':
            'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
            'download/v$version/$artifactName',
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
