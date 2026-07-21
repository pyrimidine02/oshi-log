import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/application/places_controller.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/places/presentation/widgets/field_map_controls.dart';

void main() {
  testWidgets('map search stays one 48dp pill without extra actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var localSearches = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: FieldMapMissionStrip(
              onLocalSearch: () => localSearches += 1,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('field-map-mission-strip'))).height,
      48,
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byIcon(Icons.route_outlined), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.public_rounded), findsNothing);
    expect(
      find.bySemanticsLabel('Search places and regions on this map'),
      findsOneWidget,
    );
    _expectEnabledButtonWithTap(
      tester,
      find.bySemanticsLabel('Search places and regions on this map'),
    );

    await tester.tap(find.byKey(const Key('field-map-local-search')));
    expect(localSearches, 1);
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
          child: Scaffold(body: FieldMapMissionStrip(onLocalSearch: () {})),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('map filters use scrollable service-style chips', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapFilterChips(
            activeFilterCount: 2,
            projectLabel: 'Girls Band Cry',
            regionLabel: 'Tokyo',
            bandLabel: 'Togenashi Togeari',
            onFiltersTap: () => actions.add('filters'),
            onProjectTap: () => actions.add('project'),
            onRegionTap: () => actions.add('region'),
            onBandTap: () => actions.add('band'),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Filters 2'), findsOneWidget);
    expect(find.text('Girls Band Cry'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('field-map-filter-all'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Filters 2'));
    await tester.tap(find.text('Tokyo'));
    expect(actions, ['filters', 'region']);
  });

  testWidgets('half-sheet results use horizontal field-note cards', (
    tester,
  ) async {
    const places = [
      PlaceSummary(
        id: 'first',
        name: 'Kawasaki Station',
        address: 'Kawasaki',
        latitude: 35.53,
        longitude: 139.70,
        types: ['animation'],
        tags: [],
      ),
      PlaceSummary(
        id: 'second',
        name: 'Club Citta',
        address: 'Kawasaki',
        latitude: 35.52,
        longitude: 139.69,
        types: ['live_house'],
        tags: [],
      ),
    ];
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapPlaceCarousel(
            places: places,
            selectedPlaceId: 'first',
            onOpen: (place) => opened.add(place.id),
            onDirections: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('field-map-place-carousel')), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('FIELD NOTE'), findsNWidgets(2));
    await tester.tap(
      find.byKey(const ValueKey<String>('field-map-carousel-card-first')),
    );
    expect(opened, ['first']);
  });

  testWidgets('field-note carousel grows for accessibility text', (
    tester,
  ) async {
    const place = PlaceSummary(
      id: 'large-text',
      name: 'A long field location name',
      address: 'A long address for accessibility testing',
      latitude: 35.53,
      longitude: 139.70,
      types: ['animation'],
      tags: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Scaffold(
            body: FieldMapPlaceCarousel(
              places: const [place],
              onOpen: (_) {},
              onDirections: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('field-map-place-carousel'))).height,
      240,
    );
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

    expect(tester.getSize(find.byType(FieldMapFieldIndex)).height, 192);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byKey(const Key('field-map-index-project')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-region')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-band')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-mode')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-ledger')), findsOneWidget);
    expect(find.byKey(const Key('field-map-index-row-rule')), findsNWidgets(3));
    expect(find.byKey(const Key('field-map-index-column-rule')), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    for (final category in const ['Project', 'Region', 'Band', 'Order']) {
      expect(find.text(category), findsOneWidget);
    }
    for (final number in const ['01', '02', '03', '04']) {
      expect(find.text(number), findsNothing);
    }
    for (final icon in const [
      Icons.layers_outlined,
      Icons.location_on_outlined,
      Icons.groups_2_outlined,
      Icons.swap_vert_rounded,
    ]) {
      expect(find.byIcon(icon), findsNothing);
    }
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
    await tester.tap(find.byKey(const Key('field-map-index-mode')));
    expect(actions, contains('all'));
    semantics.dispose();
  });

  testWidgets('empty map result stays compact and offers filter reset', (
    tester,
  ) async {
    var resetCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapEmptyResult(
            hasActiveFilters: true,
            onResetFilters: () => resetCount += 1,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    expect(find.text('No places match selected filters'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FieldMapEmptyResult)).height,
      lessThanOrEqualTo(112),
    );
    await tester.tap(find.text('Reset filters'));
    expect(resetCount, 1);
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

    expect(
      tester.getSize(find.byType(FieldMapFieldIndex)).height,
      lessThanOrEqualTo(288),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('field index supports iOS accessibility text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Scaffold(
            body: FieldMapFieldIndex(
              projectLabel: 'Girls Band Cry',
              regionLabel: 'All regions',
              bandLabel: 'Togenashi Togeari',
              mode: PlaceListMode.nearby,
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

    expect(
      tester.getSize(find.byType(FieldMapFieldIndex)).height,
      lessThanOrEqualTo(384),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('canvas keeps one circular 48dp location target', (tester) async {
    var locationCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapCanvasControls(
            onCurrentLocation: () => locationCount += 1,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('field-map-fit-places')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('field-map-current-location'))),
      const Size(48, 48),
    );
    expect(find.byType(Card), findsNothing);

    await tester.tap(find.byKey(const Key('field-map-current-location')));
    expect(locationCount, 1);
  });

  testWidgets('collapsed ledger header expands and owns mode switching', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var collapseCount = 0;
    var selectedMode = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMapLedgerHeader(
            placeCount: 18,
            modeLabels: const ['Map', 'Events', 'Visits', 'Stamps'],
            selectedModeIndex: selectedMode,
            onModeSelected: (value) => selectedMode = value,
            onCollapse: () => collapseCount += 1,
          ),
        ),
      ),
    );

    final header = tester.getSemantics(
      find.bySemanticsLabel('Field ledger · 18 spots'),
    );
    expect(header.flagsCollection.isHeader, isTrue);
    final expand = find.bySemanticsLabel('Expand list');
    _expectEnabledButtonWithTap(tester, expand);
    expect(find.byType(SegmentedButton<int>), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.tap(expand);
    expect(selectedMode, 1);
    expect(collapseCount, 1);
    semantics.dispose();
  });

  testWidgets('map filters open as a plain value list', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFieldMapFilters(
                context: context,
                projectLabel: 'Girls Band Cry',
                regionLabel: 'Tokyo',
                bandLabel: 'Togenashi Togeari',
                mode: PlaceListMode.nearby,
                hasRegionFilter: false,
                hasBandFilter: false,
                onProjectTap: () => actions.add('project'),
                onRegionTap: () => actions.add('region'),
                onBandTap: () => actions.add('band'),
                onModeChanged: (mode) => actions.add(mode.name),
                onResetFilters: () => actions.add('reset'),
              ),
              child: const Text('Open filters'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    expect(find.text('Map filters'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Girls Band Cry'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(4));
    expect(find.text('01'), findsNothing);
    expect(
      find.text('Choose the travel layers shown on the map.'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('field-map-index-project')));
    await tester.pumpAndSettle();
    expect(actions, contains('project'));
  });
}

void _expectEnabledButtonWithTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(node.flagsCollection.isButton, isTrue);
  expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
}
