/// EN: Ruled activity ledger for the field-notes user profile.
/// KO: 필드 노트 사용자 프로필의 줄 단위 활동 원장입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../field_user_profile_view_data.dart';

class FieldProfileLedger extends StatelessWidget {
  const FieldProfileLedger({
    super.key,
    required this.metrics,
    this.onOpenFanLevel,
    this.onOpenPlaceHistory,
    this.onOpenLiveHistory,
  });

  final List<FieldProfileMetric> metrics;
  final VoidCallback? onOpenFanLevel;
  final VoidCallback? onOpenPlaceHistory;
  final VoidCallback? onOpenLiveHistory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          0,
          GBTSpacing.pageHorizontal,
          GBTSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '활동 원장',
                      en: 'ACTIVITY LEDGER',
                      ja: '活動台帳',
                    ),
                    style: GBTTypography.overline.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Container(width: 44, height: 4, color: colors.primary),
              ],
            ),
            const SizedBox(height: GBTSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    _LedgerRow(
                      metric: metrics[index],
                      onTap: _callbackFor(metrics[index].kind),
                    ),
                    if (index < metrics.length - 1)
                      Divider(height: 1, color: colors.outlineVariant),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _callbackFor(FieldProfileMetricKind kind) {
    return switch (kind) {
      FieldProfileMetricKind.level => onOpenFanLevel,
      FieldProfileMetricKind.placeVisits => onOpenPlaceHistory,
      FieldProfileMetricKind.liveVisits => onOpenLiveHistory,
      _ => null,
    };
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.metric, this.onTap});

  final FieldProfileMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = ConstrainedBox(
      key: const Key('field-profile-ledger-row'),
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(
                _icon,
                size: GBTSpacing.iconSm,
                color: _accent(colors),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _label(context),
                style: GBTTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Flexible(
              flex: 2,
              child: Text(
                metric.value,
                style: GBTTypography.statNumber.copyWith(
                  color: colors.onSurface,
                  fontSize: 18,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: GBTSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: content),
    );
  }

  IconData get _icon => switch (metric.kind) {
    FieldProfileMetricKind.xp => Icons.auto_graph_rounded,
    FieldProfileMetricKind.level => Icons.bolt_outlined,
    FieldProfileMetricKind.placeVisits => Icons.place_outlined,
    FieldProfileMetricKind.liveVisits => Icons.festival_outlined,
    FieldProfileMetricKind.posts => Icons.article_outlined,
    FieldProfileMetricKind.comments => Icons.mode_comment_outlined,
  };

  Color _accent(ColorScheme colors) => switch (metric.kind) {
    FieldProfileMetricKind.placeVisits => colors.secondary,
    FieldProfileMetricKind.liveVisits => GBTColors.accent,
    FieldProfileMetricKind.posts ||
    FieldProfileMetricKind.comments => GBTColors.fieldMapLine,
    _ => colors.primary,
  };

  String _label(BuildContext context) => switch (metric.kind) {
    FieldProfileMetricKind.xp => 'XP',
    FieldProfileMetricKind.level => context.l10n(
      ko: '팬 레벨',
      en: 'Fan level',
      ja: 'ファンレベル',
    ),
    FieldProfileMetricKind.placeVisits => context.l10n(
      ko: '성지 방문',
      en: 'Place visits',
      ja: '聖地訪問',
    ),
    FieldProfileMetricKind.liveVisits => context.l10n(
      ko: '라이브 방문',
      en: 'Live visits',
      ja: 'ライブ参加',
    ),
    FieldProfileMetricKind.posts => context.l10n(
      ko: '작성한 글',
      en: 'Posts',
      ja: '投稿',
    ),
    FieldProfileMetricKind.comments => context.l10n(
      ko: '작성한 댓글',
      en: 'Comments',
      ja: 'コメント',
    ),
  };
}
