/// EN: Three-destination section switcher for the Field Guide.
/// KO: Field Guide의 세 가지 목적지 섹션 스위처.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: border)),
      ),
      child: Row(
        children: FieldGuideSection.values
            .map(
              (section) => Expanded(
                child: _SectionDestination(
                  section: section,
                  selected: selected == section,
                  onTap: () => onSelected(section),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SectionDestination extends StatelessWidget {
  const _SectionDestination({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final FieldGuideSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final label = switch (section) {
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
        ko: '현장 키트',
        en: 'Field kit',
        ja: '現地キット',
      ),
    };
    final key = switch (section) {
      FieldGuideSection.updates => const Key('field-guide-section-updates'),
      FieldGuideSection.artists => const Key('field-guide-section-artists'),
      FieldGuideSection.kit => const Key('field-guide-section-kit'),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${section.index + 1}'.padLeft(2, '0'),
                  style: GBTTypography.labelSmall.copyWith(
                    color: selected ? accent : muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GBTTypography.labelSmall.copyWith(
                      color: selected ? ink : muted,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
