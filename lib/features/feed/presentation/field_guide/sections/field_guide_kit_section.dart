/// EN: A single travel document for planning, attending, and archiving a trip.
/// KO: 여행 준비, 현장 참여, 기록을 하나로 묶은 여행 문서입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_spacing.dart';

/// EN: Orders practical tools by the moment a traveler needs them.
/// KO: 여행자가 도구를 쓰는 시점에 따라 실용 기능을 정렬합니다.
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
        _KitDocument(
          stages: [
            _KitJourneyStage(
              number: '01',
              title: context.l10n(ko: '일정', en: 'Schedule', ja: '予定'),
              routes: [
                _KitRouteData(
                  key: const Key('field-kit-route-calendar'),
                  icon: Icons.calendar_month_outlined,
                  title: context.l10n(
                    ko: '이벤트 캘린더',
                    en: 'Event calendar',
                    ja: 'イベントカレンダー',
                  ),
                  subtitle: context.l10n(
                    ko: '공연과 팝업 일정을 한 흐름으로 확인',
                    en: 'Shows and pop-ups on one timeline',
                    ja: '公演とポップアップをひとつの予定表で',
                  ),
                  onTap: onCalendarTap,
                ),
              ],
            ),
            _KitJourneyStage(
              number: '02',
              title: context.l10n(
                ko: '음악과 응원',
                en: 'Music & cheering',
                ja: '音楽と応援',
              ),
              routes: [
                _KitRouteData(
                  key: const Key('field-kit-route-music'),
                  icon: Icons.album_outlined,
                  title: context.l10n(
                    ko: '음악·가사',
                    en: 'Music & lyrics',
                    ja: '音楽・歌詞',
                  ),
                  subtitle: context.l10n(
                    ko: '앨범, 악곡, 라이브 정보를 한곳에서',
                    en: 'Albums, songs, and live context in one place',
                    ja: 'アルバム・楽曲・ライブ情報をひとつに',
                  ),
                  onTap: onMusicTap,
                ),
                _KitRouteData(
                  key: const Key('field-kit-route-cheer'),
                  icon: Icons.campaign_outlined,
                  title: context.l10n(
                    ko: '응원 가이드',
                    en: 'Cheer guides',
                    ja: '応援ガイド',
                  ),
                  subtitle: context.l10n(
                    ko: '곡별 콜과 현장 포인트를 바로 확인',
                    en: 'Calls and live cues when you need them',
                    ja: '曲ごとのコールとライブのポイント',
                  ),
                  onTap: onCheerGuidesTap,
                ),
              ],
            ),
            _KitJourneyStage(
              number: '03',
              title: context.l10n(
                ko: '기억과 수집',
                en: 'Memories & collection',
                ja: '記憶と収集',
              ),
              routes: [
                _KitRouteData(
                  key: const Key('field-kit-route-collection'),
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
                _KitRouteData(
                  key: const Key('field-kit-route-quotes'),
                  icon: Icons.format_quote_rounded,
                  title: context.l10n(
                    ko: '대사 노트',
                    en: 'Quote notes',
                    ja: 'セリフノート',
                  ),
                  subtitle: context.l10n(
                    ko: '장면을 기억하게 하는 대사를 다시 보기',
                    en: 'Revisit the lines that made the scene',
                    ja: 'あの場面を残す言葉をもう一度',
                  ),
                  onTap: onQuotesTap,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _KitDocument extends StatelessWidget {
  const _KitDocument({required this.stages});

  final List<_KitJourneyStage> stages;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('field-kit-document'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: colors.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _KitDocumentHeader(),
                for (var index = 0; index < stages.length; index++) ...[
                  Divider(height: 1, color: colors.outlineVariant),
                  stages[index],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KitDocumentHeader extends StatelessWidget {
  const _KitDocumentHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAN REFERENCE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '팬 자료실',
              en: 'Everyday fan reference',
              ja: 'ファン資料室',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '일정, 음악·가사, 응원, 수집 정보를 필요할 때 바로 찾아보세요.',
              en: 'Find schedules, music, lyrics, cheering, and collections whenever you need them.',
              ja: '予定、音楽・歌詞、応援、コレクションをいつでも探せます。',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitJourneyStage extends StatelessWidget {
  const _KitJourneyStage({
    required this.number,
    required this.title,
    required this.routes,
  });

  final String number;
  final String title;
  final List<_KitRouteData> routes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          label: '$number $title',
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      number,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var index = 0; index < routes.length; index++) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.only(left: GBTSpacing.md + 36),
              child: Divider(height: 1, color: colors.outlineVariant),
            ),
          _KitRoute(data: routes[index]),
        ],
        const SizedBox(height: GBTSpacing.xs),
      ],
    );
  }
}

class _KitRouteData {
  const _KitRouteData({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key key;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _KitRoute extends StatelessWidget {
  const _KitRoute({required this.data});

  final _KitRouteData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: data.key,
      button: true,
      enabled: true,
      label: '${data.title}. ${data.subtitle}',
      onTap: data.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: data.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.md,
                  GBTSpacing.sm,
                  GBTSpacing.md,
                  GBTSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      child: Icon(data.icon, size: 22, color: colors.primary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: GBTSpacing.xxs),
                          Text(
                            data.subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
