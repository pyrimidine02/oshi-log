import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_colors.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/core/widgets/navigation/gbt_standard_app_bar.dart';

void main() {
  testWidgets(
    'standard app bar uses the field-paper surface and no elevation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GBTTheme.light,
          home: Builder(
            builder: (context) =>
                Scaffold(appBar: gbtStandardAppBar(context, title: '일정')),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, GBTColors.appBackground);
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(find.text('일정'), findsOneWidget);
    },
  );

  testWidgets('standard app bar truncates a long title at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: GBTTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              appBar: gbtStandardAppBar(context, title: '성지순례 여정과 이벤트 기록 아카이브'),
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('성지순례 여정과 이벤트 기록 아카이브'));
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
