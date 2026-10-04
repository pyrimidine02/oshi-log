import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/location/location_service.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/platform/router/navigation_state.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_region_entities.dart';
import 'package:oshi_log/features/place/places/presentation/pages/places_map_page.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/field_map_controls.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/field_place_sheet_row.dart';
import '../../../../../testing/tolerant_local_file_comparator.dart';

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

  Future<_Places> pump(
    WidgetTester tester, {
    String locale = 'ja',
    bool dark = false,
    bool native = false,
    bool compact = true,
  }) async {
    debugDefaultTargetPlatformOverride = native
        ? TargetPlatform.android
        : TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = Size(compact ? 320 : 390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = _Location();
    when(
      () => location.getCurrentLocation(requestPermission: false),
    ).thenThrow(const LocationFailure('denied', code: 'permission_denied'));
    final places = _Places();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          placesListControllerProvider.overrideWith((_) => places),
          placesRegionOptionsControllerProvider.overrideWith((_) => _Regions()),
          projectsControllerProvider.overrideWith((_) => _Projects()),
          projectSelectionControllerProvider.overrideWith((_) => _Selection()),
          selectedProjectKeyProvider.overrideWith((_) => null),
          selectedProjectIdProvider.overrideWith((_) => null),
          selectedPlaceRegionCodesProvider.overrideWith((_) => ['JP-13']),
          currentNavIndexProvider.overrideWith((_) => NavIndex.map),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ja'), Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: dark ? GBTTheme.darkFor(locale) : GBTTheme.lightFor(locale),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(compact ? 2 : 1)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('map-golden'),
            child: PlacesMapPage(
              isActive: false,
              onShowBandFilter: (_, _, _, _) async {},
              onShowProjectPicker: (_, _, _) async => null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verify(
      () => location.getCurrentLocation(requestPermission: false),
    ).called(1);
    return places;
  }

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('$locale dark=$dark fallback stays usable at 320dp/200%', (
        tester,
      ) async {
        final places = await pump(tester, locale: locale, dark: dark);
        expect(find.byKey(const Key('map-fallback-list')), findsOneWidget);
        expect(find.byKey(const Key('map-filter-summary')), findsOneWidget);
        expect(find.byKey(const Key('map-choose-region')), findsOneWidget);
        final clear = find.byKey(const Key('map-reset-filters'));
        await tester.ensureVisible(clear);
        await tester.tap(clear);
        expect(places.resets, 1);
        await tester.dragUntilVisible(
          find.byType(FieldPlaceSheetRow),
          find.byKey(const Key('map-fallback-list')),
          const Offset(0, -200),
        );
        expect(find.text('下北沢ライブハウス'), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }

  testWidgets(
    'sheet reaches all three stops and changes preview to full list',
    (tester) async {
      await pump(tester, native: true);
      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.snapSizes, [sheet.minChildSize, .4, .9]);
      expect(sheet.controller!.size, sheet.minChildSize);
      sheet.controller!.jumpTo(.4);
      await tester.pumpAndSettle();
      expect(sheet.controller!.size, closeTo(.4, .001));
      await tester.dragUntilVisible(
        find.byType(FieldMapPlaceCarousel),
        find.byKey(const Key('field-map-sheet-safe-content')),
        const Offset(0, -100),
      );
      expect(find.byType(FieldMapPlaceCarousel), findsOneWidget);
      sheet.controller!.jumpTo(.9);
      await tester.pumpAndSettle();
      expect(find.byType(FieldMapPlaceCarousel), findsNothing);
      await tester.dragUntilVisible(
        find.byType(FieldPlaceSheetRow),
        find.byKey(const Key('field-map-sheet-safe-content')),
        const Offset(0, -100),
      );
      expect(find.byType(FieldPlaceSheetRow), findsOneWidget);
      sheet.controller!.jumpTo(sheet.minChildSize);
      await tester.pumpAndSettle();
      expect(sheet.controller!.size, closeTo(sheet.minChildSize, .001));
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('map and list views keep the same place results', (tester) async {
    await pump(tester, native: true);
    await tester.tap(find.byKey(const Key('map-list-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-fallback-list')), findsOneWidget);
    await tester.dragUntilVisible(
      find.byType(FieldPlaceSheetRow),
      find.byKey(const Key('map-fallback-list')),
      const Offset(0, -200),
    );
    expect(find.text('下北沢ライブハウス'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('map-list-toggle')));
    await tester.tap(find.byKey(const Key('map-list-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final compact in [false, true]) {
        final name =
            'map_${locale}_${dark ? 'dark' : 'light'}_'
            '${compact ? '320_200' : '390_100'}';
        testWidgets(name, (tester) async {
          final original = goldenFileComparator;
          goldenFileComparator = TolerantLocalFileComparator(
            Uri.file(
              '${Directory.current.path}/test/features/place/places/'
              'presentation/pages/places_map_page_test.dart',
            ),
            precisionTolerance: 0.015,
          );
          addTearDown(() => goldenFileComparator = original);
          await pump(tester, locale: locale, dark: dark, compact: compact);
          await expectLater(
            find.byKey(const ValueKey('map-golden')),
            matchesGoldenFile('goldens/$name.png'),
          );
          expect(tester.takeException(), isNull);
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  }
}

class _Location extends Mock implements LocationService {}

class _Places extends StateNotifier<AsyncValue<List<PlaceSummary>>>
    implements PlacesListController {
  _Places()
    : super(
        const AsyncData([
          PlaceSummary(
            id: 'p',
            name: '下北沢ライブハウス',
            address: '東京都世田谷区北沢二丁目六番五号',
            latitude: 35.66,
            longitude: 139.66,
          ),
        ]),
      );
  int resets = 0;
  @override
  void resetFilters({bool reload = true}) => resets++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Regions extends StateNotifier<AsyncValue<RegionFilterOptions>>
    implements PlacesRegionOptionsController {
  _Regions()
    : super(
        const AsyncData(
          RegionFilterOptions(
            countries: [],
            popularRegions: [],
            totalRegions: 0,
            totalPlaces: 1,
            lastUpdated: '',
          ),
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Projects extends StateNotifier<AsyncValue<List<Project>>>
    implements ProjectsController {
  _Projects() : super(const AsyncData([]));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Selection extends StateNotifier<ProjectSelectionState>
    implements ProjectSelectionController {
  _Selection() : super(ProjectSelectionState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
