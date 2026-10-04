/// EN: GBT Button component with multiple variants using Material ripple
/// KO: Material 리플을 사용하는 다양한 변형의 GBT 버튼 컴포넌트
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/gbt_animations.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Button variant enumeration
/// KO: 버튼 변형 열거형
enum GBTButtonVariant {
  /// EN: Primary filled button (journey blue)
  /// KO: 기본 채움 버튼 (여정 블루)
  primary,

  /// EN: Secondary outlined button
  /// KO: 보조 외곽선 버튼
  secondary,

  /// EN: Tertiary text button
  /// KO: 3차 텍스트 버튼
  tertiary,

  /// EN: Accent colored button (ElevatedButton with accent color)
  /// KO: 강조 색상 버튼 (액센트 색상의 ElevatedButton)
  accent,

  /// EN: Danger/error button (ElevatedButton with error color)
  /// KO: 위험/오류 버튼 (에러 색상의 ElevatedButton)
  danger,
}

/// EN: Button size enumeration
/// KO: 버튼 크기 열거형
enum GBTButtonSize { small, medium, large }

/// EN: Icon position enumeration
/// KO: 아이콘 위치 열거형
enum IconPosition { leading, trailing }

/// EN: GBT Button widget with Material ripple and accessibility support.
///     Uses ElevatedButton / OutlinedButton / TextButton internally so the
///     platform-default InkWell feedback is preserved without custom
///     press animation.
/// KO: Material 리플과 접근성을 지원하는 GBT 버튼 위젯.
///     내부적으로 ElevatedButton / OutlinedButton / TextButton을 사용하여
///     커스텀 프레스 애니메이션 없이 플랫폼 기본 InkWell 피드백을 유지합니다.
class GBTButton extends StatelessWidget {
  const GBTButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GBTButtonVariant.primary,
    this.size = GBTButtonSize.medium,
    this.icon,
    this.iconPosition = IconPosition.leading,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
    this.semanticHint,
  });

  /// EN: Button label text
  /// KO: 버튼 라벨 텍스트
  final String label;

  /// EN: Callback when button is pressed
  /// KO: 버튼이 눌렸을 때 콜백
  final VoidCallback? onPressed;

  /// EN: Button visual variant
  /// KO: 버튼 시각적 변형
  final GBTButtonVariant variant;

  /// EN: Button size
  /// KO: 버튼 크기
  final GBTButtonSize size;

  /// EN: Optional leading or trailing icon
  /// KO: 선택적 앞 또는 뒤 아이콘
  final IconData? icon;

  /// EN: Icon position (leading or trailing)
  /// KO: 아이콘 위치 (앞 또는 뒤)
  final IconPosition iconPosition;

  /// EN: Loading state
  /// KO: 로딩 상태
  final bool isLoading;

  /// EN: Whether button should fill available width
  /// KO: 버튼이 사용 가능한 너비를 채울지 여부
  final bool isFullWidth;

  /// EN: Semantic label for accessibility
  /// KO: 접근성을 위한 시맨틱 라벨
  final String? semanticLabel;

  /// EN: Semantic hint for accessibility (e.g. "탭하면 제출합니다")
  /// KO: 접근성을 위한 시맨틱 힌트 (예: "탭하면 제출합니다")
  final String? semanticHint;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final child = _buildChild();

    // EN: Build semantic label including loading state
    // KO: 로딩 상태를 포함한 시맨틱 라벨 빌드
    final effectiveLabel = semanticLabel ?? label;
    final stateLabel = isLoading ? '$effectiveLabel, 로딩 중' : effectiveLabel;

    Widget button = switch (variant) {
      GBTButtonVariant.primary ||
      GBTButtonVariant.accent ||
      GBTButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      GBTButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      GBTButtonVariant.tertiary => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
    };

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Semantics(
      button: true,
      label: stateLabel,
      hint: semanticHint,
      enabled: _isEnabled,
      // EN: Exclude inner button semantics to avoid double announcement
      // KO: 이중 음성 안내를 방지하기 위해 내부 버튼 시맨틱 제외
      child: ExcludeSemantics(child: button),
    );
  }

  // ------------------------------------------------------------------
  // EN: Private helpers
  // KO: 비공개 헬퍼
  // ------------------------------------------------------------------

  /// EN: Build button child with animated loading transition
  /// KO: 애니메이션 로딩 전환이 있는 버튼 자식 빌드
  Widget _buildChild() {
    return AnimatedSwitcher(
      duration: GBTAnimations.fast,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: _getIconSize(),
              height: _getIconSize(),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getForegroundColor(),
                ),
              ),
            )
          : _buildContent(),
    );
  }

  /// EN: Build button content (text + optional icon)
  /// KO: 버튼 콘텐츠 빌드 (텍스트 + 선택적 아이콘)
  Widget _buildContent() {
    if (icon != null) {
      final iconWidget = Icon(icon, size: _getIconSize());
      const spacing = SizedBox(width: GBTSpacing.sm);

      if (iconPosition == IconPosition.leading) {
        return Row(
          key: const ValueKey('content'),
          mainAxisSize: MainAxisSize.min,
          children: [iconWidget, spacing, Text(label)],
        );
      } else {
        return Row(
          key: const ValueKey('content'),
          mainAxisSize: MainAxisSize.min,
          children: [Text(label), spacing, iconWidget],
        );
      }
    }

    return Text(label, key: const ValueKey('content'));
  }

  /// EN: Get button style based on variant
  /// KO: 변형에 따른 버튼 스타일 반환
  ButtonStyle _getButtonStyle() {
    final padding = _getPadding();
    final minimumSize = _getMinimumSize();

    // EN: Pill shape (StadiumBorder) across all variants to match the
    // Journey Ticket button language defined in GBTTheme.
    // KO: GBTTheme에 정의된 "여정의 티켓" 버튼 언어에 맞춰 모든 변형에
    // 필(StadiumBorder) 형태를 적용합니다.
    return switch (variant) {
      GBTButtonVariant.primary => ElevatedButton.styleFrom(
        backgroundColor: GBTColors.primary,
        foregroundColor: GBTColors.textInverse,
        padding: padding,
        minimumSize: minimumSize,
        textStyle: _getTextStyle(),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      GBTButtonVariant.accent => ElevatedButton.styleFrom(
        backgroundColor: GBTColors.accent,
        foregroundColor: GBTColorValidator.getContrastingTextColor(
          GBTColors.accent,
        ),
        padding: padding,
        minimumSize: minimumSize,
        textStyle: _getTextStyle(),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      GBTButtonVariant.danger => ElevatedButton.styleFrom(
        backgroundColor: GBTColors.error,
        foregroundColor: GBTColors.textInverse,
        padding: padding,
        minimumSize: minimumSize,
        textStyle: _getTextStyle(),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
      GBTButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: GBTColors.primary,
        padding: padding,
        minimumSize: minimumSize,
        side: const BorderSide(color: GBTColors.border),
        textStyle: _getTextStyle(),
        shape: const StadiumBorder(),
      ),
      GBTButtonVariant.tertiary => TextButton.styleFrom(
        foregroundColor: GBTColors.primary,
        padding: padding,
        minimumSize: minimumSize,
        textStyle: _getTextStyle(),
        shape: const StadiumBorder(),
      ),
    };
  }

  /// EN: Get foreground color for loading indicator
  /// KO: 로딩 인디케이터용 전경색 반환
  Color _getForegroundColor() {
    return switch (variant) {
      GBTButtonVariant.primary => GBTColors.textInverse,
      GBTButtonVariant.accent => GBTColorValidator.getContrastingTextColor(
        GBTColors.accent,
      ),
      GBTButtonVariant.danger => GBTColors.textInverse,
      GBTButtonVariant.secondary ||
      GBTButtonVariant.tertiary => GBTColors.primary,
    };
  }

  /// EN: Get padding based on size
  /// KO: 크기에 따른 패딩 반환
  EdgeInsets _getPadding() {
    return switch (size) {
      // EN: Small uses same padding as medium (48dp touch target)
      // KO: Small은 medium과 동일한 패딩 사용 (48dp 터치 타겟)
      GBTButtonSize.small => const EdgeInsets.symmetric(
        horizontal: GBTSpacing.lg,
        vertical: GBTSpacing.sm,
      ),
      GBTButtonSize.medium => const EdgeInsets.symmetric(
        horizontal: GBTSpacing.lg,
        vertical: GBTSpacing.sm,
      ),
      GBTButtonSize.large => const EdgeInsets.symmetric(
        horizontal: GBTSpacing.xl,
        vertical: GBTSpacing.md,
      ),
    };
  }

  /// EN: Get minimum size based on size (small maps to same as medium: 48dp)
  /// KO: 크기에 따른 최소 크기 반환 (small은 medium과 동일: 48dp)
  Size _getMinimumSize() {
    return switch (size) {
      // EN: Small buttons map to same 48dp height as medium for consistency
      // KO: 일관성을 위해 small 버튼도 medium과 같은 48dp 높이로 매핑
      GBTButtonSize.small => const Size(88, GBTSpacing.minTouchTarget),
      GBTButtonSize.medium => const Size(88, GBTSpacing.minTouchTarget),
      GBTButtonSize.large => const Size(120, GBTSpacing.touchTarget),
    };
  }

  /// EN: Get text style based on size
  /// KO: 크기에 따른 텍스트 스타일 반환
  TextStyle _getTextStyle() {
    return switch (size) {
      GBTButtonSize.small => GBTTypography.labelMedium,
      GBTButtonSize.medium => GBTTypography.button,
      GBTButtonSize.large => GBTTypography.button.copyWith(fontSize: 16),
    };
  }

  /// EN: Get icon size based on button size
  /// KO: 버튼 크기에 따른 아이콘 크기 반환
  double _getIconSize() {
    return switch (size) {
      GBTButtonSize.small => 16,
      GBTButtonSize.medium => 20,
      GBTButtonSize.large => 24,
    };
  }
}

/// EN: Icon-only button widget using Material IconButton directly.
///     No custom press animation — relies on Material's InkResponse.
/// KO: Material IconButton을 직접 사용하는 아이콘 전용 버튼 위젯.
///     커스텀 프레스 애니메이션 없이 Material의 InkResponse에 의존합니다.
class GBTIconButton extends StatelessWidget {
  const GBTIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = GBTButtonSize.medium,
    this.variant = GBTButtonVariant.tertiary,
    this.semanticLabel,
    this.tooltip,
  });

  /// EN: Icon to display
  /// KO: 표시할 아이콘
  final IconData icon;

  /// EN: Callback when button is pressed
  /// KO: 버튼이 눌렸을 때 콜백
  final VoidCallback? onPressed;

  /// EN: Button size
  /// KO: 버튼 크기
  final GBTButtonSize size;

  /// EN: Button visual variant (controls icon color)
  /// KO: 버튼 시각적 변형 (아이콘 색상 제어)
  final GBTButtonVariant variant;

  /// EN: Semantic label for accessibility
  /// KO: 접근성을 위한 시맨틱 라벨
  final String? semanticLabel;

  /// EN: Tooltip text shown on long press
  /// KO: 길게 누르면 표시되는 툴팁 텍스트
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null;

    // EN: All sizes meet 48dp minimum touch target for accessibility
    // KO: 모든 크기가 접근성을 위해 48dp 최소 터치 타겟을 충족
    final buttonSize = switch (size) {
      GBTButtonSize.small => GBTSpacing.touchTarget,
      GBTButtonSize.medium => GBTSpacing.touchTarget,
      GBTButtonSize.large => GBTSpacing.touchTarget,
    };

    final iconSize = switch (size) {
      GBTButtonSize.small => 16.0,
      GBTButtonSize.medium => 24.0,
      GBTButtonSize.large => 28.0,
    };

    // EN: Use darkPrimary (lighter purple) for primary variant in dark mode
    // KO: 다크 모드에서 primary 변형에 darkPrimary (밝은 보라) 사용
    final color = switch (variant) {
      GBTButtonVariant.primary =>
        isDark ? GBTColors.darkPrimary : GBTColors.primary,
      GBTButtonVariant.secondary =>
        isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
      GBTButtonVariant.tertiary =>
        isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
      GBTButtonVariant.accent => GBTColors.accent,
      GBTButtonVariant.danger => GBTColors.error,
    };

    // EN: Build the IconButton with haptic feedback
    // KO: 햅틱 피드백을 포함한 IconButton 빌드
    Widget button = Semantics(
      button: true,
      label: semanticLabel ?? tooltip,
      enabled: isEnabled,
      child: ExcludeSemantics(
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: IconButton(
            icon: Icon(icon, size: iconSize),
            onPressed: onPressed != null
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            color: color,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: buttonSize,
              minHeight: buttonSize,
            ),
          ),
        ),
      ),
    );

    // EN: Always wrap icon buttons in Tooltip for accessibility
    // KO: 접근성을 위해 아이콘 버튼을 항상 Tooltip으로 감싸기
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    } else if (semanticLabel != null) {
      button = Tooltip(message: semanticLabel!, child: button);
    }

    return button;
  }
}
