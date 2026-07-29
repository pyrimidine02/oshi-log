import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/presentation/field_guide/sections/field_guide_kit_section.dart';

void main() {
  Widget buildSubject({TextScaler textScaler = TextScaler.noScaling}) {
    return MaterialApp(
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: FieldGuideKitSection(
            onMusicTap: () {},
            onCheerGuidesTap: () {},
            onCalendarTap: () {},
            onQuotesTap: () {},
            onCollectionTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('field kit reads as one travel document in journey order', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byKey(const Key('field-kit-document')), findsOneWidget);
    expect(find.text('FAN REFERENCE'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Music & cheering'), findsOneWidget);
    expect(find.text('Memories & collection'), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    final routeKeys = const [
      'field-kit-route-calendar',
      'field-kit-route-music',
      'field-kit-route-cheer',
      'field-kit-route-collection',
      'field-kit-route-quotes',
    ];
    final routeTops = [
      for (final key in routeKeys) tester.getTopLeft(find.byKey(Key(key))).dy,
    ];
    expect(routeTops, orderedEquals([...routeTops]..sort()));
  });

  testWidgets('all five routes expose accessible 48dp actions', (tester) async {
    final semantics = tester.ensureSemantics();
    final actions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldGuideKitSection(
            onMusicTap: () => actions.add('music'),
            onCheerGuidesTap: () => actions.add('cheer'),
            onCalendarTap: () => actions.add('calendar'),
            onQuotesTap: () => actions.add('quotes'),
            onCollectionTap: () => actions.add('collection'),
          ),
        ),
      ),
    );

    for (final entry in const <String, String>{
      'field-kit-route-calendar': 'calendar',
      'field-kit-route-music': 'music',
      'field-kit-route-cheer': 'cheer',
      'field-kit-route-collection': 'collection',
      'field-kit-route-quotes': 'quotes',
    }.entries) {
      final finder = find.byKey(Key(entry.key));
      await tester.ensureVisible(finder);
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
      await tester.tap(finder);
      await tester.pump();
      expect(actions, contains(entry.value));
    }
    semantics.dispose();
  });

  testWidgets('stage headings are semantic headers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildSubject());

    for (final label in const [
      '01 Schedule',
      '02 Music & cheering',
      '03 Memories & collection',
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.flagsCollection.isHeader, isTrue);
    }
    semantics.dispose();
  });

  testWidgets('field kit reflows at 300 percent text on 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSubject(textScaler: const TextScaler.linear(3)),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('field-kit-route-quotes')), findsOneWidget);
  });
}
