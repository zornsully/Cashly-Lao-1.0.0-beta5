import 'dart:async';

import 'package:cashly_lao/core/startup/cashly_startup_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a branded loading state while startup is pending', (
    tester,
  ) async {
    final initialization = Completer<void>();

    await tester.pumpWidget(
      CashlyStartupApp(
        initialize: () => initialization.future,
        appBuilder: (_) => const MaterialApp(home: Text('Ready')),
      ),
    );

    expect(find.text('Loading Cashly Lao…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    initialization.complete();
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('shows a recoverable error and retries startup', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      CashlyStartupApp(
        initialize: () {
          attempts++;
          if (attempts == 1) {
            return Future<void>.error(StateError('network unavailable'));
          }
          return Future<void>.value();
        },
        appBuilder: (_) => const MaterialApp(home: Text('Ready')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cashly Lao could not start.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Ready'), findsOneWidget);
  });
}
