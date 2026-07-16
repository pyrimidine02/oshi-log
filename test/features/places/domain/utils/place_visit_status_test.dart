import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/places/domain/utils/place_visit_status.dart';

void main() {
  test('applyVisitedPlaceIds returns immutable enriched copies', () {
    const original = PlaceSummary(
      id: 'live-house-1',
      name: 'Live House',
      address: 'Tokyo',
      latitude: 35.0,
      longitude: 139.0,
    );

    final enriched = applyVisitedPlaceIds(
      const [original],
      const {'live-house-1'},
    );

    expect(original.isVerified, isFalse);
    expect(enriched.single.isVerified, isTrue);
    expect(enriched.single, isNot(same(original)));
    expect(() => enriched.add(original), throwsUnsupportedError);
  });

  test('keeps an existing verified state when visit data is incomplete', () {
    const original = PlaceSummary(
      id: 'station-1',
      name: 'Station',
      address: 'Kanagawa',
      latitude: 35.0,
      longitude: 139.0,
      isVerified: true,
    );

    final enriched = applyVisitedPlaceIds(const [original], const {});

    expect(enriched.single.isVerified, isTrue);
  });
}
