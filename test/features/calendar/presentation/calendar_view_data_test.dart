import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:girlsbandtabi_app/features/calendar/presentation/field_calendar/calendar_view_data.dart';

void main() {
  final live = CalendarEvent(
    id: 'live-1',
    title: 'Live',
    date: DateTime(2026, 7, 15),
    type: CalendarEventType.live,
  );
  final release = CalendarEvent(
    id: 'release-1',
    title: 'Release',
    date: DateTime(2026, 7, 20),
    type: CalendarEventType.release,
  );

  test('filterCalendarEvents combines date and immutable type filters', () {
    final filtered = filterCalendarEvents(
      [live, release],
      selectedDate: DateTime(2026, 7, 15),
      selectedTypes: const {CalendarEventType.live},
    );

    expect(filtered, [live]);
    expect(() => filtered.add(release), throwsUnsupportedError);
  });

  test(
    'filterCalendarGridEvents applies type filters without a day filter',
    () {
      final filtered = filterCalendarGridEvents(
        [live, release],
        selectedTypes: const {CalendarEventType.release},
      );

      expect(filtered, [release]);
      expect(() => filtered.add(live), throwsUnsupportedError);
    },
  );

  test('groupCalendarEvents uses normalized dates and chronological order', () {
    final groups = groupCalendarEvents([release, live]);

    expect(groups.map((group) => group.date), [
      DateTime(2026, 7, 15),
      DateTime(2026, 7, 20),
    ]);
    expect(groups.first.events, [live]);
  });
}
