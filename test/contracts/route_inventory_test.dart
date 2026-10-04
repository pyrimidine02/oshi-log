// EN: PR 0 contract — freezes the full route path+name inventory of the real
//     router config (including /overlay/* and shell branches) so any route
//     add/remove/rename fails loudly during the redesign.
// KO: PR 0 계약 — 실제 라우터 설정의 전체 경로+이름 목록(오버레이, 쉘 분기
//     포함)을 고정하여 라우트 추가/삭제/변경 시 테스트가 실패하도록 합니다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/app/router/app_router.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

/// EN: Walks the route tree, joining parent/child paths the same way
///     go_router does, and records "path|name" for every GoRoute.
/// KO: go_router와 동일한 방식으로 상위/하위 경로를 이어붙이며 모든 GoRoute의
///     "path|name"을 기록합니다.
void _walk(List<RouteBase> routes, String parentPath, List<String> out) {
  for (final route in routes) {
    if (route is GoRoute) {
      final joined = route.path.startsWith('/')
          ? route.path
          : '$parentPath/${route.path}';
      final normalized = joined.replaceAll(RegExp(r'/+'), '/');
      out.add('$normalized|${route.name ?? ''}');
      _walk(route.routes, normalized, out);
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        _walk(branch.routes, parentPath, out);
      }
    }
  }
}

// EN: Checked-in snapshot. Update deliberately when a route is intentionally
//     added/removed/renamed — never to silence a failing test.
// KO: 체크인된 스냅샷입니다. 라우트를 의도적으로 추가/삭제/변경할 때만
//     갱신하세요 — 실패하는 테스트를 조용히 넘기기 위해 갱신하지 마세요.
const _expectedRoutes = <String>[
  '/login|login',
  '/register|register',
  '/email-verification-pending|email-verification-pending',
  '/email-verified|email-verified',
  '/auth/callback|oauth-callback',
  '/oauth/conflict|oauth-conflict',
  '/oauth/merge|oauth-merge',
  '/home|home',
  '/home/news/:newsId|home-news-detail',
  '/map|map',
  '/map/places/:placeId|map-place-detail',
  '/live|live',
  '/live/events/:eventId|live-event-detail',
  '/live/artists/:unitId|live-unit-detail',
  '/live/artists/:unitId/members/:memberId|live-member-detail',
  '/live/voice-actors/:voiceActorId|live-voice-actor-detail',
  '/live/music|music-archive',
  '/live/music/songs/:songId|music-song-detail',
  '/community|community',
  '/community/discover|discover',
  '/community/travel-reviews-tab|travel-review-tab',
  '/community/posts/new|post-create',
  '/community/travel-review-create|travelReviewCreate',
  '/community/:projectCode/travel-reviews/:reviewId|travelReviewDetail',
  '/community/travel-reviews/:reviewId|',
  '/community/posts/:postId|post-detail',
  '/community/posts/:postId/edit|post-edit',
  '/mypage|mypage',
  '/mypage/today|today',
  '/mypage/trips|private-trips',
  '/mypage/records|visit-records',
  '/settings|settings',
  '/settings/profile|profile-edit',
  '/settings/notifications|notification-settings',
  '/settings/account-tools|account-tools',
  '/settings/linked-accounts|linked-accounts',
  '/settings/change-password|change-password',
  '/settings/privacy-rights|privacy-rights',
  '/settings/consents|consent-history',
  '/settings/admin|admin-ops',
  '/forgot-password|forgot-password',
  '/reset-password|reset-password',
  '/community-settings|community-settings',
  '/preferences|preferences',
  '/search|search',
  '/fan-subjects/:subjectId|fan-subject-detail',
  '/notifications|notifications',
  '/favorites|favorites',
  '/post-bookmarks|post-bookmarks',
  '/calendar|calendar',
  '/fan-level|fan-level',
  '/cheer-guides|cheer-guides',
  '/cheer-guides/:guideId|cheer-guide-detail',
  '/quotes|quotes',
  '/zukan|zukan',
  '/zukan/:collectionId|zukan-detail',
  '/live-attendance|',
  '/banner-picker|banner-picker',
  '/title-picker|title-picker',
  '/overlay/places/:placeId|overlay-place-detail',
  '/overlay/events/:eventId|overlay-event-detail',
  '/overlay/info/news/:newsId|overlay-news-detail',
  '/overlay/board/posts/:postId|overlay-post-detail',
  '/overlay/music/songs/:songId|overlay-song-detail',
  '/visits|visit-history',
  '/visits/:visitId|visit-detail',
  '/visit-stats|visit-stats',
  '/users/:userId|user-profile',
  '/users/:userId/followers|user-followers',
  '/users/:userId/following|user-following',

  // EN: PR9 IA — legacy alias redirects for pre-IA URLs. Kept so old
  // EN: `goNamed`/path callers keep resolving to the new canonical routes
  // EN: above. See `screen-implementation-spec-v1.md` URL compat table.
  // KO: PR9 IA — 구 IA URL을 위한 레거시 alias redirect입니다. 기존
  // KO: `goNamed`/경로 호출자가 위 새 canonical 라우트로 계속 해석되도록
  // KO: 유지합니다. `screen-implementation-spec-v1.md` URL 호환 표 참고.
  '/explore|explore',
  '/explore/places/:placeId|place-detail',
  '/explore/events/:eventId|event-detail',
  '/information|information',
  '/information/news/:newsId|news-detail',
  '/information/units/:unitId|unit-detail',
  '/information/units/:unitId/members/:memberId|member-detail',
  '/information/voice-actors/:voiceActorId|voice-actor-detail',
  '/information/songs/:songId|song-detail',
];

void main() {
  test('auth transitions retain the router and all five branch navigators', () {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
    );
    addTearDown(container.dispose);
    container.read(authStateProvider.notifier).setUnauthenticated();
    final router = container.read(appRouterProvider);
    final shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;
    expect(
      shell.branches.map((branch) => (branch.routes.first as GoRoute).path),
      ['/home', '/map', '/live', '/community', '/mypage'],
    );
    container.read(authStateProvider.notifier).setAuthenticated();
    expect(container.read(appRouterProvider), same(router));
    container.read(authStateProvider.notifier).setUnauthenticated();
    expect(container.read(appRouterProvider), same(router));
  });

  test('route inventory matches the frozen snapshot', () {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    final actual = <String>[];
    _walk(router.configuration.routes, '', actual);

    expect(
      actual,
      _expectedRoutes,
      reason:
          'Route inventory changed. If intentional, update _expectedRoutes '
          'in this test to match (PR 0 contract).',
    );
  });
}
