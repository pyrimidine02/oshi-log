/// EN: Native feed-mode control for Field Reports.
/// KO: Field Reports를 위한 기본 피드 모드 컨트롤.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../application/board_controller.dart';

/// EN: Selects feed mode while section navigation stays in the bottom bar.
/// KO: 섹션 이동은 하단바에 맡기고 피드 모드를 전환합니다.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        0,
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SegmentedButton<CommunityFeedMode>(
              showSelectedIcon: false,
              segments: [
                for (final mode in modes)
                  ButtonSegment(
                    value: mode,
                    label: Semantics(
                      key: Key('field-community-mode-${mode.name}'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: GBTSpacing.touchTarget,
                        ),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(_modeLabel(context, mode)),
                        ),
                      ),
                    ),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (selection) => onSelected(selection.single),
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
