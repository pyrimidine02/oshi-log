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
    final border = isDark ? GBTColors.darkBorderSubtle : GBTColors.divider;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.pageHorizontal,
        ),
        child: Row(
          children: [
            for (final mode in modes)
              Expanded(
                child: _ModeDestination(
                  mode: mode,
                  selected: mode == selected,
                  onTap: () => onSelected(mode),
                ),
              ),
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
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final label = _modeLabel(context, mode);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: Key('field-community-mode-${mode.name}'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GBTTypography.labelLarge.copyWith(
              color: selected ? accent : muted,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
