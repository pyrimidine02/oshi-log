/// EN: Feed page with news and community tabs — unified SNS-style design.
/// KO: 뉴스 및 커뮤니티 탭을 포함한 피드 페이지 — 통일된 SNS 스타일 디자인.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/image_url_extractor.dart';
import 'package:focus_detector/focus_detector.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/result.dart';

import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/sheets/gbt_bottom_sheet.dart';
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../projects/presentation/widgets/project_selector.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/community_moderation_controller.dart';
import '../../application/feed_controller.dart';
import '../../application/new_posts_indicator_notifier.dart';
import '../../application/report_rate_limiter.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/entities/feed_entities.dart';
import '../widgets/community_fab_layout.dart';
import '../widgets/community_translation_panel.dart';
import '../widgets/community_report_sheet.dart';

/// EN: Actions available on a community post card.
/// KO: 커뮤니티 게시글 카드에서 사용 가능한 액션.
enum _FeedPostCardAction { report }

/// EN: Feed page widget with modern pill-style segmented tab bar.
/// KO: 모던 필 스타일 세그먼트 탭바를 포함한 피드 페이지 위젯.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  static const Duration _focusRefreshMinInterval = Duration(minutes: 2);
  late TabController _tabController;
  late final ValueNotifier<bool> _showCommunityFabNotifier;
  DateTime? _lastFocusRefreshAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _showCommunityFabNotifier = ValueNotifier<bool>(_tabController.index == 1);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _showCommunityFabNotifier.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted) return;
    final shouldShow = _tabController.index == 1;
    if (shouldShow == _showCommunityFabNotifier.value) return;
    _showCommunityFabNotifier.value = shouldShow;
  }

  void _handleFocusGained() {
    final now = DateTime.now();
    final last = _lastFocusRefreshAt;
    if (last != null && now.difference(last) < _focusRefreshMinInterval) {
      return;
    }
    _lastFocusRefreshAt = now;
    // EN: Only refresh news on focus — community posts use background polling.
    // KO: 포커스 시 뉴스만 새로고침 — 커뮤니티 게시글은 백그라운드 폴링으로 처리.
    unawaited(
      ref.read(newsListControllerProvider.notifier).load(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsListControllerProvider);
    final postState = ref.watch(postListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('소식'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.goToSearch(),
            tooltip: '검색',
          ),
        ],
        // EN: Pill-style segmented tab bar — matches board_page design
        // KO: 필 스타일 세그먼트 탭바 — board_page 디자인과 일치
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: GBTSegmentedTabBar(
            controller: _tabController,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
            tabs: const [
              Tab(text: '뉴스'),
              Tab(text: '커뮤니티'),
            ],
          ),
        ),
      ),
      body: FocusDetector(
        onFocusGained: _handleFocusGained,
        child: Column(
          children: [
            // EN: Project selector — compact style
            // KO: 프로젝트 선택기 — 컴팩트 스타일
            const Padding(
              padding: EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
                0,
              ),
              child: ProjectSelectorCompact(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NewsList(
                    state: newsState,
                    onRetry: () => ref
                        .read(newsListControllerProvider.notifier)
                        .load(forceRefresh: true),
                  ),
                  _CommunityList(
                    state: postState,
                    onRetry: () => ref
                        .read(postListControllerProvider.notifier)
                        .load(forceRefresh: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // EN: Compact FAB reduces visual weight in timeline screens.
      // KO: 타임라인 화면에서 시각적 부담을 줄이기 위한 컴팩트 FAB.
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showCommunityFabNotifier,
        builder: (context, showCommunityFab, _) {
          if (!showCommunityFab) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(
              bottom: resolveCommunityFabBottomPadding(
                screenHeight: MediaQuery.sizeOf(context).height,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () => context.goToPostCreate(),
              tooltip: '글쓰기',
              child: const Icon(Icons.edit_outlined),
            ),
          );
        },
      ),
    );
  }
}

/// EN: News list widget — divider-separated, borderless cards.
/// KO: 뉴스 리스트 위젯 — 구분선 분리, 무테두리 카드.
class _NewsList extends StatelessWidget {
  const _NewsList({required this.state, required this.onRetry});

  final AsyncValue<List<NewsSummary>> state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: state.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
          children: [
            GBTListSkeleton(
              itemCount: 4,
              padding: EdgeInsets.zero,
              spacing: GBTSpacing.sm,
              itemBuilder: (_) => const GBTNewsCardSkeleton(),
            ),
          ],
        ),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : '뉴스를 불러오지 못했어요';
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: GBTSpacing.paddingPage,
            children: [
              const SizedBox(height: GBTSpacing.lg),
              GBTErrorState(message: message, onRetry: onRetry),
            ],
          );
        },
        data: (newsList) {
          if (newsList.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: GBTSpacing.paddingPage,
              children: [
                const SizedBox(height: GBTSpacing.lg),
                GBTEmptyState(
                  icon: Icons.newspaper_outlined,
                  title: '표시할 뉴스가 없습니다',
                ),
              ],
            );
          }

          // EN: Divider-separated list for modern look
          // KO: 모던한 느낌의 구분선 분리 리스트
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            itemCount: newsList.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: GBTSpacing.pageHorizontal,
              endIndent: GBTSpacing.pageHorizontal,
            ),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return _NewsCard(news: news);
            },
          );
        },
      ),
    );
  }
}

/// EN: News card widget — borderless with thumbnail.
/// KO: 뉴스 카드 위젯 — 썸네일 포함 무테두리.
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final NewsSummary news;

  @override
  Widget build(BuildContext context) {
    final thumbnail = news.thumbnailUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    // EN: Borderless card — no Card wrapper, just InkWell + Padding
    // KO: 무테두리 카드 — Card 래퍼 없이, InkWell + Padding만 사용
    return InkWell(
      onTap: () => context.goToNewsDetail(news.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.pageHorizontal,
          vertical: GBTSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NewsThumbnail(imageUrl: thumbnail),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: GBTTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    news.dateLabel,
                    style: GBTTypography.labelSmall.copyWith(
                      color: tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: News thumbnail widget with rounded corners.
/// KO: 둥근 모서리의 뉴스 썸네일 위젯.
class _NewsThumbnail extends StatelessWidget {
  const _NewsThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDark
              ? GBTColors.darkSurfaceVariant
              : GBTColors.surfaceVariant,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        ),
        child: Icon(
          Icons.article_outlined,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          size: 28,
        ),
      );
    }

    return GBTImage(
      imageUrl: imageUrl!,
      width: 80,
      height: 80,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      semanticLabel: '뉴스 썸네일',
    );
  }
}

/// EN: Community list widget — divider-separated, SNS-style with new-posts pill.
/// KO: 커뮤니티 리스트 위젯 — 구분선 분리, SNS 스타일 + 새 게시글 필 오버레이.
class _CommunityList extends ConsumerStatefulWidget {
  const _CommunityList({required this.state, required this.onRetry});

  final AsyncValue<List<PostSummary>> state;
  final Future<void> Function() onRetry;

  @override
  ConsumerState<_CommunityList> createState() => _CommunityListState();
}

class _CommunityListState extends ConsumerState<_CommunityList> {
  final ScrollController _scrollController = ScrollController();

  // EN: Scroll offset above which the new-posts pill is eligible to show.
  // KO: 새 게시글 필을 표시할 최소 스크롤 오프셋.
  static const double _scrollThreshold = 160.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final notifier = ref.read(newPostsIndicatorProvider.notifier);
    final indicatorState = ref.read(newPostsIndicatorProvider);

    if (offset <= _scrollThreshold) {
      // EN: Near top — hide pill.
      // KO: 상단 근처 — 필을 숨깁니다.
      if (indicatorState.visible) notifier.dismiss();
    } else {
      // EN: Scrolled down — re-show pill if there are buffered posts.
      // KO: 스크롤 내려감 — 버퍼된 게시글이 있으면 필을 다시 표시합니다.
      if (!indicatorState.visible && indicatorState.buffered.isNotEmpty) {
        notifier.showIfBuffered();
      }
    }
  }

  void _onPillTap() {
    ref.read(newPostsIndicatorProvider.notifier).accept();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorState = ref.watch(newPostsIndicatorProvider);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRetry,
          child: widget.state.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              children: [
                GBTListSkeleton(
                  itemCount: 5,
                  padding: EdgeInsets.zero,
                  spacing: GBTSpacing.none,
                  itemBuilder: (_) => const GBTCommunityPostSkeleton(),
                ),
              ],
            ),
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : '커뮤니티 글을 불러오지 못했어요';
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: GBTSpacing.paddingPage,
                children: [
                  const SizedBox(height: GBTSpacing.lg),
                  GBTErrorState(message: message, onRetry: widget.onRetry),
                ],
              );
            },
            data: (posts) {
              if (posts.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: GBTSpacing.paddingPage,
                  children: [
                    const SizedBox(height: GBTSpacing.lg),
                    GBTEmptyState(
                      icon: Icons.forum_outlined,
                      title: '아직 커뮤니티 글이 없습니다',
                      subtitle: '첫 이야기를 들려주세요!',
                    ),
                  ],
                );
              }

              // EN: Divider-separated SNS-style list with scroll tracking.
              // KO: 구분선 분리 SNS 스타일 리스트 + 스크롤 추적.
              return ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: GBTSpacing.pageHorizontal,
                  endIndent: GBTSpacing.pageHorizontal,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _CommunityPostCard(post: post);
                },
              );
            },
          ),
        ),

        // EN: New-posts pill — slides in from top when new content arrives.
        // KO: 새 게시글 필 — 새 콘텐츠 도착 시 상단에서 슬라이드 인.
        if (indicatorState.buffered.isNotEmpty)
          Positioned(
            top: GBTSpacing.md,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSlide(
                offset: indicatorState.visible
                    ? Offset.zero
                    : const Offset(0, -1.5),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: indicatorState.visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !indicatorState.visible,
                    // EN: RepaintBoundary isolates the pill from list scroll repaints.
                    // KO: RepaintBoundary로 필을 리스트 스크롤 리페인트에서 격리합니다.
                    child: RepaintBoundary(
                      child: _NewPostsPill(
                        posts: indicatorState.buffered,
                        onTap: _onPillTap,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// EN: Twitter-style pill showing new post count and author avatars.
/// KO: 새 게시글 수와 작성자 아바타를 표시하는 트위터 스타일 필.
class _NewPostsPill extends StatelessWidget {
  const _NewPostsPill({required this.posts, required this.onTap});

  final List<PostSummary> posts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = posts.length;
    final avatarPosts = posts.take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.xs2,
        ),
        decoration: BoxDecoration(
          color: GBTColors.primary,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: GBTColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EN: RepaintBoundary isolates avatar stack from pill text updates.
            // KO: RepaintBoundary로 아바타 스택을 필 텍스트 업데이트에서 격리합니다.
            RepaintBoundary(child: _StackedAvatars(posts: avatarPosts)),
            const SizedBox(width: GBTSpacing.sm),
            Text(
              '새 글 $count개',
              style: GBTTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: GBTSpacing.xs),
            const Icon(
              Icons.arrow_upward_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: Stacked avatar circles for new post authors.
/// KO: 새 게시글 작성자 아바타 스택 원형 표시.
class _StackedAvatars extends StatelessWidget {
  const _StackedAvatars({required this.posts});

  final List<PostSummary> posts;

  @override
  Widget build(BuildContext context) {
    const double size = 22.0;
    const double overlap = 7.0;
    final count = posts.length.clamp(1, 3);
    final width = size + (count - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AvatarCircle(url: posts[i].authorAvatarUrl, size: size),
            ),
        ],
      ),
    );
  }
}

/// EN: Single avatar circle with white border and fallback initial.
/// KO: 흰색 테두리와 이니셜 폴백을 가진 단일 아바타 원.
class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: GBTColors.primary, width: 1.5),
        color: GBTColors.primary.withValues(alpha: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? GBTImage(
              imageUrl: url!,
              width: size,
              height: size,
              semanticLabel: '프로필',
            )
          : const Icon(Icons.person, size: 12, color: Colors.white),
    );
  }
}

/// EN: Community post card — borderless, divider-separated SNS style.
/// KO: 커뮤니티 게시글 카드 — 무테두리, 구분선 분리 SNS 스타일.
class _CommunityPostCard extends ConsumerWidget {
  const _CommunityPostCard({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorLabel = post.authorName?.isNotEmpty == true
        ? post.authorName!
        : '익명';
    final avatarUrl = post.authorAvatarUrl?.isNotEmpty == true
        ? post.authorAvatarUrl
        : null;
    final commentCount = post.commentCount ?? 0;
    final likeCount = post.likeCount ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    // EN: Determine if the current user can report this post.
    // KO: 현재 사용자가 이 게시글을 신고할 수 있는지 확인합니다.
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final myProfile = ref.watch(userProfileControllerProvider).valueOrNull;
    final isAuthor = myProfile?.id == post.authorId;
    final showMoreButton = isAuthenticated && !isAuthor;

    // EN: Prefer server thumbnail, then fallback list/content-derived images.
    // KO: 서버 썸네일 우선, 그 다음 목록/본문 기반 이미지로 폴백합니다.
    final previewImageUrls = _resolvePreviewImageUrls(post);
    final hasImage = previewImageUrls.isNotEmpty;

    // EN: Card container — rounded border, surface background.
    //     2026 large-radius card trend.
    // KO: 카드 컨테이너 — 둥근 테두리, 표면 배경.
    //     2026 라지 라운드 카드 트렌드.
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: isDark
              ? GBTColors.darkBorder.withValues(alpha: 0.8)
              : GBTColors.border.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          onTap: () =>
              context.goToPostDetail(post.id, projectCode: post.projectId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EN: Author row — avatar + name + time + report menu
                    // KO: 작성자 행 — 아바타 + 이름 + 시간 + 신고 메뉴
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Avatar(
                          url: avatarUrl,
                          radius: 16,
                          semanticLabel: '$authorLabel 프로필 사진',
                          onTap: () => context.goToUserProfile(post.authorId),
                        ),
                        const SizedBox(width: GBTSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorLabel,
                                style: GBTTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.timeAgoLabel,
                                style: GBTTypography.labelSmall.copyWith(
                                  color: tertiaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showMoreButton)
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: tertiaryColor,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: '더보기',
                            onPressed: () async {
                              final action =
                                  await showGBTActionSheet<_FeedPostCardAction>(
                                    context: context,
                                    actions: const [
                                      GBTActionSheetItem(
                                        label: '신고',
                                        value: _FeedPostCardAction.report,
                                        icon: Icons.flag_outlined,
                                      ),
                                    ],
                                    cancelLabel: '취소',
                                  );
                              if (!context.mounted) return;
                              if (action == _FeedPostCardAction.report) {
                                _showReportFlow(context, ref);
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // EN: Content area — Text first, then large full-width image.
                    // KO: 콘텐츠 영역 — 텍스트 먼저, 그 다음 가로로 꽉 차는 큰 이미지.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: GBTTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (post.content != null &&
                            post.content!.isNotEmpty) ...[
                          const SizedBox(height: GBTSpacing.xs),
                          GBTLinkifiedText(
                            post.content!,
                            style: GBTTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextSecondary
                                  : GBTColors.textSecondary,
                              height: 1.45,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          CommunityTranslationPanel(
                            contentId: 'post-preview:${post.id}',
                            text:
                                stripImageMarkdown(post.content!).trim().isEmpty
                                ? post.content!
                                : stripImageMarkdown(post.content!),
                            textStyle: GBTTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextSecondary
                                  : GBTColors.textSecondary,
                              height: 1.45,
                            ),
                            compact: true,
                          ),
                        ],
                        if (hasImage) ...[
                          const SizedBox(height: GBTSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusMd,
                            ),
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 200,
                                  child: _FallbackPreviewImage(
                                    imageUrls: previewImageUrls,
                                    fit: BoxFit.cover,
                                    semanticLabel: '${post.title} 첨부 이미지',
                                  ),
                                ),
                                if (post.imageUrls.length > 1)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          GBTSpacing.radiusFull,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.photo_library_outlined,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${post.imageUrls.length - 1}',
                                            style: GBTTypography.labelMedium
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // EN: Stats bar with subtle top border.
              // KO: 미묘한 상단 테두리가 있는 통계 바.
              Semantics(
                label: '좋아요 $likeCount개, 댓글 $commentCount개',
                child: Container(
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      _ModernStatChip(
                        icon: Icons.thumb_up_outlined,
                        count: likeCount,
                        color: tertiaryColor,
                      ),
                      const SizedBox(width: GBTSpacing.md),
                      _ModernStatChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: commentCount,
                        color: tertiaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// EN: Report flow — rate-limit check, report sheet, confirmation, submit.
  /// KO: 신고 흐름 — 레이트리밋 확인, 신고 시트, 확인 다이얼로그, 제출.
  Future<void> _showReportFlow(BuildContext context, WidgetRef ref) async {
    final rateLimiter = ref.read(reportRateLimiterProvider);
    if (!rateLimiter.canReport(post.id)) {
      final remaining = rateLimiter.remainingCooldown(post.id);
      final minutes = remaining.inMinutes + 1;
      _showSnackBar(context, '$minutes분 후 다시 신고할 수 있어요');
      return;
    }

    final payload = await showModalBottomSheet<CommunityReportPayload>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CommunityReportSheet(),
    );
    if (payload == null || !context.mounted) return;

    final confirmed = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '신고 접수',
      message: '게시글을 "${payload.reason.label}" 사유로 신고합니다.\n접수하시겠어요?',
      cancelLabel: '취소',
      confirmLabel: '신고 접수',
    );
    if (confirmed != true || !context.mounted) return;

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.createReport(
      targetType: CommunityReportTargetType.post,
      targetId: post.id,
      reason: payload.reason,
      description: payload.description,
    );
    if (!context.mounted) return;
    if (result is Success<void>) {
      rateLimiter.recordReport(post.id);
      _showSnackBar(context, '신고가 접수되었어요. 검토 후 조치할게요');
    } else {
      _showSnackBar(context, '신고를 접수하지 못했어요');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// EN: Resolve post preview image candidates with deterministic priority.
  /// KO: 고정 우선순위로 게시글 미리보기 이미지 후보를 해석합니다.
  List<String> _resolvePreviewImageUrls(PostSummary post) {
    final ordered = <String>[];
    final seen = <String>{};
    void addIfValid(String? raw) {
      final normalized = _normalizePreviewUrl(raw);
      if (normalized == null) return;
      if (seen.add(normalized)) {
        ordered.add(normalized);
      }
    }

    addIfValid(post.thumbnailUrl);
    for (final url in post.imageUrls) {
      addIfValid(url);
    }
    for (final url in extractImageUrls(post.content)) {
      addIfValid(url);
    }
    return ordered;
  }

  /// EN: Normalize/validate preview URL for safe image rendering.
  /// KO: 안전한 이미지 렌더링을 위해 미리보기 URL을 정규화/검증합니다.
  String? _normalizePreviewUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }
    final resolved = resolveMediaUrl(trimmed);
    final uri = Uri.tryParse(resolved);
    if (uri == null) return null;
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return resolved;
  }
}

/// EN: Tries multiple preview image URLs and falls back on load failure.
/// KO: 여러 미리보기 이미지 URL을 시도하고 로드 실패 시 다음 후보로 전환합니다.
class _FallbackPreviewImage extends StatefulWidget {
  const _FallbackPreviewImage({
    required this.imageUrls,
    required this.fit,
    required this.semanticLabel,
  });

  final List<String> imageUrls;
  final BoxFit fit;
  final String semanticLabel;

  @override
  State<_FallbackPreviewImage> createState() => _FallbackPreviewImageState();
}

class _FallbackPreviewImageState extends State<_FallbackPreviewImage> {
  int _currentIndex = 0;
  bool _advanceScheduled = false;

  @override
  void didUpdateWidget(covariant _FallbackPreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _currentIndex = 0;
      _advanceScheduled = false;
    }
  }

  void _advanceImage() {
    if (_advanceScheduled) return;
    if (_currentIndex >= widget.imageUrls.length - 1) return;
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _advanceScheduled = false;
      if (_currentIndex >= widget.imageUrls.length - 1) return;
      setState(() {
        _currentIndex += 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolvedIndex = _currentIndex.clamp(0, widget.imageUrls.length - 1);
    return GBTImage(
      key: ValueKey(widget.imageUrls[resolvedIndex]),
      imageUrl: widget.imageUrls[resolvedIndex],
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      onError: _advanceImage,
    );
  }
}

// EN: Modern stat chip — icon + count, used in feed card stats bar.
// KO: 아이콘 + 숫자 모던 통계 칩, 피드 카드 통계 바에서 사용.
class _ModernStatChip extends StatelessWidget {
  const _ModernStatChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: GBTSpacing.xs),
          Text(
            count.toString(),
            style: GBTTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Avatar widget with accessible touch targets.
/// KO: 접근 가능한 터치 타겟을 가진 아바타 위젯.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.radius,
    this.onTap,
    this.semanticLabel,
  });

  final String? url;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final iconColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(Icons.person, size: radius, color: iconColor),
    );

    final content = (url == null || url!.isEmpty)
        ? fallback
        : ClipOval(
            child: GBTImage(
              imageUrl: url!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel ?? '프로필 사진',
            ),
          );

    if (onTap == null) return content;

    // EN: Ensure minimum 48x48 touch target for accessibility.
    // KO: 접근성을 위해 최소 48x48 터치 타겟을 보장합니다.
    return Semantics(
      button: true,
      label: semanticLabel ?? '프로필 보기',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: GBTSpacing.touchTarget,
            minHeight: GBTSpacing.touchTarget,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
