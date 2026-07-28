import 'release_manifest_cache_contract.dart';
import 'release_manifest_cache_platform_stub.dart'
    if (dart.library.html) 'release_manifest_cache_platform_web.dart'
    as platform;

export 'release_manifest_cache_contract.dart';

/// Creates the safest cache available on the current host.
///
/// Browser visitors receive persistent local-storage recovery without adding a
/// new runtime dependency. Other hosts retain a session-safe in-memory copy;
/// the bundled verified manifest remains their durable fallback.
ReleaseManifestCache createDefaultReleaseManifestCache() {
  return platform.createReleaseManifestCache();
}
