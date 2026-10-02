/// EN: Riverpod providers and StateNotifiers for the titles feature.
/// KO: 칭호 기능을 위한 Riverpod 프로바이더 및 StateNotifier.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/identity/progression/data/datasources/titles_remote_data_source.dart';
import 'package:oshi_log/features/identity/progression/data/repositories/titles_repository_impl.dart';
import 'package:oshi_log/features/identity/progression/domain/entities/title_entities.dart';
import 'package:oshi_log/features/identity/progression/domain/repositories/titles_repository.dart';

// =============================================================================
// EN: Dependency providers
// KO: 의존성 프로바이더
// =============================================================================

/// EN: Provides the concrete [TitlesRepository], wiring the remote data source
///     and cache manager together. Exposed as a [FutureProvider] because
///     [CacheManager] itself requires async initialization.
/// KO: 원격 데이터 소스와 캐시 매니저를 연결하여 구체적인 [TitlesRepository]를 제공합니다.
///     [CacheManager] 자체가 비동기 초기화를 요구하므로 [FutureProvider]로 노출합니다.
final titlesRepositoryProvider = FutureProvider<TitlesRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.watch(cacheManagerProvider.future);
  return TitlesRepositoryImpl(
    remoteDataSource: TitlesRemoteDataSource(apiClient: apiClient),
    cacheManager: cacheManager,
  );
});

// =============================================================================
// EN: Active title
// KO: 활성 칭호
// =============================================================================

/// EN: Manages the user's currently active title.
///     Loads on construction; exposes mutation methods [setActive] and [clearActive].
/// KO: 사용자의 현재 활성 칭호를 관리합니다.
///     생성 시 로드하며, 변이 메서드 [setActive], [clearActive]를 제공합니다.
class ActiveTitleNotifier extends StateNotifier<AsyncValue<ActiveTitleItem?>> {
  ActiveTitleNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final TitlesRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchMyActiveTitle();
    if (!mounted) return;
    result.when(
      success: (title) => state = AsyncValue.data(title),
      failure: (_) => state = const AsyncValue.data(null),
    );
  }

  /// EN: Refreshes the active title from the remote source.
  /// KO: 원격 소스에서 활성 칭호를 새로 불러옵니다.
  Future<void> refresh() => _load();

  /// EN: Clears local state without a network call (used on logout).
  /// KO: 네트워크 호출 없이 로컬 상태만 초기화합니다 (로그아웃 시 사용).
  void clearLocally() {
    state = const AsyncValue.data(null);
  }

  /// EN: Sets a new active title by [titleId].
  ///     Optimistically updates state, rolls back on error.
  /// KO: [titleId]로 새 활성 칭호를 설정합니다.
  ///     낙관적으로 상태를 업데이트하고 오류 발생 시 롤백합니다.
  Future<void> setActive(String titleId) async {
    final previous = state;
    state = const AsyncValue.loading();
    final result = await _repository.setMyActiveTitle(titleId);
    if (!mounted) return;
    result.when(
      success: (title) => state = AsyncValue.data(title),
      failure: (failure) {
        state = previous;
        // EN: Re-throw so callers can surface the error in the UI.
        // KO: 호출자가 UI에서 에러를 표시할 수 있도록 재던집니다.
        throw failure;
      },
    );
  }

  /// EN: Clears the active title, reverting to no displayed title.
  /// KO: 활성 칭호를 제거하고 표시되는 칭호가 없는 상태로 되돌립니다.
  Future<void> clearActive() async {
    final previous = state;
    state = const AsyncValue.loading();
    final result = await _repository.clearMyActiveTitle();
    if (!mounted) return;
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      failure: (failure) {
        state = previous;
        throw failure;
      },
    );
  }
}

/// EN: Provider for [ActiveTitleNotifier].
///     Long-lived (not autoDispose) so the title persists across tab switches.
///     Delegates to a loading state until the repository is ready.
/// KO: [ActiveTitleNotifier] 프로바이더.
///     탭 전환 시 칭호가 유지되도록 autoDispose가 아닌 일반 프로바이더입니다.
///     리포지토리가 준비될 때까지 로딩 상태를 위임합니다.
final activeTitleProvider =
    StateNotifierProvider<ActiveTitleNotifier, AsyncValue<ActiveTitleItem?>>((
      ref,
    ) {
      final repoAsync = ref.watch(titlesRepositoryProvider);

      // EN: While the repository is loading / errored, return a temporary
      //     notifier that holds a loading/error state and is replaced once the
      //     repository resolves.
      // KO: 리포지토리가 로딩 중이거나 오류 상태인 경우, 로딩/오류 상태를 유지하는
      //     임시 노티파이어를 반환하고 리포지토리가 완료되면 교체됩니다.
      return repoAsync.when(
        data: (repo) {
          final notifier = ActiveTitleNotifier(repo);
          // EN: Clear local state on logout so stale title is not shown.
          // KO: 로그아웃 시 이전 유저 칭호가 표시되지 않도록 로컬 상태를 초기화합니다.
          ref.listen<bool>(isAuthenticatedProvider, (_, isAuthenticated) {
            if (!isAuthenticated) notifier.clearLocally();
          });
          return notifier;
        },
        loading: _LoadingActiveTitleNotifier.new,
        error: (error, stack) => _ErrorActiveTitleNotifier(error, stack),
      );
    });

// =============================================================================
// EN: Title catalog
// KO: 칭호 카탈로그
// =============================================================================

/// EN: Manages the title catalog list and applies changes to the active title.
/// KO: 칭호 카탈로그 목록을 관리하고 활성 칭호에 변경사항을 적용합니다.
class TitleCatalogNotifier
    extends StateNotifier<AsyncValue<List<TitleCatalogItem>>> {
  TitleCatalogNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    _load();
  }

  final TitlesRepository _repository;
  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchTitleCatalog();
    if (!mounted) return;
    result.when(
      success: (items) => state = AsyncValue.data(items),
      failure: (failure) =>
          state = AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// EN: Refreshes the catalog from the remote source (supports pull-to-refresh).
  /// KO: 원격 소스에서 카탈로그를 새로 불러옵니다 (pull-to-refresh 지원).
  Future<void> refreshCatalog() => _load();

  /// EN: Applies a title by [titleId]: sets it as active then refreshes the
  ///     catalog so isActive flags stay consistent.
  /// KO: [titleId]로 칭호를 적용합니다: 활성으로 설정한 뒤 카탈로그를 새로 불러서
  ///     isActive 플래그가 일관성을 유지하도록 합니다.
  Future<void> applyTitle(String titleId) async {
    await _ref.read(activeTitleProvider.notifier).setActive(titleId);
    if (!mounted) return;
    await _load();
  }
}

/// EN: Auto-disposing provider for fetching another user's active title.
///     Returns null when the user has no active title.
/// KO: 다른 사용자의 활성 칭호를 가져오는 자동 해제 프로바이더.
///     해당 사용자에게 활성 칭호가 없으면 null을 반환합니다.
final userActiveTitleProvider = FutureProvider.autoDispose
    .family<ActiveTitleItem?, String>((ref, userId) async {
      if (userId.isEmpty) return null;
      final repository = await ref.read(titlesRepositoryProvider.future);
      final result = await repository.fetchUserActiveTitle(userId);
      return result.when(success: (item) => item, failure: (_) => null);
    });

/// EN: Auto-disposing provider for [TitleCatalogNotifier].
///     Auto-disposed because it is only needed while the picker page is open.
/// KO: [TitleCatalogNotifier]를 위한 자동 해제 프로바이더.
///     피커 페이지가 열려 있는 동안에만 필요하므로 autoDispose를 사용합니다.
final titleCatalogProvider =
    StateNotifierProvider.autoDispose<
      TitleCatalogNotifier,
      AsyncValue<List<TitleCatalogItem>>
    >((ref) {
      return ref
          .watch(titlesRepositoryProvider)
          .when(
            data: (repo) => TitleCatalogNotifier(repo, ref),
            loading: _LoadingTitleCatalogNotifier.new,
            error: (error, stack) => _ErrorTitleCatalogNotifier(error, stack),
          );
    });

// =============================================================================
// EN: Internal placeholder notifiers for loading/error repository states.
// KO: 리포지토리 로딩/오류 상태용 내부 플레이스홀더 노티파이어.
// =============================================================================

class _LoadingActiveTitleNotifier extends ActiveTitleNotifier {
  _LoadingActiveTitleNotifier() : super(_NopTitlesRepository()) {
    state = const AsyncValue.loading();
  }
}

class _ErrorActiveTitleNotifier extends ActiveTitleNotifier {
  _ErrorActiveTitleNotifier(Object error, StackTrace stack)
    : super(_NopTitlesRepository()) {
    state = AsyncValue.error(error, stack);
  }
}

class _LoadingTitleCatalogNotifier extends TitleCatalogNotifier {
  _LoadingTitleCatalogNotifier() : super(_NopTitlesRepository(), _NopRef()) {
    state = const AsyncValue.loading();
  }
}

class _ErrorTitleCatalogNotifier extends TitleCatalogNotifier {
  _ErrorTitleCatalogNotifier(Object error, StackTrace stack)
    : super(_NopTitlesRepository(), _NopRef()) {
    state = AsyncValue.error(error, stack);
  }
}

// =============================================================================
// EN: No-operation stubs used only by placeholder notifiers.
// KO: 플레이스홀더 노티파이어에서만 사용되는 무작동 스텁.
// =============================================================================

class _NopTitlesRepository implements TitlesRepository {
  @override
  Future<Result<List<TitleCatalogItem>>> fetchTitleCatalog({
    String? projectKey,
  }) async => const Result.success([]);

  @override
  Future<Result<ActiveTitleItem?>> fetchMyActiveTitle({
    String? projectKey,
  }) async => const Result.success(null);

  @override
  Future<Result<ActiveTitleItem>> setMyActiveTitle(
    String titleId, {
    String? projectKey,
  }) async => const Result.success(
    ActiveTitleItem(
      titleId: '',
      code: '',
      name: '',
      category: TitleCategory.activity,
    ),
  );

  @override
  Future<Result<void>> clearMyActiveTitle({String? projectKey}) async =>
      const Result.success(null);

  @override
  Future<Result<ActiveTitleItem?>> fetchUserActiveTitle(
    String userId, {
    String? projectKey,
  }) async => const Result.success(null);

  @override
  Future<void> invalidateTitleCaches() async {}
}

// EN: Minimal no-operation Ref implementation for placeholder notifiers.
// EN: Only the read() method is required by TitleCatalogNotifier.
// KO: 플레이스홀더 노티파이어용 최소 무작동 Ref 구현체.
// KO: TitleCatalogNotifier에서 read() 메서드만 필요합니다.
class _NopRef implements Ref {
  @override
  T read<T>(ProviderListenable<T> provider) {
    throw UnsupportedError('_NopRef.read should never be called');
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '_NopRef does not support method: ${invocation.memberName}',
  );
}
