/// EN: GBT spacing system based on 8px grid (KT UXD design system)
/// KO: 8px 그리드 기반 GBT 간격 시스템 (KT UXD 디자인 시스템)
library;

import 'package:flutter/widgets.dart';

/// EN: Spacing constants following 8px grid system
/// KO: 8px 그리드 시스템을 따르는 간격 상수
class GBTSpacing {
  GBTSpacing._();

  // ========================================
  // EN: Base Scale (8px grid + organic off-grid values)
  // KO: 기본 스케일 (8px 그리드 + 유기적 오프그리드 값)
  // ========================================
  static const double none = 0.0; // 0px
  static const double xxs = 2.0; // 2px  - Micro spacing
  static const double xs = 4.0; // 4px  - Extra small
  static const double xs2 = 6.0; // 6px  - Off-grid
  static const double sm = 8.0; // 8px  - Small
  static const double sm2 = 10.0; // 10px - Off-grid
  static const double md2 = 14.0; // 14px - Off-grid
  static const double md = 16.0; // 16px - Medium (base)
  static const double md3 = 18.0; // 18px - Off-grid
  static const double lg2 = 20.0; // 20px - Off-grid
  static const double lg = 24.0; // 24px - Large
  static const double lg3 = 28.0; // 28px - Off-grid
  static const double xl = 32.0; // 32px - Extra large
  static const double xl2 = 40.0; // 40px - Off-grid
  static const double xxl = 48.0; // 48px - 2x Extra large
  static const double xxxl = 64.0; // 64px - Maximum

  // ========================================
  // EN: Component Specific Spacing
  // KO: 컴포넌트별 간격
  // ========================================
  static const double cardPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double cardRadius = 20.0;

  static const double listItemPadding = 16.0;
  static const double listItemSpacing = 12.0;

  static const double sectionSpacing = 32.0;
  static const double sectionSpacingLg = 40.0;
  static const double sectionSpacingXl = 48.0;
  static const double sectionMargin = 32.0;

  static const double carouselItemGap = 12.0;

  static const double formFieldSpacing = 16.0;
  static const double formGroupSpacing = 24.0;

  // ========================================
  // EN: Page Layout Spacing
  // KO: 페이지 레이아웃 간격
  // ========================================
  static const double pageHorizontal = 16.0;
  static const double pageVertical = 16.0;
  static const double pageTop = 16.0;
  static const double pageBottom = 24.0;

  // ========================================
  // EN: Navigation & App Bar
  // KO: 네비게이션 및 앱 바
  // ========================================
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;

  /// EN: Grows persistent navigation just enough for the platform text scale
  /// while preserving the existing silhouette at the default scale.
  /// KO: 기본 글자 크기에서는 기존 실루엣을 유지하고, 운영체제 글자 확대 시
  /// 내용이 잘리지 않을 만큼만 고정 내비게이션 높이를 늘립니다.
  static double scaledBottomNavHeight(
    BuildContext context, {
    double baseHeight = bottomNavHeight,
  }) {
    final scaledLabelSize = MediaQuery.textScalerOf(context).scale(11);
    final extraHeight = (scaledLabelSize - 11).clamp(0.0, 16.0);
    return baseHeight + extraHeight;
  }

  /// EN: Content clearance for the persistent bottom bar and breathing room.
  /// KO: 고정 하단 바와 여백을 함께 확보하는 콘텐츠 클리어런스.
  static const double bottomNavClearance = bottomNavHeight + md;

  /// EN: Includes the device bottom inset in persistent-bar clearance.
  /// KO: 고정 하단 바 클리어런스에 기기 하단 안전영역을 포함합니다.
  static double bottomNavClearanceOf(
    BuildContext context, {
    double barHeight = bottomNavHeight,
  }) {
    return barHeight + MediaQuery.paddingOf(context).bottom + md;
  }

  static const double fabSize = 56.0;
  static const double tabBarHeight = 48.0;

  // ========================================
  // EN: Touch Target (Accessibility)
  // KO: 터치 타겟 (접근성)
  // ========================================
  static const double touchTarget = 48.0;
  static const double minTouchTarget = 44.0;
  static const double iconButtonSize = 48.0;

  // ========================================
  // EN: Icon Sizes
  // KO: 아이콘 크기
  // ========================================
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ========================================
  // EN: Border Radius
  // KO: 테두리 반지름
  // ========================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  /// EN: Card surfaces (2026 large-radius trend) — between lg and xl.
  /// KO: 카드 표면 (2026 라지 라운드 트렌드) — lg와 xl 사이.
  static const double radiusCard = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // ========================================
  // EN: Elevation (Shadow Depth)
  // KO: 고도 (그림자 깊이)
  // ========================================
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // ========================================
  // EN: Common EdgeInsets
  // KO: 공통 EdgeInsets
  // ========================================
  static const EdgeInsets paddingNone = EdgeInsets.zero;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: sm,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: lg,
  );

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: lg,
  );

  static const EdgeInsets paddingPage = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );

  // ========================================
  // EN: Common SizedBox
  // KO: 공통 SizedBox
  // ========================================
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);

  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
}

/// EN: Responsive spacing utilities
/// KO: 반응형 간격 유틸리티
class GBTResponsiveSpacing {
  GBTResponsiveSpacing._();

  /// EN: Get responsive spacing based on screen width
  /// KO: 화면 너비에 따른 반응형 간격 반환
  static double responsive(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 1024 && desktop != null) {
      return desktop;
    } else if (width >= 600 && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// EN: Get page horizontal padding based on screen width
  /// KO: 화면 너비에 따른 페이지 수평 패딩 반환
  static double pageHorizontal(BuildContext context) {
    return responsive(
      context,
      mobile: GBTSpacing.pageHorizontal,
      tablet: GBTSpacing.lg,
      desktop: GBTSpacing.xl,
    );
  }

  /// EN: Get responsive section spacing based on screen size
  /// KO: 화면 크기에 따른 반응형 섹션 간격 반환
  static double responsiveSectionSpacing(BuildContext context) {
    return GBTResponsiveSpacing.responsive(
      context,
      mobile: GBTSpacing.sectionSpacing,
      tablet: GBTSpacing.sectionSpacingLg,
      desktop: GBTSpacing.sectionSpacingXl,
    );
  }

  /// EN: Check if current screen is mobile size
  /// KO: 현재 화면이 모바일 크기인지 확인
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  /// EN: Check if current screen is tablet size
  /// KO: 현재 화면이 태블릿 크기인지 확인
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  /// EN: Check if current screen is desktop size
  /// KO: 현재 화면이 데스크톱 크기인지 확인
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1024;
  }
}
