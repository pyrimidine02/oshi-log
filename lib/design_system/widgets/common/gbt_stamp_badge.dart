/// EN: Pilgrimage stamp badge — circular ink-stamp for collected spots.
/// Locked stamps render desaturated; unlocking plays a stamp-press pop.
/// KO: 순례 스탬프 배지 — 수집한 장소를 위한 원형 잉크 스탬프.
/// 잠긴 스탬프는 무채색으로, 해금 시 스탬프 찍기 팝 애니메이션 재생.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: A circular stamp badge with a dashed ink-stamp border.
/// KO: 점선 잉크 스탬프 테두리를 가진 원형 스탬프 배지.
class GBTStampBadge extends StatelessWidget {
  const GBTStampBadge({
    super.key,
    required this.child,
    this.unlocked = true,
    this.size = 72,
    this.color,
    this.animateOnUnlock = true,
  });

  /// EN: Center content (icon or image).
  /// KO: 중앙 콘텐츠 (아이콘 또는 이미지).
  final Widget child;

  /// EN: Whether this stamp has been collected.
  /// KO: 이 스탬프의 수집 여부.
  final bool unlocked;

  /// EN: Diameter of the stamp.
  /// KO: 스탬프 지름.
  final double size;

  /// EN: Stamp ink color. Defaults to the brand primary.
  /// KO: 스탬프 잉크 색상. 기본값은 브랜드 프라이머리.
  final Color? color;

  /// EN: Play the stamp-press pop when [unlocked] turns true.
  /// KO: [unlocked]가 true가 될 때 스탬프 찍기 팝 재생 여부.
  final bool animateOnUnlock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = color ?? (isDark ? GBTColors.darkPrimary : GBTColors.primary);
    final lockedColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textDisabled;

    final stamp = CustomPaint(
      painter: _StampBorderPainter(
        color: unlocked ? ink : lockedColor,
        dashed: true,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unlocked
              ? ink.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark
                    ? GBTColors.darkSurfaceVariant
                    : GBTColors.surfaceVariant),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: ink.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: unlocked
            ? child
            : Opacity(
                opacity: 0.45,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: child,
                ),
              ),
      ),
    );

    if (!animateOnUnlock || MediaQuery.of(context).disableAnimations) {
      return stamp;
    }

    // EN: Stamp-press pop — scales down from an "inked" overshoot when
    // the unlocked state appears.
    // KO: 스탬프 찍기 팝 — 해금 상태 표시 시 오버슈트에서 눌리듯 축소.
    return TweenAnimationBuilder<double>(
      key: ValueKey<bool>(unlocked),
      tween: Tween(begin: unlocked ? 1.25 : 1.0, end: 1.0),
      duration: GBTAnimations.slow,
      curve: GBTAnimations.bounceCurve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: stamp,
    );
  }
}

class _StampBorderPainter extends CustomPainter {
  const _StampBorderPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // EN: Dashed circle — 24 segments for the perforated stamp edge.
    // KO: 절취 느낌의 스탬프 가장자리를 위한 24개 점선 세그먼트.
    const segments = 24;
    const gapRatio = 0.35;
    const sweep = (2 * 3.141592653589793) / segments;
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * (1 - gapRatio),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StampBorderPainter oldDelegate) =>
      color != oldDelegate.color || dashed != oldDelegate.dashed;
}
