import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_mode_dock.dart';

void main() {
  testWidgets('bottom Explore bar exposes all destinations and changes mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 1;

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

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsNothing);
    for (final label in const ['지도', '이벤트', '기록', '도감']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getSize(find.byType(FieldExploreModeDock)).height,
      FieldExploreModeDock.height,
    );

    await tester.tap(find.text('도감'));
    await tester.pumpAndSettle();
    expect(selected, 3);
  });

  testWidgets('bottom Explore bar survives 200 percent text at 320dp', (
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
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
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
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Visits'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FieldExploreModeDock)).height,
      lessThanOrEqualTo(80),
    );
  });

  testWidgets('dark mode uses same persistent bottom control', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.dark,
        home: Scaffold(
          body: FieldExploreModeDock(
            selectedIndex: 2,
            labels: const ['Map', 'Events', 'Visits', 'Stamps'],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });
}
