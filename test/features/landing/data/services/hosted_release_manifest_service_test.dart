import 'dart:convert';

import 'package:cashly_lao/features/landing/data/services/hosted_release_manifest_service.dart';
import 'package:cashly_lao/features/landing/data/services/release_manifest_cache.dart';
import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

final _approvedPolicy = ReleaseDistributionPolicy.fromJson(const {
  'schemaVersion': 1,
  'repository': 'zornsully/Cashly-Lao-Releases',
});

void main() {
  group('HostedReleaseManifestService', () {
    test(
      'uses and persists a verified current stable hosted manifest',
      () async {
        final cache = _MemoryReleaseManifestCache();
        final service = HostedReleaseManifestService(
          client: _StubHttpClient.ok(_manifestJson(version: '9.2.0')),
          assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
          cache: cache,
          manifestUri: Uri.parse('https://example.com/release-manifest.json'),
          distributionPolicy: _approvedPolicy,
        );

        final manifest = await service.loadLatest();
        final android = manifest.latestStableReleaseFor(
          ReleasePlatform.android,
        );

        expect(manifest.source, ReleaseManifestSource.network);
        expect(android?.version, '9.2.0');
        expect(
          android?.downloadUrl.toString(),
          'https://github.com/zornsully/Cashly-Lao-Releases/releases/'
          'download/v9.2.0/Cashly-Lao-Android-9.2.0.apk',
        );
        expect(android?.isAvailable, isTrue);
        expect(cache.value, isNotNull);
        expect(
          ReleaseManifest.fromJson(
            jsonDecode(cache.value!) as Map<String, dynamic>,
            distributionPolicy: _approvedPolicy,
          ).release?.tag,
          'v9.2.0',
        );
      },
    );

    test('uses a persisted verified manifest for an HTTP failure', () async {
      final cache = _MemoryReleaseManifestCache(
        _manifestJson(version: '2.4.0'),
      );
      final service = HostedReleaseManifestService(
        client: _StubHttpClient.status(503),
        assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
        cache: cache,
        manifestUri: Uri.parse('https://example.com/release-manifest.json'),
        distributionPolicy: _approvedPolicy,
      );

      final manifest = await service.loadLatest();

      expect(manifest.source, ReleaseManifestSource.persistentCache);
      expect(manifest.release?.tag, 'v2.4.0');
    });

    test('uses a fresh verified network manifest instead of a cache', () async {
      final cachedSource = _manifestJson(version: '2.5.0');
      final cache = _MemoryReleaseManifestCache(cachedSource);
      final service = HostedReleaseManifestService(
        client: _StubHttpClient.ok(_manifestJson(version: '2.4.0')),
        assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
        cache: cache,
        manifestUri: Uri.parse('https://example.com/release-manifest.json'),
        distributionPolicy: _approvedPolicy,
      );

      final manifest = await service.loadLatest();

      expect(manifest.source, ReleaseManifestSource.network);
      expect(manifest.release?.tag, 'v2.4.0');
      expect(cache.value, isNot(cachedSource));
      expect(cache.writeCount, 1);
    });

    test(
      'rejects a prerelease network manifest and retains stable cache',
      () async {
        final cache = _MemoryReleaseManifestCache(
          _manifestJson(version: '2.5.0'),
        );
        final service = HostedReleaseManifestService(
          client: _StubHttpClient.ok(
            _manifestJson(version: '2.6.0-beta.1', channel: 'prerelease'),
          ),
          assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
          cache: cache,
          manifestUri: Uri.parse('https://example.com/release-manifest.json'),
          distributionPolicy: _approvedPolicy,
        );

        final manifest = await service.loadLatest();

        expect(manifest.source, ReleaseManifestSource.persistentCache);
        expect(manifest.release?.tag, 'v2.5.0');
        expect(cache.writeCount, 0);
      },
    );

    test(
      'uses the bundled verified manifest when no cache can recover',
      () async {
        final service = HostedReleaseManifestService(
          client: _StubHttpClient.offline(),
          assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
          cache: _MemoryReleaseManifestCache('{not json'),
          manifestUri: Uri.parse('https://example.com/release-manifest.json'),
          distributionPolicy: _approvedPolicy,
        );

        final manifest = await service.loadLatest();

        expect(manifest.source, ReleaseManifestSource.bundledFallback);
        expect(manifest.releaseFor(ReleasePlatform.android)?.version, '1.0.1');
        expect(
          manifest.releaseFor(ReleasePlatform.windows)?.availability,
          ReleaseAvailability.comingSoon,
        );
      },
    );

    test(
      'shows a legacy bundled manifest without enabling a download',
      () async {
        final service = HostedReleaseManifestService(
          client: _StubHttpClient.offline(),
          assetBundle: _StringAssetBundle(
            _manifestJson(version: '1.0.1', schemaVersion: 1),
          ),
          cache: _MemoryReleaseManifestCache(),
          manifestUri: Uri.parse('https://example.com/release-manifest.json'),
          distributionPolicy: _approvedPolicy,
        );

        final manifest = await service.loadLatest();

        expect(manifest.source, ReleaseManifestSource.bundledFallback);
        expect(manifest.schemaVersion, 1);
        expect(
          manifest.latestStableReleaseFor(ReleasePlatform.android),
          isNull,
        );
      },
    );

    test('round-trips history through the persisted cache', () async {
      final cache = _MemoryReleaseManifestCache();
      final networkJson = jsonEncode(
        _manifestMap(
          version: '9.2.0',
          schemaVersion: ReleaseManifest.currentSchemaVersion,
          generatedAt: DateTime.now().toUtc().toIso8601String(),
        )..['history'] = [_historyEntryJson(version: '9.1.0')],
      );
      final service = HostedReleaseManifestService(
        client: _StubHttpClient.ok(networkJson),
        assetBundle: _StringAssetBundle(_manifestJson(version: '1.0.1')),
        cache: cache,
        manifestUri: Uri.parse('https://example.com/release-manifest.json'),
        distributionPolicy: _approvedPolicy,
      );

      final manifest = await service.loadLatest();

      expect(manifest.history, hasLength(1));
      expect(manifest.history.single.version, '9.1.0');

      final cachedManifest = ReleaseManifest.fromJson(
        jsonDecode(cache.value!) as Map<String, dynamic>,
        distributionPolicy: _approvedPolicy,
      );
      expect(cachedManifest.history, hasLength(1));
      expect(cachedManifest.history.single.version, '9.1.0');
    });

    test(
      'fails with no metadata rather than exposing an unverified release',
      () {
        final service = HostedReleaseManifestService(
          client: _StubHttpClient.status(500),
          assetBundle: _FailingAssetBundle(),
          cache: _MemoryReleaseManifestCache(),
          manifestUri: Uri.parse('https://example.com/release-manifest.json'),
          distributionPolicy: _approvedPolicy,
        );

        expect(
          service.loadLatest(),
          throwsA(isA<ReleaseManifestFetchException>()),
        );
      },
    );
  });
}

class _StubHttpClient extends http.BaseClient {
  _StubHttpClient(this._handler);

  factory _StubHttpClient.ok(String body) {
    return _StubHttpClient(
      (_) async => http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(body)),
        200,
      ),
    );
  }

  factory _StubHttpClient.status(int statusCode) {
    return _StubHttpClient(
      (_) async =>
          http.StreamedResponse(const Stream<List<int>>.empty(), statusCode),
    );
  }

  factory _StubHttpClient.offline() {
    return _StubHttpClient(
      (_) => Future<http.StreamedResponse>.error(
        http.ClientException('Network error'),
      ),
    );
  }

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

class _MemoryReleaseManifestCache implements ReleaseManifestCache {
  _MemoryReleaseManifestCache([this.value]);

  String? value;
  var writeCount = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String manifestJson) async {
    writeCount += 1;
    value = manifestJson;
  }
}

class _StringAssetBundle extends AssetBundle {
  _StringAssetBundle(this.value);

  final String value;

  @override
  Future<ByteData> load(String key) async {
    final data = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(data);
  }
}

class _FailingAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) {
    return Future<ByteData>.error(StateError('No bundled manifest.'));
  }
}

String _manifestJson({
  required String version,
  String channel = 'stable',
  int schemaVersion = ReleaseManifest.currentSchemaVersion,
  String? generatedAt,
}) {
  final timestamp = generatedAt ?? DateTime.now().toUtc().toIso8601String();
  return jsonEncode(
    _manifestMap(
      version: version,
      channel: channel,
      schemaVersion: schemaVersion,
      generatedAt: timestamp,
    ),
  );
}

Map<String, dynamic> _manifestMap({
  required String version,
  String channel = 'stable',
  int schemaVersion = 2,
  required String generatedAt,
}) {
  final artifactName = 'Cashly-Lao-Android-$version.apk';
  return {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt,
    if (schemaVersion == ReleaseManifest.currentSchemaVersion)
      'release': {
        'tag': 'v$version',
        'commitSha': 'b9234493d7f92b32f191c87ac4b2988e24f9ca7b',
        'channel': channel,
        'publishedAt': generatedAt,
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
        if (schemaVersion == ReleaseManifest.currentSchemaVersion)
          'artifactName': artifactName,
        if (schemaVersion == ReleaseManifest.currentSchemaVersion)
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
    if (schemaVersion == ReleaseManifest.currentSchemaVersion)
      'isLatest': false,
  };
}

Map<String, dynamic> _historyEntryJson({required String version}) {
  final tag = 'v$version';
  final artifactName = 'Cashly-Lao-Android-$version.apk';
  return {
    'release': {
      'tag': tag,
      'commitSha': 'b9234493d7f92b32f191c87ac4b2988e24f9ca7b',
      'channel': 'stable',
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
