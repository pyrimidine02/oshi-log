/// EN: Editorial feed-mode control for Field Reports.
/// KO: Field Reports를 위한 에디토리얼 피드 모드 컨트롤.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../application/board_controller.dart';

/// EN: Compact text-only mode rail; section navigation stays in the bottom bar.
/// KO: 섹션 이동은 하단바에 맡기고 피드 모드만 전환하는 텍스트 레일입니다.
class FieldCommunityModeBar extends StatelessWidget {
  const FieldCommunityModeBar({
    super.key,
    required this.modes,
    required this.selected,
    required this.onSelected,
  });

  final List<CommunityFeedMode> modes;
  final CommunityFeedMode selected;
  final ValueChanged<CommunityFeedMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScaler = MediaQuery.textScalerOf(context);
    final usesScrollableDestinations = textScaler.scale(1) >= 1.8;
    final background = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final destinations = [
      for (final mode in modes)
        _ModeDestination(
          mode: mode,
          selected: mode == selected,
          onTap: () => onSelected(mode),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        0,
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        ),
        child: usesScrollableDestinations
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final destination in destinations)
                      SizedBox(
                        width: textScaler.scale(88).clamp(128.0, 180.0),
                        child: destination,
                      ),
                  ],
                ),
              )
            : Row(
                children: [
                  for (final destination in destinations)
                    Expanded(child: destination),
                ],
              ),
      ),
    );
  }
}

class _ModeDestination extends StatelessWidget {
  const _ModeDestination({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final CommunityFeedMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? GBTColors.darkSecondary : GBTColors.secondary;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final label = _modeLabel(context, mode);
    final selectedBackground = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final motionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: Key('field-community-mode-${mode.name}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: motionDuration,
          constraints: BoxConstraints(
            minHeight: MediaQuery.textScalerOf(
              context,
            ).scale(GBTSpacing.touchTarget).clamp(GBTSpacing.touchTarget, 72),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          ),
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GBTTypography.labelLarge.copyWith(
              color: selected ? ink : muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String _modeLabel(BuildContext context, CommunityFeedMode mode) {
  return switch (mode) {
    CommunityFeedMode.recommended => context.l10n(
      ko: '추천',
      en: 'Recommended',
      ja: 'おすすめ',
    ),
    CommunityFeedMode.following => context.l10n(
      ko: '팔로잉',
      en: 'Following',
      ja: 'フォロー中',
    ),
    CommunityFeedMode.latest => context.l10n(ko: '최신', en: 'Latest', ja: '最新'),
    CommunityFeedMode.trending => context.l10n(
      ko: '지금 인기',
      en: 'Trending',
      ja: '人気',
    ),
  };
}
