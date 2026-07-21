/// EN: Ruled ledger, upcoming schedule, and archive index sections.
/// KO: 줄 원장, 다가오는 일정, 보관함 인덱스 섹션입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import 'passport_schedule_labels.dart';
import 'travel_passport_view_data.dart';

/// EN: Shared editorial section heading with an optional action.
/// KO: 선택 액션을 포함할 수 있는 공통 에디토리얼 섹션 헤더입니다.
class PassportSectionHeading extends StatelessWidget {
  const PassportSectionHeading({
    super.key,
    required this.index,
    required this.title,
    required this.eyebrow,
    this.actionLabel,
    this.onAction,
  });

  final String index;
  final String title;
  final String eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = _SectionColors.of(context);
    final heading = Semantics(
      header: true,
      label: '$index $title',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final label = actionLabel;
    final Widget? action = label == null
        ? null
        : ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GBTSpacing.touchTarget,
            ),
            child: TextButton(onPressed: onAction, child: Text(label)),
          );
    if (action == null) return heading;

    final usesStackedAction = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    if (usesStackedAction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const SizedBox(height: GBTSpacing.xs),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: heading),
        const SizedBox(width: GBTSpacing.sm),
        action,
      ],
    );
  }
}

/// EN: Four real account totals arranged as one ruled ledger, not four cards.
/// KO: 네 개의 실제 계정 합계를 카드 네 개가 아닌 하나의 줄 원장으로 배치합니다.
class JourneyLedger extends StatelessWidget {
  const JourneyLedger({
    super.key,
    required this.data,
    required this.profileStatus,
  });

  final JourneyLedgerData data;
  final PassportProfileStatus profileStatus;

  @override
  Widget build(BuildContext context) {
    final colors = _SectionColors.of(context);
    return Column(
      key: const Key('journey-ledger'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassportSectionHeading(
          index: '01',
          eyebrow: 'JOURNEY LEDGER',
          title: context.l10n(ko: '나의 여정 원장', en: 'Journey ledger', ja: '旅の台帳'),
        ),
        const SizedBox(height: GBTSpacing.md),
        Container(
          decoration: BoxDecoration(border: Border.all(color: colors.rule)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _LedgerCell(
                      value: _availableValue(data.totalVisits),
                      label: context.l10n(
                        ko: '총 방문',
                        en: 'Total visits',
                        ja: '総訪問',
                      ),
                      colors: colors,
                    ),
                  ),
                  _VerticalRule(color: colors.rule),
                  Expanded(
                    child: _LedgerCell(
                      value: _availableValue(data.uniquePlaces),
                      label: context.l10n(
                        ko: '성지 도장',
                        en: 'Place stamps',
                        ja: '聖地スタンプ',
                      ),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: colors.rule),
              Row(
                children: [
                  Expanded(
                    child: _LedgerCell(
                      value: _availableValue(data.liveAttendances),
                      label: context.l10n(
                        ko: '라이브 참석',
                        en: 'Live attendance',
                        ja: 'ライブ参加',
                      ),
                      colors: colors,
                    ),
                  ),
                  _VerticalRule(color: colors.rule),
                  Expanded(
                    child: _LedgerCell(
                      value: _availableValue(data.sharedNotes),
                      label: context.l10n(
                        ko: '공유한 기록',
                        en: 'Shared notes',
                        ja: '共有ノート',
                      ),
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          _sourceLabel(context),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
        ),
      ],
    );
  }

  int? _availableValue(int value) {
    return profileStatus == PassportProfileStatus.ready ? value : null;
  }

  String _sourceLabel(BuildContext context) {
    return switch (profileStatus) {
      PassportProfileStatus.loading => context.l10n(
        ko: '계정 활동 기록 불러오는 중…',
        en: 'Loading account activity…',
        ja: 'アカウント活動を読み込み中…',
      ),
      PassportProfileStatus.unavailable => context.l10n(
        ko: '계정 활동 기록을 불러오지 못했어요',
        en: 'Account activity unavailable',
        ja: 'アカウント活動を読み込めません',
      ),
      PassportProfileStatus.ready => context.l10n(
        ko: '계정 활동 기록 기준',
        en: 'Based on account activity records',
        ja: 'アカウント活動記録に基づく',
      ),
    };
  }
}

class _LedgerCell extends StatelessWidget {
  const _LedgerCell({
    required this.value,
    required this.label,
    required this.colors,
  });

  final int? value;
  final String label;
  final _SectionColors colors;

  @override
  Widget build(BuildContext context) {
    final valueLabel = value?.toString() ?? '—';
    return Semantics(
      label: '$label, $valueLabel',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 86),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.mutedInk,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 86, color: color);
  }
}

/// EN: The nearest real calendar items rendered as timetable rows.
/// KO: 가장 가까운 실제 캘린더 항목을 시간표 행으로 표시합니다.
class NextStopsSection extends StatelessWidget {
  const NextStopsSection({
    super.key,
    required this.stops,
    required this.scheduleStatus,
    required this.onOpenCalendar,
    required this.onOpenStop,
  });

  final List<UpcomingStopData> stops;
  final PassportScheduleStatus scheduleStatus;
  final VoidCallback onOpenCalendar;
  final ValueChanged<UpcomingStopData> onOpenStop;

  @override
  Widget build(BuildContext context) {
    final colors = _SectionColors.of(context);
    return Column(
      key: const Key('next-stops'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassportSectionHeading(
          index: '02',
          eyebrow: 'NEXT DEPARTURES',
          title: context.l10n(ko: '다가오는 일정', en: 'Next departures', ja: '次の予定'),
          actionLabel: context.l10n(ko: '전체보기', en: 'Calendar', ja: 'カレンダー'),
          onAction: onOpenCalendar,
        ),
        const SizedBox(height: GBTSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.ink, width: 1.2),
              bottom: BorderSide(color: colors.ink, width: 1.2),
            ),
          ),
          child: stops.isEmpty
              ? _NoUpcomingStops(
                  colors: colors,
                  scheduleStatus: scheduleStatus,
                  onOpenCalendar: onOpenCalendar,
                )
              : Column(
                  children: [
                    for (var index = 0; index < stops.length; index++) ...[
                      _NextStopRow(
                        stop: stops[index],
                        colors: colors,
                        onTap: () => onOpenStop(stops[index]),
                      ),
                      if (index != stops.length - 1)
                        Divider(height: 1, color: colors.rule),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _NoUpcomingStops extends StatelessWidget {
  const _NoUpcomingStops({
    required this.colors,
    required this.scheduleStatus,
    required this.onOpenCalendar,
  });

  final _SectionColors colors;
  final PassportScheduleStatus scheduleStatus;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenCalendar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
            child: Row(
              children: [
                if (scheduleStatus == PassportScheduleStatus.loading)
                  SizedBox.square(
                    dimension: GBTSpacing.iconMd,
                    child: CircularProgressIndicator(
                      color: colors.accent,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.calendar_today_outlined, color: colors.accent),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Text(
                    _emptyScheduleLabel(context),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: colors.mutedInk),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _emptyScheduleLabel(BuildContext context) {
    return switch (scheduleStatus) {
      PassportScheduleStatus.loading => context.l10n(
        ko: '다가오는 일정을 불러오는 중…',
        en: 'Loading upcoming schedule…',
        ja: '今後の予定を読み込み中…',
      ),
      PassportScheduleStatus.unavailable => context.l10n(
        ko: '다가오는 일정을 불러오지 못했어요. 달력에서 다시 확인해보세요.',
        en: 'Could not load upcoming schedule. Try again in the calendar.',
        ja: '今後の予定を読み込めませんでした。カレンダーで再確認してください。',
      ),
      PassportScheduleStatus.ready => context.l10n(
        ko: '다음 달까지 예정된 일정이 없어요. 전체 달력을 확인해보세요.',
        en: 'No schedule through next month. Open the full calendar.',
        ja: '来月までに予定されたスケジュールはありません。カレンダーを確認しましょう。',
      ),
    };
  }
}

class _NextStopRow extends StatelessWidget {
  const _NextStopRow({
    required this.stop,
    required this.colors,
    required this.onTap,
  });

  final UpcomingStopData stop;
  final _SectionColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = stop.date.toLocal();
    final typeLabel = _eventTypeLabel(context, stop.type);
    return Semantics(
      button: true,
      label: '${stop.title}, ${date.month}/${date.day}, $typeLabel',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('next-stop-${stop.eventId}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          passportMonthLabel(context, date.month),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        Text(
                          date.day.toString().padLeft(2, '0'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 2, height: 42, color: colors.accent),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          typeLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.mutedInk,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                        ),
                        Text(
                          stop.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.mutedInk,
                    size: GBTSpacing.iconSm,
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: A flat ruled index into the user's saved travel material.
/// KO: 사용자가 저장한 여행 자료로 이동하는 평면 줄 인덱스입니다.
class TravelArchiveSection extends StatelessWidget {
  const TravelArchiveSection({
    super.key,
    required this.ledger,
    required this.profileStatus,
    required this.onOpenVisits,
    required this.onOpenCollection,
    required this.onOpenBookmarks,
    required this.onOpenFavorites,
  });

  final JourneyLedgerData ledger;
  final PassportProfileStatus profileStatus;
  final VoidCallback onOpenVisits;
  final VoidCallback onOpenCollection;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    final colors = _SectionColors.of(context);
    final rows = <_ArchiveRowData>[
      _ArchiveRowData(
        keyName: 'archive-visits',
        number: '01',
        title: context.l10n(ko: '방문 여권', en: 'Visit passport', ja: '訪問パスポート'),
        subtitle: _visitArchiveLabel(context),
        onTap: onOpenVisits,
      ),
      _ArchiveRowData(
        keyName: 'archive-collection',
        number: '02',
        title: context.l10n(
          ko: '성지 도감',
          en: 'Place collection',
          ja: '聖地コレクション',
        ),
        subtitle: _collectionArchiveLabel(context),
        onTap: onOpenCollection,
      ),
      _ArchiveRowData(
        keyName: 'archive-bookmarks',
        number: '03',
        title: context.l10n(
          ko: '저장한 정보',
          en: 'Saved information',
          ja: '保存した情報',
        ),
        subtitle: context.l10n(
          ko: '커뮤니티에서 저장한 글',
          en: 'Bookmarked community notes',
          ja: 'ブックマークしたコミュニティノート',
        ),
        onTap: onOpenBookmarks,
      ),
      _ArchiveRowData(
        keyName: 'archive-favorites',
        number: '04',
        title: context.l10n(ko: '가고 싶은 곳', en: 'Saved places', ja: '行きたい場所'),
        subtitle: context.l10n(
          ko: '즐겨찾기한 장소와 여정',
          en: 'Favorite places and plans',
          ja: 'お気に入りの場所と予定',
        ),
        onTap: onOpenFavorites,
      ),
    ];

    return Column(
      key: const Key('travel-archive'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassportSectionHeading(
          index: '03',
          eyebrow: 'ARCHIVE INDEX',
          title: context.l10n(
            ko: '여행 보관함',
            en: 'Travel archive',
            ja: '旅のアーカイブ',
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.ink, width: 1.2)),
          ),
          child: Column(
            children: [for (final row in rows) _ArchiveRow(row: row)],
          ),
        ),
      ],
    );
  }

  String _visitArchiveLabel(BuildContext context) {
    return switch (profileStatus) {
      PassportProfileStatus.loading => context.l10n(
        ko: '방문 기록 불러오는 중…',
        en: 'Loading visit records…',
        ja: '訪問記録を読み込み中…',
      ),
      PassportProfileStatus.unavailable => context.l10n(
        ko: '방문 기록을 불러오지 못했어요',
        en: 'Visit records unavailable',
        ja: '訪問記録を読み込めません',
      ),
      PassportProfileStatus.ready => context.l10n(
        ko: '총 방문 기록 ${ledger.totalVisits}건',
        en: '${ledger.totalVisits} total visit records',
        ja: '総訪問記録 ${ledger.totalVisits}件',
      ),
    };
  }

  String _collectionArchiveLabel(BuildContext context) {
    return switch (profileStatus) {
      PassportProfileStatus.loading => context.l10n(
        ko: '성지 도감 불러오는 중…',
        en: 'Loading place collection…',
        ja: '聖地コレクションを読み込み中…',
      ),
      PassportProfileStatus.unavailable => context.l10n(
        ko: '성지 도감을 불러오지 못했어요',
        en: 'Place collection unavailable',
        ja: '聖地コレクションを読み込めません',
      ),
      PassportProfileStatus.ready => context.l10n(
        ko: '방문한 성지 ${ledger.uniquePlaces}곳',
        en: '${ledger.uniquePlaces} visited places',
        ja: '訪問済み ${ledger.uniquePlaces}ヶ所',
      ),
    };
  }
}

class _ArchiveRowData {
  const _ArchiveRowData({
    required this.keyName,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final String number;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.row});

  final _ArchiveRowData row;

  @override
  Widget build(BuildContext context) {
    final colors = _SectionColors.of(context);
    return Semantics(
      button: true,
      label: '${row.title}, ${row.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(row.keyName),
          onTap: row.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.rule)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    row.number,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        row.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        row.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colors.mutedInk,
                  size: GBTSpacing.iconSm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _eventTypeLabel(BuildContext context, CalendarEventType type) {
  return switch (type) {
    CalendarEventType.characterBirthday => context.l10n(
      ko: '캐릭터 생일',
      en: 'Character birthday',
      ja: 'キャラクター誕生日',
    ),
    CalendarEventType.voiceActorBirthday => context.l10n(
      ko: '성우 생일',
      en: 'Voice actor birthday',
      ja: '声優誕生日',
    ),
    CalendarEventType.release => context.l10n(
      ko: '발매',
      en: 'Release',
      ja: '発売',
    ),
    CalendarEventType.live => context.l10n(
      ko: '라이브 / 이벤트',
      en: 'Live / event',
      ja: 'ライブ / イベント',
    ),
    CalendarEventType.ticketSale => context.l10n(
      ko: '티켓 오픈',
      en: 'Ticket sale',
      ja: 'チケット発売',
    ),
    CalendarEventType.streaming => context.l10n(
      ko: '방송 / 스트리밍',
      en: 'Streaming',
      ja: '配信',
    ),
    CalendarEventType.general => context.l10n(
      ko: '일정',
      en: 'Schedule',
      ja: '予定',
    ),
  };
}

class _SectionColors {
  const _SectionColors({
    required this.ink,
    required this.mutedInk,
    required this.rule,
    required this.accent,
  });

  final Color ink;
  final Color mutedInk;
  final Color rule;
  final Color accent;

  factory _SectionColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionColors(
      ink: isDark ? GBTColors.darkTextPrimary : GBTColors.fieldInk,
      mutedInk: isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
      rule: isDark ? GBTColors.darkBorder : GBTColors.border,
      accent: isDark ? GBTColors.darkPrimary : GBTColors.fieldBlue,
    );
  }
}
