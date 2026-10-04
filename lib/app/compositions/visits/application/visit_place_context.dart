/// EN: App-level composition joining visit history with place lookups.
/// KO: 방문 기록과 장소 조회를 연결하는 app 레벨 조합.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/platform/utils/result.dart';

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
