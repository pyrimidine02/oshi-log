/// EN: Social (follow/block) repository implementation.
/// KO: 소셜(팔로우/차단) 리포지토리 구현.
library;

import 'package:oshi_log/core/error/error_handler.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';

import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';
import '../dto/social_dto.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl({required SocialRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final SocialRemoteDataSource _remoteDataSource;

  @override
  Future<Result<BlockStatus>> getBlockStatus({required String userId}) async {
    try {
      final result = await _remoteDataSource.checkBlockStatus(userId: userId);
      if (result is Success<BlockCheckDto>) {
        final dto = result.data;
        return Result.success(
          BlockStatus(
            isBlocked: dto.isBlocked,
            blockedByMe: dto.blockedByMe,
            blockedMe: dto.blockedMe,
            blockedByAdmin: dto.blockedByAdmin,
          ),
        );
      }
      if (result is Err<BlockCheckDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown block status result',
          code: 'unknown_block_status',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UserFollowStatus>> getFollowStatus({
    required String userId,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowStatus(userId: userId);
      if (result is Success<UserFollowStatusDto>) {
        return Result.success(_toFollowStatus(result.data));
      }
      if (result is Err<UserFollowStatusDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown follow status result',
          code: 'unknown_follow_status',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UserFollowStatus>> followUser({required String userId}) async {
    try {
      final result = await _remoteDataSource.followUser(userId: userId);
      if (result is Success<UserFollowStatusDto>) {
        return Result.success(_toFollowStatus(result.data));
      }
      if (result is Err<UserFollowStatusDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown follow user result',
          code: 'unknown_follow_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> unfollowUser({required String userId}) async {
    try {
      final result = await _remoteDataSource.unfollowUser(userId: userId);
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown unfollow user result',
          code: 'unknown_unfollow_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<UserFollowSummary>>> getFollowers({
    required String userId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowers(
        userId: userId,
        page: page,
        size: size,
      );
      if (result is Success<List<UserFollowSummaryDto>>) {
        return Result.success(result.data.map(_toFollowSummary).toList());
      }
      if (result is Err<List<UserFollowSummaryDto>>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown followers result',
          code: 'unknown_followers_result',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<UserFollowSummary>>> getFollowing({
    required String userId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowing(
        userId: userId,
        page: page,
        size: size,
      );
      if (result is Success<List<UserFollowSummaryDto>>) {
        return Result.success(result.data.map(_toFollowSummary).toList());
      }
      if (result is Err<List<UserFollowSummaryDto>>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown following result',
          code: 'unknown_following_result',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> blockUser({
    required String targetUserId,
    String? reason,
  }) async {
    try {
      final request = BlockCreateRequestDto(
        targetUserId: targetUserId,
        reason: reason,
      );
      final result = await _remoteDataSource.blockUser(request: request);
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown block user result',
          code: 'unknown_block_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> unblockUser({required String targetUserId}) async {
    try {
      final result = await _remoteDataSource.unblockUser(userId: targetUserId);
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown unblock user result',
          code: 'unknown_unblock_user',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  UserFollowStatus _toFollowStatus(UserFollowStatusDto dto) {
    return UserFollowStatus(
      targetUserId: dto.targetUserId,
      following: dto.following,
      followedByTarget: dto.followedByTarget,
      followedAt: dto.followedAt == null
          ? null
          : DateTime.tryParse(dto.followedAt!),
      targetFollowerCount: dto.targetFollowerCount,
      targetFollowingCount: dto.targetFollowingCount,
    );
  }

  UserFollowSummary _toFollowSummary(UserFollowSummaryDto dto) {
    final followedAt =
        DateTime.tryParse(dto.followedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return UserFollowSummary(
      userId: dto.userId,
      displayName: dto.displayName,
      avatarUrl: dto.avatarUrl,
      bio: dto.bio,
      followedAt: followedAt,
    );
  }
}
