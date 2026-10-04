/// EN: BuildContext navigation helpers. Feature-free (R3): callers pass
/// EN: primitive ids/values; anything feature-typed goes through `extra`
/// EN: as `Object?` and is cast back at the route builder in `lib/app`.
/// KO: BuildContext 내비게이션 헬퍼입니다. 피처 의존 없음(R3): 호출자는
/// KO: 기본 타입 id/값을 넘기고, 피처 타입이 필요하면 `extra`에 `Object?`로
/// KO: 담아 `lib/app`의 라우트 빌더에서 다시 캐스팅합니다.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart' show AppRoutes;

DateTime? _lastPostDetailNavigationAt;
String? _lastPostDetailNavigationPath;

enum _ShellNavigationAction { push, go, none }

/// EN: Extension for navigation helpers
/// KO: 네비게이션 헬퍼 확장
extension AppRouterExtension on BuildContext {
  bool _isOverlayPath(String path) {
    return path.startsWith('/settings') ||
        path.startsWith('/favorites') ||
        path.startsWith('/post-bookmarks') ||
        path.startsWith('/visits') ||
        path.startsWith('/visit-stats') ||
        path.startsWith('/notifications') ||
        path.startsWith('/search') ||
        path.startsWith('/fan-subjects') ||
        path.startsWith('/calendar') ||
        path.startsWith('/fan-level') ||
        path.startsWith('/cheer-guides') ||
        path.startsWith('/quotes') ||
        path.startsWith('/zukan') ||
        path.startsWith('/users') ||
        path.startsWith('/overlay/music') ||
        path.startsWith('/overlay');
  }

  String _resolveCurrentPathFromContext() {
    // EN: Read the active match directly. Ancestor lookup can loop forever
    // from a Navigator-pushed page inside a stateful shell navigator.
    // KO: 활성 경로를 직접 조회합니다. 상태 유지 쉘에서 Navigator로 연
    // 화면의 조상을 탐색하면 같은 내비게이터를 무한 반복할 수 있습니다.
    return GoRouter.of(this).state.uri.path;
  }

  bool _isInOverlayContext() {
    final contextPath = _resolveCurrentPathFromContext();
    final routerPath = GoRouter.of(
      this,
    ).routeInformationProvider.value.uri.path;
    return _isOverlayPath(contextPath) || _isOverlayPath(routerPath);
  }

  _ShellNavigationAction _resolveShellNavigationAction(String targetPath) {
    final contextPath = _resolveCurrentPathFromContext();
    final routerPath = GoRouter.of(
      this,
    ).routeInformationProvider.value.uri.path;
    final currentLocation = GoRouter.of(
      this,
    ).routeInformationProvider.value.uri;
    final isSameTarget = currentLocation == Uri.parse(targetPath);
    final shouldUseGo =
        _isOverlayPath(contextPath) ||
        _isOverlayPath(routerPath) ||
        // EN: If target already exists in stack and this route can pop,
        // EN: prefer `go` to avoid pushing a duplicated page key.
        // KO: 타겟이 이미 스택에 있고 현재 라우트에서 pop 가능하면
        // KO: 중복 페이지 key push를 피하기 위해 `go`를 우선합니다.
        (isSameTarget && canPop());
    if (shouldUseGo) {
      return _ShellNavigationAction.go;
    }
    if (isSameTarget) {
      return _ShellNavigationAction.none;
    }
    // EN: Replace route from top-level overlays to shell branches to avoid
    // EN: stacking a second shell navigator that can render as a blank page.
    // KO: 최상위 오버레이에서 쉘 브랜치로 이동할 때 두 번째 쉘 네비게이터가
    // KO: 중첩되어 빈 화면으로 보이는 문제를 막기 위해 교체 이동(go)을 사용합니다.
    return _ShellNavigationAction.push;
  }

  /// EN: Navigate to place detail
  /// KO: 장소 상세로 이동
  void goToPlaceDetail(String placeId) {
    if (_isInOverlayContext()) {
      pushNamed(
        AppRoutes.overlayPlaceDetail,
        pathParameters: {'placeId': placeId},
      );
      return;
    }
    final router = GoRouter.of(this);
    final targetPath = router.namedLocation(
      AppRoutes.mapPlaceDetail,
      pathParameters: {'placeId': placeId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(
          AppRoutes.mapPlaceDetail,
          pathParameters: {'placeId': placeId},
        );
        return;
    }
  }

  /// EN: Navigate to event detail
  /// KO: 이벤트 상세로 이동
  void goToEventDetail(String eventId) {
    if (_isInOverlayContext()) {
      pushNamed(
        AppRoutes.overlayEventDetail,
        pathParameters: {'eventId': eventId},
      );
      return;
    }
    final router = GoRouter.of(this);
    final targetPath = router.namedLocation(
      AppRoutes.liveEventDetail,
      pathParameters: {'eventId': eventId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(
          AppRoutes.liveEventDetail,
          pathParameters: {'eventId': eventId},
        );
        return;
    }
  }

  /// EN: Navigate to news detail
  /// KO: 뉴스 상세로 이동
  void goToNewsDetail(String newsId) {
    if (_isInOverlayContext()) {
      pushNamed(
        AppRoutes.overlayNewsDetail,
        pathParameters: {'newsId': newsId},
      );
      return;
    }
    final router = GoRouter.of(this);
    final targetPath = router.namedLocation(
      AppRoutes.homeNewsDetail,
      pathParameters: {'newsId': newsId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(AppRoutes.homeNewsDetail, pathParameters: {'newsId': newsId});
        return;
    }
  }

  /// EN: Navigate to song detail.
  /// KO: 악곡 상세로 이동합니다.
  void goToSongDetail(
    String songId, {
    required String projectId,
    String? eventId,
  }) {
    final trimmedProjectId = projectId.trim();
    if (trimmedProjectId.isEmpty) {
      return;
    }
    final trimmedEventId = eventId?.trim();
    final queryParameters = <String, String>{
      'projectId': trimmedProjectId,
      if (trimmedEventId != null && trimmedEventId.isNotEmpty)
        'eventId': trimmedEventId,
    };
    if (_isInOverlayContext()) {
      pushNamed(
        AppRoutes.overlaySongDetail,
        pathParameters: {'songId': songId},
        queryParameters: queryParameters,
      );
      return;
    }
    final router = GoRouter.of(this);
    final targetPath = router.namedLocation(
      AppRoutes.musicSongDetail,
      pathParameters: {'songId': songId},
      queryParameters: queryParameters,
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(
          AppRoutes.musicSongDetail,
          pathParameters: {'songId': songId},
          queryParameters: queryParameters,
        );
        return;
    }
  }

  /// EN: Navigate to unit detail when only a search identity is available.
  /// EN: `initialUnit` is an optional feature-typed entity passed through as
  /// EN: `Object?`; the route builder in `lib/app` casts it back.
  /// KO: 검색 식별자만 있는 경우 유닛 상세 페이지로 이동합니다. `initialUnit`은
  /// KO: 선택적 피처 타입 엔티티로 `Object?`로 전달되며, `lib/app`의 라우트
  /// KO: 빌더에서 다시 캐스팅합니다.
  void goToUnitDetailByIdentifier(
    String unitIdentifier, {
    required String projectId,
    Object? initialUnit,
  }) {
    final trimmedUnitIdentifier = unitIdentifier.trim();
    final trimmedProjectId = projectId.trim();
    if (trimmedUnitIdentifier.isEmpty || trimmedProjectId.isEmpty) {
      return;
    }
    pushNamed(
      AppRoutes.liveUnitDetail,
      pathParameters: {'unitId': trimmedUnitIdentifier},
      queryParameters: {'projectId': trimmedProjectId},
      extra: initialUnit,
    );
  }

  /// EN: Navigate to member (character + VA) detail page. `extra` carries
  /// EN: feature-typed unit/member entities as `Object?`.
  /// KO: 멤버(캐릭터 + 성우) 상세 페이지로 이동. `extra`는 피처 타입
  /// KO: 유닛/멤버 엔티티를 `Object?`로 전달합니다.
  void goToMemberDetail({
    required String unitIdentifier,
    required String memberId,
    required String projectId,
    Object? extra,
  }) {
    pushNamed(
      AppRoutes.liveMemberDetail,
      pathParameters: {'unitId': unitIdentifier, 'memberId': memberId},
      queryParameters: {'projectId': projectId},
      extra: extra,
    );
  }

  /// EN: Navigate to voice actor detail.
  /// KO: 성우 상세로 이동
  void goToVoiceActorDetail(
    String voiceActorId, {
    required String projectId,
    String? fallbackName,
  }) {
    final trimmedProjectId = projectId.trim();
    if (trimmedProjectId.isEmpty) {
      return;
    }
    final trimmedName = fallbackName?.trim();
    final queryParameters = <String, String>{
      'projectId': trimmedProjectId,
      if (trimmedName != null && trimmedName.isNotEmpty) 'name': trimmedName,
    };
    pushNamed(
      AppRoutes.liveVoiceActorDetail,
      pathParameters: {'voiceActorId': voiceActorId},
      queryParameters: queryParameters,
    );
  }

  /// EN: Navigate to generic project, band/unit, person, artist, or anime detail.
  /// KO: 프로젝트·밴드/유닛·인물·아티스트·애니메이션 공통 상세로 이동합니다.
  void goToFanSubjectDetail(String subjectId) {
    final trimmedSubjectId = subjectId.trim();
    if (trimmedSubjectId.isEmpty) return;
    pushNamed(
      AppRoutes.fanSubjectDetail,
      pathParameters: {'subjectId': trimmedSubjectId},
    );
  }

  /// EN: Navigate to post detail
  /// KO: 게시글 상세로 이동
  void goToPostDetail(String postId, {String? projectCode}) {
    final trimmedProjectCode = projectCode?.trim();
    final Map<String, dynamic> queryParameters =
        trimmedProjectCode != null && trimmedProjectCode.isNotEmpty
        ? <String, String>{'projectCode': trimmedProjectCode}
        : <String, dynamic>{};
    if (_isInOverlayContext()) {
      final router = GoRouter.of(this);
      final targetPath = router.namedLocation(
        AppRoutes.overlayPostDetail,
        pathParameters: {'postId': postId},
        queryParameters: queryParameters,
      );
      final now = DateTime.now();
      final lastAt = _lastPostDetailNavigationAt;
      final currentLocation = router.routeInformationProvider.value.uri
          .toString();
      if (currentLocation == targetPath) {
        return;
      }
      if (lastAt != null &&
          _lastPostDetailNavigationPath == targetPath &&
          now.difference(lastAt).inMilliseconds < 700) {
        return;
      }
      _lastPostDetailNavigationAt = now;
      _lastPostDetailNavigationPath = targetPath;
      pushNamed(
        AppRoutes.overlayPostDetail,
        pathParameters: {'postId': postId},
        queryParameters: queryParameters,
      );
      return;
    }
    final router = GoRouter.of(this);
    final targetPath = router.namedLocation(
      AppRoutes.postDetail,
      pathParameters: {'postId': postId},
      queryParameters: queryParameters,
    );
    final navigationAction = _resolveShellNavigationAction(targetPath);
    final now = DateTime.now();
    final lastAt = _lastPostDetailNavigationAt;

    // EN: Prevent duplicate pushes caused by rapid multi-tap on the same item.
    // KO: 동일 아이템 연속 탭으로 인한 중복 push를 방지합니다.
    if (navigationAction == _ShellNavigationAction.none) {
      return;
    }
    if (lastAt != null &&
        _lastPostDetailNavigationPath == targetPath &&
        now.difference(lastAt).inMilliseconds < 700) {
      return;
    }

    _lastPostDetailNavigationAt = now;
    _lastPostDetailNavigationPath = targetPath;
    switch (navigationAction) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(
          AppRoutes.postDetail,
          pathParameters: {'postId': postId},
          queryParameters: queryParameters,
        );
        return;
    }
  }

  /// EN: Navigate to post creation.
  /// KO: 게시글 작성으로 이동
  void goToPostCreate() {
    pushNamed(AppRoutes.postCreate);
  }

  /// EN: Navigate to post edit. `extra` carries the feature-typed post
  /// EN: entity as `Object?`.
  /// KO: 게시글 수정으로 이동. `extra`는 피처 타입 게시글 엔티티를
  /// KO: `Object?`로 전달합니다.
  void goToPostEdit(String postId, {Object? extra}) {
    pushNamed(
      AppRoutes.postEdit,
      pathParameters: {'postId': postId},
      extra: extra,
    );
  }

  /// EN: Navigate to user profile.
  /// KO: 사용자 프로필로 이동
  void goToUserProfile(String userId) {
    pushNamed(AppRoutes.userProfile, pathParameters: {'userId': userId});
  }

  /// EN: Navigate to followers list.
  /// KO: 팔로워 목록으로 이동
  void goToUserFollowers(String userId) {
    pushNamed(AppRoutes.userFollowers, pathParameters: {'userId': userId});
  }

  /// EN: Navigate to following list.
  /// KO: 팔로잉 목록으로 이동
  void goToUserFollowing(String userId) {
    pushNamed(AppRoutes.userFollowing, pathParameters: {'userId': userId});
  }

  /// EN: Navigate to visit detail
  /// KO: 방문 상세로 이동
  void goToVisitDetail({
    required String visitId,
    required String placeId,
    String? visitedAt,
  }) {
    final queryParams = <String, String>{
      'placeId': placeId,
      if (visitedAt != null) 'visitedAt': visitedAt,
    };
    pushNamed(
      AppRoutes.visitDetail,
      pathParameters: {'visitId': visitId},
      queryParameters: queryParams,
    );
  }

  /// EN: Navigate to search with optional query
  /// KO: 선택적 쿼리와 함께 검색으로 이동
  void goToSearch([String? query]) {
    if (query != null) {
      pushNamed(AppRoutes.search, queryParameters: {'q': query});
    } else {
      pushNamed(AppRoutes.search);
    }
  }

  /// EN: Navigate to settings (push overlay on top of shell)
  /// KO: 설정으로 이동 (쉘 위에 오버레이로 push)
  void goToSettings() {
    final router = GoRouter.of(this);
    final currentUri = router.routeInformationProvider.value.uri;
    final settingsUri = Uri(
      path: '/settings',
      queryParameters: {'from': currentUri.toString()},
    );
    push(settingsUri.toString());
  }

  /// EN: Navigate to community settings.
  /// KO: 커뮤니티 설정으로 이동
  void goToCommunitySettings() {
    pushNamed(AppRoutes.communitySettings);
  }

  /// EN: Navigate to post bookmarks page.
  /// KO: 북마크한 게시글 페이지로 이동
  void goToPostBookmarks() {
    pushNamed(AppRoutes.postBookmarks);
  }

  /// EN: Navigate to visit stats
  /// KO: 방문 통계로 이동
  void goToVisitStats() {
    pushNamed(AppRoutes.visitStats);
  }

  /// EN: Navigate to account tools.
  /// KO: 계정 도구로 이동
  void goToAccountTools() {
    pushNamed(AppRoutes.accountTools);
  }

  /// EN: Navigate to visit history
  /// KO: 방문 기록으로 이동
  void goToVisitHistory({bool showLiveTab = false}) {
    if (showLiveTab) {
      pushNamed(AppRoutes.visitHistory, queryParameters: const {'tab': 'live'});
      return;
    }
    pushNamed(AppRoutes.visitHistory);
  }
}
