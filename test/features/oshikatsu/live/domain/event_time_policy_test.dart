import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/event_time_policy.dart';

void main() {
  final start = DateTime.parse('2026-10-04T09:00:00Z');
  test(
    'unknown end remains visible through JST day, without ongoing claim',
    () {
      final now = DateTime.parse('2026-10-04T14:59:59Z');
      expect(
        EventTimePolicy.isDisplayableToday(start: start, now: now),
        isTrue,
      );
      expect(
        EventTimePolicy.status(start: start, now: now),
        EventTimeStatus.today,
      );
      expect(
        EventTimePolicy.isActive(
          start: start,
          now: DateTime.parse('2026-10-04T15:00:00Z'),
        ),
        isFalse,
      );
    },
  );
  test('known end is exclusive and malformed end stays unknown', () {
    final end = start.add(const Duration(hours: 2));
    expect(
      EventTimePolicy.status(start: start, end: end, now: start),
      EventTimeStatus.ongoing,
    );
    expect(
      EventTimePolicy.phase(start: start, end: end, now: end),
      EventPhase.after,
    );
    expect(
      EventTimePolicy.effectiveEnd(
        start: start,
        end: start.subtract(const Duration(hours: 1)),
      ),
      DateTime.parse('2026-10-04T15:00:00Z'),
    );
  });
  test('JST grouping crosses UTC month and date boundaries', () {
    expect(
      EventTimePolicy.dateInJst(DateTime.parse('2026-09-30T16:00:00Z')),
      DateTime.utc(2026, 10, 1),
    );
    expect(
      EventTimePolicy.phase(
        start: start,
        now: DateTime.parse('2026-10-03T15:00:00Z'),
      ),
      EventPhase.today,
    );
  });
  test(
    'known overnight performance stays in today preparation after midnight',
    () {
      final overnightStart = DateTime.parse('2026-10-04T14:00:00Z');
      final end = DateTime.parse('2026-10-04T17:00:00Z');
      final now = DateTime.parse('2026-10-04T15:30:00Z');
      expect(
        EventTimePolicy.phase(start: overnightStart, end: end, now: now),
        EventPhase.today,
      );
      expect(
        EventTimePolicy.isDisplayableToday(
          start: overnightStart,
          end: end,
          now: now,
        ),
        isTrue,
      );
      expect(
        EventTimePolicy.phase(start: overnightStart, now: now),
        EventPhase.after,
      );
    },
  );
}
