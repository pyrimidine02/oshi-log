import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/navigation/gbt_search_app_bar.dart';

void main() {
  testWidgets('compact search bar stays inside the shared page chrome', (
    tester,
  ) async {
    final controller = TextEditingController(text: '라이브');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          appBar: GBTSearchAppBar(
            controller: controller,
            hintText: '장소, 일정, 게시글 검색',
            onChanged: (_) {},
            onSubmitted: (_) {},
            onClear: controller.clear,
          ),
        ),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('라이브'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(AppBar)).height, 56);
  });

  testWidgets('search chrome has no overflow at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: GBTTheme.light,
          home: Scaffold(
            appBar: GBTSearchAppBar(
              controller: controller,
              hintText: '장소, 이벤트, 뉴스, 게시글 검색',
              onChanged: (_) {},
              onSubmitted: (_) {},
              onClear: controller.clear,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GBTSearchAppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
