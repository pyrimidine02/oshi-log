/// EN: Practical tools for planning, attending, and archiving a trip.
/// KO: 여행 준비, 현장 참여, 기록을 위한 실용 도구.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';

class FieldGuideKitSection extends StatelessWidget {
  const FieldGuideKitSection({
    super.key,
    required this.onMusicTap,
    required this.onCheerGuidesTap,
    required this.onCalendarTap,
    required this.onQuotesTap,
    required this.onCollectionTap,
  });

  final VoidCallback onMusicTap;
  final VoidCallback onCheerGuidesTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onQuotesTap;
  final VoidCallback onCollectionTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.bottomNavClearanceOf(context),
      ),
      children: [
        const _KitIntro(),
        const SizedBox(height: GBTSpacing.md),
        _MusicArchiveTicket(onTap: onMusicTap),
        const SizedBox(height: GBTSpacing.lg),
        _KitStageLabel(
          number: '01',
          label: context.l10n(ko: '출발 전', en: 'BEFORE YOU GO', ja: '出発前'),
        ),
        _KitRoute(
          icon: Icons.calendar_month_outlined,
          title: context.l10n(
            ko: '이벤트 캘린더',
            en: 'Event calendar',
            ja: 'イベントカレンダー',
          ),
          subtitle: context.l10n(
            ko: '공연과 팝업 일정을 한 번에 확인',
            en: 'Shows and pop-ups on one timeline',
            ja: '公演とポップアップをひとつの予定表で',
          ),
          onTap: onCalendarTap,
        ),
        const SizedBox(height: GBTSpacing.lg),
        _KitStageLabel(
          number: '02',
          label: context.l10n(ko: '현장에서', en: 'ON SITE', ja: '現地で'),
        ),
        _KitRoute(
          icon: Icons.campaign_outlined,
          title: context.l10n(ko: '응원 가이드', en: 'Cheer guides', ja: '応援ガイド'),
          subtitle: context.l10n(
            ko: '곡별 콜과 현장 포인트를 빠르게 확인',
            en: 'Calls and live cues when you need them',
            ja: '曲ごとのコールとライブのポイント',
          ),
          onTap: onCheerGuidesTap,
        ),
        const SizedBox(height: GBTSpacing.lg),
        _KitStageLabel(
          number: '03',
          label: context.l10n(ko: '여행 이후', en: 'AFTER THE TRIP', ja: '旅のあと'),
        ),
        _KitRoute(
          icon: Icons.collections_bookmark_outlined,
          title: context.l10n(
            ko: '컬렉션 도감',
            en: 'Collection index',
            ja: 'コレクション図鑑',
          ),
          subtitle: context.l10n(
            ko: '방문과 발견을 나만의 도감으로 정리',
            en: 'Archive the places and moments you found',
            ja: '訪問と発見を自分だけの図鑑に',
          ),
          onTap: onCollectionTap,
        ),
        _KitRoute(
          icon: Icons.format_quote_rounded,
          title: context.l10n(ko: '대사 노트', en: 'Quote notes', ja: 'セリフノート'),
          subtitle: context.l10n(
            ko: '장면을 기억하게 하는 대사를 다시 보기',
            en: 'Revisit the lines that made the scene',
            ja: 'あの場面を残す言葉をもう一度',
          ),
          onTap: onQuotesTap,
        ),
      ],
    );
  }
}

class _KitIntro extends StatelessWidget {
  const _KitIntro();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '현장 도구함', en: 'Your field kit', ja: '現地ツールキット'),
          style: GBTTypography.titleLarge.copyWith(
            color: ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          context.l10n(
            ko: '준비부터 귀가 후 기록까지, 필요한 정보만 순서대로 꺼내세요.',
            en: 'Plan, attend, and archive with the right tool at each step.',
            ja: '準備から帰宅後の記録まで、必要な道具を順番に。',
          ),
          style: GBTTypography.bodySmall.copyWith(color: muted, height: 1.45),
        ),
      ],
    );
  }
}

class _MusicArchiveTicket extends StatelessWidget {
  const _MusicArchiveTicket({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final foreground = isDark
        ? GBTColors.darkBackground
        : GBTColors.textInverse;

    return Semantics(
      button: true,
      label: context.l10n(
        ko: '음악 아카이브 열기',
        en: 'Open music archive',
        ja: '音楽アーカイブを開く',
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.14),
                    border: Border.all(
                      color: foreground.withValues(alpha: 0.38),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.album_rounded, color: foreground, size: 28),
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n(
                          ko: '음악 아카이브',
                          en: 'Music archive',
                          ja: '音楽アーカイブ',
                        ),
                        style: GBTTypography.titleMedium.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        context.l10n(
                          ko: '앨범, 악곡, 라이브 정보를 한곳에서',
                          en: 'Albums, songs, and live context in one place',
                          ja: 'アルバム・楽曲・ライブ情報をひとつに',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.bodySmall.copyWith(
                          color: foreground.withValues(alpha: 0.86),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Icon(Icons.arrow_forward_rounded, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KitStageLabel extends StatelessWidget {
  const _KitStageLabel({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? GBTColors.darkSecondary : GBTColors.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
      child: Row(
        children: [
          Text(
            number,
            style: GBTTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitRoute extends StatelessWidget {
  const _KitRoute({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    final accent = isDark ? GBTColors.darkSecondary : GBTColors.secondary;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GBTTypography.bodySmall.copyWith(
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
