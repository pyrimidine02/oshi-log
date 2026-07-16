/// EN: Pure projections for map camera fallback and selected-place previews.
/// KO: 지도 카메라 대체값과 선택 장소 프리뷰를 위한 순수 투영 함수입니다.
library;

import '../entities/place_entities.dart';

/// EN: Explains which data source produced a map camera target.
/// KO: 지도 카메라 타겟을 만든 데이터 소스를 설명합니다.
enum PlaceMapTargetSource { place, safeDefault }

/// EN: An immutable map camera target independent of map SDK types.
/// KO: 지도 SDK 타입과 독립적인 불변 카메라 타겟입니다.
class PlaceMapCameraTarget {
  const PlaceMapCameraTarget({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final PlaceMapTargetSource source;

  @override
  bool operator ==(Object other) {
    return other is PlaceMapCameraTarget &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, source);
}

/// EN: Stable emergency target used only when there is no visible place.
/// KO: 표시할 장소가 전혀 없을 때만 사용하는 안정적인 비상 타겟입니다.
const safePlaceMapCameraTarget = PlaceMapCameraTarget(
  latitude: 35.681236,
  longitude: 139.767125,
  source: PlaceMapTargetSource.safeDefault,
);

/// EN: Resolves a truthful fallback from the current visible place list.
/// KO: 현재 표시 중인 장소 목록에서 진실한 대체 카메라 타겟을 결정합니다.
PlaceMapCameraTarget resolvePlaceMapCameraTarget({
  required List<PlaceSummary> places,
}) {
  if (places.isEmpty) return safePlaceMapCameraTarget;
  final place = places.first;
  return PlaceMapCameraTarget(
    latitude: place.latitude,
    longitude: place.longitude,
    source: PlaceMapTargetSource.place,
  );
}

/// EN: Re-resolves selection by ID against the current filtered projection.
/// KO: 현재 필터 결과를 기준으로 선택 상태를 ID로 다시 해석합니다.
PlaceSummary? resolveVisibleSelectedPlace({
  required String? selectedPlaceId,
  required List<PlaceSummary> visiblePlaces,
}) {
  if (selectedPlaceId == null || selectedPlaceId.isEmpty) return null;
  for (final place in visiblePlaces) {
    if (place.id == selectedPlaceId) return place;
  }
  return null;
}
