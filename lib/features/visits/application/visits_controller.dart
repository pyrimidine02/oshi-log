/// EN: Visit history controllers and providers.
/// KO: 방문 기록 컨트롤러 및 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../projects/application/project_context.dart';
import '../../../core/utils/result.dart';
import '../../places/application/places_controller.dart';
import '../../places/domain/entities/place_entities.dart';
import '../../projects/application/projects_controller.dart';
import '../data/datasources/visits_remote_data_source.dart';
import '../data/repositories/visits_repository_impl.dart';
import '../domain/entities/visit_entities.dart';
import '../domain/repositories/visits_repository.dart';

/// EN: Controller for user visit history.
/// KO: 사용자 방문 기록 컨트롤러.
class UserVisitsController extends StateNotifier<AsyncValue<List<VisitEvent>>> {
  UserVisitsController(this._ref) : super(const AsyncLoading());

  final Ref _ref;

  /// EN: Load all visit events for the user.
  /// KO: 사용자의 전체 방문 이벤트를 로드합니다.
  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncLoading();

    final repository = await _ref.read(visitsRepositoryProvider.future);
    final result = await repository.getAllVisits(forceRefresh: forceRefresh);

    if (result is Success<List<VisitEvent>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<VisitEvent>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

/// EN: Visits repository provider.
/// KO: 방문 기록 리포지토리 프로바이더.
final visitsRepositoryProvider = FutureProvider<VisitsRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return VisitsRepositoryImpl(
    remoteDataSource: VisitsRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Visit history controller provider.
/// KO: 방문 기록 컨트롤러 프로바이더.
final userVisitsControllerProvider =
    StateNotifierProvider<UserVisitsController, AsyncValue<List<VisitEvent>>>(
      (ref) => UserVisitsController(ref),
    );

/// EN: Visit summary provider for a specific place.
/// KO: 특정 장소의 방문 요약 프로바이더.
final visitSummaryProvider = FutureProvider.autoDispose
    .family<VisitSummary?, String>((ref, placeId) async {
      if (placeId.isEmpty) return null;
      final repository = await ref.read(visitsRepositoryProvider.future);
      final result = await repository.getVisitSummary(placeId: placeId);
      if (result is Success<VisitSummary>) {
        return result.data;
      }
      return null;
    });

/// EN: Visit detail provider by visit ID.
/// KO: 방문 ID 기반 방문 상세 프로바이더.
final visitDetailProvider = FutureProvider.autoDispose
    .family<VisitEvent?, String>((ref, visitId) async {
      if (visitId.isEmpty) return null;
      final repository = await ref.read(visitsRepositoryProvider.future);
      final result = await repository.getVisitDetail(visitId: visitId);
      if (result is Success<VisitEvent>) {
        return result.data;
      }
      return null;
    });

/// EN: Map of place ID to summary for visit screens.
/// KO: 방문 화면에서 사용할 장소 요약 맵.
final visitPlacesMapProvider = FutureProvider<Map<String, PlaceSummary>>((
  ref,
) async {
  final projectKey = ref.watch(selectedProjectKeyProvider);
  final projectId = ref.watch(selectedProjectIdProvider);
  final resolvedProjectKey = projectKey?.isNotEmpty == true
      ? projectKey!
      : (projectId ?? '');
  if (resolvedProjectKey.isEmpty) return <String, PlaceSummary>{};

  final repository = await ref.read(placesRepositoryProvider.future);
  final result = await repository.getAllPlaces(projectId: resolvedProjectKey);
  if (result is Success<List<PlaceSummary>>) {
    return {for (final place in result.data) place.id: place};
  }

  return <String, PlaceSummary>{};
});

/// EN: Map from place ID to place summary + project metadata, spanning all
///     projects. Used to resolve project grouping in visit history.
///     Individual project fetch failures are silently ignored so a partial
///     result is still usable.
/// KO: 전체 프로젝트에 걸친 장소 ID → 장소 요약 + 프로젝트 메타데이터 맵.
///     방문 기록의 프로젝트별 그룹화에 사용됩니다.
///     개별 프로젝트 조회 실패는 무시되어 부분 결과를 계속 사용합니다.
final visitAllProjectsPlacesMapProvider =
    FutureProvider<
      Map<String, ({PlaceSummary place, String projectId, String projectName})>
    >((ref) async {
      final projects =
          ref.watch(projectsControllerProvider).valueOrNull ?? const [];
      if (projects.isEmpty) {
        return {};
      }
      final repository = await ref.read(placesRepositoryProvider.future);
      final result =
          <
            String,
            ({PlaceSummary place, String projectId, String projectName})
          >{};
      await Future.wait(
        projects.map((project) async {
          final key = project.code.isNotEmpty ? project.code : project.id;
          try {
            final res = await repository.getAllPlaces(projectId: key);
            if (res is Success<List<PlaceSummary>>) {
              for (final place in res.data) {
                result[place.id] = (
                  place: place,
                  projectId: project.id,
                  projectName: project.name,
                );
              }
            }
          } catch (_) {
            // EN: Ignore individual project failures; other projects still show.
            // KO: 개별 프로젝트 실패는 무시하고 나머지 프로젝트는 계속 표시합니다.
          }
        }),
      );
      return result;
    });

/// EN: User ranking provider for visit statistics.
/// KO: 방문 통계를 위한 사용자 랭킹 프로바이더.
final userRankingProvider = FutureProvider<UserRanking?>((ref) async {
  final projectKey = ref.watch(selectedProjectKeyProvider);
  final projectId = ref.watch(selectedProjectIdProvider);
  final resolvedProjectId = projectId?.isNotEmpty == true
      ? projectId!
      : (projectKey ?? '');
  if (resolvedProjectId.isEmpty) return null;

  final repository = await ref.read(visitsRepositoryProvider.future);
  final result = await repository.getUserRanking(projectId: resolvedProjectId);
  if (result is Success<UserRanking>) {
    return result.data;
  }
  return null;
});
