import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_colors.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_mode_dock.dart';

void main() {
  testWidgets('floating Explore dock fits and changes mode at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FieldExploreModeDock(
                selectedIndex: selected,
                labels: const ['지도', '이벤트', '기록', '도감'],
                onSelected: (index) => setState(() => selected = index),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FieldExploreModeDock)).height,
      lessThanOrEqualTo(64),
    );
    for (var index = 0; index < 4; index++) {
      final target = tester.getSize(
        find.byKey(ValueKey('field-explore-mode-$index')),
      );
      expect(target.height, greaterThanOrEqualTo(48));
      expect(target.width, greaterThanOrEqualTo(48));
    }
    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('field-explore-mode-0')))
          .color,
      GBTColors.primary,
    );
    await tester.tap(find.text('도감'));
    await tester.pumpAndSettle();
    expect(selected, 3);
  });

  testWidgets('floating Explore dock stays usable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FieldExploreModeDock(
                selectedIndex: 1,
                labels: const ['지도', '이벤트', '기록', '도감'],
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('이벤트'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FieldExploreModeDock)).height,
      lessThanOrEqualTo(72),
    );
  });

  testWidgets('dark dock keeps a blue selected destination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.dark,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FieldExploreModeDock(
              selectedIndex: 2,
              labels: const ['Map', 'Events', 'Visits', 'Stamps'],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('field-explore-mode-2')))
          .color,
      GBTColors.darkPrimary,
    );
  });

  testWidgets('dock exposes four button semantics and selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldExploreModeDock(
            selectedIndex: 1,
            labels: const ['지도', '이벤트', '기록', '도감'],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final selectedNode = tester.getSemantics(find.bySemanticsLabel('이벤트'));
    expect(selectedNode.label, '이벤트');
    expect(selectedNode.flagsCollection.isButton, isTrue);
    expect(selectedNode.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(
      selectedNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );

    final mapNode = tester.getSemantics(find.bySemanticsLabel('지도'));
    expect(mapNode.flagsCollection.isButton, isTrue);
    expect(mapNode.flagsCollection.isSelected, ui.Tristate.isFalse);
    expect(find.bySemanticsLabel('기록'), findsOneWidget);
    expect(find.bySemanticsLabel('도감'), findsOneWidget);
    semantics.dispose();
  });
}
