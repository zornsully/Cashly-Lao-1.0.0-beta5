/// Validates a Cashly Lao release candidate before it is allowed to publish.
///
/// This is intentionally a repository-local tool: it has no credentials and
/// never uploads, deploys, or changes a release. Its JSON summary is local
/// approval evidence for the manual free-tier release process.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cashly_lao/features/landing/domain/entities/release_manifest.dart'
    as landing;

const _tagPattern = r'^v(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)$';
const _shaPattern = r'^[a-f0-9]{7,64}$';

Future<void> main(List<String> arguments) async {
  try {
    final argumentsMap = _Arguments.parse(arguments);
    if (argumentsMap.flag('help')) {
      stdout.writeln(_usage);
      return;
    }

    final tag = argumentsMap.requireValue('tag');
    final tagMatch = RegExp(_tagPattern).firstMatch(tag);
    if (tagMatch == null) {
      throw _UsageException(
        'Release tag must look like v1.2.3 or v1.2.3-beta.1.',
      );
    }
    final tagVersion = tagMatch.group(1)!;
    final isPrerelease = tagVersion.contains('-');

    final pubspecPath = argumentsMap.value('pubspec') ?? 'pubspec.yaml';
    final pubspec = _readPubspecVersion(File(pubspecPath));
    if (pubspec.version != tagVersion) {
      throw StateError(
        'Version mismatch: tag $tag contains $tagVersion, while $pubspecPath '
        'contains ${pubspec.version}+${pubspec.buildNumber}.',
      );
    }

    final ref = argumentsMap.value('ref');
    if (ref != null && !RegExp(_shaPattern).hasMatch(ref)) {
      throw _UsageException(
        '--ref must be a lowercase Git commit SHA with 7–64 hexadecimal characters.',
      );
    }

    final artifactArguments = argumentsMap.values('artifact');
    final artifacts = <_ArtifactSummary>[];
    final platforms = <String>{};
    for (final argument in artifactArguments) {
      final artifact = await _verifyArtifact(argument, pubspec.version);
      if (!platforms.add(artifact.platform)) {
        throw _UsageException(
          'Only one artifact per platform may be supplied; duplicate: '
          '${artifact.platform}.',
        );
      }
      artifacts.add(artifact);
    }

    if (argumentsMap.flag('require-artifacts') && artifacts.isEmpty) {
      throw StateError(
        'At least one --artifact platform=path value is required.',
      );
    }

    final manifestPath = argumentsMap.value('manifest');
    if (manifestPath != null) {
      _verifyManifestShape(
        File(manifestPath),
        expectedTag: tag,
        expectedRef: ref,
        distributionPolicy: _readDistributionPolicy(
          argumentsMap.value('distribution-policy'),
        ),
      );
    }

    final expectedCertificate = _normalizeCertificateFingerprint(
      argumentsMap.value('expected-android-certificate-sha256'),
    );
    if (expectedCertificate != null &&
        !argumentsMap.flag('verify-android-signature')) {
      throw const _UsageException(
        '--expected-android-certificate-sha256 requires --verify-android-signature.',
      );
    }

    final androidCertificates = <String, String>{};
    if (argumentsMap.flag('verify-android-signature')) {
      final androidApks = artifacts.where(
        (artifact) =>
            artifact.platform == 'android' &&
            artifact.artifactExtension == '.apk',
      );
      if (expectedCertificate != null && androidApks.isEmpty) {
        throw StateError(
          'An expected Android signing certificate was provided without an APK artifact.',
        );
      }
      for (final artifact in androidApks) {
        final certificate = await _verifyAndroidSignature(
          artifact.file,
          expectedCertificate: expectedCertificate,
        );
        await _verifyAndroidPackage(
          artifact.file,
          expectedVersion: pubspec.version,
          expectedBuildNumber: pubspec.buildNumber,
        );
        androidCertificates[artifact.file.path] = certificate;
      }
    }

    final result = <String, Object?>{
      'tag': tag,
      'version': pubspec.version,
      'buildNumber': pubspec.buildNumber,
      'commitSha': ref,
      'channel': isPrerelease ? 'prerelease' : 'stable',
      'validatedAt': DateTime.now().toUtc().toIso8601String(),
      'artifacts': artifacts
          .map(
            (artifact) => artifact.toJson(
              signingCertificateSha256: androidCertificates[artifact.file.path],
            ),
          )
          .toList(),
    };

    final outputPath = argumentsMap.value('output');
    if (outputPath == null) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
    } else {
      final output = File(outputPath);
      await output.parent.create(recursive: true);
      await output.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(result)}\n',
      );
      stdout.writeln('Wrote release verification to ${output.path}.');
    }
  } on _UsageException catch (error) {
    stderr.writeln('Release validation error: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } catch (error, stackTrace) {
    stderr.writeln('Release validation failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

const _usage = '''
Usage:
  dart run tool/verify_release.dart --tag v1.2.3 [options]

Required:
  --tag <tag>                   Expected Git release tag (v*).

Options:
  --ref <sha>                   Exact tagged commit SHA.
  --pubspec <path>              pubspec.yaml path (default: pubspec.yaml).
  --manifest <path>             Validate a release manifest JSON document.
  --distribution-policy <path>  Reviewed policy required for schema-v3 manifest.
  --artifact <platform>=<path>  Verify a candidate artifact; repeatable.
  --require-artifacts            Fail when no artifacts are provided.
  --verify-android-signature     Use apksigner to verify APK signatures.
  --expected-android-certificate-sha256 <SHA-256>
                               Require this signing certificate fingerprint.
  --output <path>               Write a machine-readable summary JSON file.
  --help                        Show this help.
''';

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
      'pubspec.yaml must contain a semantic version such as 1.2.3+4.',
    );
  }
  return _PubspecVersion(match.group(1)!, match.group(2) ?? '0');
}

Future<_ArtifactSummary> _verifyArtifact(
  String source,
  String expectedVersion,
) async {
  final separator = source.indexOf('=');
  if (separator <= 0 || separator == source.length - 1) {
    throw _UsageException('--artifact must use platform=path syntax.');
  }
  final platform = source.substring(0, separator).toLowerCase();
  if (!const {'android', 'ios', 'windows', 'mac', 'web'}.contains(platform)) {
    throw _UsageException('Unsupported artifact platform: $platform.');
  }
  final file = File(source.substring(separator + 1));
  if (!file.existsSync()) {
    throw StateError('Artifact for $platform was not found at ${file.path}.');
  }
  final filename = file.uri.pathSegments.last;
  final extensionStart = filename.lastIndexOf('.');
  final extension = extensionStart == -1
      ? ''
      : filename.substring(extensionStart).toLowerCase();
  final allowedExtensions = switch (platform) {
    'android' => const {'.apk', '.aab'},
    'ios' => const {'.ipa'},
    'windows' => const {'.msix', '.msi', '.exe', '.zip'},
    'mac' => const {'.dmg', '.pkg', '.zip'},
    'web' => const {'.zip'},
    _ => const <String>{},
  };
  if (!allowedExtensions.contains(extension)) {
    throw StateError(
      'Unexpected $platform artifact extension $extension. Allowed: '
      '${allowedExtensions.join(', ')}.',
    );
  }
  final length = await file.length();
  if (length <= 0) {
    throw StateError('Artifact ${file.path} is empty.');
  }

  final canonicalPrefix = switch (platform) {
    'android' => 'Cashly-Lao-Android-$expectedVersion',
    'ios' => 'Cashly-Lao-iOS-$expectedVersion',
    'windows' => 'Cashly-Lao-Windows-$expectedVersion',
    'mac' => 'Cashly-Lao-macOS-$expectedVersion',
    'web' => 'Cashly-Lao-Web-$expectedVersion',
    _ => '',
  };
  if (!filename.startsWith(canonicalPrefix)) {
    throw StateError(
      'Artifact $filename must start with '
      '$canonicalPrefix.',
    );
  }

  final digest = await sha256.bind(file.openRead()).first;
  return _ArtifactSummary(
    platform: platform,
    file: file,
    byteLength: length,
    sha256: digest.toString().toUpperCase(),
  );
}

void _verifyManifestShape(
  File file, {
  required String expectedTag,
  required String? expectedRef,
  required landing.ReleaseDistributionPolicy distributionPolicy,
}) {
  if (!file.existsSync()) {
    throw StateError('Release manifest was not found at ${file.path}.');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Release manifest root must be a JSON object.');
  }
  final manifest = landing.ReleaseManifest.fromJson(
    decoded,
    distributionPolicy: distributionPolicy,
  );
  if (manifest.schemaVersion == landing.ReleaseManifest.currentSchemaVersion) {
    final release = manifest.release;
    if (release == null || release.tag != expectedTag) {
      throw StateError(
        'Release manifest tag must match the candidate tag $expectedTag.',
      );
    }
    if (expectedRef != null && release.commitSha != expectedRef) {
      throw StateError(
        'Release manifest commit must match the candidate commit $expectedRef.',
      );
    }
  }
}

landing.ReleaseDistributionPolicy _readDistributionPolicy(String? path) {
  if (path == null) return landing.ReleaseDistributionPolicy.unconfigured;
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Release distribution policy was not found at ${file.path}.',
    );
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'Release distribution policy root must be a JSON object.',
    );
  }
  return landing.ReleaseDistributionPolicy.fromJson(decoded);
}

String? _normalizeCertificateFingerprint(String? value) {
  if (value == null) return null;
  final normalized = value.replaceAll(RegExp(r'[:\s]'), '').toUpperCase();
  if (!RegExp(r'^[A-F0-9]{64}$').hasMatch(normalized)) {
    throw const _UsageException(
      '--expected-android-certificate-sha256 must be a 64-character SHA-256 fingerprint.',
    );
  }
  return normalized;
}

Future<String> _verifyAndroidSignature(
  File apk, {
  String? expectedCertificate,
}) async {
  final executable = _findApkSigner();
  if (executable == null) {
    throw StateError(
      'Could not find apksigner. Set APKSIGNER_PATH or install Android build-tools.',
    );
  }
  final result = await Process.run(executable.path, [
    'verify',
    '--verbose',
    '--print-certs',
    '--min-sdk-version',
    '24',
    apk.path,
  ]);
  if (result.exitCode != 0) {
    throw StateError(
      'APK signature verification failed for ${apk.path}: ${result.stderr}',
    );
  }
  final output = result.stdout.toString();
  final match = RegExp(
    r'certificate SHA-256 digest:\s*([A-Fa-f0-9:]+)',
  ).firstMatch(output);
  final actualCertificate = match?.group(1)?.replaceAll(':', '').toUpperCase();
  if (actualCertificate == null ||
      !RegExp(r'^[A-F0-9]{64}$').hasMatch(actualCertificate)) {
    throw StateError(
      'APK signature verification did not report a SHA-256 signing certificate for ${apk.path}.',
    );
  }
  if (expectedCertificate != null && actualCertificate != expectedCertificate) {
    throw StateError(
      'APK signing certificate does not match the approved fingerprint for ${apk.path}.',
    );
  }
  return actualCertificate;
}

Future<void> _verifyAndroidPackage(
  File apk, {
  required String expectedVersion,
  required String expectedBuildNumber,
}) async {
  final executable = _findAapt();
  if (executable == null) {
    throw StateError(
      'Could not find aapt. Set AAPT_PATH or install Android build-tools.',
    );
  }
  final result = await Process.run(executable.path, [
    'dump',
    'badging',
    apk.path,
  ]);
  if (result.exitCode != 0) {
    throw StateError(
      'APK package validation failed for ${apk.path}: ${result.stderr}',
    );
  }
  final expectedPackage =
      "package: name='com.cashlylao.app' versionCode='$expectedBuildNumber' versionName='$expectedVersion'";
  if (!result.stdout.toString().contains(expectedPackage)) {
    throw StateError(
      'APK package ID or version does not match com.cashlylao.app $expectedVersion+$expectedBuildNumber.',
    );
  }
}

File? _findApkSigner() {
  final configuredPath = Platform.environment['APKSIGNER_PATH'];
  if (configuredPath != null && File(configuredPath).existsSync()) {
    return File(configuredPath);
  }
  final androidHome =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null) return null;
  final buildTools = Directory(
    '$androidHome${Platform.pathSeparator}build-tools',
  );
  if (!buildTools.existsSync()) return null;
  final candidates =
      buildTools
          .listSync()
          .whereType<Directory>()
          .map(
            (directory) => File(
              '${directory.path}${Platform.pathSeparator}'
              'apksigner${Platform.isWindows ? '.bat' : ''}',
            ),
          )
          .where((file) => file.existsSync())
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
  return candidates.isEmpty ? null : candidates.first;
}

File? _findAapt() {
  final configuredPath = Platform.environment['AAPT_PATH'];
  if (configuredPath != null && File(configuredPath).existsSync()) {
    return File(configuredPath);
  }
  final androidHome =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null) return null;
  final buildTools = Directory(
    '$androidHome${Platform.pathSeparator}build-tools',
  );
  if (!buildTools.existsSync()) return null;
  final filename = Platform.isWindows ? 'aapt.exe' : 'aapt';
  final candidates =
      buildTools
          .listSync()
          .whereType<Directory>()
          .map(
            (directory) =>
                File('${directory.path}${Platform.pathSeparator}$filename'),
          )
          .where((file) => file.existsSync())
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
  return candidates.isEmpty ? null : candidates.first;
}

class _PubspecVersion {
  const _PubspecVersion(this.version, this.buildNumber);

  final String version;
  final String buildNumber;
}

class _ArtifactSummary {
  const _ArtifactSummary({
    required this.platform,
    required this.file,
    required this.byteLength,
    required this.sha256,
  });

  final String platform;
  final File file;
  final int byteLength;
  final String sha256;

  String get artifactExtension {
    final filename = file.uri.pathSegments.last;
    final dot = filename.lastIndexOf('.');
    return dot == -1 ? '' : filename.substring(dot).toLowerCase();
  }

  Map<String, Object> toJson({String? signingCertificateSha256}) => {
    'platform': platform,
    'artifactName': file.uri.pathSegments.last,
    'fileSizeBytes': byteLength,
    'sha256': sha256,
    'signingCertificateSha256': ?signingCertificateSha256,
  };
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
      if (const {
        'help',
        'require-artifacts',
        'verify-android-signature',
      }.contains(name)) {
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

  String? value(String name) => _values[name]?.singleOrNull;

  List<String> values(String name) =>
      List.unmodifiable(_values[name] ?? const []);

  String requireValue(String name) =>
      value(name) ?? (throw _UsageException('Missing required --$name value.'));
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}

extension on List<String> {
  String? get singleOrNull => length == 1 ? single : null;
}
