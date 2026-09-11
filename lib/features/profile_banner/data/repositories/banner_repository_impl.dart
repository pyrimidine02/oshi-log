/// EN: Concrete implementation of [BannerRepository] backed by remote API and cache.
/// KO: 원격 API와 캐시를 기반으로 한 [BannerRepository]의 구체적 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/banner_entities.dart';
import '../../domain/repositories/banner_repository.dart';
import '../datasources/banner_remote_data_source.dart';
import '../dto/banner_dto.dart';

/// EN: Cache key for the user's active banner.
/// KO: 사용자 활성 배너 캐시 키.
const _cacheKeyActiveBanner = 'banner:active';

/// EN: Cache key for the banner catalog.
/// KO: 배너 카탈로그 캐시 키.
const _cacheKeyCatalog = 'banner:catalog';

/// EN: TTL for the active banner cache — refreshed on every set/clear mutation.
/// KO: 활성 배너 캐시 TTL — set/clear 변이마다 갱신됩니다.
const _activeBannerTtl = Duration(minutes: 10);

/// EN: TTL for the banner catalog — changes infrequently.
/// KO: 배너 카탈로그 캐시 TTL — 변경 빈도가 낮습니다.
const _catalogTtl = Duration(hours: 1);

/// EN: Implementation of [BannerRepository] with CacheManager integration.
/// KO: CacheManager를 통합한 [BannerRepository] 구현체.
class BannerRepositoryImpl implements BannerRepository {
  BannerRepositoryImpl({
    required BannerRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final BannerRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // ---------------------------------------------------------------------------
  // EN: Helpers for ActiveBannerDto JSON serialization (nullable payload).
  // KO: ActiveBannerDto JSON 직렬화 헬퍼 (nullable 페이로드).
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _activeBannerToJson(ActiveBannerDto? dto) {
    if (dto == null) return {'_null': true};
    return dto.toJson();
  }

  ActiveBannerDto? _activeBannerFromJson(Map<String, dynamic> json) {
    if (json['_null'] == true) return null;
    return ActiveBannerDto.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // EN: Helpers for List<BannerItemDto> JSON serialization.
  // KO: List<BannerItemDto> JSON 직렬화 헬퍼.
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _catalogToJson(List<BannerItemDto> items) {
    return {'items': items.map((dto) => dto.toJson()).toList(growable: false)};
  }

  List<BannerItemDto> _catalogFromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BannerItemDto.fromJson)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // EN: BannerRepository implementation
  // KO: BannerRepository 구현
  // ---------------------------------------------------------------------------

  @override
  Future<Result<ActiveBanner?>> fetchActiveBanner() async {
    try {
      final cacheResult = await _cacheManager.resolve<ActiveBannerDto?>(
        key: _cacheKeyActiveBanner,
        policy: CachePolicy.staleWhileRevalidate,
        ttl: _activeBannerTtl,
        fetcher: () async {
          final result = await _remoteDataSource.fetchActiveBanner();
          return switch (result) {
            Success(:final data) => data,
            Err(:final failure) => throw failure,
          };
        },
        toJson: _activeBannerToJson,
        fromJson: _activeBannerFromJson,
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
  Future<Result<ActiveBanner>> setActiveBanner(String bannerId) async {
    try {
      final result = await _remoteDataSource.setActiveBanner(bannerId);
      return switch (result) {
        Success(:final data) => await _cacheActiveBannerAndReturn(data),
        Err(:final failure) => Result.failure(failure),
      };
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> clearActiveBanner() async {
    try {
      final result = await _remoteDataSource.clearActiveBanner();
      if (result is Success) {
        // EN: Invalidate active banner cache after a successful clear.
        // KO: 배너 초기화 성공 후 활성 배너 캐시를 무효화합니다.
        await _cacheManager.remove(_cacheKeyActiveBanner);
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<BannerItem>>> fetchBanners() async {
    try {
      final cacheResult = await _cacheManager.resolve<List<BannerItemDto>>(
        key: _cacheKeyCatalog,
        policy: CachePolicy.staleWhileRevalidate,
        ttl: _catalogTtl,
        fetcher: () async {
          final result = await _remoteDataSource.fetchBanners();
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

  // ---------------------------------------------------------------------------
  // EN: Private helpers
  // KO: 비공개 헬퍼
  // ---------------------------------------------------------------------------

  /// EN: Writes the new active banner to cache and returns the domain entity.
  /// KO: 새 활성 배너를 캐시에 기록하고 도메인 엔티티를 반환합니다.
  Future<Result<ActiveBanner>> _cacheActiveBannerAndReturn(
    ActiveBannerDto dto,
  ) async {
    await _cacheManager.setJson(
      _cacheKeyActiveBanner,
      _activeBannerToJson(dto),
      ttl: _activeBannerTtl,
    );
    return Result.success(dto.toDomain());
  }
}
