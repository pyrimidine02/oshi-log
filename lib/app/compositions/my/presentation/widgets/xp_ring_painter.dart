/// EN: XP arc ring — CustomPainter drawing a 270° progress arc.
/// KO: XP 호 링 — 270° 진행 호를 그리는 CustomPainter.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

/// EN: Paints a 270° arc ring representing XP progress.
/// KO: XP 진행률을 나타내는 270° 호 링을 그립니다.
class XpRingPainter extends CustomPainter {
  const XpRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  // EN: Arc starts at bottom-left (225°) and sweeps 270° clockwise.
  // KO: 호는 왼쪽 하단(225°)에서 시작해 시계 방향으로 270° 회전합니다.
  static const double _startAngle = pi * 0.75;
  static const double _sweepFull = pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 10) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // EN: Track (background arc).
    // KO: 트랙(배경 호).
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepFull,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );

    // EN: Progress arc — only draw when progress > 0.
    // KO: 진행 호 — progress가 0보다 클 때만 그립니다.
    if (progress > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        _sweepFull * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(XpRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
