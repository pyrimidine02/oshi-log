import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/navigation/gbt_segmented_tab_bar.dart';

void main() {
  testWidgets('large text keeps all tab labels reachable and readable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: DefaultTabController(
            length: 5,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: GBTSegmentedTabBar(
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Places'),
                    Tab(text: 'Events'),
                    Tab(text: 'News'),
                    Tab(text: 'Fans & people'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
    expect(tabBar.tabAlignment, TabAlignment.start);
    expect(
      tabBar.unselectedLabelColor,
      GBTTheme.light.colorScheme.onSurfaceVariant,
    );
    await tester.drag(find.byType(TabBar), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fans & people'));
    await tester.pumpAndSettle();
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      4,
    );
    expect(tester.takeException(), isNull);
  });

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
