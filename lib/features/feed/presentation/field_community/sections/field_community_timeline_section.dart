/// EN: Live, paginated report timeline shared by feed and discover sections.
/// KO: 피드와 발견 섹션이 공유하는 실제 페이지네이션 리포트 타임라인.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../application/board_controller.dart';
import '../widgets/field_community_post_entry.dart';

/// EN: Renders only server-backed PostSummary rows and explicit UI states.
/// KO: 서버 기반 PostSummary 행과 명시적인 UI 상태만 렌더링합니다.
class FieldCommunityTimelineSection extends StatelessWidget {
  const FieldCommunityTimelineSection({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onApplyPending,
    required this.onCompose,
    required this.onPostTap,
  });

  final CommunityFeedViewState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final VoidCallback onApplyPending;
  final VoidCallback onCompose;
  final void Function(String postId, String projectId) onPostTap;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading && state.posts.isEmpty) {
      return const _TimelineLoading();
    }
    if (state.failure != null && state.posts.isEmpty) {
      return _TimelineMessage(
        icon: Icons.wifi_off_rounded,
        title: context.l10n(
          ko: '필드 리포트를 불러오지 못했어요',
          en: 'Could not load field reports',
          ja: 'フィールドレポートを読み込めませんでした',
        ),
        subtitle: context.l10n(
          ko: '연결을 확인한 뒤 다시 시도해주세요.',
          en: 'Check the connection and try again.',
          ja: '接続を確認して、もう一度お試しください。',
        ),
        actionLabel: context.l10n(ko: '다시 시도', en: 'Try again', ja: '再試行'),
        onAction: () => unawaited(onRefresh()),
      );
    }
    if (state.posts.isEmpty) {
      return _TimelineMessage(
        icon: Icons.edit_note_rounded,
        title: context.l10n(
          ko: '첫 필드 리포트를 기다리고 있어요',
          en: 'Waiting for the first field report',
          ja: '最初のフィールドレポートを待っています',
        ),
        subtitle: context.l10n(
          ko: '다녀온 곳의 동선과 알아두면 좋은 정보를 남겨보세요.',
          en: 'Share a route detail or lesson from a place you visited.',
          ja: '訪れた場所の動線や役立つメモを共有しましょう。',
        ),
        actionLabel: context.l10n(
          ko: '리포트 쓰기',
          en: 'Write a report',
          ja: 'レポートを書く',
        ),
        onAction: onCompose,
      );
    }

    return Column(
      children: [
        if (state.hasPendingNewPosts)
          _NewReportsStrip(
            count: state.pendingNewPosts.length,
            onTap: onApplyPending,
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 240 &&
                  state.hasMore &&
                  !state.isLoadingMore) {
                unawaited(onLoadMore());
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                key: const Key('field-community-timeline'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom:
                      GBTSpacing.bottomNavClearanceOf(
                        context,
                        barHeight: GBTSpacing.bottomNavHeight + GBTSpacing.sm,
                      ) +
                      96,
                ),
                itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (context, index) => const _ReportRule(),
                itemBuilder: (context, index) {
                  if (index == state.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(GBTSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final post = state.posts[index];
                  return FieldCommunityPostEntry(
                    post: post,
                    onTap: () => onPostTap(post.id, post.projectId),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportRule extends StatelessWidget {
  const _ReportRule();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? GBTColors.darkBorderSubtle : GBTColors.divider,
    );
  }
}

class _NewReportsStrip extends StatelessWidget {
  const _NewReportsStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? GBTColors.darkSecondary : GBTColors.secondary;
    final label = context.l10n(
      ko: '새 리포트 $count개 보기',
      en: 'Read $count new reports',
      ja: '新しいレポート $count件を見る',
    );

    return Material(
      color: color.withValues(alpha: isDark ? 0.14 : 0.10),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward_rounded, size: 18, color: color),
              const SizedBox(width: GBTSpacing.xs),
              Text(
                label,
                style: GBTTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: GBTSpacing.bottomNavClearanceOf(
          context,
          barHeight: GBTSpacing.bottomNavHeight + GBTSpacing.sm,
        ),
      ),
      children: [
        GBTEmptyState(
          icon: icon,
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ],
    );
  }
}

class _TimelineLoading extends StatelessWidget {
  const _TimelineLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const _ReportRule(),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Container(width: 104, height: 12, color: fill),
              ],
            ),
            const SizedBox(height: GBTSpacing.md),
            FractionallySizedBox(
              widthFactor: 0.82,
              child: Container(height: 18, color: fill),
            ),
            const SizedBox(height: GBTSpacing.sm),
            FractionallySizedBox(
              widthFactor: 0.58,
              child: Container(height: 12, color: fill),
            ),
          ],
        ),
      ),
    );
  }
}
