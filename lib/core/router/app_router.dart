/// EN: GoRouter configuration with deep linking support
/// KO: 딥링크 지원을 포함한 GoRouter 구성
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/core_providers.dart';
import '../theme/gbt_animations.dart';
import '../widgets/feedback/gbt_navigation_error_view.dart';
import '../widgets/navigation/gbt_standard_app_bar.dart';
import '../../shared/main_scaffold.dart';
import '../../features/auth/presentation/pages/change_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_args.dart';
import '../../features/auth/presentation/pages/email_verification_pending_page.dart';
import '../../features/auth/presentation/pages/email_verified_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/oauth_callback_page.dart';
import '../../features/auth/presentation/pages/oauth_conflict_page.dart';
import '../../features/auth/presentation/pages/oauth_merge_existing_page.dart';
import '../../features/settings/presentation/pages/linked_accounts_page.dart';
import '../../features/home/presentation/field_home/field_home_page.dart';
import '../../features/explore/presentation/field_explore/field_explore_page.dart';
import '../../features/places/presentation/pages/place_detail_page.dart';
import '../../features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import '../../features/feed/presentation/field_community/field_community_page.dart';
import '../../features/feed/presentation/field_guide/field_guide_page.dart';
import '../../features/my/presentation/travel_passport/travel_passport_page.dart';
import '../../features/feed/presentation/pages/member_detail_page.dart';
import '../../features/feed/presentation/pages/news_detail_page.dart';
import '../../features/feed/presentation/pages/post_create_page.dart';
import '../../features/feed/presentation/pages/post_detail_page.dart';
import '../../features/feed/presentation/pages/unit_detail_page.dart';
import '../../features/feed/presentation/pages/voice_actor_detail_page.dart';
import '../../features/music/presentation/pages/music_song_detail_page.dart';
import '../../features/projects/domain/entities/project_entities.dart'
    show Unit, UnitMember;
import '../../features/projects/presentation/pages/fan_subject_detail_page.dart';
import '../../features/feed/presentation/pages/post_edit_page.dart';
import '../../features/feed/presentation/pages/travel_review_create_page.dart';
import '../../features/feed/presentation/pages/travel_review_detail_page.dart';
import '../../features/feed/presentation/pages/user_connections_page.dart';
import '../../features/feed/presentation/field_user_profile/field_user_profile_page.dart';
import '../../features/feed/domain/entities/feed_entities.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/community_settings_page.dart';
import '../../features/settings/presentation/pages/profile_edit_page.dart';
import '../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../features/settings/presentation/pages/account_tools_page.dart';
import '../../features/settings/presentation/pages/privacy_rights_page.dart';
import '../../features/settings/presentation/pages/consent_history_page.dart';
import '../../features/admin_ops/presentation/pages/admin_ops_page.dart';
import '../../features/visits/presentation/pages/visit_detail_page.dart';
import '../../features/visits/presentation/field_visit_ledger/field_visit_ledger_page.dart';
import '../../features/visits/presentation/field_visit_ledger/field_visit_ledger_common.dart';
import '../../features/visits/presentation/pages/visit_stats_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/feed/presentation/pages/post_bookmarks_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile_banner/presentation/pages/banner_picker_page.dart';
import '../../features/titles/presentation/pages/title_catalog_page.dart';
import '../../features/calendar/presentation/field_calendar/field_calendar_page.dart';
import '../../features/fan_level/presentation/pages/fan_level_page.dart';
import '../../features/cheer_guides/presentation/pages/cheer_guides_page.dart';
import '../../features/cheer_guides/presentation/pages/cheer_guide_detail_page.dart';
import '../../features/quotes/presentation/pages/quotes_page.dart';
import '../../features/zukan/presentation/field_archive/field_zukan_archive_page.dart';
import '../../features/zukan/presentation/pages/zukan_detail_page.dart';

DateTime? _lastPostDetailNavigationAt;
String? _lastPostDetailNavigationPath;

Page<void> _buildAdaptiveDetailPage({
  required LocalKey key,
  required Widget child,
}) {
  // EN: Delegate to MaterialPage to universally respect the theme's PageTransitionsTheme.
  // KO: 테마의 PageTransitionsTheme을 전역적으로 존중하기 위해 MaterialPage에 위임합니다.
  return MaterialPage<void>(key: key, child: child);
}

Page<void> _buildAdaptiveOverlayPage({
  required LocalKey key,
  required Widget child,
}) {
  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return MaterialPage<void>(key: key, child: child);
  }
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: GBTPageTransitions.sharedAxisY(),
    transitionDuration: GBTAnimations.normal,
  );
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

/// EN: GoRouter provider with authentication redirect
/// KO: 인증 리다이렉트를 포함한 GoRouter 프로바이더
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      if (authState == AuthState.initial) {
        return null;
      }

      final isLoggedIn = authState == AuthState.authenticated;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' ||
          loc == '/register' ||
          loc.startsWith('/auth/') ||
          loc.startsWith('/oauth/') ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/email-verification-pending' ||
          loc == '/email-verified';
      final isPublicRoute = loc == '/home' || loc.startsWith('/information');

      // EN: If logged in and on auth pages, redirect to home.
      // KO: 로그인했고 인증 페이지면 홈으로 리다이렉트.
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      // EN: If not logged in and trying to access protected routes, redirect
      // EN: to login with original destination.
      // KO: 비로그인 상태에서 보호된 경로 접근 시 원래 목적지와 함께
      // KO: 로그인 페이지로 리다이렉트.
      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
        final redirectTo = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$redirectTo';
      }

      return null;
    },
    routes: [
      // EN: Auth routes (outside shell)
      // KO: 인증 라우트 (쉘 외부)
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/email-verification-pending',
        name: AppRoutes.emailVerificationPending,
        builder: (context, state) {
          final args = state.extra is EmailVerificationArgs
              ? state.extra! as EmailVerificationArgs
              : EmailVerificationArgs(
                  email: state.uri.queryParameters['email'] ?? '',
                );
          return EmailVerificationPendingPage(args: args);
        },
      ),
      GoRoute(
        path: '/email-verified',
        name: AppRoutes.emailVerified,
        builder: (context, state) => const EmailVerifiedPage(),
      ),
      GoRoute(
        path: '/auth/callback',
        name: AppRoutes.oauthCallback,
        builder: (context, state) {
          final provider = state.uri.queryParameters['provider'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          final stateParam = state.uri.queryParameters['state'];
          return OAuthCallbackPage(
            providerId: provider,
            code: code,
            stateParam: stateParam,
          );
        },
      ),

      // EN: OAuth conflict page — shown after EMAIL_ACCOUNT_CONFLICT (409).
      //     Receives the conflict email via [state.extra].
      // KO: OAuth 충돌 페이지 — EMAIL_ACCOUNT_CONFLICT(409) 후 표시됩니다.
      //     충돌 이메일을 [state.extra]로 전달받습니다.
      GoRoute(
        path: '/oauth/conflict',
        name: AppRoutes.oauthConflict,
        builder: (context, state) {
          final email = state.extra is String ? state.extra! as String : '';
          return OAuthConflictPage(conflictEmail: email);
        },
      ),

      // EN: OAuth merge page — shown after successful OAuth login (new account).
      //     Asks the user whether to merge with an existing local account.
      // KO: OAuth 합치기 페이지 — 신규 OAuth 계정 생성 성공 후 표시됩니다.
      //     기존 로컬 계정과 합칠지 사용자에게 묻습니다.
      GoRoute(
        path: '/oauth/merge',
        name: AppRoutes.oauthMerge,
        builder: (context, state) => const OAuthMergeExistingPage(),
      ),

      // EN: Main app with bottom navigation shell
      // KO: 하단 네비게이션 쉘을 포함한 메인 앱
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // EN: Home Branch (Index 0)
          // KO: 홈 분기 (인덱스 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: AppRoutes.home,
                builder: (context, state) => const FieldHomePage(),
              ),
            ],
          ),

          // EN: Explore Branch (Index 1) — map + live + visits sub-tabs.
          // KO: 탐방 분기 (인덱스 1) — 지도 + 라이브 + 방문기록 서브탭.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                name: AppRoutes.explore,
                pageBuilder: (context, state) {
                  final tabParam = state.uri.queryParameters['tab'];
                  final tabIndex = tabParam != null
                      ? (int.tryParse(tabParam) ?? 0)
                      : 0;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: FieldExplorePage(initialTabIndex: tabIndex),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'places/:placeId',
                    name: AppRoutes.placeDetail,
                    pageBuilder: (context, state) {
                      final placeId = state.pathParameters['placeId']!;
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: PlaceDetailPage(placeId: placeId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'events/:eventId',
                    name: AppRoutes.eventDetail,
                    pageBuilder: (context, state) {
                      final eventId = state.pathParameters['eventId']!;
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: FieldLiveEventDetailPage(eventId: eventId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // EN: Information Branch (Index 2) — info, cheer guides, quotes, zukan.
          // KO: 정보 분기 (인덱스 2) — 정보, 응원가이드, 명언, 도감.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/information',
                name: AppRoutes.information,
                builder: (context, state) => const FieldGuidePage(),
                routes: [
                  GoRoute(
                    path: 'news/:newsId',
                    name: AppRoutes.newsDetail,
                    pageBuilder: (context, state) {
                      final newsId = state.pathParameters['newsId']!;
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: NewsDetailPage(newsId: newsId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'units/:unitId',
                    name: AppRoutes.unitDetail,
                    pageBuilder: (context, state) {
                      final unitIdentifier = state.pathParameters['unitId']!;
                      final projectId =
                          state.uri.queryParameters['projectId'] ?? '';
                      if (projectId.trim().isEmpty) {
                        return _buildAdaptiveDetailPage(
                          key: state.pageKey,
                          child: const _InvalidNavigationPage(
                            message: '유닛 상세 경로 인자가 올바르지 않습니다. (projectId)',
                          ),
                        );
                      }
                      final unit = state.extra is Unit
                          ? state.extra! as Unit
                          : null;
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: UnitDetailPage(
                          projectId: projectId,
                          unitIdentifier: unitIdentifier,
                          initialUnit: unit,
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'members/:memberId',
                        name: AppRoutes.memberDetail,
                        pageBuilder: (context, state) {
                          final projectId =
                              state.uri.queryParameters['projectId'] ?? '';
                          if (projectId.trim().isEmpty) {
                            return _buildAdaptiveDetailPage(
                              key: state.pageKey,
                              child: const _InvalidNavigationPage(
                                message: '멤버 상세 경로 인자가 올바르지 않습니다. (projectId)',
                              ),
                            );
                          }
                          final unitIdentifier =
                              state.pathParameters['unitId']!;
                          final memberId = state.pathParameters['memberId']!;
                          UnitMember? member;
                          Unit? unit;
                          final extra = state.extra;
                          if (extra is Map<String, dynamic>) {
                            final maybeMember = extra['member'];
                            final maybeUnit = extra['unit'];
                            if (maybeMember is UnitMember) {
                              member = maybeMember;
                            }
                            if (maybeUnit is Unit) {
                              unit = maybeUnit;
                            }
                          }
                          return _buildAdaptiveDetailPage(
                            key: state.pageKey,
                            child: MemberDetailPage(
                              projectId: projectId,
                              unitIdentifier: unitIdentifier,
                              memberId: memberId,
                              initialMember: member,
                              unit: unit,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'voice-actors/:voiceActorId',
                    name: AppRoutes.voiceActorDetail,
                    pageBuilder: (context, state) {
                      final projectId =
                          state.uri.queryParameters['projectId'] ?? '';
                      if (projectId.trim().isEmpty) {
                        return _buildAdaptiveDetailPage(
                          key: state.pageKey,
                          child: const _InvalidNavigationPage(
                            message: '성우 상세 경로 인자가 올바르지 않습니다. (projectId)',
                          ),
                        );
                      }
                      final voiceActorId =
                          state.pathParameters['voiceActorId']!;
                      final fallbackName = state.uri.queryParameters['name'];
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: VoiceActorDetailPage(
                          projectId: projectId,
                          voiceActorId: voiceActorId,
                          fallbackName: fallbackName,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'songs/:songId',
                    name: AppRoutes.songDetail,
                    pageBuilder: (context, state) {
                      final projectId =
                          state.uri.queryParameters['projectId'] ?? '';
                      if (projectId.trim().isEmpty) {
                        return _buildAdaptiveDetailPage(
                          key: state.pageKey,
                          child: const _InvalidNavigationPage(
                            message: '악곡 상세 경로 인자가 올바르지 않습니다. (projectId)',
                          ),
                        );
                      }
                      final songId = state.pathParameters['songId']!;
                      final rawEventId = state.uri.queryParameters['eventId'];
                      final eventId = rawEventId?.trim();
                      return _buildAdaptiveDetailPage(
                        key: state.pageKey,
                        child: MusicSongDetailPage(
                          projectId: projectId,
                          songId: songId,
                          eventId: eventId?.isEmpty == true ? null : eventId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // EN: Mypage Branch (Index 3) — fan level, calendar, collection, settings.
          // KO: 마이페이지 분기 (인덱스 3) — 팬레벨, 달력, 컬렉션, 설정.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mypage',
                name: AppRoutes.mypage,
                builder: (context, state) => const TravelPassportPage(),
              ),
            ],
          ),

          // EN: Community Branch (Index 4) — board / feed.
          // KO: 커뮤니티 분기 (인덱스 4) — 게시판.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                name: AppRoutes.community,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const FieldCommunityPage(initialSectionIndex: 0),
                ),
                routes: [
                  GoRoute(
                    path: 'discover',
                    name: AppRoutes.discover,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const FieldCommunityPage(initialSectionIndex: 1),
                    ),
                  ),
                  GoRoute(
                    path: 'travel-reviews-tab',
                    name: AppRoutes.travelReviewTab,
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const FieldCommunityPage(initialSectionIndex: 2),
                    ),
                  ),
                  GoRoute(
                    path: 'posts/new',
                    name: AppRoutes.postCreate,
                    pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
                      key: state.pageKey,
                      child: const PostCreatePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'travel-review-create',
                    name: AppRoutes.travelReviewCreate,
                    pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
                      key: state.pageKey,
                      child: const TravelReviewCreatePage(),
                    ),
                  ),
                  GoRoute(
                    path: ':projectCode/travel-reviews/:reviewId',
                    name: AppRoutes.travelReviewDetail,
                    builder: (context, state) {
                      final projectCode = state.pathParameters['projectCode']!;
                      final reviewId = state.pathParameters['reviewId']!;
                      return TravelReviewDetailPage(
                        projectCode: projectCode,
                        reviewId: reviewId,
                      );
                    },
                  ),
                  // EN: Preserve query-qualified legacy links while refusing
                  //     to guess project scope from mutable global state.
                  // KO: 쿼리에 프로젝트가 있는 기존 링크는 보존하되 변경 가능한
                  //     전역 상태에서 프로젝트 범위를 추측하지 않습니다.
                  GoRoute(
                    path: 'travel-reviews/:reviewId',
                    redirect: (context, state) {
                      final projectCode = state
                          .uri
                          .queryParameters['projectCode']
                          ?.trim();
                      if (projectCode == null || projectCode.isEmpty) {
                        return null;
                      }
                      return state.namedLocation(
                        AppRoutes.travelReviewDetail,
                        pathParameters: {
                          'projectCode': projectCode,
                          'reviewId': state.pathParameters['reviewId']!,
                        },
                      );
                    },
                    builder: (context, state) {
                      return const _InvalidNavigationPage(
                        message: '여행 후기 링크에 프로젝트 정보가 없습니다.',
                      );
                    },
                  ),
                  GoRoute(
                    path: 'posts/:postId',
                    name: AppRoutes.postDetail,
                    builder: (context, state) {
                      final postId = state.pathParameters['postId']!;
                      final projectCodeHint =
                          state.uri.queryParameters['projectCode'];
                      return PostDetailPage(
                        postId: postId,
                        projectCodeHint: projectCodeHint,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'posts/:postId/edit',
                    name: AppRoutes.postEdit,
                    builder: (context, state) {
                      final post = state.extra;
                      if (post is! PostDetail) {
                        return const _InvalidNavigationPage(
                          message: '게시글 수정 경로 인자가 올바르지 않습니다.',
                        );
                      }
                      return PostEditPage(post: post);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // EN: Settings routes (overlay, outside shell)
      // KO: 설정 라우트 (오버레이, 쉘 외부)
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        pageBuilder: (context, state) {
          return _buildAdaptiveOverlayPage(
            key: state.pageKey,
            child: const SettingsPage(),
          );
        },
        routes: [
          GoRoute(
            path: 'profile',
            name: AppRoutes.profileEdit,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const ProfileEditPage(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            name: AppRoutes.notificationSettings,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const NotificationSettingsPage(),
            ),
          ),
          GoRoute(
            path: 'account-tools',
            name: AppRoutes.accountTools,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const AccountToolsPage(),
            ),
          ),
          GoRoute(
            path: 'linked-accounts',
            name: AppRoutes.linkedAccounts,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const LinkedAccountsPage(),
            ),
          ),
          GoRoute(
            path: 'change-password',
            name: AppRoutes.changePassword,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const ChangePasswordPage(),
            ),
          ),
          GoRoute(
            path: 'privacy-rights',
            name: AppRoutes.privacyRights,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const PrivacyRightsPage(),
            ),
          ),
          GoRoute(
            path: 'consents',
            name: AppRoutes.consentHistory,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const ConsentHistoryPage(),
            ),
          ),
          GoRoute(
            path: 'admin',
            name: AppRoutes.adminOps,
            pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
              key: state.pageKey,
              child: const AdminOpsPage(),
            ),
          ),
        ],
      ),

      // EN: Overlay routes (outside shell)
      // KO: 오버레이 라우트 (쉘 외부)
      // EN: Password-related routes (unauthenticated access allowed).
      // KO: 비밀번호 관련 라우트 (비인증 접근 허용).
      GoRoute(
        path: '/forgot-password',
        name: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _buildAdaptiveDetailPage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        name: AppRoutes.resetPassword,
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: ResetPasswordPage(initialToken: token),
          );
        },
      ),

      GoRoute(
        path: '/community-settings',
        name: AppRoutes.communitySettings,
        builder: (context, state) => const CommunitySettingsPage(),
      ),
      GoRoute(
        path: '/search',
        name: AppRoutes.search,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return _buildAdaptiveOverlayPage(
            key: state.pageKey,
            child: SearchPage(initialQuery: query),
          );
        },
      ),
      GoRoute(
        path: '/fan-subjects/:subjectId',
        name: AppRoutes.fanSubjectDetail,
        pageBuilder: (context, state) => _buildAdaptiveDetailPage(
          key: state.pageKey,
          child: FanSubjectDetailPage(
            subjectId: state.pathParameters['subjectId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: AppRoutes.favorites,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const FavoritesPage(),
        ),
      ),
      GoRoute(
        path: '/post-bookmarks',
        name: AppRoutes.postBookmarks,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const PostBookmarksPage(),
        ),
      ),

      // EN: Otaku feature routes (overlay, outside shell)
      // KO: 오타쿠 기능 라우트 (오버레이, 쉘 외부)
      GoRoute(
        path: '/calendar',
        name: AppRoutes.calendar,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const FieldCalendarPage(),
        ),
      ),
      GoRoute(
        path: '/fan-level',
        name: AppRoutes.fanLevel,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const FanLevelPage(),
        ),
      ),
      GoRoute(
        path: '/cheer-guides',
        name: AppRoutes.cheerGuides,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const CheerGuidesPage(),
        ),
        routes: [
          GoRoute(
            path: ':guideId',
            name: AppRoutes.cheerGuideDetail,
            builder: (context, state) {
              final guideId = state.pathParameters['guideId']!;
              return CheerGuideDetailPage(guideId: guideId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/quotes',
        name: AppRoutes.quotes,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const QuotesPage(),
        ),
      ),
      GoRoute(
        path: '/zukan',
        name: AppRoutes.zukan,
        pageBuilder: (context, state) => _buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const FieldZukanArchivePage(),
        ),
        routes: [
          GoRoute(
            path: ':collectionId',
            name: AppRoutes.zukanDetail,
            builder: (context, state) {
              final collectionId = state.pathParameters['collectionId']!;
              return ZukanDetailPage(collectionId: collectionId);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/live-attendance',
        redirect: (context, state) => '/visits?tab=live',
      ),

      // EN: Profile banner picker — overlay route outside the shell.
      // KO: 프로필 배너 피커 — 쉘 외부 오버레이 라우트.
      GoRoute(
        path: '/banner-picker',
        name: AppRoutes.bannerPicker,
        pageBuilder: (context, state) {
          return _buildAdaptiveOverlayPage(
            key: state.pageKey,
            child: const BannerPickerPage(),
          );
        },
      ),

      // EN: Title catalog picker — overlay route outside the shell.
      // KO: 칭호 카탈로그 피커 — 쉘 외부 오버레이 라우트.
      GoRoute(
        path: '/title-picker',
        name: AppRoutes.titlePicker,
        pageBuilder: (context, state) {
          final initialTitleId = state.uri.queryParameters['titleId'];
          return _buildAdaptiveOverlayPage(
            key: state.pageKey,
            child: TitleCatalogPage(initialTitleId: initialTitleId),
          );
        },
      ),

      // EN: Overlay detail routes used when opening details from overlay stacks
      // EN: (settings/favorites/visits/stats/notifications/search).
      // KO: 오버레이 스택(설정/즐겨찾기/방문/통계/알림/검색)에서 상세를 열 때
      // KO: 기존 오버레이 스택을 유지하기 위한 전용 상세 라우트입니다.
      GoRoute(
        path: '/overlay/places/:placeId',
        name: AppRoutes.overlayPlaceDetail,
        pageBuilder: (context, state) {
          final placeId = state.pathParameters['placeId']!;
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: PlaceDetailPage(placeId: placeId),
          );
        },
      ),
      GoRoute(
        path: '/overlay/events/:eventId',
        name: AppRoutes.overlayEventDetail,
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: FieldLiveEventDetailPage(eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: '/overlay/info/news/:newsId',
        name: AppRoutes.overlayNewsDetail,
        pageBuilder: (context, state) {
          final newsId = state.pathParameters['newsId']!;
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: NewsDetailPage(newsId: newsId),
          );
        },
      ),
      GoRoute(
        path: '/overlay/board/posts/:postId',
        name: AppRoutes.overlayPostDetail,
        pageBuilder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final projectCodeHint = state.uri.queryParameters['projectCode'];
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: PostDetailPage(
              postId: postId,
              projectCodeHint: projectCodeHint,
            ),
          );
        },
      ),
      GoRoute(
        path: '/overlay/music/songs/:songId',
        name: AppRoutes.overlaySongDetail,
        pageBuilder: (context, state) {
          final projectId = state.uri.queryParameters['projectId'] ?? '';
          if (projectId.trim().isEmpty) {
            return _buildAdaptiveDetailPage(
              key: state.pageKey,
              child: const _InvalidNavigationPage(
                message: '악곡 상세 경로 인자가 올바르지 않습니다. (projectId)',
              ),
            );
          }
          final songId = state.pathParameters['songId']!;
          final rawEventId = state.uri.queryParameters['eventId'];
          final eventId = rawEventId?.trim();
          return _buildAdaptiveDetailPage(
            key: state.pageKey,
            child: MusicSongDetailPage(
              projectId: projectId,
              songId: songId,
              eventId: eventId?.isEmpty == true ? null : eventId,
            ),
          );
        },
      ),

      // EN: Visit routes (top-level overlays to avoid duplicate key with /settings)
      // KO: 방문 라우트 (중복 key 방지를 위해 /settings 외부의 최상위 오버레이)
      GoRoute(
        path: '/visits',
        name: AppRoutes.visitHistory,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialKind = tab == 'live'
              ? FieldVisitLedgerKind.events
              : FieldVisitLedgerKind.places;
          return FieldVisitLedgerPage(initialKind: initialKind);
        },
        routes: [
          GoRoute(
            path: ':visitId',
            name: AppRoutes.visitDetail,
            builder: (context, state) {
              final visitId = state.pathParameters['visitId']!;
              final placeId = state.uri.queryParameters['placeId'] ?? '';
              final visitedAt = state.uri.queryParameters['visitedAt'];
              return VisitDetailPage(
                visitId: visitId,
                placeId: placeId,
                visitedAt: visitedAt,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/visit-stats',
        name: AppRoutes.visitStats,
        builder: (context, state) => const VisitStatsPage(),
      ),
      GoRoute(
        path: '/users/:userId',
        name: AppRoutes.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FieldUserProfilePage(userId: userId);
        },
        routes: [
          GoRoute(
            path: 'followers',
            name: AppRoutes.userFollowers,
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return UserConnectionsPage(
                userId: userId,
                initialTab: UserConnectionsTab.followers,
              );
            },
          ),
          GoRoute(
            path: 'following',
            name: AppRoutes.userFollowing,
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return UserConnectionsPage(
                userId: userId,
                initialTab: UserConnectionsTab.following,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: GBTNavigationErrorView(
        message: '페이지를 찾을 수 없어요',
        details: state.matchedLocation,
        onRecover: () => context.go('/home'),
      ),
    ),
  );
});

class _InvalidNavigationPage extends StatelessWidget {
  const _InvalidNavigationPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gbtStandardAppBar(context, title: '여정을 열 수 없어요'),
      body: GBTNavigationErrorView(
        message: '요청한 페이지를 열 수 없어요',
        details: message,
      ),
    );
  }
}

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
    try {
      return GoRouterState.of(this).uri.path;
    } catch (_) {
      return GoRouter.of(this).routeInformationProvider.value.uri.path;
    }
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
    final isSameTarget = contextPath == targetPath || routerPath == targetPath;
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
      AppRoutes.placeDetail,
      pathParameters: {'placeId': placeId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(AppRoutes.placeDetail, pathParameters: {'placeId': placeId});
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
      AppRoutes.eventDetail,
      pathParameters: {'eventId': eventId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(AppRoutes.eventDetail, pathParameters: {'eventId': eventId});
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
      AppRoutes.newsDetail,
      pathParameters: {'newsId': newsId},
    );
    switch (_resolveShellNavigationAction(targetPath)) {
      case _ShellNavigationAction.go:
        go(targetPath);
        return;
      case _ShellNavigationAction.none:
        return;
      case _ShellNavigationAction.push:
        pushNamed(AppRoutes.newsDetail, pathParameters: {'newsId': newsId});
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
      AppRoutes.songDetail,
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
          AppRoutes.songDetail,
          pathParameters: {'songId': songId},
          queryParameters: queryParameters,
        );
        return;
    }
  }

  /// EN: Navigate to unit detail page.
  /// KO: 유닛 상세 페이지로 이동.
  void goToUnitDetail({required Unit unit, required String projectId}) {
    final unitIdentifier = unit.code.isNotEmpty ? unit.code : unit.id;
    goToUnitDetailByIdentifier(
      unitIdentifier,
      projectId: projectId,
      initialUnit: unit,
    );
  }

  /// EN: Navigate to unit detail when only a search identity is available.
  /// KO: 검색 식별자만 있는 경우 유닛 상세 페이지로 이동합니다.
  void goToUnitDetailByIdentifier(
    String unitIdentifier, {
    required String projectId,
    Unit? initialUnit,
  }) {
    final trimmedUnitIdentifier = unitIdentifier.trim();
    final trimmedProjectId = projectId.trim();
    if (trimmedUnitIdentifier.isEmpty || trimmedProjectId.isEmpty) {
      return;
    }
    pushNamed(
      AppRoutes.unitDetail,
      pathParameters: {'unitId': trimmedUnitIdentifier},
      queryParameters: {'projectId': trimmedProjectId},
      extra: initialUnit,
    );
  }

  /// EN: Navigate to member (character + VA) detail page.
  /// KO: 멤버(캐릭터 + 성우) 상세 페이지로 이동.
  void goToMemberDetail({
    required Unit unit,
    required UnitMember member,
    required String projectId,
  }) {
    final unitIdentifier = unit.code.isNotEmpty ? unit.code : unit.id;
    pushNamed(
      AppRoutes.memberDetail,
      pathParameters: {'unitId': unitIdentifier, 'memberId': member.id},
      queryParameters: {'projectId': projectId},
      extra: {'member': member, 'unit': unit},
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
      AppRoutes.voiceActorDetail,
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

  /// EN: Navigate to post edit.
  /// KO: 게시글 수정으로 이동
  void goToPostEdit(PostDetail post) {
    pushNamed(
      AppRoutes.postEdit,
      pathParameters: {'postId': post.id},
      extra: post,
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
