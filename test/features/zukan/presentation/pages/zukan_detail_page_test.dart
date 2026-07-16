import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:girlsbandtabi_app/core/router/app_router.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_colors.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/zukan/application/zukan_controller.dart';
import 'package:girlsbandtabi_app/features/zukan/domain/entities/zukan_collection.dart';
import 'package:girlsbandtabi_app/features/zukan/presentation/pages/zukan_detail_page.dart';

void main() {
  final collection = ZukanCollection(
    id: 'route-notes',
    title: '가와사키 로케이션 노트',
    description: '작품 속 이동 동선을 따라 기록하는 표본집',
    rewardDescription: '전체 지점을 방문하면 필드 배지를 획득합니다.',
    stamps: [
      ZukanStamp(
        id: 'station-a',
        placeId: 'place-a',
        placeName: '시부야 역 북구 광장',
        status: StampStatus.stamped,
        episodeHint: 'EP.03 / 첫 만남',
        visitedAt: DateTime(2026, 7, 10),
        sortOrder: 1,
      ),
      ZukanStamp(
        id: 'live-house',
        placeId: 'place-b',
        placeName: '클럽 치타 라이브 홀 정문',
        status: StampStatus.notVisited,
        episodeHint: 'EP.08 / 공연 장면',
        sortOrder: 2,
      ),
      ZukanStamp(
        id: 'river-bank',
        placeId: 'place-c',
        placeName: '타마가와 강변',
        status: StampStatus.stamped,
        visitedAt: DateTime(2026, 7, 12),
        sortOrder: 3,
      ),
    ],
  );

  testWidgets('replaces the legacy card grid with a ruled specimen index', (
    tester,
  ) async {
    await _pumpDetail(tester, collection: collection);

    expect(find.text('SPECIMEN FILE / 01'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('STATION INDEX / 방문 지점'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('field-zukan-stamp-row-station-a')),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps visited place navigation and locked row semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final router = GoRouter(
      initialLocation: '/zukan/route-notes',
      routes: [
        GoRoute(
          path: '/zukan/:collectionId',
          name: AppRoutes.zukanDetail,
          builder: (_, state) => ZukanDetailPage(
            collectionId: state.pathParameters['collectionId']!,
          ),
        ),
        GoRoute(
          path: '/overlay/places/:placeId',
          name: AppRoutes.overlayPlaceDetail,
          builder: (_, state) =>
              Scaffold(body: Text('place:${state.pathParameters['placeId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zukanCollectionDetailProvider.overrideWith(
            (ref, collectionId) => Future.value(collection),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final visitedNode = tester.getSemantics(
      find.bySemanticsLabel(RegExp('시부야 역 북구 광장.*방문 완료')),
    );
    expect(visitedNode.flagsCollection.isButton, isTrue);
    expect(
      visitedNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );

    final lockedNode = tester.getSemantics(
      find.bySemanticsLabel(RegExp('클럽 치타 라이브 홀 정문.*미방문')),
    );
    expect(lockedNode.label, contains('미방문'));
    expect(
      lockedNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('field-zukan-stamp-row-station-a')),
    );
    await tester.pumpAndSettle();
    expect(find.text('place:place-a'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('remains readable at 320dp with 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDetail(
      tester,
      collection: collection,
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(2),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field-zukan-stamp-row-live-house')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('field-zukan-stamp-row-live-house')),
          )
          .height,
      greaterThanOrEqualTo(72),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the blue rule and completed teal in dark mode', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      collection: collection,
      theme: GBTTheme.dark,
      locale: const Locale('en'),
    );

    final blueRule = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('field-zukan-detail-blue-rule')),
    );
    final stampedStatus = tester.widget<Text>(
      find.byKey(const ValueKey('field-zukan-stamp-status-station-a')),
    );
    expect(blueRule.color, GBTColors.darkPrimary);
    expect(stampedStatus.style?.color, GBTColors.darkSecondary);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required ZukanCollection collection,
  ThemeData? theme,
  Locale locale = const Locale('ko'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        zukanCollectionDetailProvider.overrideWith(
          (ref, collectionId) => Future.value(collection),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
        theme: theme ?? GBTTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: const ZukanDetailPage(collectionId: 'route-notes'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
