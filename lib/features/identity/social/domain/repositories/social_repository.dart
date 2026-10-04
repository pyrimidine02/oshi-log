/// EN: Social (follow/block) repository interface.
/// KO: 소셜(팔로우/차단) 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';

import '../entities/social_entities.dart';

abstract class SocialRepository {
  /// EN: Check block status for a user.
  /// KO: 사용자 차단 상태를 확인합니다.
  Future<Result<BlockStatus>> getBlockStatus({required String userId});

  /// EN: Get follow status for a user.
  /// KO: 사용자 팔로우 상태를 조회합니다.
  Future<Result<UserFollowStatus>> getFollowStatus({required String userId});

  /// EN: Follow a user.
  /// KO: 사용자를 팔로우합니다.
  Future<Result<UserFollowStatus>> followUser({required String userId});

  /// EN: Unfollow a user.
  /// KO: 사용자 팔로우를 해제합니다.
  Future<Result<void>> unfollowUser({required String userId});

  /// EN: Get followers list for a user.
  /// KO: 사용자 팔로워 목록을 조회합니다.
  Future<Result<List<UserFollowSummary>>> getFollowers({
    required String userId,
    int page = 0,
    int size = 20,
  });

  /// EN: Get following list for a user.
  /// KO: 사용자가 팔로우 중인 목록을 조회합니다.
  Future<Result<List<UserFollowSummary>>> getFollowing({
    required String userId,
    int page = 0,
    int size = 20,
  });

  /// EN: Block a user.
  /// KO: 사용자를 차단합니다.
  Future<Result<void>> blockUser({
    required String targetUserId,
    String? reason,
  });

  /// EN: Unblock a user.
  /// KO: 사용자를 차단 해제합니다.
  Future<Result<void>> unblockUser({required String targetUserId});
}
