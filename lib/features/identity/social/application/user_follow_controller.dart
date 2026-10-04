/// EN: User follow controller backed by follow APIs.
/// KO: 팔로우 API 기반 사용자 팔로우 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

import '../domain/entities/social_entities.dart';
import 'social_repository_provider.dart';

class UserFollowController extends StateNotifier<AsyncValue<UserFollowStatus>> {
  UserFollowController(this._ref, this.userId) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String userId;

  Future<void> load() async {
    if (userId.isEmpty) {
      state = AsyncError(
        const ValidationFailure(
          'Target user ID is empty',
          code: 'follow_target_empty',
        ),
        StackTrace.current,
      );
      return;
    }

    final isAuthenticated = _ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      state = AsyncError(
        const AuthFailure('Login required', code: 'auth_required'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(socialRepositoryProvider.future);
    final result = await repository.getFollowStatus(userId: userId);
    if (result is Success<UserFollowStatus>) {
      state = AsyncData(result.data);
    } else if (result is Err<UserFollowStatus>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<Result<bool>> toggleFollow() async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (current?.following == true) {
      return _unfollow();
    }
    return _follow();
  }

  Future<Result<bool>> _follow() async {
    final repository = await _ref.read(socialRepositoryProvider.future);
    final result = await repository.followUser(userId: userId);
    if (result is Success<UserFollowStatus>) {
      state = AsyncData(result.data);
      return Result.success(result.data.following);
    }
    if (result is Err<UserFollowStatus>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }
    return const Result.failure(
      UnknownFailure('Unknown follow result', code: 'unknown_follow_result'),
    );
  }

  Future<Result<bool>> _unfollow() async {
    final repository = await _ref.read(socialRepositoryProvider.future);
    final result = await repository.unfollowUser(userId: userId);
    if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
      return Result.failure(result.failure);
    }

    final statusResult = await repository.getFollowStatus(userId: userId);
    if (statusResult is Success<UserFollowStatus>) {
      state = AsyncData(statusResult.data);
      return Result.success(statusResult.data.following);
    }
    if (statusResult is Err<UserFollowStatus>) {
      state = AsyncError(statusResult.failure, StackTrace.current);
      return Result.failure(statusResult.failure);
    }
    return const Result.success(false);
  }
}

/// EN: User follow state provider.
/// KO: 사용자 팔로우 상태 프로바이더.
final userFollowControllerProvider = StateNotifierProvider.autoDispose
    .family<UserFollowController, AsyncValue<UserFollowStatus>, String>((
      ref,
      userId,
    ) {
      return UserFollowController(ref, userId);
    });
