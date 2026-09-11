/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/user_profile_dto.dart';
import '../dto/user_access_level_dto.dart';
import '../../domain/entities/user_profile.dart';

extension UserProfileDtoDomainMapper on UserProfileDto {
  UserProfile toDomain() {
    final dto = this;

    return UserProfile(
      id: dto.id,
      email: dto.email,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
      role: dto.role,
      accountRole: dto.accountRole,
      baselineAccessLevel: dto.baselineAccessLevel,
      effectiveAccessLevel: dto.effectiveAccessLevel,
      grants: List.unmodifiable(
        dto.grants.map((value) => value.toDomain()).toList(growable: false),
      ),
      projectRolesByProject: Map.unmodifiable(
        dto.projectRolesByProject.map(
          (key, value) => MapEntry(key, List.unmodifiable(value)),
        ),
      ),
      createdAt: dto.createdAt,
      bio: dto.bio,
      coverImageUrl: dto.coverImageUrl,
      totalXp: dto.totalXp,
      fanLevel: dto.fanLevel,
      fanGrade: dto.fanGrade,
      uniquePlacesVisited: dto.uniquePlacesVisited,
      totalVisits: dto.totalVisits,
      liveAttendanceCount: dto.liveAttendanceCount,
      postCount: dto.postCount,
      commentCount: dto.commentCount,
    );
  }
}

extension UserAccessLevelGrantDtoDomainMapper on UserAccessLevelGrantDto {
  UserAccessGrantSnapshot toDomain() {
    final dto = this;

    return UserAccessGrantSnapshot(
      grantId: dto.grantId,
      userId: dto.userId,
      accessLevel: dto.accessLevel,
      isActive: dto.isActive,
      grantedByUserId: dto.grantedByUserId,
      grantReason: dto.grantReason,
      grantedAt: dto.grantedAt,
      expiresAt: dto.expiresAt,
      revokedAt: dto.revokedAt,
      revokedByUserId: dto.revokedByUserId,
      revokedReason: dto.revokedReason,
    );
  }
}
