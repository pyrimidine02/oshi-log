/// EN: User profile domain entity.
/// KO: 사용자 프로필 도메인 엔티티.
library;

import '../../../../core/security/user_access_level.dart' as access;

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.accountRole,
    required this.baselineAccessLevel,
    required this.effectiveAccessLevel,
    required this.grants,
    required this.projectRolesByProject,
    required this.createdAt,
    this.avatarUrl,
    this.bio,
    this.coverImageUrl,
    this.totalXp,
    this.fanLevel,
    this.fanGrade,
    this.uniquePlacesVisited,
    this.totalVisits,
    this.liveAttendanceCount,
    this.postCount,
    this.commentCount,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String accountRole;
  final String baselineAccessLevel;
  final String effectiveAccessLevel;
  final List<UserAccessGrantSnapshot> grants;
  final Map<String, List<String>> projectRolesByProject;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? bio;
  final String? coverImageUrl;
  final int? totalXp;
  final int? fanLevel;
  final String? fanGrade;
  final int? uniquePlacesVisited;
  final int? totalVisits;
  final int? liveAttendanceCount;
  final int? postCount;
  final int? commentCount;

  String get summaryLabel {
    return '가입일: ${createdAt.toLocal().toIso8601String().split('T').first}';
  }

  /// EN: Parsed effective level for access guards.
  /// KO: 접근 제어에 사용하는 파싱된 유효 접근 레벨입니다.
  access.UserAccessLevel get resolvedAccessLevel {
    return access.UserAccessLevelX.resolve(
      effectiveAccessLevel: effectiveAccessLevel,
      accountRole: accountRole,
    );
  }

  /// EN: Display text for effective access level.
  /// KO: 유효 접근 레벨 표시 문자열입니다.
  String get effectiveAccessLevelLabel => resolvedAccessLevel.labelKo;

  /// EN: Whether this profile can access admin operations screens.
  /// KO: 운영센터 화면 접근 가능 여부입니다.
  bool get canAccessAdminOps {
    return access.hasAdminOpsAccess(
      effectiveAccessLevel: effectiveAccessLevel,
      accountRole: accountRole,
    );
  }

  /// EN: Whether this profile can execute moderation actions.
  /// KO: 모더레이션 액션 실행 가능 여부입니다.
  bool get canModerateCommunity {
    return access.canModerateCommunity(
      effectiveAccessLevel: effectiveAccessLevel,
      accountRole: accountRole,
    );
  }

  /// EN: Whether this profile can edit content in a specific project.
  /// KO: 특정 프로젝트에서 콘텐츠를 편집할 수 있는지 여부입니다.
  bool canEditProjectContent({String? projectId, String? projectCode}) {
    return access.canEditProjectContent(
      effectiveAccessLevel: effectiveAccessLevel,
      accountRole: accountRole,
      projectId: projectId,
      projectCode: projectCode,
      projectRolesByProject: projectRolesByProject,
    );
  }

  /// EN: Whether this profile can moderate community in a specific project.
  /// KO: 특정 프로젝트 커뮤니티를 운영할 수 있는지 여부입니다.
  bool canModerateProjectCommunity({String? projectId, String? projectCode}) {
    return access.canModerateProjectCommunity(
      effectiveAccessLevel: effectiveAccessLevel,
      accountRole: accountRole,
      projectId: projectId,
      projectCode: projectCode,
      projectRolesByProject: projectRolesByProject,
    );
  }
}

class UserAccessGrantSnapshot {
  const UserAccessGrantSnapshot({
    required this.grantId,
    required this.userId,
    required this.accessLevel,
    required this.isActive,
    this.grantedByUserId,
    this.grantReason,
    this.grantedAt,
    this.expiresAt,
    this.revokedAt,
    this.revokedByUserId,
    this.revokedReason,
  });

  final String grantId;
  final String userId;
  final String accessLevel;
  final bool isActive;
  final String? grantedByUserId;
  final String? grantReason;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revokedByUserId;
  final String? revokedReason;
}
