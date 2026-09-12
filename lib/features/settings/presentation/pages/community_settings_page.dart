/// EN: Community-focused settings page with profile-first actions.
/// KO: 프로필 중심 액션을 제공하는 커뮤니티 전용 설정 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/sensitive_text_utils.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../widgets/field_settings_components.dart';

/// EN: Community settings page.
/// KO: 커뮤니티 설정 페이지.
class CommunitySettingsPage extends ConsumerWidget {
  const CommunitySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileState = isAuthenticated
        ? ref.watch(userProfileControllerProvider)
        : null;
    final profile = profileState?.valueOrNull;
    final currentUserId = profile?.id;
    final canAccessAdminOps = profile?.canAccessAdminOps ?? false;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        leading: GBTAppBarIconButton(
          icon: Icons.arrow_back,
          tooltip: context.l10n(ko: '뒤로 가기', en: 'Back', ja: '戻る'),
          onPressed: () => context.go('/community'),
        ),
        title: context.l10n(
          ko: '커뮤니티 설정',
          en: 'Community Settings',
          ja: 'コミュニティ設定',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!isAuthenticated) return;
          await ref
              .read(userProfileControllerProvider.notifier)
              .load(forceRefresh: true);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: GBTSpacing.sm,
          ),
          children: [
            _CommunityProfileCard(
              isAuthenticated: isAuthenticated,
              profileState: profileState,
              onLoginTap: () => context.push('/login'),
              onMyProfileTap: currentUserId == null
                  ? null
                  : () => context.goToUserProfile(currentUserId),
              onEditProfileTap: () => context.push('/settings/profile'),
            ),
            const SizedBox(height: GBTSpacing.lg),
            _CommunitySettingsGroup(
              title: context.l10n(ko: '프로필', en: 'Profile', ja: 'プロフィール'),
              children: [
                _CommunitySettingsRow(
                  icon: Icons.person_rounded,
                  iconBgColor: GBTColors.accentBlue,
                  title: context.l10n(
                    ko: '내 프로필',
                    en: 'My profile',
                    ja: 'マイプロフィール',
                  ),
                  subtitle: context.l10n(
                    ko: '작성한 글/댓글 활동 보기',
                    en: 'View my posts and comments',
                    ja: '自分の投稿・コメントを見る',
                  ),
                  enabled: isAuthenticated && currentUserId != null,
                  onTap: currentUserId == null
                      ? null
                      : () => context.goToUserProfile(currentUserId),
                ),
                _CommunitySettingsRow(
                  icon: Icons.group_rounded,
                  iconBgColor: GBTColors.secondary,
                  title: context.l10n(ko: '팔로워', en: 'Followers', ja: 'フォロワー'),
                  subtitle: context.l10n(
                    ko: '나를 팔로우한 사용자',
                    en: 'People following me',
                    ja: '自分をフォローしているユーザー',
                  ),
                  enabled: isAuthenticated && currentUserId != null,
                  onTap: currentUserId == null
                      ? null
                      : () => context.pushNamed(
                          AppRoutes.userFollowers,
                          pathParameters: {'userId': currentUserId},
                        ),
                ),
                _CommunitySettingsRow(
                  icon: Icons.person_add_alt_1_rounded,
                  iconBgColor: GBTColors.accentTeal,
                  title: context.l10n(ko: '팔로잉', en: 'Following', ja: 'フォロー中'),
                  subtitle: context.l10n(
                    ko: '내가 팔로우한 사용자',
                    en: 'People I follow',
                    ja: '自分がフォローしているユーザー',
                  ),
                  enabled: isAuthenticated && currentUserId != null,
                  onTap: currentUserId == null
                      ? null
                      : () => context.pushNamed(
                          AppRoutes.userFollowing,
                          pathParameters: {'userId': currentUserId},
                        ),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.lg),
            _CommunitySettingsGroup(
              title: context.l10n(ko: '커뮤니티', en: 'Community', ja: 'コミュニティ'),
              children: [
                _CommunitySettingsRow(
                  icon: Icons.notifications_active_rounded,
                  iconBgColor: GBTColors.warning,
                  title: context.l10n(
                    ko: '알림함',
                    en: 'Notifications inbox',
                    ja: '通知受信箱',
                  ),
                  subtitle: context.l10n(
                    ko: '댓글/좋아요/팔로우 알림 확인',
                    en: 'Check comments/likes/follow alerts',
                    ja: 'コメント・いいね・フォロー通知を確認',
                  ),
                  enabled: isAuthenticated,
                  onTap: isAuthenticated
                      ? () => context.push('/notifications')
                      : null,
                ),
                _CommunitySettingsRow(
                  icon: Icons.bookmark_rounded,
                  iconBgColor: GBTColors.favorite,
                  title: context.l10n(
                    ko: '북마크한 글',
                    en: 'Bookmarked posts',
                    ja: 'ブックマークした投稿',
                  ),
                  subtitle: context.l10n(
                    ko: '북마크한 커뮤니티 글 모아보기',
                    en: 'View bookmarked community posts',
                    ja: 'ブックマークした投稿を見る',
                  ),
                  enabled: isAuthenticated,
                  onTap: isAuthenticated
                      ? () => context.push('/post-bookmarks')
                      : null,
                ),
                _CommunitySettingsRow(
                  icon: Icons.edit_note_rounded,
                  iconBgColor: GBTColors.infoDark,
                  title: context.l10n(
                    ko: '게시글 작성',
                    en: 'Write a post',
                    ja: '投稿作成',
                  ),
                  subtitle: context.l10n(
                    ko: '커뮤니티 새 글 작성하기',
                    en: 'Create a new community post',
                    ja: 'コミュニティに新規投稿',
                  ),
                  enabled: isAuthenticated,
                  onTap: isAuthenticated ? context.goToPostCreate : null,
                ),
                _CommunitySettingsRow(
                  icon: Icons.tune_rounded,
                  iconBgColor: GBTColors.secondary,
                  title: context.l10n(
                    ko: '알림 설정',
                    en: 'Notification settings',
                    ja: '通知設定',
                  ),
                  subtitle: context.l10n(
                    ko: '푸시/이메일 알림 관리',
                    en: 'Manage push/email preferences',
                    ja: 'プッシュ・メール通知管理',
                  ),
                  enabled: isAuthenticated,
                  onTap: isAuthenticated
                      ? () => context.push('/settings/notifications')
                      : null,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.lg),
            _CommunitySettingsGroup(
              title: context.l10n(
                ko: '계정 및 운영',
                en: 'Account & Operations',
                ja: 'アカウントと運営',
              ),
              children: [
                _CommunitySettingsRow(
                  icon: Icons.build_circle_rounded,
                  iconBgColor: GBTColors.secondary,
                  title: context.l10n(
                    ko: '계정 도구',
                    en: 'Account tools',
                    ja: 'アカウントツール',
                  ),
                  subtitle: context.l10n(
                    ko: '차단/접근레벨/이의제기 관리',
                    en: 'Manage blocks/access/appeals',
                    ja: 'ブロック・アクセスレベル・異議申立て管理',
                  ),
                  enabled: isAuthenticated,
                  onTap: isAuthenticated
                      ? () => context.push('/settings/account-tools')
                      : null,
                ),
                if (canAccessAdminOps)
                  _CommunitySettingsRow(
                    icon: Icons.admin_panel_settings_rounded,
                    iconBgColor: GBTColors.infoDark,
                    title: context.l10n(
                      ko: '운영 센터',
                      en: 'Operations center',
                      ja: '運営センター',
                    ),
                    subtitle: context.l10n(
                      ko: '신고/운영 지표 관리',
                      en: 'Manage reports/ops metrics',
                      ja: '通報・運営指標管理',
                    ),
                    onTap: () => context.push('/settings/admin'),
                    isLast: true,
                  )
                else
                  _CommunitySettingsRow(
                    icon: Icons.settings_rounded,
                    iconBgColor: GBTColors.textSecondary,
                    title: context.l10n(
                      ko: '전체 설정',
                      en: 'All settings',
                      ja: '全体設定',
                    ),
                    subtitle: context.l10n(
                      ko: '앱 환경/개인정보/지원 메뉴로 이동',
                      en: 'Open full app settings page',
                      ja: 'アプリ全体設定へ移動',
                    ),
                    onTap: () => context.push('/settings'),
                    isLast: true,
                  ),
              ],
            ),
            const SizedBox(height: GBTSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _CommunityProfileCard extends StatelessWidget {
  const _CommunityProfileCard({
    required this.isAuthenticated,
    required this.profileState,
    required this.onLoginTap,
    required this.onMyProfileTap,
    required this.onEditProfileTap,
  });

  final bool isAuthenticated;
  final AsyncValue<UserProfile?>? profileState;
  final VoidCallback onLoginTap;
  final VoidCallback? onMyProfileTap;
  final VoidCallback onEditProfileTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;

    if (!isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(GBTSpacing.lg),
        color: surfaceColor,
        child: Column(
          children: [
            Text(
              context.l10n(
                ko: '로그인하면 커뮤니티 기능을 사용할 수 있습니다',
                en: 'Log in to use community features',
                ja: 'ログインするとコミュニティ機能を利用できます',
              ),
              style: GBTTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GBTSpacing.md),
            FilledButton(
              onPressed: onLoginTap,
              child: Text(context.l10n(ko: '로그인', en: 'Log in', ja: 'ログイン')),
            ),
          ],
        ),
      );
    }

    return profileState!.when(
      loading: () => Container(
        height: 132,
        color: surfaceColor,
        child: const Center(child: GBTLoading(size: 20)),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(GBTSpacing.lg),
        color: surfaceColor,
        child: Text(
          context.l10n(
            ko: '프로필 정보를 불러오지 못했습니다',
            en: 'Failed to load profile',
            ja: 'プロフィールを読み込めませんでした',
          ),
          style: GBTTypography.bodyMedium,
        ),
      ),
      data: (profile) {
        final displayName = (profile?.displayName ?? '').trim();
        final email = (profile?.email ?? '').trim();
        final safeName = displayName.isEmpty
            ? context.l10n(ko: '사용자', en: 'User', ja: 'ユーザー')
            : displayName;
        final textScale = MediaQuery.textScalerOf(context).scale(1);

        return Container(
          padding: const EdgeInsets.all(GBTSpacing.lg),
          color: surfaceColor,
          child: Column(
            children: [
              Row(
                children: [
                  _CommunityProfileAvatar(avatarUrl: profile?.avatarUrl),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GBTTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: GBTSpacing.xxs),
                            child: Text(
                              maskEmail(email),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GBTTypography.bodySmall.copyWith(
                                color: isDark
                                    ? GBTColors.darkTextSecondary
                                    : GBTColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final myProfileButton = _CommunityActionButtonFrame(
                    child: FilledButton(
                      onPressed: onMyProfileTap,
                      child: Text(
                        context.l10n(
                          ko: '내 프로필',
                          en: 'My profile',
                          ja: 'マイプロフィール',
                        ),
                      ),
                    ),
                  );
                  final editProfileButton = _CommunityActionButtonFrame(
                    child: OutlinedButton(
                      onPressed: onEditProfileTap,
                      child: Text(
                        context.l10n(
                          ko: '프로필 수정',
                          en: 'Edit profile',
                          ja: 'プロフィール編集',
                        ),
                      ),
                    ),
                  );
                  if (constraints.maxWidth < 360 || textScale > 1.3) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        myProfileButton,
                        const SizedBox(height: GBTSpacing.sm),
                        editProfileButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: myProfileButton),
                      const SizedBox(width: GBTSpacing.sm),
                      Expanded(child: editProfileButton),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityActionButtonFrame extends StatelessWidget {
  const _CommunityActionButtonFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      child: child,
    );
  }
}

class _CommunityProfileAvatar extends StatelessWidget {
  const _CommunityProfileAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: isDark
            ? GBTColors.darkSurfaceVariant
            : GBTColors.surfaceVariant,
        child: Icon(
          Icons.person,
          size: 28,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        ),
      );
    }

    return ClipOval(
      child: GBTImage(
        imageUrl: avatarUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '프로필 이미지',
          en: 'Profile image',
          ja: 'プロフィール画像',
        ),
      ),
    );
  }
}

class _CommunitySettingsGroup extends StatelessWidget {
  const _CommunitySettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FieldSettingsSection(title: title, children: children);
  }
}

class _CommunitySettingsRow extends StatelessWidget {
  const _CommunitySettingsRow({
    required this.icon,
    required Color iconBgColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    bool isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: FieldSettingsRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
