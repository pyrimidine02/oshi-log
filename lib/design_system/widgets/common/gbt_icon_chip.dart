/// EN: Compact feature marker inspired by printed map legends.
/// KO: 인쇄된 지도 범례에서 영감을 받은 작은 기능 마커.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: Visual style of [GBTIconChip].
/// KO: [GBTIconChip]의 비주얼 스타일.
enum GBTIconChipVariant {
  /// EN: Solid accent with an automatically contrasting glyph.
  /// KO: 자동 대비 글리프를 사용하는 단색 액센트.
  gradient,

  /// EN: Low-alpha tinted surface with a colored icon — quiet treatment.
  /// KO: 저알파 틴트 표면 + 컬러 아이콘 — 차분한 표현.
  tint,
}

/// EN: Squircle icon chip used across bento tiles, list rows, and cells.
/// KO: 벤토 타일, 리스트 행, 셀 전반에 쓰이는 스쿼클 아이콘 칩.
class GBTIconChip extends StatelessWidget {
  const GBTIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.variant = GBTIconChipVariant.gradient,
  });

  /// EN: Glyph to render.
  /// KO: 렌더링할 글리프.
  final IconData icon;

  /// EN: Base color of the chip.
  /// KO: 칩의 베이스 색상.
  final Color color;

  /// EN: Chip edge length (squircle radius scales with it).
  /// KO: 칩 한 변 길이 (스쿼클 반지름이 비례).
  final double size;

  /// EN: Visual variant.
  /// KO: 비주얼 변형.
  final GBTIconChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.32);
    final iconSize = size * 0.5;
    final foreground = GBTColorValidator.getContrastingTextColor(color);

    return switch (variant) {
      GBTIconChipVariant.gradient => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: color.darken(0.08)),
        ),
        child: Icon(icon, color: foreground, size: iconSize),
      ),
      GBTIconChipVariant.tint => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: radius,
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    };
  }
}
