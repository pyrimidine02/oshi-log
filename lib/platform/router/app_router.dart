/// EN: Feature-free navigation contract: route name/index constants, the
/// EN: `BuildContext` navigation extension, and the open-redirect guard.
/// EN: Router assembly (`appRouterProvider`) lives in `lib/app/router/` and
/// EN: must only be imported from `lib/app.dart`, `lib/main.dart`, or
/// EN: `lib/app/**`.
/// KO: 피처 의존 없는 내비게이션 계약입니다: 라우트 이름/인덱스 상수,
/// KO: `BuildContext` 내비게이션 확장, 오픈 리다이렉트 가드. 라우터 조립
/// KO: (`appRouterProvider`)은 `lib/app/router/`에 있으며 `lib/app.dart`,
/// KO: `lib/main.dart`, `lib/app/**`에서만 임포트해야 합니다.
library;

export 'nav_extensions.dart';

/// EN: Validates a post-login `redirect` query value, rejecting anything
/// EN: that isn't a safe relative in-app path (open-redirect guard).
/// KO: 로그인 후 `redirect` 쿼리 값이 안전한 상대 경로인지 검증합니다
/// KO: (오픈 리다이렉트 방지).
String? safeRedirectTarget(String? redirect) {
  if (redirect == null || redirect.isEmpty) return null;
  if (!redirect.startsWith('/') || redirect.startsWith('//')) return null;
  const authPrefixes = [
    '/login',
    '/register',
    '/auth/',
    '/oauth/',
    '/forgot-password',
    '/reset-password',
    '/email-verification-pending',
    '/email-verified',
  ];
  if (authPrefixes.any(redirect.startsWith)) return null;
  return redirect;
}

/// EN: Route names as constants
/// KO: 라우트 이름 상수
class AppRoutes {
  AppRoutes._();

  // EN: Auth routes
  // KO: 인증 라우트
  static const String login = 'login';
  static const String register = 'register';
  static const String oauthCallback = 'oauth-callback';
  static const String oauthConflict = 'oauth-conflict';
  static const String oauthMerge = 'oauth-merge';
  static const String linkedAccounts = 'linked-accounts';

  // EN: Main tab routes
  // KO: 메인 탭 라우트
  static const String home = 'home';

  // EN: Map branch (places map + zukan collections) — PR9 IA.
  // KO: 지도 분기 (장소 지도 + 도감 컬렉션) — PR9 IA.
  static const String map = 'map';
  static const String placeDetail = 'place-detail';
  static const String overlayPlaceDetail = 'overlay-place-detail';

  // EN: Live branch (schedule + music/artist archive) — PR9 IA.
  // KO: 라이브 분기 (스케줄 + 음악/아티스트 아카이브) — PR9 IA.
  static const String live = 'live';
  static const String musicArchive = 'music-archive';
  static const String eventDetail = 'event-detail';
  static const String overlayEventDetail = 'overlay-event-detail';

  // EN: Legacy alias-only route names (redirect targets, no page of their
  // EN: own); kept so old `goNamed` calls keep resolving. PR9 IA.
  // KO: 레거시 alias 전용 라우트 이름(자체 화면 없이 redirect만 수행).
  // KO: 기존 `goNamed` 호출이 계속 동작하도록 유지합니다. PR9 IA.
  static const String explore = 'explore';
  static const String information = 'information';

  static const String mapPlaceDetail = 'map-place-detail';
  static const String liveEventDetail = 'live-event-detail';
  static const String homeNewsDetail = 'home-news-detail';
  static const String musicSongDetail = 'music-song-detail';
  static const String liveUnitDetail = 'live-unit-detail';
  static const String liveMemberDetail = 'live-member-detail';
  static const String liveVoiceActorDetail = 'live-voice-actor-detail';

  // EN: Community branch (board)
  // KO: 커뮤니티 분기 (게시판)
  static const String community = 'community';
  static const String feed = 'feed';
  static const String discover = 'discover';
  static const String travelReviewTab = 'travel-review-tab';

  // EN: Mypage branch
  // KO: 마이페이지 분기
  static const String mypage = 'mypage';
  static const String visitRecords = 'visit-records';
  static const String today = 'today';
  static const String privateTrips = 'private-trips';

  // EN: Info/idol sub-routes
  // KO: 정보/아이돌 서브 라우트
  static const String info = 'info';
  static const String newsDetail = 'news-detail';
  static const String overlayNewsDetail = 'overlay-news-detail';
  static const String unitDetail = 'unit-detail';
  static const String memberDetail = 'member-detail';
  static const String voiceActorDetail = 'voice-actor-detail';
  static const String fanSubjectDetail = 'fan-subject-detail';
  static const String songDetail = 'song-detail';
  static const String postDetail = 'post-detail';
  static const String overlayPostDetail = 'overlay-post-detail';
  static const String overlaySongDetail = 'overlay-song-detail';
  static const String postCreate = 'post-create';
  static const String travelReviewCreate = 'travelReviewCreate';
  static const String travelReviewDetail = 'travelReviewDetail';
  static const String postEdit = 'post-edit';
  static const String userProfile = 'user-profile';
  static const String userFollowers = 'user-followers';
  static const String userFollowing = 'user-following';

  // EN: Settings routes (overlay, outside shell)
  // KO: 설정 라우트 (오버레이, 쉘 외부)
  static const String settings = 'settings';
  static const String preferences = 'preferences';
  static const String communitySettings = 'community-settings';
  static const String profileEdit = 'profile-edit';
  static const String notificationSettings = 'notification-settings';
  static const String accountTools = 'account-tools';
  static const String changePassword = 'change-password';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';
  static const String emailVerificationPending = 'email-verification-pending';
  static const String emailVerified = 'email-verified';
  static const String privacyRights = 'privacy-rights';
  static const String consentHistory = 'consent-history';
  static const String adminOps = 'admin-ops';
  static const String visitHistory = 'visit-history';
  static const String visitDetail = 'visit-detail';
  static const String visitStats = 'visit-stats';

  // EN: Overlay routes
  // KO: 오버레이 라우트
  static const String search = 'search';
  static const String notifications = 'notifications';
  static const String favorites = 'favorites';
  static const String postBookmarks = 'post-bookmarks';

  // EN: Profile banner picker overlay route.
  // KO: 프로필 배너 피커 오버레이 라우트.
  static const String bannerPicker = 'banner-picker';

  // EN: Title catalog picker overlay route.
  // KO: 칭호 카탈로그 피커 오버레이 라우트.
  static const String titlePicker = 'title-picker';

  // EN: Otaku feature routes.
  // KO: 오타쿠 기능 라우트.
  static const String calendar = 'calendar';
  static const String fanLevel = 'fan-level';
  static const String cheerGuides = 'cheer-guides';
  static const String cheerGuideDetail = 'cheer-guide-detail';
  static const String quotes = 'quotes';
  static const String zukan = 'zukan';
  static const String zukanDetail = 'zukan-detail';
}

/// EN: Navigation shell branch index
/// KO: 네비게이션 쉘 분기 인덱스
class NavIndex {
  NavIndex._();

  static const int home = 0;

  /// EN: Map branch — places map, zukan collections.
  /// KO: 지도 분기 — 장소 지도, 도감 컬렉션.
  static const int map = 1;

  /// EN: Live branch — schedule, music/artist archive.
  /// KO: 라이브 분기 — 스케줄, 음악/아티스트 아카이브.
  static const int live = 2;

  /// EN: Community branch — board / feed.
  /// KO: 커뮤니티 분기 — 게시판.
  static const int community = 3;

  /// EN: Mypage branch — fan level, calendar, collection, settings.
  /// KO: 마이페이지 분기 — 팬레벨, 달력, 컬렉션, 설정.
  static const int mypage = 4;
}
