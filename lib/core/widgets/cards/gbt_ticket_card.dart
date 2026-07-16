/// EN: Ticket-stub card — the signature "Journey Ticket" surface.
/// A rounded card with side notches and a dashed perforation line separating
/// the body from the stub, like a concert ticket.
/// KO: 티켓 스텁 카드 — "여정의 티켓" 시그니처 표면.
/// 공연 티켓처럼 본문과 스텁 사이에 사이드 노치와 점선 절취선이 있는 카드.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: A concert-ticket shaped card. [body] is the main content and [stub]
/// is the tear-off section below the perforation line.
/// KO: 공연 티켓 형태의 카드. [body]는 메인 콘텐츠, [stub]은 절취선 아래
/// 스텁 영역입니다.
class GBTTicketCard extends StatelessWidget {
  const GBTTicketCard({
    super.key,
    required this.body,
    required this.stub,
    this.stubHeight = 56,
    this.color,
    this.notchRadius = 8,
    this.borderRadius = GBTSpacing.radiusLg,
    this.padding = const EdgeInsets.all(GBTSpacing.md),
    this.stubPadding = const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
  });

  /// EN: Main content above the perforation line.
  /// KO: 절취선 위 메인 콘텐츠.
  final Widget body;

  /// EN: Stub content below the perforation line (fixed height).
  /// KO: 절취선 아래 스텁 콘텐츠 (고정 높이).
  final Widget stub;

  /// EN: Fixed height of the stub section.
  /// KO: 스텁 영역의 고정 높이.
  final double stubHeight;

  /// EN: Card fill color. Defaults to the theme surface color.
  /// KO: 카드 채움 색상. 기본값은 테마 표면 색상.
  final Color? color;

  /// EN: Radius of the side notches at the perforation line.
  /// KO: 절취선 위치 사이드 노치의 반지름.
  final double notchRadius;

  /// EN: Corner radius of the ticket.
  /// KO: 티켓 모서리 반지름.
  final double borderRadius;

  /// EN: Padding around the body content.
  /// KO: 본문 콘텐츠 패딩.
  final EdgeInsetsGeometry padding;

  /// EN: Padding around the stub content.
  /// KO: 스텁 콘텐츠 패딩.
  final EdgeInsetsGeometry stubPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        color ?? (isDark ? GBTColors.darkSurfaceVariant : GBTColors.surface);

    return CustomPaint(
      painter: _TicketPainter(
        color: fillColor,
        stubHeight: stubHeight,
        notchRadius: notchRadius,
        borderRadius: borderRadius,
        perforationColor: isDark ? GBTColors.darkBorder : GBTColors.border,
        isDark: isDark,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: padding, child: body),
          SizedBox(
            height: stubHeight,
            child: Padding(padding: stubPadding, child: stub),
          ),
        ],
      ),
    );
  }
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter({
    required this.color,
    required this.stubHeight,
    required this.notchRadius,
    required this.borderRadius,
    required this.perforationColor,
    required this.isDark,
  });

  final Color color;
  final double stubHeight;
  final double notchRadius;
  final double borderRadius;
  final Color perforationColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final notchY = size.height - stubHeight;

    final ticket = Path.combine(
      PathOperation.difference,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(borderRadius),
        ),
      ),
      Path()
        ..addOval(
          Rect.fromCircle(center: Offset(0, notchY), radius: notchRadius),
        )
        ..addOval(
          Rect.fromCircle(
            center: Offset(size.width, notchY),
            radius: notchRadius,
          ),
        ),
    );

    if (!isDark) {
      canvas.drawShadow(
        ticket.shift(const Offset(0, 1)),
        const Color(0x33000000),
        6,
        true,
      );
    }
    canvas.drawPath(ticket, Paint()..color = color);

    // EN: Dashed perforation line between the notches.
    // KO: 노치 사이의 점선 절취선.
    final dashPaint = Paint()
      ..color = perforationColor
      ..strokeWidth = 1.2;
    const dashWidth = 5.0;
    const dashGap = 4.0;
    var x = notchRadius + dashGap;
    final endX = size.width - notchRadius - dashGap;
    while (x < endX) {
      canvas.drawLine(
        Offset(x, notchY),
        Offset((x + dashWidth).clamp(0, endX), notchY),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_TicketPainter oldDelegate) =>
      color != oldDelegate.color ||
      stubHeight != oldDelegate.stubHeight ||
      notchRadius != oldDelegate.notchRadius ||
      borderRadius != oldDelegate.borderRadius ||
      perforationColor != oldDelegate.perforationColor ||
      isDark != oldDelegate.isDark;
}
