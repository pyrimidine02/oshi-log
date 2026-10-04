/// EN: Themed builder widget for efficient theme access
/// KO: 효율적인 테마 접근을 위한 테마 빌더 위젯
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';

/// EN: Themed builder widget that provides theme-aware values to reduce
/// repeated Theme.of(context) calls.
///
/// Instead of calling Theme.of(context).brightness multiple times in a widget,
/// use ThemedBuilder to get the isDark value once and pass it to the builder.
///
/// Example:
/// ```dart
/// ThemedBuilder(
///   builder: (context, isDark) {
///     final textColor = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
///     final bgColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
///
///     return Container(
///       color: bgColor,
///       child: Text('Hello', style: TextStyle(color: textColor)),
///     );
///   },
/// )
/// ```
///
/// KO: 반복적인 Theme.of(context) 호출을 줄이기 위해 테마 인식 값을 제공하는
/// 테마 빌더 위젯입니다.
///
/// 위젯에서 Theme.of(context).brightness를 여러 번 호출하는 대신,
/// ThemedBuilder를 사용하여 isDark 값을 한 번 가져와서 빌더에 전달합니다.
///
/// 예시:
/// ```dart
/// ThemedBuilder(
///   builder: (context, isDark) {
///     final textColor = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
///     final bgColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
///
///     return Container(
///       color: bgColor,
///       child: Text('안녕하세요', style: TextStyle(color: textColor)),
///     );
///   },
/// )
/// ```
class ThemedBuilder extends StatelessWidget {
  const ThemedBuilder({super.key, required this.builder});

  /// EN: Builder function that receives context and isDark flag
  /// KO: context와 isDark 플래그를 받는 빌더 함수
  final Widget Function(BuildContext context, bool isDark) builder;

  @override
  Widget build(BuildContext context) {
    // EN: Get brightness once and pass to builder
    // KO: brightness를 한 번 가져와서 빌더에 전달
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return builder(context, isDark);
  }
}

/// EN: Extension on BuildContext for quick theme-aware color access
/// KO: 빠른 테마 인식 색상 접근을 위한 BuildContext 확장
extension ThemedContextExtension on BuildContext {
  /// EN: Check if the current theme is dark mode
  /// KO: 현재 테마가 다크 모드인지 확인
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// EN: Get primary text color based on theme
  /// KO: 테마에 따른 기본 텍스트 색상 반환
  Color get textPrimary =>
      isDarkMode ? GBTColors.darkTextPrimary : GBTColors.textPrimary;

  /// EN: Get secondary text color based on theme
  /// KO: 테마에 따른 보조 텍스트 색상 반환
  Color get textSecondary =>
      isDarkMode ? GBTColors.darkTextSecondary : GBTColors.textSecondary;

  /// EN: Get tertiary text color based on theme
  /// KO: 테마에 따른 3차 텍스트 색상 반환
  Color get textTertiary =>
      isDarkMode ? GBTColors.darkTextTertiary : GBTColors.textTertiary;

  /// EN: Get surface color based on theme
  /// KO: 테마에 따른 표면 색상 반환
  Color get surfaceColor =>
      isDarkMode ? GBTColors.darkSurface : GBTColors.surface;

  /// EN: Get surface variant color based on theme
  /// KO: 테마에 따른 표면 변형 색상 반환
  Color get surfaceVariant =>
      isDarkMode ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant;

  /// EN: Get border color based on theme
  /// KO: 테마에 따른 테두리 색상 반환
  Color get borderColor => isDarkMode ? GBTColors.darkBorder : GBTColors.border;

  /// EN: Get subtle border color based on theme
  /// KO: 테마에 따른 미묘한 테두리 색상 반환
  Color get borderSubtle =>
      isDarkMode ? GBTColors.darkBorderSubtle : GBTColors.border;

  /// EN: Get primary color (brighter purple in dark mode)
  /// KO: 기본 색상 (다크 모드에서 더 밝은 보라색)
  Color get primaryColor =>
      isDarkMode ? GBTColors.darkPrimary : GBTColors.primary;
}
