/// EN: Community moderation controllers.
/// KO: 커뮤니티 신고/차단 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/session_state.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/community_remote_data_source.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/entities/community_moderation.dart';
import '../domain/repositories/community_repository.dart';

class BlockStatusController extends StateNotifier<AsyncValue<BlockStatus>> {
  BlockStatusController(this._ref, this.userId) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String userId;

  Future<void> load() async {
    final isAuthenticated = _ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      state = AsyncError(
        const AuthFailure('Login required', code: 'auth_required'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(communityRepositoryProvider.future);
    final result = await repository.getBlockStatus(userId: userId);

    // EN: Guard against setting state after disposal (autoDispose + navigation).
    // KO: 자동 dispose 후 네비게이션 복귀 시 state 설정 방지.
    if (!mounted) return;
    if (result is Success<BlockStatus>) {
      state = AsyncData(result.data);
    } else if (result is Err<BlockStatus>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<Result<void>> blockUser({String? reason}) async {
    final repository = await _ref.read(communityRepositoryProvider.future);
    final result = await repository.blockUser(
      targetUserId: userId,
      reason: reason,
    );

    if (result is Success<void>) {
      await load();
    } else if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
    }

    return result;
  }

  Future<Result<void>> unblockUser() async {
    final repository = await _ref.read(communityRepositoryProvider.future);
    final result = await repository.unblockUser(targetUserId: userId);

    if (result is Success<void>) {
      await load();
    } else if (result is Err<void>) {
      state = AsyncError(result.failure, StackTrace.current);
    }

    return result;
  }

  Future<Result<void>> toggleBlock({String? reason}) async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (current?.blockedByMe == true) {
      return unblockUser();
    }
    return blockUser(reason: reason);
  }
}

/// EN: Community repository provider.
/// KO: 커뮤니티 리포지토리 프로바이더.
final communityRepositoryProvider = FutureProvider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepositoryImpl(
    remoteDataSource: CommunityRemoteDataSource(apiClient),
  );
});

/// EN: Block status controller provider.
/// KO: 차단 상태 컨트롤러 프로바이더.
final blockStatusControllerProvider = StateNotifierProvider.autoDispose
    .family<BlockStatusController, AsyncValue<BlockStatus>, String>((
      ref,
      userId,
    ) {
      return BlockStatusController(ref, userId);
    });
