/// EN: Home controller for loading home summary.
/// KO: 홈 요약을 로드하는 홈 컨트롤러.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/utils/result.dart';
import '../../projects/application/projects_controller.dart';
import '../../projects/domain/entities/project_entities.dart';
import '../domain/entities/home_summary.dart';
import '../domain/repositories/home_repository.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/repositories/home_repository_impl.dart';

// EN: Max number of additional retries on load failure.
// KO: 로드 실패 시 최대 추가 재시도 횟수.
const int _kMaxRetries = 2;
const Duration _kFailureCooldown = Duration(seconds: 8);
const int _kHomeNavIndex = 0;

class HomeController extends StateNotifier<AsyncValue<HomeSummary>> {
  HomeController(this._ref) : super(const AsyncLoading()) {
    _ref.listen<String?>(selectedProjectKeyProvider, (_, __) {
      _scheduleProjectSelectionReload();
    });
    _ref.listen<String?>(selectedProjectIdProvider, (_, __) {
      _scheduleProjectSelectionReload();
    });
    _ref.listen<List<String>>(selectedUnitIdsProvider, (_, __) {
      // EN: Re-fetch summary when unit filters change.
      // KO: 유닛 필터가 변경되면 홈 요약을 다시 조회합니다.
      if (!_isHomeTabActive()) {
        return;
      }
      load();
    });
    _ref.listen<int>(currentNavIndexProvider, (previous, next) {
      if (next != _kHomeNavIndex || next == previous) {
        return;
      }
      // EN: Refresh when entering Home branch to avoid stale/offscreen-only updates.
      // KO: 홈 브랜치 진입 시 새로고침해 오프스크린 상태 변경으로 인한 stale 데이터를 방지합니다.
      load(forceRefresh: true);
    });
  }

  final Ref _ref;
  String? _lastRequestKey;
  DateTime? _lastFailureAt;
  bool _isLoading = false;
  bool _projectSelectionReloadScheduled = false;
  int _requestSerial = 0;
  int _activeRequestSerial = 0;
  final Map<String, HomeSummary> _summaryMemoryCache = <String, HomeSummary>{};

  bool _isHomeTabActive() {
    return _ref.read(currentNavIndexProvider) == _kHomeNavIndex;
  }

  void _scheduleProjectSelectionReload() {
    if (!_isHomeTabActive() || _projectSelectionReloadScheduled) {
      return;
    }
    _projectSelectionReloadScheduled = true;
    Future<void>.microtask(() {
      _projectSelectionReloadScheduled = false;
      if (!mounted || !_isHomeTabActive()) {
        return;
      }

      final selectedProjectKey = _ref.read(selectedProjectKeyProvider);
      if (selectedProjectKey == null || selectedProjectKey.isEmpty) {
        return;
      }
      final selectedProjectId = _ref.read(selectedProjectIdProvider);
      final unitIds = List<String>.unmodifiable(
        _ref.read(selectedUnitIdsProvider),
      );
      final cached = _findCachedSummary(
        selectedProjectKey: selectedProjectKey,
        selectedProjectId: selectedProjectId,
        unitIds: unitIds,
      );
      if (cached != null) {
        // EN: Switch instantly with cached per-project summary.
        // KO: 프로젝트별 메모리 캐시로 즉시 전환합니다.
        state = AsyncData(cached);
      } else if (state.hasValue) {
        // EN: No cache hit for the new project — show loading explicitly.
        // KO: 신규 프로젝트 캐시가 없으면 로딩 상태를 명시적으로 노출합니다.
        state = const AsyncLoading();
      }
      unawaited(load());
    });
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!_ref.read(isAuthenticatedProvider)) {
      if (!state.hasValue) {
        state = AsyncError(
          const AuthFailure('Login required', code: 'auth_required'),
          StackTrace.current,
        );
      }
      return;
    }

    final selectedProjectKey = _ref.read(selectedProjectKeyProvider);
    if (selectedProjectKey == null || selectedProjectKey.isEmpty) {
      return;
    }
    final selectedProjectId = _ref.read(selectedProjectIdProvider);
    final selectedProjectIdentifier = _resolveProjectIdentifier(
      selectedProjectKey: selectedProjectKey,
      selectedProjectId: selectedProjectId,
    );

    final unitIds = List<String>.unmodifiable(
      _ref.read(selectedUnitIdsProvider),
    );
    final requestKey = '$selectedProjectIdentifier:${unitIds.join(',')}';
    final shouldSkip =
        !forceRefresh && _isLoading && _lastRequestKey == requestKey;
    if (shouldSkip) {
      return;
    }
    if (!forceRefresh &&
        _lastRequestKey == requestKey &&
        _lastFailureAt != null &&
        DateTime.now().difference(_lastFailureAt!) < _kFailureCooldown) {
      // EN: Prevent retry storms when backend keeps returning 5xx for the same query.
      // KO: 동일 쿼리에서 백엔드 5xx가 반복될 때 재시도 폭주를 방지합니다.
      return;
    }

    _lastRequestKey = requestKey;
    _isLoading = true;
    final requestSerial = ++_requestSerial;
    _activeRequestSerial = requestSerial;

    // EN: Keep previous data visible while loading (no full-screen spinner).
    // KO: 로딩 중 이전 데이터를 유지합니다 (전체 화면 스피너 없음).
    if (!state.hasValue) {
      state = const AsyncLoading();
    }

    final projectKey = selectedProjectKey;
    final projectId = selectedProjectId;

    try {
      // EN: Resolve the repository inside the guarded request so a failed
      // provider initialization cannot leave the spinner stuck forever.
      // KO: 리포지토리 프로바이더 초기화도 보호된 요청 안에서 수행해
      // 초기화 실패로 스피너가 영원히 남지 않도록 합니다.
      final repository = await _ref.read(homeRepositoryProvider.future);
      if (!mounted || requestSerial != _activeRequestSerial) return;

      // EN: Retry only retryable failures (network/temporary server failures).
      // EN: Do not retry persistent 5xx such as 500 to avoid noisy loops.
      // KO: 재시도 가능한 실패(네트워크/일시적 서버 장애)만 재시도합니다.
      // KO: 500 같은 지속적 5xx는 재시도하지 않아 불필요한 루프를 막습니다.
      Result<HomeSummary>? result;
      for (var attempt = 0; attempt <= _kMaxRetries; attempt++) {
        if (requestSerial != _activeRequestSerial) {
          return;
        }
        if (attempt > 0) {
          await Future<void>.delayed(Duration(seconds: attempt));
          if (!mounted || requestSerial != _activeRequestSerial) return;
          AppLogger.info(
            'Retrying home summary load (attempt $attempt)',
            tag: 'HomeController',
          );
        }
        result = await _loadSummaryPreferByProject(
          repository: repository,
          selectedProjectKey: projectKey,
          selectedProjectId: projectId,
          unitIds: unitIds,
          forceRefresh: forceRefresh || attempt > 0,
        );
        if (!mounted || requestSerial != _activeRequestSerial) return;
        if (result is Success<HomeSummary>) {
          _lastFailureAt = null;
          _cacheSummaryForProject(
            selectedProjectKey: selectedProjectKey,
            selectedProjectId: selectedProjectId,
            unitIds: unitIds,
            summary: result.data,
          );
          break;
        }
        if (result is Err<HomeSummary>) {
          final failure = result.failure;
          _lastFailureAt = DateTime.now();
          final canRetry = _isRetryableFailure(failure);
          if (!canRetry || attempt >= _kMaxRetries) {
            break;
          }
        }
      }

      if (!mounted || requestSerial != _activeRequestSerial) return;
      if (result is Success<HomeSummary>) {
        AppLogger.debug(
          'Home sourceCounts loaded',
          tag: 'HomeController',
          data: {
            'project': selectedProjectIdentifier,
            'sourceCounts': {
              'places': result.data.metadata.sourceCounts.places,
              'liveEvents': result.data.metadata.sourceCounts.liveEvents,
              'news': result.data.metadata.sourceCounts.news,
            },
            'fallbackApplied': {
              'recommendedPlaces':
                  result.data.metadata.fallbackApplied.recommendedPlaces,
              'trendingLiveEvents':
                  result.data.metadata.fallbackApplied.trendingLiveEvents,
            },
          },
        );
        state = AsyncData(result.data);
      } else if (result is Err<HomeSummary>) {
        _handleUnauthorizedFailure(result.failure);
        state = AsyncError(result.failure, StackTrace.current);
      }
    } catch (error, stackTrace) {
      if (!mounted || requestSerial != _activeRequestSerial) return;
      // EN: Surface unexpected provider/repository exceptions as an error
      // state so callers can retry instead of observing a permanent loading
      // state.
      // KO: 예기치 않은 프로바이더/리포지토리 예외를 오류 상태로 노출해
      // 영구 로딩 대신 호출자가 다시 시도할 수 있도록 합니다.
      _lastFailureAt = DateTime.now();
      state = AsyncError(error, stackTrace);
    } finally {
      if (_activeRequestSerial == requestSerial) {
        _isLoading = false;
      }
    }
  }

  Future<Result<HomeSummary>> _loadSummaryPreferByProject({
    required HomeRepository repository,
    required String selectedProjectKey,
    required String? selectedProjectId,
    required List<String> unitIds,
    required bool forceRefresh,
  }) async {
    final projects = _ref.read(projectsControllerProvider).valueOrNull;
    if (projects != null && projects.isNotEmpty) {
      final projectIds = _projectIdentifiers(projects);
      final batchResult = await repository.getHomeSummariesByProject(
        projectIds: projectIds,
        unitIds: unitIds,
        forceRefresh: forceRefresh,
      );
      if (batchResult is Success<List<HomeSummaryByProjectItem>>) {
        final summary = _selectSummaryFromBatch(
          items: batchResult.data,
          selectedProjectKey: selectedProjectKey,
          selectedProjectId: selectedProjectId,
        );
        if (summary != null) {
          return Result.success(summary);
        }
      } else if (batchResult case Err<List<HomeSummaryByProjectItem>>(
        :final failure,
      )) {
        if (_isUnauthorizedFailure(failure)) {
          return Result.failure(failure);
        }
        AppLogger.warning(
          'Home by-project load failed, fallback to single summary',
          tag: 'HomeController',
          data: {
            'projectKey': selectedProjectKey,
            'projectId': selectedProjectId,
            'errorCode': failure.code,
          },
        );
      }
    }

    final projectIdentifier =
        (selectedProjectId != null && selectedProjectId.isNotEmpty)
        ? selectedProjectId
        : selectedProjectKey;

    return repository.getHomeSummary(
      projectId: projectIdentifier,
      unitIds: unitIds,
      forceRefresh: forceRefresh,
    );
  }

  String _resolveProjectIdentifier({
    required String selectedProjectKey,
    required String? selectedProjectId,
  }) {
    final projects = _ref.read(projectsControllerProvider).valueOrNull;
    if (projects != null && projects.isNotEmpty) {
      for (final project in projects) {
        if (project.code == selectedProjectKey ||
            project.id == selectedProjectKey) {
          if (project.id.isNotEmpty) {
            return project.id;
          }
          break;
        }
      }
    }

    if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
      return selectedProjectId;
    }
    return selectedProjectKey;
  }

  void _cacheSummaryForProject({
    required String selectedProjectKey,
    required String? selectedProjectId,
    required List<String> unitIds,
    required HomeSummary summary,
  }) {
    final projectKey = selectedProjectKey.trim();
    if (projectKey.isNotEmpty) {
      _summaryMemoryCache[_cacheKey(projectKey, unitIds)] = summary;
    }

    final projectId = selectedProjectId?.trim();
    if (projectId != null && projectId.isNotEmpty) {
      _summaryMemoryCache[_cacheKey(projectId, unitIds)] = summary;
    }
  }

  HomeSummary? _findCachedSummary({
    required String selectedProjectKey,
    required String? selectedProjectId,
    required List<String> unitIds,
  }) {
    final projectId = selectedProjectId?.trim();
    if (projectId != null && projectId.isNotEmpty) {
      final byId = _summaryMemoryCache[_cacheKey(projectId, unitIds)];
      if (byId != null) {
        return byId;
      }
    }

    final projectKey = selectedProjectKey.trim();
    if (projectKey.isEmpty) {
      return null;
    }
    return _summaryMemoryCache[_cacheKey(projectKey, unitIds)];
  }

  String _cacheKey(String value, List<String> unitIds) {
    final normalizedUnits = unitIds
        .map((unitId) => unitId.trim().toLowerCase())
        .where((unitId) => unitId.isNotEmpty)
        .join(',');
    return '${value.toLowerCase()}|units:$normalizedUnits';
  }

  List<String> _projectIdentifiers(List<Project> projects) {
    final seen = <String>{};
    final projectIds = <String>[];
    for (final project in projects) {
      final candidate = project.id.isNotEmpty ? project.id : project.code;
      if (candidate.isEmpty || seen.contains(candidate)) {
        continue;
      }
      seen.add(candidate);
      projectIds.add(candidate);
    }
    return projectIds;
  }

  HomeSummary? _selectSummaryFromBatch({
    required List<HomeSummaryByProjectItem> items,
    required String selectedProjectKey,
    required String? selectedProjectId,
  }) {
    if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
      for (final item in items) {
        if (item.matchesProject(selectedProjectId)) {
          return item.summary;
        }
      }
    }

    for (final item in items) {
      if (item.matchesProject(selectedProjectKey)) {
        return item.summary;
      }
    }

    if (items.isNotEmpty) {
      AppLogger.warning(
        'Selected project not found in by-project summary payload',
        tag: 'HomeController',
        data: {
          'selectedProjectKey': selectedProjectKey,
          'selectedProjectId': selectedProjectId,
          'payloadProjects': items
              .map((item) => '${item.projectCode}/${item.projectId}')
              .toList(growable: false),
        },
      );
    }
    return null;
  }

  bool _isRetryableFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return true;
    }
    if (failure is ServerFailure) {
      return switch (failure.code) {
        '429' => true,
        '502' => true,
        '503' => true,
        _ => false,
      };
    }
    return false;
  }

  bool _isUnauthorizedFailure(Failure failure) {
    if (failure is! AuthFailure) {
      return false;
    }
    final code = failure.code?.trim().toLowerCase();
    return code == '401' || code == 'auth_required';
  }

  void _handleUnauthorizedFailure(Failure failure) {
    if (!_isUnauthorizedFailure(failure)) {
      return;
    }
    _ref.read(authStateProvider.notifier).setUnauthenticated();
  }
}

/// EN: Home repository provider.
/// KO: 홈 리포지토리 프로바이더.
final homeRepositoryProvider = FutureProvider<HomeRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return HomeRepositoryImpl(
    remoteDataSource: HomeRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Home controller provider.
/// KO: 홈 컨트롤러 프로바이더.
final homeControllerProvider =
    StateNotifierProvider<HomeController, AsyncValue<HomeSummary>>((ref) {
      // EN: Don't call load() here — selectedProjectKey is always null at
      // construction time. The listener triggers load() once project is selected.
      // KO: 여기서 load() 호출 불필요 — 생성 시점에 selectedProjectKey는 항상 null.
      // 리스너가 프로젝트 선택 후 load()를 트리거함.
      return HomeController(ref);
    });
