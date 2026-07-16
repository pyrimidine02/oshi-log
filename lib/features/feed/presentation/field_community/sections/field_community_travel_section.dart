/// EN: Honest beta state for travel notes until a real data contract exists.
/// KO: 실제 데이터 계약이 준비될 때까지 표시하는 정직한 여행 노트 베타 상태.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';

/// EN: Does not fabricate itinerary, place, event, or review content.
/// KO: 일정, 장소, 이벤트, 후기 콘텐츠를 임의로 만들지 않습니다.
class FieldCommunityTravelSection extends StatelessWidget {
  const FieldCommunityTravelSection({
    super.key,
    required this.onWriteGeneralReport,
  });

  final VoidCallback onWriteGeneralReport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;

    return CustomScrollView(
      key: const Key('field-community-travel-beta'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.lg,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BetaRoute(),
                    const SizedBox(height: GBTSpacing.xl),
                    _BetaHero(
                      surface: surface,
                      border: border,
                      onWriteGeneralReport: onWriteGeneralReport,
                    ),
                    const SizedBox(height: GBTSpacing.xl),
                    Text(
                      context.l10n(
                        ko: 'BETA BUILD LIST',
                        en: 'BETA BUILD LIST',
                        ja: 'BETA BUILD LIST',
                      ),
                      style: GBTTypography.labelSmall.copyWith(
                        color: isDark
                            ? GBTColors.darkSecondary
                            : GBTColors.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    _BetaRequirement(
                      index: '01',
                      title: context.l10n(
                        ko: '검증된 방문 지점',
                        en: 'Verified stops',
                        ja: '確認済みの訪問スポット',
                      ),
                      body: context.l10n(
                        ko: '실제 장소와 방문 기록을 한 노트에 연결합니다.',
                        en: 'Connect real places and visit records to one note.',
                        ja: '実在の場所と訪問記録を1つのノートに結びます。',
                      ),
                    ),
                    _BetaRequirement(
                      index: '02',
                      title: context.l10n(
                        ko: '실제 일정 맥락',
                        en: 'Real event context',
                        ja: '実際のイベント情報',
                      ),
                      body: context.l10n(
                        ko: '라이브와 이벤트 일정을 임의 텍스트가 아닌 실제 데이터로 연결합니다.',
                        en: 'Attach live and event schedules from real records.',
                        ja: 'ライブやイベント予定を実データから紐付けます。',
                      ),
                    ),
                    _BetaRequirement(
                      index: '03',
                      title: context.l10n(
                        ko: '위치 공개는 사용자 선택',
                        en: 'Location privacy first',
                        ja: '位置情報はユーザーが選択',
                      ),
                      body: context.l10n(
                        ko: '정확한 이동 경로와 방문 시간은 작성자가 공개 범위를 결정합니다.',
                        en: 'Authors choose whether route and visit times are shared.',
                        ja: '移動経路や訪問時間の公開範囲は作成者が決めます。',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: GBTSpacing.bottomNavClearanceOf(
              context,
              barHeight: GBTSpacing.bottomNavHeight + GBTSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}

class _BetaRoute extends StatelessWidget {
  const _BetaRoute();

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n(ko: '기록', en: 'CAPTURE', ja: '記録'),
      context.l10n(ko: '연결', en: 'CONNECT', ja: '接続'),
      context.l10n(ko: '공유', en: 'SHARE', ja: '共有'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: index == 0 ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: index == 0 ? accent : border),
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (index < labels.length - 1)
            Expanded(child: Divider(height: 1, color: border)),
        ],
      ],
    );
  }
}

class _BetaHero extends StatelessWidget {
  const _BetaHero({
    required this.surface,
    required this.border,
    required this.onWriteGeneralReport,
  });

  final Color surface;
  final Color border;
  final VoidCallback onWriteGeneralReport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            top: BorderSide(color: accent, width: 4),
            left: BorderSide(color: border),
            right: BorderSide(color: border),
            bottom: BorderSide(color: border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route_outlined, color: accent),
                  const Spacer(),
                  Text(
                    'BETA / 01',
                    style: GBTTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.lg),
              Text(
                context.l10n(
                  ko: '여행 노트는 정직한 베타 단계예요',
                  en: 'Travel notes are in honest beta',
                  ja: '旅ノートは正直なベータ段階です',
                ),
                style: GBTTypography.headlineLarge.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '장소·방문·이벤트를 연결하는 실제 계약이 아직 준비 중입니다. 그래서 샘플 후기를 실제 글처럼 보여주지 않습니다.',
                  en: 'The place, visit, and event link contract is not live yet, so this page does not present sample reviews as real posts.',
                  ja: '場所・訪問・イベントの連携仕様はまだ準備中です。そのため、サンプルを実在の投稿のように表示しません。',
                ),
                style: GBTTypography.bodyMedium.copyWith(
                  color: muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: GBTSpacing.lg),
              FilledButton.icon(
                key: const Key('field-community-beta-compose'),
                onPressed: onWriteGeneralReport,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  context.l10n(
                    ko: '일반 필드 리포트 쓰기',
                    en: 'Write a regular field report',
                    ja: '通常のフィールドレポートを書く',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetaRequirement extends StatelessWidget {
  const _BetaRequirement({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? GBTColors.darkBorderSubtle : GBTColors.divider;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                index,
                style: GBTTypography.labelSmall.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GBTTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    body,
                    style: GBTTypography.bodySmall.copyWith(
                      color: muted,
                      height: 1.5,
                    ),
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
