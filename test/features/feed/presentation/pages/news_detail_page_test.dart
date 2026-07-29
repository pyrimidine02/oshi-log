import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/presentation/pages/news_detail_page.dart';

void main() {
  testWidgets('news article uses a compact document hierarchy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(body: NewsArticleView(news: _news)),
      ),
    );

    expect(find.text('FIELD DISPATCH'), findsOneWidget);
    expect(find.text('라이브 일정 안내'), findsOneWidget);
    expect(find.byType(SliverAppBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('news article has no overflow at 320dp and 200 percent text', (
    tester,
  ) async {
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
          home: Scaffold(
            body: SingleChildScrollView(child: NewsArticleView(news: _news)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

final _news = NewsDetail(
  id: 'news-1',
  title: '라이브 일정 안내',
  body: '공연 장소와 입장 시간을 확인해 주세요.',
  status: 'published',
  publishedAt: DateTime.utc(2026, 7, 15),
);
