import 'package:cashly_lao/features/landing/presentation/screens/legal_document_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpLegalDocumentPage(
    WidgetTester tester,
    Widget page,
    String path,
  ) async {
    // The page is a single long CustomScrollView; only slivers near the
    // viewport get built, so a tall surface is needed to assert on
    // sections further down without manually scrolling each into view.
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: path,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/login', builder: (context, state) => const SizedBox()),
        GoRoute(path: path, builder: (context, state) => page),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('renders the Privacy Policy document with its sections', (
    tester,
  ) async {
    await pumpLegalDocumentPage(
      tester,
      const LegalDocumentPage.privacy(),
      '/privacy',
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Our commitment'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
  });

  testWidgets('renders the Terms of Service document with its sections', (
    tester,
  ) async {
    await pumpLegalDocumentPage(
      tester,
      const LegalDocumentPage.terms(),
      '/terms',
    );

    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Early-release availability'), findsOneWidget);
    expect(find.text('Not financial advice'), findsOneWidget);
  });

  testWidgets('native back action navigates to sign in instead of landing', (
    tester,
  ) async {
    final router = await pumpLegalDocumentPage(
      tester,
      const LegalDocumentPage.privacy(),
      '/privacy',
    );

    await tester.tap(find.widgetWithText(TextButton, 'Back to sign in'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });
}
