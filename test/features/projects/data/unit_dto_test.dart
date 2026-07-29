import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/projects/data/dto/unit_dto.dart';

void main() {
  test('UnitDto parses flexible keys', () {
    final json = {
      'unitId': 'unit-1',
      'name': '밴드 A',
      'bandCode': 'band-a',
    };

    final dto = UnitDto.fromJson(json);
    expect(dto.id, 'unit-1');
    expect(dto.displayName, '밴드 A');
    expect(dto.code, 'band-a');
  });
}
