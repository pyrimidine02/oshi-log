import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/platform/providers/registrant_provider.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_comment_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_guide_entities.dart';
import 'package:oshi_log/features/place/places/presentation/pages/place_detail_page.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/place_onsite_sections.dart';
import 'package:oshi_log/features/shared/favorites/application/favorites_controller.dart';
import 'package:oshi_log/features/shared/favorites/domain/entities/favorite_entities.dart';

void main() {
  const place = PlaceDetail(
    id: 'p',
    name: '下北沢・長い名前のライブハウスと周辺の街並み',
    address: '〒155-0031 東京都世田谷区北沢二丁目六番五号 地下一階',
    types: [],
    description: '入口と撮影位置の説明。',
  );
  final guide = PlaceGuideSummary(
    id: 'g',
    title: '会場の入口・長いガイドタイトル',
    preview: '入口の短い紹介',
    updatedAt: DateTime(2026, 9, 3),
    hasImages: false,
    imageCount: 0,
  );

  Future<_Favorites> pump(
    WidgetTester tester, {
    String locale = 'ja',
    bool dark = false,
    bool loginResult = false,
  }) async {
    final favorites = _Favorites();
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeDetailControllerProvider.overrideWith(
            (ref, id) => _Detail(place),
          ),
          placeGuidesControllerProvider.overrideWith(
            (ref, id) => _Guides([guide]),
          ),
          placeCommentsControllerProvider.overrideWith(
            (ref, id) => _Comments(),
          ),
          placeTipsProvider.overrideWith((ref, key) async => []),
          contributorsProvider.overrideWith((ref, key) async => []),
          projectSelectionControllerProvider.overrideWith(
            (ref) => _Selection(),
          ),
          favoritesControllerProvider.overrideWith((ref) => favorites),
          isAuthenticatedProvider.overrideWithValue(false),
          authenticationGateProvider.overrideWithValue(
            (_) async => loginResult,
          ),
          placeGuideDetailProvider.overrideWith(
            (ref, key) async => PlaceGuideDetail(
              id: key.guideId,
              title: guide.title,
              contentMarkdown: '## 地下への入口\n右側の階段を利用します。',
              updatedAt: guide.updatedAt,
            ),
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ja'), Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: dark ? GBTTheme.darkFor(locale) : GBTTheme.lightFor(locale),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: PlaceDetailPage(
            placeId: 'p',
            onVerify: (context, ref, id, {placeName}) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return favorites;
  }

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$locale dark=$dark page orders manners, access, guide, tips at 320dp/200%',
        (tester) async {
          await pump(tester, locale: locale, dark: dark);
          final notice = find.byType(PlaceVisitNotice);
          final access = find.byType(PlaceAccessSection);
          final tips = find.byType(PlaceTipsSection);
          final guideText = find.text(locale == 'ja' ? '現地ガイド' : '현지 가이드');
          expect(
            tester.getTopLeft(notice).dy,
            lessThan(tester.getTopLeft(access).dy),
          );
          expect(
            tester.getTopLeft(access).dy,
            lessThan(tester.getTopLeft(guideText).dy),
          );
          expect(
            tester.getTopLeft(guideText).dy,
            lessThan(tester.getTopLeft(tips).dy),
          );
          final last = find.text(locale == 'ja' ? '記録協力者' : '기록 기여자');
          await tester.ensureVisible(last);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            find
                .text(locale == 'ja' ? 'ここに行ってきました' : '이곳에 다녀왔어요')
                .hitTestable(),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets(
    'guide action opens full Markdown and calls update date editorial',
    (tester) async {
      await pump(tester);
      final read = find.text('ガイド全文を読む');
      await tester.dragUntilVisible(
        read,
        find.byType(CustomScrollView),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      await tester.tap(read);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceGuideReader), findsOneWidget);
      expect(find.text('地下への入口'), findsOneWidget);
      expect(find.text('右側の階段を利用します。'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlaceGuideReader),
          matching: find.textContaining('現地確認日ではありません'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final success in [false, true]) {
    testWidgets('guest save resumes only after successful login: $success', (
      tester,
    ) async {
      final favorites = await pump(tester, locale: 'ko', loginResult: success);
      final save = find.byTooltip('즐겨찾기 추가');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(favorites.saves, success ? 1 : 0);
      expect(find.byType(PlaceDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Detail extends StateNotifier<AsyncValue<PlaceDetail>>
    implements PlaceDetailController {
  _Detail(PlaceDetail place) : super(AsyncData(place));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Guides extends StateNotifier<AsyncValue<List<PlaceGuideSummary>>>
    implements PlaceGuidesController {
  _Guides(List<PlaceGuideSummary> guides) : super(AsyncData(guides));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Comments extends StateNotifier<AsyncValue<List<PlaceComment>>>
    implements PlaceCommentsController {
  _Comments() : super(const AsyncData([]));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Selection extends StateNotifier<ProjectSelectionState>
    implements ProjectSelectionController {
  _Selection() : super(ProjectSelectionState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Favorites extends StateNotifier<AsyncValue<List<FavoriteItem>>>
    implements FavoritesController {
  _Favorites() : super(const AsyncData([]));
  int saves = 0;
  @override
  Future<Result<void>> toggleFavorite({
    required String entityId,
    required FavoriteType type,
    bool? isCurrentlyFavorite,
  }) async {
    saves += 1;
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
