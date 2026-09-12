import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/layout/gbt_field_primitives.dart';

void main() {
  testWidgets('plain service headings reserve no decorative label space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: const Scaffold(
          body: GBTFieldSectionHeader(eyebrow: '', title: '다가오는 공연'),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(GBTFieldSectionHeader)).height,
      tester.getSize(find.text('다가오는 공연')).height,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('section header keeps its eyebrow visible and accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: GBTFieldSectionHeader(
            eyebrow: 'PILGRIMAGE',
            title: 'Places worth the trip',
            actionLabel: 'Open map',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('PILGRIMAGE'), findsOneWidget);
    expect(find.text('Places worth the trip'), findsOneWidget);
    expect(find.bySemanticsLabel('Open map'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('section header stacks its action for narrow large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: GBTFieldSectionHeader(
              eyebrow: 'TRAVEL LOGBOOK',
              title: 'Your recorded pilgrimage places',
              actionLabel: 'View all places',
              onAction: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Your recorded pilgrimage places'), findsOneWidget);
    expect(find.text('View all places'), findsOneWidget);
  });

  testWidgets('section header stacks action inside a 280dp parent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: GBTFieldSectionHeader(
                eyebrow: 'TRAVEL LOGBOOK',
                title: 'Your recorded pilgrimage places',
                actionLabel: 'View all places',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final titleBottom = tester
        .getBottomLeft(find.text('Your recorded pilgrimage places'))
        .dy;
    final actionTop = tester.getTopLeft(find.text('View all places')).dy;

    expect(actionTop, greaterThan(titleBottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('section header keeps a 350dp parent side by side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: GBTFieldSectionHeader(
                eyebrow: 'TRAVEL LOGBOOK',
                title: 'Your recorded pilgrimage places',
                actionLabel: 'View all',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final titleTop = tester
        .getTopLeft(find.text('Your recorded pilgrimage places'))
        .dy;
    final actionTop = tester.getTopLeft(find.text('View all')).dy;

    expect((actionTop - titleTop).abs(), lessThan(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('field surface enforces a 48dp action target', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: Scaffold(
          body: GBTFieldSurface(
            onTap: () => tapped = true,
            accentColor: GBTColors.primary,
            child: const SizedBox(
              key: ValueKey('field-surface-content'),
              width: 12,
              height: 16,
              child: Text('Journey note'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(GBTFieldSurface)).height, 48);
    await tester.tap(find.text('Journey note'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
