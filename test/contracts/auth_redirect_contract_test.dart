// EN: PR 0 contract — freezes the router's redirect behavior for
//     logged-out/logged-in access to protected, public, and auth routes.
//     Drives the real redirect by pumping the real GoRouter inside a Router
//     widget (redirect only runs as part of route parsing driven by the
//     Router widget pipeline); does not reimplement the redirect logic.
//     Destination pages may fail to fully build without their real
//     dependencies — that's fine, the location is already resolved by
//     redirect before the page builder runs, so stray exceptions from page
//     bodies are drained and ignored.
// KO: PR 0 계약 — 보호된/공개/인증 경로에 대한 로그인/비로그인 상태의 라우터
//     리다이렉트 동작을 고정합니다. redirect는 Router 위젯 파이프라인이
//     구동하는 경로 파싱의 일부로만 실행되므로 실제 GoRouter를 Router
//     위젯 안에서 펌프하여 구동합니다. 로직을 재구현하지 않습니다.
//     목적지 페이지는 실제 의존성 없이 완전히 빌드되지 않을 수 있지만,
//     redirect가 끝난 뒤 페이지 빌더가 실행되므로 위치는 이미 해결된
//     상태입니다. 페이지 본문에서 발생하는 예외는 무시합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/security/secure_storage.dart';

void main() {
  // EN: appRouterProvider rebuilds (new GoRouter instance) whenever
  //     authStateProvider changes, since the redirect closure captures the
  //     watched value at build time. So the auth state must be set BEFORE
  //     reading the provider.
  // KO: appRouterProvider는 authStateProvider가 바뀔 때마다 재생성됩니다.
  //     redirect 클로저가 빌드 시점의 값을 캡처하기 때문입니다. 따라서
  //     프로바이더를 읽기 전에 인증 상태를 먼저 설정해야 합니다.
  Future<GoRouter> pumpRouterWithAuthState(
    WidgetTester tester,
    void Function(ProviderContainer) setup,
  ) async {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
    );
    addTearDown(container.dispose);
    setup(container);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // EN: Drain any build errors from destination pages missing their real
    // EN: dependencies (network clients, etc.) — irrelevant to this contract.
    // KO: 실제 의존성(네트워크 클라이언트 등)이 없는 목적지 페이지의 빌드
    // KO: 오류는 이 계약과 무관하므로 비웁니다.
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 50));
    tester.takeException();
    return router;
  }

  String currentLocation(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  testWidgets(
    'logged-out access to a protected path redirects to login with redirect param',
    (tester) async {
      final router = await pumpRouterWithAuthState(
        tester,
        (c) => c.read(authStateProvider.notifier).setUnauthenticated(),
      );

      router.go('/mypage');
      await tester.pump(const Duration(milliseconds: 50));
      tester.takeException();

      expect(currentLocation(router), '/login?redirect=%2Fmypage');
    },
  );

  testWidgets('logged-out access to /home (public) is allowed', (
    tester,
  ) async {
    final router = await pumpRouterWithAuthState(
      tester,
      (c) => c.read(authStateProvider.notifier).setUnauthenticated(),
    );

    router.go('/home');
    await tester.pump(const Duration(milliseconds: 50));
    tester.takeException();

    expect(currentLocation(router), '/home');
  });

  testWidgets('logged-out access to /information* (public) is allowed', (
    tester,
  ) async {
    final router = await pumpRouterWithAuthState(
      tester,
      (c) => c.read(authStateProvider.notifier).setUnauthenticated(),
    );

    router.go('/information');
    await tester.pump(const Duration(milliseconds: 50));
    tester.takeException();

    expect(currentLocation(router), '/information');
  });

  testWidgets('logged-in access to /login redirects to /home', (
    tester,
  ) async {
    final router = await pumpRouterWithAuthState(
      tester,
      (c) => c.read(authStateProvider.notifier).setAuthenticated(),
    );

    router.go('/login');
    await tester.pump(const Duration(milliseconds: 50));
    tester.takeException();

    expect(currentLocation(router), '/home');
  });
}
