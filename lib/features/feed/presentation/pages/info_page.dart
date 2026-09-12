/// EN: Info page with tabbed sections — news, units (with member/VA accordion), songs.
/// KO: 탭 구조의 정보 페이지 — 소식, 유닛(멤버/성우 아코디언), 악곡.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/palette_utils.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_profile_action.dart';
import '../../../music/application/music_controller.dart';
import '../../../music/presentation/widgets/music_catalog_tab.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/feed_controller.dart';
import '../../domain/entities/feed_entities.dart';
import '../widgets/voice_actor_directory_tab.dart';

// ===========================================================================
// EN: Info page root
// KO: 정보 페이지 루트
// ===========================================================================

/// EN: Info page with wiki-style tabs and inline project selector in AppBar.
/// KO: 위키 스타일 탭과 AppBar 인라인 프로젝트 선택기가 있는 정보 페이지.
class InfoPage extends ConsumerStatefulWidget {
  const InfoPage({super.key});

  @override
  ConsumerState<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends ConsumerState<InfoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabCount = 5;
  static const _tabIcons = [
    Icons.newspaper_outlined,
    Icons.groups_outlined,
    Icons.mic_external_on_outlined,
    Icons.music_note_outlined,
    Icons.apps_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await ref
            .read(newsListControllerProvider.notifier)
            .load(forceRefresh: true);
        return;
      case 1:
        final selection = ref.read(projectSelectionControllerProvider);
        final projectKey = selection.projectKey;
        if (projectKey == null || projectKey.isEmpty) return;
        await ref
            .read(projectUnitsControllerProvider(projectKey).notifier)
            .load(forceRefresh: true);
        return;
      case 2:
        final selection = ref.read(projectSelectionControllerProvider);
        final projectKey = selection.projectKey;
        if (projectKey == null || projectKey.isEmpty) return;
        await ref
            .read(voiceActorsCatalogControllerProvider(projectKey).notifier)
            .refresh();
        return;
      case 3:
        final selection = ref.read(projectSelectionControllerProvider);
        final projectKey = selection.projectKey;
        if (projectKey == null || projectKey.isEmpty) return;
        await Future.wait([
          ref
              .read(musicSongsControllerProvider(projectKey).notifier)
              .load(forceRefresh: true),
          ref
              .read(musicAlbumsControllerProvider(projectKey).notifier)
              .load(forceRefresh: true),
        ]);
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentNavIndex = ref.watch(currentNavIndexProvider);
    final isInfoTabActive = currentNavIndex == NavIndex.information;
    final projectSelection = ref.watch(projectSelectionControllerProvider);
    final selectedProjectId = projectSelection.projectKey ?? '';
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final bgColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final avatarUrl = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.avatarUrl;
    final tabs = [
      context.l10n(ko: '소식', en: 'News', ja: 'お知らせ'),
      context.l10n(ko: '유닛', en: 'Units', ja: 'ユニット'),
      context.l10n(ko: '성우', en: 'Voice actors', ja: '声優'),
      context.l10n(ko: '악곡', en: 'Songs', ja: '楽曲'),
      context.l10n(ko: '더보기', en: 'More', ja: 'もっと'),
    ];

    return Scaffold(
      // EN: No shadow — only bottom border for visual separation.
      // KO: 그림자 없음 — 시각적 분리를 위한 하단 테두리만 사용.
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: GBTSpacing.md),
            Text(
              context.l10n(ko: '정보', en: 'Info', ja: '情報'),
              style: GBTTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            _InfoProjectChip(isDark: isDark),
          ],
        ),
        actions: [GBTProfileAction(avatarUrl: avatarUrl)],
        // EN: Underline tab bar with indigo indicator.
        // KO: 인디고 인디케이터가 있는 밑줄 탭 바.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ColoredBox(
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                  ),
                  // EN: Indigo underline indicator, 3px height, rounded caps.
                  // KO: 인디고 밑줄 인디케이터, 3px 높이, 둥근 끝.
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                      width: 3,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(GBTSpacing.radiusFull),
                      topRight: Radius.circular(GBTSpacing.radiusFull),
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  // EN: Selected tab uses primary/indigo; unselected uses textSecondary.
                  // KO: 선택된 탭은 primary/인디고, 미선택 탭은 textSecondary 사용.
                  labelColor: isDark
                      ? GBTColors.darkPrimary
                      : GBTColors.primary,
                  unselectedLabelColor: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                  labelStyle: GBTTypography.tabLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GBTTypography.tabLabel.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  dividerHeight: 0,
                  tabs: List.generate(tabs.length, (i) {
                    final isSelected = _tabController.index == i;
                    return Tab(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabIcons[i],
                            size: 16,
                            color: isSelected
                                ? (isDark
                                      ? GBTColors.darkPrimary
                                      : GBTColors.primary)
                                : (isDark
                                      ? GBTColors.darkTextSecondary
                                      : GBTColors.textSecondary),
                          ),
                          const SizedBox(width: GBTSpacing.xs),
                          Text(tabs[i]),
                        ],
                      ),
                    );
                  }),
                ),
                // EN: Bottom divider line matching theme border color.
                // KO: 테마 테두리 색상에 맞춘 하단 구분선.
                Divider(height: 1, thickness: 1, color: borderColor),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
        onRefresh: _refreshCurrentTab,
        child: TabBarView(
          controller: _tabController,
          children: [
            _NewsTab(isActive: isInfoTabActive && _tabController.index == 0),
            _UnitsTab(isActive: isInfoTabActive && _tabController.index == 1),
            VoiceActorDirectoryTab(
              isActive: isInfoTabActive && _tabController.index == 2,
              projectId: selectedProjectId,
            ),
            const MusicCatalogTab(),
            const _MoreTab(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// EN: News tab — featured hero + compact list (wiki/media-style)
// KO: 소식 탭 — 피처드 히어로 + 컴팩트 리스트 (위키/미디어 스타일)
// ===========================================================================

class _NewsTab extends ConsumerWidget {
  const _NewsTab({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isActive) {
      return const SizedBox.shrink();
    }
    final newsState = ref.watch(newsListControllerProvider);

    return newsState.when(
      loading: () => const _NewsTabSkeleton(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '뉴스를 불러오지 못했어요',
                en: 'Failed to load news',
                ja: 'ニュースを読み込めませんでした',
              );
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const SizedBox(height: GBTSpacing.lg),
            GBTErrorState(
              message: message,
              onRetry: () => ref
                  .read(newsListControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
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
                title: context.l10n(
                  ko: '아직 소식이 없어요',
                  en: 'No news yet',
                  ja: 'まだお知らせがありません',
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              // EN: First item — large hero card for maximum impact.
              // KO: 첫 번째 항목 — 최대 임팩트를 위한 큰 히어로 카드.
              return _NewsHeroCard(news: newsList[0]);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GBTSpacing.pageHorizontal,
                      GBTSpacing.md,
                      GBTSpacing.pageHorizontal,
                      GBTSpacing.xs,
                    ),
                    child: _SectionHeader(
                      icon: Icons.article_outlined,
                      label: context.l10n(
                        ko: '최근 소식',
                        en: 'Recent news',
                        ja: '最新のお知らせ',
                      ),
                    ),
                  ),
                _NewsRowItem(news: newsList[index]),
                if (index < newsList.length - 1)
                  const Divider(
                    height: 1,
                    indent: GBTSpacing.pageHorizontal,
                    endIndent: GBTSpacing.pageHorizontal,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// EN: Hero news card — large image banner + overlay gradient title + date row.
/// KO: 히어로 뉴스 카드 — 큰 이미지 배너 + 오버레이 그라데이션 제목 + 날짜 행.
class _NewsHeroCard extends StatelessWidget {
  const _NewsHeroCard({required this.news});
  final NewsSummary news;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbnail = news.thumbnailUrl;
    final hasThumbnail = thumbnail != null && thumbnail.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
        GBTSpacing.pageHorizontal,
        0,
      ),
      child: InkWell(
        onTap: () => context.goToNewsDetail(news.id),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            // EN: Elevated card — subtle shadow for hero prominence.
            // KO: 영웅 카드 강조를 위한 미세한 그림자.
            color: isDark ? GBTColors.darkSurface : GBTColors.surface,
            boxShadow: isDark ? GBTShadows.darkMd : GBTShadows.md,
            border: isDark
                ? Border.all(color: GBTColors.darkBorder, width: 0.5)
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EN: Hero image — 16:9 aspect ratio.
              // KO: 히어로 이미지 — 16:9 비율.
              AspectRatio(
                aspectRatio: 16 / 9,
                child: hasThumbnail
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          GBTImage(
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            semanticLabel: context.l10n(
                              ko: '소식 이미지',
                              en: 'News image',
                              ja: 'お知らせ画像',
                            ),
                          ),
                          // EN: Bottom gradient overlay for text legibility.
                          // KO: 텍스트 가독성을 위한 하단 그라데이션 오버레이.
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: GBTColors.carouselCardOverlayGradient,
                            ),
                          ),
                          // EN: NEW badge — only shown if published within 72 hours.
                          // KO: NEW 배지 — 72시간 이내 게시된 경우에만 표시합니다.
                          if (DateTime.now()
                                  .difference(news.publishedAt)
                                  .inHours <
                              72)
                            Positioned(
                              top: GBTSpacing.sm,
                              left: GBTSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: GBTSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: GBTColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    GBTSpacing.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'NEW',
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : ColoredBox(
                        color: isDark
                            ? GBTColors.darkSurfaceElevated
                            : GBTColors.surfaceAlternate,
                        child: Center(
                          child: Icon(
                            Icons.newspaper_outlined,
                            size: 48,
                            color: isDark
                                ? GBTColors.darkTextTertiary
                                : GBTColors.textTertiary,
                          ),
                        ),
                      ),
              ),
              // EN: Title + metadata row below image.
              // KO: 이미지 아래 제목 + 메타데이터 행.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.md,
                  GBTSpacing.md,
                  GBTSpacing.md,
                  GBTSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: GBTTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? GBTColors.darkTextPrimary
                            : GBTColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    // EN: Date + link icon row for clear metadata display.
                    // KO: 명확한 메타데이터 표시를 위한 날짜 + 링크 아이콘 행.
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                        const SizedBox(width: GBTSpacing.xs),
                        Text(
                          news.dateLabel,
                          style: GBTTypography.labelSmall.copyWith(
                            color: isDark
                                ? GBTColors.darkTextTertiary
                                : GBTColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: isDark
                              ? GBTColors.darkPrimary
                              : GBTColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          context.l10n(
                            ko: '자세히 보기',
                            en: 'Read more',
                            ja: '詳しく見る',
                          ),
                          style: GBTTypography.labelSmall.copyWith(
                            color: isDark
                                ? GBTColors.darkPrimary
                                : GBTColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Compact news row for non-hero items — with calendar icon + 24h NEW badge.
/// KO: 히어로가 아닌 항목용 컴팩트 뉴스 행 — 캘린더 아이콘 + 24시간 이내 NEW 배지 포함.
class _NewsRowItem extends StatelessWidget {
  const _NewsRowItem({required this.news});
  final NewsSummary news;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbnail = news.thumbnailUrl;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    // EN: Flag as NEW if published within the last 24 hours.
    // KO: 24시간 이내 게시된 경우 NEW로 표시합니다.
    final isNew = DateTime.now().difference(news.publishedAt).inHours < 24;

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
            // EN: 80×80 rounded thumbnail.
            // KO: 80×80 둥근 썸네일.
            _NewsThumbnail(imageUrl: thumbnail),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
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
                      ),
                      if (isNew) ...[
                        const SizedBox(width: GBTSpacing.xs),
                        // EN: NEW badge — red dot for freshness signal.
                        // KO: 신선도 신호로서 빨간 NEW 배지.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: GBTColors.live,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            'NEW',
                            style: GBTTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  // EN: Date row with calendar icon for visual clarity.
                  // KO: 시각적 명확성을 위한 캘린더 아이콘 포함 날짜 행.
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: tertiaryColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        news.dateLabel,
                        style: GBTTypography.labelSmall.copyWith(
                          color: tertiaryColor,
                        ),
                      ),
                    ],
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
      semanticLabel: context.l10n(
        ko: '뉴스 썸네일',
        en: 'News thumbnail',
        ja: 'ニュースサムネイル',
      ),
    );
  }
}

/// EN: GBTShimmer-based skeleton for news loading state.
/// KO: GBTShimmer 기반 뉴스 로딩 상태 스켈레톤.
class _NewsTabSkeleton extends StatelessWidget {
  const _NewsTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return GBTShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
        children: [
          // EN: Hero card placeholder.
          // KO: 히어로 카드 플레이스홀더.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.pageHorizontal,
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: GBTShimmerContainer(
                width: double.infinity,
                height: double.infinity,
                borderRadius: GBTSpacing.radiusMd,
              ),
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.pageHorizontal,
                vertical: GBTSpacing.sm,
              ),
              child: Row(
                children: [
                  GBTShimmerContainer(
                    width: 80,
                    height: 80,
                    borderRadius: GBTSpacing.radiusMd,
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GBTShimmerContainer(
                          width: double.infinity,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        GBTShimmerContainer(
                          width: 160,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: GBTSpacing.sm),
                        GBTShimmerContainer(
                          width: 80,
                          height: 10,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EN: Units tab — wiki-style grid with expandable member/VA accordion
// KO: 유닛 탭 — 위키 스타일 그리드 + 멤버/성우 확장 아코디언
// ===========================================================================

class _UnitsTab extends ConsumerWidget {
  const _UnitsTab({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isActive) {
      return const SizedBox.shrink();
    }
    final selection = ref.watch(projectSelectionControllerProvider);
    final projectKey = selection.projectKey;

    if (projectKey == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: GBTSpacing.lg),
          GBTEmptyState(
            icon: Icons.groups_outlined,
            title: context.l10n(
              ko: '프로젝트를 먼저 선택해주세요',
              en: 'Please select a project first',
              ja: '先にプロジェクトを選択してください',
            ),
          ),
        ],
      );
    }

    final unitsState = ref.watch(projectUnitsControllerProvider(projectKey));

    return unitsState.when(
      loading: () => const _UnitsTabSkeleton(),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '유닛을 불러오지 못했어요',
                en: 'Failed to load units',
                ja: 'ユニットを読み込めませんでした',
              );
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const SizedBox(height: GBTSpacing.lg),
            GBTErrorState(
              message: message,
              onRetry: () => ref
                  .read(projectUnitsControllerProvider(projectKey).notifier)
                  .load(forceRefresh: true),
            ),
          ],
        );
      },
      data: (units) {
        if (units.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: GBTSpacing.paddingPage,
            children: [
              const SizedBox(height: GBTSpacing.lg),
              GBTEmptyState(
                icon: Icons.groups_outlined,
                title: context.l10n(
                  ko: '등록된 유닛이 없습니다',
                  en: 'No units available',
                  ja: '登録されたユニットがありません',
                ),
              ),
            ],
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: GBTSpacing.sm,
            bottom: GBTSpacing.xl,
          ),
          children: [
            // EN: Section header with unit count pill.
            // KO: 유닛 수 표시 필이 있는 섹션 헤더.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                GBTSpacing.sm,
                GBTSpacing.pageHorizontal,
                GBTSpacing.sm,
              ),
              child: _SectionHeaderWithCount(
                icon: Icons.groups_outlined,
                label: context.l10n(ko: '유닛', en: 'Units', ja: 'ユニット'),
                count: units.length,
              ),
            ),
            ...units.map(
              (unit) => _UnitAccordionCard(
                unit: unit,
                projectId: projectKey,
                paletteColor: _unitPaletteColor(unit),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// EN: Accordion-style unit card — tap to expand member/VA roster.
/// KO: 아코디언 스타일 유닛 카드 — 탭하면 멤버/성우 로스터 확장.
class _UnitAccordionCard extends ConsumerStatefulWidget {
  const _UnitAccordionCard({
    required this.unit,
    required this.projectId,
    required this.paletteColor,
  });

  final Unit unit;
  final String projectId;
  final Color paletteColor;

  @override
  ConsumerState<_UnitAccordionCard> createState() => _UnitAccordionCardState();
}

class _UnitAccordionCardState extends ConsumerState<_UnitAccordionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgAlpha = isDark ? 0.18 : 0.10;
    final borderAlpha = 0.25;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final surfaceColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final initial = widget.unit.displayName.isNotEmpty
        ? widget.unit.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _expanded
              ? widget.paletteColor.withValues(alpha: bgAlpha + 0.05)
              : (isDark ? GBTColors.darkSurface : GBTColors.surface),
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          border: Border.all(
            color: _expanded
                ? widget.paletteColor.withValues(alpha: borderAlpha + 0.1)
                : (isDark ? GBTColors.darkBorder : GBTColors.border),
          ),
          // EN: Subtle shadow adds depth to each unit card.
          // KO: 각 유닛 카드에 깊이감을 주는 미세한 그림자.
          boxShadow: isDark ? GBTShadows.darkSm : GBTShadows.sm,
        ),
        // EN: Clip prevents overflow of the left accent bar.
        // KO: 왼쪽 액센트 바의 오버플로우를 막기 위해 클립 적용.
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EN: Left palette-color accent bar for visual unit identity.
              // KO: 유닛 시각적 아이덴티티를 위한 왼쪽 팔레트 색상 액센트 바.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                color: widget.paletteColor.withValues(
                  alpha: _expanded ? 0.9 : 0.55,
                ),
              ),
              // EN: Main card content.
              // KO: 카드 메인 콘텐츠.
              Expanded(
                child: Column(
                  children: [
                    // EN: Unit header row — always visible.
                    // KO: 유닛 헤더 행 — 항상 표시.
                    InkWell(
                      onTap: _toggle,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(GBTSpacing.radiusMd),
                        bottomRight: Radius.circular(GBTSpacing.radiusMd),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(GBTSpacing.md),
                        child: Row(
                          children: [
                            // EN: Unit logo image if available, else palette initial circle.
                            // KO: 유닛 로고가 있으면 이미지, 없으면 팔레트 이니셜 원.
                            widget.unit.logoUrl != null &&
                                    widget.unit.logoUrl!.isNotEmpty
                                ? GBTImage(
                                    imageUrl: widget.unit.logoUrl!,
                                    width: 48,
                                    height: 48,
                                    borderRadius: BorderRadius.circular(
                                      GBTSpacing.radiusMd,
                                    ),
                                    fit: BoxFit.contain,
                                    semanticLabel: widget.unit.displayName,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: widget.paletteColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: GBTTypography.titleLarge
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: GBTSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.unit.displayName,
                                          style: GBTTypography.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: GBTSpacing.xs),
                                      // EN: Member count badge — shown after members loaded.
                                      // KO: 멤버 로드 후 표시되는 멤버 수 배지.
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final membersState = ref.watch(
                                            unitMembersControllerProvider((
                                              widget.projectId,
                                              widget.unit.id,
                                            )),
                                          );
                                          return membersState.maybeWhen(
                                            data: (members) => members.isEmpty
                                                ? const SizedBox.shrink()
                                                : Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: widget.paletteColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            GBTSpacing
                                                                .radiusFull,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      context.l10n(
                                                        ko: '${members.length}명',
                                                        en: '${members.length}',
                                                        ja: '${members.length}名',
                                                      ),
                                                      style: GBTTypography
                                                          .labelSmall
                                                          .copyWith(
                                                            color: widget
                                                                .paletteColor,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 10,
                                                          ),
                                                    ),
                                                  ),
                                            orElse: () =>
                                                const SizedBox.shrink(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.unit.code,
                                    style: GBTTypography.labelSmall.copyWith(
                                      color: textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // EN: Unit detail navigation button.
                            // KO: 유닛 상세 이동 버튼.
                            GestureDetector(
                              onTap: () => context.goToUnitDetail(
                                unit: widget.unit,
                                projectId: widget.projectId,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: textTertiary,
                                ),
                              ),
                            ),
                            const SizedBox(width: GBTSpacing.xs),
                            // EN: Expand/collapse chevron with rotation animation.
                            // KO: 회전 애니메이션이 있는 확장/축소 꺾쇠.
                            RotationTransition(
                              turns: Tween(
                                begin: 0.0,
                                end: 0.5,
                              ).animate(_expandAnim),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // EN: Expandable member section.
                    // KO: 확장 가능한 멤버 섹션.
                    SizeTransition(
                      sizeFactor: _expandAnim,
                      child: Column(
                        children: [
                          Divider(
                            height: 1,
                            color: isDark
                                ? GBTColors.darkBorder
                                : GBTColors.border,
                          ),
                          Container(
                            color: surfaceColor.withValues(alpha: 0.5),
                            padding: const EdgeInsets.fromLTRB(
                              GBTSpacing.md,
                              GBTSpacing.sm,
                              GBTSpacing.md,
                              GBTSpacing.md,
                            ),
                            child: _UnitMembersList(
                              projectId: widget.projectId,
                              unit: widget.unit,
                              paletteColor: widget.paletteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Inline member list loaded from API when unit is expanded.
/// KO: 유닛 확장 시 API에서 불러오는 인라인 멤버 목록.
class _UnitMembersList extends ConsumerWidget {
  const _UnitMembersList({
    required this.projectId,
    required this.unit,
    required this.paletteColor,
  });

  final String projectId;
  final Unit unit;
  final Color paletteColor;

  String get unitId => unit.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(
      unitMembersControllerProvider((projectId, unitId)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return membersState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
        child: Text(
          context.l10n(
            ko: '멤버 정보를 불러오지 못했어요',
            en: 'Failed to load members',
            ja: 'メンバー情報を読み込めませんでした',
          ),
          style: GBTTypography.labelSmall.copyWith(
            color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          ),
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            child: Text(
              context.l10n(
                ko: '멤버 정보가 없습니다',
                en: 'No member information',
                ja: 'メンバー情報がありません',
              ),
              style: GBTTypography.labelSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textTertiary,
              ),
            ),
          );
        }

        // EN: Sort by order field if available, then alphabetically.
        // KO: order 필드 기준으로 정렬하고, 없으면 이름 순.
        final sorted = [...members]
          ..sort((a, b) {
            if (a.order != null && b.order != null) {
              return a.order!.compareTo(b.order!);
            }
            return a.name.compareTo(b.name);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EN: Section label with palette color accent and mic icon.
            // KO: 팔레트 색상 액센트와 마이크 아이콘이 있는 섹션 레이블.
            Padding(
              padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 13, color: paletteColor),
                  const SizedBox(width: GBTSpacing.xs),
                  Text(
                    context.l10n(
                      ko: '멤버 · 성우',
                      en: 'Members · Voice actors',
                      ja: 'メンバー・声優',
                    ),
                    style: GBTTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: paletteColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            ...sorted.map(
              (m) => _MemberInlineRow(
                member: m,
                unit: unit,
                projectId: projectId,
                paletteColor: paletteColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// EN: Single member row inside unit accordion — avatar, name+VA, role, tappable.
/// KO: 유닛 아코디언 내 단일 멤버 행 — 아바타, 이름+성우, 역할, 탭 가능.
class _MemberInlineRow extends StatelessWidget {
  const _MemberInlineRow({
    required this.member,
    required this.unit,
    required this.projectId,
    required this.paletteColor,
  });

  final UnitMember member;
  final Unit unit;
  final String projectId;
  final Color paletteColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final initial = member.name.isNotEmpty ? member.name[0] : '?';

    return InkWell(
      onTap: () => context.goToMemberDetail(
        unit: unit,
        member: member,
        projectId: projectId,
      ),
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: GBTSpacing.xs,
          horizontal: 2,
        ),
        child: Row(
          children: [
            // EN: Small member avatar with image or palette initial.
            // KO: 이미지 또는 팔레트 이니셜이 있는 작은 멤버 아바타.
            _MemberAvatar(
              imageUrl: member.imageUrl,
              initial: initial,
              paletteColor: paletteColor,
              size: 36,
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN: Character name + VA name on same line for quick scan.
                  // KO: 빠른 스캔을 위해 캐릭터명 + 성우명을 한 줄에 표시.
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: GBTTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      if (member.voiceActorName != null &&
                          member.voiceActorName!.isNotEmpty) ...[
                        const SizedBox(width: GBTSpacing.xs),
                        Container(
                          width: 1,
                          height: 11,
                          color: textTertiary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: GBTSpacing.xs),
                        Icon(
                          Icons.mic_rounded,
                          size: 11,
                          color: paletteColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            member.voiceActorName!,
                            style: GBTTypography.labelSmall.copyWith(
                              color: textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // EN: Role / instrument tags row.
                  // KO: 역할 / 악기 태그 행.
                  if (member.instrument != null || member.role != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          if (member.instrument != null) ...[
                            _MiniTag(
                              label: member.instrument!,
                              color: paletteColor,
                            ),
                            const SizedBox(width: GBTSpacing.xs),
                          ],
                          if (member.role != null &&
                              member.role != member.instrument)
                            _MiniTag(label: member.role!, color: paletteColor),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: textTertiary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: Small tag chip for role / instrument labels inside member rows.
/// KO: 멤버 행 내 역할/악기 레이블용 작은 태그 칩.
class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: GBTTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _UnitsTabSkeleton extends StatelessWidget {
  const _UnitsTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return GBTShimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(GBTSpacing.md),
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
            child: GBTShimmerContainer(
              width: double.infinity,
              height: 72,
              borderRadius: GBTSpacing.radiusMd,
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Member avatar widget — shows network image or palette initial fallback.
/// KO: 멤버 아바타 위젯 — 네트워크 이미지 또는 팔레트 이니셜 폴백.
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.imageUrl,
    required this.initial,
    required this.paletteColor,
    required this.size,
  });

  final String? imageUrl;
  final String initial;
  final Color paletteColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasImage) {
      return GBTImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        fit: BoxFit.cover,
        semanticLabel:
            '$initial ${context.l10n(ko: "멤버 이미지", en: "member image", ja: "メンバー画像")}',
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: paletteColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// EN: Shared section header widgets used across tabs.
// KO: 탭 공통 섹션 헤더 위젯.
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 15, color: primary),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          label,
          style: GBTTypography.labelLarge.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderWithCount extends StatelessWidget {
  const _SectionHeaderWithCount({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final metaColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 15, color: primary),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          label,
          style: GBTTypography.labelLarge.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          '($count)',
          style: GBTTypography.labelSmall.copyWith(color: metaColor),
        ),
      ],
    );
  }
}

// ===========================================================================
// EN: More tab — entry cards for cheer guides, quotes, and zukan.
// KO: 더보기 탭 — 응원가이드, 명언, 도감 진입 카드.
// ===========================================================================

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    final entries = [
      (
        icon: Icons.celebration_outlined,
        // EN: Pink — matches the celebratory / live cheer theme.
        // KO: 핑크 — 라이브 응원 테마와 어울리는 색상.
        color: isDark ? GBTColors.darkSecondary : GBTColors.secondary,
        label: context.l10n(ko: '응원가이드', en: 'Cheer Guides', ja: '応援ガイド'),
        subtitle: context.l10n(
          ko: '이벤트에서 응원하는 법을 알아보세요',
          en: 'Learn how to cheer at events',
          ja: 'イベントの応援方法を確認',
        ),
        routeName: AppRoutes.cheerGuides,
      ),
      (
        icon: Icons.format_quote_outlined,
        // EN: Amber — warm tone for memorable quotes.
        // KO: 앰버 — 명대사에 어울리는 따뜻한 색상.
        color: isDark ? GBTColors.darkAccent : GBTColors.accent,
        label: context.l10n(ko: '명대사', en: 'Quotes', ja: '名言・名台詞'),
        subtitle: context.l10n(
          ko: '캐릭터들의 인상적인 대사 모음',
          en: 'Memorable lines from characters',
          ja: 'キャラクターの印象的なセリフ',
        ),
        routeName: AppRoutes.quotes,
      ),
      (
        icon: Icons.collections_outlined,
        // EN: Teal — collection / completionist feel.
        // KO: 틸 — 컬렉션/도감 완성 느낌의 색상.
        color: isDark
            ? GBTSemanticColors.darkMetadataDistance
            : GBTColors.accentTeal,
        label: context.l10n(ko: '도감', en: 'Zukan', ja: '図鑑'),
        subtitle: context.l10n(
          ko: '캐릭터 & 아이템 컬렉션을 확인하세요',
          en: 'Browse your character & item collection',
          ja: 'キャラクター＆アイテムコレクションを確認',
        ),
        routeName: AppRoutes.zukan,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.md,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: GBTSpacing.sm),
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pushNamed(entry.routeName),
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.md,
                vertical: GBTSpacing.sm2,
              ),
              decoration: GBTDecorations.card(isDark: isDark),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 22),
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.label,
                          style: GBTTypography.bodyMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.subtitle,
                          style: GBTTypography.bodySmall.copyWith(
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// EN: Info page project selector — solid primary pill chip (same style as
//     explore/live pages).
// KO: 정보 페이지 프로젝트 선택기 — 탐방/라이브 페이지와 동일한 solid primary 필 칩.
// ============================================================

class _InfoProjectChip extends ConsumerWidget {
  const _InfoProjectChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    final label = projectsState.maybeWhen(
      data: (projects) {
        if (projects.isEmpty) {
          return context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
        }
        // EN: Auto-select first project when none is stored.
        // KO: 저장된 프로젝트가 없으면 첫 번째 프로젝트를 자동 선택합니다.
        if (selection.projectKey == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final first = projects.first;
            final key = first.code.isNotEmpty ? first.code : first.id;
            ref
                .read(projectSelectionControllerProvider.notifier)
                .selectProject(key, projectId: first.id);
          });
        }
        final selected = projects.cast<Project?>().firstWhere(
          (p) =>
              p?.code == selection.projectKey || p?.id == selection.projectKey,
          orElse: () => projects.first,
        );
        return selected?.name ??
            context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
      },
      orElse: () => context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
    );

    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final textColor = isDark ? GBTColors.darkBackground : Colors.white;

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _InfoProjectPickerSheet(),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GBTTypography.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: textColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoProjectPickerSheet extends ConsumerWidget {
  const _InfoProjectPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          0,
          GBTSpacing.md,
          GBTSpacing.md,
        ),
        child: projectsState.when(
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n(
                  ko: '프로젝트 선택',
                  en: 'Select project',
                  ja: 'プロジェクト選択',
                ),
                style: GBTTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GBTSpacing.md),
              GBTLoading(
                message: context.l10n(
                  ko: '프로젝트를 불러오는 중...',
                  en: 'Loading projects...',
                  ja: 'プロジェクトを読み込み中...',
                ),
              ),
              const SizedBox(height: GBTSpacing.md),
            ],
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (projects) {
            if (projects.isEmpty) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n(
                    ko: '프로젝트 선택',
                    en: 'Select project',
                    ja: 'プロジェクト選択',
                  ),
                  style: GBTTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final key = project.code.isNotEmpty
                          ? project.code
                          : project.id;
                      final isSelected =
                          selection.projectKey == key ||
                          selection.projectKey == project.id;
                      final primaryColor = Theme.of(
                        context,
                      ).colorScheme.primary;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryColor : null,
                        ),
                        title: Text(project.name),
                        onTap: () {
                          ref
                              .read(projectSelectionControllerProvider.notifier)
                              .selectProject(key, projectId: project.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// EN: Resolves unit palette color — uses colorHex if available, else seeds from display name.
/// KO: 유닛 팔레트 색상 결정 — colorHex가 있으면 사용, 없으면 displayName에서 시드 생성.
Color _unitPaletteColor(Unit unit) {
  final hex = unit.colorHex;
  if (hex != null && hex.isNotEmpty) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
  }
  return paletteColorFromSeed(unit.displayName);
}
