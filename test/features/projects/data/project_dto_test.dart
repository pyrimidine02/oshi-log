import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/projects/data/dto/project_dto.dart';

void main() {
  test('ProjectDto parses flexible keys', () {
    final json = {
      'projectId': 'project-1',
      'name': 'MyGO!!!!!',
      'code': 'mygo',
      'status': 'ACTIVE',
      'defaultTimezone': 'Asia/Tokyo',
    };

    final dto = ProjectDto.fromJson(json);
    expect(dto.id, 'project-1');
    expect(dto.name, 'MyGO!!!!!');
    expect(dto.code, 'mygo');
    expect(dto.status, 'ACTIVE');
    expect(dto.defaultTimezone, 'Asia/Tokyo');
  });
}
