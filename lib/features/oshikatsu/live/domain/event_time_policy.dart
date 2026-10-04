/// EN: Shared Japanese event clock; unknown end times never imply live status.
/// KO: 일본 공연 공통 시간 정책. 종료 미정이면 진행 상태를 추정하지 않습니다.
library;

enum EventPhase { before, today, after }

enum EventTimeStatus { upcoming, today, ongoing, ended, past }

abstract final class EventTimePolicy {
  static const jstOffset = Duration(hours: 9);

  /// EN: UTC-backed wall-clock value for formatting only, not instant comparison.
  /// KO: 표시용 UTC 기반 JST 시각이며 실제 시각 비교에는 사용하지 않습니다.
  static DateTime inJst(DateTime value) => value.toUtc().add(jstOffset);

  static DateTime dateInJst(DateTime value) {
    final date = inJst(value);
    return DateTime.utc(date.year, date.month, date.day);
  }

  static DateTime effectiveEnd({required DateTime start, DateTime? end}) {
    if (end != null && end.isAfter(start)) return end;
    return dateInJst(start).add(const Duration(days: 1)).subtract(jstOffset);
  }

  static bool isActive({
    required DateTime start,
    DateTime? end,
    required DateTime now,
  }) => now.isBefore(effectiveEnd(start: start, end: end));

  static bool isDisplayableToday({
    required DateTime start,
    DateTime? end,
    required DateTime now,
  }) =>
      (dateInJst(start) == dateInJst(now) || !now.isBefore(start)) &&
      isActive(start: start, end: end, now: now);

  static EventPhase phase({
    required DateTime start,
    DateTime? end,
    required DateTime now,
  }) {
    if (!isActive(start: start, end: end, now: now)) return EventPhase.after;
    if (isDisplayableToday(start: start, end: end, now: now)) {
      return EventPhase.today;
    }
    return EventPhase.before;
  }

  static EventTimeStatus status({
    required DateTime start,
    DateTime? end,
    required DateTime now,
  }) {
    final hasEnd = end != null && end.isAfter(start);
    if (!isActive(start: start, end: end, now: now)) {
      return hasEnd ? EventTimeStatus.ended : EventTimeStatus.past;
    }
    if (now.isBefore(start)) {
      return dateInJst(start) == dateInJst(now)
          ? EventTimeStatus.today
          : EventTimeStatus.upcoming;
    }
    return hasEnd ? EventTimeStatus.ongoing : EventTimeStatus.today;
  }
}
