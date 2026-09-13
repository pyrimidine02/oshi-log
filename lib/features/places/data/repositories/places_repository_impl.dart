/// EN: Places repository implementation with caching policies.
/// KO: 캐시 정책을 포함한 장소 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/place_comment_entities.dart';
import '../../domain/entities/place_entities.dart';
import '../../domain/entities/place_guide_entities.dart';
import '../../domain/entities/place_region_entities.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_data_source.dart';
import '../dto/place_comment_dto.dart';
import '../dto/place_dto.dart';
import '../dto/place_guide_dto.dart';
import '../dto/place_region_filter_dto.dart';
import '../dto/place_stats_dto.dart';
import '../mappers/place_comment_entities_mappers.dart';
import '../mappers/place_entities_mappers.dart';
import '../mappers/place_guide_entities_mappers.dart';
import '../mappers/place_region_entities_mappers.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl({
    required PlacesRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final PlacesRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<PlaceSummary>>> getPlaces({
    required String projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _listCacheKey(projectId, unitIds, page, size);
    // EN: Use cacheFirst — place location data is essentially static.
    // KO: cacheFirst 사용 — 장소 위치 데이터는 사실상 정적 데이터.
    final profile = CacheProfiles.placesStaticList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PlaceSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPlaces(projectId, unitIds, page, size),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PlaceSummaryDto.fromJson)
                .toList();
          }
          return <PlaceSummaryDto>[];
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
  Future<Result<List<PlaceSummary>>> getAllPlaces({
    required String projectId,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    final cacheKey = _allCacheKey(projectId, unitIds);
    // EN: Use cacheFirst — place location data is essentially static.
    // KO: cacheFirst 사용 — 장소 위치 데이터는 사실상 정적 데이터.
    final profile = CacheProfiles.placesStaticList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PlaceSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchAllPlaces(projectId, unitIds),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PlaceSummaryDto.fromJson)
                .toList();
          }
          return <PlaceSummaryDto>[];
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
  Future<Result<RegionFilterOptions>> getRegionFilterOptions({
    required String projectId,
    String language = 'ko',
    int minPlaceCount = 1,
    bool hierarchical = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'places_regions_available_${projectId}_$language'
        '_${minPlaceCount}_$hierarchical';
    final profile = CacheProfiles.placesStaticList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<RegionFilterOptionsDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchRegionFilterOptions(
          projectId,
          language,
          minPlaceCount,
          hierarchical,
        ),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => RegionFilterOptionsDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PlaceSummary>>> getPlacesByRegionFilter({
    required String projectId,
    required List<String> regionCodes,
    bool includeChildren = true,
    List<String> placeTypes = const [],
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    List<String> sort = const [],
  }) async {
    final regions = regionCodes.join(',');
    final types = placeTypes.isEmpty ? 'all' : placeTypes.join(',');
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    final sortKey = sort.isEmpty ? 'default' : sort.join(',');
    final cacheKey =
        'places_region:$projectId:$regions:$includeChildren:$types:$units:$sortKey';
    // EN: Use cacheFirst — place location data is essentially static.
    // KO: cacheFirst 사용 — 장소 위치 데이터는 사실상 정적 데이터.
    const profile = CacheProfiles.placesStaticList;

    try {
      final cacheResult = await _cacheManager.resolve<List<PlaceSummaryDto>>(
        key: cacheKey,
        policy: profile.readPolicy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchAllPlacesByRegionFilter(
          projectId: projectId,
          regionCodes: regionCodes,
          includeChildren: includeChildren,
          placeTypes: placeTypes,
          unitIds: unitIds,
          sort: sort,
        ),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PlaceSummaryDto.fromJson)
                .toList();
          }
          return <PlaceSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<RegionMapBounds>> getRegionMapBounds({
    required String projectId,
    required String regionCode,
    bool includeChildren = true,
  }) async {
    final cacheKey = 'region_bounds:$projectId:$regionCode:$includeChildren';
    // EN: Use cacheFirst — region bounds are static geographic data.
    // KO: cacheFirst 사용 — 지역 경계는 정적 지리 데이터.
    const profile = CacheProfiles.placesStaticList;

    try {
      final cacheResult = await _cacheManager.resolve<RegionMapBoundsDto>(
        key: cacheKey,
        policy: profile.readPolicy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () =>
            _fetchRegionMapBoundsDto(projectId, regionCode, includeChildren),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => RegionMapBoundsDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<RegionMapBoundsDto> _fetchRegionMapBoundsDto(
    String projectId,
    String regionCode,
    bool includeChildren,
  ) async {
    final result = await _remoteDataSource.fetchRegionMapBounds(
      projectId: projectId,
      regionCode: regionCode,
      includeChildren: includeChildren,
    );

    if (result is Success<RegionMapBoundsDto>) {
      return result.data;
    }
    if (result is Err<RegionMapBoundsDto>) {
      throw result.failure;
    }
    throw const UnknownFailure('Unknown region bounds result');
  }

  @override
  Future<Result<PlaceDetail>> getPlaceDetail({
    required String projectId,
    required String placeId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _detailCacheKey(projectId, placeId);
    // EN: Use staleWhileRevalidate for place detail — show cached data first.
    // KO: 장소 상세에 staleWhileRevalidate 사용 — 캐시 먼저 표시.
    final profile = CacheProfiles.placesDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<PlaceDetailDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPlaceDetail(projectId, placeId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => PlaceDetailDto.fromJson(json),
      );

      PlaceStatsDto? stats;
      try {
        stats = await _fetchPlaceStats(projectId, placeId);
      } catch (_) {
        stats = null;
      }

      return Result.success(cacheResult.data.toDomain(stats: stats));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<PlaceSummary>>> getPlacesWithinBounds({
    required String projectId,
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    // EN: Round coordinates to 3 decimals (~111m) for stable cache keys.
    // KO: 안정적인 캐시 키를 위해 좌표를 소수점 3자리로 반올림 (~111m).
    final sw = '${swLat.toStringAsFixed(3)},${swLng.toStringAsFixed(3)}';
    final ne = '${neLat.toStringAsFixed(3)},${neLng.toStringAsFixed(3)}';
    final cacheKey = 'places_bounds:$projectId:$sw:$ne:$units';
    // EN: Use cacheFirst — place locations rarely change.
    // KO: cacheFirst 사용 — 장소 위치는 거의 변경되지 않음.
    final profile = CacheProfiles.placesStaticList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PlaceSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchPlacesWithinBounds(
          projectId,
          swLat,
          swLng,
          neLat,
          neLng,
          unitIds,
        ),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PlaceSummaryDto.fromJson)
                .toList();
          }
          return <PlaceSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PlaceSummary>>> getNearbyPlaces({
    required String projectId,
    required double latitude,
    required double longitude,
    double? radiusKm,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    // EN: Round coordinates to 3 decimals (~111m) for stable cache keys.
    // KO: 안정적인 캐시 키를 위해 좌표를 소수점 3자리로 반올림 (~111m).
    final coords =
        '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
    final radius = radiusKm?.toStringAsFixed(1) ?? 'default';
    final cacheKey = 'places_nearby:$projectId:$coords:$radius:$units';
    // EN: Use cacheFirst — place locations rarely change.
    // KO: cacheFirst 사용 — 장소 위치는 거의 변경되지 않음.
    final profile = CacheProfiles.placesStaticList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<PlaceSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchNearbyPlaces(
          projectId,
          latitude,
          longitude,
          radiusKm,
          unitIds,
        ),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(PlaceSummaryDto.fromJson)
                .toList();
          }
          return <PlaceSummaryDto>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PlaceGuideSummary>>> getPlaceGuides({
    required String placeId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'place_guides_${placeId}_${page}_$size';
    final profile = CacheProfiles.placeGuides;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<PlaceGuideSummaryDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchPlaceGuides(placeId, page, size),
            toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(PlaceGuideSummaryDto.fromJson)
                    .toList();
              }
              return <PlaceGuideSummaryDto>[];
            },
          );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();

      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PlaceComment>>> getPlaceComments({
    required String placeId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'place_comments_${placeId}_${page}_$size';
    final profile = CacheProfiles.placeComments;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<PlaceCommentDetailDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchPlaceComments(placeId, page, size),
            toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(PlaceCommentDetailDto.fromJson)
                    .toList();
              }
              return <PlaceCommentDetailDto>[];
            },
          );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();

      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<PlaceComment>> createPlaceComment({
    required String placeId,
    required String body,
    required List<String> photoUploadIds,
    bool isPublic = true,
    List<String> tags = const [],
  }) async {
    try {
      final request = CreatePlaceCommentRequestDto(
        bodyMarkdown: body,
        tags: tags,
        photoUploadIds: photoUploadIds,
        isPublic: isPublic,
      );
      final result = await _remoteDataSource.createPlaceComment(
        placeId: placeId,
        request: request,
      );
      if (result is Success<PlaceCommentDetailDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PlaceCommentDetailDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure('Unknown place comment result'),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deletePlaceComment({
    required String placeId,
    required String commentId,
  }) async {
    try {
      final result = await _remoteDataSource.deletePlaceComment(
        placeId: placeId,
        commentId: commentId,
      );
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return const Result.failure(
        UnknownFailure('Unknown place comment delete result'),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<List<PlaceSummaryDto>> _fetchPlaces(
    String projectId,
    List<String> unitIds,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchPlaces(
      projectId: projectId,
      unitIds: unitIds,
      page: page,
      size: size,
    );

    if (result is Success<List<PlaceSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PlaceSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown places list result',
      code: 'unknown_places_list',
    );
  }

  Future<List<PlaceSummaryDto>> _fetchAllPlaces(
    String projectId,
    List<String> unitIds,
  ) async {
    const pageSize = ApiPagination.maxSize;
    const maxPages = 50;
    final all = <PlaceSummaryDto>[];
    var page = 0;

    while (page < maxPages) {
      final result = await _remoteDataSource.fetchPlaces(
        projectId: projectId,
        unitIds: unitIds,
        page: page,
        size: pageSize,
      );

      if (result is Success<List<PlaceSummaryDto>>) {
        final batch = result.data;
        all.addAll(batch);
        if (batch.length < pageSize) {
          break;
        }
        page += 1;
        continue;
      }
      if (result is Err<List<PlaceSummaryDto>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown places list result',
        code: 'unknown_places_list',
      );
    }

    return all;
  }

  Future<List<PlaceSummaryDto>> _fetchAllPlacesByRegionFilter({
    required String projectId,
    required List<String> regionCodes,
    bool includeChildren = true,
    List<String> placeTypes = const [],
    List<String> unitIds = const [],
    List<String> sort = const [],
  }) async {
    const pageSize = ApiPagination.maxSize;
    const maxPages = 50;
    final all = <PlaceSummaryDto>[];
    var page = 0;

    while (page < maxPages) {
      final result = await _remoteDataSource.fetchPlacesByRegionFilter(
        projectId: projectId,
        regionCodes: regionCodes,
        includeChildren: includeChildren,
        placeTypes: placeTypes,
        unitIds: unitIds,
        page: page,
        size: pageSize,
        sort: sort,
      );

      if (result is Success<List<PlaceSummaryDto>>) {
        final batch = result.data;
        all.addAll(batch);
        if (batch.length < pageSize) {
          break;
        }
        page += 1;
        continue;
      }
      if (result is Err<List<PlaceSummaryDto>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown region filter result',
        code: 'unknown_region_filter',
      );
    }

    return all;
  }

  Future<List<PlaceSummaryDto>> _fetchPlacesWithinBounds(
    String projectId,
    double swLat,
    double swLng,
    double neLat,
    double neLng,
    List<String> unitIds,
  ) async {
    final result = await _remoteDataSource.fetchPlacesWithinBounds(
      projectId: projectId,
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
      unitIds: unitIds,
    );

    if (result is Success<List<PlaceSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PlaceSummaryDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure('Unknown within-bounds result');
  }

  Future<List<PlaceSummaryDto>> _fetchNearbyPlaces(
    String projectId,
    double latitude,
    double longitude,
    double? radiusKm,
    List<String> unitIds,
  ) async {
    final result = await _remoteDataSource.fetchNearbyPlaces(
      projectId: projectId,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      unitIds: unitIds,
    );

    if (result is Success<List<PlaceSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PlaceSummaryDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure('Unknown nearby result');
  }

  Future<List<PlaceGuideSummaryDto>> _fetchPlaceGuides(
    String placeId,
    int page,
    int size,
  ) async {
    // EN: Prefer high-priority guides endpoint for pinned content.
    // KO: 고정 콘텐츠 우선을 위해 high-priority 가이드 엔드포인트를 우선 사용합니다.
    if (page == 0) {
      final priorityResult = await _remoteDataSource
          .fetchHighPriorityPlaceGuides(placeId: placeId, limit: size);
      if (priorityResult is Success<List<PlaceGuideSummaryDto>>) {
        return priorityResult.data;
      }
      if (priorityResult is Err<List<PlaceGuideSummaryDto>> &&
          !_shouldFallbackFromHighPriorityGuides(priorityResult.failure)) {
        throw priorityResult.failure;
      }
    }

    final result = await _remoteDataSource.fetchPlaceGuides(
      placeId: placeId,
      page: page,
      size: size,
    );
    if (result is Success<List<PlaceGuideSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<PlaceGuideSummaryDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure('Unknown place guides result');
  }

  bool _shouldFallbackFromHighPriorityGuides(Failure failure) {
    // EN: Fallback to legacy guides endpoint on contract-shape differences.
    // KO: 계약 형태 차이(엔드포인트 미지원/파라미터 불일치)에서는 레거시 엔드포인트로 폴백합니다.
    return failure.code == '400' ||
        failure.code == '404' ||
        failure.code == '405' ||
        failure.code == '422';
  }

  Future<List<PlaceCommentDetailDto>> _fetchPlaceComments(
    String placeId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchPlaceComments(
      placeId: placeId,
      page: page,
      size: size,
    );
    if (result is Success<List<PlaceCommentDetailDto>>) {
      return result.data;
    }
    if (result is Err<List<PlaceCommentDetailDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure('Unknown place comments result');
  }

  Future<PlaceDetailDto> _fetchPlaceDetail(
    String projectId,
    String placeId,
  ) async {
    final result = await _remoteDataSource.fetchPlaceDetail(
      projectId: projectId,
      placeId: placeId,
    );

    if (result is Success<PlaceDetailDto>) {
      return result.data;
    }
    if (result is Err<PlaceDetailDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown place detail result',
      code: 'unknown_place_detail',
    );
  }

  Future<RegionFilterOptionsDto> _fetchRegionFilterOptions(
    String projectId,
    String language,
    int minPlaceCount,
    bool hierarchical,
  ) async {
    final result = await _remoteDataSource.fetchRegionFilterOptions(
      projectId: projectId,
      language: language,
      minPlaceCount: minPlaceCount,
      hierarchical: hierarchical,
    );

    if (result is Success<RegionFilterOptionsDto>) {
      return result.data;
    }
    if (result is Err<RegionFilterOptionsDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown region filter options result',
      code: 'unknown_region_filter_options',
    );
  }

  Future<PlaceStatsDto> _fetchPlaceStats(
    String projectId,
    String placeId,
  ) async {
    final result = await _remoteDataSource.fetchPlaceStats(
      projectId: projectId,
      placeId: placeId,
    );

    if (result is Success<PlaceStatsDto>) {
      return result.data;
    }
    if (result is Err<PlaceStatsDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown place stats result',
      code: 'unknown_place_stats',
    );
  }

  String _listCacheKey(
    String projectId,
    List<String> unitIds,
    int page,
    int size,
  ) {
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    return 'places_list:$projectId:$units:p$page:s$size';
  }

  String _allCacheKey(String projectId, List<String> unitIds) {
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    return 'places_all:$projectId:$units';
  }

  String _detailCacheKey(String projectId, String placeId) {
    // EN: Version the key so pre-contract caches cannot hide related units.
    // KO: 계약 이전 캐시가 관련 유닛을 숨기지 않도록 키 버전을 올립니다.
    return 'place_detail:v2:$projectId:$placeId';
  }
}
