import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/places/domain/entities/place_region_entities.dart';
import 'package:oshi_log/features/places/presentation/pages/places_map_page.dart';

void main() {
  testWidgets('map search keeps a fixed field and sheet as results change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildSubject({double keyboardInset = 0}) {
      return MaterialApp(
        locale: const Locale('ko'),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: FieldMapSearchSheet(
              places: const [
                PlaceSummary(
                  id: 'kawasaki',
                  name: '카와사키 DICE',
                  address: '카와사키',
                  latitude: 35.53,
                  longitude: 139.70,
                  types: ['animation'],
                  tags: [],
                ),
              ],
              regionOptionsState: const AsyncData(
                RegionFilterOptions(
                  countries: [],
                  popularRegions: [],
                  totalRegions: 0,
                  totalPlaces: 1,
                  lastUpdated: '',
                ),
              ),
              onSelectPlace: (_) {},
              onSelectRegion: (_) {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSubject());

    final initialFieldSize = tester.getSize(
      find.byKey(const Key('field-map-search-field-frame')),
    );
    final initialSheetSize = tester.getSize(
      find.byKey(const Key('field-map-search-sheet')),
    );

    await tester.enterText(find.byType(TextField), '카와사키');
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('field-map-search-field-frame'))),
      initialFieldSize,
    );
    expect(initialFieldSize.height, 48);
    expect(
      tester.getSize(find.byKey(const Key('field-map-search-sheet'))),
      initialSheetSize,
    );
    expect(find.text('카와사키 DICE'), findsOneWidget);
    expect(find.byKey(const Key('field-map-search-results')), findsOneWidget);

    await tester.pumpWidget(buildSubject(keyboardInset: 320));
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('field-map-search-field-frame'))),
      initialFieldSize,
    );
    expect(
      tester.getSize(find.byKey(const Key('field-map-search-sheet'))),
      initialSheetSize,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'map search keeps its pinned field on a short keyboard viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 360),
              viewInsets: EdgeInsets.only(bottom: 240),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: FieldMapSearchSheet(
                places: const [],
                regionOptionsState: const AsyncData(
                  RegionFilterOptions(
                    countries: [],
                    popularRegions: [],
                    totalRegions: 0,
                    totalPlaces: 0,
                    lastUpdated: '',
                  ),
                ),
                onSelectPlace: (_) {},
                onSelectRegion: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('field-map-search-field-frame'))),
        const Size(288, 48),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
