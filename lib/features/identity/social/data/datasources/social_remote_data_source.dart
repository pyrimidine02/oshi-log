/// EN: Remote data source for social (follow/block) actions.
/// KO: 소셜(팔로우/차단) 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';

import '../dto/social_dto.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Get follow status for a target user.
  /// KO: 대상 사용자 팔로우 상태를 조회합니다.
  Future<Result<UserFollowStatusDto>> getFollowStatus({
    required String userId,
  }) {
    return _apiClient.get<UserFollowStatusDto>(
      ApiEndpoints.userFollow(userId),
      fromJson: (json) => UserFollowStatusDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Follow a user.
  /// KO: 사용자를 팔로우합니다.
  Future<Result<UserFollowStatusDto>> followUser({required String userId}) {
    return _apiClient.post<UserFollowStatusDto>(
      ApiEndpoints.userFollow(userId),
      fromJson: (json) => UserFollowStatusDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }

  /// EN: Unfollow a user.
  /// KO: 사용자 팔로우를 해제합니다.
  Future<Result<void>> unfollowUser({required String userId}) {
    return _apiClient.delete<void>(
      ApiEndpoints.userFollow(userId),
      fromJson: (_) {},
    );
  }

  /// EN: Get followers list for a user.
  /// KO: 사용자 팔로워 목록을 조회합니다.
  Future<Result<List<UserFollowSummaryDto>>> getFollowers({
    required String userId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<UserFollowSummaryDto>>(
      ApiEndpoints.userFollowers(userId),
      queryParameters: {'page': page, 'size': size, 'pageable': '$page,$size'},
      fromJson: (json) {
        final list = json is List ? json : const <dynamic>[];
        return list
            .whereType<Map<String, dynamic>>()
            .map(UserFollowSummaryDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Get following list for a user.
  /// KO: 사용자가 팔로우 중인 목록을 조회합니다.
  Future<Result<List<UserFollowSummaryDto>>> getFollowing({
    required String userId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<UserFollowSummaryDto>>(
      ApiEndpoints.userFollowing(userId),
      queryParameters: {'page': page, 'size': size, 'pageable': '$page,$size'},
      fromJson: (json) {
        final list = json is List ? json : const <dynamic>[];
        return list
            .whereType<Map<String, dynamic>>()
            .map(UserFollowSummaryDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Check block status for a user.
  /// KO: 특정 사용자 차단 상태를 확인합니다.
  Future<Result<BlockCheckDto>> checkBlockStatus({required String userId}) {
    return _apiClient.get<BlockCheckDto>(
      ApiEndpoints.userBlocked(userId),
      fromJson: (json) => BlockCheckDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Block a user.
  /// KO: 사용자를 차단합니다.
  Future<Result<void>> blockUser({required BlockCreateRequestDto request}) {
    return _apiClient.post<void>(
      ApiEndpoints.userBlocks,
      data: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// EN: Unblock a user.
  /// KO: 사용자를 차단 해제합니다.
  Future<Result<void>> unblockUser({required String userId}) {
    return _apiClient.delete<void>(
      ApiEndpoints.userBlock(userId),
      fromJson: (_) {},
    );
  }
}
