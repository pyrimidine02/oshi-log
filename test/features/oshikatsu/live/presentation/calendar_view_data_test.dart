import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/oshikatsu/live/domain/entities/calendar_event.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_calendar/calendar_view_data.dart';

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

  test(
    'birthday date stays civil while timed live shifts into JST next day',
    () {
      final instant = DateTime.parse('2026-09-30T18:00:00Z');
      final birthday = CalendarEvent(
        id: 'b',
        title: 'Birthday',
        date: instant,
        type: CalendarEventType.characterBirthday,
      );
      final timed = CalendarEvent(
        id: 'l',
        title: 'Live',
        date: instant,
        type: CalendarEventType.live,
      );
      expect(calendarEventDate(birthday), DateTime.utc(2026, 9, 30));
      expect(calendarEventDate(timed), DateTime.utc(2026, 10, 1, 3));
      expect(
        filterCalendarEvents([
          birthday,
          timed,
        ], selectedDate: DateTime(2026, 10, 1)),
        [timed],
      );
    },
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
