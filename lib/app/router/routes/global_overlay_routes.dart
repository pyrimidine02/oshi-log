/// EN: Global overlay routes (outside the shell): search, favorites,
/// EN: notifications, otaku features (calendar/fan level/cheer guides/
/// EN: quotes/zukan), banner/title pickers, overlay-stack detail routes,
/// EN: visits, and user connections.
/// KO: 전역 오버레이 라우트 (쉘 외부): 검색, 즐겨찾기, 알림, 오타쿠 기능
/// KO: (달력/팬레벨/응원가이드/명언/도감), 배너/칭호 피커, 오버레이 스택
/// KO: 상세 라우트, 방문기록, 사용자 연결.
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../../features/calendar/presentation/field_calendar/field_calendar_page.dart';
import '../../../features/cheer_guides/presentation/pages/cheer_guide_detail_page.dart';
import '../../../features/cheer_guides/presentation/pages/cheer_guides_page.dart';
import '../../../features/favorites/presentation/pages/favorites_page.dart';
import '../../../features/fan_level/presentation/pages/fan_level_page.dart';
import '../../compositions/user_profile/presentation/field_user_profile/field_user_profile_page.dart';
import '../../../features/community/news/presentation/pages/news_detail_page.dart';
import 'package:oshi_log/features/community/posts/presentation/pages/post_bookmarks_page.dart';
import '../../compositions/posts/post_detail_route.dart';
import 'package:oshi_log/features/identity/social/presentation/pages/user_connections_page.dart';
import '../../../features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import '../../../features/music/presentation/pages/music_song_detail_page.dart';
import '../../../features/notifications/presentation/pages/notifications_page.dart';
import '../../../features/places/presentation/pages/place_detail_page.dart';
import '../../../features/profile_banner/presentation/pages/banner_picker_page.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/pages/fan_subject_detail_page.dart';
import '../../../features/quotes/presentation/pages/quotes_page.dart';
import '../../compositions/search/presentation/pages/search_page.dart';
import '../../../features/titles/presentation/pages/title_catalog_page.dart';
import '../../../features/visits/presentation/field_visit_ledger/field_visit_ledger_common.dart';
import '../../../features/visits/presentation/field_visit_ledger/field_visit_ledger_page.dart';
import '../../../features/visits/presentation/pages/visit_detail_page.dart';
import '../../../features/visits/presentation/pages/visit_stats_page.dart';
import '../../../features/zukan/presentation/field_archive/field_zukan_archive_page.dart';
import '../../../features/zukan/presentation/pages/zukan_detail_page.dart';
import '../route_helpers.dart';

List<RouteBase> buildGlobalOverlayRoutes() => [
  GoRoute(
    path: '/search',
    name: AppRoutes.search,
    pageBuilder: (context, state) {
      final query = state.uri.queryParameters['q'];
      return buildAdaptiveOverlayPage(
        key: state.pageKey,
        child: SearchPage(initialQuery: query),
      );
    },
  ),
  GoRoute(
    path: '/fan-subjects/:subjectId',
    name: AppRoutes.fanSubjectDetail,
    pageBuilder: (context, state) => buildAdaptiveDetailPage(
      key: state.pageKey,
      child: FanSubjectDetailPage(
        subjectId: state.pathParameters['subjectId']!,
      ),
    ),
  ),
  GoRoute(
    path: '/notifications',
    name: AppRoutes.notifications,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
      key: state.pageKey,
      child: const NotificationsPage(),
    ),
  ),
  GoRoute(
    path: '/favorites',
    name: AppRoutes.favorites,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
      key: state.pageKey,
      child: const FavoritesPage(),
    ),
  ),
  GoRoute(
    path: '/post-bookmarks',
    name: AppRoutes.postBookmarks,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
      key: state.pageKey,
      child: const PostBookmarksPage(),
    ),
  ),

  // EN: Otaku feature routes (overlay, outside shell)
  // KO: 오타쿠 기능 라우트 (오버레이, 쉘 외부)
  GoRoute(
    path: '/calendar',
    name: AppRoutes.calendar,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
      key: state.pageKey,
      child: const FieldCalendarPage(),
    ),
  ),
  GoRoute(
    path: '/fan-level',
    name: AppRoutes.fanLevel,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
      key: state.pageKey,
      child: const FanLevelPage(),
    ),
  ),
  GoRoute(
    path: '/cheer-guides',
    name: AppRoutes.cheerGuides,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
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
    pageBuilder: (context, state) =>
        buildAdaptiveOverlayPage(key: state.pageKey, child: const QuotesPage()),
  ),
  GoRoute(
    path: '/zukan',
    name: AppRoutes.zukan,
    pageBuilder: (context, state) => buildAdaptiveOverlayPage(
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
      return buildAdaptiveOverlayPage(
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
      return buildAdaptiveOverlayPage(
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
      return buildAdaptiveDetailPage(
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
      return buildAdaptiveDetailPage(
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
      return buildAdaptiveDetailPage(
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
      return buildAdaptiveDetailPage(
        key: state.pageKey,
        child: PostDetailRoute(
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
        return buildAdaptiveDetailPage(
          key: state.pageKey,
          child: const InvalidNavigationPage(
            message: '악곡 상세 경로 인자가 올바르지 않습니다. (projectId)',
          ),
        );
      }
      final songId = state.pathParameters['songId']!;
      final rawEventId = state.uri.queryParameters['eventId'];
      final eventId = rawEventId?.trim();
      return buildAdaptiveDetailPage(
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
];
