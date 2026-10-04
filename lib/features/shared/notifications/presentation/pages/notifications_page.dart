/// EN: Notifications page — grouped list with swipe-delete, type icons, navigation.
/// KO: 알림 페이지 — 그룹 목록, 스와이프 삭제, 타입 아이콘, 네비게이션.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_icon_chip.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_empty_state.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart'
    hide GBTEmptyState;
import 'package:oshi_log/design_system/widgets/navigation/gbt_app_bar_icon_button.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/shared/notifications/application/notifications_controller.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_entities.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_navigation.dart';

final _notificationPermissionProvider = FutureProvider.autoDispose<bool?>((
  ref,
) {
  return ref.watch(localNotificationsServiceProvider).hasPermission();
});

/// EN: Notifications page widget.
/// KO: 알림 페이지 위젯.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with WidgetsBindingObserver {
  bool _showUnreadOnly = false;
  Timer? _foregroundRefreshTimer;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundRefreshTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) => _refreshNotificationsIfVisible(),
    );
  }

  @override
  void dispose() {
    _foregroundRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) {
      ref.invalidate(_notificationPermissionProvider);
      _refreshNotificationsIfVisible();
    }
  }

  Future<void> _openSettings() async {
    await context.push('/settings/notifications');
    if (mounted) ref.invalidate(_notificationPermissionProvider);
  }

  void _refreshNotificationsIfVisible() {
    if (!mounted || !_isAppResumed) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    ref.read(notificationsControllerProvider.notifier).refreshInBackground();
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n(ko: '전체 삭제', en: 'Delete all', ja: 'すべて削除')),
        content: Text(
          ctx.l10n(
            ko: '모든 알림을 삭제할까요? 되돌릴 수 없습니다.',
            en: 'Delete all notifications? This cannot be undone.',
            ja: '通知をすべて削除しますか？元に戻せません。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n(ko: '삭제', en: 'Delete', ja: '削除')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deleteNotification();
    }
  }

  Future<bool> _deleteNotification([String? id]) async {
    final controller = ref.read(notificationsControllerProvider.notifier);
    try {
      final result = id == null
          ? await controller.deleteAllNotifications()
          : await controller.deleteNotification(id);
      if (result is Success<void>) return true;
    } catch (_) {
      // EN: The unchanged inbox remains available for another attempt.
      // KO: 변경되지 않은 알림 목록에서 다시 시도할 수 있습니다.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '알림을 삭제하지 못했어요. 다시 시도해 주세요.',
              en: 'Could not delete notifications. Please try again.',
              ja: '通知を削除できませんでした。もう一度お試しください。',
            ),
          ),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final permission = ref.watch(_notificationPermissionProvider).valueOrNull;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '알림', en: 'Notifications', ja: '通知'),
        actions: [
          GBTAppBarIconButton(
            icon: Icons.done_all,
            tooltip: context.l10n(
              ko: '전체 읽음',
              en: 'Mark all read',
              ja: 'すべて既読',
            ),
            onPressed: () => ref
                .read(notificationsControllerProvider.notifier)
                .markAllAsRead(),
          ),
          GBTAppBarIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: context.l10n(ko: '전체 삭제', en: 'Delete all', ja: 'すべて削除'),
            onPressed: _confirmDeleteAll,
          ),
          GBTAppBarIconButton(
            icon: Icons.settings_outlined,
            tooltip: context.l10n(ko: '알림 설정', en: 'Settings', ja: '設定'),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationsControllerProvider.notifier)
            .load(forceRefresh: true),
        child: state.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: GBTSpacing.paddingPage,
            children: [
              if (permission == false) _permissionNotice(context),
              _FilterRow(
                showUnreadOnly: _showUnreadOnly,
                onFilterChanged: (v) => setState(() => _showUnreadOnly = v),
              ),
              const SizedBox(height: GBTSpacing.md),
              GBTLoading(
                message: context.l10n(
                  ko: '알림을 불러오는 중...',
                  en: 'Loading…',
                  ja: '読み込み中…',
                ),
              ),
            ],
          ),
          error: (error, _) {
            final message = context.l10n(
              ko: '알림을 불러오지 못했어요',
              en: 'Failed to load notifications',
              ja: '通知を読み込めませんでした',
            );
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: GBTSpacing.paddingPage,
              children: [
                if (permission == false) _permissionNotice(context),
                _FilterRow(
                  showUnreadOnly: _showUnreadOnly,
                  onFilterChanged: (v) => setState(() => _showUnreadOnly = v),
                ),
                const SizedBox(height: GBTSpacing.md),
                GBTErrorState(
                  message: message,
                  onRetry: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .load(forceRefresh: true),
                ),
              ],
            );
          },
          data: (items) {
            final visible = _showUnreadOnly
                ? items.where((e) => !e.isRead).toList()
                : items;

            if (visible.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: GBTSpacing.paddingPage,
                children: [
                  if (permission == false) _permissionNotice(context),
                  _FilterRow(
                    showUnreadOnly: _showUnreadOnly,
                    onFilterChanged: (v) => setState(() => _showUnreadOnly = v),
                  ),
                  const SizedBox(height: GBTSpacing.md),
                  GBTEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: _showUnreadOnly
                        ? context.l10n(
                            ko: '읽지 않은 알림이 없어요',
                            en: 'No unread notifications',
                            ja: '未読通知はありません',
                          )
                        : context.l10n(
                            ko: '아직 알림이 없어요',
                            en: 'No notifications yet',
                            ja: '通知はまだありません',
                          ),
                    subtitle: _showUnreadOnly
                        ? null
                        : context.l10n(
                            ko: '새 알림은 이 목록에서 확인할 수 있어요.',
                            en: 'New notifications will appear in this list.',
                            ja: '新しい通知はこの一覧で確認できます。',
                          ),
                    actionLabel: _showUnreadOnly
                        ? context.l10n(
                            ko: '전체 알림 보기',
                            en: 'Show all notifications',
                            ja: 'すべての通知を見る',
                          )
                        : context.l10n(
                            ko: '알림 설정',
                            en: 'Notification settings',
                            ja: '通知設定',
                          ),
                    onAction: _showUnreadOnly
                        ? () => setState(() => _showUnreadOnly = false)
                        : _openSettings,
                  ),
                ],
              );
            }

            final grouped = _groupBySection(visible);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
              children: [
                if (permission == false)
                  Padding(
                    padding: GBTSpacing.paddingPage,
                    child: _permissionNotice(context),
                  ),
                Padding(
                  padding: GBTSpacing.paddingPage,
                  child: _FilterRow(
                    showUnreadOnly: _showUnreadOnly,
                    onFilterChanged: (v) => setState(() => _showUnreadOnly = v),
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                for (final entry in grouped.entries) ...[
                  _SectionHeader(title: entry.key),
                  ...entry.value.map(
                    (item) => _NotificationRow(
                      key: ValueKey(item.id),
                      item: item,
                      onTap: () => _handleTap(item),
                      onDelete: () => _deleteNotification(item.id),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _permissionNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n(
              ko: '기기 알림이 꺼져 있어요',
              en: 'Device notifications are off',
              ja: '端末の通知がオフになっています',
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '앱 안에서는 알림을 계속 확인할 수 있어요. 기기 알림은 설정에서 허용해 주세요.',
              en: 'You can still read notifications here. Enable device notifications in settings.',
              ja: 'アプリ内では引き続き通知を確認できます。端末の通知は設定から許可してください。',
            ),
          ),
          TextButton(
            onPressed: _openSettings,
            child: Text(
              context.l10n(
                ko: '알림 설정 열기',
                en: 'Open notification settings',
                ja: '通知設定を開く',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EN: Mark read then navigate to the notification's target.
  //     Guard against pushing the current route again (e.g. SYSTEM_NOTICE
  //     resolves to /notifications while we are already on /notifications).
  // KO: 읽음 처리 후 알림 대상 경로로 이동합니다.
  //     현재 경로와 동일한 경로를 push하지 않도록 방어합니다
  //     (예: SYSTEM_NOTICE → /notifications 이미 알림 페이지인 경우).
  Future<void> _handleTap(NotificationItem item) async {
    final notifier = ref.read(notificationsControllerProvider.notifier);
    await notifier.markAsRead(item.id, refresh: false);
    if (!mounted) return;

    final type = normalizeNotificationType(item.type);
    final targetPath = resolveNotificationNavigationPath(
      type: type,
      deeplink: item.deeplink,
      actionUrl: item.actionUrl,
      entityId: item.entityId,
    );

    final destination = targetPath;
    if (destination != null && mounted) {
      final currentPath = GoRouter.of(
        context,
      ).routeInformationProvider.value.uri.path;
      // EN: Only navigate when destination differs from current page.
      // KO: 현재 페이지와 목적지가 다를 때만 이동합니다.
      if (destination != currentPath) {
        context.push(destination);
      }
    }

    unawaited(notifier.refreshInBackground(minInterval: Duration.zero));
  }
}

// ─────────────────────────────────────────────────────────────
// Filter row
// ─────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.showUnreadOnly,
    required this.onFilterChanged,
  });

  final bool showUnreadOnly;
  final ValueChanged<bool> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(context.l10n(ko: '전체', en: 'All', ja: '全体')),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(context.l10n(ko: '읽지 않음', en: 'Unread', ja: '未読')),
          ),
        ],
        selected: {showUnreadOnly},
        onSelectionChanged: (s) => onFilterChanged(s.first),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.lg,
        GBTSpacing.md,
        GBTSpacing.lg,
        GBTSpacing.xs,
      ),
      child: Text(
        title,
        style: GBTTypography.labelMedium.copyWith(
          color: isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification row — swipe-to-delete
// ─────────────────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(isDark: isDark),
      confirmDismiss: (_) => onDelete(),
      child: _NotificationTile(item: item, isDark: isDark, onTap: onTap),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: (isDark ? GBTColors.errorDark : GBTColors.error).withValues(
        alpha: 0.9,
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: GBTSpacing.lg),
          child: Icon(
            Icons.delete_outline,
            color: GBTColors.textInverse,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final NotificationItem item;
  final bool isDark;
  final VoidCallback onTap;

  // EN: Resolve icon for notification type.
  // KO: 알림 타입에 맞는 아이콘을 반환합니다.
  IconData _iconForType(String? type) {
    final t = normalizeNotificationType(type);
    return switch (t) {
      notificationTypePostCreated => Icons.article_outlined,
      'COMMENT_CREATED' || 'COMMENT_REPLY_CREATED' => Icons.chat_bubble_outline,
      'POST_LIKED' => Icons.favorite_border,
      notificationTypeTitleEarned => Icons.workspace_premium_outlined,
      'LIVE_EVENT_UPDATED' ||
      'LIVE_EVENT_CANCELLED' ||
      'LIVE_EVENT_ATTENDANCE_VERIFIED' => Icons.event_outlined,
      'MODERATION' => Icons.gavel_outlined,
      notificationTypeSystemNotice => Icons.campaign_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  // EN: Resolve accent color for notification type.
  // KO: 알림 타입에 맞는 강조 색상을 반환합니다.
  Color _colorForType(String? type) {
    final t = normalizeNotificationType(type);
    return switch (t) {
      notificationTypePostCreated =>
        isDark ? GBTColors.darkPrimary : GBTColors.primary,
      'COMMENT_CREATED' || 'COMMENT_REPLY_CREATED' =>
        isDark ? GBTColors.darkSecondary : GBTColors.secondary,
      'POST_LIKED' => isDark ? GBTColors.darkSecondary : GBTColors.secondary,
      notificationTypeTitleEarned =>
        isDark ? GBTColors.darkPrimary : GBTColors.primary,
      'LIVE_EVENT_UPDATED' ||
      'LIVE_EVENT_CANCELLED' ||
      'LIVE_EVENT_ATTENDANCE_VERIFIED' =>
        isDark ? GBTColors.darkPrimary : GBTColors.primary,
      'MODERATION' => isDark ? GBTColors.error : GBTColors.errorDark,
      _ => isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _colorForType(item.type);
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final bg = item.isRead
        ? Colors.transparent
        : (isDark
              ? GBTColors.darkPrimary.withValues(alpha: 0.06)
              : GBTColors.primary.withValues(alpha: 0.04));

    return Semantics(
      label:
          '${item.isRead ? context.l10n(ko: '읽음', en: 'Read', ja: '既読') : context.l10n(ko: '읽지 않음', en: 'Unread', ja: '未読')}: ${item.title}. ${item.body}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ColoredBox(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EN: Type icon — gradient chip.
                // KO: 타입 아이콘 — 그라디언트 칩입니다.
                GBTIconChip(
                  icon: _iconForType(item.type),
                  color: accentColor,
                  size: 40,
                ),
                const SizedBox(width: GBTSpacing.sm2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // EN: Title — bold when unread.
                      // KO: 제목 — 읽지 않음이면 굵게 표시합니다.
                      Text(
                        item.title,
                        style: GBTTypography.bodyMedium.copyWith(
                          fontWeight: item.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: GBTSpacing.xxs),
                        Text(
                          item.body,
                          style: GBTTypography.bodySmall.copyWith(
                            color: textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        _relativeTime(item.createdAt),
                        style: GBTTypography.labelSmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // EN: Unread indicator dot.
                // KO: 읽지 않음 표시 점입니다.
                if (!item.isRead)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: GBTSpacing.xs,
                      left: GBTSpacing.sm,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

Map<String, List<NotificationItem>> _groupBySection(
  List<NotificationItem> items,
) {
  final now = DateTime.now();
  final today = <NotificationItem>[];
  final week = <NotificationItem>[];
  final older = <NotificationItem>[];

  for (final item in items) {
    final diff = now.difference(item.createdAt.toLocal());
    if (diff.inDays == 0) {
      today.add(item);
    } else if (diff.inDays < 7) {
      week.add(item);
    } else {
      older.add(item);
    }
  }

  return {
    if (today.isNotEmpty) '오늘': today,
    if (week.isNotEmpty) '이번 주': week,
    if (older.isNotEmpty) '이전': older,
  };
}

/// EN: Human-readable relative timestamp.
/// KO: 사람이 읽기 좋은 상대적 시간 문자열을 반환합니다.
String _relativeTime(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt.toLocal());
  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays == 1) return '어제';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  final local = createdAt.toLocal();
  return '${local.month}/${local.day}';
}
