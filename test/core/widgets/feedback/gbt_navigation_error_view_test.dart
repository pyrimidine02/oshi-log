import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/core/widgets/feedback/gbt_navigation_error_view.dart';

void main() {
  testWidgets('navigation error uses the shared recovery presentation', (
    tester,
  ) async {
    var recovered = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: GBTNavigationErrorView(
            message: '페이지를 찾을 수 없어요',
            details: '/missing-route',
            onRecover: () => recovered = true,
          ),
        ),
      ),
    );

    expect(find.text('페이지를 찾을 수 없어요'), findsOneWidget);
    expect(find.text('/missing-route'), findsOneWidget);
    expect(find.text('홈으로 돌아가기'), findsOneWidget);

    await tester.tap(find.text('홈으로 돌아가기'));
    expect(recovered, isTrue);
  });

  testWidgets('navigation error scrolls at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 480),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: GBTTheme.light,
          home: const Scaffold(
            body: GBTNavigationErrorView(
              message: '요청한 여정 페이지를 열 수 없어요',
              details: '링크가 올바른지 확인한 뒤 다시 시도해 주세요.',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
