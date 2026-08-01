import 'package:cashly_lao/core/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('caps the desktop workspace at 1440 pixels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveCenter(
            child: SizedBox(
              key: ValueKey('workspace'),
              width: double.infinity,
              height: 40,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('workspace'))).width, 1440);
  });
}
