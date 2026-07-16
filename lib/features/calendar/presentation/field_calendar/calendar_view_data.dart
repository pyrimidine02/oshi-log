/// EN: Immutable view-data transformations for the Field Calendar.
/// KO: Field Calendar를 위한 불변 뷰 데이터 변환.
library;

import '../../domain/entities/calendar_event.dart';

/// EN: Calendar events grouped under a normalized local date.
/// KO: 정규화된 로컬 날짜로 묶인 캘린더 이벤트입니다.
class CalendarDateGroup {
  const CalendarDateGroup({required this.date, required this.events});

  final DateTime date;
  final List<CalendarEvent> events;
}

/// EN: Applies the optional day and event-type filters without mutation.
/// KO: 선택 날짜와 이벤트 유형 필터를 원본 변경 없이 적용합니다.
List<CalendarEvent> filterCalendarEvents(
  Iterable<CalendarEvent> events, {
  DateTime? selectedDate,
  Set<CalendarEventType> selectedTypes = const {},
}) {
  final filtered = events.where((event) {
    final matchesDate =
        selectedDate == null || isSameCalendarDate(event.date, selectedDate);
    final matchesType =
        selectedTypes.isEmpty || selectedTypes.contains(event.type);
    return matchesDate && matchesType;
  }).toList()..sort((a, b) => a.date.compareTo(b.date));
  return List<CalendarEvent>.unmodifiable(filtered);
}

/// EN: Applies only event-type filters to markers shown in the month grid.
/// KO: 월 그리드 마커에 이벤트 유형 필터만 적용합니다.
List<CalendarEvent> filterCalendarGridEvents(
  Iterable<CalendarEvent> events, {
  Set<CalendarEventType> selectedTypes = const {},
}) {
  return filterCalendarEvents(events, selectedTypes: selectedTypes);
}

/// EN: Groups events by normalized date and returns chronological groups.
/// KO: 이벤트를 정규화된 날짜로 묶어 시간순 그룹으로 반환합니다.
List<CalendarDateGroup> groupCalendarEvents(Iterable<CalendarEvent> events) {
  final grouped = <DateTime, List<CalendarEvent>>{};
  for (final event in events) {
    final local = event.date.toLocal();
    final key = DateTime(local.year, local.month, local.day);
    grouped.putIfAbsent(key, () => <CalendarEvent>[]).add(event);
  }
  final dates = grouped.keys.toList()..sort();
  return List<CalendarDateGroup>.unmodifiable(
    dates.map(
      (date) => CalendarDateGroup(
        date: date,
        events: List<CalendarEvent>.unmodifiable(grouped[date]!),
      ),
    ),
  );
}

/// EN: Date-only equality in the local calendar.
/// KO: 로컬 캘린더의 날짜 단위 동일성 비교입니다.
bool isSameCalendarDate(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
