/// EN: Clean-sheet Explore workspace with a floating lower mode dock.
/// KO: 하단 플로팅 모드 도크를 사용하는 새 탐방 워크스페이스.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../live_events/presentation/field_events/field_live_events_page.dart';
import '../../../places/presentation/pages/places_map_page.dart';
import '../../../visits/presentation/field_visit_ledger/field_visit_ledger_page.dart';
import '../../../zukan/presentation/field_archive/field_zukan_archive_page.dart';
import 'field_explore_mode_dock.dart';

/// EN: Explore answers what is around the fan right now.
/// KO: 지금 팬 주변에 무엇이 있는지 답하는 탐방 화면입니다.
class FieldExplorePage extends StatefulWidget {
  const FieldExplorePage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<FieldExplorePage> createState() => _FieldExplorePageState();
}

class _FieldExplorePageState extends State<FieldExplorePage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    )..addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(covariant FieldExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialTabIndex.clamp(0, 3);
    if (oldWidget.initialTabIndex != widget.initialTabIndex &&
        _controller.index != nextIndex) {
      // EN: Route-owned tab state must remain the source of truth.
      // KO: 라우트가 소유한 탭 상태를 계속 단일 기준으로 유지합니다.
      _controller.index = nextIndex;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || _controller.indexIsChanging) return;
    setState(() {});
  }

  void _selectMode(int index) {
    if (_controller.index == index) return;
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.index = index;
    } else {
      _controller.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainNavigationOffset = _mainNavigationOffset(context);
    final labels = [
      context.l10n(ko: '지도', en: 'Map', ja: 'マップ'),
      context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
      context.l10n(ko: '기록', en: 'Visits', ja: '訪問'),
      context.l10n(ko: '도감', en: 'Stamps', ja: '図鑑'),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // EN: Reserve the entire lower navigation stack so map controls,
            //     event rows, and archive actions never sit beneath either dock.
            // KO: 지도 컨트롤, 이벤트 행, 도감 액션이 어느 도크에도 가리지
            //     않도록 하단 내비게이션 스택 전체만큼 공간을 확보합니다.
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    mainNavigationOffset +
                    FieldExploreModeDock.height +
                    GBTSpacing.sm,
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: TabBarView(
                  key: const ValueKey('field-explore-content'),
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PlacesMapPage(
                      embedded: true,
                      isActive: _controller.index == 0,
                    ),
                    const FieldLiveEventsPage(embedded: true),
                    const FieldVisitLedgerPage(
                      embedded: true,
                      bottomClearance: GBTSpacing.md,
                    ),
                    const FieldZukanArchivePage(embedded: true),
                  ],
                ),
              ),
            ),
            Positioned(
              left: GBTSpacing.pageHorizontal,
              right: GBTSpacing.pageHorizontal,
              bottom: mainNavigationOffset,
              child: FieldExploreModeDock(
                selectedIndex: _controller.index,
                labels: labels,
                onSelected: _selectMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _mainNavigationOffset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final inheritedBottom = mediaQuery.padding.bottom;
    final deviceBottom = mediaQuery.viewPadding.bottom;
    // EN: MainScaffold.extendBody injects the measured bottom-nav height into
    //     MediaQuery.padding. Reusing bottomNavClearanceOf here would add the
    //     64dp bar a second time and push this dock far above the navigation.
    // KO: MainScaffold.extendBody는 측정된 하단바 높이를 MediaQuery.padding에
    //     주입합니다. 여기서 bottomNavClearanceOf를 다시 쓰면 64dp가 중복돼
    //     이 도크가 내비게이션보다 과도하게 위로 올라갑니다.
    final navigationHeight = inheritedBottom >= GBTSpacing.bottomNavHeight
        ? inheritedBottom
        : GBTSpacing.bottomNavHeight + deviceBottom;
    return navigationHeight + GBTSpacing.sm;
  }
}
