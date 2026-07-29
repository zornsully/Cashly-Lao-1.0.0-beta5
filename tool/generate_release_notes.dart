/// Creates a review-only release-notes draft from local Git commit subjects.
///
/// This tool never publishes notes. A maintainer must review and edit the
/// generated draft (or the checked-in RELEASE_NOTES.md) before approving the
/// manual public release publication.
library;

import 'dart:io';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Arguments.parse(arguments);
    if (options.flag('help')) {
      stdout.writeln(_usage);
      return;
    }
    final output = File(options.requireValue('output'));
    final to = options.value('to') ?? 'HEAD';
    final from = options.value('from');
    final range = from == null ? to : '$from..$to';
    final result = await Process.run('git', [
      'log',
      '--no-merges',
      '--format=%s%x1e',
      range,
    ]);
    if (result.exitCode != 0) {
      throw StateError('Unable to read Git history: ${result.stderr}');
    }
    final subjects = result.stdout
        .toString()
        .split('\u001e')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final groups = <String, List<String>>{
      'New features': [],
      'Improvements': [],
      'Bug fixes': [],
      'Security updates': [],
      'Breaking changes': [],
      'Known issues': [],
    };
    for (final subject in subjects) {
      final normalized = subject.toLowerCase();
      final group = normalized.contains('breaking') || subject.contains('!')
          ? 'Breaking changes'
          : normalized.startsWith('security') || normalized.contains('cve-')
          ? 'Security updates'
          : normalized.startsWith('fix') || normalized.startsWith('bug')
          ? 'Bug fixes'
          : normalized.startsWith('feat') || normalized.startsWith('feature')
          ? 'New features'
          : 'Improvements';
      groups[group]!.add(subject);
    }

    final buffer = StringBuffer()
      ..writeln('# Draft release notes')
      ..writeln()
      ..writeln('> Review and edit this draft before production publication.')
      ..writeln();
    for (final entry in groups.entries) {
      buffer.writeln('## ${entry.key}');
      if (entry.value.isEmpty) {
        buffer.writeln('- None reported.');
      } else {
        for (final subject in entry.value) {
          buffer.writeln('- $subject');
        }
      }
      buffer.writeln();
    }
    await output.parent.create(recursive: true);
    await output.writeAsString(buffer.toString());
    stdout.writeln('Wrote review-only release notes draft to ${output.path}.');
  } on _UsageException catch (error) {
    stderr.writeln('Release notes error: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } catch (error, stackTrace) {
    stderr.writeln('Release notes generation failed: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

const _usage = '''
Usage:
  dart run tool/generate_release_notes.dart --output build/release-notes.md [options]

Options:
  --from <git ref>  First excluded ref (usually the previous version tag).
  --to <git ref>    Last included ref (default: HEAD).
  --output <path>   Draft Markdown output path.
  --help            Show this help.
''';

class _Arguments {
  _Arguments(this._values, this._flags);

  final Map<String, String> _values;
  final Set<String> _flags;

  static _Arguments parse(List<String> source) {
    final values = <String, String>{};
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
      if (!const {'from', 'to', 'output'}.contains(name)) {
        throw _UsageException('Unknown option --$name.');
      }
      if (values.containsKey(name)) {
        throw _UsageException('Option --$name may only be provided once.');
      }
      if (index + 1 >= source.length || source[index + 1].startsWith('--')) {
        throw _UsageException('Missing value for --$name.');
      }
      values[name] = source[++index];
    }
    return _Arguments(values, flags);
  }

  bool flag(String name) => _flags.contains(name);

  String? value(String name) => _values[name];

  String requireValue(String name) =>
      value(name) ?? (throw _UsageException('Missing required --$name value.'));
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
