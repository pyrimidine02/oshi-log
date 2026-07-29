import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/visits/domain/entities/visit_entities.dart';
import 'package:oshi_log/features/visits/presentation/field_visit_ledger/field_visit_ledger_view_data.dart';

void main() {
  test('place ledger sorts newest first and reports factual totals', () {
    final data = FieldPlaceLedgerData.from(
      visits: [
        VisitEvent(
          id: 'older',
          placeId: 'place-a',
          visitedAt: DateTime.utc(2026, 6, 1),
        ),
        VisitEvent(
          id: 'newer',
          placeId: 'place-b',
          visitedAt: DateTime.utc(2026, 7, 15),
          status: VisitVerificationStatus.verified,
          distanceM: 4,
        ),
        VisitEvent(
          id: 'repeat',
          placeId: 'place-a',
          visitedAt: DateTime.utc(2026, 7, 2),
        ),
      ],
      places: const {
        'place-a': (
          place: PlaceSummary(
            id: 'place-a',
            name: 'Shimokitazawa Shelter',
            address: 'Tokyo',
            latitude: 0,
            longitude: 0,
          ),
          projectId: 'project-a',
          projectName: 'Project A',
        ),
        'place-b': (
          place: PlaceSummary(
            id: 'place-b',
            name: 'Club Citta',
            address: 'Kawasaki',
            latitude: 0,
            longitude: 0,
          ),
          projectId: 'project-b',
          projectName: 'Project B',
        ),
      },
    );

    expect(data.entries.map((entry) => entry.visit.id), [
      'newer',
      'repeat',
      'older',
    ]);
    expect(data.totalRecords, 3);
    expect(data.uniquePlaces, 2);
    expect(data.projectCount, 2);
    expect(data.entries.first.isGpsVerified, isTrue);
  });

  test('event ledger uses attendance date and project names', () {
    final data = FieldEventLedgerData.from(
      records: [
        LiveAttendanceHistoryRecord(
          projectKey: 'project-code',
          eventId: 'event-1',
          attended: true,
          status: LiveAttendanceStatus.verified,
          canUndo: false,
          attendedAt: DateTime.utc(2026, 7, 15),
          eventTitle: 'Field Notes Tour',
        ),
      ],
      projectNames: const {'project-code': 'Girls Band Cry'},
    );

    expect(data.entries.single.projectName, 'Girls Band Cry');
    expect(data.entries.single.recordedAt, DateTime.utc(2026, 7, 15));
    expect(data.verifiedRecords, 1);
    expect(data.projectCount, 1);
  });
}
