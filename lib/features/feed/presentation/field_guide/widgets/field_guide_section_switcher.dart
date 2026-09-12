/// EN: Three-destination section switcher for the Field Guide.
/// KO: Field Guide의 세 가지 목적지 섹션 스위처.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_spacing.dart';

enum FieldGuideSection { updates, artists, kit }

class FieldGuideSectionSwitcher extends StatelessWidget {
  const FieldGuideSectionSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FieldGuideSection selected;
  final ValueChanged<FieldGuideSection> onSelected;

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
            child: SegmentedButton<FieldGuideSection>(
              showSelectedIcon: false,
              segments: [
                for (final section in FieldGuideSection.values)
                  ButtonSegment(
                    value: section,
                    label: Semantics(
                      key: Key('field-guide-section-${section.name}'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: GBTSpacing.touchTarget,
                        ),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(_sectionLabel(context, section)),
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

String _sectionLabel(BuildContext context, FieldGuideSection section) {
  return switch (section) {
    FieldGuideSection.updates => context.l10n(
      ko: '업데이트',
      en: 'Updates',
      ja: '更新',
    ),
    FieldGuideSection.artists => context.l10n(
      ko: '아티스트',
      en: 'Artists',
      ja: 'アーティスト',
    ),
    FieldGuideSection.kit => context.l10n(
      ko: '팬 자료실',
      en: 'Fan library',
      ja: 'ファン資料室',
    ),
  };
}
