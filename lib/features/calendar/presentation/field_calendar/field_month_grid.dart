/// EN: Accessible month grid for the Field Calendar.
/// KO: Field Calendar용 접근 가능한 월간 그리드.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/calendar_event.dart';
import 'calendar_view_data.dart';

/// EN: Month grid remains visible and interactive even with zero events.
/// KO: 이벤트가 없어도 계속 보이고 조작할 수 있는 월간 그리드입니다.
class FieldMonthGrid extends StatelessWidget {
  const FieldMonthGrid({
    super.key,
    required this.visibleMonth,
    required this.events,
    required this.onSelectDate,
    this.selectedDate,
  });

  final DateTime visibleMonth;
  final List<CalendarEvent> events;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final leadingDays = firstDay.weekday % DateTime.daysPerWeek;
    final dayCount = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final totalSlots = ((leadingDays + dayCount) / 7).ceil() * 7;
    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final event in events) {
      final local = event.date.toLocal();
      if (local.year == visibleMonth.year &&
          local.month == visibleMonth.month) {
        eventsByDay.putIfAbsent(local.day, () => []).add(event);
      }
    }
    final weekdayLabels = [
      context.l10n(ko: '일', en: 'S', ja: '日'),
      context.l10n(ko: '월', en: 'M', ja: '月'),
      context.l10n(ko: '화', en: 'T', ja: '火'),
      context.l10n(ko: '수', en: 'W', ja: '水'),
      context.l10n(ko: '목', en: 'T', ja: '木'),
      context.l10n(ko: '금', en: 'F', ja: '金'),
      context.l10n(ko: '토', en: 'S', ja: '土'),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalSlots,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 0,
            mainAxisSpacing: 2,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingDays + 1;
            if (day < 1 || day > dayCount) return const SizedBox.shrink();
            final date = DateTime(visibleMonth.year, visibleMonth.month, day);
            return _FieldDayCell(
              day: day,
              date: date,
              events: eventsByDay[day] ?? const [],
              isToday: isSameCalendarDate(date, DateTime.now()),
              isSelected:
                  selectedDate != null &&
                  isSameCalendarDate(date, selectedDate!),
              onTap: () => onSelectDate(date),
            );
          },
        ),
      ],
    );
  }
}

class _FieldDayCell extends StatelessWidget {
  const _FieldDayCell({
    required this.day,
    required this.date,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final DateTime date;
  final List<CalendarEvent> events;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eventTypes = events.map((event) => event.type).toSet().take(3);
    final eventCountLabel = events.isEmpty
        ? ''
        : context.l10n(
            ko: '일정 ${events.length}개',
            en: '${events.length} events',
            ja: '予定${events.length}件',
          );
    final fullDate = MaterialLocalizations.of(context).formatFullDate(date);
    final eventDetails = events
        .take(3)
        .map(
          (event) =>
              '${event.title} (${_eventTypeSemanticLabel(context, event.type)})',
        )
        .join('; ');
    final hiddenEventCount = events.length - 3;
    final hiddenEventLabel = hiddenEventCount > 0
        ? context.l10n(
            ko: '; 외 $hiddenEventCount개',
            en: '; $hiddenEventCount more',
            ja: '、他$hiddenEventCount件',
          )
        : '';
    final stateLabel = [
      if (isToday) context.l10n(ko: '오늘', en: 'today', ja: '今日'),
      if (isSelected) context.l10n(ko: '선택됨', en: 'selected', ja: '選択中'),
    ].join(', ');

    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      onTap: onTap,
      label: [
        fullDate,
        if (events.isNotEmpty)
          '$eventCountLabel: $eventDetails$hiddenEventLabel',
        if (stateLabel.isNotEmpty) stateLabel,
      ].join(', '),
      hint: context.l10n(
        ko: '두 번 탭하여 이 날짜의 일정 보기',
        en: 'Double tap to show events for this date',
        ja: 'ダブルタップしてこの日の予定を表示',
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isToday ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            border: isSelected
                ? Border.all(
                    color: isToday ? colors.onPrimary : colors.secondary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isToday ? colors.onPrimary : colors.onSurface,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final type in eventTypes)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isToday
                            ? colors.onPrimary
                            : calendarEventTypeColor(type, context),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (eventTypes.isEmpty) const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _eventTypeSemanticLabel(BuildContext context, CalendarEventType type) {
  return switch (type) {
    CalendarEventType.characterBirthday => context.l10n(
      ko: '캐릭터 생일',
      en: 'Character birthday',
      ja: 'キャラ誕生日',
    ),
    CalendarEventType.voiceActorBirthday => context.l10n(
      ko: '성우 생일',
      en: 'VA birthday',
      ja: '声優誕生日',
    ),
    CalendarEventType.release => context.l10n(
      ko: '발매',
      en: 'Release',
      ja: '発売',
    ),
    CalendarEventType.live => context.l10n(ko: '라이브', en: 'Live', ja: 'ライブ'),
    CalendarEventType.ticketSale => context.l10n(
      ko: '티켓',
      en: 'Tickets',
      ja: 'チケット',
    ),
    CalendarEventType.streaming => context.l10n(
      ko: '방송',
      en: 'Streaming',
      ja: '配信',
    ),
    CalendarEventType.general => context.l10n(
      ko: '일반',
      en: 'General',
      ja: '一般',
    ),
  };
}

/// EN: Semantic color mapping shared by grid markers and agenda tickets.
/// KO: 그리드 마커와 일정 티켓이 공유하는 의미 색상 매핑입니다.
Color calendarEventTypeColor(CalendarEventType type, BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return switch (type) {
    CalendarEventType.live => colors.primary,
    CalendarEventType.ticketSale => GBTColors.accent,
    CalendarEventType.release => colors.secondary,
    CalendarEventType.characterBirthday ||
    CalendarEventType.voiceActorBirthday => const Color(0xFF9D5C6A),
    CalendarEventType.streaming => GBTColors.info,
    CalendarEventType.general => colors.onSurfaceVariant,
  };
}
