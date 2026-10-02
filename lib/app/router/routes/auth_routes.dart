/// EN: Auth domain routes (outside the shell): login, register, OAuth,
/// EN: email verification, and password reset.
/// KO: 인증 도메인 라우트(쉘 외부): 로그인, 회원가입, OAuth, 이메일 인증,
/// KO: 비밀번호 재설정.
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verification_args.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verification_pending_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/email_verified_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/login_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/oauth_callback_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/oauth_conflict_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/oauth_merge_existing_page.dart';
import 'package:oshi_log/features/identity/auth/presentation/pages/register_page.dart';

List<RouteBase> buildAuthRoutes() => [
  GoRoute(
    path: '/login',
    name: AppRoutes.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: '/register',
    name: AppRoutes.register,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    path: '/email-verification-pending',
    name: AppRoutes.emailVerificationPending,
    builder: (context, state) {
      final args = state.extra is EmailVerificationArgs
          ? state.extra! as EmailVerificationArgs
          : EmailVerificationArgs(
              email: state.uri.queryParameters['email'] ?? '',
            );
      return EmailVerificationPendingPage(args: args);
    },
  ),
  GoRoute(
    path: '/email-verified',
    name: AppRoutes.emailVerified,
    builder: (context, state) => const EmailVerifiedPage(),
  ),
  GoRoute(
    path: '/auth/callback',
    name: AppRoutes.oauthCallback,
    builder: (context, state) {
      final provider = state.uri.queryParameters['provider'] ?? '';
      final code = state.uri.queryParameters['code'] ?? '';
      final stateParam = state.uri.queryParameters['state'];
      return OAuthCallbackPage(
        providerId: provider,
        code: code,
        stateParam: stateParam,
      );
    },
  ),

  // EN: OAuth conflict page — shown after EMAIL_ACCOUNT_CONFLICT (409).
  //     Receives the conflict email via [state.extra].
  // KO: OAuth 충돌 페이지 — EMAIL_ACCOUNT_CONFLICT(409) 후 표시됩니다.
  //     충돌 이메일을 [state.extra]로 전달받습니다.
  GoRoute(
    path: '/oauth/conflict',
    name: AppRoutes.oauthConflict,
    builder: (context, state) {
      final email = state.extra is String ? state.extra! as String : '';
      return OAuthConflictPage(conflictEmail: email);
    },
  ),

  // EN: OAuth merge page — shown after successful OAuth login (new account).
  //     Asks the user whether to merge with an existing local account.
  // KO: OAuth 합치기 페이지 — 신규 OAuth 계정 생성 성공 후 표시됩니다.
  //     기존 로컬 계정과 합칠지 사용자에게 묻습니다.
  GoRoute(
    path: '/oauth/merge',
    name: AppRoutes.oauthMerge,
    builder: (context, state) => const OAuthMergeExistingPage(),
  ),
];
