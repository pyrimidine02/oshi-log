/// EN: Page for managing linked social (OAuth) accounts — connect Google/Apple,
///     disconnect the currently linked provider.
/// KO: 소셜(OAuth) 계정 연결을 관리하는 페이지 — Google/Apple 연결,
///     현재 연결된 제공자 해제.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart'
    show showGBTAdaptiveConfirmDialog;
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../auth/application/auth_controller.dart';
import '../widgets/field_settings_components.dart';

/// EN: Displays social account connection management options.
/// KO: 소셜 계정 연결 관리 옵션을 표시합니다.
class LinkedAccountsPage extends ConsumerWidget {
  const LinkedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '소셜 계정 연결',
          en: 'Linked Accounts',
          ja: 'ソーシャルアカウント連携',
        ),
      ),
      body: ListView(
        padding: GBTSpacing.paddingPage,
        children: [
          const SizedBox(height: GBTSpacing.md),
          FieldSettingsIntro(
            eyebrow: 'SIGN-IN ROUTES',
            title: context.l10n(
              ko: '계정에 접속할 경로를 관리하세요',
              en: 'Manage your sign-in routes',
              ja: 'ログイン経路を管理',
            ),
            description: context.l10n(
              ko: '소셜 계정을 연결하면 해당 계정으로 앱에 접근할 수 있어요.',
              en: 'Link a provider to use it when signing in to the app.',
              ja: 'プロバイダーを連携してアプリのログインに使用できます。',
            ),
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: GBTSpacing.xl),

          FieldSettingsSection(
            title: context.l10n(
              ko: '로그인 제공자',
              en: 'SIGN-IN PROVIDERS',
              ja: 'ログイン方法',
            ),
            children: [
              _SocialAccountRow(
                icon: Icons.g_mobiledata_rounded,
                iconColor: const Color(0xFF4285F4),
                useIconChip: false,
                title: context.l10n(
                  ko: 'Google 연결',
                  en: 'Connect Google',
                  ja: 'Googleと連携',
                ),
                isLoading: isLoading,
                onTap: () => _handleConnectGoogle(context, ref),
              ),
              if (Platform.isIOS)
                _SocialAccountRow(
                  icon: Icons.apple_rounded,
                  iconColor: Colors.black,
                  useIconChip: false,
                  title: context.l10n(
                    ko: 'Apple 연결',
                    en: 'Connect Apple',
                    ja: 'Appleと連携',
                  ),
                  isLoading: isLoading,
                  onTap: () => _handleConnectApple(context, ref),
                ),
            ],
          ),

          const SizedBox(height: GBTSpacing.xxxl),

          FieldSettingsSection(
            title: context.l10n(ko: '연결 해제', en: 'DISCONNECT', ja: '連携解除'),
            description: context.l10n(
              ko: '비밀번호가 없는 소셜 계정은 먼저 비밀번호를 설정해야 연결을 해제할 수 있어요.',
              en: 'Social-only accounts need a password before they can disconnect.',
              ja: 'ソーシャル専用アカウントは先にパスワードを設定してください。',
            ),
            children: [
              _SocialAccountRow(
                icon: Icons.link_off_rounded,
                iconColor: GBTColors.error,
                useIconChip: false,
                title: context.l10n(
                  ko: '소셜 계정 연결 해제',
                  en: 'Disconnect social account',
                  ja: 'ソーシャルアカウントの連携解除',
                ),
                isLoading: isLoading,
                onTap: () => _handleDisconnect(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnectGoogle(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .connectGoogle();
    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      result,
      successMessage: context.l10n(
        ko: 'Google 계정이 연결되었습니다',
        en: 'Google account connected',
        ja: 'Googleアカウントが連携されました',
      ),
    );
  }

  Future<void> _handleConnectApple(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .connectApple();
    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      result,
      successMessage: context.l10n(
        ko: 'Apple 계정이 연결되었습니다',
        en: 'Apple account connected',
        ja: 'Appleアカウントが連携されました',
      ),
    );
  }

  Future<void> _handleDisconnect(BuildContext context, WidgetRef ref) async {
    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(
        ko: '소셜 계정 연결 해제',
        en: 'Disconnect social account',
        ja: 'ソーシャルアカウントの連携解除',
      ),
      message: context.l10n(
        ko: '소셜 계정 연결을 해제하시겠습니까?',
        en: 'Are you sure you want to disconnect your social account?',
        ja: 'ソーシャルアカウントの連携を解除しますか？',
      ),
      confirmLabel: context.l10n(ko: '해제', en: 'Disconnect', ja: '解除'),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      isDestructive: true,
    );
    if (confirm != true || !context.mounted) return;

    final result = await ref
        .read(authControllerProvider.notifier)
        .disconnectOAuth();
    if (!context.mounted) return;

    if (result is Err<void>) {
      final failure = result.failure;
      final message = failure.code == 'CANNOT_DISCONNECT_OAUTH'
          ? context.l10n(
              ko: '비밀번호를 먼저 설정하신 후 소셜 계정 연결을 해제할 수 있어요',
              en: 'Please set a password first before disconnecting your social account',
              ja: 'ソーシャルアカウントの連携を解除するには、先にパスワードを設定してください',
            )
          : failure.userMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '소셜 계정 연결이 해제되었습니다',
            en: 'Social account disconnected',
            ja: 'ソーシャルアカウントの連携が解除されました',
          ),
        ),
      ),
    );
  }

  void _showResultSnackBar(
    BuildContext context,
    Result<void> result, {
    required String successMessage,
  }) {
    if (result is Success<void>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }
    if (result is Err<void>) {
      final failure = result.failure;
      final message = _buildConnectErrorMessage(context, failure);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _buildConnectErrorMessage(BuildContext context, Failure failure) {
    return switch (failure.code) {
      'OAUTH_ALREADY_LINKED' => context.l10n(
        ko: '이 소셜 계정은 이미 다른 계정에 연결되어 있습니다',
        en: 'This social account is already linked to another account',
        ja: 'このソーシャルアカウントは既に別のアカウントに連携されています',
      ),
      'ACCOUNT_ALREADY_HAS_OAUTH' => context.l10n(
        ko: '이 계정에는 이미 다른 소셜 계정이 연결되어 있습니다',
        en: 'This account already has another social account linked',
        ja: 'このアカウントには既に別のソーシャルアカウントが連携されています',
      ),
      'sign_in_cancelled' => context.l10n(
        ko: '로그인이 취소되었습니다',
        en: 'Sign-in was cancelled',
        ja: 'ログインがキャンセルされました',
      ),
      _ => failure.userMessage,
    };
  }
}

// ---------------------------------------------------------------------------
// EN: Row widget for a single social account action.
// KO: 단일 소셜 계정 액션을 위한 행 위젯.
// ---------------------------------------------------------------------------

class _SocialAccountRow extends StatelessWidget {
  const _SocialAccountRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.isLoading = false,
    this.useIconChip = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isLoading;

  /// EN: Whether to render the gradient icon chip. Disabled for rows that
  /// display an official brand mark, which must keep its own brand color
  /// rather than sit on a recolored gradient.
  /// KO: 그라디언트 아이콘 칩 렌더링 여부. 공식 브랜드 마크를 표시하는 행은
  /// 그라디언트로 재채색되지 않고 고유 브랜드 색상을 유지해야 하므로 비활성화.
  final bool useIconChip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: useIconChip
          ? GBTIconChip(icon: icon, color: iconColor, size: 40)
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
      title: Text(
        title,
        style: GBTTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
      onTap: isLoading ? null : onTap,
    );
  }
}
