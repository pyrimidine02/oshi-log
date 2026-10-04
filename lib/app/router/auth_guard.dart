/// EN: Authentication redirect guard for the app router.
/// KO: 앱 라우터의 인증 리다이렉트 가드입니다.
library;

import 'package:go_router/go_router.dart';
import 'routes/legacy_alias_routes.dart';

import '../../platform/router/app_router.dart' show safeRedirectTarget;
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

export '../../platform/router/app_router.dart' show safeRedirectTarget;

/// EN: Builds the `GoRouter.redirect` callback bound to the given auth state.
/// KO: 주어진 인증 상태에 묶인 `GoRouter.redirect` 콜백을 만듭니다.
GoRouterRedirect authRedirect(AuthState authState) {
  return (context, state) {
    final legacyTarget = legacyRouteDestination(state.uri);
    if (legacyTarget != null) return legacyTarget;
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
    // EN: PR9 IA: `/map`, `/live` are public read-only entry points; `/mypage`
    // EN: root is public too (guest intro — no protected calls), but
    // EN: `/mypage/records` (personal visit ledger) stays protected.
    // KO: PR9 IA: `/map`, `/live`는 공개 읽기 진입점입니다; `/mypage` 루트도
    // KO: 공개입니다(게스트 소개 — 보호 호출 없음), 다만 `/mypage/records`
    // KO: (개인 방문 원장)는 보호된 상태를 유지합니다.
    final isPublicRoute =
        loc == '/home' ||
        loc == '/preferences' ||
        loc.startsWith('/home/news/') ||
        loc.startsWith('/information') ||
        loc == '/map' ||
        loc.startsWith('/map/') ||
        loc == '/live' ||
        loc.startsWith('/live/') ||
        loc == '/mypage' ||
        loc == '/community' ||
        loc == '/community/discover' ||
        loc == '/community/travel-reviews-tab';

    // EN: If logged in and on auth pages, redirect to home (or a valid
    // EN: pending redirect target, e.g. /login?redirect=/mypage).
    // KO: 로그인했고 인증 페이지면 홈으로(또는 유효한 redirect 쿼리가
    // KO: 있으면 그 경로로) 리다이렉트.
    if (isLoggedIn && isAuthRoute && loc != '/auth/callback') {
      final target = safeRedirectTarget(state.uri.queryParameters['redirect']);
      return target ?? '/home';
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
  };
}
