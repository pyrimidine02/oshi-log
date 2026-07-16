import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/application/places_controller.dart';
import 'package:girlsbandtabi_app/features/places/presentation/widgets/field_map_controls.dart';

void main() {
  testWidgets('mission strip stays 56dp and keeps searches independent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var localSearches = 0;
    var unifiedSearches = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: FieldMapMissionStrip(
              placeCount: 18,
              onLocalSearch: () => localSearches += 1,
              onUnifiedSearch: () => unifiedSearches += 1,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('field-map-mission-strip'))).height,
      56,
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(
      find.bySemanticsLabel('Search places and regions on this map'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Unified search'), findsOneWidget);
    _expectEnabledButtonWithTap(
      tester,
      find.bySemanticsLabel('Search places and regions on this map'),
    );
    _expectEnabledButtonWithTap(
      tester,
      find.bySemanticsLabel('Unified search'),
    );

    await tester.tap(find.byKey(const Key('field-map-local-search')));
    expect(localSearches, 1);
    expect(unifiedSearches, 0);
    await tester.tap(find.byKey(const Key('field-map-unified-search')));
    expect(localSearches, 1);
    expect(unifiedSearches, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('mission strip survives 200 percent text at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: FieldMapMissionStrip(
              placeCount: 128,
              onLocalSearch: () {},
              onUnifiedSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('field index moves all filters off the map canvas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapFieldIndex(
            projectLabel: 'Girls Band Cry',
            regionLabel: 'Tokyo',
            bandLabel: 'Togenashi Togeari',
            mode: PlaceListMode.nearby,
            hasRegionFilter: true,
            hasBandFilter: true,
            onProjectTap: () => actions.add('project'),
            onRegionTap: () => actions.add('region'),
            onBandTap: () => actions.add('band'),
            onModeChanged: (mode) => actions.add(mode.name),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FieldMapFieldIndex)).height, 49);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byKey(const Key('field-map-index-project')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-region')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-band')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-mode')), findsOneWidget);
    for (final label in const [
      'Project, Girls Band Cry',
      'Region, Tokyo',
      'Band, Togenashi Togeari',
      'Order, Nearby',
    ]) {
      _expectEnabledButtonWithTap(tester, find.bySemanticsLabel(label));
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('field-map-index-project')));
    expect(actions, contains('project'));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-250, 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('field-map-index-mode')));
    expect(actions, contains('all'));
    semantics.dispose();
  });

  testWidgets('field index supports dark theme and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: FieldMapFieldIndex(
              projectLabel: '길고 긴 프로젝트 이름',
              regionLabel: '전체 지역',
              bandLabel: '모든 밴드',
              mode: PlaceListMode.all,
              hasRegionFilter: false,
              hasBandFilter: false,
              onProjectTap: () {},
              onRegionTap: () {},
              onBandTap: () {},
              onModeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FieldMapFieldIndex)).height, 49);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canvas controls remain separate square 48dp targets', (
    tester,
  ) async {
    var fitCount = 0;
    var locationCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapCanvasControls(
            onFitPlaces: () => fitCount += 1,
            onCurrentLocation: () => locationCount += 1,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('field-map-fit-places'))),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(const Key('field-map-current-location'))),
      const Size(48, 48),
    );
    expect(find.byType(Card), findsNothing);

    await tester.tap(find.byKey(const Key('field-map-fit-places')));
    await tester.tap(find.byKey(const Key('field-map-current-location')));
    expect(fitCount, 1);
    expect(locationCount, 1);
  });

  testWidgets('ledger header keeps reset and collapse as separate actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var resetCount = 0;
    var collapseCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapLedgerHeader(
            placeCount: 18,
            hasActiveFilters: true,
            onResetFilters: () => resetCount += 1,
            onCollapse: () => collapseCount += 1,
          ),
        ),
      ),
    );

    final header = tester.getSemantics(
      find.bySemanticsLabel('Field ledger · 18 spots'),
    );
    expect(header.flagsCollection.isHeader, isTrue);
    final reset = find.bySemanticsLabel('Reset filters');
    final collapse = find.bySemanticsLabel('Collapse list');
    _expectEnabledButtonWithTap(tester, reset);
    _expectEnabledButtonWithTap(tester, collapse);

    await tester.tap(reset);
    await tester.tap(collapse);
    expect(resetCount, 1);
    expect(collapseCount, 1);
    semantics.dispose();
  });
}

void _expectEnabledButtonWithTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(node.flagsCollection.isButton, isTrue);
  expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
}
