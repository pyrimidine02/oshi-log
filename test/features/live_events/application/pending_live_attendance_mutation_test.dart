import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/live_events/application/pending_live_attendance_mutation.dart';

void main() {
  test('PendingLiveAttendanceMutation parses json payload', () {
    final mutation = PendingLiveAttendanceMutation.fromJson({
      'projectKey': 'girls-band-cry',
      'eventId': 'event-1',
      'attended': true,
      'queuedAt': '2026-03-13T04:00:00.000Z',
    });

    expect(mutation.projectKey, 'girls-band-cry');
    expect(mutation.eventId, 'event-1');
    expect(mutation.attended, true);
    expect(mutation.toJson()['attended'], true);
  });

  test('PendingLiveAttendanceMutation falls back invalid timestamp', () {
    final mutation = PendingLiveAttendanceMutation.fromJson({
      'projectKey': 'girls-band-cry',
      'eventId': 'event-2',
      'attended': false,
      'queuedAt': 'invalid-datetime',
    });

    expect(mutation.queuedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });
}
