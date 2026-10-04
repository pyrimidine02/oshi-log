import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/place/collections/application/zukan_controller.dart';
import 'package:oshi_log/features/place/collections/domain/entities/zukan_collection.dart';
import 'package:oshi_log/features/place/collections/presentation/pages/zukan_detail_page.dart';
import '../../../../../testing/tolerant_local_file_comparator.dart';
import '../../../../../testing/platform_golden.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });

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

  testWidgets(
    'scene hints stay out of rendering and semantics until revealed',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpDetail(tester, collection: collection);
      expect(find.text('EP.03 / 첫 만남'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('첫 만남')), findsNothing);
      final reveal = find.text('스포일러 보기').first;
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pump();
      expect(find.text('EP.03 / 첫 만남'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('첫 만남')), findsOneWidget);
      await tester.tap(find.text('스포일러 숨기기'));
      await tester.pump();
      expect(find.text('EP.03 / 첫 만남'), findsNothing);
      expect(find.textContaining('이동 순서'), findsOneWidget);
      await tester.tap(find.text('스포일러 보기').first);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await _pumpDetail(tester, collection: collection);
      expect(find.text('EP.03 / 첫 만남'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('첫 만남')), findsNothing);
      semantics.dispose();
    },
  );

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final compact in [false, true]) {
        final name =
            'collection_${locale}_${dark ? 'dark' : 'light'}_'
            '${compact ? '320_200' : '390_100'}';
        testWidgets(name, (tester) async {
          final original = goldenFileComparator;
          goldenFileComparator = TolerantLocalFileComparator(
            Uri.file(
              '${Directory.current.path}/test/features/place/collections/'
              'presentation/pages/zukan_detail_page_test.dart',
            ),
            precisionTolerance: 0.015,
          );
          addTearDown(() => goldenFileComparator = original);
          tester.view.physicalSize = Size(compact ? 320 : 390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pumpDetail(
            tester,
            collection: collection,
            locale: Locale(locale),
            theme: dark ? GBTTheme.darkFor(locale) : GBTTheme.lightFor(locale),
            textScaler: TextScaler.linear(compact ? 2 : 1),
          );
          await expectLater(
            find.byKey(const ValueKey('collection-golden')),
            matchesGoldenFile('$platformGoldenDirectory/$name.png'),
          );
          await tester.dragUntilVisible(
            find.byKey(const ValueKey('field-zukan-stamp-row-river-bank')),
            find.byType(ListView),
            const Offset(0, -250),
          );
          if (compact) {
            expect(tester.getSize(find.text('03')).height, lessThan(50));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
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
          child: const RepaintBoundary(
            key: ValueKey('collection-golden'),
            child: ZukanDetailPage(collectionId: 'route-notes'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
