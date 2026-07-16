/// EN: Post bookmarks page — lists community posts the user has bookmarked.
/// KO: 북마크한 커뮤니티 게시글 목록 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/local_post_bookmarks_controller.dart';

/// EN: Page showing all community posts the user has bookmarked locally.
/// KO: 사용자가 북마크한 커뮤니티 게시글 목록 페이지 (로컬 저장).
class PostBookmarksPage extends ConsumerWidget {
  const PostBookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(localPostBookmarksControllerProvider);

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '북마크한 글', en: 'Bookmarks', ja: 'ブックマーク'),
      ),
      body: posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: GBTSpacing.paddingPage,
              children: [
                const SizedBox(height: GBTSpacing.sm),
                GBTEmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: context.l10n(
                    ko: '북마크한 글이 없습니다',
                    en: 'No bookmarked posts',
                    ja: 'ブックマークした投稿がありません',
                  ),
                  subtitle: context.l10n(
                    ko: '게시글 하단 북마크 버튼을 눌러 저장하세요.',
                    en: 'Tap the bookmark button on a post to save it.',
                    ja: '投稿下部のブックマークボタンで保存できます。',
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final item = posts[index];
                return BookmarkedPostRow(
                  item: item,
                  onTap: () {
                    if (item.postId.isEmpty) return;
                    context.goToPostDetail(
                      item.postId,
                      projectCode: item.projectCode,
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 96,
                endIndent: GBTSpacing.pageHorizontal,
              ),
            ),
    );
  }
}

class BookmarkedPostRow extends StatelessWidget {
  const BookmarkedPostRow({super.key, required this.item, required this.onTap});

  final LocalBookmarkedPost item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label:
          '${context.l10n(ko: "북마크", en: "Bookmark", ja: "ブックマーク")}: ${item.title.isNotEmpty ? item.title : context.l10n(ko: "게시글", en: "Post", ja: "投稿")}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
            vertical: GBTSpacing.sm2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                child:
                    item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? GBTImage(
                        imageUrl: item.thumbnailUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: colors.surfaceContainerHighest,
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(
                            Icons.bookmark_outline_rounded,
                            size: 24,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
                  child: Text(
                    item.title.isNotEmpty
                        ? item.title
                        : context.l10n(ko: '게시글', en: 'Post', ja: '投稿'),
                    style: GBTTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: GBTSpacing.lg2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
