import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/layout/gbt_page_header.dart';
import 'package:oshi_log/features/feed/presentation/field_guide/field_guide_music_page.dart';

void main() {
  testWidgets('music archive uses standard chrome at 320dp and 200 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: GBTTheme.light,
            locale: const Locale('ko'),
            home: const FieldGuideMusicPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GBTPageHeader), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
