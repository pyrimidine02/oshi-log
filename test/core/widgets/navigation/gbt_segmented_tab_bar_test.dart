import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/navigation/gbt_segmented_tab_bar.dart';

void main() {
  testWidgets('segmented tabs use a flat field-notes indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const DefaultTabController(
          length: 2,
          child: Scaffold(
            body: GBTSegmentedTabBar(tabs: [Text('지도'), Text('일정')]),
          ),
        ),
      ),
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final indicator = tabBar.indicator! as BoxDecoration;

    expect(indicator.boxShadow, isNull);
    expect(tabBar.dividerColor, Colors.transparent);
    expect(tester.takeException(), isNull);
  });
}
