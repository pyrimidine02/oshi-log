import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/application/local_post_bookmarks_controller.dart';
import 'package:oshi_log/features/feed/domain/entities/community_moderation.dart';
import 'package:oshi_log/features/feed/presentation/pages/post_bookmarks_page.dart';
import 'package:oshi_log/features/feed/presentation/pages/user_connections_page.dart';

void main() {
  testWidgets('connection row remains readable without a duplicate view CTA', (
    tester,
  ) async {
    await _pumpCompact(
      tester,
      UserConnectionRow(
        item: UserFollowSummary(
          userId: 'user-1',
          displayName: '순례자',
          followedAt: DateTime.utc(2026, 7, 15),
          bio: '라이브와 성지를 따라 여행합니다.',
        ),
        onTap: () {},
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('순례자'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
