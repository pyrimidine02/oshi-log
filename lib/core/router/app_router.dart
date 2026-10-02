/// EN: Feature-free route contracts: names, indices, and the assembled
/// EN: router. Assembly, guards, and feature-typed navigation helpers live
/// EN: in `lib/app/router/` and are re-exported here so existing importers
/// EN: do not need to change.
/// KO: 피처 의존 없는 라우트 상수와 인덱스입니다. 조립·가드·피처 타입을 쓰는
/// KO: 내비게이션 헬퍼는 `lib/app/router/`에 있으며, 기존 임포터가 바뀌지
/// KO: 않도록 여기서 재노출합니다.
library;

export '../../app/router/app_router.dart';
export '../../app/router/nav_extensions.dart';

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

  // EN: Explore branch (places + live + visits)
  // KO: 탐방 분기 (장소 + 라이브 + 방문기록)
  static const String explore = 'explore';
  static const String placeDetail = 'place-detail';
  static const String overlayPlaceDetail = 'overlay-place-detail';
  static const String eventDetail = 'event-detail';
  static const String overlayEventDetail = 'overlay-event-detail';

  // EN: Information branch (info + cheer guides + quotes + zukan)
  // KO: 정보 분기 (정보 + 응원가이드 + 명언 + 도감)
  static const String information = 'information';

  // EN: Community branch (board)
  // KO: 커뮤니티 분기 (게시판)
  static const String community = 'community';
  static const String feed = 'feed';
  static const String discover = 'discover';
  static const String travelReviewTab = 'travel-review-tab';

  // EN: Mypage branch
  // KO: 마이페이지 분기
  static const String mypage = 'mypage';

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

  /// EN: Explore branch — places map, live events, visit history.
  /// KO: 탐방 분기 — 장소 지도, 라이브, 방문기록.
  static const int explore = 1;

  /// EN: Information branch — info, cheer guides, quotes, zukan.
  /// KO: 정보 분기 — 정보, 응원가이드, 명언, 도감.
  static const int information = 2;

  /// EN: Mypage branch — fan level, calendar, collection, settings.
  /// KO: 마이페이지 분기 — 팬레벨, 달력, 컬렉션, 설정.
  static const int mypage = 3;

  /// EN: Community branch — board / feed.
  /// KO: 커뮤니티 분기 — 게시판.
  static const int community = 4;
}
