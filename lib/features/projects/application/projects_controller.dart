/// EN: Projects controllers for list, units, and selection.
/// KO: 프로젝트/유닛/선택 컨트롤러.
library;

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/projects_remote_data_source.dart';
import '../data/repositories/projects_repository_impl.dart';
import '../domain/entities/project_entities.dart';
import '../domain/repositories/projects_repository.dart';

class ProjectsController extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectsController(this._ref) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }
    state = const AsyncLoading();
    final repository = await _ref.read(projectsRepositoryProvider.future);
    if (!mounted) {
      return;
    }
    final result = await repository.getProjects(forceRefresh: forceRefresh);
    if (!mounted) {
      return;
    }

    if (result is Success<List<Project>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<Project>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

class ProjectUnitsController extends StateNotifier<AsyncValue<List<Unit>>> {
  ProjectUnitsController(this._ref, this.projectKey)
    : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String projectKey;

  Future<void> load({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }
    state = const AsyncLoading();
    final repository = await _ref.read(projectsRepositoryProvider.future);
    if (!mounted) {
      return;
    }
    final result = await repository.getUnits(
      projectId: projectKey,
      forceRefresh: forceRefresh,
    );
    if (!mounted) {
      return;
    }

    if (result is Success<List<Unit>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<Unit>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

class ProjectSelectionController extends StateNotifier<ProjectSelectionState> {
  ProjectSelectionController(this._ref)
    : super(ProjectSelectionState.initial()) {
    unawaited(_initialize());
  }

  final Ref _ref;
  int _userSelectionGeneration = 0;
  Future<void> _persistenceTail = Future<void>.value();

  Future<void> _initialize() async {
    final initializationGeneration = _userSelectionGeneration;
    try {
      await _restoreSelection(initializationGeneration);
    } catch (error, stackTrace) {
      if (!_ownsSelection(initializationGeneration)) {
        return;
      }
      AppLogger.error(
        'Failed to restore project selection',
        error: error,
        stackTrace: stackTrace,
        tag: 'ProjectSelectionController',
      );
    }
  }

  Future<void> _restoreSelection(int initializationGeneration) async {
    final storage = await _ref.read(localStorageProvider.future);
    if (!_ownsSelection(initializationGeneration)) {
      return;
    }
    final storedProjectKey = storage.getSelectedProjectKey();
    final storedProjectId = storage.getSelectedProjectId();
    final storedUnitIds = List<String>.unmodifiable(
      storage.getSelectedUnitIds(),
    );
    final hasStoredProjectKey =
        storedProjectKey != null && storedProjectKey.isNotEmpty;
    final hasStoredProjectId =
        storedProjectId != null && storedProjectId.isNotEmpty;
    List<Project>? projects;

    if (hasStoredProjectKey || hasStoredProjectId) {
      projects = await _fetchProjects();
      if (!_ownsSelection(initializationGeneration)) {
        return;
      }
      final match = _findProject(projects, storedProjectKey, storedProjectId);
      if (match != null) {
        final resolvedProjectKey = _projectKeyFor(match);
        // EN: Use stored selection. Update state + providers first, persist in
        // parallel so the home controller can start loading immediately.
        // KO: 저장된 선택 사용. state + 프로바이더를 먼저 업데이트하고, 홈
        // 컨트롤러가 즉시 로드할 수 있도록 저장은 병렬 수행.
        _applySelection(
          projectKey: resolvedProjectKey,
          projectId: match.id,
          unitIds: storedUnitIds,
        );
        await _queuePersistence(
          _SelectionPersistence.project(
            generation: initializationGeneration,
            projectKey: resolvedProjectKey,
            projectId: match.id,
            unitIds: storedUnitIds,
          ),
        );
        return;
      }
    }

    // EN: No stored project — fetch from API and auto-select first.
    // KO: 저장된 프로젝트 없음 — API에서 조회 후 첫 번째를 자동 선택합니다.
    projects ??= await _fetchProjects();
    if (!_ownsSelection(initializationGeneration)) {
      return;
    }
    if (projects.isNotEmpty) {
      final project = projects.first;
      final projectKey = _projectKeyFor(project);
      _applySelection(
        projectKey: projectKey,
        projectId: project.id,
        unitIds: const [],
      );
      await _queuePersistence(
        _SelectionPersistence.project(
          generation: initializationGeneration,
          projectKey: projectKey,
          projectId: project.id,
          unitIds: const [],
        ),
      );
    }
  }

  Future<List<Project>> _fetchProjects() async {
    final repository = await _ref.read(projectsRepositoryProvider.future);
    final result = await repository.getProjects();
    if (result is! Success<List<Project>> || result.data.isEmpty) {
      return <Project>[];
    }

    return result.data;
  }

  Future<void> selectProject(String? projectKey, {String? projectId}) async {
    final generation = ++_userSelectionGeneration;
    final normalizedProjectKey = _nonEmptyOrNull(projectKey);
    final normalizedProjectId = _nonEmptyOrNull(projectId);
    // EN: Update state + providers immediately, persist in parallel.
    // KO: state + 프로바이더를 즉시 업데이트하고, 저장은 병렬 수행.
    _applySelection(
      projectKey: normalizedProjectKey,
      projectId: normalizedProjectId,
      unitIds: const [],
    );
    await _queuePersistence(
      _SelectionPersistence.project(
        generation: generation,
        projectKey: normalizedProjectKey ?? '',
        projectId: normalizedProjectId ?? '',
        unitIds: const [],
      ),
    );
  }

  Future<void> selectUnits(List<String> unitIds) async {
    final generation = _userSelectionGeneration;
    final immutableUnitIds = List<String>.unmodifiable(unitIds);
    if (!_ownsSelection(generation)) {
      return;
    }
    state = state.copyWith(unitIds: immutableUnitIds);
    _setSelectedUnitIdsIfChanged(immutableUnitIds);
    await _queuePersistence(
      _SelectionPersistence.units(
        generation: generation,
        unitIds: immutableUnitIds,
      ),
    );
  }

  bool _ownsSelection(int generation) {
    // EN: Async initialization may only publish while no newer user choice
    // owns the controller.
    // KO: 비동기 초기화는 더 최신 사용자 선택이 컨트롤러 소유권을 가져가지
    // 않았을 때만 결과를 반영합니다.
    return mounted && generation == _userSelectionGeneration;
  }

  void _applySelection({
    required String? projectKey,
    required String? projectId,
    required List<String> unitIds,
  }) {
    final immutableUnitIds = List<String>.unmodifiable(unitIds);
    state = ProjectSelectionState(
      projectKey: projectKey,
      unitIds: immutableUnitIds,
    );
    _setSelectedProjectKey(projectKey);
    _setSelectedProjectId(projectId);
    _setSelectedUnitIdsIfChanged(immutableUnitIds);
  }

  Future<void> _queuePersistence(_SelectionPersistence persistence) {
    // EN: Serialize writes so an in-flight older write always finishes before
    // the latest selection, while queued obsolete generations are discarded.
    // KO: 진행 중인 이전 저장이 최신 선택보다 먼저 끝나도록 직렬화하고,
    // 대기 중인 오래된 세대의 저장은 폐기합니다.
    final operation = _persistenceTail.then((_) async {
      if (!_ownsSelection(persistence.generation)) {
        return;
      }
      final storage = await _ref.read(localStorageProvider.future);
      if (!_ownsSelection(persistence.generation)) {
        return;
      }

      await Future.wait([
        if (persistence.includesProject)
          storage.setSelectedProjectKey(persistence.projectKey),
        if (persistence.includesProject)
          storage.setSelectedProjectId(persistence.projectId),
        storage.setSelectedUnitIds(persistence.unitIds),
      ]);
    });
    final recovered = _recoverPersistence(operation);
    _persistenceTail = recovered;
    return recovered;
  }

  Future<void> _recoverPersistence(Future<void> operation) async {
    try {
      await operation;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to persist project selection',
        error: error,
        stackTrace: stackTrace,
        tag: 'ProjectSelectionController',
      );
    }
  }

  void _setSelectedProjectKey(String? projectKey) {
    // EN: Keep provider updates minimal to avoid duplicate reloads.
    // KO: 중복 로드를 피하기 위해 프로바이더 업데이트를 최소화합니다.
    final current = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) {
      if (current != null) {
        _ref.read(selectedProjectKeyProvider.notifier).state = null;
      }
      return;
    }

    if (current != projectKey) {
      _ref.read(selectedProjectKeyProvider.notifier).state = projectKey;
    }
  }

  void _setSelectedProjectId(String? projectId) {
    // EN: Keep provider updates minimal to avoid duplicate reloads.
    // KO: 중복 로드를 피하기 위해 프로바이더 업데이트를 최소화합니다.
    final current = _ref.read(selectedProjectIdProvider);
    if (projectId == null || projectId.isEmpty) {
      if (current != null) {
        _ref.read(selectedProjectIdProvider.notifier).state = null;
      }
      return;
    }

    if (current != projectId) {
      _ref.read(selectedProjectIdProvider.notifier).state = projectId;
    }
  }

  void _setSelectedUnitIdsIfChanged(List<String> unitIds) {
    // EN: Avoid emitting identical unit lists to prevent duplicate fetches.
    // KO: 동일한 유닛 리스트 방출을 막아 중복 호출을 방지합니다.
    final current = _ref.read(selectedUnitIdsProvider);
    if (!listEquals(current, unitIds)) {
      _ref.read(selectedUnitIdsProvider.notifier).state =
          List<String>.unmodifiable(unitIds);
    }
  }
}

class _SelectionPersistence {
  const _SelectionPersistence.project({
    required this.generation,
    required this.projectKey,
    required this.projectId,
    required this.unitIds,
  }) : includesProject = true;

  const _SelectionPersistence.units({
    required this.generation,
    required this.unitIds,
  }) : includesProject = false,
       projectKey = '',
       projectId = '';

  final int generation;
  final bool includesProject;
  final String projectKey;
  final String projectId;
  final List<String> unitIds;
}

String? _nonEmptyOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

/// EN: Projects repository provider.
/// KO: 프로젝트 리포지토리 프로바이더.
final projectsRepositoryProvider = FutureProvider<ProjectsRepository>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return ProjectsRepositoryImpl(
    remoteDataSource: ProjectsRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Projects controller provider.
/// KO: 프로젝트 목록 컨트롤러 프로바이더.
final projectsControllerProvider =
    StateNotifierProvider<ProjectsController, AsyncValue<List<Project>>>((ref) {
      return ProjectsController(ref);
    });

/// EN: Project units controller provider.
/// KO: 프로젝트 유닛 컨트롤러 프로바이더.
final projectUnitsControllerProvider = StateNotifierProvider.autoDispose
    .family<ProjectUnitsController, AsyncValue<List<Unit>>, String>((
      ref,
      projectKey,
    ) {
      return ProjectUnitsController(ref, projectKey);
    });

/// EN: Unit detail provider — keyed by (projectId, unitIdentifier).
/// KO: 유닛 상세 프로바이더 — (projectId, unitIdentifier) 키.
final unitDetailProvider = FutureProvider.autoDispose
    .family<Unit, (String, String)>((ref, args) async {
      final repository = await ref.read(projectsRepositoryProvider.future);
      final result = await repository.getUnitDetail(
        projectId: args.$1,
        unitIdentifier: args.$2,
      );
      if (result is Success<Unit>) {
        return result.data;
      }
      if (result is Err<Unit>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown unit detail result',
        code: 'unknown_unit_detail_provider',
      );
    });

/// EN: Controller for loading members of a specific unit.
/// KO: 특정 유닛의 멤버 목록을 불러오는 컨트롤러.
class UnitMembersController
    extends StateNotifier<AsyncValue<List<UnitMember>>> {
  UnitMembersController(this._ref, this._projectId, this._unitIdentifier)
    : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String _projectId;
  final String _unitIdentifier;

  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncLoading();
    final repository = await _ref.read(projectsRepositoryProvider.future);
    final result = await repository.getUnitMembers(
      projectId: _projectId,
      unitIdentifier: _unitIdentifier,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<UnitMember>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<UnitMember>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

/// EN: Unit members controller provider — keyed by (projectId, unitId) tuple.
/// KO: (projectId, unitId) 쌍으로 키 지정된 유닛 멤버 컨트롤러 프로바이더.
final unitMembersControllerProvider = StateNotifierProvider.autoDispose
    .family<
      UnitMembersController,
      AsyncValue<List<UnitMember>>,
      (String, String)
    >((ref, args) {
      return UnitMembersController(ref, args.$1, args.$2);
    });

/// EN: Unit member detail controller — keyed by (projectId, unitIdentifier, memberId).
/// KO: 유닛 멤버 상세 컨트롤러 — (projectId, unitIdentifier, memberId) 키.
class UnitMemberDetailController extends StateNotifier<AsyncValue<UnitMember>> {
  UnitMemberDetailController(
    this._ref,
    this._projectId,
    this._unitIdentifier,
    this._memberId,
  ) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String _projectId;
  final String _unitIdentifier;
  final String _memberId;

  Future<void> load({bool forceRefresh = false}) async {
    state = const AsyncLoading();
    final repository = await _ref.read(projectsRepositoryProvider.future);
    final result = await repository.getUnitMemberDetail(
      projectId: _projectId,
      unitIdentifier: _unitIdentifier,
      memberId: _memberId,
      forceRefresh: forceRefresh,
    );

    if (result is Success<UnitMember>) {
      state = AsyncData(result.data);
    } else if (result is Err<UnitMember>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

final unitMemberDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<
      UnitMemberDetailController,
      AsyncValue<UnitMember>,
      (String, String, String)
    >((ref, args) {
      return UnitMemberDetailController(ref, args.$1, args.$2, args.$3);
    });

class VoiceActorsCatalogState {
  const VoiceActorsCatalogState({
    this.items = const [],
    this.query = '',
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<VoiceActorListItem> items;
  final String query;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? error;

  VoiceActorsCatalogState copyWith({
    List<VoiceActorListItem>? items,
    String? query,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? error,
    bool clearError = false,
  }) {
    return VoiceActorsCatalogState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VoiceActorsCatalogController
    extends StateNotifier<VoiceActorsCatalogState> {
  VoiceActorsCatalogController(this._ref, this._projectId)
    : super(const VoiceActorsCatalogState()) {
    unawaited(refresh());
  }

  static const int _pageSize = 20;
  final Ref _ref;
  final String _projectId;

  Future<void> refresh({String? query}) async {
    final normalizedQuery = (query ?? state.query).trim();
    state = state.copyWith(
      query: normalizedQuery,
      items: const [],
      page: 0,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    await _loadPage(page: 0, append: false, forceRefresh: true);
  }

  Future<void> search(String query) async {
    await refresh(query: query);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _loadPage(page: nextPage, append: true);
  }

  Future<void> _loadPage({
    required int page,
    required bool append,
    bool forceRefresh = false,
  }) async {
    final repository = await _ref.read(projectsRepositoryProvider.future);
    final result = await repository.searchVoiceActors(
      projectId: _projectId,
      query: state.query,
      page: page,
      size: _pageSize,
      sort: 'stageName,asc',
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<VoiceActorListItem>>) {
      final fetched = result.data;
      state = state.copyWith(
        items: append ? [...state.items, ...fetched] : fetched,
        page: page,
        hasMore: fetched.length >= _pageSize,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
      return;
    }

    if (result is Err<List<VoiceActorListItem>>) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: result.failure,
      );
    }
  }
}

final voiceActorsCatalogControllerProvider = StateNotifierProvider.autoDispose
    .family<VoiceActorsCatalogController, VoiceActorsCatalogState, String>((
      ref,
      projectId,
    ) {
      return VoiceActorsCatalogController(ref, projectId);
    });

typedef VoiceActorLookupArgs = ({String projectId, String voiceActorId});

final voiceActorDetailProvider = FutureProvider.autoDispose
    .family<VoiceActorDetail, VoiceActorLookupArgs>((ref, args) async {
      final repository = await ref.read(projectsRepositoryProvider.future);
      final result = await repository.getVoiceActorDetail(
        projectId: args.projectId,
        voiceActorId: args.voiceActorId,
      );
      if (result is Success<VoiceActorDetail>) {
        return result.data;
      }
      if (result is Err<VoiceActorDetail>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown voice actor detail result',
        code: 'unknown_voice_actor_detail_provider',
      );
    });

final voiceActorMembersProvider = FutureProvider.autoDispose
    .family<List<VoiceActorMemberSummary>, VoiceActorLookupArgs>((
      ref,
      args,
    ) async {
      final repository = await ref.read(projectsRepositoryProvider.future);
      final result = await repository.getVoiceActorMembers(
        projectId: args.projectId,
        voiceActorId: args.voiceActorId,
      );
      if (result is Success<List<VoiceActorMemberSummary>>) {
        return result.data;
      }
      if (result is Err<List<VoiceActorMemberSummary>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown voice actor members result',
        code: 'unknown_voice_actor_members_provider',
      );
    });

final voiceActorCreditsProvider = FutureProvider.autoDispose
    .family<List<VoiceActorCreditSummary>, VoiceActorLookupArgs>((
      ref,
      args,
    ) async {
      final repository = await ref.read(projectsRepositoryProvider.future);
      final result = await repository.getVoiceActorCredits(
        projectId: args.projectId,
        voiceActorId: args.voiceActorId,
      );
      if (result is Success<List<VoiceActorCreditSummary>>) {
        return result.data;
      }
      if (result is Err<List<VoiceActorCreditSummary>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown voice actor credits result',
        code: 'unknown_voice_actor_credits_provider',
      );
    });

/// EN: Project selection controller provider.
/// KO: 프로젝트 선택 컨트롤러 프로바이더.
final projectSelectionControllerProvider =
    StateNotifierProvider<ProjectSelectionController, ProjectSelectionState>((
      ref,
    ) {
      return ProjectSelectionController(ref);
    });

Project? _findProject(
  List<Project> projects,
  String? storedProjectKey,
  String? storedProjectId,
) {
  if (storedProjectKey != null && storedProjectKey.isNotEmpty) {
    for (final project in projects) {
      if (project.code == storedProjectKey || project.id == storedProjectKey) {
        return project;
      }
    }
  }

  if (storedProjectId != null && storedProjectId.isNotEmpty) {
    for (final project in projects) {
      if (project.id == storedProjectId) {
        return project;
      }
    }
  }

  return null;
}

String _projectKeyFor(Project project) {
  return project.code.isNotEmpty ? project.code : project.id;
}
