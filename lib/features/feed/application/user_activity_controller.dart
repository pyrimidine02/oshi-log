/// EN: User activity controller for community posts/comments.
/// KO: 커뮤니티 글/댓글 사용자 활동 컨트롤러.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/feed_entities.dart';
import 'feed_controller.dart';

class UserActivity {
  const UserActivity({required this.posts, required this.comments});

  final List<PostSummary> posts;
  final List<PostComment> comments;
}

class UserActivityController extends StateNotifier<AsyncValue<UserActivity>> {
  UserActivityController(this._ref, this.userId) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final String userId;

  Future<void> load({bool forceRefresh = false}) async {
    final projectKey = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) {
      state = AsyncError(
        const UnknownFailure(
          'Project selection required',
          code: 'project_required',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(feedRepositoryProvider.future);

    final postsFuture = repository.getPostsByAuthor(
      projectCode: projectKey,
      userId: userId,
      page: 0,
      size: 50,
      forceRefresh: forceRefresh,
    );
    final commentsFuture = repository.getCommentsByAuthor(
      projectCode: projectKey,
      userId: userId,
      page: 0,
      size: 50,
      forceRefresh: forceRefresh,
    );

    final results = await Future.wait([postsFuture, commentsFuture]);
    final postsResult = results[0] as Result<List<PostSummary>>;
    final commentsResult = results[1] as Result<List<PostComment>>;

    // EN: Surface error only when both requests fail.
    // KO: 두 요청이 모두 실패한 경우에만 오류 상태로 표시합니다.
    if (postsResult is Err<List<PostSummary>> &&
        commentsResult is Err<List<PostComment>>) {
      state = AsyncError(postsResult.failure, StackTrace.current);
      return;
    }

    final posts = postsResult is Success<List<PostSummary>>
        ? postsResult.data
        : <PostSummary>[];
    final comments = commentsResult is Success<List<PostComment>>
        ? commentsResult.data
        : <PostComment>[];

    state = AsyncData(UserActivity(posts: posts, comments: comments));
  }
}

/// EN: User activity controller provider.
/// KO: 사용자 활동 컨트롤러 프로바이더.
final userActivityControllerProvider = StateNotifierProvider.autoDispose
    .family<UserActivityController, AsyncValue<UserActivity>, String>((
      ref,
      userId,
    ) {
      return UserActivityController(ref, userId);
    });
