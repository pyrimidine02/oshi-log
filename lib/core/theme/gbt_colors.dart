/// EN: GBT color system — an urban travel field-notes palette.
/// KO: GBT 색상 시스템 — 도시 여행 필드 노트 팔레트.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// EN: Primary color palette for the application
/// KO: 앱의 기본 색상 팔레트
class GBTColors {
  GBTColors._();

  // ========================================
  // EN: Field-notes anchors. The original GBT blue remains the primary
  //     navigation and action color; warm paper keeps the editorial tone.
  // KO: 필드 노트 기준색. 기존 GBT 블루를 탐색·행동의 주색으로 유지하고,
  //     따뜻한 종이색으로 에디토리얼 분위기를 만듭니다.
  // ========================================
  static const Color fieldPaper = Color(0xFFF7F4EE);
  static const Color fieldPaperRaised = Color(0xFFFFFDF8);
  static const Color fieldInk = Color(0xFF17202A);
  static const Color fieldBlue = Color(0xFF0A66C2);
  static const Color fieldTeal = Color(0xFF2B7773);
  static const Color fieldMapLine = Color(0xFF336C8D);

  static const Color primary = fieldBlue;
  static const Color primaryLight = Color(0xFFE8F3FF);
  static const Color primaryHover = Color(0xFF004182);
  static const Color primaryPressed = Color(0xFF003A75);
  static const Color primaryMuted = Color(0xFFD2E9FF);

  // EN: Harbor teal supports places, visits, and route metadata.
  // KO: 하버 틸은 장소, 방문, 이동 경로 메타데이터를 지원합니다.
  static const Color secondary = fieldTeal;
  static const Color secondaryLight = Color(0xFFDDEDEA);
  static const Color secondaryHover = Color(0xFF235F5C);
  static const Color secondaryPressed = Color(0xFF1B4D4A);

  // ========================================
  // EN: Accent Colors (itinerary, map, and visited states)
  // KO: 강조 색상 (일정, 지도, 방문 상태)
  // ========================================
  static const Color accent = Color(0xFFB97813);
  static const Color accentBlue = fieldMapLine;
  static const Color accentTeal = fieldTeal;

  // ========================================
  // EN: Text Colors (ink-based editorial hierarchy)
  // KO: 텍스트 색상 (먹색 기반 에디토리얼 위계)
  // ========================================
  static const Color textPrimary = fieldInk;
  static const Color textSecondary = Color(0xFF586367);
  static const Color textTertiary = Color(0xFF7D8689);
  static const Color textDisabled = Color(0xFFA9ADAA);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ========================================
  // EN: Surface Colors (warm paper, not sterile white)
  // KO: 표면 색상 (차가운 흰색이 아닌 따뜻한 종이색)
  // ========================================
  static const Color background = fieldPaper;
  static const Color surface = fieldPaperRaised;
  static const Color surfaceVariant = Color(0xFFEFE8DE);
  static const Color surfaceAlternate = Color(0xFFE6DDD0);
  // EN: App-level background layers for consistent page chrome.
  // KO: 페이지 크롬 통일을 위한 앱 레벨 배경 레이어.
  static const Color appBackground = fieldPaper;
  static const Color appBackgroundTopTint = Color(0xFFEEE7DC);

  // ========================================
  // EN: Border & Divider Colors (neutral)
  // KO: 테두리 및 구분선 색상 (뉴트럴)
  // ========================================
  static const Color border = Color(0xFFD8CFC3);
  static const Color borderFocused = primary;
  static const Color divider = Color(0xFFE3DBD0);

  // ========================================
  // EN: Semantic Colors (Status)
  // KO: 의미적 색상 (상태)
  // ========================================
  static const Color success = Color(0xFF2F7D5C);
  static const Color successLight = Color(0xFFDDEDE4);
  static const Color successDark = Color(0xFF235F46);

  static const Color warning = accent;
  static const Color warningLight = Color(0xFFF4E8CE);
  static const Color warningDark = Color(0xFF8F5A0B);

  static const Color error = Color(0xFFB93D35);
  static const Color errorLight = Color(0xFFF5DFDC);
  static const Color errorDark = Color(0xFF922F29);

  static const Color info = fieldMapLine;
  static const Color infoLight = Color(0xFFDDE9EF);
  static const Color infoDark = Color(0xFF285672);

  // ========================================
  // EN: Dark Mode Colors (night-travel journal)
  // KO: 다크 모드 색상 (야간 여행 저널)
  // ========================================
  static const Color darkBackground = Color(0xFF0F1516);
  static const Color darkSurface = Color(0xFF171F20);
  static const Color darkSurfaceVariant = Color(0xFF222C2D);
  static const Color darkSurfaceElevated = Color(0xFF2B3637);
  // EN: Dark app-level background layers to reduce pure-black visual fatigue.
  // KO: 순수 블랙 피로도를 줄이기 위한 다크 앱 레벨 배경 레이어.
  static const Color darkAppBackground = darkBackground;
  static const Color darkAppBackgroundTopTint = Color(0xFF172122);
  static const Color darkTextPrimary = Color(0xFFF8F2E8);
  static const Color darkTextSecondary = Color(0xFFC1C7C3);
  static const Color darkTextTertiary = Color(0xFF929B98);
  static const Color darkPrimary = Color(0xFF8AB4FF);
  static const Color darkPrimaryContainer = Color(0xFF173A67);
  static const Color darkSecondary = Color(0xFF7FD0C9);
  static const Color darkAccent = Color(0xFFF1C36B);
  static const Color darkBorder = Color(0xFF344142);
  static const Color darkBorderSubtle = Color(0xFF263132);

  // ========================================
  // EN: Interactive Colors
  // KO: 인터랙티브 색상
  // ========================================
  static const Color ripple = Color(0x240A66C2);
  static const Color overlay = Color(0x80000000);
  static const Color scrim = Color(0x52000000);

  // ========================================
  // EN: Special Purpose Colors
  // KO: 특수 목적 색상
  // ========================================
  static const Color favorite = primary;
  static const Color verified = success;
  static const Color live = error;
  static const Color rating = accent;

  // ========================================
  // EN: Gradient Definitions
  // KO: 그라디언트 정의
  // ========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0x99000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// EN: Reserved brand gradient for compact feature art.
  /// KO: 작은 기능 아트에만 사용하는 브랜드 그라디언트.
  static const LinearGradient greetingGradient = LinearGradient(
    colors: [primary, primaryHover],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// EN: Dark counterpart for compact feature art.
  /// KO: 작은 기능 아트용 다크 대응 그라디언트.
  static const LinearGradient darkGreetingGradient = LinearGradient(
    colors: [Color(0xFF356EB8), Color(0xFF173A67)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// EN: Carousel card overlay gradient — transparent → 70% black
  /// KO: 캐러셀 카드 오버레이 그라디언트 — 투명 → 70% 검정
  static const LinearGradient carouselCardOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xB3000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.4, 1.0],
  );

  /// EN: Global app background gradient for light mode page consistency.
  /// KO: 라이트 모드 전 페이지 일관성을 위한 전역 배경 그라디언트.
  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [appBackgroundTopTint, appBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.28],
  );

  /// EN: Global app background gradient for dark mode page consistency.
  /// KO: 다크 모드 전 페이지 일관성을 위한 전역 배경 그라디언트.
  static const LinearGradient darkAppBackgroundGradient = LinearGradient(
    colors: [darkAppBackgroundTopTint, darkAppBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.32],
  );

  // EN: Shimmer colors for loading placeholders (neutral)
  // KO: 로딩 플레이스홀더를 위한 쉬머 색상 (뉴트럴)
  static const Color shimmerBase = Color(0xFFE5DDD1);
  static const Color shimmerHighlight = Color(0xFFF8F3EB);
  static const Color darkShimmerBase = Color(0xFF222C2D);
  static const Color darkShimmerHighlight = Color(0xFF344142);
}

/// EN: Color accessibility validator for WCAG compliance
/// KO: WCAG 준수를 위한 색상 접근성 검증기
class GBTColorValidator {
  GBTColorValidator._();

  /// EN: Check if color pair has valid contrast ratio (WCAG AA: 4.5:1)
  /// KO: 색상 쌍이 유효한 대비율을 가지는지 확인 (WCAG AA: 4.5:1)
  static bool hasValidContrast(
    Color foreground,
    Color background, {
    double minimumRatio = 4.5,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >= minimumRatio;
  }

  /// EN: Calculate contrast ratio between two colors
  /// KO: 두 색상 간의 대비율 계산
  static double calculateContrastRatio(Color color1, Color color2) {
    final l1 = color1.computeLuminance();
    final l2 = color2.computeLuminance();
    final brightest = math.max(l1, l2);
    final darkest = math.min(l1, l2);
    return (brightest + 0.05) / (darkest + 0.05);
  }

  /// EN: Get contrasting text color for given background
  /// KO: 주어진 배경에 대한 대비 텍스트 색상 반환
  static Color getContrastingTextColor(Color background) {
    final inkRatio = calculateContrastRatio(GBTColors.textPrimary, background);
    final inverseRatio = calculateContrastRatio(
      GBTColors.textInverse,
      background,
    );
    return inkRatio >= inverseRatio
        ? GBTColors.textPrimary
        : GBTColors.textInverse;
  }
}

/// EN: Extension for color manipulation
/// KO: 색상 조작을 위한 확장
extension GBTColorExtension on Color {
  /// EN: Create color with opacity (using withValues for Flutter 3.27+ compatibility)
  /// KO: 불투명도가 적용된 색상 생성 (Flutter 3.27+ 호환성을 위해 withValues 사용)
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);

  /// EN: Lighten color by percentage
  /// KO: 백분율만큼 색상 밝게
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// EN: Darken color by percentage
  /// KO: 백분율만큼 색상 어둡게
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// EN: Semantic color mappings for consistent UI/UX across the application.
/// Provides meaningful color assignments based on UI/UX Pro Max analysis,
/// ensuring clear visual hierarchy and intentional color usage.
///
/// KO: 애플리케이션 전반의 일관된 UI/UX를 위한 의미론적 색상 매핑.
/// UI/UX Pro Max 분석 기반의 의미 있는 색상 할당을 제공하며,
/// 명확한 시각적 계층 구조와 의도적인 색상 사용을 보장합니다.
class GBTSemanticColors {
  GBTSemanticColors._();

  // ========================================
  // EN: Badge & Status Indicators
  // KO: 배지 및 상태 표시기
  // ========================================

  /// EN: Verified badge color (green) — indicates authenticated/verified status
  /// KO: 인증 배지 색상 (그린) — 인증됨/확인됨 상태 표시
  static const Color badgeVerified = GBTColors.verified; // #10B981

  /// EN: Live badge color (red) — indicates live/active status
  /// KO: 라이브 배지 색상 (레드) — 라이브/활성 상태 표시
  static const Color badgeLive = GBTColors.live; // #EF4444

  /// EN: Info badge color (blue) — general informational badges
  /// KO: 정보 배지 색상 (블루) — 일반 정보 배지
  static const Color badgeInfo = GBTColors.accentBlue; // #3B82F6

  /// EN: Warning badge color (amber) — alerts and warnings
  /// KO: 경고 배지 색상 (엠버) — 경고 및 주의사항
  static const Color badgeWarning = GBTColors.warning; // #F59E0B

  // ========================================
  // EN: Metadata & Auxiliary Information
  // KO: 메타데이터 및 보조 정보
  // ========================================

  /// EN: Distance metadata color (teal) — location distance indicators
  /// KO: 거리 메타데이터 색상 (틸) — 위치 거리 표시기
  static const Color metadataDistance = GBTColors.accentTeal; // #14B8A6

  /// EN: Rating metadata color (amber) — star ratings and scores
  /// KO: 평점 메타데이터 색상 (엠버) — 별점 및 점수
  static const Color metadataRating = GBTColors.rating; // #F59E0B

  // ========================================
  // EN: Interactive Elements (Call-to-Action)
  // KO: 인터랙티브 요소 (콜 투 액션)
  // ========================================

  /// EN: Primary CTA color (sky blue) — main action buttons
  /// KO: 주요 CTA 색상 (스카이 블루) — 기본 액션 버튼
  static const Color ctaPrimary = GBTColors.primary; // #2F7DFF

  /// EN: Secondary CTA color (pink) — high-energy emphasis actions
  /// Provides strong visual weight for important secondary actions
  /// KO: 보조 CTA 색상 (핑크) — 고에너지 강조 액션
  /// 중요한 보조 액션에 강한 시각적 무게 제공
  static const Color ctaSecondary = GBTColors.secondary; // #EC4899

  /// EN: Emphasis CTA color (amber) — general emphasis and highlights
  /// KO: 일반 강조 CTA 색상 (엠버) — 일반 강조 및 하이라이트
  static const Color ctaEmphasis = GBTColors.accent; // #F59E0B

  // ========================================
  // EN: Dark Mode Overrides (Enhanced Visibility)
  // KO: 다크 모드 재정의 (가시성 향상)
  // ========================================

  /// EN: Dark mode distance color (bright teal) — improved contrast on dark surfaces
  /// KO: 다크 모드 거리 색상 (밝은 틸) — 다크 표면에서 개선된 대비
  static const Color darkMetadataDistance = Color(0xFF2DD4BF);

  /// EN: Dark mode info color (bright blue) — improved contrast on dark surfaces
  /// KO: 다크 모드 정보 색상 (밝은 블루) — 다크 표면에서 개선된 대비
  static const Color darkAccentBlue = Color(0xFF60A5FA);

  /// EN: Dark mode verified color (bright green) — improved contrast on dark surfaces
  /// KO: 다크 모드 인증 색상 (밝은 그린) — 다크 표면에서 개선된 대비
  static const Color darkVerified = Color(0xFF34D399);

  // ========================================
  // EN: Helper Methods for Context-Aware Colors
  // KO: 컨텍스트 인식 색상을 위한 헬퍼 메서드
  // ========================================

  /// EN: Get distance color based on theme brightness
  /// KO: 테마 밝기에 따른 거리 색상 반환
  static Color getDistanceColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkMetadataDistance
        : metadataDistance;
  }

  /// EN: Get info badge color based on theme brightness
  /// KO: 테마 밝기에 따른 정보 배지 색상 반환
  static Color getInfoColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkAccentBlue : badgeInfo;
  }

  /// EN: Get verified badge color based on theme brightness
  /// KO: 테마 밝기에 따른 인증 배지 색상 반환
  static Color getVerifiedColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkVerified : badgeVerified;
  }
}
