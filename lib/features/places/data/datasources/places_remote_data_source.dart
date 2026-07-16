/// EN: Remote data source for places API.
/// KO: 장소 API 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/place_dto.dart';
import '../dto/place_guide_dto.dart';
import '../dto/place_comment_dto.dart';
import '../dto/place_region_filter_dto.dart';
import '../dto/place_stats_dto.dart';

class PlacesRemoteDataSource {
  PlacesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Fetch paginated places for a project.
  /// KO: 프로젝트의 페이지네이션된 장소를 조회합니다.
  Future<Result<List<PlaceSummaryDto>>> fetchPlaces({
    required String projectId,
    List<String> unitIds = const [],
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PlaceSummaryDto>>(
      ApiEndpoints.places(projectId),
      queryParameters: {
        'page': page,
        'size': size,
        if (unitIds.isNotEmpty) 'unitIds': unitIds,
      },
      fromJson: (json) => _decodePlaceList(json),
    );
  }

  /// EN: Fetch region filter options for a project.
  /// KO: 프로젝트 지역 필터 옵션을 조회합니다.
  Future<Result<RegionFilterOptionsDto>> fetchRegionFilterOptions({
    required String projectId,
    String language = 'ko',
    int minPlaceCount = 1,
    bool hierarchical = true,
  }) {
    return _apiClient.get<RegionFilterOptionsDto>(
      ApiEndpoints.placesRegionsAvailable(projectId),
      queryParameters: {
        'language': language,
        'minPlaceCount': minPlaceCount,
        'hierarchical': hierarchical,
      },
      fromJson: (json) =>
          RegionFilterOptionsDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch places filtered by region codes.
  /// KO: 지역 코드로 필터링된 장소 목록을 조회합니다.
  Future<Result<List<PlaceSummaryDto>>> fetchPlacesByRegionFilter({
    required String projectId,
    required List<String> regionCodes,
    bool includeChildren = true,
    List<String> placeTypes = const [],
    List<String> unitIds = const [],
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
    List<String> sort = const [],
  }) {
    return _apiClient.get<List<PlaceSummaryDto>>(
      ApiEndpoints.placesRegionsFilter(projectId),
      queryParameters: {
        'regionCodes': regionCodes.join(','),
        'includeChildren': includeChildren,
        if (placeTypes.isNotEmpty) 'placeTypes': placeTypes.join(','),
        if (unitIds.isNotEmpty) 'unitIds': unitIds.join(','),
        'page': page,
        'size': size,
        if (sort.isNotEmpty) 'sort': sort,
      },
      fromJson: (json) => _decodePlaceList(json),
    );
  }

  /// EN: Fetch map bounds for a region.
  /// KO: 지역 지도 경계를 조회합니다.
  Future<Result<RegionMapBoundsDto>> fetchRegionMapBounds({
    required String projectId,
    required String regionCode,
    bool includeChildren = true,
  }) {
    return _apiClient.get<RegionMapBoundsDto>(
      ApiEndpoints.placesRegionsMapBounds(projectId),
      queryParameters: {
        'regionCode': regionCode,
        'includeChildren': includeChildren,
      },
      fromJson: (json) =>
          RegionMapBoundsDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch place detail.
  /// KO: 장소 상세를 조회합니다.
  Future<Result<PlaceDetailDto>> fetchPlaceDetail({
    required String projectId,
    required String placeId,
  }) {
    return _apiClient.get<PlaceDetailDto>(
      ApiEndpoints.place(projectId, placeId),
      fromJson: (json) => PlaceDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch published guides for a place.
  /// KO: 장소 발행 가이드를 조회합니다.
  Future<Result<List<PlaceGuideSummaryDto>>> fetchPlaceGuides({
    required String placeId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PlaceGuideSummaryDto>>(
      ApiEndpoints.placeGuides(placeId),
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) => _decodeGuideList(json),
    );
  }

  /// EN: Fetch high-priority guides (pinned/featured) for a place.
  /// KO: 장소의 고우선순위(고정/추천) 가이드를 조회합니다.
  Future<Result<List<PlaceGuideSummaryDto>>> fetchHighPriorityPlaceGuides({
    required String placeId,
    int limit = 20,
  }) {
    return _apiClient.get<List<PlaceGuideSummaryDto>>(
      ApiEndpoints.placeGuidesHighPriority(placeId),
      queryParameters: {'limit': limit},
      fromJson: (json) => _decodeGuideList(json),
    );
  }

  /// EN: Fetch comments for a place.
  /// KO: 장소 댓글을 조회합니다.
  Future<Result<List<PlaceCommentDetailDto>>> fetchPlaceComments({
    required String placeId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<PlaceCommentDetailDto>>(
      ApiEndpoints.placeComments(placeId),
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) => _decodeCommentList(json),
    );
  }

  /// EN: Create a new comment for a place.
  /// KO: 장소 댓글을 생성합니다.
  Future<Result<PlaceCommentDetailDto>> createPlaceComment({
    required String placeId,
    required CreatePlaceCommentRequestDto request,
  }) {
    return _apiClient.post<PlaceCommentDetailDto>(
      ApiEndpoints.placeComments(placeId),
      data: request.toJson(),
      fromJson: (json) {
        final response = PlaceCommentResponseDto.fromJson(
          json as Map<String, dynamic>,
        );
        return response.comment;
      },
    );
  }

  /// EN: Delete a place comment.
  /// KO: 장소 댓글을 삭제합니다.
  Future<Result<void>> deletePlaceComment({
    required String placeId,
    required String commentId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.placeComment(placeId, commentId),
      fromJson: (_) {},
    );
  }

  /// EN: Fetch places within geographic bounds (for map view).
  /// KO: 지리적 경계 내 장소를 조회합니다 (지도 뷰용).
  Future<Result<List<PlaceSummaryDto>>> fetchPlacesWithinBounds({
    required String projectId,
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    List<String> unitIds = const [],
  }) {
    return _apiClient.get<List<PlaceSummaryDto>>(
      ApiEndpoints.placesWithinBounds(projectId),
      queryParameters: {
        // EN: Keep both legacy and v3 parameter names for compatibility.
        // KO: 호환성을 위해 레거시/v3 파라미터를 모두 전송합니다.
        'south': swLat,
        'west': swLng,
        'north': neLat,
        'east': neLng,
        'swLat': swLat,
        'swLng': swLng,
        'neLat': neLat,
        'neLng': neLng,
        if (unitIds.isNotEmpty) 'unitIds': unitIds,
      },
      fromJson: (json) => _decodePlaceList(json),
    );
  }

  /// EN: Fetch nearby places relative to a coordinate.
  /// KO: 좌표 기준 인근 장소를 조회합니다.
  Future<Result<List<PlaceSummaryDto>>> fetchNearbyPlaces({
    required String projectId,
    required double latitude,
    required double longitude,
    double? radiusKm,
    List<String> unitIds = const [],
  }) {
    return _apiClient.get<List<PlaceSummaryDto>>(
      ApiEndpoints.placesNearby(projectId),
      queryParameters: {
        // EN: Send both alias pairs (`lat`/`lon`, `latitude`/`longitude`).
        // KO: 별칭 파라미터(`lat`/`lon`, `latitude`/`longitude`)를 함께 전송합니다.
        'lat': latitude,
        'lon': longitude,
        'latitude': latitude,
        'longitude': longitude,
        if (radiusKm != null) 'radius': radiusKm,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (unitIds.isNotEmpty) 'unitIds': unitIds,
      },
      fromJson: (json) => _decodePlaceList(json),
    );
  }

  /// EN: Fetch visit/favorite stats for a place using rankings endpoints.
  /// KO: 랭킹 엔드포인트를 사용해 장소 방문/즐겨찾기 통계를 조회합니다.
  Future<Result<PlaceStatsDto>> fetchPlaceStats({
    required String projectId,
    required String placeId,
  }) {
    return _apiClient.get<PlaceStatsDto>(
      ApiEndpoints.placeStats(projectId, placeId),
      fromJson: (json) => PlaceStatsDto.fromJson(json as Map<String, dynamic>),
    );
  }
}

List<PlaceSummaryDto> _decodePlaceList(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(PlaceSummaryDto.fromJson)
        .toList();
  }
  if (json is Map<String, dynamic>) {
    const listKeys = ['items', 'content', 'data', 'results'];
    for (final key in listKeys) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map(PlaceSummaryDto.fromJson)
            .toList();
      }
    }
  }
  return <PlaceSummaryDto>[];
}

List<PlaceGuideSummaryDto> _decodeGuideList(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(PlaceGuideSummaryDto.fromJson)
        .toList();
  }
  if (json is Map<String, dynamic>) {
    final guides = json['guides'];
    if (guides is List) {
      return guides
          .whereType<Map<String, dynamic>>()
          .map(PlaceGuideSummaryDto.fromJson)
          .toList();
    }
  }
  return <PlaceGuideSummaryDto>[];
}

List<PlaceCommentDetailDto> _decodeCommentList(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(PlaceCommentDetailDto.fromJson)
        .toList();
  }
  if (json is Map<String, dynamic>) {
    final comments = json['comments'];
    if (comments is List) {
      return comments
          .whereType<Map<String, dynamic>>()
          .map(PlaceCommentDetailDto.fromJson)
          .toList();
    }
  }
  return <PlaceCommentDetailDto>[];
}
