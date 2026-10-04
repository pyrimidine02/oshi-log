import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/widgets/buttons/gbt_button.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/auth_controller.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verification_args.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verification_pending_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verified_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/forgot_password_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/oauth_callback_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/oauth_conflict_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/reset_password_page.dart';

const _origin = '/live/events/event-1?project=p&song=s#calls';

class _SuccessfulAuth extends StateNotifier<AsyncValue<void>>
    implements AuthController {
  _SuccessfulAuth() : super(const AsyncData(null));

  @override
  Future<Result<void>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> linkExistingOAuth({required String password}) async =>
      const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({GoRouter router, ProviderContainer container})> _open(
  WidgetTester tester,
  String path, {
  String? redirect = _origin,
  String? externalReturn,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith((ref) => _SuccessfulAuth()),
    ],
  );
  container.read(externalLoginReturnProvider.notifier).state = externalReturn;
  final router = GoRouter(
    initialLocation: Uri(
      path: path,
      queryParameters: {if (redirect != null) 'redirect': redirect},
    ).toString(),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const Text('login target')),
      GoRoute(path: '/home', builder: (_, __) => const Text('home target')),
      GoRoute(
        path: '/live/events/:id',
        builder: (_, __) => const Text('detail'),
      ),
      GoRoute(
        path: '/pending',
        builder: (_, __) => const EmailVerificationPendingPage(
          args: EmailVerificationArgs(email: 'fan@example.test'),
        ),
      ),
      GoRoute(path: '/verified', builder: (_, __) => const EmailVerifiedPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/conflict',
        builder: (_, __) =>
            const OAuthConflictPage(conflictEmail: 'fan@example.test'),
      ),
      GoRoute(
        path: '/callback',
        builder: (_, __) =>
            const OAuthCallbackPage(providerId: 'invalid', code: ''),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, container: container);
}

void main() {
  testWidgets('verification back preserves the full return URI', (
    tester,
  ) async {
    final app = await _open(tester, '/pending');
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();
    expect(
      app.router.routeInformationProvider.value.uri.queryParameters['redirect'],
      _origin,
    );
  });

  for (final redirect in [_origin, 'https://untrusted.example/path']) {
    testWidgets('verified login validates return URI $redirect', (
      tester,
    ) async {
      final app = await _open(tester, '/verified', redirect: redirect);
      await tester.tap(find.byType(GBTButton));
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/login');
      expect(
        app
            .router
            .routeInformationProvider
            .value
            .uri
            .queryParameters['redirect'],
        redirect == _origin ? _origin : null,
      );
    });
  }

  testWidgets('forgot and reset preserve the return URI through success', (
    tester,
  ) async {
    final app = await _open(tester, '/forgot-password');
    await tester.ensureVisible(find.text('Already have a code? Enter it here'));
    await tester.tap(find.text('Already have a code? Enter it here'));
    await tester.pumpAndSettle();
    expect(
      app.router.routeInformationProvider.value.uri.queryParameters['redirect'],
      _origin,
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'reset-token');
    await tester.enterText(find.byType(TextFormField).at(1), 'FixtureOnly123!');
    await tester.enterText(find.byType(TextFormField).at(2), 'FixtureOnly123!');
    await tester.ensureVisible(find.byType(GBTButton));
    await tester.tap(find.byType(GBTButton));
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.path, '/login');
    expect(
      app.router.routeInformationProvider.value.uri.queryParameters['redirect'],
      _origin,
    );
  });

  testWidgets(
    'OAuth callback failure retains and consumes external return URI',
    (tester) async {
      final app = await _open(
        tester,
        '/callback',
        redirect: null,
        externalReturn: _origin,
      );
      await tester.tap(find.text('Back to login'));
      await tester.pumpAndSettle();
      expect(
        app
            .router
            .routeInformationProvider
            .value
            .uri
            .queryParameters['redirect'],
        _origin,
      );
      expect(app.container.read(externalLoginReturnProvider), isNull);
    },
  );

  testWidgets('linked account success returns to original detail', (
    tester,
  ) async {
    final app = await _open(tester, '/conflict');
    await tester.enterText(find.byType(TextFormField).last, 'FixtureOnly123!');
    await tester.ensureVisible(find.byType(GBTButton));
    await tester.tap(find.byType(GBTButton));
    await tester.pumpAndSettle();
    expect(app.router.routeInformationProvider.value.uri.toString(), _origin);
  });
}
