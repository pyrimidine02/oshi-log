import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_spacing.dart';
import 'package:girlsbandtabi_app/core/widgets/common/gbt_pressable.dart';

void main() {
  testWidgets('GBTPressable guarantees a 44dp touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GBTPressable(
              onTap: () {},
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(GBTPressable));
    expect(size.width, greaterThanOrEqualTo(GBTSpacing.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(GBTSpacing.minTouchTarget));
  });

  testWidgets('GBTPressable exposes button semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GBTPressable(onTap: () {}, child: const Text('Open details')),
        ),
      ),
    );

    final node = tester.getSemantics(find.text('Open details'));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}
