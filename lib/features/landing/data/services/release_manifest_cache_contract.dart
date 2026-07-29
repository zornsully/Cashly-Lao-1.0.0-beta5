/// Small persistence boundary for verified public release metadata.
///
/// The cache returns only the raw manifest document to its caller; a platform
/// implementation may retain local freshness metadata around it. The manifest
/// is parsed and validated again on every read, so a damaged or manually
/// edited cache entry can never become a download action by itself.
abstract interface class ReleaseManifestCache {
  Future<String?> read();

  Future<void> write(String manifestJson);
}

/// Safe non-persistent cache for hosts without browser local storage.
class InMemoryReleaseManifestCache implements ReleaseManifestCache {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String manifestJson) async {
    _value = manifestJson;
  }
}
