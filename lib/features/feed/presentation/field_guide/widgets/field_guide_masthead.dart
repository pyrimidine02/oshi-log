/// EN: Editorial masthead for the Field Guide root.
/// KO: Field Guide 루트의 에디토리얼 마스트헤드.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';

/// EN: Identifies the guide and the active project without a generic app bar.
/// KO: 일반적인 앱 바 대신 가이드와 활성 프로젝트를 식별합니다.
class FieldGuideMasthead extends StatelessWidget {
  const FieldGuideMasthead({
    super.key,
    required this.projectKey,
    required this.onSearch,
  });

  final String? projectKey;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final resolvedProject = projectKey?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'GBT / TRAVEL & FANDOM',
                  style: GBTTypography.labelSmall.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: context.l10n(
                  ko: '가이드 검색',
                  en: 'Search the guide',
                  ja: 'ガイドを検索',
                ),
                child: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                  color: ink,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(GBTSpacing.touchTarget),
                    side: BorderSide(color: border),
                    backgroundColor: surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.sm),
          Text(
            'FIELD GUIDE',
            maxLines: 1,
            style: GBTTypography.displayLarge.copyWith(
              color: ink,
              fontWeight: FontWeight.w900,
              height: 0.96,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  context.l10n(
                    ko: '좋아하는 세계를 따라 도시를 읽는 안내서',
                    en: 'Read the city through the worlds you love.',
                    ja: '好きな世界をたどり、街を読むための案内書。',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.bodySmall.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Container(
                constraints: const BoxConstraints(maxWidth: 104),
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.sm,
                  vertical: GBTSpacing.xs2,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
                ),
                child: Text(
                  resolvedProject == null || resolvedProject.isEmpty
                      ? 'ISSUE 01'
                      : resolvedProject.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GBTTypography.labelSmall.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
