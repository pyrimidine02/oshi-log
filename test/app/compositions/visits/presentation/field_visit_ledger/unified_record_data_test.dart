import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/app/compositions/visits/presentation/field_visit_ledger/field_visit_ledger_view_data.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/place/visits/domain/entities/visit_entities.dart';

void main() {
  test(
    'combines sources with namespaced IDs and deterministic newest order',
    () {
      final visit = FieldPlaceLedgerEntry(
        visit: VisitEvent(
          id: 'same',
          placeId: 'p',
          visitedAt: DateTime(2026, 10, 1),
        ),
      );
      final event = FieldEventLedgerEntry(
        record: LiveAttendanceHistoryRecord(
          projectKey: 'project',
          eventId: 'e',
          attendanceId: 'same',
          attended: true,
          status: 'DECLARED',
          canUndo: true,
          attendedAt: DateTime(2026, 10, 2),
        ),
        projectName: 'Project',
      );
      final records = composeUnifiedRecords(
        visits: [visit, visit],
        events: [event],
      );
      expect(records.map((item) => item.id), [
        'attendance:project:same',
        'visit:same',
      ]);
      expect(records.first.event?.isVerified, isFalse);
      expect(records.last.visit?.isGpsVerified, isFalse);
    },
  );
}
