import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/live_events/domain/entities/live_event_entities.dart';

void main() {
  group('LiveAttendanceHistoryRecord', () {
    test('fromState maps attendance fields', () {
      final state = LiveAttendanceState(
        attendanceId: 'attendance-1',
        liveEventId: 'event-1',
        attended: true,
        status: LiveAttendanceStatus.declared,
        canUndo: true,
        verificationMethod: 'SELF_DECLARED',
        attendedAt: DateTime.parse('2026-03-08T08:00:00Z'),
      );

      final record = LiveAttendanceHistoryRecord.fromState(
        projectKey: 'girls-band-cry',
        state: state,
      );

      expect(record.projectKey, 'girls-band-cry');
      expect(record.attendanceId, 'attendance-1');
      expect(record.eventId, 'event-1');
      expect(record.attended, isTrue);
      expect(record.isDeclared, isTrue);
      expect(record.canUndo, isTrue);
      expect(record.verificationMethod, 'SELF_DECLARED');
      expect(record.attendedAt, DateTime.parse('2026-03-08T08:00:00Z'));
      expect(record.eventTitle, isNull);
    });

    test('titleFallback uses event title when present', () {
      final record = LiveAttendanceHistoryRecord(
        projectKey: 'girls-band-cry',
        eventId: 'event-2',
        attended: true,
        status: LiveAttendanceStatus.verified,
        canUndo: false,
        eventTitle: 'DIAMOND DUST LIVE',
      );

      expect(record.titleFallback, 'DIAMOND DUST LIVE');
    });

    test('titleFallback falls back to event id when title is missing', () {
      final record = LiveAttendanceHistoryRecord(
        projectKey: 'girls-band-cry',
        eventId: 'event-3',
        attended: true,
        status: LiveAttendanceStatus.declared,
        canUndo: true,
      );

      expect(record.titleFallback, 'event-3');
    });

    test('withDetail fills event snapshot fields', () {
      final base = LiveAttendanceHistoryRecord(
        projectKey: 'girls-band-cry',
        eventId: 'event-4',
        attended: true,
        status: LiveAttendanceStatus.verified,
        canUndo: false,
      );

      final detail = LiveEventDetail(
        id: 'event-4',
        title: 'TOGENASHI LIVE',
        showStartTime: DateTime.parse('2026-04-01T09:00:00Z'),
        status: 'SCHEDULED',
        projectIds: const ['project-1'],
        unitIds: const ['unit-1'],
        bannerUrl: 'https://example.com/poster.jpg',
      );

      final patched = base.withDetail(detail);
      expect(patched.eventTitle, 'TOGENASHI LIVE');
      expect(patched.bannerUrl, 'https://example.com/poster.jpg');
      expect(patched.showStartTime, DateTime.parse('2026-04-01T09:00:00Z'));
    });
  });
}
