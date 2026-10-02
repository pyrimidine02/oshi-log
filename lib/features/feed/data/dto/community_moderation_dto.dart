/// EN: Community moderation DTOs.
/// KO: 커뮤니티 신고/차단 DTO.
library;

class ReportCreateRequestDto {
  const ReportCreateRequestDto({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
  });

  final String targetType;
  final String targetId;
  final String reason;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}

class UserSanctionStatusDto {
  const UserSanctionStatusDto({
    required this.level,
    this.reason,
    this.expiresAt,
  });

  final String level;
  final String? reason;
  final String? expiresAt;

  factory UserSanctionStatusDto.fromJson(Map<String, dynamic> json) {
    return UserSanctionStatusDto(
      level: json['level'] as String? ?? 'NONE',
      reason: json['reason'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}

class AppealCreateRequestDto {
  const AppealCreateRequestDto({
    required this.targetType,
    required this.targetId,
    required this.reason,
  });

  final String targetType;
  final String targetId;
  final String reason;

  Map<String, dynamic> toJson() {
    return {'targetType': targetType, 'targetId': targetId, 'reason': reason};
  }
}

class ReportSummaryDto {
  const ReportSummaryDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final String priority;
  final DateTime createdAt;

  factory ReportSummaryDto.fromJson(Map<String, dynamic> json) {
    return ReportSummaryDto(
      id: json['id'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'POST',
      targetId: json['targetId'] as String? ?? '',
      reason: json['reason'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class ReportDetailDto {
  const ReportDetailDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.adminAction,
    this.resolvedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? adminAction;
  final DateTime? resolvedAt;

  factory ReportDetailDto.fromJson(Map<String, dynamic> json) {
    return ReportDetailDto(
      id: json['id'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'POST',
      targetId: json['targetId'] as String? ?? '',
      reason: json['reason'] as String? ?? 'OTHER',
      status: json['status'] as String? ?? 'OPEN',
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: _dateTime(json['createdAt']),
      updatedAt: _dateTime(json['updatedAt']),
      description: json['description'] as String?,
      adminAction: json['adminAction'] as String?,
      resolvedAt: _dateTimeOrNull(json['resolvedAt']),
    );
  }
}

class ProjectCommunityBanRequestDto {
  const ProjectCommunityBanRequestDto({this.reason, this.expiresAt});

  final String? reason;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }
}

class ProjectCommunityBanDto {
  const ProjectCommunityBanDto({
    required this.id,
    required this.projectId,
    required this.bannedUserId,
    required this.moderatorUserId,
    required this.createdAt,
    this.bannedUserDisplayName,
    this.bannedUserEmail,
    this.bannedUserAvatarUrl,
    this.reason,
    this.expiresAt,
  });

  final String id;
  final String projectId;
  final String bannedUserId;
  final String moderatorUserId;
  final DateTime createdAt;
  final String? bannedUserDisplayName;
  final String? bannedUserEmail;
  final String? bannedUserAvatarUrl;
  final String? reason;
  final DateTime? expiresAt;

  factory ProjectCommunityBanDto.fromJson(Map<String, dynamic> json) {
    final bannedUser = json['bannedUser'];
    final bannedUserMap = bannedUser is Map<String, dynamic>
        ? bannedUser
        : const <String, dynamic>{};
    return ProjectCommunityBanDto(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      bannedUserId: bannedUserMap['id'] as String? ?? '',
      moderatorUserId: json['moderatorUserId'] as String? ?? '',
      createdAt: _dateTime(json['createdAt']),
      bannedUserDisplayName: bannedUserMap['displayName'] as String?,
      bannedUserEmail: bannedUserMap['email'] as String?,
      bannedUserAvatarUrl: bannedUserMap['avatarUrl'] as String?,
      reason: json['reason'] as String?,
      expiresAt: _dateTimeOrNull(json['expiresAt']),
    );
  }
}

DateTime _dateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
