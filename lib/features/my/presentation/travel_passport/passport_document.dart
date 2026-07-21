/// EN: Editorial travel-document header and compact fan stamp.
/// KO: 에디토리얼 여행 문서 헤더와 간결한 팬 스탬프입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import 'travel_passport_view_data.dart';

/// EN: Passport-like identity block backed by the authenticated profile.
/// KO: 인증된 프로필을 기반으로 한 여권형 신원 블록입니다.
class PassportDocument extends StatelessWidget {
  const PassportDocument({
    super.key,
    required this.data,
    required this.onOpenFanLevel,
  });

  final TravelPassportViewData data;
  final VoidCallback onOpenFanLevel;

  @override
  Widget build(BuildContext context) {
    final colors = _PassportColors.of(context);
    return Semantics(
      container: true,
      label: context.l10n(
        ko: '내 여행 여권',
        en: 'My travel passport',
        ja: '私の旅行パスポート',
      ),
      child: Container(
        key: const Key('travel-passport-document'),
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.rule, width: 1.2),
          borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: colors.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md + 5,
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      'GIRLS BAND TABI · TRAVEL PASSPORT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.sm,
                    ),
                    child: Divider(height: 1, color: colors.rule),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return _IdentityBlock(
                        data: data,
                        colors: colors,
                        compact: constraints.maxWidth < 340,
                        onOpenFanLevel: onOpenFanLevel,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.data,
    required this.colors,
    required this.compact,
    required this.onOpenFanLevel,
  });

  final TravelPassportViewData data;
  final _PassportColors colors;
  final bool compact;
  final VoidCallback onOpenFanLevel;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 72.0 : 88.0;
    final stamp = data.fanStamp;
    final identityRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PassportPortrait(
          imageUrl: data.avatarUrl,
          size: avatarSize,
          colors: colors,
        ),
        const SizedBox(width: GBTSpacing.md),
        Expanded(
          child: _PassportIdentity(
            displayName: data.displayName,
            memberSince: data.memberSince,
            profileStatus: data.profileStatus,
            colors: colors,
          ),
        ),
        if (!compact && stamp != null) ...[
          const SizedBox(width: GBTSpacing.sm),
          FanGradeStamp(data: stamp, onPressed: onOpenFanLevel),
        ],
      ],
    );
    if (!compact || stamp == null) return identityRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        identityRow,
        const SizedBox(height: GBTSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FanGradeStamp(data: stamp, onPressed: onOpenFanLevel),
        ),
      ],
    );
  }
}

class _PassportPortrait extends StatelessWidget {
  const _PassportPortrait({
    required this.imageUrl,
    required this.size,
    required this.colors,
  });

  final String? imageUrl;
  final double size;
  final _PassportColors colors;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: colors.photoBackground,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          color: colors.mutedInk,
          size: 36,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: context.l10n(
        ko: '여행자 프로필 사진',
        en: 'Traveler profile photo',
        ja: '旅行者のプロフィール写真',
      ),
      child: Container(
        width: size,
        height: size * 1.18,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(color: colors.rule),
          borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: imageUrl == null
              ? fallback
              : GBTImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  useShimmer: false,
                  errorWidget: fallback,
                ),
        ),
      ),
    );
  }
}

class _PassportIdentity extends StatelessWidget {
  const _PassportIdentity({
    required this.displayName,
    required this.memberSince,
    required this.profileStatus,
    required this.colors,
  });

  final String? displayName;
  final DateTime? memberSince;
  final PassportProfileStatus profileStatus;
  final _PassportColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = switch (profileStatus) {
      PassportProfileStatus.loading => context.l10n(
        ko: '프로필 불러오는 중…',
        en: 'Loading profile…',
        ja: 'プロフィールを読み込み中…',
      ),
      PassportProfileStatus.unavailable => context.l10n(
        ko: '프로필을 불러오지 못했어요',
        en: 'Profile unavailable',
        ja: 'プロフィールを読み込めません',
      ),
      PassportProfileStatus.ready =>
        displayName ?? context.l10n(ko: '여행자', en: 'Traveler', ja: 'トラベラー'),
    };
    final issued =
        profileStatus != PassportProfileStatus.ready || memberSince == null
        ? '—'
        : '${memberSince!.year.toString().padLeft(4, '0')}.'
              '${memberSince!.month.toString().padLeft(2, '0')}.'
              '${memberSince!.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '성명 / NAME', en: 'NAME', ja: '氏名 / NAME'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: GBTSpacing.md),
        Text(
          context.l10n(
            ko: '발행일 / MEMBER SINCE',
            en: 'MEMBER SINCE',
            ja: '発行日 / MEMBER SINCE',
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          issued,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// EN: A small, secondary stamp linking to detailed fan progress.
/// KO: 상세 팬 진행도로 이동하는 작고 보조적인 스탬프입니다.
class FanGradeStamp extends StatelessWidget {
  const FanGradeStamp({super.key, required this.data, required this.onPressed});

  final FanStampData data;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _PassportColors.of(context);
    final grade = switch (Localizations.localeOf(context).languageCode) {
      'ko' => data.grade.koLabel,
      _ => data.grade.enLabel,
    };
    final semanticLabel = context.l10n(
      ko: '팬 등급 $grade, 상세 보기',
      en: 'Fan grade $grade, view details',
      ja: 'ファングレード $grade、詳細を表示',
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: -0.055,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('fan-grade-stamp'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.accent, width: 2),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accent),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FAN GRADE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        grade,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (data.rank > 0)
                        Text(
                          '#${data.rank}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportColors {
  const _PassportColors({
    required this.paper,
    required this.ink,
    required this.mutedInk,
    required this.rule,
    required this.accent,
    required this.photoBackground,
  });

  final Color paper;
  final Color ink;
  final Color mutedInk;
  final Color rule;
  final Color accent;
  final Color photoBackground;

  factory _PassportColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _PassportColors(
      paper: isDark ? GBTColors.darkSurface : GBTColors.fieldPaperRaised,
      ink: isDark ? GBTColors.darkTextPrimary : GBTColors.fieldInk,
      mutedInk: isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
      rule: isDark ? GBTColors.darkBorder : GBTColors.border,
      accent: isDark ? GBTColors.darkPrimary : GBTColors.fieldBlue,
      photoBackground: isDark
          ? GBTColors.darkSurfaceVariant
          : GBTColors.surfaceVariant,
    );
  }
}
