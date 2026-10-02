/// EN: Settings domain routes (overlay, outside the shell).
/// KO: 설정 도메인 라우트 (오버레이, 쉘 외부).
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../../features/admin_ops/presentation/pages/admin_ops_page.dart';
import '../../../features/auth/presentation/pages/change_password_page.dart';
import '../../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/presentation/pages/reset_password_page.dart';
import '../../compositions/account/presentation/pages/account_tools_page.dart';
import '../../../features/settings/presentation/pages/community_settings_page.dart';
import '../../../features/settings/presentation/pages/consent_history_page.dart';
import '../../../features/settings/presentation/pages/linked_accounts_page.dart';
import '../../../features/settings/presentation/pages/notification_settings_page.dart';
import '../../../features/settings/presentation/pages/privacy_rights_page.dart';
import '../../../features/settings/presentation/pages/profile_edit_page.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../route_helpers.dart';

List<RouteBase> buildSettingsRoutes() => [
  GoRoute(
    path: '/settings',
    name: AppRoutes.settings,
    pageBuilder: (context, state) {
      return buildAdaptiveOverlayPage(
        key: state.pageKey,
        child: const SettingsPage(),
      );
    },
    routes: [
      GoRoute(
        path: 'profile',
        name: AppRoutes.profileEdit,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const ProfileEditPage(),
        ),
      ),
      GoRoute(
        path: 'notifications',
        name: AppRoutes.notificationSettings,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const NotificationSettingsPage(),
        ),
      ),
      GoRoute(
        path: 'account-tools',
        name: AppRoutes.accountTools,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const AccountToolsPage(),
        ),
      ),
      GoRoute(
        path: 'linked-accounts',
        name: AppRoutes.linkedAccounts,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const LinkedAccountsPage(),
        ),
      ),
      GoRoute(
        path: 'change-password',
        name: AppRoutes.changePassword,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
        ),
      ),
      GoRoute(
        path: 'privacy-rights',
        name: AppRoutes.privacyRights,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const PrivacyRightsPage(),
        ),
      ),
      GoRoute(
        path: 'consents',
        name: AppRoutes.consentHistory,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const ConsentHistoryPage(),
        ),
      ),
      GoRoute(
        path: 'admin',
        name: AppRoutes.adminOps,
        pageBuilder: (context, state) => buildAdaptiveOverlayPage(
          key: state.pageKey,
          child: const AdminOpsPage(),
        ),
      ),
    ],
  ),

  // EN: Password-related routes (unauthenticated access allowed).
  // KO: 비밀번호 관련 라우트 (비인증 접근 허용).
  GoRoute(
    path: '/forgot-password',
    name: AppRoutes.forgotPassword,
    pageBuilder: (context, state) => buildAdaptiveDetailPage(
      key: state.pageKey,
      child: const ForgotPasswordPage(),
    ),
  ),
  GoRoute(
    path: '/reset-password',
    name: AppRoutes.resetPassword,
    pageBuilder: (context, state) {
      final token = state.uri.queryParameters['token'];
      return buildAdaptiveDetailPage(
        key: state.pageKey,
        child: ResetPasswordPage(initialToken: token),
      );
    },
  ),

  GoRoute(
    path: '/community-settings',
    name: AppRoutes.communitySettings,
    builder: (context, state) => const CommunitySettingsPage(),
  ),
];
