import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/domain/utils/place_marker_style.dart';

void main() {
  group('placeMarkerHueForVisit', () {
    test('returns harbor teal hue for verified (visited) places', () {
      expect(placeMarkerHueForVisit(isVerified: true), 176.0);
    });

    test('returns brand blue hue for unvisited places', () {
      expect(placeMarkerHueForVisit(isVerified: false), 210.0);
    });

    test('visited and unvisited hues are distinct', () {
      expect(
        placeMarkerHueForVisit(isVerified: true),
        isNot(placeMarkerHueForVisit(isVerified: false)),
      );
    });
  });

  group('placeClusterMarkerHue', () {
    test('uses a warm itinerary amber hue', () {
      expect(placeClusterMarkerHue, 38.0);
    });

    test('does not collide with single-pin hues', () {
      expect(
        placeClusterMarkerHue,
        isNot(placeMarkerHueForVisit(isVerified: true)),
      );
      expect(
        placeClusterMarkerHue,
        isNot(placeMarkerHueForVisit(isVerified: false)),
      );
    });
  });
}
