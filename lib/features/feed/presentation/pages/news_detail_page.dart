/// EN: News detail page with full article content.
/// KO: 전체 기사 콘텐츠를 포함한 뉴스 상세 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/feed_controller.dart';
import '../../domain/entities/feed_entities.dart';

/// EN: News detail page widget.
/// KO: 뉴스 상세 페이지 위젯.
class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({super.key, required this.newsId});

  final String newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newsDetailControllerProvider(newsId));

    return state.when(
      loading: () => Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '뉴스', en: 'News', ja: 'ニュース'),
        ),
        body: GBTLoading(
          message: context.l10n(
            ko: '뉴스를 불러오는 중...',
            en: 'Loading news...',
            ja: 'ニュースを読み込み中...',
          ),
        ),
      ),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '뉴스를 불러오지 못했어요',
                en: 'Failed to load news',
                ja: 'ニュースを読み込めませんでした',
              );
        return Scaffold(
          appBar: gbtStandardAppBar(
            context,
            title: context.l10n(ko: '뉴스', en: 'News', ja: 'ニュース'),
          ),
          body: GBTErrorState(
            message: message,
            onRetry: () => ref
                .read(newsDetailControllerProvider(newsId).notifier)
                .load(forceRefresh: true),
          ),
        );
      },
      data: (news) => Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '뉴스', en: 'News', ja: 'ニュース'),
        ),
        body: SingleChildScrollView(child: NewsArticleView(news: news)),
      ),
    );
  }
}

/// EN: News detail view widget.
/// KO: 뉴스 상세 뷰 위젯.
class NewsArticleView extends StatelessWidget {
  const NewsArticleView({super.key, required this.news});

  final NewsDetail news;

  @override
  Widget build(BuildContext context) {
    final content = news.body;
    // EN: Use theme-aware colors for dark mode compatibility.
    // KO: 다크 모드 호환성을 위해 테마 인식 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GBTPageHeader(
              eyebrow: 'FIELD DISPATCH',
              title: news.title,
              description: news.dateLabel,
            ),
            if (news.coverImageUrl?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.lg,
                  GBTSpacing.pageHorizontal,
                  0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _NewsHeaderImage(
                      newsId: news.id,
                      imageUrl: news.coverImageUrl,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                GBTSpacing.lg,
                GBTSpacing.pageHorizontal,
                GBTSpacing.xxl,
              ),
              child: SelectableText(
                content.isNotEmpty
                    ? content
                    : context.l10n(
                        ko: '기사 본문을 불러오지 못했어요.',
                        en: 'Failed to load article body.',
                        ja: '記事本文を読み込めませんでした。',
                      ),
                style: GBTTypography.bodyMedium.copyWith(
                  height: 1.8,
                  color: bodyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: News header image widget with dark-mode-aware placeholder.
/// KO: 다크 모드 인식 플레이스홀더를 가진 뉴스 헤더 이미지 위젯.
class _NewsHeaderImage extends StatelessWidget {
  const _NewsHeaderImage({required this.newsId, required this.imageUrl});

  final String newsId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    // EN: Use theme-aware placeholder colors.
    // KO: 테마 인식 플레이스홀더 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.article,
            size: 64,
            color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          ),
        ),
      );
    }

    return Hero(
      tag: GBTHeroTags.newsImage(newsId),
      child: GBTImage(
        imageUrl: imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '뉴스 대표 이미지',
          en: 'News cover image',
          ja: 'ニュース代表画像',
        ),
      ),
    );
  }
}
