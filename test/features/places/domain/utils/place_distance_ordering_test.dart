import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/places/domain/utils/place_distance_ordering.dart';

void main() {
  group('orderPlacesForUserLocation', () {
    final places = [
      _place('server-first', 35.0, 139.0),
      _place('server-second', 35.68, 139.76),
    ];

    test('preserves server order and labels when location is unavailable', () {
      final result = orderPlacesForUserLocation(places, userLocation: null);

      expect(result.map((place) => place.id), [
        'server-first',
        'server-second',
      ]);
      expect(result.first.distanceLabel, 'server label');
      expect(() => result.add(places.first), throwsUnsupportedError);
    });

    test('returns a new nearest-first projection for a real location', () {
      final result = orderPlacesForUserLocation(
        places,
        userLocation: const PlaceCoordinate(35.68, 139.76),
      );

      expect(result.map((place) => place.id), [
        'server-second',
        'server-first',
      ]);
      expect(result.first.distanceLabel, '0m');
      expect(places.first.distanceLabel, 'server label');
    });
  });
}

PlaceSummary _place(String id, double latitude, double longitude) {
  return PlaceSummary(
    id: id,
    name: id,
    address: '',
    latitude: latitude,
    longitude: longitude,
    distanceLabel: 'server label',
  );
}
