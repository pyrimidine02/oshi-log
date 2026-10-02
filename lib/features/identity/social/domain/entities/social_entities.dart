/// EN: Social (follow/block) domain entities.
/// KO: 소셜(팔로우/차단) 도메인 엔티티.
library;

class UserFollowStatus {
  const UserFollowStatus({
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
  final DateTime? followedAt;
  final int targetFollowerCount;
  final int targetFollowingCount;
}

class UserFollowSummary {
  const UserFollowSummary({
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
  final DateTime followedAt;
}

class BlockStatus {
  const BlockStatus({
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedMe,
    required this.blockedByAdmin,
  });

  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedMe;
  final bool blockedByAdmin;
}
