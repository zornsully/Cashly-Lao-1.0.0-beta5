import 'dart:convert';

import 'package:web/web.dart' as web;

import 'release_manifest_cache_contract.dart';

ReleaseManifestCache createReleaseManifestCache() {
  try {
    return BrowserLocalStorageReleaseManifestCache(web.window.localStorage);
  } catch (_) {
    // Privacy-restricted contexts can deny local storage. The caller still
    // receives an in-memory cache and the bundled verified fallback.
    return InMemoryReleaseManifestCache();
  }
}

/// Persistent last-known-valid cache for the public web landing page.
class BrowserLocalStorageReleaseManifestCache implements ReleaseManifestCache {
  BrowserLocalStorageReleaseManifestCache(this._storage);

  static const storageKey = 'cashly_lao.last_known_valid_release_manifest.v2';
  static const _maxAge = Duration(days: 30);
  static const _maximumFutureSkew = Duration(minutes: 10);

  final web.Storage _storage;

  @override
  Future<String?> read() async {
    final raw = _storage.getItem(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cache envelope is not an object.');
      }
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      final manifestJson = decoded['manifest'] as String?;
      if (cachedAt == null || manifestJson == null || manifestJson.isEmpty) {
        throw const FormatException('Cache envelope is incomplete.');
      }
      final now = DateTime.now().toUtc();
      final normalizedCachedAt = cachedAt.toUtc();
      if (normalizedCachedAt.isAfter(now.add(_maximumFutureSkew)) ||
          now.difference(normalizedCachedAt) > _maxAge) {
        _storage.removeItem(storageKey);
        return null;
      }
      return manifestJson;
    } catch (_) {
      _storage.removeItem(storageKey);
      return null;
    }
  }

  @override
  Future<void> write(String manifestJson) async {
    _storage.setItem(
      storageKey,
      jsonEncode({
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'manifest': manifestJson,
      }),
    );
  }
}
