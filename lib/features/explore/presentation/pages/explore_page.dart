/// EN: Explore tab page — unified container for map, live events,
///     and visit history sub-tabs.
/// KO: 탐방 탭 페이지 — 지도, 라이브, 방문기록 서브탭의 통합 컨테이너.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../live_events/presentation/pages/live_events_page.dart';
import '../../../places/presentation/pages/places_map_page.dart';
import '../../../visits/presentation/pages/visit_history_page.dart';
import '../../../zukan/presentation/pages/zukan_page.dart';

/// EN: Root explore page with 4 sub-tabs: map, live events, visit history, zukan.
/// KO: 지도/라이브/방문기록/성지도감 4개 서브탭이 있는 탐방 탭 루트 페이지.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.initialTabIndex = 0});

  /// EN: Initial sub-tab index (0 = map, 1 = live, 2 = visits, 3 = zukan).
  /// KO: 초기 서브탭 인덱스 (0 = 지도, 1 = 라이브, 2 = 방문기록, 3 = 성지도감).
  final int initialTabIndex;

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // EN: Height reserved at the bottom of the content area for the mode pill.
  // KO: 모드 pill이 차지하는 콘텐츠 영역 하단 높이.
  static const double _modeBarHeight = 54.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      body: Stack(
        children: [
          // EN: TabBarView occupies the full viewport so the map tab can
          //     render edge-to-edge up to the status bar area.
          // KO: 지도 탭이 상태 바 영역까지 꽉 차게 렌더되도록 TabBarView가
          //     전체 뷰포트를 사용합니다.
          //
          // EN: Only reserve additional bottom padding for the floating mode
          //     pill so inner pages can account for the overlay.
          // KO: 플로팅 모드 pill 오버레이를 고려할 수 있도록 하단 패딩만
          //     추가로 예약합니다.
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: mq.padding.bottom + _modeBarHeight,
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              // EN: Disable swipe to prevent conflicts with the map's
              //     pan gesture.
              // KO: 지도 팬 제스처와의 충돌을 방지하기 위해 스와이프를
              //     비활성화합니다.
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PlacesMapPage(),
                LiveEventsPage(),
                VisitHistoryPage(),
                ZukanPage(),
              ],
            ),
          ),

          // EN: Floating mode-selection pill anchored above the system
          //     bottom inset so it is never obscured by the home indicator
          //     or gesture navigation bar.
          // KO: 홈 인디케이터 또는 제스처 내비게이션 바에 가리지 않도록
          //     시스템 하단 여백 위에 고정된 플로팅 모드 선택 pill.
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.padding.bottom + 8,
            height: _modeBarHeight,
            child: _ExploreModePill(controller: _tabController, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Floating pill segmented control for the explore page mode switcher.
// KO: 탐방 페이지 모드 전환을 위한 플로팅 pill 세그먼트 컨트롤.
// ---------------------------------------------------------------------------

class _ExploreModePill extends StatelessWidget {
  const _ExploreModePill({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pillRadius = Theme.of(context).platform == TargetPlatform.iOS
        ? 36.0
        : 24.0;

    final selectedColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final unselectedColor = isDark
        ? GBTColors.darkTextSecondary.withValues(alpha: 0.80)
        : GBTColors.textSecondary.withValues(alpha: 0.80);
    final gradientColors = isDark
        ? [
            GBTColors.darkSurface.withValues(alpha: 0.95),
            GBTColors.darkSurfaceVariant.withValues(alpha: 0.95),
          ]
        : [
            GBTColors.surface.withValues(alpha: 0.95),
            GBTColors.appBackground.withValues(alpha: 0.95),
          ];
    final borderColor = isDark
        ? GBTColors.darkBorder.withValues(alpha: 0.72)
        : GBTColors.border.withValues(alpha: 0.82);

    final labels = [
      context.l10n(ko: '지도', en: 'Map', ja: 'マップ'),
      context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
      context.l10n(ko: '방문기록', en: 'Visits', ja: '訪問'),
      context.l10n(ko: '성지도감', en: 'Collection', ja: '聖地図鑑'),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: GBTSpacing.sm2),
          child: Center(
            child: IntrinsicWidth(
              child: Container(
                // EN: Outer container provides the drop-shadow layer.
                // KO: 외부 컨테이너가 드롭 섀도우 레이어를 제공합니다.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pillRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.32 : 0.12,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipPath(
                  // EN: Continuous corner profile matches _CommunitySubBottomNav
                  //     visual DNA.
                  // KO: _CommunitySubBottomNav와 동일한 연속 곡률 프로파일을
                  //     적용합니다.
                  clipper: ShapeBorderClipper(
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(pillRadius),
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: gradientColors,
                        ),
                        border: Border.all(color: borderColor, width: 0.8),
                        borderRadius: BorderRadius.circular(pillRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(labels.length, (i) {
                          final isSelected = controller.index == i;
                          final primary = isDark
                              ? GBTColors.darkPrimary
                              : GBTColors.primary;
                          // EN: Announce mode label with selection state for
                          //     screen-reader users.
                          // KO: 스크린 리더 사용자를 위해 모드 레이블과
                          //     선택 상태를 함께 안내합니다.
                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label:
                                '${labels[i]} 탭${isSelected ? ', 현재 선택됨' : ''}',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.animateTo(i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 130),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primary.withValues(alpha: 0.14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    pillRadius,
                                  ),
                                ),
                                child: Text(
                                  labels[i],
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? selectedColor
                                        : unselectedColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
