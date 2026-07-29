import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

import 'package:oshi_log/core/widgets/common/gbt_image.dart';

void main() {
  testWidgets('GBTImage renders with semantic label', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    await mockNetworkImages(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GBTImage(
              imageUrl: 'https://example.com/test.png',
              width: 80,
              height: 80,
              semanticLabel: '테스트 이미지',
              useShimmer: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('테스트 이미지'), findsOneWidget);
    });
    semanticsHandle.dispose();
  });
}
