/// EN: Home page — greeting header + carousels + compact news
/// KO: 홈 페이지 — 인사말 헤더 + 캐러셀 + 컴팩트 뉴스
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/a11y_wrapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/animations/staggered_list_item.dart';
import '../../../../core/widgets/cards/gbt_event_card_carousel.dart';
import '../../../../core/widgets/cards/gbt_place_card_carousel.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/layout/gbt_carousel_section.dart';
import '../../../../core/widgets/layout/gbt_glass_panel.dart';
import '../../../../core/widgets/layout/gbt_greeting_header.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_profile_action.dart';
import '../../../ads/domain/entities/ad_slot_entities.dart';
import '../../../profile_banner/application/banner_controller.dart';
import '../../../ads/presentation/widgets/hybrid_sponsored_slot.dart';
import '../../../home_banners/presentation/widgets/home_banner_carousel.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../projects/presentation/widgets/project_selector.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/home_controller.dart';
import '../../domain/entities/home_summary.dart';

/// EN: Home page widget — CustomScrollView with greeting header + carousels
/// KO: 홈 페이지 위젯 — 인사말 헤더 + 캐러셀을 갖춘 CustomScrollView
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!mounted) return;
      final isScrolled =
          _scrollController.hasClients && _scrollController.offset > 50;
      if (isScrolled != _isScrolled) {
        setState(() => _isScrolled = isScrolled);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // EN: Eagerly initialize project selection — prevents deadlock where
    // HomeController waits for selectedProjectKey but ProjectSelector only
    // renders after content loads.
    // KO: 프로젝트 선택을 즉시 초기화 — HomeController가 selectedProjectKey를
    // 기다리지만 ProjectSelector가 콘텐츠 로드 후에만 렌더링되는 데드락 방지.
    ref.watch(projectSelectionControllerProvider);
    final selectedProjectKey = ref.watch(selectedProjectKeyProvider);
    final isProjectSelected = selectedProjectKey?.isNotEmpty == true;
    final projectsState = ref.watch(projectsControllerProvider);
    final state = ref.watch(homeControllerProvider);
    final userProfile = ref.watch(userProfileControllerProvider).valueOrNull;
    final avatarUrl = userProfile?.avatarUrl;
    final nickname = userProfile?.displayName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final activeBanner = ref.watch(activeBannerProvider).valueOrNull;

    final appBarBgColor = _isScrolled
        ? (isDark ? GBTColors.darkSurface : Colors.white).withValues(alpha: 0.8)
        : Colors.transparent;
    final appBarFgColor = _isScrolled
        ? (isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary)
        : Colors.white;
    final appBarOverlayStyle = _isScrolled
        ? (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        : SystemUiOverlayStyle.light;
    final appBarTitleStyle = GBTTypography.titleMedium.copyWith(
      color: appBarFgColor,
      fontWeight: FontWeight.w700,
      shadows: _isScrolled
          ? null
          : const [
              Shadow(
                color: Color(0x70000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
    );
    final appBarActionIconColor = appBarFgColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('oshi@log'),
        titleTextStyle: appBarTitleStyle,
        backgroundColor: appBarBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: appBarFgColor,
        iconTheme: IconThemeData(color: appBarActionIconColor),
        actionsIconTheme: IconThemeData(color: appBarActionIconColor),
        systemOverlayStyle: appBarOverlayStyle,
        flexibleSpace: _isScrolled
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const SizedBox.expand(),
                ),
              )
            : null,
        actions: [
          // EN: Search/notifications live in the floating glass pill over the
          // greeting gradient while unscrolled; the AppBar only needs them
          // once that pill has scrolled out of view, to avoid duplicate
          // affordances on screen at once.
          // KO: 스크롤 전에는 검색/알림이 인사말 그라디언트 위 플로팅 글래스
          // 필에 있음. 필이 화면 밖으로 스크롤된 뒤에만 AppBar에도 노출해
          // 화면에 동일 기능이 중복 표시되지 않도록 합니다.
          if (_isScrolled) ...[
            GBTAppBarIconButton(
              icon: Icons.search,
              iconColor: appBarActionIconColor,
              onPressed: () => context.goToSearch(),
              tooltip: context.l10n(ko: '검색', en: 'Search', ja: '検索'),
            ),
            GBTAppBarIconButton(
              icon: Icons.notifications_outlined,
              iconColor: appBarActionIconColor,
              onPressed: () => context.push('/notifications'),
              tooltip: context.l10n(ko: '알림', en: 'Notifications', ja: '通知'),
            ),
          ],
          if (!_isScrolled)
            GBTProfileAction(
              avatarUrl: avatarUrl,
              placeholderBackgroundColor: Colors.black.withValues(alpha: 0.26),
              placeholderIconColor: Colors.white.withValues(alpha: 0.94),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GBTProfileAction(
                avatarUrl: avatarUrl,
                placeholderIconColor: appBarActionIconColor.withValues(
                  alpha: 0.9,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(homeControllerProvider.notifier).load(forceRefresh: true),
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        child: !isProjectSelected
            ? _buildProjectGate(projectsState)
            : state.when(
                loading: () => _buildLoading(),
                error: (error, _) => _buildError(error),
                data: (summary) => _buildContent(
                  summary,
                  nickname,
                  userBannerUrl: activeBanner?.imageUrl,
                  isAuthenticated: isAuthenticated,
                ),
              ),
      ),
    );
  }

  Widget _buildProjectGate(AsyncValue<List<Project>> projectsState) {
    return projectsState.when(
      loading: _buildLoading,
      error: (error, _) => _buildError(
        error,
        onRetry: () {
          ref
              .read(projectsControllerProvider.notifier)
              .load(forceRefresh: true);
          ref.read(homeControllerProvider.notifier).load(forceRefresh: true);
        },
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return _buildError(
            const ValidationFailure(
              'No projects available',
              code: 'projects_empty',
            ),
            onRetry: () => ref
                .read(projectsControllerProvider.notifier)
                .load(forceRefresh: true),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final current = ref.read(selectedProjectKeyProvider);
          if (current != null && current.isNotEmpty) {
            return;
          }
          final first = projects.first;
          final firstProjectKey = first.code.isNotEmpty ? first.code : first.id;
          ref
              .read(projectSelectionControllerProvider.notifier)
              .selectProject(firstProjectKey, projectId: first.id);
        });

        return _buildLoading();
      },
    );
  }

  Widget _buildLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // EN: Spacer for SliverAppBar overlap
        // KO: SliverAppBar 겹침을 위한 스페이서
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
        ),
        // EN: Greeting header shimmer placeholder
        // KO: 인사말 헤더 쉬머 플레이스홀더
        SliverToBoxAdapter(
          child: GBTShimmer(
            child: Container(
              height: 100,
              color: isDark
                  ? GBTColors.darkSurfaceVariant
                  : GBTColors.primaryLight,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: GBTSpacing.sectionSpacingLg),
        ),
        // EN: Carousel shimmer placeholders
        // KO: 캐러셀 쉬머 플레이스홀더
        SliverToBoxAdapter(child: _buildCarouselShimmer(isDark)),
        const SliverToBoxAdapter(
          child: SizedBox(height: GBTSpacing.sectionSpacingLg),
        ),
        SliverToBoxAdapter(child: _buildCarouselShimmer(isDark)),
      ],
    );
  }

  Widget _buildCarouselShimmer(bool isDark) {
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
          ),
          child: GBTShimmer(
            child: Container(
              height: 22,
              width: 120,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
              ),
            ),
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.pageHorizontal,
            ),
            itemCount: 4,
            separatorBuilder: (_, __) =>
                const SizedBox(width: GBTSpacing.carouselItemGap),
            itemBuilder: (_, __) => GBTShimmer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error, {VoidCallback? onRetry}) {
    final message = error is Failure
        ? error.userMessage
        : context.l10n(
            ko: '홈 정보를 불러오지 못했어요',
            en: 'Failed to load home content',
            ja: 'ホーム情報を読み込めませんでした',
          );
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: GBTErrorState(
            message: message,
            onRetry:
                onRetry ??
                () => ref
                    .read(homeControllerProvider.notifier)
                    .load(forceRefresh: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    HomeSummary summary,
    String? nickname, {
    String? userBannerUrl,
    bool isAuthenticated = false,
  }) {
    final featuredLive = _pickFeaturedLive(summary.trendingLiveEvents);
    final headerImageUrl = _pickHeaderImage(summary, featuredLive);
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. GBTGreetingHeader — greeting area, with a floating glass
        //    search/notification pill layered over the gradient.
        // KO: GBTGreetingHeader — 인사말 영역. 그라디언트 위에 플로팅
        //    글래스 검색/알림 필을 겹쳐 배치.
        SliverToBoxAdapter(
          child: Stack(
            children: [
              GBTGreetingHeader(
                userName: nickname,
                backgroundImageUrl: headerImageUrl,
                userBannerUrl: userBannerUrl,
                featuredTitle: featuredLive?.title,
                featuredDate: featuredLive?.dateLabel,
                featuredPosterUrl: featuredLive?.posterUrl,
                onFeaturedTap: featuredLive == null
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(analyticsServiceProvider)
                              .logLiveEventView(
                                featuredLive.id,
                                eventName: featuredLive.title,
                              ),
                        );
                        context.goToEventDetail(featuredLive.id);
                      },
                onCustomizeTap: isAuthenticated
                    ? () => context.push('/banner-picker')
                    : null,
              ),
              Positioned(
                top: topPadding + kToolbarHeight + GBTSpacing.sm,
                left: GBTSpacing.pageHorizontal,
                right: GBTSpacing.pageHorizontal,
                child: _GreetingGlassPill(
                  onSearchTap: () => context.goToSearch(),
                  onNotificationsTap: () => context.push('/notifications'),
                ),
              ),
            ],
          ),
        ),

        // 2. Project switcher — the scope selector sits directly under the
        //    header WITH a label, so users understand it filters the whole
        //    page before they reach the content it scopes (Weverse pattern).
        // KO: 프로젝트 스위처 — 스코프 셀렉터를 라벨과 함께 헤더 바로 아래
        //    배치. 필터 대상 콘텐츠보다 먼저 스코프를 선언합니다 (위버스
        //    패턴).
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.pageHorizontal,
                  ),
                  child: Text(
                    context.l10n(
                      ko: '지금 보는 밴드',
                      en: 'Now following',
                      ja: '今見ているバンド',
                    ),
                    style: GBTTypography.labelMedium.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                const ProjectSelector(),
              ],
            ),
          ),
        ),

        // 3. Bento quick-action grid — a large "near you" tile plus three
        //    compact shortcuts (guide book, calendar, live), replacing the
        //    monotony of a single carousel with an anchor grid.
        // KO: 벤토 퀵 액션 그리드 — 큰 "내 주변" 타일 + 도감/캘린더/라이브
        //    축약 타일 3개. 단조로운 캐러셀 대신 벤토 앵커를 배치합니다.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              GBTSpacing.lg,
              GBTSpacing.pageHorizontal,
              0,
            ),
            child: const _QuickActionBento(),
          ),
        ),

        // EN: Full-bleed promo banner rail — breaks the rhythm between the
        //     bento grid above and the content rails below.
        // KO: 전체 폭 프로모 배너 레일 — 위쪽 벤토 그리드와 아래 콘텐츠
        //     레일 사이에서 리듬을 환기합니다.
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: GBTSpacing.lg),
            child: HomeBannerCarousel(),
          ),
        ),

        // EN: Hard empty state (no cards + no source data)
        // KO: 완전 빈 상태 (카드/원천 데이터 모두 없음)
        if (summary.shouldShowNoContentEmptyState)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: GBTSpacing.xl),
              child: GBTEmptyState(
                icon: Icons.auto_awesome_mosaic_outlined,
                title: context.l10n(
                  ko: '표시할 홈 콘텐츠가 없습니다',
                  en: 'No home content available',
                  ja: '表示できるホームコンテンツがありません',
                ),
              ),
            ),
          ),
        // EN: Soft empty state (cards empty but source rows exist)
        // KO: 소프트 빈 상태 (카드는 비었지만 원천 데이터가 존재)
        if (summary.shouldShowFilteredEmptyState)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: GBTSpacing.xl),
              child: GBTEmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: context.l10n(
                  ko: '조건에 맞는 최신 항목이 없습니다',
                  en: 'No recent items match current conditions',
                  ja: '条件に合う最新項目がありません',
                ),
              ),
            ),
          ),

        // 4. Near-you places band — visually distinct tinted rail (mint/teal
        //    accent) instead of a plain rail, to vary section rhythm.
        // KO: 내 주변 성지 밴드 — 리듬 변화를 위해 민트/틸 톤 배경을 입힌
        //    시각적으로 구분되는 레일.
        if (summary.recommendedPlaces.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SizedBox(
              height: GBTResponsiveSpacing.responsiveSectionSpacing(context),
            ),
          ),
          SliverToBoxAdapter(
            child: _NearbyPlacesBand(
              child: GBTCarouselSection(
                // EN: Honest label — this rail is recommendation data, not
                //     GPS-based; "near you" belongs to the bento map tile.
                // KO: 정직한 라벨 — 이 레일은 추천 데이터이지 GPS 기반이
                //     아니므로 "내 주변"은 벤토 지도 타일에만 사용합니다.
                title: context.l10n(
                  ko: '추천 성지',
                  en: 'Recommended',
                  ja: 'おすすめ聖地',
                ),
                itemCount: summary.recommendedPlaces.length,
                itemHeight: 220,
                onSeeAll: () => context.go('/explore'),
                itemBuilder: (context, index) {
                  final place = summary.recommendedPlaces[index];
                  return GBTPlaceCardCarousel(
                    placeId: place.id,
                    name: place.name,
                    location:
                        place.location ??
                        context.l10n(
                          ko: '방문 ${place.visitCount}회',
                          en: '${place.visitCount} visits',
                          ja: '${place.visitCount}回訪問',
                        ),
                    imageUrl: place.imageUrl,
                    onTap: () {
                      unawaited(
                        ref
                            .read(analyticsServiceProvider)
                            .logPlaceVisit(place.id, placeName: place.name),
                      );
                      context.goToPlaceDetail(place.id);
                    },
                  );
                },
              ),
            ),
          ),
        ],

        // 5. Trending live events carousel
        if (summary.trendingLiveEvents.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SizedBox(
              height: GBTResponsiveSpacing.responsiveSectionSpacing(context),
            ),
          ),
          SliverToBoxAdapter(
            child: GBTCarouselSection(
              title: context.l10n(
                ko: '트렌딩 이벤트',
                en: 'Trending Live',
                ja: 'トレンドライブ',
              ),
              itemCount: summary.trendingLiveEvents.length,
              itemHeight: 220,
              onSeeAll: () => context.go('/explore?tab=1'),
              itemBuilder: (context, index) {
                final event = summary.trendingLiveEvents[index];
                return GBTEventCardCarousel(
                  title: event.title,
                  date: event.dateLabel,
                  posterUrl: event.posterUrl,
                  isLive: event.isLive,
                  onTap: () {
                    unawaited(
                      ref
                          .read(analyticsServiceProvider)
                          .logLiveEventView(event.id, eventName: event.title),
                    );
                    context.goToEventDetail(event.id);
                  },
                );
              },
            ),
          ),
        ],

        // EN: Single native sponsored slot — demoted BELOW the primary
        //     content rails per KR home convention (ads never above content).
        // KO: 네이티브 스폰서 슬롯 1개 — 한국 홈 컨벤션에 따라 주요 콘텐츠
        //     레일 아래로 강등 (광고는 콘텐츠 위에 두지 않음).
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.lg),
            child: _HomeSponsoredSlot(onTap: () => context.go('/explore')),
          ),
        ),

        // 6. Latest news — compact borderless list
        if (summary.latestNews.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SizedBox(
              height: GBTResponsiveSpacing.responsiveSectionSpacing(context),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: context.l10n(ko: '최신 소식', en: 'Latest News', ja: '最新ニュース'),
              onSeeAll: () => context.go('/info'),
            ),
          ),
          SliverList.builder(
            itemCount: summary.latestNews.take(5).length,
            itemBuilder: (context, index) {
              final news = summary.latestNews[index];
              final delay = GBTStaggerAnimations.delayFor(index);

              // EN: Wrap in StaggeredListItem for fade + slide animation
              // KO: fade + slide 애니메이션을 위해 StaggeredListItem으로 래핑
              return StaggeredListItem(
                key: ValueKey(news.id),
                delay: delay,
                child: _CompactNewsTile(item: news),
              );
            },
          ),
        ],

        // 7. Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(
            height: GBTSpacing.xxl + MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }

  HomeEventItem? _pickFeaturedLive(List<HomeEventItem> events) {
    if (events.isEmpty) {
      return null;
    }
    for (final event in events) {
      if (_hasText(event.posterUrl)) {
        return event;
      }
    }
    return events.first;
  }

  String? _pickHeaderImage(HomeSummary summary, HomeEventItem? featuredLive) {
    final candidates = <String?>[
      featuredLive?.posterUrl,
      ...summary.trendingLiveEvents.map((event) => event.posterUrl),
      ...summary.recommendedPlaces.map((place) => place.imageUrl),
      ...summary.latestNews.map((news) => news.imageUrl),
    ];
    for (final candidate in candidates) {
      if (_hasText(candidate)) {
        return candidate!.trim();
      }
    }
    return null;
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

/// EN: Home sponsored slot card shown once per screen build.
/// KO: 화면당 한 번만 노출되는 홈 스폰서 슬롯 카드입니다.
class _HomeSponsoredSlot extends StatelessWidget {
  const _HomeSponsoredSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HybridSponsoredSlot(
      request: const AdSlotRequest(placement: AdSlotPlacement.homePrimary),
      noDecisionStrategy: NoDecisionStrategy.house,
      deliveryNoneStrategy: DeliveryNoneStrategy.fallback,
      fallback: SponsoredFallbackContent(
        badgeLabel: context.l10n(ko: '광고', en: 'AD', ja: '広告'),
        sponsorLabel: context.l10n(
          ko: 'oshi@log 추천',
          en: 'oshi@log Sponsored',
          ja: 'oshi@log スポンサー',
        ),
        title: context.l10n(
          ko: '성지 방문 전, 장소 태그와 동선을 먼저 확인해보세요',
          en: 'Check place tags and routes before your visit',
          ja: '聖地訪問前に場所タグと動線を確認しましょう',
        ),
        description: context.l10n(
          ko: '근처 장소를 빠르게 비교해 오늘 동선을 자연스럽게 정할 수 있어요.',
          en: 'Compare nearby places quickly and plan today\'s route naturally.',
          ja: '近くの場所をすぐ比較して今日の動線を自然に決められます。',
        ),
        ctaLabel: context.l10n(
          ko: '장소 탐색 시작',
          en: 'Start Exploring Places',
          ja: '場所探索を開始',
        ),
        icon: Icons.map_outlined,
        accentColor: GBTColors.accentTeal,
        onTap: onTap,
      ),
      margin: const EdgeInsets.symmetric(horizontal: GBTSpacing.pageHorizontal),
    );
  }
}

/// EN: Floating glass pill layered over the greeting gradient — carries the
/// search and notifications affordances while the AppBar is fully
/// transparent (single glass surface, perf-conscious).
/// KO: 인사말 그라디언트 위에 얹힌 플로팅 글래스 필 — AppBar가 완전히
/// 투명한 동안 검색/알림 기능을 담당합니다 (단일 글래스 표면, 성능 고려).
class _GreetingGlassPill extends StatelessWidget {
  const _GreetingGlassPill({
    required this.onSearchTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return GBTGlassPanel(
      borderRadius: GBTSpacing.radiusFull,
      tintOpacity: 0.2,
      padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: context.l10n(ko: '검색', en: 'Search', ja: '検索'),
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 18),
                      const SizedBox(width: GBTSpacing.xs),
                      Flexible(
                        child: Text(
                          context.l10n(
                            ko: '탐비 검색',
                            en: 'Search Tabi',
                            ja: 'タビを検索',
                          ),
                          style: GBTTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: context.l10n(ko: '알림', en: 'Notifications', ja: '通知'),
            child: InkWell(
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              child: const Padding(
                padding: EdgeInsets.all(GBTSpacing.sm),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Bento quick-action grid — one large "near you" tile + three compact
/// shortcuts (guide book, calendar, live). Tinted layer surfaces, not glass —
/// this section sits in a scrollable list context.
/// KO: 벤토 퀵 액션 그리드 — 큰 "내 주변" 타일 1개 + 도감/캘린더/라이브
/// 축약 타일 3개. 리스트 컨텍스트이므로 글래스 대신 틴트 레이어 표면 사용.
class _QuickActionBento extends StatelessWidget {
  const _QuickActionBento();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _BentoTile(
          icon: Icons.map_rounded,
          label: context.l10n(ko: '내 주변 성지', en: 'Near You', ja: '近くの聖地'),
          color: GBTColors.accentTeal,
          isDark: isDark,
          large: true,
          onTap: () => context.go('/explore'),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.photo_album_rounded,
                label: context.l10n(ko: '도감', en: 'Guide', ja: '図鑑'),
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                isDark: isDark,
                onTap: () => context.push('/zukan'),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: _BentoTile(
                icon: Icons.calendar_month_rounded,
                label: context.l10n(ko: '캘린더', en: 'Calendar', ja: 'カレンダー'),
                color: isDark ? GBTColors.darkAccent : GBTColors.accent,
                isDark: isDark,
                onTap: () => context.push('/calendar'),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: _BentoTile(
                icon: Icons.live_tv_rounded,
                label: context.l10n(ko: '라이브', en: 'Live', ja: 'ライブ'),
                color: GBTColors.live,
                isDark: isDark,
                onTap: () => context.go('/explore?tab=1'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// EN: Single bento tile — the large variant lays out icon + label + chevron
/// horizontally; the compact variant stacks icon above label for narrow
/// grid cells.
/// KO: 벤토 타일 단일 컴포넌트 — large 변형은 아이콘+라벨+화살표를 가로로,
/// 컴팩트 변형은 좁은 그리드 셀에 맞춰 아이콘/라벨을 세로로 배치합니다.
class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    // EN: Neutral surface + hairline border — color lives only in the icon
    //     chip so the grid reads crafted instead of pastel-washed.
    // KO: 뉴트럴 표면 + 헤어라인 보더 — 컬러는 아이콘 칩에만 두어 그리드가
    //     파스텔 범벅 대신 정제된 인상을 주도록 합니다.
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surface;
    final borderColor = isDark
        ? GBTColors.darkBorderSubtle
        : GBTColors.border.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          child: Container(
            // EN: minHeight (not a fixed height) — the tile grows with large
            //     accessibility text scales instead of overflowing.
            // KO: 고정 높이 대신 minHeight — 접근성 텍스트 스케일이 커져도
            //     오버플로우 없이 타일이 늘어납니다.
            constraints: BoxConstraints(minHeight: large ? 88 : 96),
            padding: const EdgeInsets.all(GBTSpacing.md),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: large
                ? Row(
                    children: [
                      GBTIconChip(icon: icon, color: color, size: 44),
                      const SizedBox(width: GBTSpacing.md2),
                      Expanded(
                        child: Text(
                          label,
                          style: GBTTypography.titleMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? GBTColors.darkTextTertiary
                            : GBTColors.textTertiary,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GBTIconChip(icon: icon, color: color, size: 40),
                      const SizedBox(height: GBTSpacing.xs2),
                      Text(
                        label,
                        style: GBTTypography.labelMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// EN: Soft mint-tinted band wrapping the "near you" places rail — the one
///     section on the page that intentionally breaks the plain-white rail
///     pattern used by every other carousel.
/// KO: "내 주변 성지" 레일을 감싸는 부드러운 민트 톤 밴드 — 다른 모든
///     캐러셀이 사용하는 흰 배경 레일 패턴을 의도적으로 깨는 유일한 섹션.
class _NearbyPlacesBand extends StatelessWidget {
  const _NearbyPlacesBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = GBTColors.accentTeal.withValues(alpha: isDark ? 0.10 : 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.lg),
      color: tint,
      child: child,
    );
  }
}

/// EN: Section header widget — headlineLarge style
/// KO: 섹션 헤더 위젯 — headlineLarge 스타일
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // EN: Wrap section title in A11yHeading for proper heading hierarchy
          // KO: 적절한 heading 계층을 위해 섹션 제목을 A11yHeading으로 래핑
          A11yHeading(
            level: 2,
            child: Text(
              title,
              style: GBTTypography.headlineLarge.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
          ),
          Semantics(
            label:
                '$title ${context.l10n(ko: "전체 보기", en: "see all", ja: "すべて見る")}',
            button: true,
            child: TextButton(
              onPressed: onSeeAll,
              child: Text(
                context.l10n(ko: '전체 보기', en: 'See all', ja: 'すべて見る'),
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Compact borderless news tile — 56x56 thumbnail + title, no Card wrapper
/// KO: 컴팩트 무테두리 뉴스 타일 — 56x56 썸네일 + 제목, Card 래퍼 없음
class _CompactNewsTile extends StatelessWidget {
  const _CompactNewsTile({required this.item});

  final HomeNewsItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: item.title,
      hint: context.l10n(
        ko: '탭하면 뉴스 상세로 이동합니다',
        en: 'Tap to open news details',
        ja: 'タップしてニュース詳細へ移動',
      ),
      button: true,
      child: InkWell(
        onTap: () => context.goToNewsDetail(item.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
            vertical: GBTSpacing.sm,
          ),
          child: Row(
            children: [
              // EN: 56x56 thumbnail
              // KO: 56x56 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: item.imageUrl != null
                      ? GBTImage(
                          imageUrl: item.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          semanticLabel:
                              '${item.title} ${context.l10n(ko: "뉴스 썸네일", en: "news thumbnail", ja: "ニュースサムネイル")}',
                          useShimmer: false,
                        )
                      : Container(
                          color: isDark
                              ? GBTColors.darkSurfaceVariant
                              : GBTColors.primaryLight,
                          child: Icon(
                            Icons.article_outlined,
                            color: isDark
                                ? GBTColors.darkTextTertiary
                                : GBTColors.primaryMuted,
                            size: 24,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              // EN: Title + optional summary
              // KO: 제목 + 선택적 요약
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: isDark
                            ? GBTColors.darkTextPrimary
                            : GBTColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.summary != null) ...[
                      const SizedBox(height: GBTSpacing.xxs),
                      Text(
                        item.summary!,
                        style: GBTTypography.bodySmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextSecondary
                              : GBTColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
