/// EN: Riverpod providers and StateNotifiers for the profile banner feature.
/// KO: 프로필 배너 기능을 위한 Riverpod 프로바이더 및 StateNotifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'dart:async';
import 'package:oshi_log/features/identity/progression/data/datasources/banner_remote_data_source.dart';
import 'package:oshi_log/features/identity/progression/data/repositories/banner_repository_impl.dart';
import 'package:oshi_log/features/identity/progression/domain/entities/banner_entities.dart';
import 'package:oshi_log/features/identity/progression/domain/repositories/banner_repository.dart';

// =============================================================================
// EN: Dependency providers
// KO: 의존성 프로바이더
// =============================================================================

/// EN: Provides the concrete [BannerRepository], wiring the remote data source
///     and cache manager together. Exposed as a [FutureProvider] because
///     [CacheManager] itself requires async initialization.
/// KO: 원격 데이터 소스와 캐시 매니저를 연결하여 구체적인 [BannerRepository]를 제공합니다.
///     [CacheManager] 자체가 비동기 초기화를 요구하므로 [FutureProvider]로 노출합니다.
final bannerRepositoryProvider = FutureProvider<BannerRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.watch(cacheManagerProvider.future);
  return BannerRepositoryImpl(
    remoteDataSource: BannerRemoteDataSource(apiClient: apiClient),
    cacheManager: cacheManager,
  );
});

// =============================================================================
// EN: Active banner
// KO: 활성 배너
// =============================================================================

/// EN: Manages the user's currently active banner.
///     Loads on construction; exposes mutation methods [setActive] and [clearActive].
/// KO: 사용자의 현재 활성 배너를 관리합니다.
///     생성 시 로드하며, 변이 메서드 [setActive], [clearActive]를 제공합니다.
class ActiveBannerNotifier extends StateNotifier<AsyncValue<ActiveBanner?>> {
  ActiveBannerNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final BannerRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchActiveBanner();
    if (!mounted) return;
    result.when(
      success: (banner) => state = AsyncValue.data(banner),
      failure: (_) => state = const AsyncValue.data(null),
    );
  }

  /// EN: Refreshes the active banner from the remote source.
  /// KO: 원격 소스에서 활성 배너를 새로 불러옵니다.
  Future<void> refresh() => _load();

  /// EN: Clears local state without a network call (used on logout).
  /// KO: 네트워크 호출 없이 로컬 상태만 초기화합니다 (로그아웃 시 사용).
  void clearLocally() {
    state = const AsyncValue.data(null);
  }

  /// EN: Sets a new active banner by [bannerId].
  ///     Optimistically updates state, rolls back on error.
  /// KO: [bannerId]로 새 활성 배너를 설정합니다.
  ///     낙관적으로 상태를 업데이트하고 오류 발생 시 롤백합니다.
  Future<void> setActive(String bannerId) async {
    final previous = state;
    state = const AsyncValue.loading();
    final result = await _repository.setActiveBanner(bannerId);
    if (!mounted) return;
    result.when(
      success: (banner) => state = AsyncValue.data(banner),
      failure: (failure) {
        state = previous;
        // EN: Re-throw so callers can surface the error in the UI.
        // KO: 호출자가 UI에서 에러를 표시할 수 있도록 재던집니다.
        throw failure;
      },
    );
  }

  /// EN: Clears the active banner, reverting to the default gradient header.
  /// KO: 활성 배너를 제거하고 기본 그라디언트 헤더로 되돌립니다.
  Future<void> clearActive() async {
    final previous = state;
    state = const AsyncValue.loading();
    final result = await _repository.clearActiveBanner();
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

/// EN: Provider for [ActiveBannerNotifier].
///     Long-lived (not autoDispose) so the banner persists across tab switches.
///     Delegates to a loading state until the repository is ready.
/// KO: [ActiveBannerNotifier] 프로바이더.
///     탭 전환 시 배너가 유지되도록 autoDispose가 아닌 일반 프로바이더입니다.
///     리포지토리가 준비될 때까지 로딩 상태를 위임합니다.
final activeBannerProvider =
    StateNotifierProvider<ActiveBannerNotifier, AsyncValue<ActiveBanner?>>((
      ref,
    ) {
      final repoAsync = ref.watch(bannerRepositoryProvider);

      // EN: While the repository is loading / errored, return a temporary
      //     notifier that holds a loading/error state and is replaced once the
      //     repository resolves.
      // KO: 리포지토리가 로딩 중이거나 오류 상태인 경우, 로딩/오류 상태를 유지하는
      //     임시 노티파이어를 반환하고 리포지토리가 완료되면 교체됩니다.
      return repoAsync.when(
        data: (repo) {
          final notifier = ActiveBannerNotifier(repo);
          // EN: Clear local state on logout so stale banner is not shown.
          // KO: 로그아웃 시 이전 유저 배너가 표시되지 않도록 로컬 상태를 초기화합니다.
          ref.listen<bool>(isAuthenticatedProvider, (_, isAuthenticated) {
            if (!isAuthenticated) notifier.clearLocally();
          });
          return notifier;
        },
        loading: _LoadingActiveBannerNotifier.new,
        error: (error, stack) => _ErrorActiveBannerNotifier(error, stack),
      );
    });

// =============================================================================
// EN: Banner catalog
// KO: 배너 카탈로그
// =============================================================================

/// EN: Manages the banner catalog list and applies changes to the active banner.
/// KO: 배너 카탈로그 목록을 관리하고 활성 배너에 변경사항을 적용합니다.
class BannerCatalogNotifier
    extends StateNotifier<AsyncValue<List<BannerItem>>> {
  BannerCatalogNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    _load();
  }

  final BannerRepository _repository;
  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchBanners();
    if (!mounted) return;
    result.when(
      success: (items) => state = AsyncValue.data(items),
      failure: (failure) =>
          state = AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// EN: Refreshes the catalog from the remote source.
  /// KO: 원격 소스에서 카탈로그를 새로 불러옵니다.
  Future<void> refresh() => _load();

  /// EN: Applies a banner by [bannerId]: sets it as active then refreshes the
  ///     catalog so isActive flags stay consistent.
  /// KO: [bannerId]로 배너를 적용합니다: 활성으로 설정한 뒤 카탈로그를 새로 불러서
  ///     isActive 플래그가 일관성을 유지하도록 합니다.
  Future<void> applyBanner(String bannerId) async {
    await _ref.read(activeBannerProvider.notifier).setActive(bannerId);
    if (!mounted) return;
    await _load();
  }

  /// EN: Removes the active banner, reverting to the default gradient header.
  ///     Refreshes the catalog so isActive flags are cleared.
  /// KO: 활성 배너를 해제하고 기본 그라디언트 헤더로 되돌립니다.
  ///     카탈로그를 새로 불러서 isActive 플래그가 초기화되도록 합니다.
  Future<void> removeBanner() async {
    await _ref.read(activeBannerProvider.notifier).clearActive();
    if (!mounted) return;
    await _load();
  }
}

/// EN: Auto-disposing provider for [BannerCatalogNotifier].
///     Auto-disposed because it is only needed while the picker page is open.
/// KO: [BannerCatalogNotifier]를 위한 자동 해제 프로바이더.
///     피커 페이지가 열려 있는 동안에만 필요하므로 autoDispose를 사용합니다.
final bannerCatalogProvider =
    StateNotifierProvider.autoDispose<
      BannerCatalogNotifier,
      AsyncValue<List<BannerItem>>
    >((ref) {
      return ref
          .watch(bannerRepositoryProvider)
          .when(
            data: (repo) => BannerCatalogNotifier(repo, ref),
            loading: _LoadingCatalogNotifier.new,
            error: (error, stack) => _ErrorCatalogNotifier(error, stack),
          );
    });

// =============================================================================
// EN: Internal placeholder notifiers for loading/error repository states.
// KO: 리포지토리 로딩/오류 상태용 내부 플레이스홀더 노티파이어.
// =============================================================================

class _LoadingActiveBannerNotifier extends ActiveBannerNotifier {
  _LoadingActiveBannerNotifier() : super(_NopBannerRepository()) {
    state = const AsyncValue.loading();
  }
}

class _ErrorActiveBannerNotifier extends ActiveBannerNotifier {
  _ErrorActiveBannerNotifier(Object error, StackTrace stack)
    : super(_NopBannerRepository()) {
    state = AsyncValue.error(error, stack);
  }
}

class _LoadingCatalogNotifier extends BannerCatalogNotifier {
  _LoadingCatalogNotifier() : super(_NopBannerRepository(), _NopRef()) {
    state = const AsyncValue.loading();
  }
}

class _ErrorCatalogNotifier extends BannerCatalogNotifier {
  _ErrorCatalogNotifier(Object error, StackTrace stack)
    : super(_NopBannerRepository(), _NopRef()) {
    state = AsyncValue.error(error, stack);
  }
}

// =============================================================================
// EN: No-operation stubs used only by placeholder notifiers.
// KO: 플레이스홀더 노티파이어에서만 사용되는 무작동 스텁.
// =============================================================================

class _NopBannerRepository implements BannerRepository {
  @override
  Future<Result<ActiveBanner?>> fetchActiveBanner() async =>
      const Result.success(null);

  @override
  Future<Result<ActiveBanner>> setActiveBanner(String bannerId) async =>
      const Result.success(ActiveBanner());

  @override
  Future<Result<void>> clearActiveBanner() async => const Result.success(null);

  @override
  Future<Result<List<BannerItem>>> fetchBanners() async =>
      const Result.success([]);
}

// EN: Minimal no-operation Ref implementation for placeholder notifiers.
// EN: Only the read() method is required by BannerCatalogNotifier.
// KO: 플레이스홀더 노티파이어용 최소 무작동 Ref 구현체.
// KO: BannerCatalogNotifier에서 read() 메서드만 필요합니다.
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
