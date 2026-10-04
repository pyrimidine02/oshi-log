import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/community/posts/application/local_post_bookmarks_controller.dart';
import 'package:oshi_log/features/community/posts/presentation/pages/post_bookmarks_page.dart';

void main() {
  testWidgets('bookmark row has no overflow at compact large text', (
    tester,
  ) async {
    await _pumpCompact(
      tester,
      BookmarkedPostRow(
        item: LocalBookmarkedPost(
          postId: 'post-1',
          projectCode: 'gbc',
          title: '카와사키 순례 루트와 공연장 정보를 공유합니다',
          bookmarkedAt: DateTime.utc(2026, 7, 15),
        ),
        onTap: () {},
      ),
    );

    expect(find.textContaining('카와사키'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCompact(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
        textScaler: TextScaler.linear(2),
      ),
      child: MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}
