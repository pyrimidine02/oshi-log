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
    final background = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

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
    final selectedBackground = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final motionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
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
        ko: '팬 자료실',
        en: 'Fan library',
        ja: 'ファン資料室',
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
            duration: motionDuration,
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GBTTypography.labelSmall.copyWith(
                color: selected ? ink : muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
