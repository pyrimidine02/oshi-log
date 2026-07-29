import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';

void main() {
  group('GBTSpacing.bottomNavClearanceOf', () {
    testWidgets('includes a 34dp bottom safe-area inset', (tester) async {
      late double clearance;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: Builder(
            builder: (context) {
              clearance = GBTSpacing.bottomNavClearanceOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(clearance, 114);
    });

    testWidgets('uses the provided navigation bar height', (tester) async {
      late double clearance;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: Builder(
            builder: (context) {
              clearance = GBTSpacing.bottomNavClearanceOf(
                context,
                barHeight: 72,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(clearance, 122);
    });
  });
}
