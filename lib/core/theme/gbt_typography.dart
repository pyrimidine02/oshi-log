/// EN: GBT typography system — bundled Pretendard with an editorial travel hierarchy.
/// KO: GBT 타이포그래피 시스템 — 번들 Pretendard 기반 여행 에디토리얼 위계.
library;

import 'package:flutter/material.dart';

/// EN: Typography constants and styles for the application
/// KO: 앱의 타이포그래피 상수 및 스타일
class GBTTypography {
  GBTTypography._();

  // ========================================
  // EN: Font Family
  // KO: 폰트 패밀리
  // ========================================
  static const String primaryFontFamily = 'Pretendard';
  static const String secondaryFontFamily = 'Pretendard';

  /// EN: Base text style using bundled Pretendard with system fallbacks
  /// KO: 번들 Pretendard + 시스템 폴백을 사용하는 기본 텍스트 스타일
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: ['Apple SD Gothic Neo', 'Noto Sans KR', 'sans-serif'],
  );

  // ========================================
  // EN: Display styles for concise editorial headlines.
  // KO: 간결한 에디토리얼 헤드라인용 디스플레이 스타일.
  // ========================================
  static TextStyle get displayLarge => _baseStyle.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle get displayMedium => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get displaySmall => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // ========================================
  // EN: Headline Styles (Section headers)
  // KO: 헤드라인 스타일 (섹션 헤더)
  // ========================================
  static TextStyle get headlineLarge => _baseStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.27,
  );

  static TextStyle get headlineMedium => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.33,
  );

  static TextStyle get headlineSmall => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.38,
  );

  // ========================================
  // EN: Title Styles (Card titles, list items)
  // KO: 타이틀 스타일 (카드 제목, 리스트 아이템)
  // ========================================
  static TextStyle get titleLarge => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get titleMedium => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get titleSmall => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.43,
  );

  // ========================================
  // EN: Body Styles (Main content text)
  // KO: 본문 스타일 (메인 콘텐츠 텍스트)
  // ========================================
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.43,
  );

  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // ========================================
  // EN: Label Styles (Buttons, chips, tags)
  // KO: 라벨 스타일 (버튼, 칩, 태그)
  // ========================================
  static TextStyle get labelLarge => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.43,
  );

  static TextStyle get labelMedium => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.33,
  );

  static TextStyle get labelSmall => _baseStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.45,
  );

  // ========================================
  // EN: Additional Utility Styles
  // KO: 추가 유틸리티 스타일
  // ========================================
  static TextStyle get caption => _baseStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  static TextStyle get overline => _baseStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.6,
  );

  // ========================================
  // EN: Special Purpose Styles
  // KO: 특수 목적 스타일
  // ========================================
  static TextStyle get button =>
      labelLarge.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get tabLabel =>
      labelMedium.copyWith(fontWeight: FontWeight.w600);

  static TextStyle get badge => _baseStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.0,
  );

  static TextStyle get price =>
      titleMedium.copyWith(fontWeight: FontWeight.w700);

  static TextStyle get distance =>
      bodySmall.copyWith(fontWeight: FontWeight.w500);

  /// EN: Stat numbers (stamp counts, XP, distances) — tabular figures
  /// so digits align in ticker/stat layouts.
  /// KO: 통계 숫자 (스탬프 수, XP, 거리) — 스탯 레이아웃에서 자릿수가
  /// 정렬되도록 고정폭 숫자 적용.
  static TextStyle get statNumber => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// EN: Extension for applying color to text styles
/// KO: 텍스트 스타일에 색상을 적용하는 확장
extension GBTTextStyleExtension on TextStyle {
  /// EN: Apply color to text style
  /// KO: 텍스트 스타일에 색상 적용
  TextStyle withColor(Color color) => copyWith(color: color);

  /// EN: Apply semi-bold weight
  /// KO: 세미볼드 웨이트 적용
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// EN: Apply bold weight
  /// KO: 볼드 웨이트 적용
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  /// EN: Apply medium weight
  /// KO: 미디엄 웨이트 적용
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// EN: Apply regular weight
  /// KO: 레귤러 웨이트 적용
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
}

/// EN: Extension for localization support
/// KO: 다국어 지원을 위한 확장
extension GBTTypographyLocalization on TextStyle {
  /// EN: Adjust typography for different locales
  /// KO: 로케일별 타이포그래피 조정
  TextStyle forLocale(Locale locale) {
    return switch (locale.languageCode) {
      'ko' => copyWith(height: height != null ? height! * 1.1 : 1.5),
      'ja' => copyWith(height: height != null ? height! * 1.2 : 1.6),
      _ => this,
    };
  }
}
