/// EN: Standard intro card shown at the top of feature pages.
/// KO: 기능 페이지 상단에 표시하는 표준 인트로 카드입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Intro card that provides page context and optional trailing widget.
/// KO: 페이지 맥락과 선택적 우측 위젯을 제공하는 인트로 카드입니다.
class GBTPageIntroCard extends StatelessWidget {
  const GBTPageIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final iconBg = iconColor.withValues(alpha: isDark ? 0.20 : 0.12);
    final descColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final dividerColor = isDark ? GBTColors.darkBorder : GBTColors.divider;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor, width: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.none,
          GBTSpacing.xs,
          GBTSpacing.none,
          GBTSpacing.sm2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: GBTSpacing.lg,
              height: GBTSpacing.lg,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              ),
              child: Icon(icon, color: iconColor, size: GBTSpacing.iconSm),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GBTTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xxs),
                  Text(
                    description,
                    style: GBTTypography.bodySmall.copyWith(color: descColor),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: GBTSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
