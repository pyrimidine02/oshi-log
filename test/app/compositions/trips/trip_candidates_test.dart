import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/app/compositions/trips/application/trip_candidates.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/repositories/live_events_repository.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';
import 'package:oshi_log/features/place/visits/domain/entities/visit_entities.dart';
import 'package:oshi_log/features/place/visits/domain/repositories/visits_repository.dart';

void main() {
  test(
    'imports only project places and paginates attendance without inventing travel dates',
    () async {
      final live = _LiveRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => AuthStateNotifier(SecureStorage())..setAuthenticated(),
          ),
          tripPlacesProvider('project').overrideWith(
            (ref) async => [
              const PlaceSummary(
                id: 'place',
                name: 'Place',
                address: 'Tokyo',
                latitude: 35,
                longitude: 139,
              ),
            ],
          ),
          visitsRepositoryProvider.overrideWith(
            (ref) async => _VisitsRepository(),
          ),
          liveEventsRepositoryProvider.overrideWith((ref) async => live),
        ],
      );
      addTearDown(container.dispose);
      final candidates = await container.read(
        tripCandidatesProvider('project').future,
      );
      expect(candidates, hasLength(3));
      expect(candidates.expand((t) => t.entries).map((e) => e.resourceId), [
        'place',
        'event-0',
        'event-1',
      ]);
      expect(
        candidates.every((t) => t.startedOn == null && !t.datesConfirmed),
        isTrue,
      );
      expect(candidates.first.entries.single.verified, isTrue);
      expect(candidates[1].entries.single.verified, isFalse);
      expect(candidates[1].entries.single.event, isNull);
      expect(candidates[2].entries.single.verified, isTrue);
      expect(live.pages, [0, 1]);
    },
  );
}

class _VisitsRepository implements VisitsRepository {
  @override
  Future<Result<List<VisitEvent>>> getAllVisits({
    int pageSize = 50,
    bool forceRefresh = false,
  }) async => Success([
    VisitEvent(
      id: 'one',
      placeId: 'place',
      visitedAt: DateTime(2026, 10, 1, 22),
      status: 'VERIFIED',
    ),
    VisitEvent(
      id: 'other',
      placeId: 'other-project-place',
      visitedAt: DateTime(2026, 10, 1, 22),
    ),
  ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LiveRepository implements LiveEventsRepository {
  final pages = <int>[];
  @override
  Future<Result<LiveAttendanceHistoryPageData>> getLiveAttendanceHistory({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    pages.add(page);
    return Success(
      LiveAttendanceHistoryPageData(
        currentPage: page,
        pageSize: 1,
        hasNext: page == 0,
        items: [
          LiveAttendanceHistoryRecord(
            projectKey: projectId,
            eventId: 'event-$page',
            attended: true,
            status: page == 0 ? 'DECLARED' : 'VERIFIED',
            canUndo: true,
            attendedAt: DateTime(2026, 10, 1),
            showStartTime: page == 0 ? null : DateTime(2026, 10, 1, 18),
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
