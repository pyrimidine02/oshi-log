/// EN: Truthful, immutable distance projection for place summaries.
/// KO: 장소 요약을 위한 정직한 불변 거리 투영입니다.
library;

import 'dart:math' as math;

import '../entities/place_entities.dart';

/// EN: Coordinate captured from the user's real location provider.
/// KO: 사용자의 실제 위치 프로바이더에서 얻은 좌표입니다.
class PlaceCoordinate {
  const PlaceCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// EN: Keeps server order when location is unavailable. With a real location,
///     returns a new nearest-first list with derived distance labels.
/// KO: 위치가 없으면 서버 순서를 유지합니다. 실제 위치가 있으면 계산한 거리
///     라벨을 포함한 새 가까운 순 목록을 반환합니다.
List<PlaceSummary> orderPlacesForUserLocation(
  Iterable<PlaceSummary> places, {
  required PlaceCoordinate? userLocation,
}) {
  if (userLocation == null) {
    return List<PlaceSummary>.unmodifiable(places);
  }

  final measured =
      places
          .map(
            (place) => (
              place: place,
              distance: _haversineDistance(
                userLocation.latitude,
                userLocation.longitude,
                place.latitude,
                place.longitude,
              ),
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => left.distance.compareTo(right.distance));

  return List<PlaceSummary>.unmodifiable(
    measured.map(
      (item) =>
          item.place.copyWith(distanceLabel: _formatDistance(item.distance)),
    ),
  );
}

double _haversineDistance(
  double latitude1,
  double longitude1,
  double latitude2,
  double longitude2,
) {
  const earthRadius = 6371000.0;
  final latitudeDelta = _toRadians(latitude2 - latitude1);
  final longitudeDelta = _toRadians(longitude2 - longitude1);
  final value =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(_toRadians(latitude1)) *
          math.cos(_toRadians(latitude2)) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final arc = 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value));
  return earthRadius * arc;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()}m';
  final kilometers = meters / 1000;
  if (kilometers < 10) return '${kilometers.toStringAsFixed(1)}km';
  return '${kilometers.round()}km';
}
