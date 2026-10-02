/// EN: User profile DTO for settings/profile.
/// KO: 설정/프로필용 사용자 프로필 DTO.
library;

import 'user_access_level_dto.dart';

class UserProfileDto {
  const UserProfileDto({
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
  final String accountRole;
  final String baselineAccessLevel;
  final String effectiveAccessLevel;
  final List<UserAccessLevelGrantDto> grants;
  final Map<String, List<String>> projectRolesByProject;

  /// EN: Legacy role field kept for backward compatibility with old payloads.
  /// KO: 구형 응답 호환을 위해 유지하는 레거시 role 필드입니다.
  final String role;
  final DateTime createdAt;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = _string(json, ['createdAt', 'created_at']) ?? '';
    final parsedCreatedAt =
        DateTime.tryParse(createdAtRaw) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final explicitAccountRole = _string(json, ['accountRole', 'account_role']);
    final roleCandidate =
        _string(json, ['role', 'userRole', 'user_role', 'authority']) ??
        _firstRoleValue(json, ['roles', 'authorities', 'grantedAuthorities']);
    final accountRole = _normalizeAccountRole(
      explicitAccountRole,
      fallbackRole: roleCandidate,
    );
    final role = _normalizeRoleValue(roleCandidate ?? accountRole);
    final roleBasedAccessLevel = explicitAccountRole == null
        ? _accessLevelFromRole(role)
        : null;
    final baselineAccessLevel =
        _normalizeAccessLevel(
          _string(json, ['baselineAccessLevel', 'baseline_access_level']),
        ) ??
        roleBasedAccessLevel ??
        _baselineFromAccountRole(accountRole);
    final effectiveAccessLevel =
        _normalizeAccessLevel(
          _string(json, [
            'effectiveAccessLevel',
            'effective_access_level',
            'accessLevel',
            'access_level',
            'resolvedAccessLevel',
            'resolved_access_level',
          ]),
        ) ??
        roleBasedAccessLevel ??
        baselineAccessLevel;
    final grants = _parseAccessLevelGrants(json['grants']);
    final projectRolesByProject = _parseProjectRolesByProject(json);
    final totalXp = _resolveStatsInt(json, [
      'totalXp',
      'total_xp',
      'xp',
      'fanXp',
      'fan_xp',
    ]);
    final fanLevel = _resolveStatsInt(json, [
      'fanLevel',
      'fan_level',
      'level',
      'levelNumber',
      'level_number',
    ]);
    final fanGrade = _resolveStatsString(json, [
      'fanGrade',
      'fan_grade',
      'grade',
      'levelName',
      'level_name',
    ]);
    final uniquePlacesVisited = _resolveStatsInt(json, [
      'uniquePlacesVisited',
      'unique_places_visited',
      'uniquePlaces',
      'unique_places',
    ]);
    final totalVisits = _resolveStatsInt(json, [
      'totalVisits',
      'total_visits',
      'visitCount',
      'visit_count',
    ]);
    final liveAttendanceCount = _resolveStatsInt(json, [
      'liveAttendanceCount',
      'live_attendance_count',
      'attendanceCount',
      'attendance_count',
      'liveVisits',
      'live_visits',
    ]);
    final postCount = _resolveStatsInt(json, [
      'postCount',
      'post_count',
      'postsCount',
      'posts_count',
    ]);
    final commentCount = _resolveStatsInt(json, [
      'commentCount',
      'comment_count',
      'commentsCount',
      'comments_count',
    ]);

    return UserProfileDto(
      id: _string(json, ['id', 'userId', 'user_id']) ?? '',
      email: _string(json, ['email', 'emailAddress', 'email_address']) ?? '',
      displayName:
          _string(json, ['displayName', 'display_name', 'nickname', 'name']) ??
          '사용자',
      role: role,
      accountRole: accountRole,
      baselineAccessLevel: baselineAccessLevel,
      effectiveAccessLevel: effectiveAccessLevel,
      grants: grants,
      projectRolesByProject: projectRolesByProject,
      createdAt: parsedCreatedAt,
      avatarUrl: _string(json, [
        'avatarUrl',
        'avatar_url',
        'profileImageUrl',
        'profile_image_url',
        'imageUrl',
        'image_url',
      ]),
      bio: _string(json, ['bio', 'introduction', 'about', 'summary']),
      coverImageUrl: _string(json, [
        'coverImageUrl',
        'cover_image_url',
        'headerImageUrl',
        'header_image_url',
        'bannerImageUrl',
        'banner_image_url',
      ]),
      totalXp: totalXp,
      fanLevel: fanLevel,
      fanGrade: fanGrade,
      uniquePlacesVisited: uniquePlacesVisited,
      totalVisits: totalVisits,
      liveAttendanceCount: liveAttendanceCount,
      postCount: postCount,
      commentCount: commentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'coverImageUrl': coverImageUrl,
      if (totalXp != null) 'totalXp': totalXp,
      if (fanLevel != null) 'fanLevel': fanLevel,
      if (fanGrade != null) 'fanGrade': fanGrade,
      if (uniquePlacesVisited != null)
        'uniquePlacesVisited': uniquePlacesVisited,
      if (totalVisits != null) 'totalVisits': totalVisits,
      if (liveAttendanceCount != null)
        'liveAttendanceCount': liveAttendanceCount,
      if (postCount != null) 'postCount': postCount,
      if (commentCount != null) 'commentCount': commentCount,
      'accountRole': accountRole,
      'baselineAccessLevel': baselineAccessLevel,
      'effectiveAccessLevel': effectiveAccessLevel,
      'activeGrantCount': grants.where((grant) => grant.isActive).length,
      'grants': grants.map((grant) => grant.toJson()).toList(growable: false),
      'projectRoles': projectRolesByProject.map(
        (key, value) => MapEntry<String, dynamic>(key, value),
      ),
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserProfileDto mergeAccessLevel(UserAccessLevelDto accessLevel) {
    final mergedAccountRole = _normalizeAccountRole(
      accessLevel.accountRole,
      fallbackRole: role,
    );
    final mergedBaseline =
        _normalizeAccessLevel(accessLevel.baselineAccessLevel) ??
        _baselineFromAccountRole(mergedAccountRole);
    final mergedEffective =
        _normalizeAccessLevel(accessLevel.effectiveAccessLevel) ??
        mergedBaseline;

    return UserProfileDto(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      coverImageUrl: coverImageUrl,
      totalXp: totalXp,
      fanLevel: fanLevel,
      fanGrade: fanGrade,
      uniquePlacesVisited: uniquePlacesVisited,
      totalVisits: totalVisits,
      liveAttendanceCount: liveAttendanceCount,
      postCount: postCount,
      commentCount: commentCount,
      role: role,
      accountRole: mergedAccountRole,
      baselineAccessLevel: mergedBaseline,
      effectiveAccessLevel: mergedEffective,
      grants: accessLevel.grants,
      projectRolesByProject: projectRolesByProject,
      createdAt: createdAt,
    );
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Map<String, dynamic>? _map(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return null;
}

int? _resolveStatsInt(Map<String, dynamic> json, List<String> keys) {
  final direct = _int(json, keys);
  if (direct != null) {
    return direct;
  }
  final nested = _map(json, [
    'stats',
    'activityStats',
    'activity_stats',
    'profileStats',
    'profile_stats',
    'fanLevel',
    'fan_level',
    'visitStats',
    'visit_stats',
    'attendanceStats',
    'attendance_stats',
  ]);
  if (nested == null) {
    return null;
  }
  return _int(nested, keys);
}

String? _resolveStatsString(Map<String, dynamic> json, List<String> keys) {
  final direct = _string(json, keys);
  if (direct != null) {
    return direct;
  }
  final nested = _map(json, [
    'stats',
    'activityStats',
    'activity_stats',
    'profileStats',
    'profile_stats',
    'fanLevel',
    'fan_level',
    'visitStats',
    'visit_stats',
    'attendanceStats',
    'attendance_stats',
  ]);
  if (nested == null) {
    return null;
  }
  return _string(nested, keys);
}

String? _firstRoleValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is List) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
        if (item is Map<String, dynamic>) {
          final nested = _string(item, ['role', 'name', 'authority', 'value']);
          if (nested != null) {
            return nested;
          }
        }
      }
    }
  }
  return null;
}

String _baselineFromAccountRole(String accountRole) {
  final normalized = _normalizeToken(accountRole);
  if (_isAdminToken(normalized)) {
    return 'PLATFORM_SUPER_ADMIN';
  }
  return 'USER_BASE';
}

String _normalizeAccountRole(String? rawRole, {String? fallbackRole}) {
  final normalizedRole = _normalizeToken(rawRole);
  if (_isPlatformAdminToken(normalizedRole) || _isAdminToken(normalizedRole)) {
    return 'ADMIN';
  }
  if (_isUserToken(normalizedRole)) {
    return 'USER';
  }

  final normalizedFallback = _normalizeToken(fallbackRole);
  if (_isPlatformAdminToken(normalizedFallback) ||
      _isAdminToken(normalizedFallback)) {
    return 'ADMIN';
  }
  return 'USER';
}

String _normalizeRoleValue(String rawRole) {
  final normalized = _normalizeToken(rawRole);
  if (normalized == null || normalized.isEmpty) {
    return rawRole;
  }
  return normalized;
}

String? _normalizeAccessLevel(String? rawLevel) {
  final normalized = _normalizeToken(rawLevel);
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  switch (normalized) {
    case 'USER':
    case 'MEMBER':
    case 'VIEWER':
    case 'GUEST':
      return 'USER_BASE';
    case 'EDITOR':
      return 'CONTENT_EDITOR';
    case 'MODERATOR':
      return 'COMMUNITY_MODERATOR';
    case 'ADMIN':
      return 'PLATFORM_SUPER_ADMIN';
    case 'SUPER_ADMIN':
    case 'PLATFORM_ADMIN':
    case 'ROOT_ADMIN':
    case 'SYSTEM_ADMIN':
      return 'PLATFORM_SUPER_ADMIN';
    default:
      return normalized;
  }
}

String? _accessLevelFromRole(String? role) {
  final normalized = _normalizeToken(role);
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (_isPlatformAdminToken(normalized)) {
    return 'PLATFORM_SUPER_ADMIN';
  }
  if (_isAdminToken(normalized)) {
    return 'PLATFORM_SUPER_ADMIN';
  }
  if (_isModeratorToken(normalized)) {
    return 'COMMUNITY_MODERATOR';
  }
  if (_isEditorToken(normalized)) {
    return 'CONTENT_EDITOR';
  }
  if (_isUserToken(normalized)) {
    return 'USER_BASE';
  }
  return null;
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

bool _isPlatformAdminToken(String? token) {
  if (token == null) {
    return false;
  }
  return token == 'PLATFORM_SUPER_ADMIN' ||
      token == 'SUPER_ADMIN' ||
      token == 'PLATFORM_ADMIN' ||
      token == 'ROOT_ADMIN' ||
      token == 'SYSTEM_ADMIN';
}

bool _isAdminToken(String? token) {
  if (token == null) {
    return false;
  }
  if (_isPlatformAdminToken(token)) {
    return true;
  }
  return token == 'ADMIN';
}

bool _isModeratorToken(String? token) {
  if (token == null) {
    return false;
  }
  return token == 'COMMUNITY_MODERATOR' ||
      token == 'MODERATOR' ||
      token.endsWith('_MODERATOR');
}

bool _isEditorToken(String? token) {
  if (token == null) {
    return false;
  }
  return token == 'CONTENT_EDITOR' ||
      token == 'EDITOR' ||
      token.endsWith('_EDITOR');
}

bool _isUserToken(String? token) {
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

Map<String, List<String>> _parseProjectRolesByProject(
  Map<String, dynamic> json,
) {
  final raw = json['projectRoles'] ?? json['project_roles'];
  final parsed = <String, List<String>>{};

  void addRole(String projectKey, String roleRaw) {
    final normalizedProjectKey = projectKey.trim();
    if (normalizedProjectKey.isEmpty) {
      return;
    }
    final normalizedRole = _normalizeToken(roleRaw);
    if (normalizedRole == null || normalizedRole.isEmpty) {
      return;
    }
    final canonicalRole = _canonicalProjectRole(normalizedRole);
    if (canonicalRole == null) {
      return;
    }
    final roles = parsed.putIfAbsent(normalizedProjectKey, () => <String>[]);
    if (!roles.contains(canonicalRole)) {
      roles.add(canonicalRole);
    }
  }

  if (raw is Map<String, dynamic>) {
    raw.forEach((key, value) {
      if (value is String) {
        addRole(key, value);
        return;
      }
      if (value is List) {
        for (final item in value) {
          if (item is String) {
            addRole(key, item);
          } else if (item is Map<String, dynamic>) {
            final role = _string(item, ['role', 'name', 'authority', 'value']);
            if (role != null) {
              addRole(key, role);
            }
          }
        }
      }
    });
  } else if (raw is List) {
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final projectKey = _string(item, [
        'projectId',
        'project_id',
        'projectCode',
        'project_code',
        'projectSlug',
        'project_slug',
        'projectKey',
        'project_key',
      ]);
      if (projectKey == null || projectKey.isEmpty) {
        continue;
      }

      final singleRole = _string(item, ['role', 'projectRole', 'project_role']);
      if (singleRole != null) {
        addRole(projectKey, singleRole);
      }

      final roleList =
          item['roles'] ?? item['projectRoles'] ?? item['project_roles'];
      if (roleList is List) {
        for (final roleItem in roleList) {
          if (roleItem is String) {
            addRole(projectKey, roleItem);
          } else if (roleItem is Map<String, dynamic>) {
            final role = _string(roleItem, [
              'role',
              'name',
              'authority',
              'value',
            ]);
            if (role != null) {
              addRole(projectKey, role);
            }
          }
        }
      }
    }
  }

  return parsed;
}

String? _canonicalProjectRole(String normalizedRole) {
  switch (normalizedRole) {
    case 'ADMIN':
      return 'ADMIN';
    case 'PLACE_EDITOR':
    case 'EDITOR':
      return 'PLACE_EDITOR';
    case 'COMMUNITY_MODERATOR':
    case 'MODERATOR':
      return 'COMMUNITY_MODERATOR';
    case 'MEMBER':
    case 'USER':
      return 'MEMBER';
    default:
      return null;
  }
}

List<UserAccessLevelGrantDto> _parseAccessLevelGrants(dynamic raw) {
  if (raw is! List) {
    return const <UserAccessLevelGrantDto>[];
  }
  return raw
      .whereType<Map<String, dynamic>>()
      .map(UserAccessLevelGrantDto.fromJson)
      .toList(growable: false);
}
