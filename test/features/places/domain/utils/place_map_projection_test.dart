import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/places/domain/utils/place_map_projection.dart';

void main() {
  group('resolvePlaceMapCameraTarget', () {
    test('uses the first visible place when user location is unavailable', () {
      final target = resolvePlaceMapCameraTarget(
        places: <PlaceSummary>[
          _place('kyoto', latitude: 35.0116, longitude: 135.7681),
        ],
      );

      expect(target.latitude, 35.0116);
      expect(target.longitude, 135.7681);
      expect(target.source, PlaceMapTargetSource.place);
    });

    test('uses the safe default only when no visible place exists', () {
      final target = resolvePlaceMapCameraTarget(
        places: const <PlaceSummary>[],
      );

      expect(target, safePlaceMapCameraTarget);
      expect(target.source, PlaceMapTargetSource.safeDefault);
    });
  });

  group('resolveVisibleSelectedPlace', () {
    test('returns the current list instance with the selected ID', () {
      final current = _place('selected', latitude: 35.0, longitude: 139.0);

      final resolved = resolveVisibleSelectedPlace(
        selectedPlaceId: 'selected',
        visiblePlaces: <PlaceSummary>[current],
      );

      expect(identical(resolved, current), isTrue);
    });

    test('hides a selection absent from the filtered project list', () {
      final resolved = resolveVisibleSelectedPlace(
        selectedPlaceId: 'stale-project-place',
        visiblePlaces: <PlaceSummary>[
          _place('current-project-place', latitude: 34.7, longitude: 135.5),
        ],
      );

      expect(resolved, isNull);
    });
  });
}

PlaceSummary _place(
  String id, {
  required double latitude,
  required double longitude,
}) {
  return PlaceSummary(
    id: id,
    name: id,
    address: '',
    latitude: latitude,
    longitude: longitude,
  );
}
