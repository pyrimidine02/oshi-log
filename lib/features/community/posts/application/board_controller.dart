/// EN: Community board list controllers (recommend/following/latest/trending).
/// KO: 커뮤니티 게시판 목록 컨트롤러(추천/팔로우/최신/인기).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/logging/app_logger.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/core/router/navigation_state.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/core/realtime/sse_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import 'feed_repository_provider.dart';

const int _kBoardNavIndex = 4;

bool _isBoardTabActive(Ref ref) {
  return ref.read(currentNavIndexProvider) == _kBoardNavIndex;
}

class PostListController extends StateNotifier<AsyncValue<List<PostSummary>>> {
  PostListController(this._ref) : super(const AsyncLoading()) {
    _ref.listen<String?>(selectedProjectKeyProvider, (_, __) {
      if (!_isBoardTabActive(_ref)) {
        return;
      }
      load(forceRefresh: true);
    });
    _ref.listen<int>(currentNavIndexProvider, (previous, next) {
      if (next != _kBoardNavIndex || next == previous) {
        return;
      }
      // EN: Only load on tab return if there is no data yet — background
      // EN: polling handles freshness while the tab is active.
      // KO: 데이터가 없을 때만 탭 복귀 시 로드 — 탭 활성 중 백그라운드 폴링이 최신성을 유지합니다.
      if (state.valueOrNull == null) load();
    });
  }

  final Ref _ref;

  /// EN: Prepend new posts to the top of the current list without a full reload.
  /// KO: 전체 재로딩 없이 새 게시글을 현재 목록 상단에 추가합니다.
  void prependPosts(List<PostSummary> posts) {
    final current = state.valueOrNull;
    if (current == null || posts.isEmpty) return;
    final existingIds = current.map((p) => p.id).toSet();
    final unique = posts.where((p) => !existingIds.contains(p.id)).toList();
    if (unique.isEmpty) return;
    state = AsyncData([...unique, ...current]);
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    final projectKey = _ref.read(selectedProjectKeyProvider);
    if (projectKey == null || projectKey.isEmpty) {
      // EN: Wait for project selection before loading.
      // KO: 로드 전 프로젝트 선택을 기다립니다.
      return;
    }

    state = const AsyncLoading();

    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await repository.getPosts(
      projectCode: projectKey,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<PostSummary>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<PostSummary>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }
}

enum CommunityFeedMode { recommended, following, latest, trending }

const Object _communityFeedNoChange = Object();

extension CommunityFeedModeX on CommunityFeedMode {
  String get label {
    final languageCode = Intl.getCurrentLocale().split(RegExp(r'[_-]')).first;
    switch (this) {
      case CommunityFeedMode.recommended:
        if (languageCode == 'en') return 'Recommended';
        if (languageCode == 'ja') return 'おすすめ';
        return '추천';
      case CommunityFeedMode.following:
        if (languageCode == 'en') return 'Following';
        if (languageCode == 'ja') return 'フォロー';
        return '팔로우';
      case CommunityFeedMode.latest:
        if (languageCode == 'en') return 'Latest';
        if (languageCode == 'ja') return '最新';
        return '최신';
      case CommunityFeedMode.trending:
        if (languageCode == 'en') return 'Trending';
        if (languageCode == 'ja') return '人気';
        return '인기';
    }
  }
}

enum CommunitySearchScope { all, title, author, content, media }

extension CommunitySearchScopeX on CommunitySearchScope {
  String get label {
    final languageCode = Intl.getCurrentLocale().split(RegExp(r'[_-]')).first;
    switch (this) {
      case CommunitySearchScope.all:
        if (languageCode == 'en') return 'All';
        if (languageCode == 'ja') return '全体';
        return '전체';
      case CommunitySearchScope.title:
        if (languageCode == 'en') return 'Title';
        if (languageCode == 'ja') return 'タイトル';
        return '제목';
      case CommunitySearchScope.author:
        if (languageCode == 'en') return 'Author';
        if (languageCode == 'ja') return '作成者';
        return '작성자';
      case CommunitySearchScope.content:
        if (languageCode == 'en') return 'Content';
        if (languageCode == 'ja') return '内容';
        return '내용';
      case CommunitySearchScope.media:
        if (languageCode == 'en') return 'Media';
        if (languageCode == 'ja') return 'メディア';
        return '미디어';
    }
  }
}

class CommunityFeedViewState {
  const CommunityFeedViewState({
    this.mode = CommunityFeedMode.recommended,
    this.searchQuery = '',
    this.searchScope = CommunitySearchScope.all,
    this.posts = const [],
    this.searchSourcePosts = const [],
    this.subscriptions = const [],
    this.pendingNewPosts = const [],
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.isSubscriptionsLoading = true,
    this.hasMore = false,
    this.page = 0,
    this.nextCursor,
    this.failure,
  });

  final CommunityFeedMode mode;
  final String searchQuery;
  final CommunitySearchScope searchScope;
  final List<PostSummary> posts;
  final List<PostSummary> searchSourcePosts;
  final List<ProjectSubscriptionSummary> subscriptions;

  /// EN: New posts detected in background, not yet applied to the main list.
  /// KO: 백그라운드에서 감지된 새 글 — 아직 메인 목록에 적용되지 않은 상태.
  final List<PostSummary> pendingNewPosts;

  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isSubscriptionsLoading;
  final bool hasMore;
  final int page;
  final String? nextCursor;
  final Failure? failure;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  /// EN: Whether there are buffered new posts ready to apply.
  /// KO: 적용 대기 중인 새 글이 있는지 여부.
  bool get hasPendingNewPosts => pendingNewPosts.isNotEmpty;

  CommunityFeedViewState copyWith({
    CommunityFeedMode? mode,
    String? searchQuery,
    CommunitySearchScope? searchScope,
    List<PostSummary>? posts,
    List<PostSummary>? searchSourcePosts,
    List<ProjectSubscriptionSummary>? subscriptions,
    List<PostSummary>? pendingNewPosts,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isSubscriptionsLoading,
    bool? hasMore,
    int? page,
    Object? nextCursor = _communityFeedNoChange,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CommunityFeedViewState(
      mode: mode ?? this.mode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchScope: searchScope ?? this.searchScope,
      posts: posts ?? this.posts,
      searchSourcePosts: searchSourcePosts ?? this.searchSourcePosts,
      subscriptions: subscriptions ?? this.subscriptions,
      pendingNewPosts: pendingNewPosts ?? this.pendingNewPosts,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubscriptionsLoading:
          isSubscriptionsLoading ?? this.isSubscriptionsLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      nextCursor: identical(nextCursor, _communityFeedNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class CommunityFeedController extends StateNotifier<CommunityFeedViewState> {
  CommunityFeedController(this._ref) : super(const CommunityFeedViewState()) {
    _ref.listen<String?>(selectedProjectKeyProvider, (_, __) {
      if (!_isBoardTabActive(_ref)) {
        return;
      }
      final requiresProjectSelection =
          state.isSearching ||
          state.mode == CommunityFeedMode.latest ||
          state.mode == CommunityFeedMode.trending;
      if (requiresProjectSelection) {
        reload(forceRefresh: true);
      }
      _loadSubscriptions(forceRefresh: true);
    });
    _ref.listen<int>(currentNavIndexProvider, (previous, next) {
      if (next != _kBoardNavIndex || next == previous) {
        return;
      }
      // EN: On tab return, only do a full reload when there is no data yet.
      // EN: With existing data, use background refresh so the visible list is not wiped.
      // KO: 탭 복귀 시 데이터가 없을 때만 전체 재로드합니다.
      // KO: 데이터가 있으면 목록을 초기화하지 않는 백그라운드 새로고침을 사용합니다.
      if (state.posts.isEmpty) {
        unawaited(_reloadForActiveBoard());
      } else {
        unawaited(refreshInBackground(minInterval: Duration.zero));
        unawaited(_loadSubscriptions());
      }
    });
    _ref.listen<bool>(isAuthenticatedProvider, (_, isAuthenticated) {
      if (!isAuthenticated) {
        unawaited(stopRealtimeSync());
        return;
      }
      if (_isRealtimeActive) {
        unawaited(_connectRealtimeSafely(origin: 'auth_state_change'));
      }
    });
  }

  final Ref _ref;
  static const int _pageSize = 20;
  bool _isBackgroundSyncing = false;
  DateTime? _lastBackgroundSyncAt;
  // EN: Guard flag preventing concurrent reload() calls from listeners/FocusDetector.
  // KO: 리스너/FocusDetector의 동시 reload() 호출을 방지하는 가드 플래그.
  bool _isReloading = false;
  SseConnection? _realtimeConnection;
  StreamSubscription<SseEvent>? _realtimeSubscription;
  Timer? _realtimeReconnectTimer;
  Duration _reconnectDelay = const Duration(seconds: 2);
  DateTime? _lastRealtimeRefreshAt;
  bool _isRealtimeActive = false;
  bool _isRealtimeConnected = false;

  Future<void> initialize() async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    await _loadSubscriptions();
    await reload();
  }

  Future<void> _reloadForActiveBoard({bool forceRefresh = false}) async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    await _loadSubscriptions(forceRefresh: forceRefresh);
    await reload(forceRefresh: forceRefresh);
  }

  /// EN: Start realtime feed sync via SSE with polling fallback.
  /// KO: 폴링 폴백을 유지한 채 SSE 기반 실시간 피드 동기화를 시작합니다.
  Future<void> startRealtimeSync() async {
    if (_isRealtimeActive) return;
    _isRealtimeActive = true;
    await _connectRealtimeSafely(origin: 'start_realtime_sync');
  }

  /// EN: Stop realtime SSE sync and keep polling fallback only.
  /// KO: SSE 실시간 동기화를 중지하고 폴링 폴백만 유지합니다.
  Future<void> stopRealtimeSync() async {
    _isRealtimeActive = false;
    _realtimeReconnectTimer?.cancel();
    _realtimeReconnectTimer = null;
    _isRealtimeConnected = false;
    await _disposeRealtimeConnection();
  }

  Future<void> _connectRealtime() async {
    if (!_isRealtimeActive || _isRealtimeConnected) return;
    if (!_ref.read(isAuthenticatedProvider)) return;
    if (_realtimeConnection != null || _realtimeSubscription != null) return;

    final sseClient = _ref.read(sseClientProvider);
    try {
      final connection = await sseClient.connect(
        path: ApiEndpoints.communityEventsStream,
      );
      _realtimeConnection = connection;
      _isRealtimeConnected = true;
      _reconnectDelay = const Duration(seconds: 2);

      _realtimeSubscription = connection.events.listen(
        _handleRealtimeEvent,
        onError: (Object error, StackTrace stackTrace) {
          if (_isExpectedStreamDisconnectError(error)) {
            AppLogger.debug(
              '[CommunityFeed] SSE disconnected while receiving data',
              tag: 'CommunityFeedController',
            );
          } else {
            AppLogger.warning(
              '[CommunityFeed] SSE error; fallback to polling',
              tag: 'CommunityFeedController',
              data: error,
            );
          }
          unawaited(
            _handleRealtimeDisconnectSafely(
              origin: 'stream_on_error',
              sourceError: error,
              sourceStackTrace: stackTrace,
            ),
          );
        },
        onDone: () {
          unawaited(_handleRealtimeDisconnectSafely(origin: 'stream_on_done'));
        },
        cancelOnError: true,
      );
    } catch (error, stackTrace) {
      AppLogger.debug(
        '[CommunityFeed] SSE connect failed; fallback to polling',
        tag: 'CommunityFeedController',
      );
      AppLogger.error(
        '[CommunityFeed] SSE connect exception',
        tag: 'CommunityFeedController',
        error: error,
        stackTrace: stackTrace,
      );
      _isRealtimeConnected = false;
      _scheduleRealtimeReconnect();
    }
  }

  void _handleRealtimeEvent(SseEvent event) {
    if (!_isRealtimeActive) return;
    if (!_isCommunityEvent(event)) return;

    final now = DateTime.now();
    if (_lastRealtimeRefreshAt != null &&
        now.difference(_lastRealtimeRefreshAt!) <
            const Duration(milliseconds: 700)) {
      return;
    }
    _lastRealtimeRefreshAt = now;
    unawaited(refreshInBackground(minInterval: Duration.zero));
  }

  bool _isCommunityEvent(SseEvent event) {
    final rawType =
        event.event ?? event.dataAsJson?['eventType']?.toString() ?? '';
    if (rawType.isEmpty) {
      return true;
    }
    final normalized = rawType.toLowerCase();
    return normalized.contains('community') ||
        normalized.contains('feed') ||
        normalized.contains('post') ||
        normalized.contains('comment') ||
        normalized.contains('notification');
  }

  Future<void> _handleRealtimeDisconnect() async {
    _isRealtimeConnected = false;
    await _disposeRealtimeConnection();
    _scheduleRealtimeReconnect();
  }

  void _scheduleRealtimeReconnect() {
    if (!_isRealtimeActive) return;
    _realtimeReconnectTimer?.cancel();
    final delay = _reconnectDelay;
    _realtimeReconnectTimer = Timer(delay, () {
      unawaited(_connectRealtimeSafely(origin: 'reconnect_timer'));
    });
    final nextSeconds = (_reconnectDelay.inSeconds * 2).clamp(2, 60);
    _reconnectDelay = Duration(seconds: nextSeconds);
  }

  Future<void> _disposeRealtimeConnection() async {
    final subscription = _realtimeSubscription;
    _realtimeSubscription = null;
    final connection = _realtimeConnection;
    _realtimeConnection = null;

    if (subscription != null) {
      try {
        await subscription.cancel();
      } catch (error, stackTrace) {
        _logRealtimeDisposeFailure(
          operation: 'subscription.cancel',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (connection != null) {
      try {
        await connection.close();
      } catch (error, stackTrace) {
        _logRealtimeDisposeFailure(
          operation: 'connection.close',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _connectRealtimeSafely({required String origin}) async {
    try {
      await _connectRealtime();
    } catch (error, stackTrace) {
      AppLogger.error(
        '[CommunityFeed] Unexpected realtime connect failure ($origin)',
        tag: 'CommunityFeedController',
        error: error,
        stackTrace: stackTrace,
      );
      _isRealtimeConnected = false;
      _scheduleRealtimeReconnect();
    }
  }

  Future<void> _handleRealtimeDisconnectSafely({
    required String origin,
    Object? sourceError,
    StackTrace? sourceStackTrace,
  }) async {
    try {
      await _handleRealtimeDisconnect();
    } catch (error, stackTrace) {
      AppLogger.error(
        '[CommunityFeed] Realtime disconnect handler failed ($origin)',
        tag: 'CommunityFeedController',
        error: error,
        stackTrace: stackTrace,
      );
      if (sourceError != null) {
        AppLogger.debug(
          '[CommunityFeed] Realtime disconnect source error',
          tag: 'CommunityFeedController',
          data: sourceError,
        );
      }
      if (sourceStackTrace != null) {
        AppLogger.debug(
          '[CommunityFeed] Realtime disconnect source stack',
          tag: 'CommunityFeedController',
          data: sourceStackTrace,
        );
      }
    }
  }

  bool _isExpectedStreamDisconnectError(Object error) {
    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      return message.contains('connection closed while receiving data') ||
          message.contains('connection closed before full header was received');
    }
    final raw = error.toString().toLowerCase();
    return raw.contains('connection closed while receiving data') ||
        raw.contains('connection closed before full header was received');
  }

  void _logRealtimeDisposeFailure({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (_isExpectedStreamDisconnectError(error)) {
      AppLogger.debug(
        '[CommunityFeed] Ignored realtime dispose failure: $operation',
        tag: 'CommunityFeedController',
        data: error,
      );
      return;
    }
    AppLogger.error(
      '[CommunityFeed] Realtime dispose failed: $operation',
      tag: 'CommunityFeedController',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void dispose() {
    _isRealtimeActive = false;
    _realtimeReconnectTimer?.cancel();
    unawaited(_disposeRealtimeConnection());
    super.dispose();
  }

  Future<void> setMode(CommunityFeedMode mode) async {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode, clearFailure: true);
    await reload(forceRefresh: true);
  }

  void setSearchScope(CommunitySearchScope scope) {
    if (scope == state.searchScope) return;

    if (!state.isSearching) {
      state = state.copyWith(searchScope: scope, clearFailure: true);
      return;
    }

    final filtered = _filterSearchResults(
      sourcePosts: state.searchSourcePosts,
      query: state.searchQuery,
      scope: scope,
    );
    state = state.copyWith(
      searchScope: scope,
      posts: filtered,
      clearFailure: true,
    );
  }

  Future<void> applySearch(String query) async {
    final trimmed = query.trim();
    if (trimmed == state.searchQuery.trim()) return;
    state = state.copyWith(
      searchQuery: trimmed,
      searchSourcePosts: const [],
      clearFailure: true,
    );
    await reload(forceRefresh: true);
  }

  Future<void> clearSearch() async {
    if (state.searchQuery.isEmpty) return;
    state = state.copyWith(
      searchQuery: '',
      searchSourcePosts: const [],
      clearFailure: true,
    );
    await reload(forceRefresh: true);
  }

  Future<void> refreshInBackground({
    Duration minInterval = const Duration(seconds: 25),
  }) async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    // EN: Keep lightweight polling even when SSE is connected to reduce
    // EN: perceived lag from delayed/missed realtime events.
    // KO: SSE가 연결되어 있어도 지연/누락 이벤트 체감을 줄이기 위해
    // KO: 가벼운 폴링을 함께 유지합니다.
    if (_isBackgroundSyncing || state.isInitialLoading || state.isLoadingMore) {
      return;
    }

    final now = DateTime.now();
    if (_lastBackgroundSyncAt != null &&
        now.difference(_lastBackgroundSyncAt!) < minInterval) {
      return;
    }

    final projectKey = _ref.read(selectedProjectKeyProvider);
    final requiresProjectSelection =
        state.isSearching ||
        state.mode == CommunityFeedMode.latest ||
        state.mode == CommunityFeedMode.trending;
    if (requiresProjectSelection &&
        (projectKey == null || projectKey.isEmpty)) {
      return;
    }

    _isBackgroundSyncing = true;
    try {
      final repository = await _ref.read(feedRepositoryProvider.future);
      if (state.isSearching) {
        final searchResult = await repository.searchPosts(
          projectCode: projectKey!,
          query: state.searchQuery,
          page: 0,
          size: _pageSize,
        );
        if (searchResult is Success<List<PostSummary>>) {
          final filtered = _filterSearchResults(
            sourcePosts: searchResult.data,
            query: state.searchQuery,
            scope: state.searchScope,
          );
          state = state.copyWith(
            posts: filtered,
            searchSourcePosts: searchResult.data,
            hasMore: false,
            nextCursor: null,
            clearFailure: true,
          );
        } else if (searchResult is Err<List<PostSummary>> &&
            state.posts.isEmpty) {
          _handleUnauthorizedFailure(searchResult.failure);
          state = state.copyWith(failure: searchResult.failure);
        }
        return;
      }
      if (_requiresAuthentication(state.mode) &&
          !_ref.read(isAuthenticatedProvider)) {
        if (state.posts.isEmpty) {
          state = state.copyWith(
            failure: const AuthFailure('Login required', code: 'auth_required'),
          );
        }
        return;
      }

      switch (state.mode) {
        case CommunityFeedMode.recommended:
          final recommendedResult = await repository
              .getCommunityRecommendedFeedByCursor(
                cursor: null,
                size: _pageSize,
              );
          if (recommendedResult is Success<PostCursorPage>) {
            final fresh = recommendedResult.data.items;
            final newPosts = _findNewPosts(fresh: fresh, current: state.posts);
            if (newPosts.isNotEmpty) {
              _accumulatePending(newPosts);
            } else {
              state = state.copyWith(
                posts: fresh,
                searchSourcePosts: const [],
                page: 0,
                hasMore: recommendedResult.data.hasNext,
                nextCursor: recommendedResult.data.nextCursor ?? '',
                clearFailure: true,
              );
            }
          } else if (recommendedResult is Err<PostCursorPage> &&
              state.posts.isEmpty) {
            _handleUnauthorizedFailure(recommendedResult.failure);
            state = state.copyWith(failure: recommendedResult.failure);
          }
        case CommunityFeedMode.latest:
          final latestResult = await repository.getPostsByCursor(
            projectCode: projectKey!,
            cursor: null,
            size: _pageSize,
          );
          if (latestResult is Success<PostCursorPage>) {
            final fresh = latestResult.data.items;
            final newPosts = _findNewPosts(fresh: fresh, current: state.posts);
            if (newPosts.isNotEmpty) {
              _accumulatePending(newPosts);
            } else {
              state = state.copyWith(
                posts: fresh,
                searchSourcePosts: const [],
                hasMore: latestResult.data.hasNext,
                nextCursor: latestResult.data.nextCursor ?? '',
                clearFailure: true,
              );
            }
          } else if (latestResult is Err<PostCursorPage> &&
              state.posts.isEmpty) {
            _handleUnauthorizedFailure(latestResult.failure);
            state = state.copyWith(failure: latestResult.failure);
          }
        case CommunityFeedMode.trending:
          // EN: Trending is rank-ordered, not time-ordered — silent update only.
          // KO: 트렌딩은 시간순이 아닌 랭킹순이므로 새 글 감지 없이 조용히 갱신합니다.
          final trendingResult = await repository.getTrendingPosts(
            projectCode: projectKey!,
            page: 0,
            size: _pageSize,
            forceRefresh: true,
          );
          if (trendingResult is Success<List<PostSummary>>) {
            state = state.copyWith(
              posts: trendingResult.data,
              searchSourcePosts: const [],
              page: 0,
              hasMore: trendingResult.data.length >= _pageSize,
              nextCursor: null,
              clearFailure: true,
            );
          } else if (trendingResult is Err<List<PostSummary>> &&
              state.posts.isEmpty) {
            _handleUnauthorizedFailure(trendingResult.failure);
            state = state.copyWith(failure: trendingResult.failure);
          }
        case CommunityFeedMode.following:
          final followingResult = await repository
              .getCommunityFollowingFeedByCursor(cursor: null, size: _pageSize);
          if (followingResult is Success<PostCursorPage>) {
            final fresh = followingResult.data.items;
            final newPosts = _findNewPosts(fresh: fresh, current: state.posts);
            if (newPosts.isNotEmpty) {
              _accumulatePending(newPosts);
            } else {
              state = state.copyWith(
                posts: fresh,
                searchSourcePosts: const [],
                hasMore: followingResult.data.hasNext,
                nextCursor: followingResult.data.nextCursor ?? '',
                clearFailure: true,
              );
            }
          } else if (followingResult is Err<PostCursorPage> &&
              state.posts.isEmpty) {
            _handleUnauthorizedFailure(followingResult.failure);
            state = state.copyWith(failure: followingResult.failure);
          }
      }
    } finally {
      _lastBackgroundSyncAt = DateTime.now();
      _isBackgroundSyncing = false;
    }
  }

  /// EN: Apply buffered new posts to the top of the main list and clear the pending buffer.
  /// KO: 대기 중인 새 글을 메인 목록 상단에 적용하고 버퍼를 비웁니다.
  void applyPendingPosts() {
    if (state.pendingNewPosts.isEmpty) return;
    final pending = state.pendingNewPosts;
    final currentIds = state.posts.map((p) => p.id).toSet();
    final unique = pending
        .where((p) => !currentIds.contains(p.id))
        .toList(growable: false);
    state = state.copyWith(
      posts: [...unique, ...state.posts],
      pendingNewPosts: const [],
    );
  }

  /// EN: Find posts in [fresh] that do not exist in [current] (new arrivals).
  /// KO: [fresh] 목록에서 [current]에 없는 새 글을 반환합니다.
  List<PostSummary> _findNewPosts({
    required List<PostSummary> fresh,
    required List<PostSummary> current,
  }) {
    if (current.isEmpty) return const []; // first load handled by reload()
    final currentIds = current.map((p) => p.id).toSet();
    return fresh
        .where((p) => !currentIds.contains(p.id))
        .toList(growable: false);
  }

  /// EN: Accumulate new posts into the pending buffer, deduplicating by ID.
  /// KO: 새 글을 ID 기준으로 중복 제거하며 대기 버퍼에 쌓습니다.
  void _accumulatePending(List<PostSummary> newPosts) {
    final existingIds = state.pendingNewPosts.map((p) => p.id).toSet();
    final unique = newPosts
        .where((p) => !existingIds.contains(p.id))
        .toList(growable: false);
    if (unique.isEmpty) return;
    state = state.copyWith(
      pendingNewPosts: [...unique, ...state.pendingNewPosts],
    );
  }

  Future<void> reload({bool forceRefresh = false}) async {
    // EN: Skip concurrent reloads — listeners and FocusDetector can fire together.
    // KO: 동시 리로드를 건너뜁니다 — 리스너와 FocusDetector가 동시에 실행될 수 있습니다.
    if (_isReloading) return;
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    _isReloading = true;
    try {
      final projectKey = _ref.read(selectedProjectKeyProvider);
      final isSearching = state.isSearching;
      final requiresProjectSelection =
          isSearching ||
          state.mode == CommunityFeedMode.latest ||
          state.mode == CommunityFeedMode.trending;
      if (requiresProjectSelection &&
          (projectKey == null || projectKey.isEmpty)) {
        state = state.copyWith(
          posts: const [],
          searchSourcePosts: const [],
          isInitialLoading: false,
          hasMore: false,
          nextCursor: null,
          page: 0,
          failure: const AuthFailure(
            'Project selection required',
            code: 'project_required',
          ),
        );
        return;
      }
      if (!isSearching &&
          _requiresAuthentication(state.mode) &&
          !_ref.read(isAuthenticatedProvider)) {
        state = state.copyWith(
          posts: const [],
          searchSourcePosts: const [],
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: false,
          nextCursor: null,
          page: 0,
          failure: const AuthFailure('Login required', code: 'auth_required'),
        );
        return;
      }

      state = state.copyWith(
        isInitialLoading: true,
        isLoadingMore: false,
        posts: const [],
        searchSourcePosts: const [],
        pendingNewPosts: const [],
        hasMore: false,
        nextCursor: null,
        page: 0,
        clearFailure: true,
      );

      final repository = await _ref.read(feedRepositoryProvider.future);
      if (isSearching) {
        final result = await repository.searchPosts(
          projectCode: projectKey!,
          query: state.searchQuery,
          page: 0,
          size: _pageSize,
        );
        if (result is Success<List<PostSummary>>) {
          final filtered = _filterSearchResults(
            sourcePosts: result.data,
            query: state.searchQuery,
            scope: state.searchScope,
          );
          state = state.copyWith(
            posts: filtered,
            searchSourcePosts: result.data,
            hasMore: false,
            nextCursor: null,
            isInitialLoading: false,
            clearFailure: true,
          );
        } else if (result is Err<List<PostSummary>>) {
          _handleUnauthorizedFailure(result.failure);
          state = state.copyWith(
            posts: const [],
            searchSourcePosts: const [],
            hasMore: false,
            nextCursor: null,
            isInitialLoading: false,
            failure: result.failure,
          );
        }
        return;
      }

      switch (state.mode) {
        case CommunityFeedMode.recommended:
          final result = await repository.getCommunityRecommendedFeedByCursor(
            cursor: null,
            size: _pageSize,
          );
          if (result is Success<PostCursorPage>) {
            state = state.copyWith(
              posts: result.data.items,
              searchSourcePosts: const [],
              page: 0,
              hasMore: result.data.hasNext,
              nextCursor: result.data.nextCursor ?? '',
              isInitialLoading: false,
              clearFailure: true,
            );
          } else if (result is Err<PostCursorPage>) {
            _handleUnauthorizedFailure(result.failure);
            state = state.copyWith(
              posts: const [],
              searchSourcePosts: const [],
              hasMore: false,
              page: 0,
              nextCursor: null,
              isInitialLoading: false,
              failure: result.failure,
            );
          }
        case CommunityFeedMode.latest:
          final result = await repository.getPostsByCursor(
            projectCode: projectKey!,
            cursor: null,
            size: _pageSize,
          );
          if (result is Success<PostCursorPage>) {
            state = state.copyWith(
              posts: result.data.items,
              searchSourcePosts: const [],
              hasMore: result.data.hasNext,
              nextCursor: result.data.nextCursor ?? '',
              isInitialLoading: false,
              clearFailure: true,
            );
          } else if (result is Err<PostCursorPage>) {
            _handleUnauthorizedFailure(result.failure);
            state = state.copyWith(
              posts: const [],
              searchSourcePosts: const [],
              hasMore: false,
              nextCursor: null,
              isInitialLoading: false,
              failure: result.failure,
            );
          }
        case CommunityFeedMode.trending:
          final result = await repository.getTrendingPosts(
            projectCode: projectKey!,
            page: 0,
            size: _pageSize,
            forceRefresh: forceRefresh,
          );
          if (result is Success<List<PostSummary>>) {
            final items = result.data;
            state = state.copyWith(
              posts: items,
              searchSourcePosts: const [],
              page: 0,
              hasMore: items.length >= _pageSize,
              nextCursor: null,
              isInitialLoading: false,
              clearFailure: true,
            );
          } else if (result is Err<List<PostSummary>>) {
            _handleUnauthorizedFailure(result.failure);
            state = state.copyWith(
              posts: const [],
              searchSourcePosts: const [],
              hasMore: false,
              page: 0,
              isInitialLoading: false,
              failure: result.failure,
            );
          }
        case CommunityFeedMode.following:
          final result = await repository.getCommunityFollowingFeedByCursor(
            cursor: null,
            size: _pageSize,
          );
          if (result is Success<PostCursorPage>) {
            state = state.copyWith(
              posts: result.data.items,
              searchSourcePosts: const [],
              hasMore: result.data.hasNext,
              nextCursor: result.data.nextCursor ?? '',
              isInitialLoading: false,
              clearFailure: true,
            );
          } else if (result is Err<PostCursorPage>) {
            _handleUnauthorizedFailure(result.failure);
            state = state.copyWith(
              posts: const [],
              searchSourcePosts: const [],
              hasMore: false,
              nextCursor: null,
              isInitialLoading: false,
              failure: result.failure,
            );
          }
      }
    } finally {
      _isReloading = false;
    }
  }

  Future<void> loadMore() async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.isSearching) return;

    final projectKey = _ref.read(selectedProjectKeyProvider);
    final requiresProjectSelection =
        state.mode == CommunityFeedMode.latest ||
        state.mode == CommunityFeedMode.trending;
    if (requiresProjectSelection &&
        (projectKey == null || projectKey.isEmpty)) {
      return;
    }
    if (_requiresAuthentication(state.mode) &&
        !_ref.read(isAuthenticatedProvider)) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final repository = await _ref.read(feedRepositoryProvider.future);

    switch (state.mode) {
      case CommunityFeedMode.recommended:
        final cursor = state.nextCursor;
        if (cursor == null || cursor.isEmpty) {
          state = state.copyWith(isLoadingMore: false, hasMore: false);
          return;
        }
        final result = await repository.getCommunityRecommendedFeedByCursor(
          cursor: cursor,
          size: _pageSize,
        );
        _appendCursorResult(result);
      case CommunityFeedMode.latest:
        final cursor = state.nextCursor;
        if (cursor == null || cursor.isEmpty) {
          state = state.copyWith(isLoadingMore: false, hasMore: false);
          return;
        }
        final result = await repository.getPostsByCursor(
          projectCode: projectKey!,
          cursor: cursor,
          size: _pageSize,
        );
        _appendCursorResult(result);
      case CommunityFeedMode.trending:
        final nextPage = state.page + 1;
        final result = await repository.getTrendingPosts(
          projectCode: projectKey!,
          page: nextPage,
          size: _pageSize,
        );
        if (result is Success<List<PostSummary>>) {
          final merged = [...state.posts, ...result.data];
          state = state.copyWith(
            posts: merged,
            page: nextPage,
            hasMore: result.data.length >= _pageSize,
            isLoadingMore: false,
            clearFailure: true,
          );
        } else if (result is Err<List<PostSummary>>) {
          _handleUnauthorizedFailure(result.failure);
          state = state.copyWith(isLoadingMore: false, failure: result.failure);
        }
      case CommunityFeedMode.following:
        final cursor = state.nextCursor;
        if (cursor == null || cursor.isEmpty) {
          state = state.copyWith(isLoadingMore: false, hasMore: false);
          return;
        }
        final result = await repository.getCommunityFollowingFeedByCursor(
          cursor: cursor,
          size: _pageSize,
        );
        _appendCursorResult(result);
    }
  }

  bool _requiresAuthentication(CommunityFeedMode mode) {
    return mode == CommunityFeedMode.recommended ||
        mode == CommunityFeedMode.following;
  }

  Future<void> _loadSubscriptions({bool forceRefresh = false}) async {
    if (!_isBoardTabActive(_ref)) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      state = state.copyWith(
        subscriptions: const <ProjectSubscriptionSummary>[],
        isSubscriptionsLoading: false,
      );
      return;
    }
    state = state.copyWith(isSubscriptionsLoading: true);
    final repository = await _ref.read(feedRepositoryProvider.future);
    final result = await repository.getCommunitySubscriptions(
      page: 0,
      size: 30,
      forceRefresh: forceRefresh,
    );
    if (result is Success<List<ProjectSubscriptionSummary>>) {
      state = state.copyWith(
        subscriptions: result.data,
        isSubscriptionsLoading: false,
      );
    } else {
      if (result is Err<List<ProjectSubscriptionSummary>>) {
        _handleUnauthorizedFailure(result.failure);
      }
      state = state.copyWith(isSubscriptionsLoading: false);
    }
  }

  void _appendCursorResult(Result<PostCursorPage> result) {
    if (result is Success<PostCursorPage>) {
      final merged = [...state.posts, ...result.data.items];
      state = state.copyWith(
        posts: merged,
        searchSourcePosts: const [],
        hasMore: result.data.hasNext,
        nextCursor: result.data.nextCursor ?? '',
        isLoadingMore: false,
        clearFailure: true,
      );
    } else if (result is Err<PostCursorPage>) {
      _handleUnauthorizedFailure(result.failure);
      state = state.copyWith(isLoadingMore: false, failure: result.failure);
    }
  }

  bool _isUnauthorizedFailure(Failure failure) {
    if (failure is! AuthFailure) {
      return false;
    }
    final code = failure.code?.trim().toLowerCase();
    return code == '401' || code == 'auth_required';
  }

  void _handleUnauthorizedFailure(Failure failure) {
    if (!_isUnauthorizedFailure(failure)) {
      return;
    }
    _ref.read(authStateProvider.notifier).setUnauthenticated();
    unawaited(stopRealtimeSync());
  }

  List<PostSummary> _filterSearchResults({
    required List<PostSummary> sourcePosts,
    required String query,
    required CommunitySearchScope scope,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return sourcePosts;
    }

    return sourcePosts
        .where(
          (post) => _matchesSearchScope(
            post: post,
            query: normalizedQuery,
            scope: scope,
          ),
        )
        .toList(growable: false);
  }

  bool _matchesSearchScope({
    required PostSummary post,
    required String query,
    required CommunitySearchScope scope,
  }) {
    bool contains(String? value) =>
        value?.toLowerCase().contains(query) ?? false;

    final titleMatch = contains(post.title);
    final authorMatch = contains(post.authorName);
    final contentMatch = contains(post.content);
    final hasMedia =
        post.imageUrls.isNotEmpty ||
        (post.thumbnailUrl?.isNotEmpty ?? false) ||
        (post.content?.contains('![') ?? false);

    switch (scope) {
      case CommunitySearchScope.all:
        return titleMatch || authorMatch || contentMatch;
      case CommunitySearchScope.title:
        return titleMatch;
      case CommunitySearchScope.author:
        return authorMatch;
      case CommunitySearchScope.content:
        return contentMatch;
      case CommunitySearchScope.media:
        return hasMedia && (titleMatch || authorMatch || contentMatch);
    }
  }
}

/// EN: Post list controller provider.
/// KO: 게시글 리스트 컨트롤러 프로바이더.
final postListControllerProvider =
    StateNotifierProvider<PostListController, AsyncValue<List<PostSummary>>>((
      ref,
    ) {
      return PostListController(ref)..load();
    });

/// EN: Community feed controller provider with mode/search/pagination state.
/// KO: 모드/검색/페이지네이션 상태를 관리하는 커뮤니티 피드 컨트롤러 프로바이더.
final communityFeedControllerProvider =
    StateNotifierProvider.autoDispose<
      CommunityFeedController,
      CommunityFeedViewState
    >((ref) {
      final controller = CommunityFeedController(ref)..initialize();
      ref.onDispose(() {
        unawaited(controller.stopRealtimeSync());
      });
      return controller;
    });
