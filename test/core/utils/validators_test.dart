import 'package:cashly_lao/core/utils/validators.dart';
import 'package:cashly_lao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validators need a [BuildContext] to look up localized messages, so every
/// test pumps a minimal localized widget tree and captures its context.
Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}

void main() {
  group('Validators.email', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.email(context, ''), isNotNull);
      expect(Validators.email(context, null), isNotNull);
    });

    testWidgets('rejects malformed addresses', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.email(context, 'not-an-email'), isNotNull);
      expect(Validators.email(context, 'missing@domain'), isNotNull);
      expect(Validators.email(context, '@nouser.com'), isNotNull);
    });

    testWidgets('accepts valid addresses', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.email(context, 'user@example.com'), isNull);
      expect(Validators.email(context, '  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.password(context, ''), isNotNull);
    });

    testWidgets('rejects passwords shorter than 8 characters', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      expect(Validators.password(context, 'Ab1'), isNotNull);
    });

    testWidgets('rejects passwords missing an uppercase letter', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      expect(Validators.password(context, 'lowercase1'), isNotNull);
    });

    testWidgets('rejects passwords missing a digit', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.password(context, 'NoDigitsHere'), isNotNull);
    });

    testWidgets('accepts a strong password', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.password(context, 'Str0ngPass'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(
        Validators.confirmPassword(context, '', 'Str0ngPass'),
        isNotNull,
      );
    });

    testWidgets('rejects mismatched passwords', (tester) async {
      final context = await _pumpContext(tester);
      expect(
        Validators.confirmPassword(context, 'Different1', 'Str0ngPass'),
        isNotNull,
      );
    });

    testWidgets('accepts matching passwords', (tester) async {
      final context = await _pumpContext(tester);
      expect(
        Validators.confirmPassword(context, 'Str0ngPass', 'Str0ngPass'),
        isNull,
      );
    });
  });

  group('Validators.displayName', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.displayName(context, ''), isNotNull);
      expect(Validators.displayName(context, '  '), isNotNull);
    });

    testWidgets('rejects single-character names', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.displayName(context, 'A'), isNotNull);
    });

    testWidgets('accepts a valid name', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.displayName(context, 'Somchai'), isNull);
    });
  });

  group('Validators.requiredField', () {
    testWidgets('rejects empty/whitespace input with the given label', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      expect(
        Validators.requiredField(context, '', label: 'Account name'),
        isNotNull,
      );
      expect(
        Validators.requiredField(context, '   ', label: 'Account name'),
        isNotNull,
      );
    });

    testWidgets('accepts non-empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(
        Validators.requiredField(context, 'Cash wallet', label: 'Name'),
        isNull,
      );
    });
  });

  group('Validators.amount', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.amount(context, ''), isNotNull);
    });

    testWidgets('rejects non-numeric input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.amount(context, 'abc'), isNotNull);
    });

    testWidgets('accepts positive, negative, and decimal numbers', (
      tester,
    ) async {
      final context = await _pumpContext(tester);
      expect(Validators.amount(context, '100'), isNull);
      expect(Validators.amount(context, '-50.25'), isNull);
      expect(Validators.amount(context, '0'), isNull);
    });
  });

  group('Validators.positiveAmount', () {
    testWidgets('rejects empty input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.positiveAmount(context, ''), isNotNull);
    });

    testWidgets('rejects non-numeric input', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.positiveAmount(context, 'abc'), isNotNull);
    });

    testWidgets('rejects zero and negative amounts', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.positiveAmount(context, '0'), isNotNull);
      expect(Validators.positiveAmount(context, '-10'), isNotNull);
    });

    testWidgets('accepts positive decimal amounts', (tester) async {
      final context = await _pumpContext(tester);
      expect(Validators.positiveAmount(context, '42.50'), isNull);
    });
  });
}
