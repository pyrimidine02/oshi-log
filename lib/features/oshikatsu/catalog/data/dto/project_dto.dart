/// EN: Project DTO for project list/detail.
/// KO: 프로젝트 목록/상세 DTO.
library;

class ProjectDto {
  const ProjectDto({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.defaultTimezone,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final String defaultTimezone;

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: _string(json, ['id', 'projectId']) ?? '',
      code: _string(json, ['code', 'slug']) ?? '',
      name: _string(json, ['name']) ?? '프로젝트',
      status: _string(json, ['status']) ?? 'UNKNOWN',
      defaultTimezone: _string(json, ['defaultTimezone']) ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'status': status,
      'defaultTimezone': defaultTimezone,
    };
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}
