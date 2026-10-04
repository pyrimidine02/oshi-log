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

  /// EN: System font fallback chain for Japanese so kana/kanji render with
  /// Japanese glyph forms instead of Pretendard's Korean shapes. No bundled
  /// JP font file is added (app size); this relies on OS-provided fonts.
  /// KO: 가나/한자가 Pretendard의 한국어 글리프 형태 대신 일본어 글리프로
  /// 렌더링되도록 하는 일본어 시스템 폰트 폴백 체인입니다. 앱 용량을 위해
  /// 번들 일본어 폰트 파일은 추가하지 않고 OS 제공 폰트에 의존합니다.
  static const List<String> jaFontFallback = [
    'Hiragino Sans',
    'Hiragino Kaku Gothic ProN',
    'Noto Sans JP',
    'Noto Sans CJK JP',
    'sans-serif',
  ];

  /// EN: Adapts a style for [languageCode]. For `ja`, drops Pretendard
  /// (no kana coverage) in favor of system JP fallbacks; when [isBody] is
  /// true also applies the ja body text rule (height 1.6, letterSpacing
  /// 0.02em, min 14sp) per docs/product/design-references-v1.md §4.1.
  /// Other locales are returned unchanged.
  /// KO: [languageCode]에 맞춰 스타일을 조정합니다. `ja`인 경우 가나를
  /// 지원하지 않는 Pretendard 대신 시스템 JP 폴백을 사용하며, [isBody]가
  /// true면 §4.1의 일본어 본문 규칙(줄높이 1.6, 자간 0.02em, 최소 14sp)도
  /// 적용합니다. 그 외 로케일은 변경 없이 반환합니다.
  static TextStyle forLanguage(
    TextStyle style,
    String languageCode, {
    bool isBody = false,
  }) {
    if (languageCode != 'ja') return style;
    // EN: TextStyle.copyWith can't null out fontFamily (it falls back to
    // `fontFamily ?? this.fontFamily`), so rebuild explicitly instead of
    // copying from a Pretendard-bearing style.
    // KO: TextStyle.copyWith는 fontFamily를 null로 되돌릴 수 없어
    // (`fontFamily ?? this.fontFamily`) Pretendard가 들어있는 스타일을
    // 복사하는 대신 명시적으로 새로 만듭니다.
    final jaStyle = TextStyle(
      fontFamilyFallback: jaFontFallback,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      letterSpacing: style.letterSpacing,
      height: style.height,
      fontFeatures: style.fontFeatures,
    );
    if (!isBody) return jaStyle;
    final size = (style.fontSize ?? 16).clamp(14, double.infinity).toDouble();
    return jaStyle.copyWith(
      fontSize: size,
      height: 1.6,
      letterSpacing: size * 0.02,
    );
  }

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
