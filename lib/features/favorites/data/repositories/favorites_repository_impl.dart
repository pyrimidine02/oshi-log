/// EN: Favorites repository implementation with caching.
/// KO: 캐시를 포함한 즐겨찾기 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/favorite_entities.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';
import '../dto/favorite_dto.dart';
import '../mappers/favorite_entities_mappers.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({
    required FavoritesRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final FavoritesRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _favoritesCacheKeyPaged(page, size);
    final profile = CacheProfiles.favoritesList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<FavoriteItemDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchFavorites(page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(FavoriteItemDto.fromJson)
                .toList();
          }
          return <FavoriteItemDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<FavoriteItem>> addFavorite({
    required String entityId,
    required FavoriteType type,
  }) async {
    try {
      final result = await _remoteDataSource.addFavorite(
        entityId: entityId,
        entityType: _typeToApi(type),
      );

      if (result is Success<FavoriteItemDto>) {
        await _cacheManager.remove(_favoritesCacheKeyPaged(0, 20));
        return Result.success(result.data.toDomain());
      }
      if (result is Err<FavoriteItemDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown add favorite result',
          code: 'unknown_add_favorite',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> removeFavorite({
    required String entityId,
    required FavoriteType type,
  }) async {
    try {
      final result = await _remoteDataSource.removeFavorite(
        entityId: entityId,
        entityType: _typeToApi(type),
      );

      if (result is Success<void>) {
        await _cacheManager.remove(_favoritesCacheKeyPaged(0, 20));
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown remove favorite result',
          code: 'unknown_remove_favorite',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<FavoriteItemDto>> _fetchFavorites(int page, int size) async {
    final result = await _remoteDataSource.fetchFavorites(
      page: page,
      size: size,
    );

    if (result is Success<List<FavoriteItemDto>>) {
      return result.data;
    }
    if (result is Err<List<FavoriteItemDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown favorites result',
      code: 'unknown_favorites',
    );
  }

  String _typeToApi(FavoriteType type) {
    return switch (type) {
      FavoriteType.place => 'PLACE',
      FavoriteType.liveEvent => 'LIVE_EVENT',
      FavoriteType.news => 'NEWS',
      FavoriteType.post => 'POST',
      FavoriteType.unknown => 'UNKNOWN',
    };
  }

  static const String _favoritesCacheKeyPrefix = 'favorites_list';

  String _favoritesCacheKeyPaged(int page, int size) {
    return '$_favoritesCacheKeyPrefix:p$page:s$size';
  }
}
