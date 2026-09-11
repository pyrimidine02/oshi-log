/// EN: Post reaction controllers (like/bookmark).
/// KO: 게시글 반응 컨트롤러(좋아요/북마크).
library;

import 'dart:async' show unawaited;

import '../../../core/connectivity/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../../projects/application/projects_controller.dart';
import '../domain/entities/feed_entities.dart';
import '../domain/repositories/feed_repository.dart';
import 'feed_repository_provider.dart';
import 'pending_post_reaction_mutation.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

/// EN: Resolve feed reaction project reference(id/code) into project code.
/// KO: 피드 반응용 프로젝트 참조값(id/code)을 프로젝트 코드로 해석합니다.
String? _normalizeProjectCode(Ref ref, String? rawReference) {
  final reference = rawReference?.trim() ?? '';
  if (reference.isEmpty) {
    return null;
  }

  final projects = ref.read(projectsControllerProvider).valueOrNull;
  if (projects != null) {
    for (final project in projects) {
      if (project.code == reference || project.id == reference) {
        return project.code.isNotEmpty ? project.code : project.id;
      }
    }
  }

  final selectedProjectId = ref.read(selectedProjectIdProvider);
  final selectedProjectKey = ref.read(selectedProjectKeyProvider);
  if (selectedProjectId != null &&
      selectedProjectId == reference &&
      selectedProjectKey != null &&
      selectedProjectKey.isNotEmpty) {
    return selectedProjectKey;
  }

  if (_uuidPattern.hasMatch(reference)) {
    return null;
  }

  return reference;
}

String? _resolveReactionProjectCode(Ref ref, PostReactionTarget target) {
  final override = _normalizeProjectCode(ref, target.projectCodeOverride);
  if (override != null && override.isNotEmpty) {
    return override;
  }

  final selectedProjectKey = ref.read(selectedProjectKeyProvider);
  if (selectedProjectKey == null || selectedProjectKey.isEmpty) {
    return null;
  }
  return selectedProjectKey;
}

bool _shouldQueueMutationForRetry(Failure failure) {
  return failure is NetworkFailure || failure is AuthFailure;
}

PostLikeStatus _buildOptimisticLikeStatus({
  required PostLikeStatus? current,
  required String postId,
  required bool targetIsLiked,
}) {
  final currentCount = current?.likeCount ?? 0;
  final nextCount = targetIsLiked
      ? currentCount + 1
      : (currentCount <= 0 ? 0 : currentCount - 1);
  return PostLikeStatus(
    postId: current?.postId.isNotEmpty == true ? current!.postId : postId,
    isLiked: targetIsLiked,
    likeCount: nextCount,
  );
}

PostBookmarkStatus _buildOptimisticBookmarkStatus({
  required PostBookmarkStatus? current,
  required String postId,
  required bool targetIsBookmarked,
}) {
  return PostBookmarkStatus(
    postId: current?.postId.isNotEmpty == true ? current!.postId : postId,
    isBookmarked: targetIsBookmarked,
    bookmarkedAt: targetIsBookmarked ? DateTime.now() : null,
  );
}

/// EN: Identifies a post reaction request context.
/// KO: 게시글 반응 요청 컨텍스트를 식별합니다.
class PostReactionTarget {
  const PostReactionTarget({required this.postId, this.projectCodeOverride});

  final String postId;
  final String? projectCodeOverride;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PostReactionTarget &&
            other.postId == postId &&
            other.projectCodeOverride == projectCodeOverride;
  }

  @override
  int get hashCode => Object.hash(postId, projectCodeOverride);
}

/// EN: Offline outbox controller for post reaction mutations.
/// KO: 게시글 반응 오프라인 대기열(아웃박스) 컨트롤러입니다.
class PostReactionOutboxController {
  PostReactionOutboxController(this._ref) {
    _ref.onDispose(() {
      _disposed = true;
    });
    _ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (
      _,
      next,
    ) {
      if (next.valueOrNull == ConnectivityStatus.online) {
        unawaited(syncPendingMutations());
      }
    });
    _ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (previous != next) {
        _authSessionGeneration += 1;
      }
      if (next && previous != true) {
        unawaited(syncPendingMutations());
      }
    });
    unawaited(syncPendingMutations());
  }

  final Ref _ref;
  bool _isSyncing = false;
  bool _disposed = false;
  int _authSessionGeneration = 0;
  static const int _maxPendingMutations = 400;

  Future<void> enqueueLike({
    required String projectCode,
    required String postId,
    required bool targetIsLiked,
  }) async {
    if (_disposed) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    await _enqueueMutation(
      PendingPostReactionMutation(
        projectCode: projectCode,
        postId: postId,
        type: PostReactionMutationType.like,
        enabled: targetIsLiked,
        queuedAt: DateTime.now(),
      ),
      sessionGeneration: sessionGeneration,
    );
  }

  Future<void> enqueueBookmark({
    required String projectCode,
    required String postId,
    required bool targetIsBookmarked,
  }) async {
    if (_disposed) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    await _enqueueMutation(
      PendingPostReactionMutation(
        projectCode: projectCode,
        postId: postId,
        type: PostReactionMutationType.bookmark,
        enabled: targetIsBookmarked,
        queuedAt: DateTime.now(),
      ),
      sessionGeneration: sessionGeneration,
    );
  }

  Future<void> removePending({
    required String projectCode,
    required String postId,
    required PostReactionMutationType type,
  }) async {
    if (_disposed) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    final pending = await _readPendingMutations();
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    final before = pending.length;
    pending.removeWhere(
      (mutation) =>
          mutation.projectCode == projectCode &&
          mutation.postId == postId &&
          mutation.type == type,
    );
    if (pending.length != before) {
      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      await _writePendingMutations(
        pending,
        sessionGeneration: sessionGeneration,
      );
    }
  }

  Future<void> syncPendingMutations() async {
    if (_disposed) {
      return;
    }
    if (_isSyncing) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;

    final isOnline = await _ref.read(connectivityServiceProvider).isOnline;
    if (!isOnline || !_isCurrentAuthSession(sessionGeneration)) {
      return;
    }

    _isSyncing = true;
    try {
      final pending = await _readPendingMutations();
      if (!_isCurrentAuthSession(sessionGeneration) || pending.isEmpty) {
        return;
      }

      final repository = await _ref.read(feedRepositoryProvider.future);
      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      final remaining = <PendingPostReactionMutation>[];

      for (var i = 0; i < pending.length; i += 1) {
        if (!_isCurrentAuthSession(sessionGeneration)) {
          return;
        }
        final mutation = pending[i];
        final result = await _applyMutation(
          repository: repository,
          mutation: mutation,
          sessionGeneration: sessionGeneration,
        );
        if (!_isCurrentAuthSession(sessionGeneration)) {
          return;
        }

        if (result is Success<void>) {
          continue;
        }

        if (result is Err<void>) {
          if (_shouldQueueMutationForRetry(result.failure)) {
            remaining.add(mutation);
            remaining.addAll(pending.skip(i + 1));
            break;
          }
          // EN: Drop non-retriable mutation.
          // KO: 재시도 불가능한 작업은 대기열에서 제거합니다.
          continue;
        }
      }

      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      await _writePendingMutations(
        remaining,
        sessionGeneration: sessionGeneration,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<Result<void>> _applyMutation({
    required FeedRepository repository,
    required PendingPostReactionMutation mutation,
    required int sessionGeneration,
  }) async {
    switch (mutation.type) {
      case PostReactionMutationType.like:
        Result<PostLikeStatus> result = mutation.enabled
            ? await repository.likePost(
                projectCode: mutation.projectCode,
                postId: mutation.postId,
              )
            : await repository.unlikePost(
                projectCode: mutation.projectCode,
                postId: mutation.postId,
              );

        if (!mutation.enabled && result is Err<PostLikeStatus>) {
          if (!_isCurrentAuthSession(sessionGeneration)) {
            return const Result.failure(
              AuthFailure(
                'Authentication session changed',
                code: 'auth_session_changed',
              ),
            );
          }
          final selectedProjectId = _ref.read(selectedProjectIdProvider);
          final shouldRetryWithProjectId =
              selectedProjectId != null &&
              selectedProjectId.isNotEmpty &&
              selectedProjectId != mutation.projectCode &&
              result.failure is ServerFailure &&
              result.failure.code == '500';
          if (shouldRetryWithProjectId) {
            result = await repository.unlikePost(
              projectCode: selectedProjectId,
              postId: mutation.postId,
            );
          }
        }
        if (result is Success<PostLikeStatus>) {
          return const Result.success(null);
        }
        if (result is Err<PostLikeStatus>) {
          return Result.failure(result.failure);
        }
        return const Result.failure(
          UnknownFailure(
            'Unknown post like mutation result',
            code: 'unknown_post_like_mutation',
          ),
        );
      case PostReactionMutationType.bookmark:
        final result = mutation.enabled
            ? await repository.bookmarkPost(
                projectCode: mutation.projectCode,
                postId: mutation.postId,
              )
            : await repository.unbookmarkPost(
                projectCode: mutation.projectCode,
                postId: mutation.postId,
              );
        if (result is Success<PostBookmarkStatus>) {
          return const Result.success(null);
        }
        if (result is Err<PostBookmarkStatus>) {
          return Result.failure(result.failure);
        }
        return const Result.failure(
          UnknownFailure(
            'Unknown post bookmark mutation result',
            code: 'unknown_post_bookmark_mutation',
          ),
        );
      case PostReactionMutationType.unknown:
        return const Result.failure(
          ValidationFailure('Unknown post reaction mutation type'),
        );
    }
  }

  Future<void> _enqueueMutation(
    PendingPostReactionMutation mutation, {
    required int sessionGeneration,
  }) async {
    final pending = await _readPendingMutations();
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    pending.removeWhere(
      (item) =>
          item.projectCode == mutation.projectCode &&
          item.postId == mutation.postId &&
          item.type == mutation.type,
    );
    pending.add(mutation);
    if (pending.length > _maxPendingMutations) {
      pending.removeRange(0, pending.length - _maxPendingMutations);
    }
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await _writePendingMutations(pending, sessionGeneration: sessionGeneration);
  }

  bool _isCurrentAuthSession(int generation) {
    return !_disposed &&
        generation == _authSessionGeneration &&
        _ref.read(isAuthenticatedProvider);
  }

  Future<List<PendingPostReactionMutation>> _readPendingMutations() async {
    final storage = await _ref.read(localStorageProvider.future);
    final raw = storage.getPendingPostReactionMutations();
    return raw
        .map(PendingPostReactionMutation.fromJson)
        .where(
          (mutation) =>
              mutation.projectCode.isNotEmpty &&
              mutation.postId.isNotEmpty &&
              mutation.type != PostReactionMutationType.unknown,
        )
        .toList(growable: true);
  }

  Future<void> _writePendingMutations(
    List<PendingPostReactionMutation> pending, {
    required int sessionGeneration,
  }) async {
    final storage = await _ref.read(localStorageProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await storage.setPendingPostReactionMutations(
      pending.map((mutation) => mutation.toJson()).toList(growable: false),
    );
  }
}

/// EN: Post like status controller provider.
/// KO: 게시글 좋아요 상태 컨트롤러 프로바이더.
class PostLikeController extends StateNotifier<AsyncValue<PostLikeStatus>> {
  PostLikeController(this._ref, this.target) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final PostReactionTarget target;

  Future<void> load() async {
    final projectCode = _resolveReactionProjectCode(_ref, target);
    if (projectCode == null || projectCode.isEmpty) {
      state = AsyncError(
        const AuthFailure(
          'Project selection required',
          code: 'project_required',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await repository.getPostLikeStatus(
      projectCode: projectCode,
      postId: target.postId,
    );

    // EN: Guard against setting state after disposal (autoDispose + navigation).
    // KO: 자동 dispose 후 네비게이션 복귀 시 state 설정 방지.
    if (!mounted) return;
    if (result is Success<PostLikeStatus>) {
      state = AsyncData(result.data);
    } else if (result is Err<PostLikeStatus>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<Result<PostLikeStatus>> toggleLike() async {
    final projectCode = _resolveReactionProjectCode(_ref, target);
    if (projectCode == null || projectCode.isEmpty) {
      const failure = AuthFailure(
        'Project selection required',
        code: 'project_required',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    final targetIsLiked = !(current?.isLiked ?? false);
    final optimistic = _buildOptimisticLikeStatus(
      current: current,
      postId: target.postId,
      targetIsLiked: targetIsLiked,
    );
    state = AsyncData(optimistic);

    final outbox = _ref.read(postReactionOutboxControllerProvider);
    final isOnline = await _ref.read(connectivityServiceProvider).isOnline;
    if (!isOnline) {
      await outbox.enqueueLike(
        projectCode: projectCode,
        postId: target.postId,
        targetIsLiked: targetIsLiked,
      );
      return Result.success(optimistic);
    }

    final repository = await _ref.read(feedRepositoryProvider.future);
    final isUnlikeFlow = current?.isLiked == true;
    Result<PostLikeStatus> result = isUnlikeFlow
        ? await repository.unlikePost(
            projectCode: projectCode,
            postId: target.postId,
          )
        : await repository.likePost(
            projectCode: projectCode,
            postId: target.postId,
          );

    if (isUnlikeFlow && result is Err<PostLikeStatus>) {
      final selectedProjectId = _ref.read(selectedProjectIdProvider);
      final shouldRetryWithProjectId =
          selectedProjectId != null &&
          selectedProjectId.isNotEmpty &&
          selectedProjectId != projectCode &&
          result.failure is ServerFailure &&
          result.failure.code == '500';

      // EN: Backend workaround — retry unlike once with UUID projectId when
      // slug-based unlike returns 500 but like endpoint works.
      // KO: 백엔드 우회 — slug 기반 unlike에서 500이 발생하면 UUID projectId로
      // 한 번 재시도합니다.
      if (shouldRetryWithProjectId) {
        result = await repository.unlikePost(
          projectCode: selectedProjectId,
          postId: target.postId,
        );
      }
    }

    if (result is Success<PostLikeStatus>) {
      state = AsyncData(result.data);
      await outbox.removePending(
        projectCode: projectCode,
        postId: target.postId,
        type: PostReactionMutationType.like,
      );
    } else if (result is Err<PostLikeStatus>) {
      if (_shouldQueueMutationForRetry(result.failure)) {
        await outbox.enqueueLike(
          projectCode: projectCode,
          postId: target.postId,
          targetIsLiked: targetIsLiked,
        );
        state = AsyncData(optimistic);
        return Result.success(optimistic);
      }
      // EN: Preserve current data on toggle failure to avoid breaking action UI.
      // KO: 토글 실패 시 액션 UI가 깨지지 않도록 현재 데이터를 유지합니다.
      if (current != null) {
        state = AsyncData(current);
      } else {
        state = AsyncError(result.failure, StackTrace.current);
      }
    }

    return result;
  }
}

/// EN: Post bookmark status controller provider.
/// KO: 게시글 북마크 상태 컨트롤러 프로바이더.
class PostBookmarkController
    extends StateNotifier<AsyncValue<PostBookmarkStatus>> {
  PostBookmarkController(this._ref, this.target) : super(const AsyncLoading()) {
    load();
  }

  final Ref _ref;
  final PostReactionTarget target;

  Future<void> load() async {
    final projectCode = _resolveReactionProjectCode(_ref, target);
    if (projectCode == null || projectCode.isEmpty) {
      state = AsyncError(
        const AuthFailure(
          'Project selection required',
          code: 'project_required',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await repository.getPostBookmarkStatus(
      projectCode: projectCode,
      postId: target.postId,
    );

    // EN: Guard against setting state after disposal (autoDispose + navigation).
    // KO: 자동 dispose 후 네비게이션 복귀 시 state 설정 방지.
    if (!mounted) return;
    if (result is Success<PostBookmarkStatus>) {
      state = AsyncData(result.data);
    } else if (result is Err<PostBookmarkStatus>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<Result<PostBookmarkStatus>> toggleBookmark() async {
    final projectCode = _resolveReactionProjectCode(_ref, target);
    if (projectCode == null || projectCode.isEmpty) {
      const failure = AuthFailure(
        'Project selection required',
        code: 'project_required',
      );
      state = AsyncError(failure, StackTrace.current);
      return Result.failure(failure);
    }

    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    final targetIsBookmarked = !(current?.isBookmarked ?? false);
    final optimistic = _buildOptimisticBookmarkStatus(
      current: current,
      postId: target.postId,
      targetIsBookmarked: targetIsBookmarked,
    );
    state = AsyncData(optimistic);

    final outbox = _ref.read(postReactionOutboxControllerProvider);
    final isOnline = await _ref.read(connectivityServiceProvider).isOnline;
    if (!isOnline) {
      await outbox.enqueueBookmark(
        projectCode: projectCode,
        postId: target.postId,
        targetIsBookmarked: targetIsBookmarked,
      );
      return Result.success(optimistic);
    }

    final repository = await _ref.read(feedRepositoryProvider.future);

    final result = current?.isBookmarked == true
        ? await repository.unbookmarkPost(
            projectCode: projectCode,
            postId: target.postId,
          )
        : await repository.bookmarkPost(
            projectCode: projectCode,
            postId: target.postId,
          );

    if (result is Success<PostBookmarkStatus>) {
      state = AsyncData(result.data);
      await outbox.removePending(
        projectCode: projectCode,
        postId: target.postId,
        type: PostReactionMutationType.bookmark,
      );
    } else if (result is Err<PostBookmarkStatus>) {
      if (_shouldQueueMutationForRetry(result.failure)) {
        await outbox.enqueueBookmark(
          projectCode: projectCode,
          postId: target.postId,
          targetIsBookmarked: targetIsBookmarked,
        );
        state = AsyncData(optimistic);
        return Result.success(optimistic);
      }
      state = AsyncError(result.failure, StackTrace.current);
    }

    return result;
  }
}

/// EN: Post reaction outbox controller provider.
/// KO: 게시글 반응 오프라인 대기열 컨트롤러 프로바이더.
final postReactionOutboxControllerProvider =
    Provider<PostReactionOutboxController>((ref) {
      return PostReactionOutboxController(ref);
    });

/// EN: App-scope bootstrap provider for post reaction outbox auto-sync.
/// KO: 게시글 반응 오프라인 대기열 자동 동기화 앱 전역 부트스트랩 프로바이더.
final postReactionOutboxBootstrapProvider = Provider<void>((ref) {
  ref.watch(postReactionOutboxControllerProvider);
});

/// EN: Post like controller provider.
/// KO: 게시글 좋아요 컨트롤러 프로바이더.
final postLikeControllerProvider = StateNotifierProvider.autoDispose
    .family<PostLikeController, AsyncValue<PostLikeStatus>, PostReactionTarget>(
      (ref, target) {
        return PostLikeController(ref, target);
      },
    );

/// EN: Post bookmark controller provider.
/// KO: 게시글 북마크 컨트롤러 프로바이더.
final postBookmarkControllerProvider = StateNotifierProvider.autoDispose
    .family<
      PostBookmarkController,
      AsyncValue<PostBookmarkStatus>,
      PostReactionTarget
    >((ref, target) {
      return PostBookmarkController(ref, target);
    });
