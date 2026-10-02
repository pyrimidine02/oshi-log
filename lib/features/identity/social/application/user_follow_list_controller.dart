/// EN: Providers for user follower/following lists.
/// KO: 사용자 팔로워/팔로잉 목록 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';

import '../domain/entities/social_entities.dart';
import 'social_repository_provider.dart';

final userFollowersProvider = FutureProvider.autoDispose
    .family<List<UserFollowSummary>, String>((ref, userId) async {
      if (userId.isEmpty) {
        throw const ValidationFailure(
          'Target user ID is empty',
          code: 'follow_target_empty',
        );
      }
      final repository = await ref.read(socialRepositoryProvider.future);
      final result = await repository.getFollowers(userId: userId, size: 100);
      if (result is Success<List<UserFollowSummary>>) {
        return result.data;
      }
      if (result is Err<List<UserFollowSummary>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown followers provider result',
        code: 'unknown_followers_provider_result',
      );
    });

final userFollowingProvider = FutureProvider.autoDispose
    .family<List<UserFollowSummary>, String>((ref, userId) async {
      if (userId.isEmpty) {
        throw const ValidationFailure(
          'Target user ID is empty',
          code: 'follow_target_empty',
        );
      }
      final repository = await ref.read(socialRepositoryProvider.future);
      final result = await repository.getFollowing(userId: userId, size: 100);
      if (result is Success<List<UserFollowSummary>>) {
        return result.data;
      }
      if (result is Err<List<UserFollowSummary>>) {
        throw result.failure;
      }
      throw const UnknownFailure(
        'Unknown following provider result',
        code: 'unknown_following_provider_result',
      );
    });
