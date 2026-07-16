/// EN: Edge-to-edge journal entry for a real community post.
/// KO: 실제 커뮤니티 게시글을 위한 엣지 투 엣지 저널 엔트리.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/utils/image_url_extractor.dart';
import '../../../../../core/widgets/common/gbt_image.dart';
import '../../../domain/entities/feed_entities.dart';

/// EN: Community content is presented as a report sheet, not a floating card.
/// KO: 커뮤니티 콘텐츠를 플로팅 카드가 아닌 리포트 시트로 표현합니다.
class FieldCommunityPostEntry extends StatelessWidget {
  const FieldCommunityPostEntry({
    super.key,
    required this.post,
    required this.onTap,
  });

  final PostSummary post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final author = _authorLabel(context);
    final body = stripImageMarkdown(post.content ?? '');
    final imageUrl = _coverImageUrl();

    return Semantics(
      button: true,
      label: context.l10n(
        ko: '$author님의 필드 리포트. ${post.title}',
        en: 'Field report by $author. ${post.title}',
        ja: '$authorさんのフィールドレポート。${post.title}',
      ),
      child: Material(
        color: surface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.md,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.sm,
                ),
                child: _ReportHeader(post: post, author: author),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.pageHorizontal,
                ),
                child: Text(
                  post.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.headlineMedium.copyWith(
                    color: isDark
                        ? GBTColors.darkTextPrimary
                        : GBTColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: GBTSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.pageHorizontal,
                  ),
                  child: Text(
                    body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
              if (imageUrl != null) ...[
                const SizedBox(height: GBTSpacing.md),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GBTImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: post.title,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.sm,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.md,
                ),
                child: _ReportFooter(post: post),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _authorLabel(BuildContext context) {
    final name = post.authorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return context.l10n(ko: '익명 여행자', en: 'Anonymous traveler', ja: '匿名の旅人');
  }

  String? _coverImageUrl() {
    final candidates = <String?>[
      post.thumbnailUrl,
      ...post.imageUrls,
      ...extractImageUrls(post.content),
    ];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.post, required this.author});

  final PostSummary post;
  final String author;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final avatarUrl = post.authorAvatarUrl?.trim();
    final topic = post.topic?.trim();

    return Row(
      children: [
        ClipOval(
          child: SizedBox.square(
            dimension: 36,
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? GBTImage(
                    imageUrl: avatarUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    semanticLabel: author,
                  )
                : ColoredBox(
                    color: isDark
                        ? GBTColors.darkSurfaceElevated
                        : GBTColors.secondaryLight,
                    child: Center(
                      child: Text(
                        author.characters.first.toUpperCase(),
                        style: GBTTypography.labelLarge.copyWith(
                          color: isDark
                              ? GBTColors.darkSecondary
                              : GBTColors.secondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: GBTSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GBTTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                [
                  if (topic != null && topic.isNotEmpty) topic,
                  post.timeAgoLabel,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GBTTypography.labelSmall.copyWith(color: muted),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_outward_rounded, size: 18, color: muted),
      ],
    );
  }
}

class _ReportFooter extends StatelessWidget {
  const _ReportFooter({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tags = post.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .take(2)
        .toList(growable: false);

    return Row(
      children: [
        if (tags.isNotEmpty)
          Expanded(
            child: Text(
              tags.map((tag) => '#$tag').join('  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GBTTypography.labelSmall.copyWith(
                color: isDark ? GBTColors.darkSecondary : GBTColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          const Spacer(),
        _Metric(
          icon: Icons.favorite_border_rounded,
          value: post.likeCount ?? 0,
          color: muted,
        ),
        const SizedBox(width: GBTSpacing.md),
        _Metric(
          icon: Icons.chat_bubble_outline_rounded,
          value: post.commentCount ?? 0,
          color: muted,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.color});

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: GBTSpacing.xs),
          Text(
            '$value',
            style: GBTTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
