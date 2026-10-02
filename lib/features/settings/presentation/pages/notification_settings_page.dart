/// EN: Notification settings page with card-grouped toggle rows.
/// KO: 카드 그룹 토글 행이 있는 알림 설정 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../auth/application/session_state.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/settings_controller.dart';
import '../../domain/entities/notification_settings.dart';
import '../widgets/field_settings_components.dart';

/// EN: Notification settings page widget.
/// KO: 알림 설정 페이지 위젯.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '알림 설정', en: 'Notifications', ja: '通知設定'),
        ),
        body: _LoginRequired(onLogin: () => context.push('/login')),
      );
    }

    final state = ref.watch(notificationSettingsControllerProvider);

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '알림 설정', en: 'Notifications', ja: '通知設定'),
      ),
      body: state.when(
        loading: () => GBTLoading(
          message: context.l10n(
            ko: '알림 설정을 불러오는 중...',
            en: 'Loading notification settings...',
            ja: '通知設定を読み込んでいます...',
          ),
        ),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '알림 설정을 불러오지 못했어요',
                  en: 'Failed to load notification settings.',
                  ja: '通知設定を読み込めませんでした。',
                );
          return GBTErrorState(
            message: message,
            onRetry: () => ref
                .read(notificationSettingsControllerProvider.notifier)
                .load(forceRefresh: true),
          );
        },
        data: (settings) => _NotificationSettingsView(
          settings: settings,
          onChanged: (updated) async {
            final result = await ref
                .read(notificationSettingsControllerProvider.notifier)
                .updateSettings(updated);
            if (result is Err<NotificationSettings>) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n(
                        ko: '설정을 저장하지 못했어요',
                        en: 'Failed to save settings.',
                        ja: '設定を保存できませんでした。',
                      ),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView({
    required this.settings,
    required this.onChanged,
  });

  final NotificationSettings settings;
  final ValueChanged<NotificationSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.md,
      ),
      children: [
        // EN: Summary badge showing how many notifications are active
        // KO: 활성화된 알림 수를 보여주는 요약 배지
        _SummaryHeader(settings: settings, isDark: isDark),
        const SizedBox(height: GBTSpacing.lg),

        // EN: Channel group — push/email
        // KO: 채널 그룹 — 푸시/이메일
        _NotifGroupCard(
          title: context.l10n(ko: '수신 채널', en: 'Channels', ja: '受信チャネル'),
          isDark: isDark,
          children: [
            _NotifToggleRow(
              icon: Icons.notifications_active_rounded,
              iconColor: GBTColors.warning,
              title: context.l10n(
                ko: '푸시 알림',
                en: 'Push notifications',
                ja: 'プッシュ通知',
              ),
              subtitle: context.l10n(
                ko: '앱 푸시 알림 수신',
                en: 'Receive app push notifications',
                ja: 'アプリのプッシュ通知を受け取ります',
              ),
              value: settings.pushEnabled,
              semanticLabel: context.l10n(
                ko: '푸시 알림 ${settings.pushEnabled ? "켜짐" : "꺼짐"}',
                en: 'Push notifications ${settings.pushEnabled ? "on" : "off"}',
                ja: 'プッシュ通知${settings.pushEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) => onChanged(settings.copyWith(pushEnabled: v)),
              isDark: isDark,
            ),
            _NotifToggleRow(
              icon: Icons.email_rounded,
              iconColor: GBTColors.accentBlue,
              title: context.l10n(
                ko: '이메일 알림',
                en: 'Email notifications',
                ja: 'メール通知',
              ),
              subtitle: context.l10n(
                ko: '이메일로 알림 수신',
                en: 'Receive notifications by email',
                ja: 'メールで通知を受け取ります',
              ),
              value: settings.emailEnabled,
              semanticLabel: context.l10n(
                ko: '이메일 알림 ${settings.emailEnabled ? "켜짐" : "꺼짐"}',
                en: 'Email notifications ${settings.emailEnabled ? "on" : "off"}',
                ja: 'メール通知${settings.emailEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) => onChanged(settings.copyWith(emailEnabled: v)),
              isDark: isDark,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.lg),

        // EN: Content group — live/favorites/comments/following posts
        // KO: 콘텐츠 그룹 — 라이브/즐겨찾기/댓글/팔로잉 글
        _NotifGroupCard(
          title: context.l10n(
            ko: '콘텐츠 알림',
            en: 'Content notifications',
            ja: 'コンテンツ通知',
          ),
          isDark: isDark,
          children: [
            _NotifToggleRow(
              icon: Icons.event_rounded,
              iconColor: GBTColors.secondary,
              title: context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
              subtitle: context.l10n(
                ko: '다가오는 공연 소식',
                en: 'Upcoming event updates',
                ja: '開催予定のイベント情報',
              ),
              value: settings.liveEventsEnabled,
              semanticLabel: context.l10n(
                ko: '이벤트 알림 ${settings.liveEventsEnabled ? "켜짐" : "꺼짐"}',
                en: 'Event notifications ${settings.liveEventsEnabled ? "on" : "off"}',
                ja: 'イベント通知${settings.liveEventsEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) =>
                  onChanged(settings.copyWith(liveEventsEnabled: v)),
              isDark: isDark,
              enabled: settings.pushEnabled,
            ),
            _NotifToggleRow(
              icon: Icons.favorite_rounded,
              iconColor: GBTColors.favorite,
              title: context.l10n(ko: '즐겨찾기', en: 'Favorites', ja: 'お気に入り'),
              subtitle: context.l10n(
                ko: '즐겨찾기한 장소/콘텐츠 소식',
                en: 'Updates on favorited places and content',
                ja: 'お気に入りの場所・コンテンツ情報',
              ),
              value: settings.favoritesEnabled,
              semanticLabel: context.l10n(
                ko: '즐겨찾기 알림 ${settings.favoritesEnabled ? "켜짐" : "꺼짐"}',
                en: 'Favorites notifications ${settings.favoritesEnabled ? "on" : "off"}',
                ja: 'お気に入り通知${settings.favoritesEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) =>
                  onChanged(settings.copyWith(favoritesEnabled: v)),
              isDark: isDark,
              enabled: settings.pushEnabled,
            ),
            _NotifToggleRow(
              icon: Icons.chat_bubble_rounded,
              iconColor: GBTColors.accent,
              title: context.l10n(ko: '댓글', en: 'Comments', ja: 'コメント'),
              subtitle: context.l10n(
                ko: '댓글/후기 알림',
                en: 'Comment and review notifications',
                ja: 'コメント・レビュー通知',
              ),
              value: settings.commentsEnabled,
              semanticLabel: context.l10n(
                ko: '댓글 알림 ${settings.commentsEnabled ? "켜짐" : "꺼짐"}',
                en: 'Comment notifications ${settings.commentsEnabled ? "on" : "off"}',
                ja: 'コメント通知${settings.commentsEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) =>
                  onChanged(settings.copyWith(commentsEnabled: v)),
              isDark: isDark,
              enabled: settings.pushEnabled,
            ),
            _NotifToggleRow(
              icon: Icons.people_alt_rounded,
              iconColor: GBTColors.success,
              title: context.l10n(
                ko: '팔로잉 글',
                en: 'Following posts',
                ja: 'フォロー中の投稿',
              ),
              subtitle: context.l10n(
                ko: '팔로우한 사용자의 새 글 알림',
                en: 'New posts from users you follow',
                ja: 'フォロー中のユーザーの新しい投稿通知',
              ),
              value: settings.followingPostsEnabled,
              semanticLabel: context.l10n(
                ko: '팔로잉 글 알림 ${settings.followingPostsEnabled ? "켜짐" : "꺼짐"}',
                en: 'Following posts notifications ${settings.followingPostsEnabled ? "on" : "off"}',
                ja: 'フォロー中の投稿通知${settings.followingPostsEnabled ? "オン" : "オフ"}',
              ),
              onChanged: (v) =>
                  onChanged(settings.copyWith(followingPostsEnabled: v)),
              isDark: isDark,
              isLast: true,
              enabled: settings.pushEnabled,
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xl),
      ],
    );
  }
}

// ========================================
// EN: Summary header with active count badge
// KO: 활성 수 배지가 있는 요약 헤더
// ========================================

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.settings, required bool isDark});

  final NotificationSettings settings;

  @override
  Widget build(BuildContext context) {
    final contentEnabledCount = settings.pushEnabled
        ? [
            settings.liveEventsEnabled,
            settings.favoritesEnabled,
            settings.commentsEnabled,
            settings.followingPostsEnabled,
          ].where((value) => value).length
        : 0;
    final enabledCount =
        [
          settings.pushEnabled,
          settings.emailEnabled,
        ].where((value) => value).length +
        contentEnabledCount;

    return FieldSettingsIntro(
      eyebrow: 'NOTIFICATION ROUTING',
      title: context.l10n(
        ko: '활성화된 알림 $enabledCount개',
        en: '$enabledCount notifications enabled',
        ja: '有効な通知$enabledCount件',
      ),
      description: context.l10n(
        ko: '원하는 채널과 콘텐츠 알림만 선택하세요.',
        en: 'Choose only the channels and content you want notifications for.',
        ja: '必要なチャネルとコンテンツ通知だけを選択してください。',
      ),
      icon: Icons.notifications_outlined,
    );
  }
}

// ========================================
// EN: Notification group card — section container
// KO: 알림 그룹 카드 — 섹션 컨테이너
// ========================================

class _NotifGroupCard extends StatelessWidget {
  const _NotifGroupCard({
    required this.title,
    required this.children,
    required bool isDark,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FieldSettingsSection(title: title, children: children);
  }
}

// ========================================
// EN: Notification toggle row with icon
// KO: 아이콘이 있는 알림 토글 행
// ========================================

class _NotifToggleRow extends StatelessWidget {
  const _NotifToggleRow({
    required this.icon,
    required Color iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
    this.semanticLabel,
    bool isLast = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final String? semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final textDisabled = isDark
        ? GBTColors.darkTextTertiary.withValues(alpha: 0.55)
        : GBTColors.textTertiary.withValues(alpha: 0.55);
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final effectiveTextPrimary = enabled ? textPrimary : textDisabled;
    final effectiveTextTertiary = enabled ? textTertiary : textDisabled;

    return Semantics(
      toggled: value,
      label: semanticLabel ?? '$title - $subtitle',
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: SizedBox(
                    width: GBTSpacing.xl,
                    child: Icon(icon, size: 22, color: primaryColor),
                  ),
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: effectiveTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GBTTypography.bodySmall.copyWith(
                          color: effectiveTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeThumbColor: primaryColor,
                  activeTrackColor: primaryColor.withValues(alpha: 0.4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Center(
      child: Padding(
        padding: GBTSpacing.paddingPage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: GBTSpacing.touchTarget,
              color: textTertiary,
              semanticLabel: context.l10n(
                ko: '잠금 아이콘',
                en: 'Lock icon',
                ja: 'ロックアイコン',
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              context.l10n(
                ko: '로그인이 필요합니다',
                en: 'Sign-in required',
                ja: 'ログインが必要です',
              ),
              style: GBTTypography.titleSmall.copyWith(color: textPrimary),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '알림 설정을 변경하려면 로그인해주세요.',
                en: 'Please sign in to change notification settings.',
                ja: '通知設定を変更するにはログインしてください。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GBTSpacing.lg),
            Semantics(
              button: true,
              label: context.l10n(
                ko: '로그인 페이지로 이동',
                en: 'Go to sign-in page',
                ja: 'ログインページへ移動',
              ),
              child: FilledButton(
                onPressed: onLogin,
                child: Text(
                  context.l10n(ko: '로그인', en: 'Sign in', ja: 'ログインする'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
