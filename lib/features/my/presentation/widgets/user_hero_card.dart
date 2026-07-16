/// EN: Hero fan-level card with XP ring + grade badge + progress bar.
/// KO: XP 링·등급 배지·진행 바가 있는 히어로 팬레벨 카드.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../../fan_level/domain/entities/fan_level.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../titles/application/titles_controller.dart';
import '../../../titles/domain/entities/title_entities.dart';
import '../../../titles/presentation/widgets/active_title_badge.dart';
import 'xp_ring_painter.dart';

// EN: Format XP with thousands separators.
// KO: XP 값에 천 단위 구분자를 삽입합니다.
String _fmtXp(int xp) => xp.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

/// EN: Hero fan-level card with XP ring, grade badge, and progress bar.
/// KO: XP 링, 등급 배지, 진행 바가 있는 히어로 팬레벨 카드.
class UserHeroCard extends ConsumerWidget {
  const UserHeroCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fanLevelControllerProvider);
    final avatarUrl = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.avatarUrl;
    final activeTitle = ref.watch(activeTitleProvider).valueOrNull;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final secondaryColor = isDark
        ? GBTColors.darkSecondary
        : GBTColors.secondary;
    final fillColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;

    return GestureDetector(
      onTap: () => context.pushNamed(AppRoutes.fanLevel),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          boxShadow: isDark ? GBTShadows.darkSm : GBTShadows.sm,
        ),
        child: Stack(
          children: [
            // EN: Subtle stage-gradient edge — the card's "ticket stub" accent.
            // KO: 미세한 스테이지 그라디언트 엣지 — 카드의 "티켓 스텁" 강조.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md + 4,
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
              ),
              child: state.when(
                loading: () => const _HeroSkeleton(),
                error: (_, __) => _HeroError(isDark: isDark),
                data: (profile) => profile == null
                    ? _HeroLoginPrompt(
                        isDark: isDark,
                        primaryColor: primaryColor,
                      )
                    : _HeroContent(
                        isDark: isDark,
                        profile: profile,
                        primaryColor: primaryColor,
                        avatarUrl: avatarUrl,
                        activeTitle: activeTitle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.isDark,
    required this.profile,
    required this.primaryColor,
    this.avatarUrl,
    this.activeTitle,
  });

  final bool isDark;
  final FanLevelProfile profile;
  final Color primaryColor;
  final String? avatarUrl;
  final ActiveTitleItem? activeTitle;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final gradeName = isKo ? profile.grade.koLabel : profile.grade.enLabel;
    final hasAvatar = avatarUrl?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // EN: XP arc ring with the fan's avatar (or grade icon fallback)
            // in the centre, plus a small grade-icon badge when an avatar
            // is shown.
            // KO: 중앙에 팬 아바타(없으면 등급 아이콘)가 있는 XP 호 링,
            // 아바타 표시 시 작은 등급 아이콘 배지를 함께 표시.
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: XpRingPainter(
                      progress: profile.progressRatio,
                      color: primaryColor,
                      trackColor: primaryColor.withValues(
                        alpha: isDark ? 0.22 : 0.14,
                      ),
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.16 : 0.09,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: hasAvatar
                        ? ClipOval(
                            child: GBTImage(
                              imageUrl: avatarUrl!,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              semanticLabel: context.l10n(
                                ko: '프로필 사진',
                                en: 'Profile photo',
                                ja: 'プロフィール写真',
                              ),
                            ),
                          )
                        : Icon(
                            _gradeIcon(profile.grade),
                            color: primaryColor,
                            size: 26,
                          ),
                  ),
                  if (hasAvatar)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? GBTColors.darkSurfaceElevated
                                : GBTColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _gradeIcon(profile.grade),
                          color: GBTColors.textInverse,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: GBTSpacing.md),

            // EN: Grade name + check-in badge + active title + XP text.
            // KO: 등급명 + 출석 배지 + 활성 칭호 + XP 텍스트.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        gradeName,
                        style: GBTTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      if (profile.hasCheckedInToday) ...[
                        const SizedBox(width: GBTSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: GBTColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 10,
                                color: GBTColors.success,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                context.l10n(
                                  ko: '출석',
                                  en: 'Checked in',
                                  ja: '出席',
                                ),
                                style: GBTTypography.labelSmall.copyWith(
                                  color: GBTColors.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (activeTitle != null && activeTitle!.name.isNotEmpty) ...[
                    const SizedBox(height: GBTSpacing.xxs),
                    ActiveTitleBadge.fromActiveItem(activeTitle!),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    '${_fmtXp(profile.totalXp)} XP',
                    style: GBTTypography.labelLarge.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  // EN: XP min/max labels above the bar.
                  // KO: 바 위의 XP 최소/최대 라벨.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmtXp(profile.currentLevelXp),
                        style: GBTTypography.labelSmall.copyWith(
                          color: textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _fmtXp(profile.nextLevelXp),
                        style: GBTTypography.labelSmall.copyWith(
                          color: textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // EN: Linear XP progress bar.
                  // KO: 선형 XP 진행 바.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: profile.progressRatio,
                      minHeight: 5,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: GBTSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: textTertiary, size: 18),
          ],
        ),
      ],
    );
  }

  static IconData _gradeIcon(FanGrade grade) => switch (grade) {
    FanGrade.newbie => Icons.person_outline_rounded,
    FanGrade.beginner => Icons.star_outline_rounded,
    FanGrade.enthusiast => Icons.auto_awesome_outlined,
    FanGrade.devotee => Icons.favorite_outline_rounded,
    FanGrade.master => Icons.workspace_premium_outlined,
    FanGrade.legend => Icons.emoji_events_outlined,
  };
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return GBTShimmer(
      child: Row(
        children: [
          const GBTShimmerContainer(width: 80, height: 80, borderRadius: 40),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GBTShimmerContainer(
                  width: 100,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const GBTShimmerContainer(
                  width: 70,
                  height: 10,
                  borderRadius: 4,
                ),
                const SizedBox(height: 10),
                GBTShimmerContainer(
                  width: double.infinity,
                  height: 5,
                  borderRadius: GBTSpacing.radiusFull,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: textSecondary, size: 20),
          const SizedBox(width: GBTSpacing.sm),
          Text(
            context.l10n(
              ko: '덕력 정보를 불러올 수 없어요',
              en: 'Could not load fan level',
              ja: 'ファンレベルを読み込めませんでした',
            ),
            style: GBTTypography.bodySmall.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HeroLoginPrompt extends StatelessWidget {
  const _HeroLoginPrompt({required this.isDark, required this.primaryColor});

  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
      child: Row(
        children: [
          GBTIconChip(
            icon: Icons.person_outline_rounded,
            color: primaryColor,
            size: 48,
          ),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Text(
              context.l10n(
                ko: '로그인하면 덕력을 확인할 수 있어요',
                en: 'Log in to see your fan level',
                ja: 'ログインしてファンレベルを確認',
              ),
              style: GBTTypography.bodySmall.copyWith(color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
