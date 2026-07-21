/// EN: Explore workspace with a compact mode control above main navigation.
/// KO: 메인 내비게이션 바로 위에 간결한 모드 제어를 둔 탐방 화면입니다.
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
    final modeBottomOffset = _mainNavigationOffset(context);
    final modeContentClearance =
        modeBottomOffset + FieldExploreModeDock.height + GBTSpacing.sm;
    final labels = [
      context.l10n(ko: '지도', en: 'Map', ja: 'マップ'),
      context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
      context.l10n(ko: '기록', en: 'Visits', ja: '訪問'),
      context.l10n(ko: '도감', en: 'Stamps', ja: '図鑑'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              key: const ValueKey('field-explore-content'),
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PlacesMapPage(
                  embedded: true,
                  isActive: _controller.index == 0,
                  bottomInset: MediaQuery.paddingOf(context).bottom,
                  modeLabels: labels,
                  selectedModeIndex: _controller.index,
                  onModeSelected: _selectMode,
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    key: const ValueKey('field-explore-safe-content-1'),
                    padding: EdgeInsets.only(bottom: modeContentClearance),
                    child: const FieldLiveEventsPage(embedded: true),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: KeyedSubtree(
                    key: const ValueKey('field-explore-safe-content-2'),
                    child: FieldVisitLedgerPage(
                      embedded: true,
                      bottomClearance: modeContentClearance,
                      onOpenMap: () => _selectMode(0),
                      onOpenEvents: () => _selectMode(1),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    key: const ValueKey('field-explore-safe-content-3'),
                    padding: EdgeInsets.only(bottom: modeContentClearance),
                    child: const FieldZukanArchivePage(embedded: true),
                  ),
                ),
              ],
            ),
          ),
          if (_controller.index != 0)
            Positioned(
              key: const ValueKey('field-explore-bottom-mode-rail'),
              left: 0,
              right: 0,
              bottom: modeBottomOffset,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.md,
                  ),
                  child: FieldExploreModeDock(
                    selectedIndex: _controller.index,
                    labels: labels,
                    onSelected: _selectMode,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _mainNavigationOffset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final inheritedBottom = mediaQuery.padding.bottom;
    final deviceBottom = mediaQuery.viewPadding.bottom;
    // EN: MainScaffold.extendBody already injects the measured navigation
    //     height into padding. Add a fallback only outside that scaffold.
    // KO: MainScaffold.extendBody가 측정된 내비게이션 높이를 padding에 이미
    //     주입합니다. 해당 Scaffold 밖에서만 기본 높이를 보완합니다.
    final navigationHeight = inheritedBottom >= GBTSpacing.bottomNavHeight
        ? inheritedBottom
        : GBTSpacing.scaledBottomNavHeight(context) + deviceBottom;
    return navigationHeight + GBTSpacing.sm;
  }
}
