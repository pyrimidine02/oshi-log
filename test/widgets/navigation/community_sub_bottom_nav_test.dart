import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/app/shell/main_scaffold.dart';
import 'package:oshi_log/platform/router/navigation_state.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_bottom_nav.dart';

void main() {
  for (final locale in ['ja', 'ko']) {
    testWidgets(
      'real shell keeps main navigation across community sections $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final router = GoRouter(
          initialLocation: '/community',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => MainScaffold(navigationShell: shell),
              branches: [
                for (final path in [
                  '/home',
                  '/map',
                  '/live',
                  '/community',
                  '/mypage',
                ])
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: path,
                        builder: (_, __) => Center(child: Text('body:$path')),
                        routes: [
                          if (path == '/community')
                            for (final section in [
                              'discover',
                              'travel-reviews-tab',
                            ])
                              GoRoute(
                                path: section,
                                builder: (_, __) =>
                                    Center(child: Text('section:$section')),
                              ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(locale),
              supportedLocales: const [Locale('ja'), Locale('ko')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in [
          '/community',
          '/community/discover',
          '/community/travel-reviews-tab',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          final nav = tester.widget<GBTBottomNav>(find.byType(GBTBottomNav));
          expect(nav.items, hasLength(5));
          expect(nav.currentIndex, 3);
          expect(container.read(currentNavIndexProvider), 3);
          expect(tester.takeException(), isNull);
        }
        // EN: Session cleanup can reset shared state; the actual shell wins.
        // KO: 세션 정리가 공용 상태를 초기화해도 실제 쉘 위치가 우선합니다.
        container.read(currentNavIndexProvider.notifier).state = 0;
        await tester.pumpAndSettle();
        expect(container.read(currentNavIndexProvider), 3);
        await tester.tap(find.text(locale == 'ja' ? 'ライブ' : '라이브'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/live');
        expect(container.read(currentNavIndexProvider), 2);
        await tester.tap(find.text(locale == 'ja' ? 'コミュニティ' : '커뮤니티'));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/community/travel-reviews-tab',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
