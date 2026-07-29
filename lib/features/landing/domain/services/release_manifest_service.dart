import '../entities/release_manifest.dart';

/// Provides the latest public release data for the landing page.
///
/// This small interface keeps the UI independent from the delivery channel so
/// the hosted JSON file can later be replaced with a release API or CI service.
abstract interface class ReleaseManifestService {
  Future<ReleaseManifest> loadLatest();
}
