/// EN: DTOs for settings account-tools APIs.
/// KO: 설정 계정 도구 API DTO 모음.
library;

/// EN: Response DTO for the account restoration endpoint.
/// KO: 계정 복구 엔드포인트 응답 DTO.
class RestoreAccountResultDto {
  const RestoreAccountResultDto({
    required this.result,
    required this.restoredAt,
    this.retentionUntil,
  });

  /// EN: Result string, e.g. "RESTORED".
  /// KO: 결과 문자열 (예: "RESTORED").
  final String result;

  /// EN: Timestamp when the account was restored.
  /// KO: 계정이 복구된 시각.
  final DateTime restoredAt;

  /// EN: Date until which user data is retained (nullable).
  /// KO: 사용자 데이터 보존 기한 (nullable).
  final DateTime? retentionUntil;

  factory RestoreAccountResultDto.fromJson(Map<String, dynamic> json) {
    return RestoreAccountResultDto(
      result: json['result'] as String? ?? 'RESTORED',
      restoredAt:
          _dateTime(json, const ['restoredAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      retentionUntil: _dateTime(json, const ['retentionUntil']),
    );
  }
}

class BlockedUserDto {
  const BlockedUserDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) {
    return BlockedUserDto(
      id: _string(json, const ['id', 'userId']) ?? '',
      displayName:
          _string(json, const ['displayName', 'nickname', 'name']) ?? '사용자',
      avatarUrl: _string(json, const [
        'avatarUrl',
        'profileImageUrl',
        'imageUrl',
      ]),
    );
  }
}

class UserBlockDto {
  const UserBlockDto({
    required this.id,
    required this.blockedUser,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final BlockedUserDto blockedUser;
  final String? reason;
  final DateTime createdAt;

  factory UserBlockDto.fromJson(Map<String, dynamic> json) {
    final blockedUserRaw = json['blockedUser'];
    final blockedUserMap = blockedUserRaw is Map<String, dynamic>
        ? blockedUserRaw
        : <String, dynamic>{};

    return UserBlockDto(
      id: _string(json, const ['id']) ?? '',
      blockedUser: BlockedUserDto.fromJson(blockedUserMap),
      reason: _string(json, const ['reason']),
      createdAt:
          _dateTime(json, const ['createdAt', 'blockedAt', 'created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class VerificationAppealDto {
  const VerificationAppealDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.placeId,
    this.description,
    this.evidenceUrls = const <String>[],
    this.reviewerMemo,
    this.resolvedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String? placeId;
  final String reason;
  final String? description;
  final List<String> evidenceUrls;
  final String status;
  final String? reviewerMemo;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory VerificationAppealDto.fromJson(Map<String, dynamic> json) {
    final evidenceRaw = json['evidenceUrls'];
    final evidenceUrls = <String>[];
    if (evidenceRaw is List) {
      evidenceUrls.addAll(
        evidenceRaw
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    return VerificationAppealDto(
      id: _string(json, const ['id']) ?? '',
      targetType: _string(json, const ['targetType']) ?? 'PLACE_VISIT',
      targetId: _string(json, const ['targetId']) ?? '',
      placeId: _string(json, const ['placeId']),
      reason: _string(json, const ['reason']) ?? 'OTHER',
      description: _string(json, const ['description']),
      evidenceUrls: evidenceUrls,
      status: _string(json, const ['status']) ?? 'PENDING',
      reviewerMemo: _string(json, const ['reviewerMemo']),
      createdAt:
          _dateTime(json, const ['createdAt', 'created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      resolvedAt: _dateTime(json, const ['resolvedAt']),
    );
  }
}

class VerificationAppealCreateRequestDto {
  const VerificationAppealCreateRequestDto({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    this.evidenceUrls = const <String>[],
  });

  final String targetType;
  final String targetId;
  final String reason;
  final String? description;
  final List<String> evidenceUrls;

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (evidenceUrls.isNotEmpty) 'evidenceUrls': evidenceUrls,
    };
  }
}

class ProjectRoleRequestDto {
  const ProjectRoleRequestDto({
    required this.id,
    required this.projectId,
    required this.projectCode,
    required this.projectName,
    required this.requestedRole,
    required this.status,
    required this.justification,
    required this.createdAt,
    this.adminMemo,
    this.reviewedAt,
    this.reviewerId,
    this.reviewerName,
  });

  final String id;
  final String projectId;
  final String? projectCode;
  final String? projectName;
  final String requestedRole;
  final String status;
  final String justification;
  final DateTime createdAt;
  final String? adminMemo;
  final DateTime? reviewedAt;
  final String? reviewerId;
  final String? reviewerName;

  factory ProjectRoleRequestDto.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    final projectMap = project is Map<String, dynamic>
        ? project
        : const <String, dynamic>{};
    final reviewer = json['reviewer'];
    final reviewerMap = reviewer is Map<String, dynamic>
        ? reviewer
        : const <String, dynamic>{};

    return ProjectRoleRequestDto(
      id: _string(json, const ['id', 'requestId']) ?? '',
      projectId:
          _string(json, const ['projectId']) ??
          _string(projectMap, const ['id']) ??
          '',
      projectCode:
          _string(json, const ['projectCode', 'projectSlug']) ??
          _string(projectMap, const ['code', 'slug']),
      projectName:
          _string(json, const ['projectName']) ??
          _string(projectMap, const ['name']),
      requestedRole:
          _string(json, const ['requestedRole', 'role']) ?? 'PLACE_EDITOR',
      status: _string(json, const ['status']) ?? 'PENDING',
      justification:
          _string(json, const ['justification', 'reason']) ?? '(No reason)',
      createdAt:
          _dateTime(json, const [
            'createdAt',
            'requestedAt',
            'created_at',
            'updatedAt',
          ]) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      adminMemo: _string(json, const ['adminMemo', 'reviewMemo']),
      reviewedAt: _dateTime(json, const ['reviewedAt', 'resolvedAt']),
      reviewerId:
          _string(json, const ['reviewerId']) ??
          _string(reviewerMap, const ['id']),
      reviewerName:
          _string(json, const ['reviewerName']) ??
          _string(reviewerMap, const ['displayName', 'name']),
    );
  }

  static List<ProjectRoleRequestDto> listFromAny(dynamic raw) {
    final list = _extractList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(ProjectRoleRequestDto.fromJson)
        .toList(growable: false);
  }
}

class ProjectRoleRequestCreateRequestDto {
  const ProjectRoleRequestCreateRequestDto({
    required this.projectId,
    required this.requestedRole,
    required this.justification,
  });

  final String projectId;
  final String requestedRole;
  final String justification;

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'requestedRole': requestedRole,
      'justification': justification,
    };
  }
}

List<Map<String, dynamic>> _extractList(dynamic json) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  if (json is Map<String, dynamic>) {
    final items = json['items'] ?? json['content'] ?? json['results'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (json.containsKey('id') || json.containsKey('requestId')) {
      return <Map<String, dynamic>>[json];
    }
  }
  return const <Map<String, dynamic>>[];
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

DateTime? _dateTime(Map<String, dynamic> json, List<String> keys) {
  final raw = _string(json, keys);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}
