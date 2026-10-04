import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';
import '../domain/private_trip.dart';

final tripPlacesProvider = FutureProvider.autoDispose
    .family<List<PlaceSummary>, String>((ref, project) async {
      final repository = await ref.watch(placesRepositoryProvider.future);
      return (await repository.getAllPlaces(projectId: project)).getOrThrow();
    });

/// EN: Read only after explicit import; never infer travel dates from check-ins.
/// KO: 명시적인 가져오기 후에만 조회하며 체크인으로 여행 날짜를 추정하지 않습니다.
final tripCandidatesProvider = FutureProvider.autoDispose
    .family<List<PrivateTrip>, String>((ref, project) async {
      ref.watch(authStateProvider);
      ref.watch(authTokenRefreshTickProvider);
      final placesFuture = ref.watch(tripPlacesProvider(project).future);
      final visitsRepo = await ref.watch(visitsRepositoryProvider.future);
      final liveRepo = await ref.watch(liveEventsRepositoryProvider.future);
      final visits = (await visitsRepo.getAllVisits()).getOrThrow();
      final places = {for (final p in await placesFuture) p.id: p};
      final entries = <PrivateTripEntry>[
        for (final visit in visits)
          if (places[visit.placeId] case final place?)
            PrivateTripEntry(
              id: 'visit:${visit.id}',
              resourceId: place.id,
              title: place.name,
              kind: TripEntryKind.place,
              projectKey: project,
              verified: visit.isVerified,
              place: place,
            ),
      ];
      var page = 0;
      while (true) {
        final result = (await liveRepo.getLiveAttendanceHistory(
          projectId: project,
          page: page,
          size: 100,
        )).getOrThrow();
        for (final record in result.items.where(
          (r) => r.attended && r.projectKey == project,
        )) {
          entries.add(
            PrivateTripEntry(
              id: 'live:${record.eventId}',
              resourceId: record.eventId,
              title: record.titleFallback,
              kind: TripEntryKind.live,
              projectKey: project,
              verified: record.isVerified,
              eventStart: record.showStartTime,
            ),
          );
        }
        if (!result.hasNext) break;
        page++;
      }
      return [
        for (final entry in entries)
          PrivateTrip(
            id: 'candidate:$project:${entry.id}',
            projectKey: project,
            title: entry.title,
            entries: [entry],
          ),
      ];
    });
