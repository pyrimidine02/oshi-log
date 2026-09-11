import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/home/application/home_controller.dart';
import 'package:oshi_log/features/home/domain/entities/home_summary.dart';
import 'package:oshi_log/features/home/domain/repositories/home_repository.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';

void main() {
  test(
    'a changed unit filter starts a distinct request and wins the race',
    () async {
      final repository = _ControlledHomeRepository();
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      final controller = container.read(homeControllerProvider.notifier);
      final firstLoad = controller.load();
      await _drainMicrotasks();
      expect(repository.requestKeys, ['project-id:']);

      container.read(selectedUnitIdsProvider.notifier).state = const ['unit-b'];
      await _drainMicrotasks();
      expect(repository.requestKeys, ['project-id:', 'project-id:unit-b']);

      repository.complete(
        'project-id:unit-b',
        Result.success(_summary('unit-b-summary')),
      );
      await _drainMicrotasks();
      expect(
        container.read(homeControllerProvider).valueOrNull?.recommendedPlaces,
        hasLength(1),
      );
      expect(
        container
            .read(homeControllerProvider)
            .valueOrNull
            ?.recommendedPlaces
            .single
            .id,
        'unit-b-summary',
      );

      repository.complete(
        'project-id:',
        Result.success(_summary('stale-project-summary')),
      );
      await firstLoad;
      await _drainMicrotasks();

      expect(
        container
            .read(homeControllerProvider)
            .valueOrNull
            ?.recommendedPlaces
            .single
            .id,
        'unit-b-summary',
      );

      // EN: Switching back must fetch the unfiltered snapshot; the stale
      // request above must not populate the project-only cache entry.
      // KO: 필터를 되돌리면 필터 없는 스냅샷을 다시 조회해야 하며, 위의
      // 오래된 요청이 프로젝트 전용 캐시를 오염시키면 안 됩니다.
      container.read(selectedUnitIdsProvider.notifier).state = const [];
      await _drainMicrotasks();
      expect(repository.requestKeys, [
        'project-id:',
        'project-id:unit-b',
        'project-id:',
      ]);
      repository.complete(
        'project-id:',
        Result.success(_summary('unfiltered-summary')),
      );
      await _drainMicrotasks();
      expect(
        container
            .read(homeControllerProvider)
            .valueOrNull
            ?.recommendedPlaces
            .single
            .id,
        'unfiltered-summary',
      );
    },
  );

  test(
    'repository initialization failure becomes retryable error state',
    () async {
      final repository = _ControlledHomeRepository(immediate: true);
      var shouldThrow = true;
      final container = _createContainer(
        repository,
        homeRepositoryOverride: (ref) async {
          if (shouldThrow) {
            shouldThrow = false;
            throw const UnknownFailure(
              'repository unavailable',
              code: 'repository_init_failed',
            );
          }
          return repository;
        },
      );
      addTearDown(container.dispose);

      final controller = container.read(homeControllerProvider.notifier);
      await controller.load();
      final failedState = container.read(homeControllerProvider);
      expect(failedState.hasError, isTrue);
      expect(failedState.error, isA<UnknownFailure>());

      container.invalidate(homeRepositoryProvider);
      await controller.load(forceRefresh: true);

      expect(container.read(homeControllerProvider).hasValue, isTrue);
      expect(
        container
            .read(homeControllerProvider)
            .valueOrNull
            ?.recommendedPlaces
            .single
            .id,
        'project-id:',
      );
    },
  );
}

ProviderContainer _createContainer(
  _ControlledHomeRepository repository, {
  Future<HomeRepository> Function(Ref ref)? homeRepositoryOverride,
}) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWith((ref) => true),
      selectedProjectKeyProvider.overrideWith((ref) => 'project'),
      selectedProjectIdProvider.overrideWith((ref) => 'project-id'),
      selectedUnitIdsProvider.overrideWith((ref) => const <String>[]),
      currentNavIndexProvider.overrideWith((ref) => 0),
      projectsControllerProvider.overrideWith(
        (ref) => ProjectsController(ref, loadOnCreate: false),
      ),
      homeRepositoryProvider.overrideWith(
        homeRepositoryOverride ?? (ref) async => repository,
      ),
    ],
  );
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

HomeSummary _summary(String id) {
  return HomeSummary(
    recommendedPlaces: [HomePlaceItem(id: id, name: id)],
    trendingLiveEvents: const [],
    latestNews: const [],
    metadata: const HomeSummaryMetadata(
      sourceCounts: HomeSourceCounts(places: 1, liveEvents: 0, news: 0),
      fallbackApplied: HomeFallbackApplied(
        recommendedPlaces: false,
        trendingLiveEvents: false,
      ),
    ),
  );
}

class _ControlledHomeRepository implements HomeRepository {
  _ControlledHomeRepository({this.immediate = false});

  final bool immediate;
  final List<String> requestKeys = [];
  final Map<String, Completer<Result<HomeSummary>>> _pending = {};

  @override
  Future<Result<List<HomeSummaryByProjectItem>>> getHomeSummariesByProject({
    List<String> projectIds = const [],
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    return const Result.success([]);
  }

  @override
  Future<Result<HomeSummary>> getHomeSummary({
    required String projectId,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) {
    final key = '$projectId:${unitIds.join(',')}';
    requestKeys.add(key);
    if (immediate) {
      return Future.value(Result.success(_summary(key)));
    }
    final completer = Completer<Result<HomeSummary>>();
    _pending[key] = completer;
    return completer.future;
  }

  void complete(String key, Result<HomeSummary> result) {
    final completer = _pending.remove(key);
    if (completer == null) {
      throw StateError('No pending home request for $key');
    }
    completer.complete(result);
  }
}
