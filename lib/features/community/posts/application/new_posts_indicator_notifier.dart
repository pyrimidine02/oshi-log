/// EN: Twitter-style new posts indicator — polls silently and buffers new posts.
/// KO: 트위터 스타일 새 게시글 인디케이터 — 조용히 폴링하여 새 게시글을 버퍼에 저장합니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/community/posts/application/board_controller.dart';
import 'package:oshi_log/features/community/posts/application/feed_repository_provider.dart';

/// EN: State for the new posts indicator — buffered posts and pill visibility.
/// KO: 새 게시글 인디케이터 상태 — 버퍼된 게시글과 필 표시 여부.
class NewPostsIndicatorState {
  const NewPostsIndicatorState({
    this.buffered = const [],
    this.visible = false,
  });

  final List<PostSummary> buffered;
  final bool visible;

  int get count => buffered.length;

  NewPostsIndicatorState copyWith({
    List<PostSummary>? buffered,
    bool? visible,
  }) {
    return NewPostsIndicatorState(
      buffered: buffered ?? this.buffered,
      visible: visible ?? this.visible,
    );
  }
}

/// EN: Notifier that silently polls for new posts and surfaces them as a pill.
/// KO: 새 게시글을 조용히 폴링하고 필 형태로 표시하는 노티파이어.
class NewPostsIndicatorNotifier extends StateNotifier<NewPostsIndicatorState> {
  NewPostsIndicatorNotifier(this._ref) : super(const NewPostsIndicatorState()) {
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  final Ref _ref;
  Timer? _timer;

  static const Duration _pollInterval = Duration(seconds: 45);
  static const int _peekSize = 10;

  Future<void> _poll() async {
    final currentPosts = _ref.read(postListControllerProvider).valueOrNull;
    if (currentPosts == null || currentPosts.isEmpty) return;

    final projectKey = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) return;

    final sinceCreatedAt = currentPosts.first.createdAt;

    try {
      final repository = await _ref.read(feedRepositoryProvider.future);
      final result = await repository.getPosts(
        projectCode: projectKey,
        page: 0,
        size: _peekSize,
        forceRefresh: true,
      );

      if (result is! Success<List<PostSummary>>) return;
      final freshPosts = result.data;

      // EN: Collect posts newer than the current top — by timestamp comparison.
      // KO: 현재 최상단보다 새로운 게시글을 타임스탬프 비교로 수집합니다.
      final newPosts = freshPosts
          .where((p) => p.createdAt.isAfter(sinceCreatedAt))
          .toList(growable: false);

      if (newPosts.isEmpty) return;

      state = NewPostsIndicatorState(buffered: newPosts, visible: true);
    } catch (_) {
      // EN: Silently ignore polling errors — indicator is best-effort.
      // KO: 폴링 오류는 무시합니다 — 인디케이터는 최선 시도 방식입니다.
    }
  }

  /// EN: Accept buffered posts — prepend to main list and clear state.
  /// KO: 버퍼 게시글 수락 — 메인 목록에 추가하고 상태를 초기화합니다.
  void accept() {
    final posts = state.buffered;
    if (posts.isEmpty) return;
    _ref.read(postListControllerProvider.notifier).prependPosts(posts);
    state = const NewPostsIndicatorState();
  }

  /// EN: Dismiss the pill — hides it but keeps the buffer for re-show on scroll.
  /// KO: 필을 숨깁니다 — 버퍼는 유지해 스크롤 시 재표시할 수 있습니다.
  void dismiss() {
    if (!state.visible) return;
    state = state.copyWith(visible: false);
  }

  /// EN: Show the pill if there are buffered posts.
  /// KO: 버퍼된 게시글이 있을 경우 필을 표시합니다.
  void showIfBuffered() {
    if (state.buffered.isEmpty || state.visible) return;
    state = state.copyWith(visible: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// EN: Provider for the new posts indicator notifier.
/// KO: 새 게시글 인디케이터 노티파이어 프로바이더.
final newPostsIndicatorProvider =
    StateNotifierProvider.autoDispose<
      NewPostsIndicatorNotifier,
      NewPostsIndicatorState
    >((ref) => NewPostsIndicatorNotifier(ref));
