import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/places/domain/utils/place_type_search.dart';

void main() {
  group('normalizePlaceSearchText', () {
    test('normalizes case and separators', () {
      expect(
        normalizePlaceSearchText(' Filming_Location '),
        equals('filming location'),
      );
    });
  });

  group('matchesPlaceTypeQuery', () {
    test('matches korean synonym for filming location', () {
      final matched = matchesPlaceTypeQuery(
        query: '성지',
        types: const ['filming_location'],
      );
      expect(matched, isTrue);
    });

    test('matches compact english query for underscored type', () {
      final matched = matchesPlaceTypeQuery(
        query: 'livehouse',
        types: const ['live_house'],
      );
      expect(matched, isTrue);
    });

    test('returns false when no type matches query', () {
      final matched = matchesPlaceTypeQuery(
        query: '공원',
        types: const ['filming_location'],
      );
      expect(matched, isFalse);
    });
  });

  group('placeTypeLabel', () {
    test('returns localized label for known type', () {
      expect(placeTypeLabel('filming_location'), equals('촬영지'));
    });

    test('falls back to title-cased text for unknown type', () {
      expect(placeTypeLabel('special_spot'), equals('Special Spot'));
    });
  });
}
