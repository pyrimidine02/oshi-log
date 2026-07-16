/// EN: Board page showing community posts with Toss-style minimal design.
/// KO: 토스 스타일 미니멀 디자인의 커뮤니티 게시글을 표시하는 게시판 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/localization/locale_text.dart';
import 'package:focus_detector/focus_detector.dart';
import '../../../../core/security/user_access_level.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/image_url_extractor.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_action_icons.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/sheets/gbt_bottom_sheet.dart';
import '../../../ads/domain/entities/ad_slot_entities.dart';
import '../../../ads/presentation/widgets/hybrid_sponsored_slot.dart';
import '../../../projects/presentation/widgets/project_selector.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/community_ban_view_helper.dart';
import '../../application/community_moderation_controller.dart';
import '../../application/feed_controller.dart';
import '../../application/local_post_bookmarks_controller.dart';
import '../../application/report_rate_limiter.dart';
import '../../application/travel_reviews_controller.dart';
import '../../application/user_follow_list_controller.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/entities/feed_entities.dart';
import '../../domain/entities/travel_review.dart';
import '../models/feed_native_ad_placement.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../widgets/community_translation_panel.dart';
import '../widgets/community_report_sheet.dart';
import '../widgets/community_fab_layout.dart';
import '../../../titles/application/titles_controller.dart';
import '../../../titles/presentation/widgets/active_title_badge.dart';

// ========================================
// EN: Board Page — section-driven by sub bottom nav, Toss minimal
// KO: 게시판 페이지 — 서브 하단바로 섹션 결정, 토스 미니멀
// ========================================

/// EN: Board page widget — section content driven by initialTabIndex (from sub bottom nav).
/// KO: 게시판 페이지 위젯 — 서브 하단바의 initialTabIndex로 섹션 콘텐츠를 결정.
class BoardPage extends ConsumerStatefulWidget {
  const BoardPage({super.key, this.initialTabIndex = 0});

  /// EN: Section index — 0: Feed (추천/팔로잉/프로젝트), 1: Discover, 2: Travel Review.
  /// KO: 섹션 인덱스 — 0: 피드(추천/팔로잉/프로젝트), 1: 발견, 2: 여행후기.
  final int initialTabIndex;

  @override
  ConsumerState<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<BoardPage> {
  bool _isFabMenuExpanded = false;

  Future<void> _showMyReportsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _MyReportsSheet(),
    );
  }

  Future<void> _showCommunityBanSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _CommunityBanSheet(),
    );
  }

  void _toggleFabMenu() {
    if (!mounted) return;
    setState(() {
      _isFabMenuExpanded = !_isFabMenuExpanded;
    });
  }

  void _closeFabMenu() {
    if (!_isFabMenuExpanded || !mounted) return;
    setState(() {
      _isFabMenuExpanded = false;
    });
  }

  Future<void> _openSearchSheet(BuildContext context) async {
    final feedState = ref.read(communityFeedControllerProvider);
    final query = feedState.searchQuery.trim();
    if (query.isEmpty) {
      context.goToSearch();
      return;
    }
    context.goToSearch(query);
  }

  double _fabBottomPadding(BuildContext context) {
    return resolveCommunityFabBottomPadding(
      screenHeight: MediaQuery.sizeOf(context).height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final selectedProjectKey = ref.watch(selectedProjectKeyProvider);
    final profileState = ref.watch(userProfileControllerProvider);
    final isAdmin = profileState.maybeWhen(
      data: (profile) => _isAdminRole(
        effectiveAccessLevel: profile?.effectiveAccessLevel,
        accountRole: profile?.accountRole,
        projectRolesByProject: profile?.projectRolesByProject,
        projectId: selectedProjectId,
        projectCode: selectedProjectKey,
      ),
      orElse: () => false,
    );
    // EN: Section index determines which content to show (controlled by sub bottom nav).
    // KO: 섹션 인덱스가 표시할 콘텐츠를 결정합니다 (서브 하단바로 제어).
    final sectionIndex = widget.initialTabIndex.clamp(0, 2);
    final sectionTitle = switch (sectionIndex) {
      0 => context.l10n(ko: '피드', en: 'Feed', ja: 'フィード'),
      1 => context.l10n(ko: '발견', en: 'Discover', ja: '発見'),
      _ => context.l10n(ko: '여행후기', en: 'Travel Reviews', ja: '旅行レビュー'),
    };

    final useFeedHeroHeader = sectionIndex == 0;

    return FocusDetector(
      onFocusGained: () {
        final notifier = ref.read(communityFeedControllerProvider.notifier);
        final feedState = ref.read(communityFeedControllerProvider);

        if (sectionIndex == 0) {
          if (feedState.mode != CommunityFeedMode.recommended) {
            // EN: Mode mismatch (e.g. returning from Discover/trending) — reset mode.
            // KO: 모드 불일치 (예: 발견/트렌딩에서 복귀) — 모드를 초기화합니다.
            unawaited(notifier.setMode(CommunityFeedMode.recommended));
          } else if (feedState.posts.isNotEmpty) {
            // EN: Data exists — soft refresh only, never wipe the visible list.
            // KO: 데이터 있음 — 목록을 초기화하지 않고 조용히 새로고침합니다.
            unawaited(notifier.refreshInBackground(minInterval: Duration.zero));
          }
          // EN: Empty feed is handled by the controller's nav-index listener.
          // KO: 빈 피드는 컨트롤러의 네비게이션 인덱스 리스너가 처리합니다.
        } else {
          if (feedState.posts.isEmpty) {
            unawaited(notifier.reload(forceRefresh: true));
          } else {
            unawaited(notifier.refreshInBackground(minInterval: Duration.zero));
          }
        }

        // EN: Project post list — only load if no data yet.
        // KO: 프로젝트 게시글 목록 — 데이터가 없을 때만 로드합니다.
        final postState = ref.read(postListControllerProvider);
        if (postState.valueOrNull == null) {
          unawaited(ref.read(postListControllerProvider.notifier).load());
        }
      },
      child: Scaffold(
        appBar: useFeedHeroHeader
            ? null
            : AppBar(
                titleSpacing: 0,
                title: Row(
                  children: [
                    const SizedBox(width: GBTSpacing.md),
                    Text(
                      sectionTitle,
                      style: GBTTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // EN: Search icon — hidden on travel review section.
                  // KO: 검색 아이콘 — 여행후기 섹션에서는 숨김.
                  if (sectionIndex != 2)
                    GBTAppBarIconButton(
                      icon: Icons.search_rounded,
                      tooltip: context.l10n(ko: '검색', en: 'Search', ja: '検索'),
                      onPressed: () => _openSearchSheet(context),
                    ),
                  GBTAppBarIconButton(
                    icon: Icons.menu_rounded,
                    tooltip: context.l10n(
                      ko: '커뮤니티 설정',
                      en: 'Community settings',
                      ja: 'コミュニティ設定',
                    ),
                    onPressed: context.goToCommunitySettings,
                  ),
                ],
              ),
        body: switch (sectionIndex) {
          0 => const _FeedSection(),
          1 => const _CommunityTab(isDiscoverSection: true),
          _ => const _TravelReviewTab(),
        },
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: _fabBottomPadding(context)),
          child: _ExpandableActionFab(
            isExpanded: _isFabMenuExpanded,
            onToggle: _toggleFabMenu,
            mainHeroTag: 'board-fab-main',
            actions: [
              if (sectionIndex != 2)
                _FabMenuAction(
                  id: 'create-post',
                  icon: Icons.edit_outlined,
                  label: context.l10n(
                    ko: '게시글 작성',
                    en: 'Write Post',
                    ja: '投稿作成',
                  ),
                  onPressed: () {
                    _closeFabMenu();
                    context.goToPostCreate();
                  },
                ),
              if (sectionIndex == 2)
                _FabMenuAction(
                  id: 'create-review',
                  icon: Icons.rate_review_outlined,
                  label: context.l10n(
                    ko: '여행후기 작성',
                    en: 'Write Review',
                    ja: '旅行レビュー作成',
                  ),
                  onPressed: () {
                    _closeFabMenu();
                    context.pushNamed(AppRoutes.travelReviewCreate);
                  },
                ),
              if (sectionIndex != 2 && isAuthenticated)
                _FabMenuAction(
                  id: 'my-reports',
                  icon: Icons.flag_outlined,
                  label: context.l10n(
                    ko: '내 신고 내역',
                    en: 'My Reports',
                    ja: '自分の通報履歴',
                  ),
                  onPressed: () {
                    _closeFabMenu();
                    _showMyReportsSheet(context);
                  },
                ),
              if (sectionIndex != 2 && isAdmin)
                _FabMenuAction(
                  id: 'ban',
                  icon: Icons.gavel_outlined,
                  label: context.l10n(
                    ko: '커뮤니티 제재 관리',
                    en: 'Moderation',
                    ja: 'コミュニティ制裁管理',
                  ),
                  onPressed: () {
                    _closeFabMenu();
                    _showCommunityBanSheet(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Motion spec constants
// KO: 모션 사양 상수
// ========================================

class _BoardMotionSpec {
  static const Duration micro = Duration(milliseconds: 180);
}

// ========================================
// EN: FAB components
// KO: FAB 컴포넌트
// ========================================

class _FabMenuAction {
  const _FabMenuAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _ExpandableActionFab extends StatelessWidget {
  const _ExpandableActionFab({
    required this.isExpanded,
    required this.onToggle,
    required this.mainHeroTag,
    required this.actions,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final String mainHeroTag;
  final List<_FabMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelBg = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.94)
        : GBTColors.background;
    final labelBorder = isDark ? GBTColors.darkBorder : GBTColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: _BoardMotionSpec.micro,
          child: !isExpanded || actions.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
                  child: Column(
                    key: ValueKey(actions.length),
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: actions.reversed.map((action) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: GBTSpacing.sm,
                                vertical: GBTSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: labelBg,
                                borderRadius: BorderRadius.circular(
                                  GBTSpacing.radiusFull,
                                ),
                                border: Border.all(color: labelBorder),
                              ),
                              child: Text(
                                action.label,
                                style: GBTTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: GBTSpacing.sm),
                            FloatingActionButton.small(
                              heroTag: 'board-fab-${action.id}',
                              onPressed: action.onPressed,
                              child: Icon(action.icon, size: 18),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        FloatingActionButton.extended(
          heroTag: mainHeroTag,
          onPressed: onToggle,
          tooltip: isExpanded
              ? context.l10n(ko: '메뉴 닫기', en: 'Close menu', ja: 'メニューを閉じる')
              : context.l10n(
                  ko: '작성 메뉴 열기',
                  en: 'Open compose menu',
                  ja: '作成メニューを開く',
                ),
          icon: Icon(isExpanded ? Icons.close : Icons.edit_outlined),
          label: Text(
            isExpanded
                ? context.l10n(ko: '닫기', en: 'Close', ja: '閉じる')
                : context.l10n(ko: '글쓰기', en: 'Write', ja: '書く'),
          ),
        ),
      ],
    );
  }
}

// ========================================
// EN: Feed Section — feed-first layout inspired by market community timeline.
// KO: 피드 섹션 — 마켓 커뮤니티 타임라인 스타일을 반영한 피드 중심 레이아웃.
// ========================================

/// EN: Top controls for feed section: recommended/following + project feed.
/// KO: 피드 섹션 상단 컨트롤: 추천/팔로잉 + 프로젝트 피드.
enum _FeedTopTab { recommended, following, project }

/// EN: Feed section with timeline-style header and segmented tabs.
/// KO: 타임라인 스타일 헤더와 분할 탭을 포함한 피드 섹션.
class _FeedSection extends ConsumerStatefulWidget {
  const _FeedSection();

  @override
  ConsumerState<_FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends ConsumerState<_FeedSection>
    with WidgetsBindingObserver {
  _FeedTopTab _tab = _FeedTopTab.recommended;
  final ScrollController _scrollController = ScrollController();
  late final CommunityFeedController _feedController;
  Timer? _foregroundRefreshTimer;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();
    _feedController = ref.read(communityFeedControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_feedController.startRealtimeSync());
    _scrollController.addListener(_handleScroll);
    _foregroundRefreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _refreshFeedIfVisible(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final mode = ref.read(communityFeedControllerProvider).mode;
      if (mode != CommunityFeedMode.recommended) {
        await ref
            .read(communityFeedControllerProvider.notifier)
            .setMode(CommunityFeedMode.recommended);
        return;
      }
      await ref
          .read(communityFeedControllerProvider.notifier)
          .reload(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _foregroundRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    unawaited(_feedController.stopRealtimeSync());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) _refreshFeedIfVisible();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _feedController.loadMore();
    }
  }

  void _refreshFeedIfVisible() {
    if (!mounted || !_isAppResumed) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _feedController.refreshInBackground(
      minInterval: const Duration(seconds: 25),
    );
  }

  // EN: Scroll to top then apply buffered new posts — Twitter-style "new posts" flow.
  // KO: 상단으로 스크롤 후 대기 중인 새 글 적용 — 트위터 스타일 새 글 배너 동작.
  void _scrollToTopAndApplyPending() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    _feedController.applyPendingPosts();
  }

  Future<void> _openSearchSheet() async {
    final feedState = ref.read(communityFeedControllerProvider);
    final query = feedState.searchQuery.trim();
    if (query.isEmpty) {
      context.goToSearch();
      return;
    }
    context.goToSearch(query);
  }

  void _onTabChanged(_FeedTopTab tab) {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _tab = tab);
    switch (tab) {
      case _FeedTopTab.recommended:
        _feedController.setMode(CommunityFeedMode.recommended);
        break;
      case _FeedTopTab.following:
        _feedController.setMode(CommunityFeedMode.following);
        break;
      case _FeedTopTab.project:
        break;
    }
  }

  void _onProjectSelected() {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _tab = _FeedTopTab.project);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedControllerProvider);
    final notifier = ref.read(communityFeedControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.xs,
              GBTSpacing.md,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.l10n(ko: '피드', en: 'Feed', ja: 'フィード'),
                  style: GBTTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                _FeedHeaderIconButton(
                  icon: Icons.search_rounded,
                  tooltip: context.l10n(ko: '검색', en: 'Search', ja: '検索'),
                  onPressed: _openSearchSheet,
                ),
                const SizedBox(width: GBTSpacing.xs),
                _FeedHeaderIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: context.l10n(
                    ko: '커뮤니티 설정 열기',
                    en: 'Open community settings',
                    ja: 'コミュニティ設定を開く',
                  ),
                  onPressed: context.goToCommunitySettings,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.sm,
              GBTSpacing.md,
              0,
            ),
            // EN: Sticky-feeling category tab row — translucent tint +
            //     hairline bottom border (no blur; this row sits above the
            //     list in normal layout flow rather than a pinned Sliver
            //     header, so a full glass panel would not overlay content).
            // KO: 스티키 느낌의 카테고리 탭 행 — 반투명 틴트 + 헤어라인
            //     하단 보더 (블러 없음; 이 행은 고정 Sliver 헤더가 아니라
            //     리스트 위 일반 레이아웃 흐름에 위치하므로 완전한 글래스
            //     패널은 콘텐츠 위에 뜨는 효과를 내지 못합니다).
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? GBTColors.darkSurface : GBTColors.surface)
                    .withValues(alpha: 0.6),
                border: Border(
                  bottom: BorderSide(
                    color: (isDark ? GBTColors.darkBorder : GBTColors.border)
                        .withValues(alpha: 0.5),
                    width: 0.6,
                  ),
                ),
              ),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FeedModePill(
                      label: context.l10n(
                        ko: '추천',
                        en: 'Recommended',
                        ja: 'おすすめ',
                      ),
                      isSelected: _tab == _FeedTopTab.recommended,
                      onTap: () => _onTabChanged(_FeedTopTab.recommended),
                    ),
                    const SizedBox(width: GBTSpacing.xs),
                    _FeedModePill(
                      label: context.l10n(
                        ko: '팔로잉',
                        en: 'Following',
                        ja: 'フォロー中',
                      ),
                      isSelected: _tab == _FeedTopTab.following,
                      onTap: () => _onTabChanged(_FeedTopTab.following),
                    ),
                    const SizedBox(width: GBTSpacing.xs),
                    _FeedModePill(
                      label: context.l10n(
                        ko: '프로젝트별',
                        en: 'By Project',
                        ja: 'プロジェクト別',
                      ),
                      isSelected: _tab == _FeedTopTab.project,
                      onTap: () => _onTabChanged(_FeedTopTab.project),
                    ),
                    if (_tab == _FeedTopTab.project) ...[
                      const SizedBox(width: GBTSpacing.xs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: ProjectAudienceSelectorCompact(
                          dense: true,
                          onProjectSelected: (_) => _onProjectSelected(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          if (_tab == _FeedTopTab.project) ...[
            const Expanded(child: _ProjectPostList()),
          ],
          if (_tab != _FeedTopTab.project)
            Expanded(
              child: Stack(
                children: [
                  _CommunityList(
                    state: feedState,
                    scrollController: _scrollController,
                    onRefresh: () => notifier.reload(forceRefresh: true),
                    onRetry: () => notifier.reload(forceRefresh: true),
                  ),
                  Positioned(
                    top: GBTSpacing.sm,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _NewPostsBanner(
                        count: feedState.pendingNewPosts.length,
                        onTap: _scrollToTopAndApplyPending,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// EN: Circular icon button used in feed hero header.
/// KO: 피드 상단 헤더에서 사용하는 원형 아이콘 버튼.
class _FeedHeaderIconButton extends StatelessWidget {
  const _FeedHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.7)
        : GBTColors.surfaceVariant.withValues(alpha: 0.9);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(child: Icon(icon, size: 22, color: iconColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Rounded segmented mode pill for the feed top tabs.
/// KO: 피드 상단 탭용 라운드 분할 모드 필.
class _FeedModePill extends StatelessWidget {
  const _FeedModePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final inactiveColor = Colors.transparent;
    final activeTextColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final inactiveTextColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GBTTypography.titleMedium.copyWith(
            color: isSelected ? activeTextColor : inactiveTextColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Project post list — shows posts for the selected project.
// KO: 프로젝트 게시글 목록 — 선택된 프로젝트의 게시글을 표시.
// ========================================

/// EN: Post list driven by the selected project key via postListControllerProvider.
/// KO: postListControllerProvider를 통해 선택된 프로젝트의 게시글 목록을 표시.
class _ProjectPostList extends ConsumerWidget {
  const _ProjectPostList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(postListControllerProvider);

    return postState.when(
      loading: () => ListView(
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
      error: (err, _) {
        final message = err is Failure
            ? err.userMessage
            : context.l10n(
                ko: '게시글을 불러오지 못했어요',
                en: 'Failed to load posts',
                ja: '投稿を読み込めませんでした',
              );
        return ListView(
          padding: GBTSpacing.paddingPage,
          children: [
            const SizedBox(height: GBTSpacing.lg),
            GBTErrorState(
              message: message,
              onRetry: () => ref
                  .read(postListControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
          ],
        );
      },
      data: (posts) {
        if (posts.isEmpty) {
          return ListView(
            padding: GBTSpacing.paddingPage,
            children: [
              const SizedBox(height: GBTSpacing.lg),
              GBTEmptyState(
                icon: Icons.article_outlined,
                title: context.l10n(
                  ko: '이 프로젝트에 아직 게시글이 없습니다',
                  en: 'No posts in this project yet',
                  ja: 'このプロジェクトにはまだ投稿がありません',
                ),
                subtitle: context.l10n(
                  ko: '첫 이야기를 들려주세요!',
                  en: 'Be the first to share a story!',
                  ja: '最初のお話を聞かせてください!',
                ),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(postListControllerProvider.notifier)
              .load(forceRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: FeedNativeAdPlacement.totalItemCount(posts.length),
            itemBuilder: (context, index) {
              if (FeedNativeAdPlacement.isAdIndex(
                listIndex: index,
                postCount: posts.length,
              )) {
                final adOrdinal = FeedNativeAdPlacement.adOrdinalForIndex(
                  listIndex: index,
                  postCount: posts.length,
                );
                return _FeedSponsoredCard(adOrdinal: adOrdinal);
              }
              final postIndex = FeedNativeAdPlacement.postIndexForListIndex(
                listIndex: index,
                postCount: posts.length,
              );
              return _CommunityPostCard(post: posts[postIndex]);
            },
          ),
        );
      },
    );
  }
}

// ========================================
// EN: Community Tab (Discover only — feed section replaced by _FeedSection)
// KO: 커뮤니티 탭 (발견 전용 — 피드 섹션은 _FeedSection으로 대체됨)
// ========================================

/// EN: Community tab used for the discover section.
/// KO: 발견 섹션에 사용되는 커뮤니티 탭.
class _CommunityTab extends ConsumerStatefulWidget {
  const _CommunityTab({required this.isDiscoverSection});

  final bool isDiscoverSection;

  @override
  ConsumerState<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<_CommunityTab>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late final CommunityFeedController _feedController;
  Timer? _foregroundRefreshTimer;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();
    _feedController = ref.read(communityFeedControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_feedController.startRealtimeSync());
    _scrollController.addListener(_handleScroll);
    _foregroundRefreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _refreshFeedIfVisible(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSectionMode();
    });
  }

  @override
  void dispose() {
    _foregroundRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    unawaited(_feedController.stopRealtimeSync());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CommunityTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDiscoverSection != widget.isDiscoverSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncSectionMode(previousWasDiscover: oldWidget.isDiscoverSection);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) {
      _refreshFeedIfVisible();
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _feedController.loadMore();
    }
  }

  void _refreshFeedIfVisible() {
    if (!mounted || !_isAppResumed) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _feedController.refreshInBackground(
      minInterval: const Duration(seconds: 25),
    );
  }

  // EN: Scroll to top then apply buffered new posts.
  // KO: 상단으로 스크롤 후 대기 중인 새 글 적용.
  void _scrollToTopAndApplyPending() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    _feedController.applyPendingPosts();
  }

  void _syncSectionMode({bool? previousWasDiscover}) {
    if (!mounted) return;
    final state = ref.read(communityFeedControllerProvider);
    if (widget.isDiscoverSection) {
      if (state.mode != CommunityFeedMode.trending) {
        unawaited(_feedController.setMode(CommunityFeedMode.trending));
      }
      return;
    }
    if (!widget.isDiscoverSection &&
        (previousWasDiscover ?? false) &&
        state.mode == CommunityFeedMode.trending) {
      unawaited(_feedController.setMode(CommunityFeedMode.recommended));
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedControllerProvider);
    final notifier = ref.read(communityFeedControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // EN: Map current mode to primary three-way selection (recommended/following/latest).
    // KO: 현재 모드를 3방향 선택(추천/팔로잉/최신)으로 매핑합니다.
    final primaryMode = switch (feedState.mode) {
      CommunityFeedMode.following => CommunityFeedMode.following,
      CommunityFeedMode.latest => CommunityFeedMode.latest,
      _ => CommunityFeedMode.recommended,
    };

    // EN: Current user ID for following users lookup.
    // KO: 팔로잉 유저 조회를 위한 현재 유저 ID.
    final profileState = ref.watch(userProfileControllerProvider);
    final currentUserId = profileState.maybeWhen(
      data: (profile) => profile?.id,
      orElse: () => null,
    );

    // EN: Watch following users only in following mode with valid user ID.
    // KO: 팔로잉 모드 + 유효한 유저 ID일 때만 팔로잉 유저 목록 감시.
    final AsyncValue<List<UserFollowSummary>>? followingUsersAsync =
        (!feedState.isSearching &&
            !widget.isDiscoverSection &&
            primaryMode == CommunityFeedMode.following &&
            currentUserId != null)
        ? ref.watch(userFollowingProvider(currentUserId))
        : null;

    return Column(
      children: [
        // EN: Mode selector — only for feed section, hidden during search.
        // KO: 모드 선택기 — 피드 섹션 전용, 검색 중 숨김.
        if (!widget.isDiscoverSection && !feedState.isSearching) ...[
          const SizedBox(height: GBTSpacing.xs),
          _FeedModeTabRow(
            selectedMode: primaryMode,
            onChanged: notifier.setMode,
          ),
        ],

        // EN: Search scope filter chips — visible only while searching.
        // KO: 검색 범위 필터 칩 — 검색 중에만 표시.
        if (feedState.isSearching) ...[
          const SizedBox(height: GBTSpacing.xs),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
              children:
                  const [
                    CommunitySearchScope.all,
                    CommunitySearchScope.title,
                    CommunitySearchScope.author,
                    CommunitySearchScope.content,
                    CommunitySearchScope.media,
                  ].map((scope) {
                    return Padding(
                      padding: const EdgeInsets.only(right: GBTSpacing.sm),
                      child: _FilterChipModern(
                        label: _searchScopeLabel(context, scope),
                        icon: _searchScopeIcon(scope),
                        isSelected: feedState.searchScope == scope,
                        onTap: () => notifier.setSearchScope(scope),
                      ),
                    );
                  }).toList(),
            ),
          ),
          _FeedSearchSummary(
            query: feedState.searchQuery,
            scopeLabel: _searchScopeLabel(context, feedState.searchScope),
            resultCount: feedState.posts.length,
          ),
        ],

        // EN: Following users pills — following mode only, shows users the current user follows.
        // KO: 팔로잉 유저 필 — 팔로잉 모드 전용, 현재 유저가 팔로우한 사람 목록.
        if (!feedState.isSearching &&
            !widget.isDiscoverSection &&
            primaryMode == CommunityFeedMode.following) ...[
          const SizedBox(height: GBTSpacing.xs),
          SizedBox(
            height: 34,
            child:
                followingUsersAsync?.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (users) => users.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GBTSpacing.md,
                            vertical: 8,
                          ),
                          child: Text(
                            context.l10n(
                              ko: '팔로우한 유저가 없습니다',
                              en: 'No followed users yet',
                              ja: 'フォロー中のユーザーがいません',
                            ),
                            style: GBTTypography.caption.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextTertiary
                                  : GBTColors.textTertiary,
                            ),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: GBTSpacing.md,
                          ),
                          children: users
                              .map(
                                (user) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: GBTSpacing.xs,
                                  ),
                                  child: _FollowingUserPill(user: user),
                                ),
                              )
                              .toList(),
                        ),
                ) ??
                const SizedBox.shrink(),
          ),
        ],

        // EN: Main content list with new-posts banner overlay.
        // KO: 새 글 배너 오버레이가 포함된 메인 콘텐츠 목록.
        Expanded(
          child: Stack(
            children: [
              _CommunityList(
                state: feedState,
                scrollController: _scrollController,
                onRefresh: () => notifier.reload(forceRefresh: true),
                onRetry: () => notifier.reload(forceRefresh: true),
              ),
              Positioned(
                top: GBTSpacing.sm,
                left: 0,
                right: 0,
                child: Center(
                  child: _NewPostsBanner(
                    count: feedState.pendingNewPosts.length,
                    onTap: _scrollToTopAndApplyPending,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================
// EN: Feed Mode Tab Row — Toss-style plain text selector
// KO: 피드 모드 탭 행 — 토스 스타일 단순 텍스트 선택기
// ========================================

/// EN: Simple text-based feed mode selector — no borders, no backgrounds, Toss-style.
/// KO: 토스 스타일 단순 텍스트 피드 모드 선택기 — 테두리/배경 없음.
class _FeedModeTabRow extends StatelessWidget {
  const _FeedModeTabRow({required this.selectedMode, required this.onChanged});

  final CommunityFeedMode selectedMode;
  final ValueChanged<CommunityFeedMode> onChanged;

  static const _modes = [
    CommunityFeedMode.recommended,
    CommunityFeedMode.following,
    CommunityFeedMode.latest,
  ];

  static String _label(BuildContext context, CommunityFeedMode m) =>
      switch (m) {
        CommunityFeedMode.recommended => context.l10n(
          ko: '추천',
          en: 'Recommended',
          ja: 'おすすめ',
        ),
        CommunityFeedMode.following => context.l10n(
          ko: '팔로잉',
          en: 'Following',
          ja: 'フォロー中',
        ),
        CommunityFeedMode.latest => context.l10n(
          ko: '최신',
          en: 'Latest',
          ja: '最新',
        ),
        _ => m.label,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final trackColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final unselectedColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    // EN: Segmented pill track — selected mode gets a solid primary fill.
    // KO: 세그먼트 필 트랙 — 선택된 모드는 프라이머리 색으로 채워집니다.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        ),
        child: Row(
          children: _modes.map((mode) {
            final isSelected = mode == selectedMode;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                  ),
                  child: Text(
                    _label(context, mode),
                    textAlign: TextAlign.center,
                    style: GBTTypography.labelMedium.copyWith(
                      color: isSelected
                          ? GBTColors.textInverse
                          : unselectedColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ========================================
// EN: Search Sheet
// KO: 검색 시트
// ========================================

class _CommunitySearchSheet extends StatefulWidget {
  const _CommunitySearchSheet({required this.initialQuery});

  final String initialQuery;

  @override
  State<_CommunitySearchSheet> createState() => _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends State<_CommunitySearchSheet> {
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GBTSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(ko: '게시글 검색', en: 'Search posts', ja: '投稿検索'),
                style: GBTTypography.titleMedium,
              ),
              const SizedBox(height: GBTSpacing.sm),
              TextFormField(
                autofocus: true,
                initialValue: _query,
                onChanged: (value) => _query = value,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n(
                    ko: '제목/작성자/내용',
                    en: 'Title/Author/Content',
                    ja: 'タイトル/作成者/内容',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onFieldSubmitted: (value) =>
                    Navigator.of(context).pop(value.trim()),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(
                      context.l10n(ko: '초기화', en: 'Reset', ja: 'リセット'),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_query.trim()),
                    child: Text(context.l10n(ko: '검색', en: 'Search', ja: '検索')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Search summary & filter chip
// KO: 검색 요약 & 필터 칩
// ========================================

class _FeedSearchSummary extends StatelessWidget {
  const _FeedSearchSummary({
    required this.query,
    required this.scopeLabel,
    required this.resultCount,
  });

  final String query;
  final String scopeLabel;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xs,
        GBTSpacing.md,
        GBTSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 14,
            color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          ),
          const SizedBox(width: GBTSpacing.xxs),
          Expanded(
            child: Text(
              '"$query" · $scopeLabel ${context.l10n(ko: "$resultCount건", en: "$resultCount results", ja: "$resultCount件")}',
              style: GBTTypography.caption.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Modern filter chip with filled/outlined toggle style and optional mode icon.
/// KO: 채워진/아웃라인 토글 스타일 및 선택적 모드 아이콘이 있는 모던 필터 칩.
class _FilterChipModern extends StatelessWidget {
  const _FilterChipModern({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : isDark
                ? GBTColors.darkBorder
                : GBTColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? primaryColor
                    : isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GBTTypography.labelMedium.copyWith(
                color: isSelected
                    ? primaryColor
                    : isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Following User Pill — avatar + display name chip
// KO: 팔로잉 유저 필 — 아바타 + 표시 이름 칩
// ========================================

class _FollowingUserPill extends StatelessWidget {
  const _FollowingUserPill({required this.user});

  final UserFollowSummary user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.goToUserProfile(user.userId),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? GBTColors.darkSurfaceVariant
              : GBTColors.surfaceVariant,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          border: Border.all(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.avatarUrl != null) ...[
              ClipOval(
                child: GBTImage(
                  imageUrl: user.avatarUrl!,
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              user.displayName,
              style: GBTTypography.labelSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Travel Review Tab
// KO: 여행 후기 탭
// ========================================

class _TravelReviewTab extends ConsumerWidget {
  const _TravelReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectCode = ref.watch(selectedProjectKeyProvider)?.trim();
    if (projectCode == null || projectCode.isEmpty) {
      return const _TravelReviewListMessage(
        icon: Icons.folder_off_outlined,
        message: '여행 후기를 볼 프로젝트를 먼저 선택해주세요.',
      );
    }

    final reviews = ref.watch(travelReviewsProvider(projectCode));
    return reviews.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _TravelReviewListMessage(
        icon: Icons.cloud_off_rounded,
        message: '여행 후기를 불러오지 못했어요.',
        actionLabel: '다시 시도',
        onAction: () => ref.invalidate(travelReviewsProvider(projectCode)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _TravelReviewListMessage(
            icon: Icons.route_outlined,
            message: '아직 등록된 여행 후기가 없어요.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(travelReviewsProvider(projectCode));
            await ref.read(travelReviewsProvider(projectCode).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: GBTSpacing.md,
              right: GBTSpacing.md,
              top: GBTSpacing.md,
              bottom: 80,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: GBTSpacing.md),
              child: _TravelReviewCard(
                projectCode: projectCode,
                review: items[index],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// EN: Travel review card with modern design — image header, route badges.
/// KO: 모던 디자인의 여행 후기 카드 — 이미지 헤더, 경로 배지.
class _TravelReviewCard extends StatelessWidget {
  const _TravelReviewCard({required this.projectCode, required this.review});

  final String projectCode;
  final TravelReviewSummary review;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final places = review.stops.map((stop) => stop.place.name).toList();
    final likeCount = review.post.likeCount ?? 0;
    final commentCount = review.post.commentCount ?? 0;
    final imageUrl =
        review.post.thumbnailUrl ??
        (review.post.imageUrls.isEmpty ? null : review.post.imageUrls.first);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surface,
        // EN: 2026 large-radius card trend.
        // KO: 2026 라지 라운드 카드 트렌드.
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        border: Border.all(
          color: isDark
              ? GBTColors.darkBorderSubtle
              : GBTColors.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.pushNamed(
            AppRoutes.travelReviewDetail,
            pathParameters: {'projectCode': projectCode, 'reviewId': review.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EN: Cover image with gradient fallback and place count badge
            // KO: 장소 수 배지와 그라디언트 폴백이 있는 커버 이미지
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl?.isNotEmpty == true)
                    GBTImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: review.post.title,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  GBTColors.darkSurfaceElevated,
                                  GBTColors.darkSurfaceVariant,
                                ]
                              : [
                                  GBTColors.primaryLight,
                                  GBTColors.primaryMuted.withValues(alpha: 0.5),
                                ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  // EN: Route badge count overlay
                  // KO: 경로 배지 카운트 오버레이
                  Positioned(
                    top: GBTSpacing.sm,
                    right: GBTSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            context.l10n(
                              ko: '${places.length}곳',
                              en: '${places.length} places',
                              ja: '${places.length}か所',
                            ),
                            style: GBTTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // EN: Route badges — horizontal scroll
            // KO: 경로 배지 — 가로 스크롤
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.sm + 2,
                GBTSpacing.md,
                0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < places.length; i++) ...[
                      _RouteBadge(index: i + 1, name: places[i]),
                      if (i < places.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: isDark
                                ? GBTColors.darkTextTertiary
                                : GBTColors.textTertiary,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            // EN: Content section
            // KO: 콘텐츠 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.sm + 2,
                GBTSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.post.title,
                    style: GBTTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    _summaryText(review),
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // EN: Bottom bar — author + engagement
            // KO: 하단 바 — 작성자 + 인게이지먼트
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.sm + 2,
                GBTSpacing.md,
                GBTSpacing.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDark
                        ? GBTColors.darkSurfaceElevated
                        : GBTColors.surfaceAlternate,
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.xs),
                  Text(
                    review.post.authorName?.trim().isNotEmpty == true
                        ? review.post.authorName!
                        : '여행자',
                    style: GBTTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.xs),
                  Text(
                    review.post.timeAgoLabel,
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$likeCount',
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$commentCount',
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
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

class _TravelReviewListMessage extends StatelessWidget {
  const _TravelReviewListMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: GBTSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: GBTSpacing.sm),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _summaryText(TravelReviewSummary review) {
  final routeNote = review.routeNote?.trim();
  if (routeNote != null && routeNote.isNotEmpty) return routeNote;
  if (review.post.tags.isNotEmpty) return review.post.tags.join(' · ');
  final eventCount = review.events.length;
  return eventCount == 0
      ? '방문 장소 ${review.stops.length}곳을 이은 여행 기록'
      : '방문 장소 ${review.stops.length}곳 · 라이브 $eventCount개';
}

/// EN: Route badge chip with numbered index and place name.
/// KO: 번호 인덱스와 장소명이 있는 경로 배지 칩.
class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.index, required this.name});

  final int index;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: GBTTypography.caption.copyWith(
                color: isDark ? GBTColors.darkBackground : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: GBTTypography.labelSmall.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Community List
// KO: 커뮤니티 리스트
// ========================================

class _CommunityList extends StatelessWidget {
  const _CommunityList({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
  });

  final CommunityFeedViewState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Builder(
        builder: (context) {
          if (state.isInitialLoading) {
            return ListView(
              controller: scrollController,
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
            );
          }

          if (state.failure != null && state.posts.isEmpty) {
            return ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: GBTSpacing.paddingPage,
              children: [
                const SizedBox(height: GBTSpacing.lg),
                GBTErrorState(
                  message: state.failure!.userMessage,
                  onRetry: onRetry,
                ),
              ],
            );
          }

          if (state.posts.isEmpty) {
            final message = state.isSearching
                ? context.l10n(
                    ko: '${_searchScopeLabel(context, state.searchScope)} 검색 결과가 없습니다',
                    en: 'No search results in ${_searchScopeLabel(context, state.searchScope)}',
                    ja: '${_searchScopeLabel(context, state.searchScope)}の検索結果がありません',
                  )
                : switch (state.mode) {
                    CommunityFeedMode.recommended => context.l10n(
                      ko: '추천 피드에 표시할 글이 없습니다',
                      en: 'No posts in recommended feed',
                      ja: 'おすすめフィードに表示する投稿がありません',
                    ),
                    CommunityFeedMode.following => context.l10n(
                      ko: '팔로우 피드에 표시할 글이 없습니다',
                      en: 'No posts in following feed',
                      ja: 'フォローフィードに表示する投稿がありません',
                    ),
                    CommunityFeedMode.latest => context.l10n(
                      ko: '아직 피드 글이 없습니다',
                      en: 'No feed posts yet',
                      ja: 'まだフィード投稿がありません',
                    ),
                    CommunityFeedMode.trending => context.l10n(
                      ko: '인기 글이 아직 없습니다',
                      en: 'No trending posts yet',
                      ja: 'まだ人気投稿がありません',
                    ),
                  };
            return ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: GBTSpacing.paddingPage,
              children: [
                const SizedBox(height: GBTSpacing.lg),
                GBTEmptyState(icon: Icons.forum_outlined, title: message),
              ],
            );
          }

          // EN: AnimatedSwitcher keyed on feed mode — fade+slide transition
          // when the user switches between recommended/following/latest.
          // KO: 피드 모드를 키로 사용하는 AnimatedSwitcher — 추천/팔로잉/최신
          // 전환 시 페이드+슬라이드 전환 애니메이션 적용.
          final reduceMotion =
              MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          return AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offsetAnim =
                  Tween<Offset>(
                    begin: reduceMotion ? Offset.zero : const Offset(0, 0.025),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnim, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(state.mode),
              child: Builder(
                builder: (context) {
                  final feedItemCount = FeedNativeAdPlacement.totalItemCount(
                    state.posts.length,
                  );
                  final totalCount =
                      feedItemCount + (state.isLoadingMore ? 1 : 0);
                  return ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 6, bottom: 88),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (index >= feedItemCount) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: GBTSpacing.md,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      if (FeedNativeAdPlacement.isAdIndex(
                        listIndex: index,
                        postCount: state.posts.length,
                      )) {
                        final adOrdinal =
                            FeedNativeAdPlacement.adOrdinalForIndex(
                              listIndex: index,
                              postCount: state.posts.length,
                            );
                        return _FeedSponsoredCard(adOrdinal: adOrdinal);
                      }

                      final postIndex =
                          FeedNativeAdPlacement.postIndexForListIndex(
                            listIndex: index,
                            postCount: state.posts.length,
                          );
                      final post = state.posts[postIndex];
                      return _CommunityPostCard(post: post);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedSponsoredCampaign {
  /// EN: Selects deterministic fallback copy by slot order.
  /// KO: 슬롯 순번 기준으로 결정적인 폴백 문구를 선택합니다.
  static SponsoredFallbackContent fallbackContent(
    BuildContext context,
    int adOrdinal,
  ) {
    switch (adOrdinal % 3) {
      case 1:
        return SponsoredFallbackContent(
          icon: Icons.map_outlined,
          title: context.l10n(
            ko: '오늘 갈 만한 성지를 바로 찾아보세요',
            en: 'Find today\'s pilgrimage spots quickly',
            ja: '今日行ける聖地をすぐに探しましょう',
          ),
          description: context.l10n(
            ko: '거리와 태그를 기준으로 장소를 빠르게 탐색할 수 있어요.',
            en: 'Browse places fast by distance and tags.',
            ja: '距離とタグを基準に場所を素早く探せます。',
          ),
          ctaLabel: context.l10n(
            ko: '장소 탐색하기',
            en: 'Explore Places',
            ja: '場所を探す',
          ),
          accentColor: GBTColors.accentTeal,
          badgeLabel: context.l10n(ko: '광고', en: 'AD', ja: '広告'),
          sponsorLabel: context.l10n(
            ko: 'GirlsBandTabi 추천',
            en: 'GirlsBandTabi Sponsored',
            ja: 'GirlsBandTabi スポンサー',
          ),
          onTap: () => context.go('/explore'),
        );
      case 2:
        return SponsoredFallbackContent(
          icon: Icons.rate_review_outlined,
          title: context.l10n(
            ko: '실제 이동 동선이 담긴 여행후기를 확인하세요',
            en: 'Read travel reviews with real routes',
            ja: '実際の移動動線がある旅行レビューを確認しましょう',
          ),
          description: context.l10n(
            ko: '같은 프로젝트 팬들의 방문 기록과 팁을 한 번에 볼 수 있어요.',
            en: 'See fellow fans\' visit logs and tips at once.',
            ja: '同じプロジェクトのファンの訪問記録とコツをまとめて見られます。',
          ),
          ctaLabel: context.l10n(
            ko: '여행후기 보기',
            en: 'Open Reviews',
            ja: '旅行レビューを見る',
          ),
          accentColor: GBTColors.secondary,
          badgeLabel: context.l10n(ko: '광고', en: 'AD', ja: '広告'),
          sponsorLabel: context.l10n(
            ko: 'GirlsBandTabi 추천',
            en: 'GirlsBandTabi Sponsored',
            ja: 'GirlsBandTabi スポンサー',
          ),
          onTap: () => context.goNamed(AppRoutes.travelReviewTab),
        );
      default:
        return SponsoredFallbackContent(
          icon: Icons.music_note_outlined,
          title: context.l10n(
            ko: '다가오는 이벤트 일정을 놓치지 마세요',
            en: 'Don\'t miss upcoming events',
            ja: '近づくイベント日程を見逃さないでください',
          ),
          description: context.l10n(
            ko: '예정/완료 필터로 공연 흐름을 빠르게 확인할 수 있어요.',
            en: 'Track event flow fast with upcoming/completed filters.',
            ja: '予定/完了フィルターで公演の流れを素早く確認できます。',
          ),
          ctaLabel: context.l10n(
            ko: '이벤트 보기',
            en: 'View Events',
            ja: 'イベントを見る',
          ),
          accentColor: GBTColors.accentBlue,
          badgeLabel: context.l10n(ko: '광고', en: 'AD', ja: '広告'),
          sponsorLabel: context.l10n(
            ko: 'GirlsBandTabi 추천',
            en: 'GirlsBandTabi Sponsored',
            ja: 'GirlsBandTabi スポンサー',
          ),
          onTap: () => context.go('/explore?tab=1'),
        );
    }
  }
}

class _FeedSponsoredCard extends StatelessWidget {
  const _FeedSponsoredCard({required this.adOrdinal});

  final int adOrdinal;

  @override
  Widget build(BuildContext context) {
    return HybridSponsoredSlot(
      request: AdSlotRequest(
        placement: AdSlotPlacement.boardFeed,
        ordinal: adOrdinal,
      ),
      noDecisionStrategy: NoDecisionStrategy.networkThenHouse,
      deliveryNoneStrategy: DeliveryNoneStrategy.fallback,
      fallback: _FeedSponsoredCampaign.fallbackContent(context, adOrdinal),
    );
  }
}

// ========================================
// EN: Community Post Card — timeline block style
// KO: 커뮤니티 게시글 카드 — 타임라인 블록 스타일
// ========================================

enum _PostCardAction { edit, delete, report, blockToggle, ban }

class _CommunityPostCard extends ConsumerWidget {
  const _CommunityPostCard({required this.post});

  final PostSummary post;

  PostReactionTarget get _reactionTarget => PostReactionTarget(
    postId: post.id,
    // EN: Community feed can include mixed projects, so use each post's project.
    // KO: 커뮤니티 피드는 프로젝트가 섞일 수 있어 게시글별 프로젝트를 사용합니다.
    projectCodeOverride: post.projectId,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorLabel = post.authorName?.isNotEmpty == true
        ? post.authorName!
        : context.l10n(ko: '익명', en: 'Anonymous', ja: '匿名');
    final avatarUrl = post.authorAvatarUrl?.isNotEmpty == true
        ? post.authorAvatarUrl
        : null;
    final commentCount = post.commentCount ?? 0;
    final baseLikeCount = post.likeCount ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final projectAccentColor = isDark
        ? GBTColors.darkPrimary
        : GBTColors.primary;
    final projectBadgeBackground = projectAccentColor.withValues(
      alpha: isDark ? 0.24 : 0.12,
    );
    final projectBadgeBorder = projectAccentColor.withValues(
      alpha: isDark ? 0.54 : 0.28,
    );
    final commentActionColor = isDark
        ? GBTColors.darkPrimary
        : GBTColors.accentBlue;

    // EN: Prefer server thumbnail, then fallback list/content-derived images.
    // KO: 서버 썸네일 우선, 그 다음 목록/본문 기반 이미지로 폴백합니다.
    final previewImageUrls = _resolvePreviewImageUrls(post);
    final hasThumbnailImage = previewImageUrls.isNotEmpty;
    final contentRaw = post.content?.trim() ?? '';
    String previewText = '';
    if (contentRaw.isNotEmpty) {
      final stripped = stripImageMarkdown(
        contentRaw,
      ).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (stripped.isNotEmpty) {
        previewText = stripped;
      } else {
        // EN: Fallback clean-up when markdown stripping leaves empty text.
        // KO: 마크다운 제거 후 빈 문자열일 때를 위한 폴백 정리.
        previewText = contentRaw
            .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }
    final previewSnippet = previewText;

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final likeState = isAuthenticated
        ? ref.watch(postLikeControllerProvider(_reactionTarget))
        : null;
    final bookmarkState = isAuthenticated
        ? ref.watch(postBookmarkControllerProvider(_reactionTarget))
        : null;
    final isLiked =
        likeState?.maybeWhen(
          data: (value) => value.isLiked,
          orElse: () => false,
        ) ??
        false;
    final likeCount =
        likeState?.maybeWhen(
          data: (value) => value.likeCount,
          orElse: () => baseLikeCount,
        ) ??
        baseLikeCount;
    final isBookmarked =
        bookmarkState?.maybeWhen(
          data: (value) => value.isBookmarked,
          orElse: () => false,
        ) ??
        false;
    final canToggleLike = !isAuthenticated || (likeState?.hasValue ?? false);
    final canToggleBookmark =
        !isAuthenticated || (bookmarkState?.hasValue ?? false);
    final likeActionColor = isLiked ? GBTColors.secondary : tertiaryColor;
    final bookmarkActionColor = isBookmarked
        ? (isDark ? GBTColors.darkPrimary : GBTColors.primary)
        : tertiaryColor;
    final profileState = ref.watch(userProfileControllerProvider);
    final currentUserId = profileState.maybeWhen(
      data: (profile) => profile?.id,
      orElse: () => null,
    );
    final isAdmin = profileState.maybeWhen(
      data: (profile) => _isAdminRole(
        effectiveAccessLevel: profile?.effectiveAccessLevel,
        accountRole: profile?.accountRole,
        projectRolesByProject: profile?.projectRolesByProject,
        projectId: post.projectId,
        projectCode: post.projectId,
      ),
      orElse: () => false,
    );
    final isAuthor = currentUserId != null && currentUserId == post.authorId;
    final followingUsersState =
        !isAuthor && isAuthenticated && currentUserId != null
        ? ref.watch(userFollowingProvider(currentUserId))
        : null;
    final isFollowingAuthor =
        followingUsersState?.maybeWhen(
          data: (users) => users.any((user) => user.userId == post.authorId),
          orElse: () => false,
        ) ??
        false;
    final blockStatusState = isAuthenticated && !isAuthor
        ? ref.watch(blockStatusControllerProvider(post.authorId))
        : null;
    final blockStatus = blockStatusState?.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final blockLabel = blockStatus?.blockedByMe == true
        ? context.l10n(ko: '차단 해제', en: 'Unblock', ja: 'ブロック解除')
        : context.l10n(ko: '차단', en: 'Block', ja: 'ブロック');
    final showMoreButton = isAuthenticated;
    final projectsState = ref.watch(projectsControllerProvider);
    final projectName = projectsState.maybeWhen(
      data: (projects) => _resolveProjectName(projects, post.projectId),
      orElse: () => post.projectId,
    );
    // EN: Author active title — shown as a small badge below the author name.
    // KO: 작성자의 활성 칭호 — 작성자 이름 아래 작은 배지로 표시합니다.
    final authorTitleItem = ref
        .watch(userActiveTitleProvider(post.authorId))
        .valueOrNull;

    // EN: Timeline block — edge-to-edge content with bottom divider.
    // KO: 타임라인 블록 — 카드 테두리 대신 하단 구분선 기반 레이아웃.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? GBTColors.darkBorder.withValues(alpha: 0.55)
                : GBTColors.border.withValues(alpha: 0.55),
            width: 0.6,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.goToPostDetail(post.id, projectCode: post.projectId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(
                      url: avatarUrl,
                      radius: 20,
                      semanticLabel:
                          '$authorLabel ${context.l10n(ko: "프로필 사진", en: "profile image", ja: "プロフィール画像")}',
                      onTap: () => context.goToUserProfile(post.authorId),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  authorLabel,
                                  style: GBTTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (authorTitleItem?.hasTitle == true) ...[
                                const SizedBox(width: 6),
                                ActiveTitleBadge.fromActiveItem(
                                  authorTitleItem!,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          // EN: Emphasize project identity with a tinted badge.
                          // KO: 프로젝트 식별성을 강조하기 위해 톤 배지를 사용합니다.
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: projectBadgeBackground,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: projectBadgeBorder,
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  projectName,
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: projectAccentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                post.timeAgoLabel,
                                style: GBTTypography.labelMedium.copyWith(
                                  color: tertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isAuthor)
                      TextButton(
                        onPressed: () => context.goToUserProfile(post.authorId),
                        style: TextButton.styleFrom(
                          foregroundColor: isFollowingAuthor
                              ? (isDark
                                    ? GBTColors.darkTextPrimary
                                    : GBTColors.textPrimary)
                              : null,
                          backgroundColor: isFollowingAuthor
                              ? (isDark
                                    ? GBTColors.darkSurfaceElevated
                                    : GBTColors.surfaceVariant)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isFollowingAuthor
                              ? context.l10n(
                                  ko: '팔로잉',
                                  en: 'Following',
                                  ja: 'フォロー中',
                                )
                              : context.l10n(
                                  ko: '팔로우',
                                  en: 'Follow',
                                  ja: 'フォロー',
                                ),
                          style: GBTTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (showMoreButton)
                      IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: tertiaryColor,
                        ),
                        tooltip: context.l10n(
                          ko: '더 보기',
                          en: 'More',
                          ja: 'その他',
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final actions = <GBTActionSheetItem<_PostCardAction>>[
                            if (isAuthor)
                              GBTActionSheetItem(
                                label: context.l10n(
                                  ko: '수정',
                                  en: 'Edit',
                                  ja: '編集',
                                ),
                                value: _PostCardAction.edit,
                                icon: Icons.edit_outlined,
                              ),
                            if (isAuthor || isAdmin)
                              GBTActionSheetItem(
                                label: isAuthor
                                    ? context.l10n(
                                        ko: '삭제',
                                        en: 'Delete',
                                        ja: '削除',
                                      )
                                    : context.l10n(
                                        ko: '관리 삭제',
                                        en: 'Admin delete',
                                        ja: '管理者削除',
                                      ),
                                value: _PostCardAction.delete,
                                icon: Icons.delete_outline,
                                isDestructive: true,
                              ),
                            if (!isAuthor && isAuthenticated)
                              GBTActionSheetItem(
                                label: context.l10n(
                                  ko: '신고',
                                  en: 'Report',
                                  ja: '通報',
                                ),
                                value: _PostCardAction.report,
                                icon: Icons.flag_outlined,
                              ),
                            if (!isAuthor && isAuthenticated)
                              GBTActionSheetItem(
                                label: blockLabel,
                                value: _PostCardAction.blockToggle,
                                icon: Icons.person_off_outlined,
                              ),
                            if (isAdmin && !isAuthor)
                              GBTActionSheetItem(
                                label: context.l10n(
                                  ko: '커뮤니티 제재',
                                  en: 'Moderation ban',
                                  ja: 'コミュニティ制裁',
                                ),
                                value: _PostCardAction.ban,
                                icon: Icons.block,
                                isDestructive: true,
                              ),
                          ];

                          final action =
                              await showGBTActionSheet<_PostCardAction>(
                                context: context,
                                actions: actions,
                                cancelLabel: '취소',
                              );

                          if (action == null || !context.mounted) return;

                          if (action == _PostCardAction.edit) {
                            context.goToPostDetail(
                              post.id,
                              projectCode: post.projectId,
                            );
                            return;
                          }
                          if (action == _PostCardAction.delete) {
                            _confirmDeletePost(
                              context,
                              ref,
                              isAuthor: isAuthor,
                              isAdmin: isAdmin,
                            );
                            return;
                          }
                          if (action == _PostCardAction.report) {
                            _showReportFlow(context, ref);
                            return;
                          }
                          if (action == _PostCardAction.blockToggle) {
                            _toggleBlockUser(context, ref);
                            return;
                          }
                          if (action == _PostCardAction.ban) {
                            _confirmBanUser(context, ref);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: GBTTypography.titleLarge.copyWith(height: 1.32),
                ),
                CommunityTranslationPanel(
                  contentId: 'post-title:${post.id}',
                  text: post.title,
                  textStyle: GBTTypography.titleLarge.copyWith(height: 1.32),
                  compact: true,
                ),
                if (previewSnippet.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final previewStyle = GBTTypography.bodyLarge.copyWith(
                        color: secondaryTextColor,
                        height: 1.45,
                      );
                      final isOverflowing = _didTextExceedMaxLines(
                        context,
                        text: previewSnippet,
                        style: previewStyle,
                        maxWidth: constraints.maxWidth,
                        maxLines: 5,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: GBTSpacing.xs),
                            child: Text(
                              previewSnippet,
                              style: previewStyle,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOverflowing)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: GBTSpacing.xs,
                              ),
                              child: TextButton(
                                onPressed: () => context.goToPostDetail(
                                  post.id,
                                  projectCode: post.projectId,
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 0,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.l10n(
                                    ko: '더보기',
                                    en: 'Read more',
                                    ja: 'さらに表示',
                                  ),
                                  style: GBTTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                if (previewSnippet.isNotEmpty)
                  CommunityTranslationPanel(
                    contentId: 'post-preview:${post.id}',
                    text: previewSnippet,
                    textStyle: GBTTypography.bodyLarge.copyWith(
                      color: secondaryTextColor,
                      height: 1.45,
                    ),
                    compact: true,
                  ),
                if (hasThumbnailImage)
                  Padding(
                    padding: const EdgeInsets.only(top: GBTSpacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        // EN: 2026 large-radius card trend.
                        // KO: 2026 라지 라운드 카드 트렌드.
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusCard,
                        ),
                        border: Border.all(
                          color: isDark
                              ? GBTColors.darkBorder.withValues(alpha: 0.6)
                              : GBTColors.border.withValues(alpha: 0.6),
                          width: 0.6,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusCard,
                        ),
                        child: ConstrainedBox(
                          // EN: Cap very tall images (e.g. 9:16 portrait) at 480px.
                          // KO: 매우 세로 긴 이미지(9:16 등)를 480px로 제한합니다.
                          constraints: const BoxConstraints(
                            minHeight: 60,
                            maxHeight: 480,
                          ),
                          child: _FallbackPreviewImage(
                            imageUrls: previewImageUrls,
                            fit: BoxFit.fitWidth,
                            semanticLabel:
                                '${post.title} ${context.l10n(ko: "첨부 이미지", en: "attached image", ja: "添付画像")}',
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: GBTSpacing.sm),
                Semantics(
                  label:
                      '${context.l10n(ko: "좋아요", en: "Likes", ja: "いいね")} $likeCount${context.l10n(ko: "개", en: "", ja: "件")}, ${context.l10n(ko: "댓글", en: "Comments", ja: "コメント")} $commentCount${context.l10n(ko: "개", en: "", ja: "件")}, ${context.l10n(ko: "북마크", en: "Bookmark", ja: "ブックマーク")} ${isBookmarked ? context.l10n(ko: "북마크됨", en: "bookmarked", ja: "ブックマーク済み") : context.l10n(ko: "북마크 안 됨", en: "not bookmarked", ja: "未ブックマーク")}',
                  child: Row(
                    children: [
                      _AnimatedLikeButton(
                        isLiked: isLiked,
                        likeCount: likeCount,
                        enabled: canToggleLike,
                        onTap: () => _toggleLike(context, ref),
                        activeColor: likeActionColor,
                        inactiveColor: tertiaryColor,
                      ),
                      const SizedBox(width: GBTSpacing.sm),
                      _FeedActionButton(
                        icon: GBTActionIcons.comment,
                        label: _formatCount(commentCount),
                        color: commentActionColor,
                        semanticsLabel:
                            '${context.l10n(ko: "댓글", en: "Comments", ja: "コメント")} $commentCount',
                        onTap: () => context.goToPostDetail(
                          post.id,
                          projectCode: post.projectId,
                        ),
                      ),
                      const SizedBox(width: GBTSpacing.sm),
                      _AnimatedBookmarkButton(
                        isBookmarked: isBookmarked,
                        enabled: canToggleBookmark,
                        onTap: () => _toggleBookmark(context, ref),
                        activeColor: bookmarkActionColor,
                        inactiveColor: tertiaryColor,
                        textLabel: isBookmarked
                            ? context.l10n(
                                ko: '북마크됨',
                                en: 'Bookmarked',
                                ja: 'ブックマーク済み',
                              )
                            : context.l10n(
                                ko: '북마크',
                                en: 'Bookmark',
                                ja: 'ブックマーク',
                              ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// EN: Measures whether the preview text exceeds the target line count.
  /// KO: 미리보기 텍스트가 목표 줄 수를 초과하는지 측정합니다.
  bool _didTextExceedMaxLines(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
  }) {
    if (!maxWidth.isFinite || text.isEmpty) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: maxLines,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
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
  /// KO: 이미지 렌더링을 위해 미리보기 URL을 정규화/검증합니다.
  String? _normalizePreviewUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }

    final resolved = resolveMediaUrl(trimmed);
    final uri = Uri.tryParse(resolved);
    if (uri == null) return null;

    // EN: Allow only web URLs (http/https) for feed thumbnails.
    // KO: 피드 썸네일은 웹 URL(http/https)만 허용합니다.
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return resolved;
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isAuthenticatedProvider)) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '좋아요는 로그인 후 이용할 수 있어요',
          en: 'Like is available after login',
          ja: 'いいねはログイン後に利用できます',
        ),
      );
      return;
    }

    final result = await ref
        .read(postLikeControllerProvider(_reactionTarget).notifier)
        .toggleLike();
    if (!context.mounted) return;
    if (result is Err<PostLikeStatus>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '좋아요 상태를 반영하지 못했어요',
          en: 'Failed to update like',
          ja: 'いいねの反映に失敗しました',
        ),
      );
    }
  }

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    if (!ref.read(isAuthenticatedProvider)) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '북마크는 로그인 후 이용할 수 있어요',
          en: 'Bookmark is available after login',
          ja: 'ブックマークはログイン後に利用できます',
        ),
      );
      return;
    }

    final result = await ref
        .read(postBookmarkControllerProvider(_reactionTarget).notifier)
        .toggleBookmark();
    if (!context.mounted) return;
    if (result is Success<PostBookmarkStatus>) {
      final bookmarksNotifier = ref.read(
        localPostBookmarksControllerProvider.notifier,
      );
      if (result.data.isBookmarked) {
        unawaited(
          bookmarksNotifier.addBookmark(
            LocalBookmarkedPost(
              postId: post.id,
              projectCode: post.projectId,
              title: post.title,
              thumbnailUrl:
                  post.thumbnailUrl ??
                  (post.imageUrls.isNotEmpty ? post.imageUrls.first : null),
              bookmarkedAt: result.data.bookmarkedAt ?? DateTime.now(),
            ),
          ),
        );
      } else {
        unawaited(bookmarksNotifier.removeBookmark(post.id));
      }
    }
    if (result is Err<PostBookmarkStatus>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '저장 상태를 반영하지 못했어요',
          en: 'Failed to update save state',
          ja: '保存状態の反映に失敗しました',
        ),
      );
    }
  }

  Future<void> _confirmDeletePost(
    BuildContext context,
    WidgetRef ref, {
    required bool isAuthor,
    required bool isAdmin,
  }) async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '프로젝트를 먼저 선택해주세요',
          en: 'Please select a project first',
          ja: '先にプロジェクトを選択してください',
        ),
      );
      return;
    }

    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(ko: '게시글 삭제', en: 'Delete post', ja: '投稿削除'),
      message: context.l10n(
        ko: '정말로 이 게시글을 삭제할까요?',
        en: 'Do you want to delete this post?',
        ja: 'この投稿を削除しますか？',
      ),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      confirmLabel: context.l10n(ko: '삭제', en: 'Delete', ja: '削除'),
      isDestructive: true,
    );

    if (confirm != true || !context.mounted) return;

    final Result<void> result;
    if (isAdmin && !isAuthor) {
      final repository = await ref.read(communityRepositoryProvider.future);
      result = await repository.moderateDeletePost(
        projectCode: projectCode,
        postId: post.id,
      );
    } else {
      final repository = await ref.read(feedRepositoryProvider.future);
      result = await repository.deletePost(
        projectCode: projectCode,
        postId: post.id,
      );
    }

    if (!context.mounted) return;
    if (result is Success<void>) {
      await ref
          .read(communityFeedControllerProvider.notifier)
          .reload(forceRefresh: true);
      if (context.mounted) {
        _showSnackBar(
          context,
          context.l10n(ko: '게시글을 삭제했어요', en: 'Post deleted', ja: '投稿を削除しました'),
        );
      }
    } else if (result is Err<void>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '게시글을 삭제하지 못했어요',
          en: 'Failed to delete post',
          ja: '投稿を削除できませんでした',
        ),
      );
    }
  }

  Future<void> _showReportFlow(BuildContext context, WidgetRef ref) async {
    final rateLimiter = ref.read(reportRateLimiterProvider);
    if (!rateLimiter.canReport(post.id)) {
      final remaining = rateLimiter.remainingCooldown(post.id);
      final minutes = remaining.inMinutes + 1;
      _showSnackBar(
        context,
        context.l10n(
          ko: '$minutes분 후 다시 신고할 수 있어요',
          en: 'You can report again in $minutes minutes',
          ja: '$minutes分後に再度通報できます',
        ),
      );
      return;
    }

    final payload = await showModalBottomSheet<CommunityReportPayload>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const CommunityReportSheet(),
    );
    if (payload == null || !context.mounted) {
      return;
    }

    final confirmed = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(ko: '신고 접수', en: 'Submit report', ja: '通報受付'),
      message: context.l10n(
        ko: '게시글을 "${payload.reason.label}" 사유로 신고합니다.\n접수하시겠어요?',
        en: 'Report this post for "${payload.reason.label}"?\nDo you want to submit?',
        ja: 'この投稿を「${payload.reason.label}」理由で通報します。\n受付しますか？',
      ),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      confirmLabel: context.l10n(ko: '신고 접수', en: 'Submit', ja: '受付'),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.createReport(
      targetType: CommunityReportTargetType.post,
      targetId: post.id,
      reason: payload.reason,
      description: payload.description,
    );
    if (!context.mounted) {
      return;
    }
    if (result is Success<void>) {
      rateLimiter.recordReport(post.id);
      _showSnackBar(
        context,
        context.l10n(
          ko: '신고가 접수되었어요. 검토 후 조치할게요',
          en: 'Report submitted. We will review it',
          ja: '通報を受け付けました。確認後に対応します',
        ),
      );
    } else if (result is Err<void>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '신고를 접수하지 못했어요',
          en: 'Failed to submit report',
          ja: '通報を受け付けできませんでした',
        ),
      );
    }
  }

  Future<void> _toggleBlockUser(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(
      blockStatusControllerProvider(post.authorId).notifier,
    );
    final result = await controller.toggleBlock();
    if (result is Err<void> && context.mounted) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '차단 상태를 변경하지 못했어요',
          en: 'Failed to change block status',
          ja: 'ブロック状態を変更できませんでした',
        ),
      );
      return;
    }
    if (!context.mounted) {
      return;
    }
    final state = ref.read(blockStatusControllerProvider(post.authorId));
    final blockedByMe = state.maybeWhen(
      data: (value) => value.blockedByMe,
      orElse: () => false,
    );
    _showSnackBar(
      context,
      blockedByMe
          ? context.l10n(
              ko: '사용자를 차단했어요',
              en: 'User blocked',
              ja: 'ユーザーをブロックしました',
            )
          : context.l10n(
              ko: '차단을 해제했어요',
              en: 'User unblocked',
              ja: 'ブロックを解除しました',
            ),
    );
  }

  Future<void> _confirmBanUser(BuildContext context, WidgetRef ref) async {
    final authorLabel = post.authorName?.isNotEmpty == true
        ? post.authorName!
        : context.l10n(ko: '익명', en: 'Anonymous', ja: '匿名');
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '프로젝트를 먼저 선택해주세요',
          en: 'Please select a project first',
          ja: '先にプロジェクトを選択してください',
        ),
      );
      return;
    }

    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(ko: '커뮤니티 제재', en: 'Community ban', ja: 'コミュニティ制裁'),
      message: context.l10n(
        ko: '$authorLabel 사용자를 이 프로젝트 커뮤니티에서 제재할까요?',
        en: 'Ban $authorLabel from this project community?',
        ja: '$authorLabel さんをこのプロジェクトコミュニティで制裁しますか？',
      ),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      confirmLabel: context.l10n(ko: '차단', en: 'Ban', ja: '制裁'),
      isDestructive: true,
    );

    if (confirm != true || !context.mounted) return;

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.banProjectUser(
      projectCode: projectCode,
      userId: post.authorId,
      reason: 'COMMUNITY_MODERATION',
    );

    if (!context.mounted) return;
    if (result is Success) {
      await ref
          .read(communityFeedControllerProvider.notifier)
          .reload(forceRefresh: true);
      if (context.mounted) {
        _showSnackBar(
          context,
          context.l10n(
            ko: '$authorLabel 사용자를 커뮤니티 제재했어요',
            en: '$authorLabel has been banned from community',
            ja: '$authorLabel さんをコミュニティ制裁しました',
          ),
        );
      }
    } else if (result is Err) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '커뮤니티 제재에 실패했어요',
          en: 'Failed to apply community ban',
          ja: 'コミュニティ制裁に失敗しました',
        ),
      );
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      width: double.infinity,
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      onError: _advanceImage,
    );
  }
}

// ========================================
// EN: Action Buttons — comment, like, bookmark
// KO: 액션 버튼 — 댓글, 좋아요, 북마크
// ========================================

/// EN: Compact feed action button used in timeline-style cards.
/// Used only for the comment action; animated like/bookmark use dedicated widgets.
/// KO: 타임라인형 카드에서 사용하는 컴팩트 액션 버튼.
/// 댓글 액션에만 사용되며, 좋아요/북마크는 전용 애니메이션 위젯을 사용합니다.
class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.xs,
            vertical: GBTSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GBTTypography.labelSmall.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Animated like button with scale micro-interaction on toggle.
/// Scale sequence: 0.88 → 1.08 → 1.0 over 180ms with easeOutBack rebound.
/// Icon crossfades between outline/filled via AnimatedSwitcher.
/// KO: 토글 시 스케일 마이크로 인터랙션이 있는 애니메이션 좋아요 버튼.
/// 스케일 시퀀스: 0.88 → 1.08 → 1.0, 180ms, easeOutBack 리바운드.
/// 아이콘은 AnimatedSwitcher로 아웃라인/채움 간 크로스페이드.
class _AnimatedLikeButton extends StatefulWidget {
  const _AnimatedLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.enabled,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final bool isLiked;
  final int likeCount;
  final bool enabled;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  static const Duration _duration = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 44,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 28,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    unawaited(_controller.forward(from: 0));
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLiked ? widget.activeColor : widget.inactiveColor;
    final label = _formatCount(widget.likeCount);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      toggled: widget.isLiked,
      label:
          '${context.l10n(ko: "좋아요", en: "Likes", ja: "いいね")} ${widget.likeCount}',
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: widget.enabled ? _handleTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.xs,
            ),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Icon(
                      widget.isLiked
                          ? GBTActionIcons.likeActive
                          : GBTActionIcons.like,
                      key: ValueKey(widget.isLiked),
                      size: 17,
                      color: color,
                    ),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GBTTypography.labelSmall.copyWith(color: color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Animated bookmark button with scale micro-interaction on toggle.
/// Scale sequence: 0.88 → 1.08 → 1.0 over 180ms with easeOutBack rebound.
/// Icon crossfades between outline/filled via AnimatedSwitcher.
/// KO: 토글 시 스케일 마이크로 인터랙션이 있는 애니메이션 북마크 버튼.
/// 스케일 시퀀스: 0.88 → 1.08 → 1.0, 180ms, easeOutBack 리바운드.
/// 아이콘은 AnimatedSwitcher로 아웃라인/채움 간 크로스페이드.
class _AnimatedBookmarkButton extends StatefulWidget {
  const _AnimatedBookmarkButton({
    required this.isBookmarked,
    required this.enabled,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    required this.textLabel,
  });

  final bool isBookmarked;
  final bool enabled;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final String textLabel;

  @override
  State<_AnimatedBookmarkButton> createState() =>
      _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<_AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  static const Duration _duration = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 44,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 28,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    unawaited(_controller.forward(from: 0));
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isBookmarked
        ? widget.activeColor
        : widget.inactiveColor;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      toggled: widget.isBookmarked,
      label: widget.isBookmarked
          ? context.l10n(ko: '내 저장 해제', en: 'Remove from saved', ja: '保存解除')
          : context.l10n(ko: '내 저장', en: 'Save for me', ja: '保存'),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: widget.enabled ? _handleTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.xs,
            ),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Icon(
                      widget.isBookmarked
                          ? GBTActionIcons.bookmarkActive
                          : GBTActionIcons.bookmark,
                      key: ValueKey(widget.isBookmarked),
                      size: 17,
                      color: color,
                    ),
                  ),
                  if (widget.textLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.textLabel,
                      style: GBTTypography.labelSmall.copyWith(color: color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Helper functions
// KO: 헬퍼 함수
// ========================================

String _formatCount(int count) {
  final languageCode = Intl.getCurrentLocale().split(RegExp(r'[_-]')).first;
  if (count >= 10000) {
    if (languageCode == 'ja') {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    if (languageCode == 'en') {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '${(count / 10000).toStringAsFixed(1)}만';
  }
  if (count >= 1000) {
    if (languageCode == 'ja') {
      return '${(count / 1000).toStringAsFixed(1)}千';
    }
    if (languageCode == 'en') {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '${(count / 1000).toStringAsFixed(1)}천';
  }
  return count.toString();
}

String _searchScopeLabel(BuildContext context, CommunitySearchScope scope) {
  return switch (scope) {
    CommunitySearchScope.all => context.l10n(ko: '전체', en: 'All', ja: '全体'),
    CommunitySearchScope.title => context.l10n(
      ko: '제목',
      en: 'Title',
      ja: 'タイトル',
    ),
    CommunitySearchScope.author => context.l10n(
      ko: '작성자',
      en: 'Author',
      ja: '作成者',
    ),
    CommunitySearchScope.content => context.l10n(
      ko: '내용',
      en: 'Content',
      ja: '内容',
    ),
    CommunitySearchScope.media => context.l10n(
      ko: '미디어',
      en: 'Media',
      ja: 'メディア',
    ),
  };
}

/// EN: Returns the icon for a community search scope.
/// KO: 커뮤니티 검색 범위 아이콘을 반환합니다.
IconData _searchScopeIcon(CommunitySearchScope scope) {
  return switch (scope) {
    CommunitySearchScope.all => Icons.grid_view_rounded,
    CommunitySearchScope.title => Icons.title_rounded,
    CommunitySearchScope.author => Icons.person_outline_rounded,
    CommunitySearchScope.content => Icons.subject_rounded,
    CommunitySearchScope.media => Icons.image_outlined,
  };
}

/// EN: Returns true when profile can perform moderation actions.
/// KO: 프로필이 모더레이션 액션을 수행할 수 있는지 반환합니다.
bool _isAdminRole({
  String? effectiveAccessLevel,
  String? accountRole,
  Map<String, List<String>>? projectRolesByProject,
  String? projectId,
  String? projectCode,
}) {
  return canModerateProjectCommunity(
    effectiveAccessLevel: effectiveAccessLevel,
    accountRole: accountRole,
    projectRolesByProject: projectRolesByProject,
    projectId: projectId,
    projectCode: projectCode,
  );
}

// ========================================
// EN: Bottom Sheets — My Reports & Community Ban
// KO: 바텀 시트 — 내 신고 내역 & 커뮤니티 제재
// ========================================

class _MyReportsSheet extends ConsumerStatefulWidget {
  const _MyReportsSheet();

  @override
  ConsumerState<_MyReportsSheet> createState() => _MyReportsSheetState();
}

class _MyReportsSheetState extends ConsumerState<_MyReportsSheet> {
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;
  List<CommunityReportSummary> _reports = const [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.getMyReports(page: 0, size: 50);
    if (!mounted) return;
    if (result is Success<List<CommunityReportSummary>>) {
      setState(() {
        _reports = result.data;
        _isLoading = false;
      });
    } else if (result is Err<List<CommunityReportSummary>>) {
      setState(() {
        _reports = const [];
        _isLoading = false;
        _errorMessage = result.failure.userMessage;
      });
    }
  }

  Future<void> _openReportDetail(String reportId) async {
    final repository = await ref.read(communityRepositoryProvider.future);
    final detailResult = await repository.getMyReportDetail(reportId: reportId);
    if (!mounted) return;
    if (detailResult is Err<CommunityReportDetail>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '신고 상세를 불러오지 못했어요',
              en: 'Failed to load report details',
              ja: '通報詳細を読み込めませんでした',
            ),
          ),
        ),
      );
      return;
    }
    final detail = (detailResult as Success<CommunityReportDetail>).data;
    final cancellable =
        detail.status == CommunityReportStatus.open ||
        detail.status == CommunityReportStatus.inReview;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.l10n(ko: '신고 상세', en: 'Report details', ja: '通報詳細'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.l10n(ko: "대상", en: "Target", ja: "対象")}: ${detail.targetType.label}',
              ),
              Text(
                '${context.l10n(ko: "사유", en: "Reason", ja: "理由")}: ${detail.reason.label}',
              ),
              Text(
                '${context.l10n(ko: "상태", en: "Status", ja: "状態")}: ${_reportStatusLabel(context, detail.status)}',
              ),
              Text(
                '${context.l10n(ko: "우선순위", en: "Priority", ja: "優先度")}: ${_reportPriorityLabel(context, detail.priority)}',
              ),
              Text(
                '${context.l10n(ko: "생성", en: "Created", ja: "作成")}: ${_formatDateTime(detail.createdAt)}',
              ),
              if (detail.description?.isNotEmpty == true) ...[
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  '${context.l10n(ko: "설명", en: "Description", ja: "説明")}: ${detail.description!}',
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (cancellable)
            TextButton(
              onPressed: _isCancelling
                  ? null
                  : () async {
                      setState(() => _isCancelling = true);
                      final cancelResult = await repository.cancelMyReport(
                        reportId: detail.id,
                      );
                      if (!mounted) return;
                      setState(() => _isCancelling = false);
                      if (cancelResult is Success<void>) {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        await _loadReports();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n(
                                ko: '신고를 취소했어요',
                                en: 'Report canceled',
                                ja: '通報をキャンセルしました',
                              ),
                            ),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n(
                                ko: '신고 취소에 실패했어요',
                                en: 'Failed to cancel report',
                                ja: '通報キャンセルに失敗しました',
                              ),
                            ),
                          ),
                        );
                      }
                    },
              child: _isCancelling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      context.l10n(
                        ko: '신고 취소',
                        en: 'Cancel report',
                        ja: '通報取り消し',
                      ),
                    ),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n(ko: '닫기', en: 'Close', ja: '閉じる')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.lg,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n(
                      ko: '내 신고 내역',
                      en: 'My reports',
                      ja: '自分の通報履歴',
                    ),
                    style: GBTTypography.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadReports,
                    tooltip: context.l10n(ko: '새로고침', en: 'Refresh', ja: '更新'),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.sm),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: GBTLoading(
                          message: context.l10n(
                            ko: '신고 내역을 불러오는 중...',
                            en: 'Loading report history...',
                            ja: '通報履歴を読み込み中...',
                          ),
                        ),
                      )
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _reports.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n(
                            ko: '신고 내역이 없습니다',
                            en: 'No report history',
                            ja: '通報履歴がありません',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: GBTSpacing.xs),
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return ListTile(
                            onTap: () => _openReportDetail(report.id),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusMd,
                              ),
                            ),
                            tileColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(40),
                            title: Text(
                              '${report.targetType.label} · ${report.reason.label}',
                              style: GBTTypography.bodyMedium,
                            ),
                            subtitle: Text(
                              _formatDateTime(report.createdAt),
                              style: GBTTypography.labelSmall,
                            ),
                            trailing: _ReportStatusChip(
                              status: report.status,
                              labelBuilder: (status) =>
                                  _reportStatusLabel(context, status),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.status, required this.labelBuilder});

  final CommunityReportStatus status;
  final String Function(CommunityReportStatus status) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg) = switch (status) {
      CommunityReportStatus.open => (
        isDark
            ? GBTColors.warning.withValues(alpha: 0.22)
            : GBTColors.warningLight,
        isDark ? GBTColors.warningLight : GBTColors.warningDark,
      ),
      CommunityReportStatus.inReview => (
        isDark ? GBTColors.info.withValues(alpha: 0.22) : GBTColors.infoLight,
        isDark ? GBTColors.infoLight : GBTColors.infoDark,
      ),
      CommunityReportStatus.resolved => (
        isDark
            ? GBTColors.success.withValues(alpha: 0.22)
            : GBTColors.successLight,
        isDark ? GBTColors.successLight : GBTColors.successDark,
      ),
      CommunityReportStatus.rejected => (
        isDark ? GBTColors.error.withValues(alpha: 0.22) : GBTColors.errorLight,
        isDark ? GBTColors.errorLight : GBTColors.errorDark,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        labelBuilder(status),
        style: GBTTypography.labelSmall.copyWith(color: fg),
      ),
    );
  }
}

class _CommunityBanSheet extends ConsumerStatefulWidget {
  const _CommunityBanSheet();

  @override
  ConsumerState<_CommunityBanSheet> createState() => _CommunityBanSheetState();
}

class _CommunityBanSheetState extends ConsumerState<_CommunityBanSheet> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isLookupLoading = false;
  String? _errorMessage;
  String? _lookupMessage;
  List<ProjectCommunityBan> _bans = const [];
  ProjectCommunityBan? _lookupBan;
  String _listQuery = '';
  bool _onlyPermanent = false;
  bool _hideExpired = true;
  CommunityBanSortOption _sortOption = CommunityBanSortOption.newest;

  @override
  void initState() {
    super.initState();
    _loadBans();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadBans() async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n(
          ko: '프로젝트를 먼저 선택해주세요',
          en: 'Please select a project first',
          ja: '先にプロジェクトを選択してください',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.listProjectBans(
      projectCode: projectCode,
      page: 0,
      size: 100,
    );
    if (!mounted) return;

    if (result is Success<List<ProjectCommunityBan>>) {
      setState(() {
        _bans = result.data;
        _isLoading = false;
      });
    } else if (result is Err<List<ProjectCommunityBan>>) {
      setState(() {
        _bans = const [];
        _isLoading = false;
        _errorMessage = result.failure.userMessage;
      });
    }
  }

  Future<void> _lookupBanStatus() async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    final lookupQuery = _userIdController.text.trim();
    if (projectCode == null || projectCode.isEmpty) {
      setState(
        () => _lookupMessage = context.l10n(
          ko: '프로젝트를 먼저 선택해주세요',
          en: 'Please select a project first',
          ja: '先にプロジェクトを選択してください',
        ),
      );
      return;
    }
    if (lookupQuery.isEmpty) {
      setState(
        () => _lookupMessage = context.l10n(
          ko: '사용자 ID/닉네임/이메일을 입력해주세요',
          en: 'Enter user ID/nickname/email',
          ja: 'ユーザーID/ニックネーム/メールを入力してください',
        ),
      );
      return;
    }

    setState(() {
      _isLookupLoading = true;
      _lookupMessage = null;
      _lookupBan = null;
    });

    if (_looksLikeUuid(lookupQuery)) {
      final repository = await ref.read(communityRepositoryProvider.future);
      final result = await repository.getProjectBanStatus(
        projectCode: projectCode,
        userId: lookupQuery,
      );
      if (!mounted) return;

      if (result is Success<ProjectCommunityBan>) {
        setState(() {
          _lookupBan = result.data;
          _isLookupLoading = false;
        });
        return;
      }
      if (result is Err<ProjectCommunityBan>) {
        setState(() {
          _lookupBan = null;
          _isLookupLoading = false;
          _lookupMessage = result.failure.userMessage;
        });
        return;
      }
    }

    if (_bans.isEmpty) {
      await _loadBans();
      if (!mounted) return;
    }

    final normalizedQuery = lookupQuery.toLowerCase();
    final matches = _bans
        .where((ban) {
          final name = ban.bannedUserDisplayName?.toLowerCase() ?? '';
          final email = ban.bannedUserEmail?.toLowerCase() ?? '';
          final userId = ban.bannedUserId.toLowerCase();
          return name.contains(normalizedQuery) ||
              email.contains(normalizedQuery) ||
              userId.contains(normalizedQuery);
        })
        .toList(growable: false);

    if (!mounted) return;
    if (matches.isEmpty) {
      setState(() {
        _lookupBan = null;
        _isLookupLoading = false;
        _lookupMessage = context.l10n(
          ko: '일치하는 제재 사용자를 찾지 못했어요',
          en: 'No matching banned user found',
          ja: '一致する制裁ユーザーが見つかりませんでした',
        );
      });
      return;
    }

    if (matches.length == 1) {
      setState(() {
        _lookupBan = matches.first;
        _isLookupLoading = false;
      });
      return;
    }

    setState(() {
      _lookupBan = null;
      _isLookupLoading = false;
      _listQuery = lookupQuery;
      _filterController.text = lookupQuery;
      _lookupMessage = context.l10n(
        ko: '${matches.length}건이 검색되어 목록 필터에 적용했어요',
        en: '${matches.length} matches found and applied to list filter',
        ja: '${matches.length}件が見つかり、一覧フィルタに適用しました',
      );
    });
  }

  Future<void> _unbanUser(String userId) async {
    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '프로젝트를 먼저 선택해주세요',
              en: 'Please select a project first',
              ja: '先にプロジェクトを選択してください',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.unbanProjectUser(
      projectCode: projectCode,
      userId: userId,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result is Success<void>) {
      if (_lookupBan?.bannedUserId == userId) {
        setState(() {
          _lookupBan = null;
          _lookupMessage = context.l10n(
            ko: '제재를 해제했습니다',
            en: 'Ban removed',
            ja: '制裁を解除しました',
          );
        });
      }
      await _loadBans();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '커뮤니티 제재를 해제했어요',
              en: 'Community ban removed',
              ja: 'コミュニティ制裁を解除しました',
            ),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '제재 해제에 실패했어요',
              en: 'Failed to remove ban',
              ja: '制裁解除に失敗しました',
            ),
          ),
        ),
      );
    }
  }

  bool _looksLikeUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final visibleBans = filterAndSortCommunityBans(
      bans: _bans,
      query: _listQuery,
      sortOption: _sortOption,
      onlyPermanent: _onlyPermanent,
      hideExpired: _hideExpired,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.lg,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n(
                      ko: '커뮤니티 제재 관리',
                      en: 'Community moderation',
                      ja: 'コミュニティ制裁管理',
                    ),
                    style: GBTTypography.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isProcessing ? null : _loadBans,
                    tooltip: context.l10n(ko: '새로고침', en: 'Refresh', ja: '更新'),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.sm),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  hintText: context.l10n(
                    ko: '사용자 ID/닉네임/이메일로 제재 조회',
                    en: 'Search ban by user ID/nickname/email',
                    ja: 'ユーザーID/ニックネーム/メールで制裁照会',
                  ),
                  suffixIcon: _isLookupLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _lookupBanStatus,
                          icon: const Icon(Icons.search),
                        ),
                ),
                onSubmitted: (_) => _lookupBanStatus(),
              ),
              if (_lookupMessage != null) ...[
                const SizedBox(height: GBTSpacing.xs),
                Text(_lookupMessage!, style: GBTTypography.labelSmall),
              ],
              if (_lookupBan != null) ...[
                const SizedBox(height: GBTSpacing.sm),
                Card(
                  child: ListTile(
                    title: Text(
                      _lookupBan!.bannedUserDisplayName?.isNotEmpty == true
                          ? _lookupBan!.bannedUserDisplayName!
                          : _lookupBan!.bannedUserId,
                    ),
                    subtitle: Text(
                      _lookupBan!.expiresAt == null
                          ? context.l10n(
                              ko: '무기한 제재',
                              en: 'Permanent ban',
                              ja: '無期限制裁',
                            )
                          : '${context.l10n(ko: "만료", en: "Expires", ja: "期限")}: ${_formatDateTime(_lookupBan!.expiresAt!)}',
                      style: GBTTypography.labelSmall,
                    ),
                    trailing: TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _unbanUser(_lookupBan!.bannedUserId),
                      child: Text(
                        context.l10n(ko: '해제', en: 'Unban', ja: '解除'),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: GBTSpacing.md),
              Text(
                context.l10n(ko: '현재 제재 목록', en: 'Current bans', ja: '現在の制裁一覧'),
                style: GBTTypography.titleSmall,
              ),
              const SizedBox(height: GBTSpacing.xs),
              TextField(
                controller: _filterController,
                onChanged: (value) {
                  setState(() => _listQuery = value);
                },
                decoration: InputDecoration(
                  hintText: context.l10n(
                    ko: '목록 필터 (이름/ID/사유)',
                    en: 'List filter (name/ID/reason)',
                    ja: '一覧フィルタ (名前/ID/理由)',
                  ),
                  isDense: true,
                  prefixIcon: const Icon(Icons.filter_list),
                  suffixIcon: _listQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _filterController.clear();
                            setState(() => _listQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Wrap(
                spacing: GBTSpacing.sm,
                runSpacing: GBTSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<CommunityBanSortOption>(
                    value: _sortOption,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOption = value);
                    },
                    items: CommunityBanSortOption.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(_banSortLabel(context, option)),
                          ),
                        )
                        .toList(),
                  ),
                  FilterChip(
                    label: Text(
                      context.l10n(
                        ko: '영구 제재만',
                        en: 'Permanent only',
                        ja: '無期限のみ',
                      ),
                    ),
                    selected: _onlyPermanent,
                    onSelected: (selected) {
                      setState(() => _onlyPermanent = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      context.l10n(
                        ko: '만료 제외',
                        en: 'Exclude expired',
                        ja: '期限切れ除外',
                      ),
                    ),
                    selected: _hideExpired,
                    onSelected: (selected) {
                      setState(() => _hideExpired = selected);
                    },
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n(
                    ko: '표시 ${visibleBans.length} / 전체 ${_bans.length}',
                    en: 'Showing ${visibleBans.length} / Total ${_bans.length}',
                    ja: '表示 ${visibleBans.length} / 全体 ${_bans.length}',
                  ),
                  style: GBTTypography.labelSmall,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: GBTLoading(
                          message: context.l10n(
                            ko: '제재 목록을 불러오는 중...',
                            en: 'Loading ban list...',
                            ja: '制裁一覧を読み込み中...',
                          ),
                        ),
                      )
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _bans.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n(
                            ko: '현재 제재 중인 사용자가 없습니다',
                            en: 'No users are currently banned',
                            ja: '現在制裁中のユーザーはいません',
                          ),
                        ),
                      )
                    : visibleBans.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n(
                            ko: '필터 조건에 맞는 제재가 없습니다',
                            en: 'No bans match filter conditions',
                            ja: 'フィルタ条件に一致する制裁がありません',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleBans.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: GBTSpacing.xs),
                        itemBuilder: (context, index) {
                          final ban = visibleBans[index];
                          final displayName = ban.bannedUserDisplayName;
                          final subtitleParts = <String>[
                            'ID: ${ban.bannedUserId}',
                            if (ban.reason?.isNotEmpty == true)
                              '${context.l10n(ko: "사유", en: "Reason", ja: "理由")}: ${ban.reason!}',
                            if (ban.bannedUserEmail?.isNotEmpty == true)
                              '${context.l10n(ko: "이메일", en: "Email", ja: "メール")}: ${ban.bannedUserEmail!}',
                            if (ban.expiresAt != null)
                              '${context.l10n(ko: "만료", en: "Expires", ja: "期限")}: ${_formatDateTime(ban.expiresAt!)}'
                            else
                              context.l10n(
                                ko: '무기한',
                                en: 'Permanent',
                                ja: '無期限',
                              ),
                          ];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusMd,
                              ),
                            ),
                            tileColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(36),
                            title: Text(
                              displayName?.isNotEmpty == true
                                  ? displayName!
                                  : ban.bannedUserId,
                            ),
                            subtitle: Text(
                              subtitleParts.join(' · '),
                              style: GBTTypography.labelSmall,
                            ),
                            trailing: TextButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _unbanUser(ban.bannedUserId),
                              child: Text(
                                context.l10n(ko: '해제', en: 'Unban', ja: '解除'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Helper functions (continued)
// KO: 헬퍼 함수 (계속)
// ========================================

String _resolveProjectName(List<Project> projects, String projectIdOrCode) {
  for (final project in projects) {
    if (project.id == projectIdOrCode || project.code == projectIdOrCode) {
      return project.name;
    }
  }
  return projectIdOrCode;
}

String _reportStatusLabel(BuildContext context, CommunityReportStatus status) {
  switch (status) {
    case CommunityReportStatus.open:
      return context.l10n(ko: '접수', en: 'Open', ja: '受付');
    case CommunityReportStatus.inReview:
      return context.l10n(ko: '검토중', en: 'In review', ja: '確認中');
    case CommunityReportStatus.resolved:
      return context.l10n(ko: '처리완료', en: 'Resolved', ja: '処理完了');
    case CommunityReportStatus.rejected:
      return context.l10n(ko: '반려', en: 'Rejected', ja: '却下');
  }
}

String _reportPriorityLabel(
  BuildContext context,
  CommunityReportPriority priority,
) {
  switch (priority) {
    case CommunityReportPriority.low:
      return context.l10n(ko: '낮음', en: 'Low', ja: '低');
    case CommunityReportPriority.normal:
      return context.l10n(ko: '보통', en: 'Normal', ja: '通常');
    case CommunityReportPriority.high:
      return context.l10n(ko: '높음', en: 'High', ja: '高');
    case CommunityReportPriority.critical:
      return context.l10n(ko: '긴급', en: 'Critical', ja: '緊急');
  }
}

String _banSortLabel(BuildContext context, CommunityBanSortOption option) {
  switch (option) {
    case CommunityBanSortOption.newest:
      return context.l10n(ko: '최신순', en: 'Newest', ja: '新しい順');
    case CommunityBanSortOption.oldest:
      return context.l10n(ko: '오래된순', en: 'Oldest', ja: '古い順');
    case CommunityBanSortOption.expiresSoon:
      return context.l10n(ko: '만료 임박순', en: 'Expiring soon', ja: '期限が近い順');
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}.$month.$day $hour:$minute';
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
              semanticLabel:
                  semanticLabel ??
                  context.l10n(
                    ko: '프로필 사진',
                    en: 'Profile image',
                    ja: 'プロフィール画像',
                  ),
            ),
          );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label:
          semanticLabel ??
          context.l10n(ko: '프로필 보기', en: 'View profile', ja: 'プロフィールを見る'),
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

// ========================================
// EN: New Posts Banner — Twitter-style floating pill shown when new posts are buffered.
// KO: 새 글 배너 — 새 글이 버퍼에 쌓이면 나타나는 트위터 스타일 플로팅 필.
// ========================================

/// EN: Animated floating pill banner that appears when background sync detects new posts.
/// KO: 백그라운드 동기화가 새 글을 감지하면 위에서 슬라이드 인하는 플로팅 배너.
class _NewPostsBanner extends StatelessWidget {
  const _NewPostsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = count > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // EN: Pill background — dark in both themes for contrast against feed.
    // KO: 피드 배경 대비를 위해 라이트/다크 모두 짙은 색상 사용.
    final bgColor = isDark
        ? GBTColors.darkTextPrimary.withValues(alpha: 0.92)
        : GBTColors.textPrimary.withValues(alpha: 0.88);

    final label = count >= 99
        ? context.l10n(ko: '새 글 99+개', en: '99+ new posts', ja: '新着99+件')
        : count == 1
        ? context.l10n(ko: '새 글 1개', en: '1 new post', ja: '新着1件')
        : context.l10n(
            ko: '새 글 $count개',
            en: '$count new posts',
            ja: '新着$count件',
          );

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -2.5),
        duration: Duration(milliseconds: visible ? 320 : 220),
        curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Semantics(
            button: true,
            label: label,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.md,
                  vertical: GBTSpacing.xs2,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: GBTSpacing.xs),
                    Text(
                      label,
                      style: GBTTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
