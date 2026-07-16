import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';
import 'package:girlsbandtabi_app/features/visits/domain/entities/visit_entities.dart';
import 'package:girlsbandtabi_app/features/visits/presentation/field_visit_ledger/field_visit_ledger_navigation.dart';
import 'package:girlsbandtabi_app/features/visits/presentation/field_visit_ledger/field_visit_ledger_view_data.dart';

void main() {
  test('selects the visit project before opening detail', () async {
    final order = <String>[];

    final result = await openFieldVisitLedgerEntry(
      entry: _resolvedEntry,
      projects: _projects,
      selectedProjectKey: 'other',
      selectedProjectId: 'other-id',
      selectProject: (projectKey, projectId) async {
        order.add('select:$projectKey:$projectId');
      },
      navigate: () => order.add('navigate'),
    );

    expect(result, FieldVisitNavigationResult.opened);
    expect(order, ['select:gbc:project-1', 'navigate']);
  });

  test('does not navigate when a visit has no project context', () async {
    var navigated = false;

    final result = await openFieldVisitLedgerEntry(
      entry: FieldPlaceLedgerEntry(
        visit: VisitEvent(
          id: 'visit-orphan',
          placeId: 'place-orphan',
          visitedAt: DateTime.utc(2026, 7, 15),
        ),
      ),
      projects: _projects,
      selectedProjectKey: 'other',
      selectedProjectId: 'other-id',
      selectProject: (_, __) async {},
      navigate: () => navigated = true,
    );

    expect(result, FieldVisitNavigationResult.missingProjectContext);
    expect(navigated, isFalse);
  });
}

const _projects = [
  Project(
    id: 'project-1',
    code: 'gbc',
    name: 'Girls Band Cry',
    status: 'active',
    defaultTimezone: 'Asia/Tokyo',
  ),
];

final _resolvedEntry = FieldPlaceLedgerEntry(
  visit: VisitEvent(
    id: 'visit-1',
    placeId: 'place-1',
    visitedAt: DateTime.utc(2026, 7, 15),
  ),
  metadata: const (
    place: PlaceSummary(
      id: 'place-1',
      name: 'Club Citta',
      address: 'Kawasaki',
      latitude: 0,
      longitude: 0,
    ),
    projectId: 'project-1',
    projectName: 'Girls Band Cry',
  ),
);
