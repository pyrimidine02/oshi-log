/// EN: DTOs for `/users/me/access-level` response payload.
/// KO: `/users/me/access-level` 응답 페이로드 DTO입니다.
library;

class UserAccessLevelGrantDto {
  const UserAccessLevelGrantDto({
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

  factory UserAccessLevelGrantDto.fromJson(Map<String, dynamic> json) {
    return UserAccessLevelGrantDto(
      grantId: _string(json, const ['grantId', 'id']) ?? '',
      userId: _string(json, const ['userId']) ?? '',
      accessLevel: _string(json, const ['accessLevel']) ?? '',
      isActive: _boolOrFallback(json['isActive'], false),
      grantedByUserId: _string(json, const ['grantedByUserId']),
      grantReason: _string(json, const ['grantReason']),
      grantedAt: _dateTimeOrNull(json['grantedAt']),
      expiresAt: _dateTimeOrNull(json['expiresAt']),
      revokedAt: _dateTimeOrNull(json['revokedAt']),
      revokedByUserId: _string(json, const ['revokedByUserId']),
      revokedReason: _string(json, const ['revokedReason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grantId': grantId,
      'userId': userId,
      'accessLevel': accessLevel,
      'isActive': isActive,
      if (grantedByUserId != null) 'grantedByUserId': grantedByUserId,
      if (grantReason != null) 'grantReason': grantReason,
      if (grantedAt != null) 'grantedAt': grantedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (revokedAt != null) 'revokedAt': revokedAt!.toIso8601String(),
      if (revokedByUserId != null) 'revokedByUserId': revokedByUserId,
      if (revokedReason != null) 'revokedReason': revokedReason,
    };
  }
}

class UserAccessLevelDto {
  const UserAccessLevelDto({
    required this.userId,
    required this.accountRole,
    required this.baselineAccessLevel,
    required this.effectiveAccessLevel,
    required this.activeGrantCount,
    required this.grants,
  });

  final String userId;
  final String accountRole;
  final String baselineAccessLevel;
  final String effectiveAccessLevel;
  final int activeGrantCount;
  final List<UserAccessLevelGrantDto> grants;

  factory UserAccessLevelDto.fromJson(Map<String, dynamic> json) {
    final grantsRaw = json['grants'];
    final grants = grantsRaw is List
        ? grantsRaw
              .whereType<Map<String, dynamic>>()
              .map(UserAccessLevelGrantDto.fromJson)
              .toList(growable: false)
        : const <UserAccessLevelGrantDto>[];
    return UserAccessLevelDto(
      userId: _string(json, const ['userId', 'id']) ?? '',
      accountRole: _string(json, const ['accountRole']) ?? 'USER',
      baselineAccessLevel:
          _string(json, const ['baselineAccessLevel']) ?? 'USER_BASE',
      effectiveAccessLevel:
          _string(json, const ['effectiveAccessLevel']) ?? 'USER_BASE',
      activeGrantCount: _intOrFallback(
        json['activeGrantCount'],
        grants.where((grant) {
          return grant.isActive;
        }).length,
      ),
      grants: grants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'accountRole': accountRole,
      'baselineAccessLevel': baselineAccessLevel,
      'effectiveAccessLevel': effectiveAccessLevel,
      'activeGrantCount': activeGrantCount,
      'grants': grants.map((grant) => grant.toJson()).toList(growable: false),
    };
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

bool _boolOrFallback(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

int _intOrFallback(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback;
}
