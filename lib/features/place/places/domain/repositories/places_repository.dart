/// EN: Places repository interface.
/// KO: 장소 리포지토리 인터페이스.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_comment_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_guide_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_region_entities.dart';

abstract class PlacesRepository {
  /// EN: Get paginated places for a project.
  /// KO: 프로젝트의 페이지네이션된 장소를 가져옵니다.
  Future<Result<List<PlaceSummary>>> getPlaces({
    required String projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Get all places for a project (fetch all pages).
  /// KO: 프로젝트의 전체 장소를 가져옵니다 (전체 페이지 조회).
  Future<Result<List<PlaceSummary>>> getAllPlaces({
    required String projectId,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  });

  /// EN: Get region filter options for the project.
  /// KO: 프로젝트 지역 필터 옵션을 가져옵니다.
  Future<Result<RegionFilterOptions>> getRegionFilterOptions({
    required String projectId,
    String language = 'ko',
    int minPlaceCount = 1,
    bool hierarchical = true,
    bool forceRefresh = false,
  });

  /// EN: Get places filtered by region codes.
  /// KO: 지역 코드로 필터링된 장소 목록을 가져옵니다.
  Future<Result<List<PlaceSummary>>> getPlacesByRegionFilter({
    required String projectId,
    required List<String> regionCodes,
    bool includeChildren = true,
    List<String> placeTypes = const [],
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    List<String> sort = const [],
  });

  /// EN: Get map bounds for a region.
  /// KO: 지역 지도 경계를 가져옵니다.
  Future<Result<RegionMapBounds>> getRegionMapBounds({
    required String projectId,
    required String regionCode,
    bool includeChildren = true,
  });

  /// EN: Get place detail.
  /// KO: 장소 상세를 가져옵니다.
  Future<Result<PlaceDetail>> getPlaceDetail({
    required String projectId,
    required String placeId,
    bool forceRefresh = false,
  });

  /// EN: Get places within geographic bounds (for map view).
  /// KO: 지리적 경계 내 장소를 가져옵니다 (지도 뷰용).
  Future<Result<List<PlaceSummary>>> getPlacesWithinBounds({
    required String projectId,
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  });

  /// EN: Get nearby places relative to a coordinate.
  /// KO: 좌표 기준 인근 장소를 가져옵니다.
  Future<Result<List<PlaceSummary>>> getNearbyPlaces({
    required String projectId,
    required double latitude,
    required double longitude,
    double? radiusKm,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  });

  /// EN: Get published guides for a place.
  /// KO: 장소 발행 가이드를 가져옵니다.
  Future<Result<List<PlaceGuideSummary>>> getPlaceGuides({
    required String placeId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Get comments for a place.
  /// KO: 장소 댓글을 가져옵니다.
  Future<Result<List<PlaceComment>>> getPlaceComments({
    required String placeId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Create a new comment for a place.
  /// KO: 장소 댓글을 생성합니다.
  Future<Result<PlaceComment>> createPlaceComment({
    required String placeId,
    required String body,
    required List<String> photoUploadIds,
    bool isPublic = true,
    List<String> tags = const [],
  });

  /// EN: Delete a place comment.
  /// KO: 장소 댓글을 삭제합니다.
  Future<Result<void>> deletePlaceComment({
    required String placeId,
    required String commentId,
  });
}
