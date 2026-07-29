/// Generates a schema-v2 Cashly Lao release manifest from verified artifacts
/// prepared for an approved public GitHub distribution release.
///
/// The command is deliberately offline and credential-free. It only writes a
/// local JSON file; publication and Firebase Spark metadata deployment remain
/// manual owner actions after their separate explicit approvals.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart'
    as landing;

const _tagExpression = r'^v(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)$';
const _shaExpression = r'^[a-f0-9]{7,64}$';
const _checksumExpression = r'^[A-Fa-f0-9]{64}$';
const _platformOrder = ['android', 'ios', 'windows', 'mac'];

Future<void> main(List<String> arguments) async {
  try {
    final options = _Arguments.parse(arguments);
    if (options.flag('help')) {
      stdout.writeln(_usage);
      return;
    }

    final version = options.requireValue('version');
    final tag = options.value('tag') ?? 'v$version';
    if (RegExp(_tagExpression).firstMatch(tag)?.group(1) != version) {
      throw _UsageException(
        '--tag must exactly match --version, for example v1.2.3.',
      );
    }
    final channel =
        options.value('channel') ??
        (version.contains('-') ? 'prerelease' : 'stable');
    if (!const {'stable', 'prerelease'}.contains(channel)) {
      throw _UsageException('--channel must be stable or prerelease.');
    }

    final commit =
        options.value('commit') ?? Platform.environment['GITHUB_SHA'];
    if (commit == null || !RegExp(_shaExpression).hasMatch(commit)) {
      throw _UsageException(
        'Provide --commit with the exact lowercase release commit SHA.',
      );
    }
    final distributionRepository = options.requireValue(
      'distribution-repository',
    );
    final distributionPolicy = _readDistributionPolicy(
      File(
        options.value('distribution-policy') ??
            'assets/release/distribution_policy.json',
      ),
    );
    if (!distributionPolicy.approvesRepository(distributionRepository)) {
      throw const FormatException(
        '--distribution-repository must exactly match the reviewed bundled distribution policy.',
      );
    }
    final releaseUri = _githubReleaseUri(
      options.requireValue('release-url'),
      tag,
      distributionPolicy,
    );
    final output = File(options.requireValue('output'));
    final template = File(
      options.value('template') ?? 'assets/release/release_manifest.json',
    );
    if (!template.existsSync()) {
      throw StateError(
        'Release manifest template was not found at ${template.path}.',
      );
    }

    final templateJson = _decodeObject(await template.readAsString());
    final appVersion = _readPubspecVersion(
      File(options.value('pubspec') ?? 'pubspec.yaml'),
    );
    if (appVersion.version != version) {
      throw StateError(
        '--version $version does not match pubspec version ${appVersion.version}.',
      );
    }

    final notes = await _readReleaseNotes(options.value('notes'));
    final artifactFile = options.value('artifacts');
    final artifacts = artifactFile == null
        ? <String, _PublishedArtifact>{}
        : _parseArtifacts(File(artifactFile));
    if (channel == 'stable' && artifacts.isEmpty) {
      throw const FormatException(
        'A stable manifest needs at least one verified public GitHub artifact.',
      );
    }
    if (channel == 'stable' &&
        artifacts.keys.any((platform) => platform != 'android')) {
      throw const FormatException(
        'Only Android is currently eligible for the public development release channel.',
      );
    }

    final existingPlatforms = _platformMaps(templateJson);
    final resultPlatforms = <Map<String, Object?>>[];
    for (final platform in _platformOrder) {
      final existing = existingPlatforms[platform] ?? _comingSoon(platform);
      final artifact = artifacts[platform];
      if (artifact == null || channel == 'prerelease') {
        // Prereleases are never allowed to displace the current stable download
        // metadata. A public production manifest is generated only for stable
        // releases after the protected approval gate.
        resultPlatforms.add(_normalizeExisting(platform, existing));
        continue;
      }
      resultPlatforms.add(
        _availablePlatform(
          platform: platform,
          artifact: artifact,
          version: version,
          buildNumber: appVersion.buildNumber,
          releaseDate: DateTime.now().toUtc().toIso8601String().substring(
            0,
            10,
          ),
          releaseNotes:
              notes ??
              _string(existing['releaseNotes']) ??
              'Cashly Lao $version is ready to download.',
          downloadUrl: _githubAndroidDownloadUrl(
            version: version,
            tag: tag,
            policy: distributionPolicy,
            artifact: artifact,
          ),
          minimumOsVersion:
              artifact.minimumOsVersion ??
              _string(existing['minimumOsVersion']) ??
              _minimumOs(platform),
          packageFormat:
              artifact.packageFormat ??
              _packageFormatFor(artifact.artifactName),
          installationNote:
              artifact.installationNote ??
              _installationNote(platform, artifact.artifactName),
        ),
      );
    }

    final outputJson = <String, Object?>{
      'schemaVersion': 2,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'release': {
        'tag': tag,
        'commitSha': commit,
        'channel': channel,
        'publishedAt': DateTime.now().toUtc().toIso8601String(),
        'distributionRepository': distributionRepository,
        'releaseUrl': releaseUri.toString(),
      },
      'platforms': resultPlatforms,
    };
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(outputJson)}\n',
    );
    stdout.writeln(
      'Generated schema-v2 release manifest at ${output.path} for $tag.',
    );
  } on _UsageException catch (error) {
    stderr.writeln('Release manifest generation error: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } catch (error, stackTrace) {
    stderr.writeln('Release manifest generation failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

const _usage = '''
Usage:
  dart run tool/generate_release_manifest.dart \\
    --version 1.2.3 \\
    --commit <sha> \\
    --distribution-repository owner/public-release-repository \\
    --release-url https://github.com/owner/public-release-repository/releases/tag/v1.2.3 \\
    --artifacts release-artifacts.json \\
    --output build/web/release-manifest.json

Required:
  --version <version>           Version from pubspec.yaml, without v.
  --distribution-repository     Approved public GitHub owner/repository.
  --release-url <https URL>     Public GitHub Release page URL.
  --output <path>               Generated manifest location.

Options:
  --commit <sha>                Release commit SHA (defaults to GITHUB_SHA).
  --tag <tag>                   Git tag (defaults to v<version>).
  --channel <stable|prerelease> Release channel (auto-detected by default).
  --artifacts <json>            Verified public GitHub release artifact manifest.
  --distribution-policy <path>  Reviewed bundled distribution policy JSON.
  --template <path>             Current manifest template.
  --notes <path>                Reviewed release-notes Markdown file.
  --pubspec <path>              pubspec.yaml path.
  --help                        Show this help.

Artifact JSON uses `artifacts` (or `platforms`) containing entries with:
platform, artifactName (or fileName), fileSizeBytes, sha256, and optional
downloadUrl (which must be the canonical public GitHub asset URL when supplied),
minimumOsVersion, packageFormat, installationNote.
''';

Map<String, Object?> _decodeObject(String source) {
  final value = jsonDecode(source);
  if (value is! Map) {
    throw const FormatException('The JSON document root must be an object.');
  }
  return value.map((key, value) => MapEntry('$key', value));
}

Map<String, Map<String, Object?>> _platformMaps(Map<String, Object?> root) {
  final rawPlatforms = root['platforms'];
  if (rawPlatforms is! List) {
    throw const FormatException(
      'Release manifest template platforms must be a list.',
    );
  }
  final result = <String, Map<String, Object?>>{};
  for (final rawPlatform in rawPlatforms) {
    if (rawPlatform is! Map) {
      throw const FormatException(
        'Each release platform entry must be an object.',
      );
    }
    final map = rawPlatform.map((key, value) => MapEntry('$key', value));
    final platform = _string(map['platform']);
    if (platform == null || !_platformOrder.contains(platform)) {
      throw FormatException(
        'Unsupported or missing platform in template: $platform.',
      );
    }
    if (result.containsKey(platform)) {
      throw FormatException(
        'Duplicate platform in release manifest template: $platform.',
      );
    }
    result[platform] = map;
  }
  return result;
}

Map<String, _PublishedArtifact> _parseArtifacts(File source) {
  if (!source.existsSync()) {
    throw StateError(
      'Verified artifact metadata was not found at ${source.path}.',
    );
  }
  final document = _decodeObject(source.readAsStringSync());
  final rawArtifacts = document['artifacts'] ?? document['platforms'];
  if (rawArtifacts is! List) {
    throw const FormatException(
      'Artifact metadata must contain an artifacts or platforms list.',
    );
  }
  final result = <String, _PublishedArtifact>{};
  for (final entry in rawArtifacts) {
    if (entry is! Map) {
      throw const FormatException('Artifact entries must be JSON objects.');
    }
    final map = entry.map((key, value) => MapEntry('$key', value));
    final artifact = _PublishedArtifact.fromJson(map);
    if (result.containsKey(artifact.platform)) {
      throw FormatException(
        'Duplicate artifact platform: ${artifact.platform}.',
      );
    }
    result[artifact.platform] = artifact;
  }
  return result;
}

landing.ReleaseDistributionPolicy _readDistributionPolicy(File source) {
  if (!source.existsSync()) {
    throw StateError(
      'Release distribution policy was not found at ${source.path}.',
    );
  }
  return landing.ReleaseDistributionPolicy.fromJson(
    _decodeObject(source.readAsStringSync()),
  );
}

Uri _githubReleaseUri(
  String value,
  String expectedTag,
  landing.ReleaseDistributionPolicy policy,
) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !landing.ReleaseManifestTrustPolicy.isTrustedReleasePage(
        uri,
        expectedTag,
        policy: policy,
        rawUri: value,
      )) {
    throw FormatException(
      'Release URL must exactly match the approved public GitHub Release tagged $expectedTag.',
    );
  }
  return uri;
}

String _githubAndroidDownloadUrl({
  required String version,
  required String tag,
  required landing.ReleaseDistributionPolicy policy,
  required _PublishedArtifact artifact,
}) {
  if (artifact.platform != 'android') {
    throw FormatException(
      '${artifact.platform} is not eligible for the public development release channel.',
    );
  }

  final artifactName = landing.ReleaseManifestTrustPolicy.androidArtifactName(
    version,
  );
  if (artifact.artifactName != artifactName) {
    throw FormatException(
      'Android artifactName must exactly match $artifactName.',
    );
  }

  final repository = policy.repository;
  if (repository == null) {
    throw const FormatException(
      'A reviewed public distribution repository is required for a stable manifest.',
    );
  }
  final canonicalUri = landing.ReleaseManifestTrustPolicy.androidDownloadUri(
    repository: repository,
    tag: tag,
    version: version,
  );
  final suppliedUri = artifact.downloadUrl;
  if (suppliedUri != null && suppliedUri != canonicalUri.toString()) {
    throw FormatException(
      'Android artifact downloadUrl must exactly match the public GitHub asset $canonicalUri when supplied.',
    );
  }
  return canonicalUri.toString();
}

Future<String?> _readReleaseNotes(String? path) async {
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Release notes file was not found at ${file.path}.');
  }
  final notes = (await file.readAsString()).trim();
  if (notes.isEmpty) {
    throw const FormatException('Reviewed release notes must not be empty.');
  }
  return notes;
}

_PubspecVersion _readPubspecVersion(File file) {
  if (!file.existsSync()) {
    throw StateError('pubspec file was not found at ${file.path}.');
  }
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?)(?:\+([0-9]+))?\s*$',
    multiLine: true,
  ).firstMatch(file.readAsStringSync());
  if (match == null) {
    throw const FormatException(
      'Unable to read a semantic version from pubspec.yaml.',
    );
  }
  return _PubspecVersion(match.group(1)!, match.group(2) ?? '0');
}

Map<String, Object?> _availablePlatform({
  required String platform,
  required _PublishedArtifact artifact,
  required String version,
  required String buildNumber,
  required String releaseDate,
  required String releaseNotes,
  required String downloadUrl,
  required String minimumOsVersion,
  required String packageFormat,
  required String installationNote,
}) {
  return {
    'platform': platform,
    'displayName': _displayName(platform),
    'availability': 'available',
    'statusLabel': 'Latest release',
    'actionLabel': _actionLabel(platform),
    'availabilityMessage': '${_displayName(platform)} is ready to download.',
    'version': version,
    'buildNumber': buildNumber,
    'releaseDate': releaseDate,
    'fileSizeBytes': artifact.fileSizeBytes,
    'minimumOsVersion': minimumOsVersion,
    'releaseNotes': releaseNotes,
    'downloadUrl': downloadUrl,
    'packageFormat': packageFormat,
    'installationNote': installationNote,
    'sha256': artifact.sha256,
    'artifactName': artifact.artifactName,
    'isLatest': true,
  };
}

Map<String, Object?> _normalizeExisting(
  String platform,
  Map<String, Object?> existing,
) {
  final availability = _string(existing['availability']) ?? 'coming_soon';
  final normalized = Map<String, Object?>.from(existing)
    ..['platform'] = platform
    ..['displayName'] =
        _string(existing['displayName']) ?? _displayName(platform)
    ..['availability'] = availability
    ..['statusLabel'] =
        _string(existing['statusLabel']) ??
        (availability == 'available' ? 'Latest release' : 'Coming soon')
    ..['actionLabel'] =
        _string(existing['actionLabel']) ??
        (availability == 'available' ? _actionLabel(platform) : 'Coming soon')
    ..['availabilityMessage'] =
        _string(existing['availabilityMessage']) ??
        (availability == 'available'
            ? '${_displayName(platform)} is ready to download.'
            : '${_displayName(platform)} support is coming soon.');
  if (availability == 'available') {
    normalized['isLatest'] = existing['isLatest'] is bool
        ? existing['isLatest']
        : true;
  } else {
    // Schema v2 requires every platform to state whether it is the latest
    // public artifact. An unavailable platform is never eligible.
    normalized['isLatest'] = false;
  }
  return normalized;
}

Map<String, Object?> _comingSoon(String platform) => {
  'platform': platform,
  'displayName': _displayName(platform),
  'availability': 'coming_soon',
  'statusLabel': 'Coming soon',
  'actionLabel': 'Coming soon',
  'availabilityMessage': '${_displayName(platform)} support is coming soon.',
  'isLatest': false,
};

String _displayName(String platform) => switch (platform) {
  'android' => 'Android',
  'ios' => 'iOS',
  'windows' => 'Windows',
  'mac' => 'Mac',
  _ => platform,
};

String _actionLabel(String platform) => switch (platform) {
  'android' => 'Download APK',
  'ios' => 'Get iOS app',
  'windows' => 'Download for Windows',
  'mac' => 'Download for Mac',
  _ => 'Download',
};

String _minimumOs(String platform) => switch (platform) {
  'android' => 'Android 7.0+',
  'ios' => 'iOS 13+',
  'windows' => 'Windows 10+',
  'mac' => 'macOS 10.15+',
  _ => '',
};

String _packageFormatFor(String artifactName) {
  final dot = artifactName.lastIndexOf('.');
  final extension = dot == -1
      ? ''
      : artifactName.substring(dot + 1).toUpperCase();
  return extension.isEmpty ? 'Release package' : '$extension package';
}

String _installationNote(String platform, String artifactName) =>
    switch (platform) {
      'android' when artifactName.toLowerCase().endsWith('.apk') =>
        'Install the signed APK after download.',
      'android' => 'Follow the Android package installation instructions.',
      'ios' => 'Install through the approved Apple distribution channel.',
      'windows' => 'Open the installer after download.',
      'mac' => 'Open the signed package after download.',
      _ => 'Follow the installation instructions for your platform.',
    };

String? _string(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

class _PubspecVersion {
  const _PubspecVersion(this.version, this.buildNumber);

  final String version;
  final String buildNumber;
}

class _PublishedArtifact {
  const _PublishedArtifact({
    required this.platform,
    required this.artifactName,
    required this.fileSizeBytes,
    required this.sha256,
    this.downloadUrl,
    this.minimumOsVersion,
    this.packageFormat,
    this.installationNote,
  });

  final String platform;
  final String artifactName;
  final int fileSizeBytes;
  final String sha256;
  final String? downloadUrl;
  final String? minimumOsVersion;
  final String? packageFormat;
  final String? installationNote;

  factory _PublishedArtifact.fromJson(Map<String, Object?> json) {
    final platform = _string(json['platform']);
    final artifactName = _string(json['artifactName'] ?? json['fileName']);
    final size = json['fileSizeBytes'];
    final checksum = _string(json['sha256']);
    if (platform == null || !_platformOrder.contains(platform)) {
      throw FormatException('Unsupported artifact platform: $platform.');
    }
    if (artifactName == null ||
        artifactName.contains('/') ||
        artifactName.contains('\\')) {
      throw const FormatException('Artifact names must be simple filenames.');
    }
    if (size is! int || size <= 0) {
      throw const FormatException(
        'Artifact fileSizeBytes must be a positive integer.',
      );
    }
    if (checksum == null || !RegExp(_checksumExpression).hasMatch(checksum)) {
      throw const FormatException(
        'Artifact sha256 must be a 64-character hexadecimal digest.',
      );
    }
    final downloadUrl = _string(json['downloadUrl'] ?? json['url']);
    if (downloadUrl != null) {
      final uri = Uri.tryParse(downloadUrl);
      if (uri == null || uri.scheme != 'https') {
        throw const FormatException('Artifact downloadUrl must use HTTPS.');
      }
    }
    return _PublishedArtifact(
      platform: platform,
      artifactName: artifactName,
      fileSizeBytes: size,
      sha256: checksum.toUpperCase(),
      downloadUrl: downloadUrl,
      minimumOsVersion: _string(json['minimumOsVersion']),
      packageFormat: _string(json['packageFormat']),
      installationNote: _string(json['installationNote']),
    );
  }
}

class _Arguments {
  _Arguments(this._values, this._flags);

  final Map<String, List<String>> _values;
  final Set<String> _flags;

  static _Arguments parse(List<String> source) {
    final values = <String, List<String>>{};
    final flags = <String>{};
    for (var index = 0; index < source.length; index++) {
      final argument = source[index];
      if (!argument.startsWith('--')) {
        throw _UsageException('Unexpected argument: $argument.');
      }
      final name = argument.substring(2);
      if (name == 'help') {
        flags.add(name);
        continue;
      }
      if (index + 1 >= source.length || source[index + 1].startsWith('--')) {
        throw _UsageException('Missing value for --$name.');
      }
      values.putIfAbsent(name, () => []).add(source[++index]);
    }
    return _Arguments(values, flags);
  }

  bool flag(String name) => _flags.contains(name);

  String? value(String name) {
    final values = _values[name];
    return values != null && values.length == 1 ? values.single : null;
  }

  String requireValue(String name) =>
      value(name) ?? (throw _UsageException('Missing required --$name value.'));
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
