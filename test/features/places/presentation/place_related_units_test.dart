import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/places/presentation/utils/place_related_units.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';

void main() {
  const projectUnits = [
    Unit(id: 'unit-place', code: 'place-band', displayName: 'Place band'),
    Unit(id: 'unit-other', code: 'other-band', displayName: 'Other band'),
  ];

  test('filters project units to the units attached to the place', () {
    const place = PlaceDetail(
      id: 'place-1',
      name: 'Place',
      address: 'Tokyo',
      types: [],
      unitIds: ['unit-place'],
    );

    final relatedUnits = unitsForPlace(place, projectUnits);

    expect(relatedUnits.map((unit) => unit.id), ['unit-place']);
  });

  test('does not fall back to all project units when place IDs are empty', () {
    const place = PlaceDetail(
      id: 'place-2',
      name: 'Unassociated place',
      address: 'Tokyo',
      types: [],
    );

    expect(unitsForPlace(place, projectUnits), isEmpty);
  });
}
