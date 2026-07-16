import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/places/application/places_controller.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/places/presentation/widgets/field_map_controls.dart';

void main() {
  const selectedPlace = PlaceSummary(
    id: 'live-house-1',
    name: '라이브 하우스 마리나',
    address: '도쿄도 시나가와구 텐노즈',
    latitude: 35.6208,
    longitude: 139.7502,
    types: ['live_house'],
    tags: ['Girls Band Cry', 'Togenashi Togeari'],
    distanceLabel: '1.2 km',
    isVerified: true,
  );

  testWidgets(
    'exploration overlay keeps layers and selected field card off native map',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final actions = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          home: Scaffold(
            body: FieldMapExplorationOverlay(
              projectLabel: 'Girls Band Cry',
              regionLabel: '도쿄',
              bandLabel: '토게나시 토게아리',
              mode: PlaceListMode.nearby,
              hasRegionFilter: true,
              hasBandFilter: true,
              selectedPlace: selectedPlace,
              onProjectTap: () => actions.add('project'),
              onRegionTap: () => actions.add('region'),
              onBandTap: () => actions.add('band'),
              onModeChanged: (mode) => actions.add(mode.name),
              onOpenSelectedPlace: (place) => actions.add('open:${place.id}'),
              onDirections: (place) => actions.add('directions:${place.id}'),
            ),
          ),
        ),
      );

      final overlay = find.byKey(
        const ValueKey<String>('field-map-exploration-overlay'),
      );
      final layers = find.byKey(
        const ValueKey<String>('field-map-exploration-layers'),
      );
      final fieldCard = find.byKey(
        const ValueKey<String>('field-map-selected-place-card'),
      );
      expect(overlay, findsOneWidget);
      expect(layers, findsOneWidget);
      expect(fieldCard, findsOneWidget);
      expect(
        tester.getTopLeft(layers).dy,
        lessThan(tester.getTopLeft(fieldCard).dy),
      );
      expect(find.text('라이브 하우스 마리나'), findsOneWidget);
      expect(find.textContaining('도쿄도 시나가와구'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(Chip), findsNothing);
      expect(find.byType(AndroidView), findsNothing);
      expect(find.byType(UiKitView), findsNothing);

      for (final entry in const <String, String>{
        'field-map-index-project': 'project',
        'field-map-index-region': 'region',
        'field-map-index-band': 'band',
        'field-map-index-mode': 'all',
        'field-map-selected-place-open': 'open:live-house-1',
        'field-map-selected-place-directions': 'directions:live-house-1',
      }.entries) {
        final action = find.byKey(ValueKey<String>(entry.key));
        _expectAccessibleTapTarget(tester, action);
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pump();
        expect(actions, contains(entry.value));
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('layers and selected field card survive 320dp at 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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
            body: SingleChildScrollView(
              child: FieldMapExplorationOverlay(
                projectLabel: '걸즈 밴드 크라이 장기 프로젝트',
                regionLabel: '도쿄도 시나가와구 전체 지역',
                bandLabel: '토게나시 토게아리와 관련 밴드',
                mode: PlaceListMode.nearby,
                hasRegionFilter: true,
                hasBandFilter: true,
                selectedPlace: selectedPlace,
                onProjectTap: () {},
                onRegionTap: () {},
                onBandTap: () {},
                onModeChanged: (_) {},
                onOpenSelectedPlace: (_) {},
                onDirections: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = find.byKey(
      const ValueKey<String>('field-map-exploration-overlay'),
    );
    expect(tester.getSize(overlay).width, lessThanOrEqualTo(320));
    for (final key in const [
      'field-map-index-project',
      'field-map-index-region',
      'field-map-index-band',
      'field-map-index-mode',
      'field-map-selected-place-open',
      'field-map-selected-place-directions',
    ]) {
      _expectAccessibleTapTarget(tester, find.byKey(ValueKey<String>(key)));
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

void _expectAccessibleTapTarget(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  final node = tester.getSemantics(finder);
  expect(node.flagsCollection.isButton, isTrue);
  expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
}
