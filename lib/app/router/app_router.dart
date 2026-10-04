/// EN: GoRouter assembly: wires the auth guard, the 5-branch shell, and
/// EN: every domain route group. PR9 IA: branches reordered to
/// EN: home/map/live/community/mypage; old `/explore`, `/information` URLs
/// EN: are kept as compatibility redirects outside the shell.
/// KO: GoRouter 조립: 인증 가드, 5분기 쉘, 도메인별 라우트 그룹을 연결합니다.
/// KO: PR9 IA: 분기 순서가 홈/지도/라이브/커뮤니티/마이로 재배치되었으며,
/// KO: 기존 `/explore`, `/information` URL은 쉘 밖 호환 redirect로 유지됩니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import '../../design_system/widgets/feedback/gbt_navigation_error_view.dart';
import '../shell/main_scaffold.dart';
import 'auth_guard.dart';
import 'routes/auth_routes.dart';
import 'routes/community_routes.dart';
import 'routes/global_overlay_routes.dart';
import 'routes/home_routes.dart';
import 'routes/legacy_alias_routes.dart';
import 'routes/live_routes.dart';
import 'routes/map_routes.dart';
import 'routes/my_routes.dart';
import 'routes/settings_routes.dart';

/// EN: GoRouter provider with authentication redirect
/// KO: 인증 리다이렉트를 포함한 GoRouter 프로바이더
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(ref.read(authStateProvider));
  ref.listen(authStateProvider, (_, next) => refresh.value = next);

  final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authStateProvider))(context, state),
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

          // EN: Map Branch (Index 1) — places map + zukan collections.
          // KO: 지도 분기 (인덱스 1) — 장소 지도 + 도감 컬렉션.
          StatefulShellBranch(routes: buildMapRoutes()),

          // EN: Live Branch (Index 2) — schedule + music/artist archive.
          // KO: 라이브 분기 (인덱스 2) — 스케줄 + 음악/아티스트 아카이브.
          StatefulShellBranch(routes: buildLiveRoutes()),

          // EN: Community Branch (Index 3) — board / feed.
          // KO: 커뮤니티 분기 (인덱스 3) — 게시판.
          StatefulShellBranch(routes: buildCommunityRoutes()),

          // EN: Mypage Branch (Index 4) — fan level, calendar, collection, settings.
          // KO: 마이페이지 분기 (인덱스 4) — 팬레벨, 달력, 컬렉션, 설정.
          StatefulShellBranch(routes: buildMyRoutes()),
        ],
      ),

      // EN: Settings routes (overlay, outside shell)
      // KO: 설정 라우트 (오버레이, 쉘 외부)
      ...buildSettingsRoutes(),

      // EN: Overlay routes (outside shell)
      // KO: 오버레이 라우트 (쉘 외부)
      ...buildGlobalOverlayRoutes(),

      // EN: Legacy alias redirects (outside shell, no bottom-nav of their own)
      // KO: 레거시 alias redirect (쉘 외부, 자체 하단바 없음)
      ...buildLegacyAliasRoutes(),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: GBTNavigationErrorView(
        message: '페이지를 찾을 수 없어요',
        details: state.matchedLocation,
        onRecover: () => context.go('/home'),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
