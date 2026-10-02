/// EN: GoRouter assembly: wires the auth guard, the 5-branch shell, and
/// EN: every domain route group. No route path/name/behavior changes.
/// KO: GoRouter 조립: 인증 가드, 5분기 쉘, 도메인별 라우트 그룹을 연결합니다.
/// KO: 경로/이름/동작 변경 없음.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import '../../core/widgets/feedback/gbt_navigation_error_view.dart';
import '../shell/main_scaffold.dart';
import 'auth_guard.dart';
import 'routes/auth_routes.dart';
import 'routes/community_routes.dart';
import 'routes/explore_routes.dart';
import 'routes/global_overlay_routes.dart';
import 'routes/home_routes.dart';
import 'routes/info_routes.dart';
import 'routes/my_routes.dart';
import 'routes/settings_routes.dart';

/// EN: GoRouter provider with authentication redirect
/// KO: 인증 리다이렉트를 포함한 GoRouter 프로바이더
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
    redirect: authRedirect(authState),
    routes: [
      // EN: Auth routes (outside shell)
      // KO: 인증 라우트 (쉘 외부)
      ...buildAuthRoutes(),

      // EN: Main app with bottom navigation shell
      // KO: 하단 네비게이션 쉘을 포함한 메인 앱
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // EN: Home Branch (Index 0)
          // KO: 홈 분기 (인덱스 0)
          StatefulShellBranch(routes: buildHomeRoutes()),

          // EN: Explore Branch (Index 1) — map + live + visits sub-tabs.
          // KO: 탐방 분기 (인덱스 1) — 지도 + 라이브 + 방문기록 서브탭.
          StatefulShellBranch(routes: buildExploreRoutes()),

          // EN: Information Branch (Index 2) — info, cheer guides, quotes, zukan.
          // KO: 정보 분기 (인덱스 2) — 정보, 응원가이드, 명언, 도감.
          StatefulShellBranch(routes: buildInfoRoutes()),

          // EN: Mypage Branch (Index 3) — fan level, calendar, collection, settings.
          // KO: 마이페이지 분기 (인덱스 3) — 팬레벨, 달력, 컬렉션, 설정.
          StatefulShellBranch(routes: buildMyRoutes()),

          // EN: Community Branch (Index 4) — board / feed.
          // KO: 커뮤니티 분기 (인덱스 4) — 게시판.
          StatefulShellBranch(routes: buildCommunityRoutes()),
        ],
      ),

      // EN: Settings routes (overlay, outside shell)
      // KO: 설정 라우트 (오버레이, 쉘 외부)
      ...buildSettingsRoutes(),

      // EN: Overlay routes (outside shell)
      // KO: 오버레이 라우트 (쉘 외부)
      ...buildGlobalOverlayRoutes(),
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
