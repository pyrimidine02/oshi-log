import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/search/presentation/pages/search_page.dart';

void main() {
  testWidgets('search history actions remain 48dp at 200 percent text', (
    tester,
  ) async {
    var openCount = 0;
    var removeCount = 0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: GBTTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SearchHistoryChip(
                label: 'i',
                isDark: false,
                onTap: () => openCount += 1,
                onRemove: () => removeCount += 1,
              ),
            ),
          ),
        ),
      ),
    );

    final inkWell = find
        .descendant(
          of: find.byType(SearchHistoryChip),
          matching: find.byType(InkWell),
        )
        .first;
    final removeButton = find.byType(IconButton);
    expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(inkWell).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(removeButton).height, greaterThanOrEqualTo(48));

    await tester.tap(inkWell);
    await tester.tap(removeButton);
    expect(openCount, 1);
    expect(removeCount, 1);
    expect(tester.takeException(), isNull);
  });
}
