import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/release_manifest.dart';
import '../../domain/services/release_manifest_service.dart';
import 'release_manifest_cache.dart';

/// Loads the live, centrally hosted release document for Cashly Lao.
///
/// A response is used only after the strict manifest parser verifies it is a
/// stable public release. The last verified release is persisted locally so a
/// transient API/CDN failure cannot replace a working download with a broken
/// button. A bundled manifest is the final offline-safe fallback.
class HostedReleaseManifestService implements ReleaseManifestService {
  HostedReleaseManifestService({
    http.Client? client,
    AssetBundle? assetBundle,
    ReleaseManifestCache? cache,
    Uri? manifestUri,
    this.requestTimeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _assetBundle = assetBundle ?? rootBundle,
       _cache = cache ?? createDefaultReleaseManifestCache(),
       _manifestUri = manifestUri ?? defaultManifestUri;

  static final Uri defaultManifestUri = Uri.parse(
    'https://cashly-lao.web.app/release-manifest.json',
  );
  static const fallbackAssetPath = 'assets/release/release_manifest.json';

  final http.Client _client;
  final AssetBundle _assetBundle;
  final ReleaseManifestCache _cache;
  final Uri _manifestUri;
  final Duration requestTimeout;

  @override
  Future<ReleaseManifest> loadLatest() async {
    final cachedManifest = await _loadCachedManifest();
    try {
      final networkManifest = await _loadNetworkManifest();

      // The verified network channel is authoritative. A cache is recovery
      // only, never an authority that can outrank a fresh rollback or update.
      await _persistManifest(networkManifest);
      return networkManifest.withSource(ReleaseManifestSource.network);
    } catch (error) {
      if (cachedManifest != null) {
        return cachedManifest.withSource(ReleaseManifestSource.persistentCache);
      }

      final bundledManifest = await _loadBundledManifest();
      if (bundledManifest != null) {
        return bundledManifest.withSource(
          ReleaseManifestSource.bundledFallback,
        );
      }

      throw ReleaseManifestFetchException(_friendlyFailureMessage(error));
    }
  }

  Future<ReleaseManifest> _loadNetworkManifest() async {
    final response = await _client
        .get(
          _manifestUri,
          headers: const {
            'Cache-Control': 'no-cache',
            'Accept': 'application/json',
          },
        )
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw ReleaseManifestFetchException(
        'Release manifest returned HTTP ${response.statusCode}.',
      );
    }

    return _requirePublicStableManifest(_decode(response.body));
  }

  Future<ReleaseManifest?> _loadCachedManifest() async {
    try {
      final source = await _cache.read();
      if (source == null || source.trim().isEmpty) return null;
      return _requirePublicStableManifest(_decode(source));
    } catch (_) {
      // Cached data is an availability optimisation only. It is ignored if it
      // cannot satisfy the same validation as a network response.
      return null;
    }
  }

  Future<ReleaseManifest?> _loadBundledManifest() async {
    try {
      final source = await _assetBundle.loadString(
        fallbackAssetPath,
        cache: false,
      );
      final manifest = _decode(source);

      // Older bundles remain useful for explaining availability while offline,
      // but only a current-schema document can unlock a public download.
      return manifest.schemaVersion == ReleaseManifest.currentSchemaVersion
          ? _requirePublicStableManifest(manifest)
          : manifest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistManifest(ReleaseManifest source) async {
    try {
      await _cache.write(_encode(source));
    } catch (_) {
      // A browser can reject local storage in private modes. The verified live
      // response is still safe to display for this session.
    }
  }

  ReleaseManifest _requirePublicStableManifest(ReleaseManifest manifest) {
    if (manifest.schemaVersion != ReleaseManifest.currentSchemaVersion ||
        !manifest.isStable ||
        !manifest.hasAvailableLatestStableRelease) {
      throw const ReleaseManifestFetchException(
        'The release channel does not contain a published stable download.',
      );
    }
    return manifest;
  }

  ReleaseManifest _decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Release manifest root must be an object.');
    }
    return ReleaseManifest.fromJson(decoded);
  }

  String _encode(ReleaseManifest manifest) {
    // Cache the exact document that passed validation. Runtime-only source
    // fields are intentionally not written because the next read must make an
    // independent trust decision.
    final encoded = <String, Object?>{
      'schemaVersion': manifest.schemaVersion,
      'generatedAt': manifest.generatedAt.toUtc().toIso8601String(),
      'platforms': manifest.platforms
          .map((platform) => _encodePlatform(platform, manifest.schemaVersion))
          .toList(growable: false),
    };
    final release = manifest.release;
    if (release != null) {
      encoded['release'] = {
        'tag': release.tag,
        'commitSha': release.commitSha,
        'channel': release.channel.value,
        'publishedAt': release.publishedAt.toUtc().toIso8601String(),
        'releaseUrl': release.releaseUrl.toString(),
      };
    }
    return jsonEncode(encoded);
  }

  Map<String, Object?> _encodePlatform(
    PlatformRelease platform,
    int schemaVersion,
  ) {
    final encoded = <String, Object?>{
      'platform': platform.platform.value,
      'displayName': platform.displayName,
      'availability': platform.availability.value,
      'statusLabel': platform.statusLabel,
      'actionLabel': platform.actionLabel,
      'availabilityMessage': platform.availabilityMessage,
    };
    _addIfPresent(encoded, 'version', platform.version);
    _addIfPresent(encoded, 'buildNumber', platform.buildNumber);
    _addIfPresent(
      encoded,
      'releaseDate',
      platform.releaseDate?.toIso8601String(),
    );
    _addIfPresent(encoded, 'fileSizeBytes', platform.fileSizeBytes);
    _addIfPresent(encoded, 'minimumOsVersion', platform.minimumOsVersion);
    _addIfPresent(encoded, 'releaseNotes', platform.releaseNotes);
    _addIfPresent(encoded, 'downloadUrl', platform.downloadUrl?.toString());
    _addIfPresent(encoded, 'packageFormat', platform.packageFormat);
    _addIfPresent(encoded, 'installationNote', platform.installationNote);
    _addIfPresent(encoded, 'sha256', platform.sha256);
    _addIfPresent(encoded, 'artifactName', platform.artifactName);
    if (schemaVersion >= ReleaseManifest.currentSchemaVersion) {
      encoded['isLatest'] = platform.isLatest;
    }
    return encoded;
  }

  void _addIfPresent(Map<String, Object?> target, String key, Object? value) {
    if (value != null) target[key] = value;
  }

  String _friendlyFailureMessage(Object error) {
    if (error is TimeoutException) {
      return 'The release channel took too long to respond. Please try again.';
    }
    if (error is http.ClientException) {
      return 'Unable to reach the release channel. Check your connection and try again.';
    }
    if (error is ReleaseManifestFetchException) return error.message;
    return 'We could not verify a current Cashly Lao release. Please try again.';
  }
}

class ReleaseManifestFetchException implements Exception {
  const ReleaseManifestFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
