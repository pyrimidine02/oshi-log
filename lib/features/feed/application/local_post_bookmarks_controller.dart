/// EN: Local post bookmarks controller — persists bookmarked posts to device storage.
/// KO: 로컬 게시글 북마크 컨트롤러 — 북마크 게시글을 기기 저장소에 유지합니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

/// EN: Lightweight model for a locally cached bookmarked post.
/// KO: 로컬 캐시에 저장된 북마크 게시글의 경량 모델.
class LocalBookmarkedPost {
  const LocalBookmarkedPost({
    required this.postId,
    required this.projectCode,
    required this.title,
    this.thumbnailUrl,
    required this.bookmarkedAt,
  });

  final String postId;
  final String projectCode;
  final String title;
  final String? thumbnailUrl;
  final DateTime bookmarkedAt;

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'projectCode': projectCode,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'bookmarkedAt': bookmarkedAt.toIso8601String(),
  };

  factory LocalBookmarkedPost.fromJson(Map<String, dynamic> json) =>
      LocalBookmarkedPost(
        postId: json['postId'] as String? ?? '',
        projectCode: json['projectCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        bookmarkedAt:
            DateTime.tryParse(json['bookmarkedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// EN: Controller that maintains a persistent local list of bookmarked posts.
/// KO: 북마크 게시글의 영속적인 로컬 목록을 관리하는 컨트롤러.
class LocalPostBookmarksController
    extends StateNotifier<List<LocalBookmarkedPost>> {
  LocalPostBookmarksController(this._ref) : super(const []) {
    _ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (previous != next) {
        _authSessionGeneration += 1;
      }
      if (!next && mounted) {
        state = const [];
      } else if (next) {
        _load();
      }
    });
    _load();
  }

  final Ref _ref;
  int _authSessionGeneration = 0;

  void _load() {
    if (!mounted || !_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    _ref.read(localStorageProvider.future).then((storage) {
      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      final raw = storage.getLocalPostBookmarks();
      state = raw
          .map((json) => LocalBookmarkedPost.fromJson(json))
          .where((entry) => entry.postId.isNotEmpty)
          .toList(growable: false);
    });
  }

  /// EN: Add a post to the local bookmarks list. No-op if already bookmarked.
  /// KO: 로컬 북마크 목록에 게시글을 추가합니다. 이미 북마크된 경우 무시합니다.
  Future<void> addBookmark(LocalBookmarkedPost entry) async {
    if (!_isAuthenticated()) {
      return;
    }
    if (state.any((e) => e.postId == entry.postId)) return;
    final sessionGeneration = _authSessionGeneration;
    final updated = [entry, ...state];
    state = updated;
    final storage = await _ref.read(localStorageProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await storage.setLocalPostBookmarks(
      updated.map((e) => e.toJson()).toList(growable: false),
    );
  }

  /// EN: Remove a post from the local bookmarks list by post ID.
  /// KO: 게시글 ID로 로컬 북마크 목록에서 해당 게시글을 제거합니다.
  Future<void> removeBookmark(String postId) async {
    if (!_isAuthenticated()) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    final updated = state
        .where((e) => e.postId != postId)
        .toList(growable: false);
    if (updated.length == state.length) return;
    state = updated;
    final storage = await _ref.read(localStorageProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await storage.setLocalPostBookmarks(
      updated.map((e) => e.toJson()).toList(growable: false),
    );
  }

  /// EN: Check if a post is locally bookmarked.
  /// KO: 게시글이 로컬에 북마크되어 있는지 확인합니다.
  bool isBookmarked(String postId) => state.any((e) => e.postId == postId);

  bool _isAuthenticated() {
    return mounted && _ref.read(isAuthenticatedProvider);
  }

  bool _isCurrentAuthSession(int sessionGeneration) {
    return mounted &&
        sessionGeneration == _authSessionGeneration &&
        _ref.read(isAuthenticatedProvider);
  }
}

/// EN: Local post bookmarks controller provider.
/// KO: 로컬 게시글 북마크 컨트롤러 프로바이더.
final localPostBookmarksControllerProvider =
    StateNotifierProvider<
      LocalPostBookmarksController,
      List<LocalBookmarkedPost>
    >((ref) => LocalPostBookmarksController(ref));
