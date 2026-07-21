import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/core/widgets/layout/gbt_page_header.dart';

void main() {
  testWidgets('GBTPageHeader exposes the shared editorial hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const Scaffold(
          body: GBTPageHeader(
            eyebrow: 'TRAVEL DESK',
            title: '여정 준비',
            description: '성지와 일정을 한 곳에서 확인하세요.',
          ),
        ),
      ),
    );

    expect(find.text('TRAVEL DESK'), findsOneWidget);
    expect(find.text('여정 준비'), findsOneWidget);
    expect(find.text('성지와 일정을 한 곳에서 확인하세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GBTPageHeader preserves copy and can omit its divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const Scaffold(
          body: GBTPageHeader(
            eyebrow: 'Travel desk',
            title: '여정 준비',
            showDivider: false,
          ),
        ),
      ),
    );

    expect(find.text('Travel desk'), findsOneWidget);
    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(GBTPageHeader),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.border, isNull);
  });

  testWidgets('GBTPageHeader remains usable at 320dp and 200 percent text', (
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
          home: const Scaffold(
            body: SingleChildScrollView(
              child: GBTPageHeader(
                eyebrow: 'PILGRIMAGE ARCHIVE',
                title: '여행과 성지순례의 모든 기록',
                description: '다음 여정을 준비하고 지난 탐방을 다시 확인합니다.',
                trailing: IconButton(
                  onPressed: null,
                  icon: Icon(Icons.tune_outlined),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GBTPageHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GBTPageHeader preserves trailing control semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: GBTPageHeader(
            title: '여정 원장',
            trailing: IconButton(
              tooltip: '필터',
              onPressed: () {},
              icon: const Icon(Icons.tune_outlined),
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byIcon(Icons.tune_outlined));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(find.byTooltip('필터'), findsOneWidget);
    semantics.dispose();
  });
}
