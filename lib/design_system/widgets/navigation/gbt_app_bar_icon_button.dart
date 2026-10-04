/// EN: Reusable AppBar icon button with consistent sizing and semantics.
/// KO: 일관된 크기와 시맨틱을 갖춘 재사용 가능한 AppBar 아이콘 버튼.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_spacing.dart';

/// EN: Standard icon button for AppBar actions — wraps [IconButton] with
/// minimum touch target, semantic label, and optional tooltip.
/// KO: AppBar 액션용 표준 아이콘 버튼 — 최소 터치 타겟, 시맨틱 라벨,
/// 선택적 툴팁을 포함한 [IconButton] 래퍼.
class GBTAppBarIconButton extends StatelessWidget {
  const GBTAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.iconColor,
  });

  /// EN: Icon to display.
  /// KO: 표시할 아이콘.
  final IconData icon;

  /// EN: Callback when pressed.
  /// KO: 누를 때 호출되는 콜백.
  final VoidCallback? onPressed;

  /// EN: Tooltip text shown on long press.
  /// KO: 길게 누를 때 표시되는 툴팁 텍스트.
  final String? tooltip;

  /// EN: Accessibility semantic label (defaults to tooltip).
  /// KO: 접근성 시맨틱 라벨 (기본값: tooltip).
  final String? semanticLabel;

  /// EN: Optional explicit icon color to override theme defaults.
  /// KO: 테마 기본값을 덮어쓰는 선택적 아이콘 색상입니다.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip,
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: GBTSpacing.touchTarget,
          minHeight: GBTSpacing.touchTarget,
        ),
      ),
    );
  }
}
