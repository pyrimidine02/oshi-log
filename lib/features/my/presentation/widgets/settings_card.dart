/// EN: Full-width settings card — neutral, at the bottom.
/// KO: 전체 너비 설정 카드 — 중립 색상, 하단 배치.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';

/// EN: Full-width tappable settings entry card.
/// KO: 전체 너비 탭 가능한 설정 진입 카드.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final iconColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: GBTSpacing.sm2,
          ),
          // EN: Override default card radius with the 2026 bento radius.
          // KO: 기본 카드 반지름을 2026 벤토 반지름으로 재정의.
          decoration: GBTDecorations.card(isDark: isDark).copyWith(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          ),
          child: Row(
            children: [
              GBTIconChip(
                icon: Icons.settings_outlined,
                color: iconColor,
                size: 40,
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n(ko: '앱 설정', en: 'App Settings', ja: 'アプリ設定'),
                      style: GBTTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n(
                        ko: '프로필, 알림, 계정 설정',
                        en: 'Profile, notifications, account',
                        ja: 'プロフィール、通知、アカウント',
                      ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
