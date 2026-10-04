/// EN: Unified segmented tab bar used across pages.
/// KO: 페이지 전반에서 사용하는 통합 세그먼트 탭바입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Pill-style segmented tab bar wrapper for consistent page UI.
/// KO: 일관된 페이지 UI를 위한 필 스타일 세그먼트 탭바 래퍼입니다.
class GBTSegmentedTabBar extends StatelessWidget {
  const GBTSegmentedTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.margin,
    this.padding = const EdgeInsets.all(3),
    this.isScrollable = false,
    this.height,
    this.borderRadius = GBTSpacing.radiusMd,
    this.indicatorBorderRadius = GBTSpacing.radiusSm + 1,
    this.indicatorShadow = false,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.labelPadding,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;
  final double? height;
  final double borderRadius;
  final double indicatorBorderRadius;
  final bool indicatorShadow;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final EdgeInsetsGeometry? labelPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeColor = colors.primary;
    final scrollable =
        isScrollable || MediaQuery.textScalerOf(context).scale(14) > 18.2;
    final resolvedLabelStyle = (labelStyle ?? GBTTypography.labelLarge)
        .copyWith(fontWeight: FontWeight.w700);
    final resolvedUnselectedLabelStyle =
        unselectedLabelStyle ?? labelStyle ?? GBTTypography.labelLarge;

    final segmented = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GBTSpacing.minTouchTarget),
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
        padding: padding,
        // EN: A quiet paper track keeps local modes distinct from global
        // bottom navigation without introducing glass or floating depth.
        // KO: 차분한 페이퍼 트랙으로 로컬 모드를 전역 하단 내비게이션과
        // 구분하되 글래스나 떠 있는 깊이감은 추가하지 않습니다.
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.outlineVariant, width: 0.8),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: scrollable,
          tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
          indicator: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(indicatorBorderRadius),
            boxShadow: indicatorShadow
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          // EN: Elastic slide gives the pill a soft, liquid-glass squash/stretch
          // as it moves between tabs. The transition's actual duration follows
          // the owning TabController (Flutter default ~300ms, close to the
          // ~200ms feel requested) — TabBar has no per-widget duration override.
          // KO: 엘라스틱 슬라이드는 필이 탭 사이를 이동할 때 부드러운 리퀴드
          // 글래스 squash/stretch 느낌을 줍니다. 실제 전환 시간은 컨트롤러를
          // 소유한 TabController를 따릅니다 (Flutter 기본 ~300ms로 요청된
          // ~200ms 느낌에 근접) — TabBar는 위젯 단위 duration 오버라이드를
          // 제공하지 않습니다.
          indicatorAnimation: TabIndicatorAnimation.elastic,
          dividerColor: Colors.transparent,
          labelColor: activeColor,
          unselectedLabelColor: colors.onSurfaceVariant,
          labelStyle: resolvedLabelStyle,
          unselectedLabelStyle: resolvedUnselectedLabelStyle,
          labelPadding: labelPadding,
          tabs: tabs,
        ),
      ),
    );

    if (height == null) {
      return segmented;
    }
    return SizedBox(height: height, child: segmented);
  }
}
