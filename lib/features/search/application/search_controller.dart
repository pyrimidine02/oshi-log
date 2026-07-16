/// EN: Search controllers for query results and history.
/// KO: 검색 결과/기록 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/search_remote_data_source.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/entities/search_entities.dart';
import '../domain/repositories/search_repository.dart';

class SearchController extends StateNotifier<AsyncValue<List<SearchItem>>> {
  SearchController(this._ref) : super(const AsyncData([]));

  final Ref _ref;
  int _activeRequestId = 0;

  Future<void> search(
    String query, {
    bool forceRefresh = false,
    List<String> types = const [],
  }) async {
    final requestId = ++_activeRequestId;
    final repository = await _ref.read(searchRepositoryProvider.future);
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      repository.cancelInFlightSearch();
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    repository.cancelInFlightSearch();
    final projectId = _ref.read(selectedProjectIdProvider);
    final unitIds = List<String>.unmodifiable(
      _ref.read(selectedUnitIdsProvider),
    );
    final result = await repository.search(
      query: trimmed,
      types: types,
      projectId: projectId,
      unitIds: unitIds,
      forceRefresh: forceRefresh,
    );
    if (requestId != _activeRequestId) {
      return;
    }

    if (result is Success<List<SearchItem>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<SearchItem>>) {
      if (result.failure.code == 'cancelled') {
        return;
      }
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

class SearchHistoryController extends StateNotifier<List<String>> {
  SearchHistoryController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(localStorageProvider.future);
    state = storage.getRecentSearches();
  }

  Future<void> addSearch(String query) async {
    final storage = await _ref.read(localStorageProvider.future);
    await storage.addRecentSearch(query);
    state = storage.getRecentSearches();
  }

  Future<void> removeSearch(String query) async {
    final storage = await _ref.read(localStorageProvider.future);
    await storage.removeRecentSearch(query);
    state = storage.getRecentSearches();
  }

  Future<void> clear() async {
    final storage = await _ref.read(localStorageProvider.future);
    await storage.clearRecentSearches();
    state = const [];
  }
}

/// EN: Search repository provider.
/// KO: 검색 리포지토리 프로바이더.
final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return SearchRepositoryImpl(
    remoteDataSource: SearchRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Search controller provider.
/// KO: 검색 컨트롤러 프로바이더.
final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<List<SearchItem>>>((
      ref,
    ) {
      return SearchController(ref);
    });

/// EN: Search history controller provider.
/// KO: 검색 기록 컨트롤러 프로바이더.
final searchHistoryControllerProvider =
    StateNotifierProvider<SearchHistoryController, List<String>>((ref) {
      return SearchHistoryController(ref);
    });

/// EN: Popular search keyword discovery provider.
/// KO: 인기 검색어 디스커버리 프로바이더.
final searchPopularDiscoveryProvider = FutureProvider.autoDispose
    .family<SearchPopularDiscovery, int>((ref, limit) async {
      final repository = await ref.watch(searchRepositoryProvider.future);
      final result = await repository.getPopularDiscovery(limit: limit);
      if (result is Success<SearchPopularDiscovery>) {
        return result.data;
      }
      if (result is Err<SearchPopularDiscovery>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown popular discovery provider state',
        code: 'unknown_popular_discovery_provider',
      );
    });

/// EN: Discovery category provider.
/// KO: 디스커버리 카테고리 프로바이더.
final searchCategoryDiscoveryProvider = FutureProvider.autoDispose
    .family<SearchCategoryDiscovery, int>((ref, limit) async {
      final repository = await ref.watch(searchRepositoryProvider.future);
      final result = await repository.getCategoryDiscovery(limit: limit);
      if (result is Success<SearchCategoryDiscovery>) {
        return result.data;
      }
      if (result is Err<SearchCategoryDiscovery>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown category discovery provider state',
        code: 'unknown_category_discovery_provider',
      );
    });
