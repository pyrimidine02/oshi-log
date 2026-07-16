/// EN: 2-column action cell for navigation items.
/// KO: 네비게이션 항목용 2열 액션 셀.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';

/// EN: Tappable action cell with icon, label, and subtitle for 2-column grids.
/// KO: 2열 그리드용 아이콘·라벨·서브타이틀이 있는 탭 가능한 액션 셀.
class ActionCell extends StatelessWidget {
  const ActionCell({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(GBTSpacing.md),
          // EN: Override default card radius with the 2026 bento radius.
          // KO: 기본 카드 반지름을 2026 벤토 반지름으로 재정의.
          decoration: GBTDecorations.card(isDark: isDark).copyWith(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EN: Gradient icon chip — visual anchor for the action.
              // KO: 그라디언트 아이콘 칩 — 액션의 시각적 앵커.
              GBTIconChip(icon: icon, color: color, size: 44),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                label,
                style: GBTTypography.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GBTTypography.labelSmall.copyWith(
                  color: textTertiary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
