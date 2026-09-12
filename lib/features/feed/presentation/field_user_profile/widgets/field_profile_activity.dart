/// EN: Posts and comments ledger for a public user profile.
/// KO: 공개 사용자 프로필의 게시글·댓글 원장입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../domain/entities/feed_entities.dart';

typedef FieldOpenPost = void Function(String postId, String projectCode);

class FieldProfileActivity extends StatelessWidget {
  const FieldProfileActivity({
    super.key,
    required this.posts,
    required this.comments,
    required this.onRefresh,
    required this.onOpenPost,
    this.isLoading = false,
    this.errorMessage,
    this.blockedMessage,
    this.onRetry,
    this.includeVisitLedger = false,
    this.visitCountLabel,
    this.onOpenVisitHistory,
    this.onRefreshVisits,
    this.showTabBar = true,
  });

  final List<PostSummary> posts;
  final List<PostComment> comments;
  final Future<void> Function() onRefresh;
  final FieldOpenPost onOpenPost;
  final bool isLoading;
  final String? errorMessage;
  final String? blockedMessage;
  final VoidCallback? onRetry;
  final bool includeVisitLedger;
  final String? visitCountLabel;
  final VoidCallback? onOpenVisitHistory;
  final Future<void> Function()? onRefreshVisits;
  final bool showTabBar;

  @override
  Widget build(BuildContext context) {
    final tabView = TabBarView(children: _tabChildren(context));
    if (!showTabBar) return tabView;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          FieldProfileActivityTabBar(includeVisitLedger: includeVisitLedger),
          Expanded(child: tabView),
        ],
      ),
    );
  }

  List<Widget> _tabChildren(BuildContext context) {
    if (blockedMessage != null) {
      final tabCount = includeVisitLedger ? 3 : 2;
      return List<Widget>.generate(
        tabCount,
        (_) => _ActivityStatus(
          message: blockedMessage!,
          icon: Icons.block_rounded,
        ),
      );
    }
    if (isLoading) {
      final message = context.l10n(
        ko: '활동을 불러오는 중...',
        en: 'Loading activity...',
        ja: 'アクティビティを読み込み中...',
      );
      return [
        _ActivityLoading(message: message),
        _ActivityLoading(message: message),
        if (includeVisitLedger) _buildVisitLedger(),
      ];
    }
    if (errorMessage != null) {
      return [
        _ActivityError(message: errorMessage!, onRetry: onRetry),
        _ActivityError(message: errorMessage!, onRetry: onRetry),
        if (includeVisitLedger) _buildVisitLedger(),
      ];
    }
    return [
      _PostLedger(posts: posts, onRefresh: onRefresh, onOpenPost: onOpenPost),
      _CommentLedger(
        comments: comments,
        onRefresh: onRefresh,
        onOpenPost: onOpenPost,
      ),
      if (includeVisitLedger) _buildVisitLedger(),
    ];
  }

  Widget _buildVisitLedger() {
    return _VisitLedger(
      visitCountLabel: visitCountLabel,
      onOpenVisitHistory: onOpenVisitHistory,
      onRefresh: onRefreshVisits ?? onRefresh,
    );
  }
}

/// EN: Adaptive profile activity index shared by route and isolated views.
/// KO: 라우트와 독립 뷰가 공유하는 반응형 프로필 활동 인덱스입니다.
class FieldProfileActivityTabBar extends StatelessWidget {
  const FieldProfileActivityTabBar({
    super.key,
    required this.includeVisitLedger,
  });

  final bool includeVisitLedger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final tabHeight = textScale > 1.3 ? 64.0 : 48.0;
    return Material(
      color: colors.surface,
      child: TabBar(
        tabs: [
          _ActivityTab(
            height: tabHeight,
            label: context.l10n(ko: '작성한 글', en: 'Posts', ja: '投稿'),
          ),
          _ActivityTab(
            height: tabHeight,
            label: context.l10n(ko: '작성한 댓글', en: 'Comments', ja: 'コメント'),
          ),
          if (includeVisitLedger)
            _ActivityTab(
              height: tabHeight,
              label: context.l10n(ko: '방문 기록', en: 'Visits', ja: '訪問記録'),
            ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.height, required this.label});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: height,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _VisitLedger extends StatelessWidget {
  const _VisitLedger({
    required this.visitCountLabel,
    required this.onOpenVisitHistory,
    required this.onRefresh,
  });

  final String? visitCountLabel;
  final VoidCallback? onOpenVisitHistory;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = visitCountLabel?.trim();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.lg,
          GBTSpacing.pageHorizontal,
          GBTSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(GBTSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.primary, width: 3),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(ko: '방문 기록', en: 'Visit records', ja: '訪問記録'),
                  style: GBTTypography.overline.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  count == null || count.isEmpty || count == '—'
                      ? context.l10n(
                          ko: '공개된 방문 기록이 아직 없어요.',
                          en: 'No public visit record yet.',
                          ja: '公開された訪問記録はまだありません。',
                        )
                      : context.l10n(
                          ko: '성지 $count곳을 기록했어요.',
                          en: '$count places recorded.',
                          ja: '$count件の聖地を記録しました。',
                        ),
                  style: GBTTypography.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onOpenVisitHistory != null) ...[
                  const SizedBox(height: GBTSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: GBTSpacing.touchTarget,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: onOpenVisitHistory,
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        context.l10n(
                          ko: '방문 기록 보기',
                          en: 'Open visit history',
                          ja: '訪問履歴を見る',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(GBTSpacing.lg),
      children: [GBTLoading(message: message)],
    );
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(GBTSpacing.lg),
      children: [GBTErrorState(message: message, onRetry: onRetry)],
    );
  }
}

class _ActivityStatus extends StatelessWidget {
  const _ActivityStatus({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: GBTSpacing.xxl),
      children: [GBTEmptyState(icon: icon, title: message)],
    );
  }
}

class _PostLedger extends StatelessWidget {
  const _PostLedger({
    required this.posts,
    required this.onRefresh,
    required this.onOpenPost,
  });

  final List<PostSummary> posts;
  final Future<void> Function() onRefresh;
  final FieldOpenPost onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _RefreshableEmpty(
        icon: Icons.article_outlined,
        title: context.l10n(
          ko: '작성한 글이 없어요',
          en: 'No posts yet',
          ja: '投稿はまだありません',
        ),
        onRefresh: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.xxl,
        ),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final post = posts[index];
          return _ActivityEntry(
            eyebrow:
                post.topic ??
                context.l10n(
                  ko: '커뮤니티 기록',
                  en: 'Community note',
                  ja: 'コミュニティ記録',
                ),
            title: post.title,
            body: post.content,
            timeLabel: post.timeAgoLabel,
            trailingLabel: _engagementLabel(context, post),
            icon: Icons.article_outlined,
            onTap: () => onOpenPost(post.id, post.projectId),
          );
        },
      ),
    );
  }
}

class _CommentLedger extends StatelessWidget {
  const _CommentLedger({
    required this.comments,
    required this.onRefresh,
    required this.onOpenPost,
  });

  final List<PostComment> comments;
  final Future<void> Function() onRefresh;
  final FieldOpenPost onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return _RefreshableEmpty(
        icon: Icons.mode_comment_outlined,
        title: context.l10n(
          ko: '작성한 댓글이 없어요',
          en: 'No comments yet',
          ja: 'コメントはまだありません',
        ),
        onRefresh: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.xxl,
        ),
        itemCount: comments.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final comment = comments[index];
          return _ActivityEntry(
            eyebrow: context.l10n(
              ko: '댓글 기록',
              en: 'Comment note',
              ja: 'コメント記録',
            ),
            title: comment.content,
            timeLabel: comment.timeAgoLabel,
            trailingLabel: comment.replyCount == null
                ? null
                : context.l10n(
                    ko: '답글 ${comment.replyCount}',
                    en: '${comment.replyCount} replies',
                    ja: '返信 ${comment.replyCount}',
                  ),
            icon: Icons.mode_comment_outlined,
            onTap: () => onOpenPost(comment.postId, comment.projectId),
          );
        },
      ),
    );
  }
}

class _ActivityEntry extends StatelessWidget {
  const _ActivityEntry({
    required this.eyebrow,
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.onTap,
    this.body,
    this.trailingLabel,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final String timeLabel;
  final String? trailingLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedBody = body?.trim();
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outline),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: colors.secondary),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: GBTTypography.overline.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.xs),
                      GBTLinkifiedText(
                        title,
                        style: GBTTypography.titleSmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (normalizedBody != null &&
                          normalizedBody.isNotEmpty &&
                          normalizedBody != title) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        GBTLinkifiedText(
                          normalizedBody,
                          style: GBTTypography.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: GBTSpacing.sm),
                      Wrap(
                        spacing: GBTSpacing.sm,
                        runSpacing: GBTSpacing.xs,
                        children: [
                          Text(
                            timeLabel,
                            style: GBTTypography.labelSmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (trailingLabel != null)
                            Text(
                              trailingLabel!,
                              style: GBTTypography.labelSmall.copyWith(
                                color: GBTColors.fieldMapLine,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshableEmpty extends StatelessWidget {
  const _RefreshableEmpty({
    required this.icon,
    required this.title,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: GBTSpacing.xxl),
        children: [GBTEmptyState(icon: icon, title: title)],
      ),
    );
  }
}

String? _engagementLabel(BuildContext context, PostSummary post) {
  final likes = post.likeCount;
  final comments = post.commentCount;
  if (likes == null && comments == null) return null;
  return context.l10n(
    ko: '공감 ${likes ?? '—'} · 댓글 ${comments ?? '—'}',
    en: '${likes ?? '—'} likes · ${comments ?? '—'} comments',
    ja: 'いいね ${likes ?? '—'} · コメント ${comments ?? '—'}',
  );
}
