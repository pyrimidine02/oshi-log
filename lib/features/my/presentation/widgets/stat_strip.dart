/// EN: Stat strip — bento stat grid showing the fan passport's collection
/// counts: a big "visits" tile paired with two stacked compact tiles
/// (stamps, posts).
/// KO: 통계 스트립 — 팬 패스포트의 컬렉션 카운트를 보여주는 벤토 통계
/// 그리드. 큰 "방문" 타일 + 스택된 컴팩트 타일 2개(스탬프, 글).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';
import '../../../settings/application/settings_controller.dart';

/// EN: Bento stat grid — big visits tile (left) + stacked stamps/posts
/// tiles (right).
/// KO: 벤토 통계 그리드 — 큰 방문 타일(왼쪽) + 스탬프/글 스택 타일(오른쪽).
class StatStrip extends ConsumerWidget {
  const StatStrip({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;
    final visits = profile?.totalVisits ?? 0;
    final stamps = profile?.uniquePlacesVisited ?? 0;
    final posts = profile?.postCount ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _BigStatTile(
              value: '$visits',
              label: context.l10n(ko: '방문', en: 'Visits', ja: '訪問'),
              caption: context.l10n(
                ko: '누적 성지 방문 기록',
                en: 'Total pilgrimage visits',
                ja: '累計聖地訪問記録',
              ),
              icon: Icons.pin_drop_rounded,
              color: isDark
                  ? GBTSemanticColors.darkMetadataDistance
                  : GBTColors.accentTeal,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '$stamps',
                    label: context.l10n(ko: '스탬프', en: 'Stamps', ja: 'スタンプ'),
                    icon: Icons.local_activity_rounded,
                    color: isDark ? GBTColors.darkAccent : GBTColors.accent,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Expanded(
                  child: _StatTile(
                    value: '$posts',
                    label: context.l10n(ko: '글', en: 'Posts', ja: '投稿'),
                    icon: Icons.edit_note_rounded,
                    color: isDark
                        ? GBTColors.darkSecondary
                        : GBTColors.secondary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Large bento tile — icon + statNumber + trend-style caption, used for
/// the highest-emphasis metric (visits).
/// KO: 큰 벤토 타일 — 아이콘 + statNumber + 트렌드 스타일 캡션. 가장 강조되는
/// 지표(방문)에 사용됩니다.
class _BigStatTile extends StatelessWidget {
  const _BigStatTile({
    required this.value,
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String value;
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GBTIconChip(icon: icon, color: color, size: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GBTTypography.statNumber.copyWith(color: textPrimary),
              ),
              Text(
                label,
                style: GBTTypography.labelMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: GBTSpacing.xxs),
              Text(
                caption,
                style: GBTTypography.labelSmall.copyWith(color: textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GBTSpacing.sm,
        horizontal: GBTSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
      ),
      child: Row(
        children: [
          GBTIconChip(icon: icon, color: color, size: 30),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GBTTypography.statNumber.copyWith(
                    fontSize: 17,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GBTTypography.labelSmall.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
