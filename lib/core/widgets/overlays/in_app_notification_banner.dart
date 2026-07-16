/// EN: In-app notification banner overlay widget with slide-in animation.
/// KO: 슬라이드 인 애니메이션이 포함된 인앱 알림 배너 오버레이 위젯입니다.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/in_app_notification_queue.dart';
import '../../../core/theme/gbt_colors.dart';
import '../../../core/theme/gbt_spacing.dart';
import '../../../core/theme/gbt_typography.dart';
import '../../../features/notifications/domain/entities/notification_navigation.dart';

/// EN: Full-screen overlay that renders in-app notification banners above
/// all other content, consuming entries from [inAppNotificationQueueProvider].
/// KO: [inAppNotificationQueueProvider]에서 항목을 소비해 다른 모든 콘텐츠
/// 위에 인앱 알림 배너를 렌더링하는 전체 화면 오버레이입니다.
class InAppNotificationBannerOverlay extends ConsumerStatefulWidget {
  const InAppNotificationBannerOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppNotificationBannerOverlay> createState() =>
      _InAppNotificationBannerOverlayState();
}

class _InAppNotificationBannerOverlayState
    extends ConsumerState<InAppNotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  // EN: Animation controller for slide-in/slide-out banner transitions.
  // KO: 배너 슬라이드 인/아웃 전환을 위한 애니메이션 컨트롤러입니다.
  late final AnimationController _animController;

  // EN: Slide animation from off-screen top to visible position.
  // KO: 화면 위에서 보이는 위치로 슬라이드하는 애니메이션입니다.
  late final Animation<Offset> _slideAnim;

  // EN: Auto-dismiss timer fired after the display duration elapses.
  // KO: 표시 시간이 경과한 후 실행되는 자동 해제 타이머입니다.
  Timer? _autoDismissTimer;

  // EN: The entry currently being displayed in the banner.
  // KO: 배너에 현재 표시 중인 항목입니다.
  InAppNotificationEntry? _current;

  // EN: Guards against re-entrant dismiss calls during reverse animation.
  // KO: 역방향 애니메이션 중 재진입 해제 호출을 방지하는 플래그입니다.
  bool _isDismissing = false;

  static const Duration _animDuration = Duration(milliseconds: 280);
  static const Duration _displayDuration = Duration(milliseconds: 3500);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: _animDuration);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // EN: Begin displaying the given entry — forward animation + start timer.
  // KO: 주어진 항목 표시를 시작합니다 — 순방향 애니메이션 + 타이머 시작.
  void _showEntry(InAppNotificationEntry entry) {
    if (!mounted) return;
    setState(() => _current = entry);
    _animController.forward(from: 0);
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(_displayDuration, _dismiss);
  }

  // EN: Dismiss the current banner with reverse animation, then dequeue.
  // KO: 역방향 애니메이션으로 현재 배너를 닫고 큐에서 제거합니다.
  void _dismiss() {
    if (_isDismissing || !mounted) return;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _isDismissing = true;
    _animController.reverse().then((_) {
      if (!mounted) return;
      ref.read(inAppNotificationQueueProvider.notifier).dismissCurrent();
      setState(() {
        _current = null;
        _isDismissing = false;
      });
      // EN: Show next queued entry immediately if one is waiting.
      // KO: 대기 중인 다음 항목이 있으면 즉시 표시합니다.
      final queue = ref.read(inAppNotificationQueueProvider);
      if (queue.isNotEmpty) {
        _showEntry(queue.first);
      }
    });
  }

  // EN: Handle swipe-up gesture to dismiss the banner early.
  // KO: 위로 스와이프 제스처를 처리해 배너를 조기 해제합니다.
  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
      _dismiss();
    }
  }

  // EN: Tap handler that navigates to the resolved destination path.
  // KO: 해석된 목적 경로로 이동하는 탭 핸들러입니다.
  void _onTap(InAppNotificationEntry entry) {
    _dismiss();
    final path = resolveNotificationNavigationPath(
      type: entry.type,
      deeplink: entry.deeplink,
      actionUrl: entry.actionUrl,
      entityId: entry.entityId,
    );
    if (path != null && path.isNotEmpty && mounted) {
      context.push(path);
    }
  }

  // EN: Resolve the icon for the given notification type.
  // KO: 주어진 알림 타입에 맞는 아이콘을 반환합니다.
  IconData _iconForType(String? type) {
    return switch (type) {
      'POST_CREATED' => Icons.article_outlined,
      'COMMENT_CREATED' || 'COMMENT_REPLY_CREATED' => Icons.chat_bubble_outline,
      _ => Icons.notifications_outlined,
    };
  }

  // EN: Resolve the accent color for the given notification type.
  // KO: 주어진 알림 타입에 맞는 강조 색상을 반환합니다.
  Color _colorForType(String? type) {
    return switch (type) {
      'POST_CREATED' => GBTColors.primary,
      'COMMENT_CREATED' || 'COMMENT_REPLY_CREATED' => GBTColors.secondary,
      _ => GBTColors.textSecondary,
    };
  }

  Widget _buildBanner(
    BuildContext context,
    InAppNotificationEntry entry,
    bool isDark,
  ) {
    final typeColor = _colorForType(entry.type);
    final typeIcon = _iconForType(entry.type);
    final surfaceColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final textSecondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          top: GBTSpacing.sm,
          left: GBTSpacing.md,
          right: GBTSpacing.md,
        ),
        child: GestureDetector(
          onVerticalDragEnd: _onVerticalDragEnd,
          onTap: () => _onTap(entry),
          child: Material(
            elevation: GBTSpacing.elevationMd,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
            color: surfaceColor,
            child: Padding(
              padding: const EdgeInsets.all(GBTSpacing.sm2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // EN: Tinted icon container for notification type indicator.
                  // KO: 알림 타입 표시를 위한 틴트 아이콘 컨테이너입니다.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: GBTSpacing.iconSm,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm2),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: GBTTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: GBTSpacing.xxs),
                        Text(
                          entry.body,
                          style: GBTTypography.bodySmall.copyWith(
                            color: textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // EN: Manual dismiss button with accessible touch target.
                  // KO: 접근 가능한 터치 타겟을 갖춘 수동 해제 버튼입니다.
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    onPressed: _dismiss,
                    splashRadius: GBTSpacing.lg,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: GBTSpacing.minTouchTarget,
                      minHeight: GBTSpacing.minTouchTarget,
                    ),
                    color: textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // EN: Watch queue — when new item arrives, show banner if idle.
    // KO: 큐를 감시합니다 — 새 항목이 오면 유휴 상태일 때 배너를 표시합니다.
    ref.listen<List<InAppNotificationEntry>>(inAppNotificationQueueProvider, (
      _,
      next,
    ) {
      if (next.isNotEmpty && _current == null && !_isDismissing) {
        _showEntry(next.first);
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildBanner(context, _current!, isDark),
            ),
          ),
      ],
    );
  }
}
