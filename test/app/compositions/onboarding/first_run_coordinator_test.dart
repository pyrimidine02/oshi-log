import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/app/compositions/onboarding/first_run_coordinator.dart';
import 'package:oshi_log/app/compositions/onboarding/onboarding_host.dart';
import 'package:oshi_log/app/compositions/onboarding/preferences_page.dart';
import 'package:oshi_log/app/router/auth_guard.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';

class _EmptyProjects extends ProjectsController {
  _EmptyProjects(super.ref) : super(loadOnCreate: false) {
    state = const AsyncData([]);
  }
}

void main() {
  testWidgets(
    'first run preserves deep link, offers once at home, persists skip',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) async => storage),
          projectsControllerProvider.overrideWith((ref) => _EmptyProjects(ref)),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/live?eventId=e#prepare',
        routes: [
          for (final path in ['/live', '/home'])
            GoRoute(path: path, builder: (_, __) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (_, child) =>
                FirstRunCoordinator(router: router, child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/live?eventId=e#prepare',
      );
      expect(find.byType(FirstRunPreferencesSheet), findsNothing);
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(FirstRunPreferencesSheet), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('first-run-skip-all')));
      await tester.pumpAndSettle();
      expect(storage.isOnboardingCompleted(), isTrue);
      router.go('/live');
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(FirstRunPreferencesSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guest preferences direct link closes to guest My without login',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      final router = GoRouter(
        initialLocation: '/preferences',
        redirect: authRedirect(AuthState.unauthenticated),
        routes: [
          GoRoute(
            path: '/preferences',
            builder: (_, __) => const PreferencesPage(),
          ),
          GoRoute(
            path: '/mypage',
            builder: (_, __) => const Scaffold(body: Text('guest My')),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('login')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWith((ref) async => storage),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LocaleThemeSheet), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('guest My'), findsOneWidget);
      expect(find.text('login'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
