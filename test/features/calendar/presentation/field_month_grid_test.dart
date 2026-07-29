import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/calendar/domain/entities/calendar_event.dart';
import 'package:oshi_log/features/calendar/presentation/field_calendar/field_calendar_page.dart';
import 'package:oshi_log/features/calendar/presentation/field_calendar/field_month_grid.dart';

void main() {
  testWidgets('FieldMonthGrid keeps empty days tappable at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldMonthGrid(
            visibleMonth: DateTime(2026, 7),
            events: const [],
            onSelectDate: (date) => selected = date,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('15'));
    expect(selected, DateTime(2026, 7, 15));
  });

  testWidgets('FieldMonthGrid describes the full date and visible events', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: FieldMonthGrid(
            visibleMonth: DateTime(2026, 7),
            events: [
              CalendarEvent(
                id: 'live-1',
                title: 'Harbor live',
                date: DateTime(2026, 7, 15),
                type: CalendarEventType.live,
              ),
              CalendarEvent(
                id: 'release-1',
                title: 'New single',
                date: DateTime(2026, 7, 15),
                type: CalendarEventType.release,
              ),
            ],
            onSelectDate: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(r'July 15, 2026.*Harbor live.*Live.*New single.*Release'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('FieldCalendarEventTypeRail scrolls without overflow at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldCalendarEventTypeRail(
            selectedTypes: const {},
            onToggle: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
