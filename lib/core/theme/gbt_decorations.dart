/// EN: GBT decoration system for consistent shadows, borders, and surfaces
/// KO: 일관된 그림자, 테두리, 표면을 위한 GBT 데코레이션 시스템
library;

import 'package:flutter/material.dart';

import 'gbt_colors.dart';
import 'gbt_spacing.dart';

/// EN: Consistent box shadow presets
/// KO: 일관된 박스 그림자 프리셋
class GBTShadows {
  GBTShadows._();

  // ========================================
  // EN: Light Mode Shadows
  // KO: 라이트 모드 그림자
  // ========================================

  /// EN: Subtle shadow for cards at rest (single layer)
  /// KO: 정지 상태 카드를 위한 미세한 그림자 (단일 레이어)
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  /// EN: Medium shadow for elevated elements (single layer)
  /// KO: 높은 요소를 위한 중간 그림자 (단일 레이어)
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];

  /// EN: Large shadow for modals/sheets
  /// KO: 모달/시트를 위한 큰 그림자
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

  /// EN: Extra large shadow for floating elements
  /// KO: 플로팅 요소를 위한 초대형 그림자
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 48, offset: Offset(0, 16)),
  ];

  /// EN: Colored glow shadow for accent elements
  /// KO: 강조 요소를 위한 색상 글로우 그림자
  static List<BoxShadow> accentGlow({double opacity = 0.25}) => [
    BoxShadow(
      color: GBTColors.accent.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// EN: Secondary color glow
  /// KO: 보조 색상 글로우
  static List<BoxShadow> secondaryGlow({double opacity = 0.25}) => [
    BoxShadow(
      color: GBTColors.secondary.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  /// EN: Primary color glow for purple-accented elements
  /// KO: 보라색 강조 요소를 위한 기본 색상 글로우
  static List<BoxShadow> primaryGlow({double opacity = 0.25}) => [
    BoxShadow(
      color: GBTColors.primary.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ========================================
  // EN: Dark Mode Shadows (using colored glows)
  // KO: 다크 모드 그림자 (색상 글로우 사용)
  // ========================================

  /// EN: Subtle border glow for dark mode cards
  /// KO: 다크 모드 카드를 위한 미세한 테두리 글로우
  static const List<BoxShadow> darkSm = [
    BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// EN: Medium glow for dark mode
  /// KO: 다크 모드를 위한 중간 글로우
  static const List<BoxShadow> darkMd = [
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// EN: Large glow for dark mode modals
  /// KO: 다크 모드 모달을 위한 큰 글로우
  static const List<BoxShadow> darkLg = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// EN: Consistent decoration presets for cards, containers, surfaces
/// KO: 카드, 컨테이너, 표면을 위한 일관된 데코레이션 프리셋
class GBTDecorations {
  GBTDecorations._();

  // ========================================
  // EN: Card Decorations
  // KO: 카드 데코레이션
  // ========================================

  /// EN: Default card decoration — border only, no shadow
  /// KO: 기본 카드 데코레이션 — 테두리만, 그림자 없음
  static BoxDecoration card({bool isDark = false}) => BoxDecoration(
    color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surface,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
    border: Border.all(
      color: isDark ? GBTColors.darkBorderSubtle : GBTColors.border,
      width: isDark ? 0.5 : 1,
    ),
  );

  /// EN: Elevated card decoration — subtle single shadow
  /// KO: 높은 카드 데코레이션 — 미세한 단일 그림자
  static BoxDecoration cardElevated({bool isDark = false}) => BoxDecoration(
    color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
    boxShadow: isDark ? GBTShadows.darkSm : GBTShadows.sm,
    border: isDark ? Border.all(color: GBTColors.darkBorder, width: 0.5) : null,
  );

  // ========================================
  // EN: Surface Decorations
  // KO: 표면 데코레이션
  // ========================================

  /// EN: Subtle surface decoration
  /// KO: 미세한 표면 데코레이션
  static BoxDecoration surface({bool isDark = false}) => BoxDecoration(
    color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
  );

  /// EN: Interactive surface with border on hover/focus
  /// KO: 호버/포커스 시 테두리가 있는 인터랙티브 표면
  static BoxDecoration surfaceInteractive({
    bool isDark = false,
    bool isActive = false,
  }) => BoxDecoration(
    color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
    border: Border.all(
      color: isActive
          ? (isDark ? GBTColors.secondary : GBTColors.primary)
          : (isDark ? GBTColors.darkBorderSubtle : GBTColors.border),
      width: isActive ? 1.5 : 1,
    ),
  );

  // ========================================
  // EN: Badge Decorations
  // KO: 배지 데코레이션
  // ========================================

  /// EN: Live badge decoration
  /// KO: 라이브 배지 데코레이션
  static BoxDecoration liveBadge() => BoxDecoration(
    color: GBTColors.live,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
    boxShadow: [
      BoxShadow(
        color: GBTColors.live.withValues(alpha: 0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// EN: Verified badge decoration
  /// KO: 인증 배지 데코레이션
  static BoxDecoration verifiedBadge() => BoxDecoration(
    color: GBTColors.verified,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
  );

  // ========================================
  // EN: Sheet / Modal Decorations
  // KO: 시트 / 모달 데코레이션
  // ========================================

  /// EN: Bottom sheet decoration (16px radius)
  /// KO: 바텀 시트 데코레이션 (16px 반지름)
  static BoxDecoration bottomSheet({bool isDark = false}) => BoxDecoration(
    color: isDark ? GBTColors.darkSurface : GBTColors.surface,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(GBTSpacing.radiusLg),
    ),
    boxShadow: isDark ? GBTShadows.darkLg : GBTShadows.lg,
  );

  // ========================================
  // EN: Image-First Card Decoration (Journey Ticket cards)
  // KO: 이미지 우선 카드 데코레이션 ("여정의 티켓" 카드)
  // ========================================

  /// EN: Image-first card shell — 2026 large-radius (radiusCard), border-subtle
  /// for depth instead of a heavy shadow (place/event/carousel cards).
  /// KO: 2026 라지 라운드(radiusCard)의 이미지 우선 카드 셸 — 무거운 그림자 대신
  /// border-subtle로 깊이감을 표현합니다 (장소/이벤트/캐러셀 카드).
  static BoxDecoration imageCard({bool isDark = false}) => BoxDecoration(
    color: isDark ? GBTColors.darkSurface : GBTColors.surface,
    borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
    border: Border.all(
      color: isDark
          ? GBTColors.darkBorderSubtle
          : GBTColors.border.withValues(alpha: 0.6),
      width: isDark ? 0.75 : 1,
    ),
  );

  // ========================================
  // EN: Liquid-Glass Decorations (cheap, no blur)
  // KO: 리퀴드 글래스 데코레이션 (저비용, 블러 없음)
  // ========================================

  /// EN: Cheap pseudo-glass surface for use inside lists/tracks where a real
  /// [BackdropFilter] would be too costly per-item — translucent surfaceVariant
  /// tint + hairline border, no blur. For real frosted blur, use GBTGlassPanel
  /// instead (sparingly — a handful of surfaces per screen).
  /// KO: 리스트/트랙 내부에서 실제 [BackdropFilter]를 아이템마다 쓰기엔 비용이
  /// 큰 경우를 위한 저비용 유사 글래스 표면 — 반투명 surfaceVariant 틴트 +
  /// 헤어라인 보더, 블러 없음. 실제 프로스티드 블러가 필요하면 GBTGlassPanel을
  /// 사용하세요 (단, 화면당 소수 표면으로 제한).
  static BoxDecoration glassSurface({bool isDark = false}) => BoxDecoration(
    color: (isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant)
        .withValues(alpha: isDark ? 0.55 : 0.7),
    borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.6),
      width: 0.75,
    ),
  );

  /// EN: Subtle top-edge highlight for image-first cards — a soft ~8% white
  /// hairline that fades at both ends, suggesting light catching the rim of
  /// a glass surface. Cheap: a single 1px gradient strip, no blur.
  /// KO: 이미지 우선 카드의 미세한 상단 하이라이트 — 양 끝이 페이드되는
  /// 약 8% 화이트 헤어라인으로, 글래스 표면 가장자리에 빛이 닿는 느낌을
  /// 줍니다. 저비용: 블러 없이 1px 그라디언트 스트립 하나만 사용합니다.
  static const LinearGradient glassTopHairline = LinearGradient(
    colors: [Colors.transparent, Color(0x14FFFFFF), Colors.transparent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// EN: Top scrim gradient placed over images so badges/icons stay legible.
  /// KO: 이미지 위 배지/아이콘의 가독성을 지키기 위한 상단 스크림 그라디언트.
  static const LinearGradient imageTopScrim = LinearGradient(
    colors: [Color(0x66000000), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45],
  );
}
