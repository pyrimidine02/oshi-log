import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/feed/application/travel_reviews_controller.dart';
import 'package:girlsbandtabi_app/features/live_events/domain/entities/live_event_entities.dart';
import 'package:girlsbandtabi_app/features/visits/domain/entities/visit_entities.dart';

void main() {
  test('uses only a VERIFIED attendance row as travel-review proof', () {
    final records = [
      const LiveAttendanceHistoryRecord(
        projectKey: 'bang-dream',
        attendanceId: 'declared-attendance',
        eventId: 'event-1',
        attended: true,
        status: LiveAttendanceStatus.declared,
        canUndo: true,
      ),
      const LiveAttendanceHistoryRecord(
        projectKey: 'bang-dream',
        attendanceId: 'verified-attendance',
        eventId: 'event-1',
        attended: true,
        status: LiveAttendanceStatus.verified,
        canUndo: false,
      ),
    ];

    expect(
      verifiedAttendanceProofId(records, 'event-1'),
      'verified-attendance',
    );
  });

  test('fails closed when VERIFIED row has no server attendance id', () {
    const records = [
      LiveAttendanceHistoryRecord(
        projectKey: 'bang-dream',
        eventId: 'event-1',
        attended: true,
        status: LiveAttendanceStatus.verified,
        canUndo: false,
      ),
    ];

    expect(verifiedAttendanceProofId(records, 'event-1'), isNull);
  });

  test('uses only VERIFIED visit status and ignores distance as proof', () {
    final visits = [
      VisitEvent(
        id: 'new-rejected',
        placeId: 'place-1',
        visitedAt: DateTime.utc(2026, 7, 16),
        status: 'REJECTED',
        distanceM: 1,
      ),
      VisitEvent(
        id: 'verified-without-distance',
        placeId: 'place-1',
        visitedAt: DateTime.utc(2026, 7, 15),
        status: VisitVerificationStatus.verified,
      ),
    ];

    expect(
      verifiedVisitProofId(visits, 'place-1'),
      'verified-without-distance',
    );
  });

  test('fails closed when legacy visit status is missing', () {
    final visits = [
      VisitEvent(
        id: 'legacy-distance-only',
        placeId: 'place-1',
        visitedAt: DateTime.utc(2026, 7, 16),
        distanceM: 1,
      ),
    ];

    expect(verifiedVisitProofId(visits, 'place-1'), isNull);
  });
}
