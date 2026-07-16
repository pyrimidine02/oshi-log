/// EN: Travel-journal masthead for the clean-sheet community root.
/// KO: 새 커뮤니티 루트를 위한 여행 저널형 마스트헤드.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';

/// EN: Establishes the shared-notes identity without a generic app bar.
/// KO: 일반 앱 바 없이 공유 노트의 정체성을 보여줍니다.
class FieldCommunityMasthead extends StatelessWidget {
  const FieldCommunityMasthead({
    super.key,
    required this.onSearch,
    required this.onSettings,
  });

  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.sm,
        GBTSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'GBT / SHARED NOTES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _MastheadAction(
                icon: Icons.search_rounded,
                label: context.l10n(
                  ko: '커뮤니티 검색',
                  en: 'Search community',
                  ja: 'コミュニティを検索',
                ),
                onPressed: onSearch,
              ),
              _MastheadAction(
                icon: Icons.tune_rounded,
                label: context.l10n(
                  ko: '커뮤니티 설정',
                  en: 'Community settings',
                  ja: 'コミュニティ設定',
                ),
                onPressed: onSettings,
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            'FIELD REPORTS',
            maxLines: 1,
            style: GBTTypography.displayMedium.copyWith(
              color: ink,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '다녀온 곳과 알게 된 것을, 다음 여행자에게.',
              en: 'Places visited and lessons learned, for the next traveler.',
              ja: '訪れた場所と学んだことを、次の旅人へ。',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GBTTypography.bodySmall.copyWith(color: muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MastheadAction extends StatelessWidget {
  const _MastheadAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: SizedBox.square(
          dimension: GBTSpacing.touchTarget,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}
