import 'package:cashly_lao/core/widgets/app_skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSkeletonList renders itemCount skeleton tiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppSkeletonList(itemCount: 4)),
    );
    await tester.pump();

    expect(find.byType(AppSkeletonListTile), findsNWidgets(4));
  });

  testWidgets('AppSkeletonList defaults to 6 tiles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppSkeletonList()));
    await tester.pump();

    expect(find.byType(AppSkeletonListTile), findsNWidgets(6));
  });

  testWidgets('SkeletonBox pulses without throwing across several frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonBox(width: 100))),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}
