import 'dart:io';

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/app/compositions/search/presentation/pages/search_page.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/shared/search/application/search_controller.dart';
import 'package:oshi_log/features/shared/search/domain/entities/search_entities.dart';

import '../../../testing/tolerant_local_file_comparator.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final original = goldenFileComparator;
    goldenFileComparator = TolerantLocalFileComparator(
      Uri.file(
        '${Directory.current.path}/test/features/search/presentation/'
        'search_states_test.dart',
      ),
      precisionTolerance: 0.015,
    );
    addTearDown(() => goldenFileComparator = original);
  });

  for (final (locale, brightness) in [
    ('ko', Brightness.light),
    ('ko', Brightness.dark),
    ('ja', Brightness.light),
    ('ja', Brightness.dark),
  ]) {
    for (final compact in [false, true]) {
      final variant =
          '${locale}_${brightness.name}_${compact ? '320_200' : '390_100'}';
      testWidgets('empty category clears filter with query intact $variant', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(
          Size(compact ? 320 : 390, compact ? 760 : 844),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              searchControllerProvider.overrideWith(
                (ref) => _Search(
                  ref,
                  const AsyncData([
                    SearchItem(
                      id: 'place-1',
                      title: 'Live house',
                      type: SearchItemType.place,
                      sourceId: 'place-1',
                    ),
                  ]),
                ),
              ),
            ],
            child: _app(
              locale,
              const SearchPage(initialQuery: 'MyGO'),
              brightness: brightness,
              textScale: compact ? 2 : 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final events = find.text(locale == 'ko' ? '이벤트' : 'イベント');
        await tester.ensureVisible(events);
        await tester.tap(events);
        await tester.pumpAndSettle();
        final all = find.text(locale == 'ko' ? '전체 결과 보기' : 'すべての結果を見る');
        await tester.ensureVisible(all);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('search-states-golden')),
          matchesGoldenFile('goldens/search_category_empty_$variant.png'),
        );
        await tester.tap(all);
        await tester.pumpAndSettle();
        expect(find.text('Live house'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'MyGO',
        );
        expect(tester.takeException(), isNull);
      });
      testWidgets(
        'retry preserves query and hides raw server diagnostics $variant',
        (tester) async {
          await tester.binding.setSurfaceSize(
            Size(compact ? 320 : 390, compact ? 760 : 844),
          );
          addTearDown(() => tester.binding.setSurfaceSize(null));
          late _Search controller;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                searchControllerProvider.overrideWith(
                  (ref) => controller = _Search(
                    ref,
                    AsyncError(
                      const ServerFailure('SQL internal trace', code: '500'),
                      StackTrace.current,
                    ),
                  ),
                ),
              ],
              child: _app(
                locale,
                const SearchPage(initialQuery: 'MyGO'),
                brightness: brightness,
                textScale: compact ? 2 : 1,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.textContaining('SQL'), findsNothing);
          expect(
            find.text(locale == 'ko' ? '검색 결과를 불러오지 못했어요' : '検索結果を読み込めませんでした'),
            findsOneWidget,
          );
          final retry = find.text(locale == 'ko' ? '다시 시도' : '再試行');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('search-states-golden')),
            matchesGoldenFile('goldens/search_error_$variant.png'),
          );
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(controller.queries, ['MyGO', 'MyGO']);
          expect(controller.refreshes.last, isTrue);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'MyGO',
          );
        },
      );

      testWidgets(
        'no results offers editing without discarding query $variant',
        (tester) async {
          await tester.binding.setSurfaceSize(
            Size(compact ? 320 : 390, compact ? 760 : 844),
          );
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                searchControllerProvider.overrideWith(
                  (ref) => _Search(ref, const AsyncData([])),
                ),
              ],
              child: _app(
                locale,
                const SearchPage(initialQuery: 'MyGO'),
                brightness: brightness,
                textScale: compact ? 2 : 1,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final edit = find.text(locale == 'ko' ? '검색어 바꾸기' : 'キーワードを変える');
          await tester.ensureVisible(edit);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('search-states-golden')),
            matchesGoldenFile('goldens/search_no_results_$variant.png'),
          );
          await tester.tap(edit);
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.controller!.text, 'MyGO');
          expect(
            field.controller!.selection,
            const TextSelection(baseOffset: 0, extentOffset: 4),
          );
          expect(field.focusNode!.hasFocus, isTrue);
        },
      );
    }
  }
}

Widget _app(
  String locale,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 2,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: const [Locale('ko'), Locale('ja')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: brightness == Brightness.dark
      ? GBTTheme.darkFor(locale)
      : GBTTheme.lightFor(locale),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: RepaintBoundary(
      key: const ValueKey('search-states-golden'),
      child: child!,
    ),
  ),
  home: child,
);

class _Search extends SearchController {
  _Search(super.ref, this.result);
  final AsyncValue<List<SearchItem>> result;
  final queries = <String>[];
  final refreshes = <bool>[];
  @override
  Future<void> search(
    String query, {
    bool forceRefresh = false,
    List<String> types = const [],
  }) async {
    queries.add(query);
    refreshes.add(forceRefresh);
    state = result;
  }
}
