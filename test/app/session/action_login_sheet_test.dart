import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/app/session/action_login_sheet.dart';
import 'package:oshi_log/app/session/protected_read_gate.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/auth_controller.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/login_page.dart';

class _IdleAuth extends StateNotifier<AsyncValue<void>>
    implements AuthController {
  _IdleAuth() : super(const AsyncData(null));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final signedIn = StateProvider((ref) => false);
  testWidgets('dismissed login cannot pop underlying detail on late success', (
    tester,
  ) async {
    var actions = 0;
    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => ref.watch(signedIn)),
        authControllerProvider.overrideWith((ref) => _IdleAuth()),
        apiSessionGenerationProvider.overrideWithValue(() => 7),
        authenticationGateProvider.overrideWith(
          (ref) =>
              (context) => showActionLoginSheet(context, ref),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/base',
      routes: [
        GoRoute(path: '/base', builder: (_, __) => const Scaffold()),
        GoRoute(
          path: '/detail',
          builder: (_, __) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async {
                  if (await ref.read(authenticationGateProvider)(context)) {
                    actions++;
                  }
                },
                child: const Text('save'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/detail?projectId=p&eventId=e#calls');
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    final login = tester.widget<LoginPage>(find.byType(LoginPage));
    expect(login.redirectTarget, '/detail?projectId=p&eventId=e#calls');
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 20));
    container.read(signedIn.notifier).state = true;
    login.onAuthenticated!();
    await tester.pumpAndSettle();
    expect(find.byType(ActionLoginSheet), findsNothing);
    expect(router.state.uri.path, '/detail');
    expect(actions, 0);
    expect(tester.takeException(), isNull);
  });
  for (final success in [true, false]) {
    testWidgets(
      'action login ${success ? 'resumes once' : 'cancels'} and preserves full URI',
      (tester) async {
        var actions = 0;
        final container = ProviderContainer(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => ref.watch(signedIn)),
            authControllerProvider.overrideWith((ref) => _IdleAuth()),
            apiSessionGenerationProvider.overrideWithValue(() => 7),
            authenticationGateProvider.overrideWith(
              (ref) =>
                  (context) => showActionLoginSheet(context, ref),
            ),
          ],
        );
        addTearDown(container.dispose);
        final origin = Uri.parse('/detail?projectId=p&eventId=e#calls');
        final router = GoRouter(
          initialLocation: origin.toString(),
          routes: [
            GoRoute(
              path: '/detail',
              builder: (_, __) => Scaffold(
                body: Consumer(
                  builder: (context, ref, _) => FilledButton(
                    child: const Text('save'),
                    onPressed: () async {
                      if (await ref.read(authenticationGateProvider)(context)) {
                        actions++;
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('save'));
        await tester.pumpAndSettle();
        expect(find.byType(ActionLoginSheet), findsOneWidget);
        expect(actions, 0);
        if (success) {
          container.read(signedIn.notifier).state = true;
          await tester.pump();
          // EN: An unrelated sign-in alone must not release the pending action.
          // KO: 다른 경로의 로그인만으로 대기 행동을 실행하면 안 됩니다.
          expect(find.byType(ActionLoginSheet), findsOneWidget);
          expect(actions, 0);
          tester.widget<LoginPage>(find.byType(LoginPage)).onAuthenticated!();
        } else {
          await tester.tap(find.byIcon(Icons.close));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ActionLoginSheet), findsNothing);
        expect(actions, success ? 1 : 0);
        expect(router.routeInformationProvider.value.uri, origin);
        await tester.pumpAndSettle();
        expect(actions, success ? 1 : 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('protected consumer is not built before login', (tester) async {
    var reads = 0;
    final container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => ref.watch(signedIn)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ProtectedReadGate(
              child: Builder(
                builder: (_) {
                  reads++;
                  return const Text('private');
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(reads, 0);
    container.read(signedIn.notifier).state = true;
    await tester.pump();
    expect(reads, 1);
    expect(find.text('private'), findsOneWidget);
  });
}
