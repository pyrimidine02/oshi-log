/// EN: Liquid-glass panel — reusable frosted translucent surface for the
/// 2026 glass design language (app bars, chips, floating overlays, tiles).
/// KO: 리퀴드 글래스 패널 — 2026 글래스 디자인 언어를 위한 재사용 가능한
/// 프로스티드 반투명 표면 (앱바, 칩, 플로팅 오버레이, 타일).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: A frosted-glass container with blur, translucent tint, and a hairline
/// border. Wrap floating UI (chips, bars, tiles) that sits over content.
/// Note: BackdropFilter has real GPU cost — use for a handful of surfaces
/// per screen, not for every list item.
/// KO: 블러 + 반투명 틴트 + 헤어라인 보더를 가진 프로스티드 글래스 컨테이너.
/// 콘텐츠 위에 뜨는 UI(칩, 바, 타일)에 사용하세요.
/// 참고: BackdropFilter는 GPU 비용이 큼 — 화면당 소수 표면에만 사용하고
/// 리스트 아이템마다 쓰지 마세요.
class GBTGlassPanel extends StatelessWidget {
  const GBTGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = GBTSpacing.radiusXl,
    this.blur = 24,
    this.tintOpacity,
    this.padding = EdgeInsets.zero,
    this.border = true,
  });

  /// EN: Content rendered on the glass surface.
  /// KO: 글래스 표면 위에 렌더링되는 콘텐츠.
  final Widget child;

  /// EN: Corner radius of the panel.
  /// KO: 패널 모서리 반지름.
  final double borderRadius;

  /// EN: Gaussian blur sigma applied to the backdrop.
  /// KO: 배경에 적용되는 가우시안 블러 시그마.
  final double blur;

  /// EN: Overrides the surface tint opacity (defaults per brightness).
  /// KO: 표면 틴트 불투명도 재정의 (기본값은 밝기별로 다름).
  final double? tintOpacity;

  /// EN: Inner padding around [child].
  /// KO: [child] 안쪽 패딩.
  final EdgeInsetsGeometry padding;

  /// EN: Whether to draw the hairline glass border.
  /// KO: 헤어라인 글래스 보더를 그릴지 여부.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? GBTColors.darkSurface.withValues(alpha: tintOpacity ?? 0.55)
        : GBTColors.surface.withValues(alpha: tintOpacity ?? 0.65);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ? Border.all(color: borderColor, width: 0.8) : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
