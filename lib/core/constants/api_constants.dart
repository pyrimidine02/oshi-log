/// EN: API endpoint constants and configurations
/// KO: API 엔드포인트 상수 및 구성
library;

/// EN: API endpoint paths
/// KO: API 엔드포인트 경로
class ApiEndpoints {
  ApiEndpoints._();

  // EN: API version prefix
  // KO: API 버전 접두사
  static const String apiVersion = '/api/v1';

  // ============================================================
  // EN: Auth endpoints (8.1)
  // KO: 인증 엔드포인트 (8.1)
  // ============================================================
  static const String login = '$apiVersion/auth/login';
  static const String register = '$apiVersion/auth/register';
  static const String refresh = '$apiVersion/auth/refresh';
  static const String logout = '$apiVersion/auth/logout';
  static const String emailVerifications =
      '$apiVersion/auth/email-verifications';
  static const String emailVerificationsConfirm =
      '$apiVersion/auth/email-verifications/confirm';

  // EN: Password reset request (unauthenticated — forgot password flow).
  // KO: 비밀번호 재설정 요청 (비인증 — 비밀번호 분실 플로우).
  static const String passwordResetRequests =
      '$apiVersion/auth/password-reset-requests';
  static const String passwordResetRequestsConfirm =
      '$apiVersion/auth/password-reset-requests/confirm';
  static String oauthCallback(String provider) =>
      '$apiVersion/auth/oauth2/callback/$provider';

  // EN: Public legal policy documents — no auth required, used at registration.
  // KO: 공개 법률 정책 문서 — 인증 불필요, 회원가입 시 사용.
  static const String legalPolicies = '$apiVersion/auth/legal/policies';

  // EN: Native social login endpoints (POST idToken / identityToken from SDK).
  // KO: 네이티브 소셜 로그인 엔드포인트 (SDK에서 받은 idToken / identityToken POST).
  static const String oauthGoogle = '$apiVersion/auth/oauth2/google';
  static const String oauthApple = '$apiVersion/auth/oauth2/apple';

  // EN: X (Twitter) PKCE login — POST code + codeVerifier + redirectUri.
  // KO: X (Twitter) PKCE 로그인 — code + codeVerifier + redirectUri POST.
  static const String oauthTwitter = '$apiVersion/auth/oauth2/twitter';

  // EN: OAuth link-existing endpoints — called after EMAIL_ACCOUNT_CONFLICT (409).
  // KO: EMAIL_ACCOUNT_CONFLICT(409) 충돌 후 기존 계정 연동 엔드포인트.
  static const String oauthGoogleLinkExisting =
      '$apiVersion/auth/oauth2/google/link-existing';
  static const String oauthAppleLinkExisting =
      '$apiVersion/auth/oauth2/apple/link-existing';

  // EN: OAuth connect endpoints — authenticated, for account merging and settings.
  // KO: OAuth 연결 엔드포인트 — 인증 필요, 계정 합치기 및 설정용.
  static const String oauthConnectExisting =
      '$apiVersion/auth/oauth2/connect/existing';
  // EN: Merge current OAuth account with an existing Google account (POST).
  //     Called from the merge page when the user proves ownership via Google SDK.
  // KO: 현재 OAuth 계정을 기존 Google 계정과 합치기 (POST).
  //     머지 페이지에서 Google SDK로 소유권 인증 시 호출합니다.
  static const String oauthConnectExistingGoogle =
      '$apiVersion/auth/oauth2/connect/existing/google';
  // EN: Merge current OAuth account with an existing Apple account (POST).
  // KO: 현재 OAuth 계정을 기존 Apple 계정과 합치기 (POST).
  static const String oauthConnectExistingApple =
      '$apiVersion/auth/oauth2/connect/existing/apple';
  static const String oauthConnectGoogle =
      '$apiVersion/auth/oauth2/connect/google';
  static const String oauthConnectApple =
      '$apiVersion/auth/oauth2/connect/apple';

  // EN: OAuth disconnect endpoint (DELETE) — authenticated.
  // KO: OAuth 연결 해제 엔드포인트 (DELETE) — 인증 필요.
  static const String oauthDisconnect = '$apiVersion/auth/oauth2/connect';

  // ============================================================
  // EN: User endpoints (8.2)
  // KO: 사용자 엔드포인트 (8.2)
  // ============================================================
  static const String userMe = '$apiVersion/users/me';

  // EN: Change password for authenticated user (PATCH).
  // KO: 인증된 사용자의 비밀번호 변경 (PATCH).
  static const String userMePassword = '$userMe/password';
  static const String userMeAccessLevel = '$userMe/access-level';
  static const String userVisits = '$apiVersion/users/me/visits';
  static const String userVisitsSummary = '$apiVersion/users/me/visits/summary';
  static String userVisitDetail(String visitId) => '$userVisits/$visitId';
  static const String usersSearch = '$apiVersion/users/search';
  static String userProfile(String userId) => '$apiVersion/users/$userId';
  static const String userPrivacySettings = '$userMe/privacy-settings';
  static const String userConsents = '$userMe/consents';
  static const String userConsentStatus = '$userMe/consent-status';
  static const String userPrivacyRequests = '$userMe/privacy-requests';
  static String userFollow(String userId) => '${userProfile(userId)}/follow';
  static String userFollowers(String userId) =>
      '${userProfile(userId)}/followers';
  static String userFollowing(String userId) =>
      '${userProfile(userId)}/following';
  static String userBlocked(String userId) => '${userProfile(userId)}/blocked';
  static const String userBlocks = '$apiVersion/users/me/blocks';
  static String userBlock(String targetUserId) => '$userBlocks/$targetUserId';

  // EN: Account restoration endpoint (30-day grace period after deactivation).
  // KO: 계정 복구 엔드포인트 (비활성화 후 30일 유예기간 내 복구).
  static const String userMeRestore = '$userMe/restore';

  // ============================================================
  // EN: Favorites endpoints (8.14)
  // KO: 즐겨찾기 엔드포인트 (8.14)
  // ============================================================
  static const String userFavorites = '$apiVersion/users/me/favorites';

  // ============================================================
  // EN: Notification endpoints (8.2)
  // KO: 알림 엔드포인트 (8.2)
  // ============================================================
  static const String notifications = '$apiVersion/notifications';
  static String notificationRead(String id) => '$notifications/$id/read';
  static String notificationOpen(String id) => '$notifications/$id/open';
  static String notificationDelete(String id) => '$notifications/$id';
  static const String notificationsDeleteAll = notifications;
  static const String notificationSettings = '$notifications/settings';
  static const String notificationDevices = '$notifications/devices';
  static String notificationDevice(String deviceId) =>
      '$notificationDevices/$deviceId';
  static String notificationDeviceToken(String deviceId) =>
      '${notificationDevice(deviceId)}/token';
  static const String notificationsStream = '$notifications/stream';

  // ============================================================
  // EN: Verification endpoints (8.3)
  // KO: 검증 엔드포인트 (8.3)
  // ============================================================
  static const String verificationConfig = '$apiVersion/verification/config';
  static const String verificationChallenge =
      '$apiVersion/verification/challenge';
  static const String verificationKeys = '$apiVersion/verification/keys';

  // ============================================================
  // EN: Home/Search endpoints (8.4)
  // KO: 홈/검색 엔드포인트 (8.4)
  // ============================================================
  static const String homeSummary = '$apiVersion/home/summary';
  static const String homeSummaryByProject = '$homeSummary/by-project';

  /// EN: Active home page banner slides (GET).
  /// KO: 홈 페이지 활성 배너 슬라이드 (GET).
  static const String homeBanners = '$apiVersion/home/banners';

  // ============================================================
  // EN: Calendar endpoints (8.27)
  // KO: 캘린더 엔드포인트 (8.27)
  // ============================================================

  /// EN: Paginated calendar events filtered by year, month, and optional projectId.
  /// KO: 연도, 월, 선택적 projectId로 필터링된 페이지네이션 캘린더 이벤트.
  static const String calendarEvents = '$apiVersion/calendar/events';

  static const String search = '$apiVersion/search';
  static const String searchDiscoveryPopular =
      '$apiVersion/search/discovery/popular';
  static const String searchDiscoveryCategories =
      '$apiVersion/search/discovery/categories';
  static const String adsDecision = '$apiVersion/ads/decision';
  static const String adsEvents = '$apiVersion/ads/events';

  // ============================================================
  // EN: Project endpoints (8.5)
  // KO: 프로젝트 엔드포인트 (8.5)
  // ============================================================
  static const String projects = '$apiVersion/projects';
  static String project(String projectId) => '$projects/$projectId';

  // EN: Unit endpoints
  // KO: 유닛 엔드포인트
  static String projectUnits(String projectId) => '${project(projectId)}/units';
  static String projectUnit(String projectId, String bandCode) =>
      '${projectUnits(projectId)}/$bandCode';
  static String projectUnitsSearch(String projectId) =>
      '${projectUnits(projectId)}/search';
  static String unitMembers(String projectId, String unitId) =>
      '${projectUnits(projectId)}/$unitId/members';
  static String unitMember(String projectId, String unitId, String memberId) =>
      '${unitMembers(projectId, unitId)}/$memberId';
  static String projectVoiceActors(String projectId) =>
      '${projectUnits(projectId)}/voice-actors';
  static String projectVoiceActor(String projectId, String voiceActorId) =>
      '${projectVoiceActors(projectId)}/$voiceActorId';
  static String projectVoiceActorMembers(
    String projectId,
    String voiceActorId,
  ) => '${projectVoiceActor(projectId, voiceActorId)}/members';
  static String projectVoiceActorCredits(
    String projectId,
    String voiceActorId,
  ) => '${projectVoiceActor(projectId, voiceActorId)}/credits';

  // ============================================================
  // EN: Place endpoints (8.6)
  // KO: 장소 엔드포인트 (8.6)
  // ============================================================
  static String places(String projectId) => '${project(projectId)}/places';
  static String place(String projectId, String placeId) =>
      '${places(projectId)}/$placeId';
  static String placesWithinBounds(String projectId) =>
      '${places(projectId)}/within-bounds';
  static String placesNearby(String projectId) => '${places(projectId)}/nearby';

  // EN: Place verification
  // KO: 장소 인증
  static String placeVerification(String projectId, String placeId) =>
      '${place(projectId, placeId)}/verification';

  // ============================================================
  // EN: Place Photos endpoints (8.7)
  // KO: 장소 사진 엔드포인트 (8.7)
  // ============================================================
  static String placePhotos(String placeId) =>
      '$apiVersion/places/$placeId/photos';
  static String placePhotosBatch(String placeId) =>
      '${placePhotos(placeId)}/batch';
  static String placePhotosAll(String placeId) => '${placePhotos(placeId)}/all';
  static String placePhotosFeatured(String placeId) =>
      '${placePhotos(placeId)}/featured';
  static String placePhotosPending(String placeId) =>
      '${placePhotos(placeId)}/pending';
  static String placePhoto(String placeId, String photoId) =>
      '${placePhotos(placeId)}/$photoId';
  static String placePhotoApprove(String placeId, String photoId) =>
      '${placePhoto(placeId, photoId)}/approve';

  // ============================================================
  // EN: Place Guides endpoints (8.8)
  // KO: 장소 가이드 엔드포인트 (8.8)
  // ============================================================
  static String placeGuides(String placeId) =>
      '$apiVersion/places/$placeId/guides';
  static String placeGuidesBatch(String placeId) =>
      '${placeGuides(placeId)}/batch';
  static String placeGuidesAll(String placeId) => '${placeGuides(placeId)}/all';
  static String placeGuide(String placeId, String guideId) =>
      '${placeGuides(placeId)}/$guideId';
  static String placeGuidePreview(String placeId, String guideId) =>
      '${placeGuide(placeId, guideId)}/preview';
  static String placeGuidePublish(String placeId, String guideId) =>
      '${placeGuide(placeId, guideId)}/publish';
  static String placeGuidesUnpublished(String placeId) =>
      '${placeGuides(placeId)}/unpublished';
  static String placeGuidesHighPriority(String placeId) =>
      '${placeGuides(placeId)}/high-priority';
  static String placeGuidesSearch(String placeId) =>
      '${placeGuides(placeId)}/search';

  // ============================================================
  // EN: Place Comments endpoints (8.9)
  // KO: 장소 댓글 엔드포인트 (8.9)
  // ============================================================
  static String placeComments(String placeId) =>
      '$apiVersion/places/$placeId/comments';
  static String placeCommentsBatch(String placeId) =>
      '${placeComments(placeId)}/batch';
  static String placeCommentThread(String placeId, String threadId) =>
      '${placeComments(placeId)}/threads/$threadId';
  static String placeComment(String placeId, String commentId) =>
      '${placeComments(placeId)}/$commentId';
  static String placeCommentReply(String placeId, String commentId) =>
      '${placeComment(placeId, commentId)}/reply';
  static String placeCommentModerate(String placeId, String commentId) =>
      '${placeComment(placeId, commentId)}/moderate';
  static String placeCommentsTagsPopular(String placeId) =>
      '${placeComments(placeId)}/tags/popular';
  static String placeCommentsFilterAccessibility(String placeId) =>
      '${placeComments(placeId)}/filter/accessibility';
  static String placeCommentsFilterRoutes(String placeId) =>
      '${placeComments(placeId)}/filter/routes';
  static String placeCommentsFilterAdvice(String placeId) =>
      '${placeComments(placeId)}/filter/advice';
  static String placeCommentsFilterPhotos(String placeId) =>
      '${placeComments(placeId)}/filter/photos';
  static String placeCommentsPinned(String placeId) =>
      '${placeComments(placeId)}/pinned';
  static String placeCommentsSearch(String placeId) =>
      '${placeComments(placeId)}/search';
  static String placeCommentsStats(String placeId) =>
      '${placeComments(placeId)}/stats';

  // ============================================================
  // EN: Region Navigation endpoints (8.11)
  // KO: 지역 네비게이션 엔드포인트 (8.11)
  // ============================================================
  static const String regionsTree = '$apiVersion/regions/tree';
  static const String regionsCountries = '$apiVersion/regions/countries';
  static String regionsChildren(String parentCode) =>
      '$apiVersion/regions/$parentCode/children';
  static String regionsPlaces(String regionCode) =>
      '$apiVersion/regions/$regionCode/places';
  static const String regionsPopular = '$apiVersion/regions/popular';
  static const String regionsSearch = '$apiVersion/regions/search';

  // ============================================================
  // EN: Project Places Regions endpoints (8.10)
  // KO: 프로젝트 장소 지역 엔드포인트 (8.10)
  // ============================================================
  static String placesRegionsAvailable(String projectId) =>
      '${places(projectId)}/regions/available';
  static String placesRegionsFilter(String projectId) =>
      '${places(projectId)}/regions/filter';
  static String placesRegionsStats(String projectId) =>
      '${places(projectId)}/regions/stats';
  static String placesRegionsBreadcrumb(String projectId, String regionCode) =>
      '${places(projectId)}/regions/breadcrumb/$regionCode';
  static String placesRegionsMapBounds(String projectId) =>
      '${places(projectId)}/regions/map-bounds';
  static String placesRegionsFavorites(String projectId) =>
      '${places(projectId)}/regions/favorites';

  // ============================================================
  // EN: Unified Search endpoints (8.13)
  // KO: 통합 검색 엔드포인트 (8.13)
  // ============================================================
  static String placesSearchUnified(String projectId) =>
      '${places(projectId)}/search/unified';
  static String placesSearchAutocomplete(String projectId) =>
      '${places(projectId)}/search/autocomplete';
  static String placesSearchSuggestions(String projectId) =>
      '${places(projectId)}/search/suggestions';
  static String placesSearchRegionsStats(String projectId) =>
      '${places(projectId)}/search/regions/stats';
  static String placesSearchPopular(String projectId) =>
      '${places(projectId)}/search/popular';
  static String placesSearchFiltersAvailable(String projectId) =>
      '${places(projectId)}/search/filters/available';
  static String placesSearchQuickFilters(String projectId) =>
      '${places(projectId)}/search/quick-filters';

  // ============================================================
  // EN: Place region search endpoints (8.12)
  // KO: 장소 지역 검색 엔드포인트 (8.12)
  // ============================================================
  static const String placeRegionSearchExamples =
      '$apiVersion/search/place-region/demo/search-examples';
  static const String placeRegionPlacesByMultipleRegions =
      '$apiVersion/search/place-region/places/by-multiple-regions';
  static const String placeRegionPlacesByRegionName =
      '$apiVersion/search/place-region/places/by-region-name';
  static String placeRegionPlacesByRegion(String regionCode) =>
      '$apiVersion/search/place-region/places/by-region/$regionCode';
  static String placeRegionPlaceHierarchy(String placeId) =>
      '$apiVersion/search/place-region/places/$placeId/region-hierarchy';
  static String placeRegionStats(String regionCode) =>
      '$apiVersion/search/place-region/regions/$regionCode/stats';

  // ============================================================
  // EN: Live event endpoints (8.15)
  // KO: 라이브 이벤트 엔드포인트 (8.15)
  // ============================================================
  static String liveEvents(String projectId) =>
      '${project(projectId)}/live-events';
  static String liveEventAttendances(String projectId) =>
      '${liveEvents(projectId)}/attendances';
  static String liveEvent(String projectId, String liveEventId) =>
      '${liveEvents(projectId)}/$liveEventId';
  static String liveEventAttendance(String projectId, String liveEventId) =>
      '${liveEvent(projectId, liveEventId)}/attendance';
  static String liveEventVerification(String projectId, String liveEventId) =>
      '${liveEvent(projectId, liveEventId)}/verification';
  static String liveEventSetlist(String projectId, String liveEventId) =>
      '${liveEvent(projectId, liveEventId)}/setlist';

  // ============================================================
  // EN: Music information endpoints (8.26)
  // KO: 악곡 정보 엔드포인트 (8.26)
  // ============================================================
  static String musicAlbums(String projectId) =>
      '${project(projectId)}/music/albums';
  static String musicAlbum(String projectId, String albumId) =>
      '${musicAlbums(projectId)}/$albumId';
  static String musicSongs(String projectId) =>
      '${project(projectId)}/music/songs';
  static String musicSong(String projectId, String songId) =>
      '${musicSongs(projectId)}/$songId';
  static String musicSongLyrics(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/lyrics';
  static String musicSongParts(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/parts';
  static String musicSongCallGuide(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/call-guide';
  static String musicSongVersions(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/versions';
  static String musicSongVersion(
    String projectId,
    String songId,
    String versionCode,
  ) => '${musicSongVersions(projectId, songId)}/$versionCode';
  static String musicSongCredits(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/credits';
  static String musicSongDifficulty(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/difficulty';
  static String musicSongMediaLinks(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/media-links';
  static String musicSongAvailability(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/availability';
  static String musicSongLiveContext(String projectId, String songId) =>
      '${musicSong(projectId, songId)}/live-context';

  // ============================================================
  // EN: Community endpoints (8.16) - Uses projectCode!
  // KO: 커뮤니티 엔드포인트 (8.16) - projectCode 사용!
  // ============================================================
  static String posts(String projectCode) =>
      '$apiVersion/projects/$projectCode/posts';
  static String postsCursor(String projectCode) =>
      '${posts(projectCode)}/cursor';
  static String postsSearch(String projectCode) =>
      '${posts(projectCode)}/search';
  static String postsTrending(String projectCode) =>
      '${posts(projectCode)}/trending';
  static String post(String projectCode, String postId) =>
      '${posts(projectCode)}/$postId';
  static String postComments(String projectCode, String postId) =>
      '${post(projectCode, postId)}/comments';
  static String postCommentsThread(String projectCode, String postId) =>
      '${postComments(projectCode, postId)}/thread';
  static String postComment(
    String projectCode,
    String postId,
    String commentId,
  ) => '${postComments(projectCode, postId)}/$commentId';
  static String postLike(String projectCode, String postId) =>
      '${post(projectCode, postId)}/like';
  static String postBookmark(String projectCode, String postId) =>
      '${post(projectCode, postId)}/bookmark';
  static String postsByAuthor(String projectCode, String userId) =>
      '${posts(projectCode)}/by-author/$userId';
  static String commentsByAuthor(String projectCode, String userId) =>
      '$apiVersion/projects/$projectCode/comments/by-author/$userId';

  // EN: Project-scoped pilgrimage travel review aggregate endpoints.
  // KO: 프로젝트 범위 성지순례 여행 후기 애그리거트 엔드포인트.
  static String travelReviews(String projectCode) =>
      '$apiVersion/projects/$projectCode/travel-reviews';
  static String travelReview(String projectCode, String reviewId) =>
      '${travelReviews(projectCode)}/$reviewId';

  // EN: Community subscription endpoints.
  // KO: 커뮤니티 구독 엔드포인트.
  static const String communityRecommendedFeed =
      '$apiVersion/community/feed/recommended';
  static const String communityRecommendedFeedCursor =
      '$apiVersion/community/feed/recommended/cursor';
  static const String communityFollowingFeedCursor =
      '$apiVersion/community/feed/following/cursor';
  static const String communityPostOptions =
      '$apiVersion/community/posts/options';
  static const String communityEventsStream =
      '$apiVersion/community/events/stream';
  static const String communitySubscriptions =
      '$apiVersion/community/subscriptions';
  static const String communityTranslations =
      '$apiVersion/community/translations';

  // EN: Community reports endpoints.
  // KO: 커뮤니티 신고 엔드포인트.
  static const String communityReports = '$apiVersion/community/reports';
  static const String communityReportsMe = '$apiVersion/community/reports/me';
  static String communityReport(String reportId) =>
      '$communityReports/$reportId';

  // EN: Community moderation endpoints (project scoped).
  // KO: 프로젝트 단위 커뮤니티 모더레이션 엔드포인트.
  static String moderationBans(String projectCode) =>
      '$apiVersion/projects/$projectCode/moderation/bans';
  static String moderationBan(String projectCode, String userId) =>
      '${moderationBans(projectCode)}/$userId';
  static String moderationPost(String projectCode, String postId) =>
      '$apiVersion/projects/$projectCode/moderation/posts/$postId';
  static String moderationPostComment(
    String projectCode,
    String postId,
    String commentId,
  ) => '${moderationPost(projectCode, postId)}/comments/$commentId';

  // EN: Verification appeal endpoints.
  // KO: 인증 이의제기 엔드포인트.
  static String verificationAppeals(String projectId) =>
      '${project(projectId)}/verification-appeals';
  static String verificationAppeal(String projectId, String appealId) =>
      '${verificationAppeals(projectId)}/$appealId';

  // ============================================================
  // EN: News endpoints (8.17)
  // KO: 뉴스 엔드포인트 (8.17)
  // ============================================================
  static String news(String projectId) => '${project(projectId)}/news';
  static String newsDetail(String projectId, String newsId) =>
      '${news(projectId)}/$newsId';

  // ============================================================
  // EN: Upload endpoints (8.18)
  // KO: 업로드 엔드포인트 (8.18)
  // ============================================================
  static const String uploadsPresignedUrl = '$apiVersion/uploads/presigned-url';
  static const String uploadsDirect = '$apiVersion/uploads';
  static String uploadsConfirm(String uploadId) =>
      '$apiVersion/uploads/$uploadId/confirm';
  static const String uploadsMy = '$apiVersion/uploads/my';
  static String uploadsDelete(String uploadId) =>
      '$apiVersion/uploads/$uploadId';

  // ============================================================
  // EN: Media Link endpoints (8.19)
  // KO: 미디어 링크 엔드포인트 (8.19)
  // ============================================================
  static String placeImagesLink(String projectId, String placeId) =>
      '${place(projectId, placeId)}/images';
  static String placeImageDelete(
    String projectId,
    String placeId,
    String imageId,
  ) => '${placeImagesLink(projectId, placeId)}/$imageId';
  static String placeImagePrimary(
    String projectId,
    String placeId,
    String imageId,
  ) => '${placeImageDelete(projectId, placeId, imageId)}:primary';
  static String placeImagesReorder(String projectId, String placeId) =>
      '${placeImagesLink(projectId, placeId)}:reorder';

  static String newsImagesLink(String projectId, String newsId) =>
      '${newsDetail(projectId, newsId)}/images';
  static String newsImageDelete(
    String projectId,
    String newsId,
    String imageId,
  ) => '${newsImagesLink(projectId, newsId)}/$imageId';
  static String newsImagePrimary(
    String projectId,
    String newsId,
    String imageId,
  ) => '${newsImageDelete(projectId, newsId, imageId)}:primary';
  static String newsImagesReorder(String projectId, String newsId) =>
      '${newsImagesLink(projectId, newsId)}:reorder';

  static String liveEventBannerLink(String projectId, String liveEventId) =>
      '${liveEvent(projectId, liveEventId)}/banner';

  // ============================================================
  // EN: Ranking endpoints (8.20)
  // KO: 랭킹 엔드포인트 (8.20)
  // ============================================================
  static String rankingsMostVisited(String projectId) =>
      '${project(projectId)}/rankings/most-visited';
  static String rankingsMostLiked(String projectId) =>
      '${project(projectId)}/rankings/most-liked';
  static String rankingsTrending(String projectId) =>
      '${project(projectId)}/rankings/trending';
  static String rankingsUsers(String projectId) =>
      '${project(projectId)}/rankings/users';
  static String rankingsCurrentUser(String projectId) =>
      '${rankingsUsers(projectId)}/me';

  // ============================================================
  // EN: Unified fan-subject endpoints (project, unit, voice actor)
  // KO: 통합 팬 대상 엔드포인트 (프로젝트, 유닛, 성우)
  // ============================================================
  static const String fanSubjects = '$apiVersion/fan-subjects';
  static String fanSubject(String subjectId) => '$fanSubjects/$subjectId';
  static String fanSubjectChildren(String subjectId) =>
      '${fanSubject(subjectId)}/children';
  static const String myFanSubjects = '$apiVersion/users/me/fan-subjects';
  static String myFanSubject(String subjectId) => '$myFanSubjects/$subjectId';

  // ============================================================
  // EN: Admin User/Role endpoints (8.21)
  // KO: 어드민 사용자/권한 엔드포인트 (8.21)
  // ============================================================
  static const String adminUsers = '$apiVersion/admin/users';
  static String adminUserActive(String userId) => '$adminUsers/$userId/active';
  static String adminUserRole(String userId) => '$adminUsers/$userId/role';
  static String adminUserAccessLevel(String userId) =>
      '$adminUsers/$userId/access-level';
  static String adminUserAccessGrants(String userId) =>
      '$adminUsers/$userId/access-grants';
  static String adminUserAccessGrantRevoke(String userId, String grantId) =>
      '${adminUserAccessGrants(userId)}/$grantId/revoke';
  static const String adminUsersNotificationsBroadcast =
      '$adminUsers/notifications/broadcast';
  static const String adminUsersNotificationsTestSend =
      '$adminUsers/notifications/test-send';
  static const String adminTokensRevoke = '$apiVersion/admin/tokens/revoke';
  static String projectRoles(String projectId) => '${project(projectId)}/roles';
  static String projectRolesGrant(String projectId) =>
      '${projectRoles(projectId)}/grant';
  static String projectRolesRevoke(String projectId) =>
      '${projectRoles(projectId)}/revoke';
  static const String projectRoleRequests =
      '$apiVersion/projects/role-requests';
  static String projectRoleRequest(String requestId) =>
      '$projectRoleRequests/$requestId';
  static const String adminProjectRoleRequests =
      '$apiVersion/admin/projects/role-requests';
  static String adminProjectRoleRequest(String requestId) =>
      '$adminProjectRoleRequests/$requestId';
  static String adminProjectRoleRequestReview(String requestId) =>
      '${adminProjectRoleRequest(requestId)}/review';
  static const String adminPasswordSecurityConfig =
      '$apiVersion/admin/password-security/config';
  static const String adminPasswordSecurityTest =
      '$apiVersion/admin/password-security/test';
  static const String adminCircuitBreakers =
      '$apiVersion/admin/circuit-breakers';
  static const String adminCircuitBreakersRedis =
      '$apiVersion/admin/circuit-breakers/redis';
  static const String adminCircuitBreakersDatabase =
      '$apiVersion/admin/circuit-breakers/database';

  // ============================================================
  // EN: Admin Monitoring/Analytics endpoints (8.22)
  // KO: 어드민 모니터링/분석 엔드포인트 (8.22)
  // ============================================================
  static const String adminDashboard = '$apiVersion/admin/dashboard';
  static const String adminModerationDashboard =
      '$apiVersion/admin/moderation/dashboard';
  static const String adminCommunityReports =
      '$apiVersion/admin/community/reports';
  static String adminCommunityReport(String reportId) =>
      '$adminCommunityReports/$reportId';
  static String adminCommunityReportAssign(String reportId) =>
      '${adminCommunityReport(reportId)}/assign';
  static const String adminMediaDeletions = '$apiVersion/admin/media-deletions';
  static String adminMediaDeletionApprove(String requestId) =>
      '$adminMediaDeletions/$requestId/approve';
  static String adminMediaDeletionReject(String requestId) =>
      '$adminMediaDeletions/$requestId/reject';
  static const String adminAuditLogs = '$apiVersion/admin/audit-logs';
  static const String adminExports = '$apiVersion/admin/exports';
  static String adminExport(String id) => '$adminExports/$id';
  static String adminExportDownload(String id) => '${adminExport(id)}/download';
  static const String adminInsightsProjects =
      '$apiVersion/admin/insights/projects';
  static String adminInsightsProjectUnits(String projectId) =>
      '$adminInsightsProjects/$projectId/units';
  static const String adminAnalyticsVisitsByPlace =
      '$apiVersion/admin/analytics/visits/by-place';
  static const String adminAnalyticsVisitsTimeseries =
      '$apiVersion/admin/analytics/visits/timeseries';

  // ============================================================
  // EN: Admin Place/LiveEvent Operations endpoints (8.23)
  // KO: 어드민 장소/라이브 이벤트 운영 엔드포인트 (8.23)
  // ============================================================
  static String adminPlaceVisits(String projectId, String placeId) =>
      '${project(projectId)}/admin/places/$placeId/visits';
  static String adminPlaceVisitsSummary(String projectId, String placeId) =>
      '${adminPlaceVisits(projectId, placeId)}/summary';
  static String adminPlaceVisitsAnomalies(String projectId, String placeId) =>
      '${adminPlaceVisits(projectId, placeId)}/anomalies';
  static String adminPlaceVisitModerate(
    String projectId,
    String placeId,
    String visitId,
  ) => '${adminPlaceVisits(projectId, placeId)}/$visitId/moderate';
  static String adminLiveEvents(String projectId) =>
      '${project(projectId)}/admin/live-events';
  static String adminPlaceUnitsReplace(String projectId, String placeId) =>
      '${project(projectId)}/admin/places/$placeId/units:replace';
  static String adminNewsUnitsReplace(String projectId, String newsId) =>
      '${project(projectId)}/admin/news/$newsId/units:replace';
  static String adminLiveEventUnitsReplace(
    String projectId,
    String liveEventId,
  ) => '${project(projectId)}/admin/live-events/$liveEventId/units:replace';

  // ============================================================
  // EN: Admin SSE endpoints (8.24)
  // KO: 어드민 SSE 엔드포인트 (8.24)
  // ============================================================
  static const String adminStreamActivity = '$apiVersion/admin/stream/activity';
  static const String adminEventsStream = '$apiVersion/admin/events/stream';

  // ============================================================
  // EN: Banner endpoints (8.XX)
  // KO: 배너 엔드포인트 (8.XX)
  // ============================================================

  /// EN: Active banner for the authenticated user (GET/PUT/DELETE).
  /// KO: 인증된 사용자의 활성 배너 엔드포인트 (GET/PUT/DELETE).
  static const String userBanner = '$userMe/banner';

  /// EN: Full banner catalog with unlock state for the current user.
  /// KO: 현재 사용자의 해금 상태가 포함된 전체 배너 카탈로그.
  static const String banners = '$apiVersion/banners';

  // ============================================================
  // EN: Title endpoints (Title System v1)
  // KO: 칭호 엔드포인트 (칭호 시스템 v1)
  // ============================================================

  /// EN: Full title catalog (GET). Auth optional — isEarned/isActive null when unauthenticated.
  /// KO: 전체 칭호 카탈로그 (GET). 인증 선택 — 비인증 시 isEarned/isActive는 null.
  static const String titles = '$apiVersion/titles';

  /// EN: Authenticated user's active title (GET/PUT/DELETE).
  /// KO: 인증된 사용자의 활성 칭호 엔드포인트 (GET/PUT/DELETE).
  static const String userMeTitle = '$userMe/title';

  /// EN: Another user's active title (GET, public).
  /// KO: 다른 사용자의 활성 칭호 엔드포인트 (GET, 공개).
  static String userTitle(String userId) => '$apiVersion/users/$userId/title';

  // ============================================================
  // EN: Telemetry endpoints
  // KO: 텔레메트리 엔드포인트
  // ============================================================

  /// EN: Batch telemetry event submission (POST). Auth optional.
  /// KO: 텔레메트리 이벤트 배치 전송 (POST). 인증 선택.
  static const String telemetryEvents = '$apiVersion/telemetry/events';

  // ============================================================
  // EN: Health check endpoints (8.25)
  // KO: 헬스 체크 엔드포인트 (8.25)
  // ============================================================
  static const String health = '$apiVersion/health';
  static const String healthDetailed = '$apiVersion/health/detailed';
  static const String healthReady = '$apiVersion/health/ready';
  static const String healthLive = '$apiVersion/health/live';

  // ============================================================
  // EN: Fan level (덕力) endpoints
  // KO: 팬 레벨(덕력) 엔드포인트
  // ============================================================

  /// EN: Authenticated user's fan level profile (GET).
  /// KO: 인증된 사용자의 팬 레벨 프로필 (GET).
  static const String fanLevelProfile = '$apiVersion/users/me/fan-level';

  /// EN: Daily check-in endpoint for the authenticated user (POST).
  /// KO: 인증된 사용자의 일일 출석 체크 엔드포인트 (POST).
  static const String fanLevelCheckIn =
      '$apiVersion/users/me/fan-level/check-in';

  /// EN: XP earning endpoint for in-app activities (POST).
  /// KO: 앱 내 활동 XP 획득 엔드포인트 (POST).
  static const String fanLevelEarnXp = '$apiVersion/users/me/fan-level/xp';

  // ============================================================
  // EN: Cheer guide endpoints
  // KO: 응원 가이드 엔드포인트
  // ============================================================

  /// EN: List of all cheer guides (GET).
  /// KO: 모든 응원 가이드 목록 (GET).
  static const String cheerGuides = '$apiVersion/cheer-guides';

  /// EN: Single cheer guide detail by ID (GET).
  /// KO: ID로 단일 응원 가이드 상세 조회 (GET).
  static String cheerGuide(String guideId) => '$cheerGuides/$guideId';

  // ============================================================
  // EN: Quote card endpoints
  // KO: 명대사 카드 엔드포인트
  // ============================================================

  /// EN: List of quote cards (GET).
  /// KO: 명대사 카드 목록 (GET).
  static const String quotes = '$apiVersion/quotes';

  /// EN: Like/unlike a quote card (POST/DELETE).
  /// KO: 명대사 카드 좋아요/취소 (POST/DELETE).
  static String quoteLike(String quoteId) => '$quotes/$quoteId/like';

  // ============================================================
  // EN: Contributors endpoint — public, no auth required.
  // KO: 기여자 목록 엔드포인트 — 공개, 인증 불필요.
  // ============================================================

  /// EN: Deduplicated contributor list for any entity type (GET, public).
  ///     Sorted by lastModifiedAt DESC; `isRegistrant: true` marks the original creator.
  /// KO: 모든 엔티티 타입의 중복 제거된 기여자 목록 (GET, 공개).
  ///     lastModifiedAt 내림차순 정렬; `isRegistrant: true`가 최초 등록자.
  ///
  /// `entityType`: `places` | `lives` | `units` | `characters`
  ///               | `projects` | `songs` | `albums`
  static String contributors(String entityType, String entityId) =>
      '$apiVersion/$entityType/$entityId/contributors';

  // ============================================================
  // EN: Zukan / pilgrimage stamp collection endpoints
  // KO: 도감 / 성지순례 스탬프 컬렉션 엔드포인트
  // ============================================================

  /// EN: List of zukan collections (GET).
  /// KO: 도감 컬렉션 목록 (GET).
  static const String zukanCollections = '$apiVersion/zukan/collections';

  /// EN: Single zukan collection detail by ID (GET).
  /// KO: ID로 단일 도감 컬렉션 상세 조회 (GET).
  static String zukanCollection(String collectionId) =>
      '$zukanCollections/$collectionId';
}

/// EN: API timeout configurations (in milliseconds)
/// KO: API 타임아웃 구성 (밀리초)
class ApiTimeouts {
  ApiTimeouts._();

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 15000;
}

/// EN: API header constants
/// KO: API 헤더 상수
class ApiHeaders {
  ApiHeaders._();

  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  static const String accept = 'Accept';
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String clientType = 'X-Client-Type';
  static const String clientTypeMobile = 'mobile';
  static const String correlationId = 'X-Correlation-ID';
  static const String responseTime = 'X-Response-Time';
  static const String xsrfToken = 'X-XSRF-TOKEN';
}

/// EN: Pagination defaults
/// KO: 페이지네이션 기본값
class ApiPagination {
  ApiPagination._();

  static const int defaultPage = 0;
  static const int defaultSize = 20;
  static const int maxSize = 100;
}

/// EN: Cache control configurations
/// KO: 캐시 컨트롤 구성
class ApiCache {
  ApiCache._();

  /// EN: Default cache TTL in seconds
  /// KO: 기본 캐시 TTL (초)
  static const int defaultTtl = 300; // 5 minutes

  /// EN: Project list cache TTL
  /// KO: 프로젝트 목록 캐시 TTL
  static const int projectsTtl = 300; // 5 minutes

  /// EN: Place detail cache TTL
  /// KO: 장소 상세 캐시 TTL
  static const int placeDetailTtl = 600; // 10 minutes

  /// EN: Home summary cache TTL
  /// KO: 홈 요약 캐시 TTL
  static const int homeSummaryTtl = 300; // 5 minutes
}
