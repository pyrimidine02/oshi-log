/// EN: Narrow presentation adapters for the real community feed controller.
/// KO: 실제 커뮤니티 피드 컨트롤러를 위한 좁은 프레젠테이션 어댑터.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/board_controller.dart';

/// EN: Actions the clean-sheet community UI can perform on the live feed.
/// KO: 새 커뮤니티 UI가 실제 피드에서 수행할 수 있는 동작입니다.
abstract interface class FieldCommunityActions {
  Future<void> startRealtimeSync();

  Future<void> stopRealtimeSync();

  Future<void> selectMode(CommunityFeedMode mode);

  Future<void> refresh();

  Future<void> refreshInBackground({required Duration minInterval});

  Future<void> loadMore();

  void applyPendingPosts();
}

final class _RiverpodFieldCommunityActions implements FieldCommunityActions {
  const _RiverpodFieldCommunityActions(this._ref);

  final Ref _ref;

  CommunityFeedController get _controller =>
      _ref.read(communityFeedControllerProvider.notifier);

  @override
  void applyPendingPosts() => _controller.applyPendingPosts();

  @override
  Future<void> loadMore() => _controller.loadMore();

  @override
  Future<void> refresh() => _controller.reload(forceRefresh: true);

  @override
  Future<void> refreshInBackground({required Duration minInterval}) =>
      _controller.refreshInBackground(minInterval: minInterval);

  @override
  Future<void> selectMode(CommunityFeedMode mode) => _controller.setMode(mode);

  @override
  Future<void> startRealtimeSync() => _controller.startRealtimeSync();

  @override
  Future<void> stopRealtimeSync() => _controller.stopRealtimeSync();
}

/// EN: Read-only live feed projection used by the field-report timeline.
/// KO: 필드 리포트 타임라인이 사용하는 읽기 전용 실제 피드 투영입니다.
final fieldCommunityFeedStateProvider =
    Provider.autoDispose<CommunityFeedViewState>((ref) {
      return ref.watch(communityFeedControllerProvider);
    });

/// EN: Testable action boundary backed by the existing production controller.
/// KO: 기존 운영 컨트롤러로 동작하는 테스트 가능한 액션 경계입니다.
final fieldCommunityActionsProvider =
    Provider.autoDispose<FieldCommunityActions>((ref) {
      return _RiverpodFieldCommunityActions(ref);
    });
