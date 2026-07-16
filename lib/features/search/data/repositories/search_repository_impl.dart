/// EN: Search repository implementation with caching.
/// KO: 캐시를 포함한 검색 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';
import '../dto/search_discovery_dto.dart';
import '../dto/search_item_dto.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({
    required SearchRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final SearchRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<SearchItem>>> search({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(
      query: query,
      types: types,
      projectId: projectId,
      unitIds: unitIds,
      page: page,
      size: size,
    );
    // EN: Use staleWhileRevalidate — show cached search results instantly.
    // KO: staleWhileRevalidate 사용 — 캐시된 검색 결과 즉시 표시.
    final profile = CacheProfiles.searchResults;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<SearchItemDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchSearch(
          query: query,
          types: types,
          projectId: projectId,
          unitIds: unitIds,
          page: page,
          size: size,
        ),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(SearchItemDto.fromJson)
                .toList();
          }
          return <SearchItemDto>[];
        },
      );

      final entities = cacheResult.data
          .map((dto) => SearchItem.fromDto(dto, projectId: projectId))
          .toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<SearchItemDto>> _fetchSearch({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
  }) async {
    final result = await _remoteDataSource.search(
      query: query,
      types: types,
      projectId: projectId,
      unitIds: unitIds,
      page: page,
      size: size,
    );

    if (result is Success<List<SearchItemDto>>) {
      return result.data;
    }
    if (result is Err<List<SearchItemDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure('Unknown search result', code: 'unknown_search');
  }

  @override
  Future<Result<SearchPopularDiscovery>> getPopularDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'search:discovery:popular:${limit.clamp(1, 20)}';
    final profile = CacheProfiles.searchPopularDiscovery;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<SearchPopularDiscoveryDto>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () async {
              final result = await _remoteDataSource.fetchPopularDiscovery(
                limit: limit,
              );
              if (result is Success<SearchPopularDiscoveryDto>) {
                return result.data;
              }
              if (result is Err<SearchPopularDiscoveryDto>) {
                throw result.failure;
              }
              throw const UnknownFailure(
                'Unknown popular discovery result',
                code: 'unknown_search_discovery_popular',
              );
            },
            toJson: (dto) => {
              'updatedAt': dto.updatedAt?.toUtc().toIso8601String(),
              'popularKeywords': dto.popularKeywords
                  .map((item) => {'keyword': item.keyword, 'score': item.score})
                  .toList(),
            },
            fromJson: SearchPopularDiscoveryDto.fromJson,
          );
      return Result.success(SearchPopularDiscovery.fromDto(cacheResult.data));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<SearchCategoryDiscovery>> getCategoryDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'search:discovery:categories:${limit.clamp(1, 20)}';
    final profile = CacheProfiles.searchCategoryDiscovery;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<SearchCategoryDiscoveryDto>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () async {
              final result = await _remoteDataSource.fetchCategoryDiscovery(
                limit: limit,
              );
              if (result is Success<SearchCategoryDiscoveryDto>) {
                return result.data;
              }
              if (result is Err<SearchCategoryDiscoveryDto>) {
                throw result.failure;
              }
              throw const UnknownFailure(
                'Unknown category discovery result',
                code: 'unknown_search_discovery_categories',
              );
            },
            toJson: (dto) => {
              'updatedAt': dto.updatedAt?.toUtc().toIso8601String(),
              'categories': dto.categories
                  .map(
                    (item) => {
                      'code': item.code,
                      'label': item.label,
                      'contentCount': item.contentCount,
                    },
                  )
                  .toList(),
            },
            fromJson: SearchCategoryDiscoveryDto.fromJson,
          );
      return Result.success(SearchCategoryDiscovery.fromDto(cacheResult.data));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  void cancelInFlightSearch() {
    _remoteDataSource.cancelInFlightSearch();
  }

  String _cacheKey({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedTypes = List<String>.from(types)
      ..removeWhere((type) => type.trim().isEmpty)
      ..sort();
    final normalizedProjectId = projectId?.trim() ?? '';
    final normalizedUnitIds =
        unitIds
            .map((unitId) => unitId.trim())
            .where((unitId) => unitId.isNotEmpty)
            .toList()
          ..sort();
    final typeKey = normalizedTypes.isEmpty ? 'all' : normalizedTypes.join(',');
    final projectKey = normalizedProjectId.isEmpty
        ? 'all-projects'
        : normalizedProjectId;
    final unitKey = normalizedUnitIds.isEmpty
        ? 'all-units'
        : normalizedUnitIds.join(',');
    return 'search:$normalizedQuery:$typeKey:$projectKey:$unitKey:$page:$size';
  }
}
