/// EN: Access-level model and guards for account role migration.
/// KO: 계정 권한 체계 마이그레이션용 접근 레벨 모델과 가드입니다.
library;

/// EN: Effective user access levels from backend policy.
/// KO: 백엔드 정책 기준 유효 접근 레벨입니다.
enum UserAccessLevel {
  userBase('USER_BASE', 0),
  contentEditor('CONTENT_EDITOR', 1),
  communityModerator('COMMUNITY_MODERATOR', 2),
  adminNonSensitive('ADMIN_NON_SENSITIVE', 3),
  platformSuperAdmin('PLATFORM_SUPER_ADMIN', 4),
  unknown('UNKNOWN', -1);

  const UserAccessLevel(this.apiValue, this.rank);

  final String apiValue;
  final int rank;
}

/// EN: Project-scoped role values for project-specific authorization checks.
/// KO: 프로젝트 범위 인가 판단에 사용하는 프로젝트 역할 값입니다.
enum ProjectRole {
  admin('ADMIN'),
  placeEditor('PLACE_EDITOR'),
  communityModerator('COMMUNITY_MODERATOR'),
  member('MEMBER'),
  unknown('UNKNOWN');

  const ProjectRole(this.apiValue);

  final String apiValue;
}

extension UserAccessLevelX on UserAccessLevel {
  /// EN: Human-readable Korean label for settings/admin UI.
  /// KO: 설정/관리자 UI에 표시할 한글 라벨입니다.
  String get labelKo => switch (this) {
    UserAccessLevel.userBase => '일반 사용자',
    UserAccessLevel.contentEditor => '콘텐츠 에디터',
    UserAccessLevel.communityModerator => '커뮤니티 모더레이터',
    UserAccessLevel.adminNonSensitive => '비민감 관리자',
    UserAccessLevel.platformSuperAdmin => '플랫폼 최고 관리자',
    UserAccessLevel.unknown => '알 수 없음',
  };

  /// EN: Returns true when this level includes the required level.
  /// KO: 현재 레벨이 요구 레벨 이상인지 반환합니다.
  bool isAtLeast(UserAccessLevel required) {
    if (this == UserAccessLevel.unknown) {
      return false;
    }
    return rank >= required.rank;
  }

  /// EN: Parses API access-level string to enum.
  /// KO: API 접근 레벨 문자열을 enum으로 파싱합니다.
  static UserAccessLevel fromApiValue(String? rawValue) {
    final normalized = _normalizeToken(rawValue);
    switch (normalized) {
      case 'USER_BASE':
      case 'USER':
      case 'MEMBER':
      case 'VIEWER':
      case 'GUEST':
        return UserAccessLevel.userBase;
      case 'CONTENT_EDITOR':
      case 'EDITOR':
        return UserAccessLevel.contentEditor;
      case 'COMMUNITY_MODERATOR':
      case 'MODERATOR':
        return UserAccessLevel.communityModerator;
      case 'ADMIN_NON_SENSITIVE':
        return UserAccessLevel.adminNonSensitive;
      case 'PLATFORM_SUPER_ADMIN':
      case 'ADMIN':
      case 'SUPER_ADMIN':
      case 'PLATFORM_ADMIN':
      case 'ROOT_ADMIN':
      case 'SYSTEM_ADMIN':
        return UserAccessLevel.platformSuperAdmin;
      default:
        return UserAccessLevel.unknown;
    }
  }

  /// EN: Resolves access level with API value first and account-role fallback.
  /// KO: API 접근 레벨을 우선하고 account-role을 보조로 사용해 결정합니다.
  static UserAccessLevel resolve({
    String? effectiveAccessLevel,
    String? accountRole,
  }) {
    final explicit = fromApiValue(effectiveAccessLevel);
    if (explicit != UserAccessLevel.unknown) {
      return explicit;
    }

    final normalizedAccountRole = _normalizeToken(accountRole);
    if (_isAdminAccountRole(normalizedAccountRole)) {
      return UserAccessLevel.platformSuperAdmin;
    }
    if (_isUserAlias(normalizedAccountRole)) {
      return UserAccessLevel.userBase;
    }

    return UserAccessLevel.unknown;
  }
}

extension ProjectRoleX on ProjectRole {
  /// EN: Parses API project-role string to enum.
  /// KO: API 프로젝트 역할 문자열을 enum으로 파싱합니다.
  static ProjectRole fromApiValue(String? rawValue) {
    final normalized = _normalizeToken(rawValue);
    switch (normalized) {
      case 'ADMIN':
        return ProjectRole.admin;
      case 'PLACE_EDITOR':
      case 'EDITOR':
        return ProjectRole.placeEditor;
      case 'COMMUNITY_MODERATOR':
      case 'MODERATOR':
        return ProjectRole.communityModerator;
      case 'MEMBER':
      case 'USER':
        return ProjectRole.member;
      default:
        return ProjectRole.unknown;
    }
  }
}

/// EN: Returns true when user can access ops center screens.
/// KO: 사용자에게 운영센터 화면 접근 권한이 있는지 반환합니다.
bool hasAdminOpsAccess({String? effectiveAccessLevel, String? accountRole}) {
  return canAccessNonSensitiveAdmin(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
}

/// EN: Returns true when user can perform community moderation actions.
/// KO: 사용자에게 커뮤니티 모더레이션 권한이 있는지 반환합니다.
bool canModerateCommunity({String? effectiveAccessLevel, String? accountRole}) {
  final level = UserAccessLevelX.resolve(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
  return level.isAtLeast(UserAccessLevel.communityModerator);
}

/// EN: Returns true when user can access non-sensitive admin APIs.
/// KO: 비민감 관리자 API 접근 권한이 있는지 반환합니다.
bool canAccessNonSensitiveAdmin({
  String? effectiveAccessLevel,
  String? accountRole,
}) {
  final level = UserAccessLevelX.resolve(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
  return level.isAtLeast(UserAccessLevel.adminNonSensitive);
}

/// EN: Returns true when user can access sensitive admin APIs.
/// KO: 민감 관리자 API 접근 권한이 있는지 반환합니다.
bool canAccessSensitiveAdmin({
  String? effectiveAccessLevel,
  String? accountRole,
}) {
  final level = UserAccessLevelX.resolve(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
  return level.isAtLeast(UserAccessLevel.platformSuperAdmin);
}

/// EN: Returns true when user can edit project content with global or project role.
/// KO: 전역 권한 또는 프로젝트 역할로 프로젝트 콘텐츠 편집 가능 여부를 반환합니다.
bool canEditProjectContent({
  String? effectiveAccessLevel,
  String? accountRole,
  String? projectId,
  String? projectCode,
  Map<String, List<String>>? projectRolesByProject,
}) {
  final level = UserAccessLevelX.resolve(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
  if (level.isAtLeast(UserAccessLevel.contentEditor)) {
    return true;
  }

  final roles = _lookupProjectRoles(
    projectRolesByProject: projectRolesByProject,
    projectId: projectId,
    projectCode: projectCode,
  );
  return roles.contains(ProjectRole.admin) ||
      roles.contains(ProjectRole.placeEditor);
}

/// EN: Returns true when user can moderate project community with global or project role.
/// KO: 전역 권한 또는 프로젝트 역할로 프로젝트 커뮤니티 운영 가능 여부를 반환합니다.
bool canModerateProjectCommunity({
  String? effectiveAccessLevel,
  String? accountRole,
  String? projectId,
  String? projectCode,
  Map<String, List<String>>? projectRolesByProject,
}) {
  final level = UserAccessLevelX.resolve(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
  );
  if (level.isAtLeast(UserAccessLevel.communityModerator)) {
    return true;
  }

  final roles = _lookupProjectRoles(
    projectRolesByProject: projectRolesByProject,
    projectId: projectId,
    projectCode: projectCode,
  );
  return roles.contains(ProjectRole.admin) ||
      roles.contains(ProjectRole.communityModerator);
}

String? _normalizeToken(String? rawValue) {
  final trimmed = rawValue?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  var normalized = trimmed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
  normalized = normalized.replaceAll(RegExp('_+'), '_');
  normalized = normalized.replaceAll(RegExp('^_+|_+\$'), '');
  if (normalized.startsWith('ROLE_')) {
    normalized = normalized.substring('ROLE_'.length);
  }
  return normalized;
}

bool _isAdminAccountRole(String? token) {
  if (token == null) {
    return false;
  }
  return token == 'ADMIN' ||
      token == 'PLATFORM_SUPER_ADMIN' ||
      token == 'SUPER_ADMIN' ||
      token == 'PLATFORM_ADMIN' ||
      token == 'ROOT_ADMIN' ||
      token == 'SYSTEM_ADMIN';
}

bool _isUserAlias(String? token) {
  if (token == null) {
    return false;
  }
  return token == 'USER' ||
      token == 'USER_BASE' ||
      token == 'MEMBER' ||
      token == 'VIEWER' ||
      token == 'GUEST' ||
      token.endsWith('_USER');
}

Set<ProjectRole> _lookupProjectRoles({
  required Map<String, List<String>>? projectRolesByProject,
  required String? projectId,
  required String? projectCode,
}) {
  if (projectRolesByProject == null || projectRolesByProject.isEmpty) {
    return const <ProjectRole>{};
  }

  final candidateKeys = <String>{
    if (projectId != null && projectId.trim().isNotEmpty)
      _normalizeProjectKey(projectId),
    if (projectCode != null && projectCode.trim().isNotEmpty)
      _normalizeProjectKey(projectCode),
  };
  if (candidateKeys.isEmpty) {
    return const <ProjectRole>{};
  }

  for (final entry in projectRolesByProject.entries) {
    final entryKey = _normalizeProjectKey(entry.key);
    if (!candidateKeys.contains(entryKey)) {
      continue;
    }
    return entry.value
        .map(ProjectRoleX.fromApiValue)
        .where((role) => role != ProjectRole.unknown)
        .toSet();
  }

  return const <ProjectRole>{};
}

String _normalizeProjectKey(String raw) {
  return raw.trim().toLowerCase();
}
