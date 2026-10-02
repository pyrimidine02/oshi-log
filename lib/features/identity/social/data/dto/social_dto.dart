/// EN: Social (follow/block) DTOs.
/// KO: 소셜(팔로우/차단) DTO.
library;

class BlockCreateRequestDto {
  const BlockCreateRequestDto({required this.targetUserId, this.reason});

  final String targetUserId;
  final String? reason;

  Map<String, dynamic> toJson() {
    return {
      'targetUserId': targetUserId,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}

class BlockCheckDto {
  const BlockCheckDto({
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedMe,
    required this.blockedByAdmin,
  });

  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedMe;
  final bool blockedByAdmin;

  factory BlockCheckDto.fromJson(Map<String, dynamic> json) {
    return BlockCheckDto(
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedByMe: json['blockedByMe'] as bool? ?? false,
      blockedMe: json['blockedMe'] as bool? ?? false,
      blockedByAdmin: json['blockedByAdmin'] as bool? ?? false,
    );
  }
}

class UserFollowStatusDto {
  const UserFollowStatusDto({
    required this.targetUserId,
    required this.following,
    required this.followedByTarget,
    required this.targetFollowerCount,
    required this.targetFollowingCount,
    this.followedAt,
  });

  final String targetUserId;
  final bool following;
  final bool followedByTarget;
  final String? followedAt;
  final int targetFollowerCount;
  final int targetFollowingCount;

  factory UserFollowStatusDto.fromJson(Map<String, dynamic> json) {
    return UserFollowStatusDto(
      targetUserId: json['targetUserId'] as String? ?? '',
      following: json['following'] as bool? ?? false,
      followedByTarget: json['followedByTarget'] as bool? ?? false,
      followedAt: json['followedAt'] as String?,
      targetFollowerCount: (json['targetFollowerCount'] as num?)?.toInt() ?? 0,
      targetFollowingCount:
          (json['targetFollowingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserFollowSummaryDto {
  const UserFollowSummaryDto({
    required this.userId,
    required this.displayName,
    required this.followedAt,
    this.avatarUrl,
    this.bio,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String followedAt;

  factory UserFollowSummaryDto.fromJson(Map<String, dynamic> json) {
    return UserFollowSummaryDto(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '사용자',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      followedAt: json['followedAt'] as String? ?? '',
    );
  }
}
