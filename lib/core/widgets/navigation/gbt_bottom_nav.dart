/// EN: GBT bottom navigation — the retained glass silhouette, recolored as a
///     compact field-notes dock.
/// KO: GBT 하단 네비게이션 — 기존 유리 실루엣을 유지한 필드 노트 도크.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/locale_text.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';
import '../../theme/gbt_animations.dart';

/// EN: Bottom navigation item definition.
/// KO: 하단 네비게이션 아이템 정의.
class GBTBottomNavItem {
  const GBTBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? semanticLabel;
}

/// EN: Bottom navigation bar with the app's retained floating silhouette.
///     A restrained translucent surface keeps content context visible while
///     preserving legibility and familiar five-destination navigation.
/// KO: 앱의 기존 플로팅 실루엣을 유지한 하단 네비게이션 바입니다.
///     절제된 반투명 표면으로 콘텐츠 맥락과 5개 목적지의 익숙함을
///     함께 유지합니다.
class GBTBottomNav extends StatelessWidget {
  const GBTBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.height = GBTSpacing.bottomNavHeight,
  });

  /// EN: Navigation items.
  /// KO: 네비게이션 아이템 목록.
  final List<GBTBottomNavItem> items;

  /// EN: Currently selected index.
  /// KO: 현재 선택된 인덱스.
  final int currentIndex;

  /// EN: Tap handler for item selection.
  /// KO: 아이템 선택 시 탭 핸들러.
  final ValueChanged<int> onTap;

  /// EN: Navigation bar content height (excluding safe area).
  /// KO: 네비게이션 바 콘텐츠 높이 (SafeArea 제외).
  final double height;

  static const _kRadius = Radius.circular(40);
  static const _kBorderRadius = BorderRadius.vertical(top: _kRadius);

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = GBTSpacing.scaledBottomNavHeight(
      context,
      baseHeight: height,
    );
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return _buildAndroidBottomNav(context, effectiveHeight);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // EN: Outer shadow — rendered outside ClipRRect so it's not clipped.
      // KO: 외부 그림자 — ClipRRect에 의해 잘리지 않도록 외부에 배치.
      decoration: BoxDecoration(
        borderRadius: _kBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
            blurRadius: 36,
            offset: const Offset(0, -8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _kBorderRadius,
        child: BackdropFilter(
          // EN: Blur what's behind the bar — liquid glass core effect.
          // KO: 바 뒤쪽 화면을 블러 처리 — 리퀴드 글라스 핵심 효과.
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // EN: Semi-transparent fill over the blur — plum-tinted in dark
              // mode to match the live-house surface tone.
              // KO: 블러 위에 반투명 채색 — 다크 모드는 라이브하우스 플럼
              // 표면 톤에 맞춰 틴트.
              color: isDark
                  ? GBTColors.darkBackground.withValues(alpha: 0.88)
                  : GBTColors.surface.withValues(alpha: 0.90),
              // EN: Top glass edge — subtle highlight line.
              // KO: 상단 유리 테두리 — 미세한 하이라이트 선.
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.white.withValues(alpha: 0.60),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: effectiveHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    items.length,
                    (index) => _BottomNavItem(
                      item: items[index],
                      isSelected: currentIndex == index,
                      isDark: isDark,
                      onTap: () => onTap(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidBottomNav(BuildContext context, double effectiveHeight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(28);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.34 : 0.16);
    final surfaceTint = colorScheme.primary.withValues(alpha: 0.08);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: isDark ? 26 : 20,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
            ],
          ),
          // EN: ClipRRect + BackdropFilter brings the Android bar closer to
          // the iOS liquid-glass look above — translucent fill over a
          // blurred backdrop, rounded floating container — while the
          // Material inside keeps full NavigationBar ergonomics (ripple,
          // indicator, a11y).
          // KO: ClipRRect + BackdropFilter로 위 iOS 리퀴드 글래스 룩에
          // 가깝게 — 블러 처리된 배경 위에 반투명 채움, 둥근 플로팅
          // 컨테이너 — Material 내부는 NavigationBar의 리플·인디케이터·
          // 접근성 등 Material 고유 동작을 그대로 유지합니다.
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Material(
                color: colorScheme.surface.withValues(
                  alpha: isDark ? 0.72 : 0.80,
                ),
                surfaceTintColor: surfaceTint,
                shadowColor: shadowColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                clipBehavior: Clip.antiAlias,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return GBTTypography.labelSmall.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: isSelected ? 11 : 10.5,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: isSelected ? 26 : 23,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentIndex,
                    height: effectiveHeight,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    backgroundColor: Colors.transparent,
                    indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
                    onDestinationSelected: (index) {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                    destinations: items
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.activeIcon),
                            label: item.label,
                            tooltip: item.semanticLabel ?? item.label,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Individual bottom navigation destination with a compact vertical layout.
/// KO: 간결한 수직 레이아웃의 개별 하단 네비게이션 목적지입니다.
class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final GBTBottomNavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final motionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : GBTAnimations.fast;
    // EN: Keep inactive destinations comfortably legible on translucent surfaces.
    // KO: 반투명 표면에서도 비활성 목적지를 편안하게 읽을 수 있게 유지합니다.
    final unselectedColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final iconColor = isSelected ? selectedColor : unselectedColor;
    final labelColor = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: Semantics(
        label: item.semanticLabel ?? item.label,
        hint: isSelected
            ? null
            : context.l10n(
                ko: '탭하면 ${item.label} 탭으로 이동합니다',
                en: 'Tap to open ${item.label}',
                ja: 'タップして${item.label}を開きます',
              ),
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Center(
            // EN: Soft pill indicator behind icon+label — fades and scales in
            // when the tab becomes active.
            // KO: 아이콘+라벨 뒤 소프트 필 인디케이터 — 탭 활성화 시 페이드·스케일.
            child: AnimatedContainer(
              duration: motionDuration,
              curve: GBTAnimations.defaultCurve,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor.withValues(alpha: isDark ? 0.20 : 0.13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.02 : 1.0,
                    duration: motionDuration,
                    curve: GBTAnimations.defaultCurve,
                    child: AnimatedSwitcher(
                      duration: motionDuration,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        key: ValueKey(isSelected),
                        color: iconColor,
                        // EN: Slightly larger icon when selected for visual emphasis.
                        // KO: 선택 시 아이콘 약간 크게 — 시각적 강조.
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GBTTypography.labelSmall.copyWith(
                      color: labelColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
