import 'package:intl/intl.dart';

/// Supported distribution targets for the public Cashly Lao release channel.
enum ReleasePlatform {
  android('android', 'Android'),
  ios('ios', 'iOS'),
  windows('windows', 'Windows'),
  mac('mac', 'Mac');

  const ReleasePlatform(this.value, this.fallbackDisplayName);

  final String value;
  final String fallbackDisplayName;

  static ReleasePlatform fromValue(String value) {
    return ReleasePlatform.values.firstWhere(
      (platform) => platform.value == value,
      orElse: () =>
          throw FormatException('Unsupported release platform: $value'),
    );
  }
}

/// Whether an announced platform artifact can be installed by the public.
enum ReleaseAvailability {
  available('available'),
  comingSoon('coming_soon');

  const ReleaseAvailability(this.value);

  final String value;

  static ReleaseAvailability fromValue(String value) {
    return ReleaseAvailability.values.firstWhere(
      (availability) => availability.value == value,
      orElse: () =>
          throw FormatException('Unsupported release availability: $value'),
    );
  }
}

/// Publication channel for a versioned release document.
///
/// The landing page deliberately treats prereleases as ineligible for the
/// public download call-to-action. A preview can still be parsed for release
/// tooling, but it cannot displace the last verified stable manifest.
enum ReleaseChannel {
  stable('stable'),
  prerelease('prerelease');

  const ReleaseChannel(this.value);

  final String value;

  static ReleaseChannel fromValue(String value) {
    return ReleaseChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () =>
          throw FormatException('Unsupported release channel: $value'),
    );
  }
}

/// The only public artifact channel accepted by Cashly Lao.
///
/// Release provenance remains tied to the private GitHub repository, but the
/// public Android package is deliberately served from Cashly Lao Firebase
/// Hosting. Keeping both rules here makes a future ownership or distribution
/// change explicit and reviewable instead of allowing a manifest to redirect
/// visitors to an arbitrary HTTPS host.
abstract final class ReleaseManifestTrustPolicy {
  static const githubHost = 'github.com';
  static const repositoryOwner = 'zornsully';
  static const repositoryName = 'Cashly-Lao-1.0.0-beta5';
  static const firebaseHostingHost = 'cashly-lao.web.app';
  static const _androidDownloadsPath = 'downloads';

  static bool isTrustedReleasePage(Uri uri, String tag, {String? rawUri}) {
    return _isTrustedGitHubUri(uri, [
      repositoryOwner,
      repositoryName,
      'releases',
      'tag',
      tag,
    ], rawUri: rawUri);
  }

  static bool isTrustedArtifactDownload(
    Uri uri, {
    required ReleasePlatform platform,
    required String version,
    required String artifactName,
    String? rawUri,
  }) {
    if (platform != ReleasePlatform.android ||
        artifactName != androidArtifactName(version)) {
      return false;
    }

    // Compare the complete canonical URI rather than only decoded path
    // segments. This rejects a default port, user info, query/fragment data,
    // a trailing slash, or encoded path variants that could otherwise look
    // equivalent after parsing.
    final canonicalUri = androidDownloadUri(version).toString();
    return uri.toString() == canonicalUri &&
        (rawUri == null || rawUri == canonicalUri);
  }

  static String androidArtifactName(String version) =>
      'Cashly-Lao-Android-$version.apk';

  static Uri androidDownloadUri(String version) => Uri.https(
    firebaseHostingHost,
    '/$_androidDownloadsPath/${androidArtifactName(version)}',
  );

  static bool _isTrustedGitHubUri(
    Uri uri,
    List<String> expectedSegments, {
    String? rawUri,
  }) {
    if (uri.scheme != 'https' ||
        uri.host != githubHost ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      return false;
    }
    final segments = uri.pathSegments;
    if (segments.length != expectedSegments.length) return false;
    for (var index = 0; index < segments.length; index++) {
      if (segments[index] != expectedSegments[index]) return false;
    }
    final canonicalUri = Uri.https(
      githubHost,
      '/${expectedSegments.join('/')}',
    ).toString();
    return uri.toString() == canonicalUri &&
        (rawUri == null || rawUri == canonicalUri);
  }
}

/// Identifies where a release manifest was recovered from.
///
/// Source information is runtime-only and is never trusted from downloaded
/// JSON. It lets the public page be transparent when it is using a last-known
/// valid document instead of a fresh response.
enum ReleaseManifestSource {
  unknown,
  network,
  persistentCache,
  bundledFallback;

  bool get isFallback =>
      this == ReleaseManifestSource.persistentCache ||
      this == ReleaseManifestSource.bundledFallback;
}

/// Immutable release-level facts published by the release pipeline.
class ReleaseDescriptor {
  const ReleaseDescriptor({
    required this.tag,
    required this.commitSha,
    required this.channel,
    required this.publishedAt,
    required this.releaseUrl,
  });

  final String tag;
  final String commitSha;
  final ReleaseChannel channel;
  final DateTime publishedAt;
  final Uri releaseUrl;

  String get version => tag.substring(1);

  bool get isStable => channel == ReleaseChannel.stable;

  factory ReleaseDescriptor.fromJson(Map<String, dynamic> json) {
    final tag = _requiredString(json, 'tag');
    final version = _versionFromTag(tag);
    final commitSha = _requiredString(json, 'commitSha');
    if (!_commitShaPattern.hasMatch(commitSha)) {
      throw const FormatException(
        'Release manifest commitSha must be a lowercase Git SHA.',
      );
    }

    final channel = ReleaseChannel.fromValue(_requiredString(json, 'channel'));
    final hasPrereleaseQualifier = version.contains('-');
    if (channel == ReleaseChannel.stable && hasPrereleaseQualifier) {
      throw const FormatException(
        'Stable releases cannot use a prerelease version tag.',
      );
    }
    if (channel == ReleaseChannel.prerelease && !hasPrereleaseQualifier) {
      throw const FormatException(
        'Prerelease releases must use a prerelease version tag.',
      );
    }

    final rawReleaseUrl = _requiredString(json, 'releaseUrl');
    final releaseUrl = _parseHttpsUri(rawReleaseUrl);
    if (!ReleaseManifestTrustPolicy.isTrustedReleasePage(
      releaseUrl,
      tag,
      rawUri: rawReleaseUrl,
    )) {
      throw const FormatException(
        'Release manifest releaseUrl must be the official GitHub Release page.',
      );
    }

    return ReleaseDescriptor(
      tag: tag,
      commitSha: commitSha,
      channel: channel,
      publishedAt: _requiredTimestamp(json, 'publishedAt'),
      releaseUrl: releaseUrl,
    );
  }
}

/// A single platform entry in the centrally published release manifest.
///
/// The presentation layer intentionally consumes this data instead of keeping
/// version numbers, package links, or availability messages in widgets.
class PlatformRelease {
  const PlatformRelease({
    required this.platform,
    required this.displayName,
    required this.availability,
    required this.statusLabel,
    required this.actionLabel,
    required this.availabilityMessage,
    this.version,
    this.buildNumber,
    this.releaseDate,
    this.fileSizeBytes,
    this.minimumOsVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.packageFormat,
    this.installationNote,
    this.sha256,
    this.artifactName,
    bool? isLatest,
  }) : isLatest = isLatest ?? availability == ReleaseAvailability.available;

  final ReleasePlatform platform;
  final String displayName;
  final ReleaseAvailability availability;
  final String statusLabel;
  final String actionLabel;
  final String availabilityMessage;
  final String? version;
  final String? buildNumber;
  final DateTime? releaseDate;
  final int? fileSizeBytes;
  final String? minimumOsVersion;
  final String? releaseNotes;
  final Uri? downloadUrl;
  final String? packageFormat;
  final String? installationNote;
  final String? sha256;
  final String? artifactName;

  /// Whether this entry is the verified latest artifact for its platform.
  ///
  /// A schema v1 document did not carry this field. It is therefore inferred
  /// as true for its available entry so existing bundled manifests remain
  /// compatible while schema v2 requires it explicitly.
  final bool isLatest;

  bool get isAvailable =>
      availability == ReleaseAvailability.available && downloadUrl != null;

  String? get versionLabel => version == null ? null : 'v$version';

  String? get releaseDateLabel {
    final value = releaseDate;
    if (value == null) return null;
    return DateFormat('d MMM yyyy').format(value.toLocal());
  }

  String? get fileSizeLabel {
    final bytes = fileSizeBytes;
    if (bytes == null || bytes <= 0) return null;

    const bytesPerMegabyte = 1024 * 1024;
    final megabytes = bytes / bytesPerMegabyte;
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  factory PlatformRelease.fromJson(
    Map<String, dynamic> json, {
    int schemaVersion = 1,
    ReleaseDescriptor? releaseDescriptor,
  }) {
    final rawDownloadUrl = _optionalString(json, 'downloadUrl');
    final availability = ReleaseAvailability.fromValue(
      _requiredString(json, 'availability'),
    );
    final release = PlatformRelease(
      platform: ReleasePlatform.fromValue(_requiredString(json, 'platform')),
      displayName: _requiredString(json, 'displayName'),
      availability: availability,
      statusLabel: _requiredString(json, 'statusLabel'),
      actionLabel: _requiredString(json, 'actionLabel'),
      availabilityMessage: _requiredString(json, 'availabilityMessage'),
      version: _optionalString(json, 'version'),
      buildNumber: _optionalString(json, 'buildNumber'),
      releaseDate: _optionalDate(json, 'releaseDate'),
      fileSizeBytes: _optionalInt(json, 'fileSizeBytes'),
      minimumOsVersion: _optionalString(json, 'minimumOsVersion'),
      releaseNotes: _optionalString(json, 'releaseNotes'),
      downloadUrl: rawDownloadUrl == null
          ? null
          : _parseHttpsUri(rawDownloadUrl),
      packageFormat: _optionalString(json, 'packageFormat'),
      installationNote: _optionalString(json, 'installationNote'),
      sha256: _optionalString(json, 'sha256'),
      artifactName: _optionalString(json, 'artifactName'),
      isLatest: schemaVersion >= ReleaseManifest.currentSchemaVersion
          ? _requiredBool(json, 'isLatest')
          : null,
    );
    _validatePlatformRelease(
      release,
      schemaVersion: schemaVersion,
      releaseDescriptor: releaseDescriptor,
      rawDownloadUrl: rawDownloadUrl,
    );
    return release;
  }
}

/// The versioned document fetched from the central release channel.
class ReleaseManifest {
  const ReleaseManifest({
    required this.schemaVersion,
    required this.generatedAt,
    required this.platforms,
    this.release,
    this.source = ReleaseManifestSource.unknown,
  });

  /// Schema v2 adds a pipeline-verifiable release identity and assets.
  static const currentSchemaVersion = 2;

  final int schemaVersion;
  final DateTime generatedAt;
  final List<PlatformRelease> platforms;
  final ReleaseDescriptor? release;
  final ReleaseManifestSource source;

  bool get isStable => release?.isStable ?? true;

  bool get isFallback => source.isFallback;

  PlatformRelease? releaseFor(ReleasePlatform platform) {
    for (final release in platforms) {
      if (release.platform == platform) return release;
    }
    return null;
  }

  /// The only release that may be used by the public stable download UI.
  PlatformRelease? latestStableReleaseFor(ReleasePlatform platform) {
    if (!isTrustedForPublicDownload) return null;
    final candidate = releaseFor(platform);
    if (candidate == null || !candidate.isAvailable || !candidate.isLatest) {
      return null;
    }
    return candidate;
  }

  bool get hasAvailableLatestStableRelease => ReleasePlatform.values.any(
    (platform) => latestStableReleaseFor(platform) != null,
  );

  /// Re-applies the public-download trust boundary to constructed objects.
  ///
  /// Production manifests normally enter through [fromJson], but callers can
  /// also construct these immutable models directly (for example, in future
  /// providers or tests). A manually constructed object must never turn an
  /// arbitrary URI into a download action merely because it looks available.
  bool get isTrustedForPublicDownload {
    final releaseDescriptor = release;
    if (schemaVersion != currentSchemaVersion ||
        releaseDescriptor == null ||
        !releaseDescriptor.isStable) {
      return false;
    }

    try {
      final version = _versionFromTag(releaseDescriptor.tag);
      if (!_commitShaPattern.hasMatch(releaseDescriptor.commitSha) ||
          version.contains('-') ||
          !ReleaseManifestTrustPolicy.isTrustedReleasePage(
            releaseDescriptor.releaseUrl,
            releaseDescriptor.tag,
          )) {
        return false;
      }

      final representedPlatforms = <ReleasePlatform>{};
      final artifactNames = <String>{};
      for (final platform in platforms) {
        if (!representedPlatforms.add(platform.platform)) return false;
        _validatePlatformRelease(
          platform,
          schemaVersion: schemaVersion,
          releaseDescriptor: releaseDescriptor,
        );
        final artifactName = platform.artifactName;
        if (platform.isAvailable &&
            (artifactName == null || !artifactNames.add(artifactName))) {
          return false;
        }
      }
      if (representedPlatforms.length != ReleasePlatform.values.length) {
        return false;
      }

      _validateManifestIdentity(this);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Uses the document generation timestamp rather than a release version so
  /// an intentional approved rollback can still replace cached metadata.
  bool isOlderThan(ReleaseManifest other) =>
      generatedAt.isBefore(other.generatedAt);

  ReleaseManifest withSource(ReleaseManifestSource source) {
    return ReleaseManifest(
      schemaVersion: schemaVersion,
      generatedAt: generatedAt,
      platforms: platforms,
      release: release,
      source: source,
    );
  }

  factory ReleaseManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != 1 && schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported release manifest schemaVersion: $schemaVersion.',
      );
    }

    final rawPlatforms = json['platforms'];
    if (rawPlatforms is! List) {
      throw const FormatException('Release manifest platforms must be a list.');
    }

    final release = schemaVersion >= currentSchemaVersion
        ? ReleaseDescriptor.fromJson(_requiredObject(json, 'release'))
        : null;
    final platforms = rawPlatforms
        .map((platform) {
          if (platform is! Map<String, dynamic>) {
            throw const FormatException(
              'Each release manifest platform must be an object.',
            );
          }
          return PlatformRelease.fromJson(
            platform,
            schemaVersion: schemaVersion,
            releaseDescriptor: release,
          );
        })
        .toList(growable: false);

    final representedPlatforms = <ReleasePlatform>{};
    for (final platform in platforms) {
      if (!representedPlatforms.add(platform.platform)) {
        throw FormatException(
          'Release manifest contains duplicate platform: ${platform.platform.value}.',
        );
      }
    }
    final missingPlatforms = ReleasePlatform.values
        .where((platform) => !representedPlatforms.contains(platform))
        .map((platform) => platform.value);
    if (missingPlatforms.isNotEmpty) {
      throw FormatException(
        'Release manifest is missing: ${missingPlatforms.join(', ')}.',
      );
    }
    final artifactNames = <String>{};
    for (final platform in platforms) {
      final artifactName = platform.artifactName;
      if (!platform.isAvailable || artifactName == null) continue;
      if (!artifactNames.add(artifactName)) {
        throw FormatException(
          'Release manifest contains duplicate artifactName: $artifactName.',
        );
      }
    }

    final manifest = ReleaseManifest(
      schemaVersion: schemaVersion,
      generatedAt: _requiredTimestamp(json, 'generatedAt'),
      platforms: platforms,
      release: release,
    );
    _validateManifestIdentity(manifest);
    return manifest;
  }
}

void _validateManifestIdentity(ReleaseManifest manifest) {
  final release = manifest.release;
  final latestAllowedTimestamp = DateTime.now().toUtc().add(
    const Duration(hours: 24),
  );
  if (manifest.generatedAt.isAfter(latestAllowedTimestamp)) {
    throw const FormatException(
      'Release manifest generatedAt is implausibly far in the future.',
    );
  }
  if (release == null) return;
  if (release.publishedAt.isAfter(latestAllowedTimestamp)) {
    throw const FormatException(
      'Release manifest publishedAt is implausibly far in the future.',
    );
  }

  for (final platformRelease in manifest.platforms) {
    if (!platformRelease.isAvailable) continue;
    if (release.isStable && platformRelease.version!.contains('-')) {
      throw FormatException(
        'Stable release metadata cannot expose a prerelease ${platformRelease.platform.value} asset.',
      );
    }
    if (!platformRelease.isLatest) {
      throw FormatException(
        'Available ${platformRelease.platform.value} releases must be marked isLatest.',
      );
    }
  }
}

void _validatePlatformRelease(
  PlatformRelease release, {
  required int schemaVersion,
  required ReleaseDescriptor? releaseDescriptor,
  String? rawDownloadUrl,
}) {
  final isCurrentSchema = schemaVersion >= ReleaseManifest.currentSchemaVersion;
  if (release.availability == ReleaseAvailability.comingSoon) {
    if (isCurrentSchema && release.isLatest) {
      throw FormatException(
        'Coming-soon ${release.platform.value} releases cannot be marked isLatest.',
      );
    }
    if (release.downloadUrl != null || release.artifactName != null) {
      throw FormatException(
        'Coming-soon ${release.platform.value} releases cannot include a download asset.',
      );
    }
    return;
  }

  if (release.downloadUrl == null) {
    throw const FormatException(
      'Available releases must include a download URL.',
    );
  }
  if (!isCurrentSchema) return;

  if (releaseDescriptor == null) {
    throw const FormatException(
      'Schema-v2 platform metadata requires a release descriptor.',
    );
  }

  final version = release.version;
  if (version == null || !_semanticVersionPattern.hasMatch(version)) {
    throw FormatException(
      'Available ${release.platform.value} releases must include a semantic version.',
    );
  }
  if (version != releaseDescriptor.version) {
    throw FormatException(
      'Available ${release.platform.value} metadata must match the release version.',
    );
  }
  final buildNumber = release.buildNumber;
  if (buildNumber == null || !_buildNumberPattern.hasMatch(buildNumber)) {
    throw FormatException(
      'Available ${release.platform.value} releases must include a positive build number.',
    );
  }
  if (release.releaseDate == null ||
      release.fileSizeBytes == null ||
      release.fileSizeBytes! <= 0 ||
      release.minimumOsVersion == null ||
      release.releaseNotes == null ||
      release.packageFormat == null) {
    throw FormatException(
      'Available ${release.platform.value} releases are missing required metadata.',
    );
  }
  final artifactName = release.artifactName;
  if (artifactName == null || !_artifactNamePattern.hasMatch(artifactName)) {
    throw FormatException(
      'Available ${release.platform.value} releases need a safe artifactName.',
    );
  }
  final lastPathSegment = release.downloadUrl!.pathSegments.isEmpty
      ? ''
      : Uri.decodeComponent(release.downloadUrl!.pathSegments.last);
  if (lastPathSegment != artifactName) {
    throw FormatException(
      'The ${release.platform.value} artifactName must match its download URL.',
    );
  }
  if (release.sha256 == null || !_sha256Pattern.hasMatch(release.sha256!)) {
    throw FormatException(
      'Available ${release.platform.value} releases need a SHA-256 checksum.',
    );
  }
  if (!_hasExpectedArtifactName(release.platform, artifactName, version)) {
    throw FormatException(
      'The ${release.platform.value} artifactName does not match its platform or version.',
    );
  }
  if (!ReleaseManifestTrustPolicy.isTrustedArtifactDownload(
    release.downloadUrl!,
    platform: release.platform,
    version: version,
    artifactName: artifactName,
    rawUri: rawDownloadUrl,
  )) {
    throw FormatException(
      'The ${release.platform.value} downloadUrl must reference the canonical Firebase Hosting asset.',
    );
  }
}

bool _hasExpectedArtifactName(
  ReleasePlatform platform,
  String artifactName,
  String version,
) {
  // Schema-v2 intentionally has one public artifact channel: the signed
  // Android APK served from Firebase Hosting. Other platforms stay
  // coming-soon until an equally strict, platform-specific policy exists.
  return platform == ReleasePlatform.android &&
      artifactName == ReleaseManifestTrustPolicy.androidArtifactName(version);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Release manifest $key must be a non-empty string.');
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Release manifest $key must be a non-empty string.');
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Release manifest $key must be an integer.');
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Release manifest $key must be an integer.');
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Release manifest $key must be a boolean.');
}

Map<String, dynamic> _requiredObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Release manifest $key must be an object.');
}

DateTime _requiredTimestamp(Map<String, dynamic> json, String key) {
  final rawValue = _requiredString(json, key);
  if (!rawValue.contains('T')) {
    throw FormatException(
      'Release manifest $key must be an ISO-8601 timestamp.',
    );
  }
  final value = DateTime.tryParse(rawValue);
  if (value == null) {
    throw FormatException(
      'Release manifest $key must be an ISO-8601 timestamp.',
    );
  }
  return value.toUtc();
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  if (value == null) return null;
  return DateTime.tryParse(value) ??
      (throw FormatException(
        'Release manifest $key must be an ISO-8601 date.',
      ));
}

Uri _parseHttpsUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException(
      'Release manifest downloadUrl must be an absolute HTTPS URL.',
    );
  }
  return uri;
}

String _versionFromTag(String tag) {
  if (!tag.startsWith('v') || tag.length == 1) {
    throw const FormatException('Release manifest tag must start with v.');
  }
  final version = tag.substring(1);
  if (!_semanticVersionPattern.hasMatch(version)) {
    throw const FormatException(
      'Release manifest tag must contain a semantic version.',
    );
  }
  return version;
}

final _semanticVersionPattern = RegExp(
  r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?(?:\+[0-9A-Za-z][0-9A-Za-z.-]*)?$',
);
final _commitShaPattern = RegExp(r'^[a-f0-9]{7,64}$');
final _buildNumberPattern = RegExp(r'^[1-9]\d*$');
final _artifactNamePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._+-]*$');
final _sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');
