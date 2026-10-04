/// EN: Native sponsored slot card for inline feed placement.
/// KO: 피드 인라인 배치를 위한 네이티브 스폰서 슬롯 카드입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Lightweight sponsored card that blends into timeline/list surfaces.
/// KO: 타임라인/리스트 표면과 자연스럽게 어우러지는 경량 스폰서 카드입니다.
class GBTSponsoredSlotCard extends StatelessWidget {
  const GBTSponsoredSlotCard({
    super.key,
    required this.badgeLabel,
    required this.sponsorLabel,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.icon,
    this.onTap,
    this.accentColor,
    this.margin = const EdgeInsets.symmetric(
      horizontal: GBTSpacing.md,
      vertical: 5,
    ),
  });

  /// EN: Short disclosure label such as "AD".
  /// KO: "AD"와 같은 짧은 고지 라벨입니다.
  final String badgeLabel;

  /// EN: Sponsor or campaign source label.
  /// KO: 스폰서 또는 캠페인 출처 라벨입니다.
  final String sponsorLabel;

  /// EN: Main headline of the sponsored slot.
  /// KO: 스폰서 슬롯의 메인 헤드라인입니다.
  final String title;

  /// EN: Supporting copy for the slot.
  /// KO: 슬롯의 보조 설명 문구입니다.
  final String description;

  /// EN: CTA label shown at the bottom row.
  /// KO: 하단 행에 표시할 CTA 라벨입니다.
  final String ctaLabel;

  /// EN: Leading icon used by campaign type.
  /// KO: 캠페인 유형에 따른 선행 아이콘입니다.
  final IconData icon;

  /// EN: Optional callback when the card is tapped.
  /// KO: 카드를 탭했을 때 호출할 선택 콜백입니다.
  final VoidCallback? onTap;

  /// EN: Optional accent color override.
  /// KO: 선택적 강조 색상 오버라이드입니다.
  final Color? accentColor;

  /// EN: Outer margin of the card.
  /// KO: 카드의 바깥 여백입니다.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        accentColor ?? (isDark ? GBTColors.darkPrimary : GBTColors.primary);
    final borderColor = isDark
        ? GBTColors.darkBorder.withValues(alpha: 0.55)
        : GBTColors.border.withValues(alpha: 0.55);
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceVariant.withValues(alpha: 0.62)
        : GBTColors.surface;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GBTTypography.labelSmall.copyWith(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.xs),
                    Expanded(
                      child: Text(
                        sponsorLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.labelSmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextSecondary
                              : GBTColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  style: GBTTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GBTTypography.bodySmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(icon, size: 17, color: accent),
                    const SizedBox(width: GBTSpacing.xs),
                    Expanded(
                      child: Text(
                        ctaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.labelMedium.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? GBTColors.darkTextTertiary
                          : GBTColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
