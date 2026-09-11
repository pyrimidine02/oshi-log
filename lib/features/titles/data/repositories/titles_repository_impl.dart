/// EN: Concrete implementation of [TitlesRepository] backed by remote API
///     and CacheManager.
/// KO: 원격 API와 CacheManager를 기반으로 한 [TitlesRepository]의 구체적 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/title_entities.dart';
import '../../domain/repositories/titles_repository.dart';
import '../datasources/titles_remote_data_source.dart';
import '../dto/title_dto.dart';

// =============================================================================
// EN: Cache configuration constants
// KO: 캐시 설정 상수
// =============================================================================

/// EN: Cache key for the authenticated user's active title.
/// KO: 인증된 사용자의 활성 칭호 캐시 키.
const _cacheKeyMyActiveTitle = 'title:me:active';

/// EN: Cache key for the title catalog.
/// KO: 칭호 카탈로그 캐시 키.
const _cacheKeyCatalog = 'title:catalog';

/// EN: TTL for the active title cache — refreshed on every set/clear mutation.
/// KO: 활성 칭호 캐시 TTL — set/clear 변이마다 갱신됩니다.
const _activeTitleTtl = Duration(minutes: 10);

/// EN: TTL for the title catalog — catalog changes are infrequent.
/// KO: 칭호 카탈로그 캐시 TTL — 카탈로그 변경 빈도가 낮습니다.
const _catalogTtl = Duration(hours: 1);

// =============================================================================
// EN: Repository implementation
// KO: 리포지토리 구현체
// =============================================================================

/// EN: Implementation of [TitlesRepository] with CacheManager integration.
///     - Catalog and own active title use staleWhileRevalidate caching.
///     - Other-user active title is fetched directly (no caching needed).
/// KO: CacheManager를 통합한 [TitlesRepository] 구현체.
///     - 카탈로그와 본인 활성 칭호는 staleWhileRevalidate 캐싱을 사용합니다.
///     - 다른 사용자의 활성 칭호는 직접 조회합니다 (캐시 불필요).
class TitlesRepositoryImpl implements TitlesRepository {
  TitlesRepositoryImpl({
    required TitlesRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final TitlesRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // ---------------------------------------------------------------------------
  // EN: Helpers — ActiveTitleItemDto nullable JSON serialization
  // KO: 헬퍼 — ActiveTitleItemDto nullable JSON 직렬화
  // ---------------------------------------------------------------------------

  /// EN: Serializes a nullable [ActiveTitleItemDto] to a JSON map.
  ///     A sentinel `_null: true` entry marks the intentional absence of a title
  ///     so that a cache hit can be distinguished from a cache miss.
  /// KO: nullable [ActiveTitleItemDto]를 JSON 맵으로 직렬화합니다.
  ///     `_null: true` 센티넬 항목으로 칭호가 의도적으로 없음을 표시하여
  ///     캐시 히트와 캐시 미스를 구분합니다.
  Map<String, dynamic> _activeTitleToJson(ActiveTitleItemDto? dto) {
    if (dto == null) return {'_null': true};
    return dto.toJson();
  }

  /// EN: Deserializes a nullable [ActiveTitleItemDto] from a cached JSON map.
  /// KO: 캐시된 JSON 맵에서 nullable [ActiveTitleItemDto]를 역직렬화합니다.
  ActiveTitleItemDto? _activeTitleFromJson(Map<String, dynamic> json) {
    if (json['_null'] == true) return null;
    return ActiveTitleItemDto.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // EN: Helpers — List<TitleCatalogItemDto> JSON serialization
  // KO: 헬퍼 — List<TitleCatalogItemDto> JSON 직렬화
  // ---------------------------------------------------------------------------

  /// EN: Serializes a list of [TitleCatalogItemDto] to a JSON map.
  /// KO: [TitleCatalogItemDto] 목록을 JSON 맵으로 직렬화합니다.
  Map<String, dynamic> _catalogToJson(List<TitleCatalogItemDto> items) {
    return {'items': items.map((dto) => dto.toJson()).toList(growable: false)};
  }

  /// EN: Deserializes a list of [TitleCatalogItemDto] from a cached JSON map.
  /// KO: 캐시된 JSON 맵에서 [TitleCatalogItemDto] 목록을 역직렬화합니다.
  List<TitleCatalogItemDto> _catalogFromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TitleCatalogItemDto.fromJson)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // EN: TitlesRepository implementation
  // KO: TitlesRepository 구현
  // ---------------------------------------------------------------------------

  @override
  Future<Result<List<TitleCatalogItem>>> fetchTitleCatalog({
    String? projectKey,
  }) async {
    try {
      final cacheResult = await _cacheManager
          .resolve<List<TitleCatalogItemDto>>(
            key: _cacheKeyCatalog,
            policy: CachePolicy.staleWhileRevalidate,
            ttl: _catalogTtl,
            fetcher: () async {
              final result = await _remoteDataSource.fetchTitleCatalog(
                projectKey: projectKey,
              );
              return switch (result) {
                Success(:final data) => data,
                Err(:final failure) => throw failure,
              };
            },
            toJson: _catalogToJson,
            fromJson: _catalogFromJson,
          );
      final domain = cacheResult.data
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Result.success(domain);
    } on Failure catch (f) {
      return Result.failure(f);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ActiveTitleItem?>> fetchMyActiveTitle({
    String? projectKey,
  }) async {
    try {
      final cacheResult = await _cacheManager.resolve<ActiveTitleItemDto?>(
        key: _cacheKeyMyActiveTitle,
        policy: CachePolicy.staleWhileRevalidate,
        ttl: _activeTitleTtl,
        fetcher: () async {
          final result = await _remoteDataSource.fetchMyActiveTitle(
            projectKey: projectKey,
          );
          return switch (result) {
            Success(:final data) => data,
            Err(:final failure) => throw failure,
          };
        },
        toJson: _activeTitleToJson,
        fromJson: _activeTitleFromJson,
      );
      final domain = cacheResult.data?.toDomain();
      return Result.success(domain);
    } on Failure catch (f) {
      return Result.failure(f);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ActiveTitleItem>> setMyActiveTitle(
    String titleId, {
    String? projectKey,
  }) async {
    try {
      final result = await _remoteDataSource.setMyActiveTitle(
        titleId,
        projectKey: projectKey,
      );
      return switch (result) {
        Success(:final data) => await _cacheActiveTitleAndReturn(data),
        Err(:final failure) => Result.failure(failure),
      };
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> clearMyActiveTitle({String? projectKey}) async {
    try {
      final result = await _remoteDataSource.clearMyActiveTitle(
        projectKey: projectKey,
      );
      if (result is Success) {
        // EN: Invalidate active title cache after a successful clear.
        // KO: 칭호 초기화 성공 후 활성 칭호 캐시를 무효화합니다.
        await _cacheManager.remove(_cacheKeyMyActiveTitle);
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ActiveTitleItem?>> fetchUserActiveTitle(
    String userId, {
    String? projectKey,
  }) async {
    try {
      // EN: No caching for other users' active titles — always fresh from API.
      // KO: 다른 사용자의 활성 칭호는 캐시하지 않고 항상 API에서 직접 조회합니다.
      final result = await _remoteDataSource.fetchUserActiveTitle(
        userId,
        projectKey: projectKey,
      );
      return switch (result) {
        Success(:final data) => Result.success(data?.toDomain()),
        Err(:final failure) => Result.failure(failure),
      };
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<void> invalidateTitleCaches() async {
    await Future.wait([
      _cacheManager.remove(_cacheKeyMyActiveTitle),
      _cacheManager.remove(_cacheKeyCatalog),
    ]);
  }

  // ---------------------------------------------------------------------------
  // EN: Private helpers
  // KO: 비공개 헬퍼
  // ---------------------------------------------------------------------------

  /// EN: Writes the newly active title to cache and returns the domain entity.
  /// KO: 새로운 활성 칭호를 캐시에 기록하고 도메인 엔티티를 반환합니다.
  Future<Result<ActiveTitleItem>> _cacheActiveTitleAndReturn(
    ActiveTitleItemDto dto,
  ) async {
    await _cacheManager.setJson(
      _cacheKeyMyActiveTitle,
      _activeTitleToJson(dto),
      ttl: _activeTitleTtl,
    );
    return Result.success(dto.toDomain());
  }
}
