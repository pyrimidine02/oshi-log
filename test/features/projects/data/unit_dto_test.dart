import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/projects/data/dto/unit_dto.dart';

void main() {
  test('UnitDto parses flexible keys', () {
    final json = {'unitId': 'unit-1', 'name': '밴드 A', 'bandCode': 'band-a'};

    final dto = UnitDto.fromJson(json);
    expect(dto.id, 'unit-1');
    expect(dto.displayName, '밴드 A');
    expect(dto.code, 'band-a');
  });

  test('UnitDto preserves unknown member count from list responses', () {
    final dto = UnitDto.fromJson({
      'unitId': 'unit-1',
      'name': '밴드 A',
      'bandCode': 'band-a',
      'members': null,
    });

    expect(dto.members, isEmpty);
    expect(dto.memberCount, isNull);
    expect(UnitDto.fromJson(dto.toJson()).memberCount, isNull);
  });

  test('UnitDto parses member count when the API supplies it', () {
    final dto = UnitDto.fromJson({
      'unitId': 'unit-1',
      'name': '밴드 A',
      'bandCode': 'band-a',
      'memberCount': 5,
    });

    expect(dto.memberCount, 5);
    expect(UnitDto.fromJson(dto.toJson()).memberCount, 5);
  });

  test('UnitDto derives member count from detail members', () {
    final dto = UnitDto.fromJson({
      'unitId': 'unit-1',
      'name': '밴드 A',
      'bandCode': 'band-a',
      'members': [
        {'id': 'member-1', 'characterName': 'Tomori'},
        {'id': 'member-2', 'characterName': 'Anon'},
      ],
    });

    expect(dto.members, hasLength(2));
    expect(dto.memberCount, 2);
  });
}
