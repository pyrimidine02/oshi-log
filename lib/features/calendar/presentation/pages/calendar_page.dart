/// EN: Calendar events page — monthly view of otaku events.
/// KO: 캘린더 이벤트 페이지 — 오타쿠 이벤트 월간 보기.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/calendar_controller.dart';
import '../../domain/entities/calendar_event.dart';

/// EN: Displays calendar events for the selected month.
/// KO: 선택된 월의 캘린더 이벤트를 표시합니다.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _selectedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDate = null;
    });
  }

  void _selectDate(DateTime? date) {
    setState(() {
      // EN: Tapping the already-selected day clears the filter.
      // KO: 이미 선택된 날짜를 다시 탭하면 필터가 해제됩니다.
      _selectedDate = (date != null && _selectedDate == date) ? null : date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final query = (
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      projectKey: projectKey?.isNotEmpty == true ? projectKey : null,
    );
    final eventsAsync = ref.watch(calendarEventsProvider(query));

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '이벤트 캘린더',
          en: 'Event Calendar',
          ja: 'イベントカレンダー',
        ),
      ),
      body: Column(
        children: [
          // EN: Month navigation header
          // KO: 월 네비게이션 헤더
          _MonthHeader(
            selectedMonth: _selectedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              loading: () => _CalendarShimmer(),
              error: (_, __) => GBTEmptyState(
                message: context.l10n(
                  ko: '이벤트를 불러오지 못했어요',
                  en: 'Could not load events',
                  ja: 'イベントを読み込めませんでした',
                ),
                icon: Icons.cloud_off_outlined,
              ),
              data: (events) => events.isEmpty
                  ? GBTEmptyState(
                      message: context.l10n(
                        ko: '이번 달 이벤트가 없어요',
                        en: 'No events this month',
                        ja: '今月のイベントはありません',
                      ),
                      icon: Icons.event_busy_outlined,
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // EN: Month grid — event-type dots, today filled in
                        // primary, selected day gets a secondary ring.
                        // KO: 월간 그리드 — 이벤트 타입 도트, 오늘은 primary로
                        // 채워지고 선택일은 secondary 링으로 표시됩니다.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            GBTSpacing.pageHorizontal,
                            GBTSpacing.md,
                            GBTSpacing.pageHorizontal,
                            GBTSpacing.xs,
                          ),
                          child: _MonthGrid(
                            visibleMonth: _selectedMonth,
                            events: events,
                            selectedDate: _selectedDate,
                            onSelectDate: _selectDate,
                          ),
                        ),
                        const Divider(height: 1),
                        _EventList(
                          events: _selectedDate == null
                              ? events
                              : events
                                    .where(
                                      (event) => _isSameDate(
                                        event.date,
                                        _selectedDate!,
                                      ),
                                    )
                                    .toList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Month navigation header widget
// KO: 월 네비게이션 헤더 위젯
// ──────────────────────────────────────────────────────────────

/// EN: Header row with previous/next month navigation and the current month label.
/// KO: 이전/다음 월 네비게이션과 현재 월 라벨이 있는 헤더 행입니다.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.selectedMonth,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = DateFormat('yyyy년 MM월').format(selectedMonth);

    return Container(
      color: isDark ? GBTColors.darkSurface : GBTColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: '이전 달',
            child: IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GBTTypography.titleMedium.copyWith(
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Semantics(
            button: true,
            label: '다음 달',
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Shimmer placeholder for loading state
// KO: 로딩 상태용 쉬머 플레이스홀더
// ──────────────────────────────────────────────────────────────

/// EN: Shimmer skeleton shown while calendar events are loading.
/// KO: 캘린더 이벤트 로딩 중 표시되는 쉬머 스켈레톤입니다.
class _CalendarShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
        child: GBTShimmer(
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? GBTColors.darkSurfaceVariant
                  : GBTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Event list — groups events by date
// KO: 이벤트 목록 — 날짜별로 이벤트 그룹화
// ──────────────────────────────────────────────────────────────

/// EN: Event list grouped by date, laid out as compact cards under the
/// month grid above. Lives inside the page's outer scroll view.
/// KO: 월간 그리드 아래에 컴팩트 카드로 배치되는, 날짜별로 그룹화된
/// 이벤트 목록입니다. 페이지의 외부 스크롤 뷰 안에 위치합니다.
class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    // EN: Group events by date label using insertion-ordered map.
    // KO: 삽입 순서 맵을 사용해 날짜 라벨별로 이벤트를 그룹화합니다.
    final grouped = <String, List<CalendarEvent>>{};
    for (final event in events) {
      final key = DateFormat('MM월 dd일 (E)', 'ko').format(event.date);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final dateKeys = grouped.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final dateLabel in dateKeys)
            _DateSection(dateLabel: dateLabel, events: grouped[dateLabel]!),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Date section — label + list of event tiles
// KO: 날짜 섹션 — 라벨과 이벤트 타일 목록
// ──────────────────────────────────────────────────────────────

/// EN: A section grouping events under a single date label.
/// KO: 단일 날짜 라벨 아래 이벤트를 묶는 섹션입니다.
class _DateSection extends StatelessWidget {
  const _DateSection({required this.dateLabel, required this.events});

  final String dateLabel;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: GBTSpacing.md,
            bottom: GBTSpacing.xs,
          ),
          child: Text(
            dateLabel,
            style: GBTTypography.labelMedium.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...events.map((event) => _EventTile(event: event)),
        const SizedBox(height: GBTSpacing.xs),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Individual event tile
// KO: 개별 이벤트 타일
// ──────────────────────────────────────────────────────────────

/// EN: A single calendar event row with a colour-coded left border and icon.
/// KO: 색상으로 구분된 왼쪽 테두리와 아이콘이 있는 단일 캘린더 이벤트 행입니다.
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  IconData _typeIcon(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.characterBirthday => Icons.cake_outlined,
      CalendarEventType.voiceActorBirthday => Icons.mic_outlined,
      CalendarEventType.release => Icons.album_outlined,
      CalendarEventType.live => Icons.music_note_outlined,
      CalendarEventType.ticketSale => Icons.confirmation_number_outlined,
      CalendarEventType.streaming => Icons.live_tv_outlined,
      CalendarEventType.general => Icons.event_outlined,
    };
  }

  String _typeLabel(CalendarEventType type, BuildContext context) {
    return switch (type) {
      CalendarEventType.characterBirthday => context.l10n(
        ko: '캐릭터 생일',
        en: 'Character Birthday',
        ja: 'キャラ誕生日',
      ),
      CalendarEventType.voiceActorBirthday => context.l10n(
        ko: '성우 생일',
        en: 'VA Birthday',
        ja: '声優誕生日',
      ),
      CalendarEventType.release => context.l10n(
        ko: '발매',
        en: 'Release',
        ja: '発売',
      ),
      CalendarEventType.live => context.l10n(
        ko: '이벤트',
        en: 'Events',
        ja: 'イベント',
      ),
      CalendarEventType.ticketSale => context.l10n(
        ko: '티켓 판매',
        en: 'Ticket Sale',
        ja: 'チケット販売',
      ),
      CalendarEventType.streaming => context.l10n(
        ko: '방송',
        en: 'Streaming',
        ja: '放送',
      ),
      CalendarEventType.general => context.l10n(
        ko: '이벤트',
        en: 'Event',
        ja: 'イベント',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _eventTypeColor(event.type, isDark);
    final typeLabel = _typeLabel(event.type, context);

    return Semantics(
      label: '${event.title}, $typeLabel',
      child: Padding(
        padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? GBTColors.darkSurface : GBTColors.surface,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.xxs,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon(event.type), color: color, size: 18),
            ),
            title: Text(
              event.title,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              typeLabel,
              style: GBTTypography.bodySmall.copyWith(color: color),
            ),
            dense: true,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EN: Shared event-type color mapping (used by the grid dots and tiles)
// KO: 그리드 도트와 타일이 함께 사용하는 이벤트 타입 색상 매핑
// ──────────────────────────────────────────────────────────────

Color _eventTypeColor(CalendarEventType type, bool isDark) {
  return switch (type) {
    CalendarEventType.characterBirthday =>
      isDark ? const Color(0xFFEC4899) : const Color(0xFFDB2777),
    CalendarEventType.voiceActorBirthday =>
      isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
    CalendarEventType.release =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
    CalendarEventType.live =>
      isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
    CalendarEventType.ticketSale =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
    CalendarEventType.streaming =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
    CalendarEventType.general =>
      isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
  };
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// ──────────────────────────────────────────────────────────────
// EN: Month grid — day cells with event-type dots
// KO: 월간 그리드 — 이벤트 타입 도트가 있는 일자 셀
// ──────────────────────────────────────────────────────────────

/// EN: A 7-column month grid. Today is a filled primary circle, the
/// selected day gets a secondary ring, and each day with events shows up
/// to three small dots colored by event type.
/// KO: 7열 월간 그리드입니다. 오늘은 primary로 채워진 원, 선택일은
/// secondary 링으로 표시되며, 이벤트가 있는 날은 타입별 색상의 작은
/// 도트를 최대 3개까지 보여줍니다.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.events,
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime visibleMonth;
  final List<CalendarEvent> events;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final firstWeekday = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    ).weekday;
    final leadingEmpty = firstWeekday % 7;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final totalSlots = rows * 7;

    // EN: Group events by day-of-month for quick dot lookup.
    // KO: 도트를 빠르게 조회하기 위해 이벤트를 일자별로 그룹화합니다.
    final eventsByDay = <int, List<CalendarEvent>>{};
    for (final event in events) {
      if (event.date.year == visibleMonth.year &&
          event.date.month == visibleMonth.month) {
        eventsByDay.putIfAbsent(event.date.day, () => []).add(event);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GBTTypography.labelSmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
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
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmpty + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(
              visibleMonth.year,
              visibleMonth.month,
              dayNumber,
            );
            final dayEvents = eventsByDay[dayNumber] ?? const <CalendarEvent>[];
            final dotColors = <Color>{
              for (final event in dayEvents)
                _eventTypeColor(event.type, isDark),
            }.take(3).toList(growable: false);

            return _CalendarGridCell(
              day: dayNumber,
              isToday: _isSameDate(date, DateTime.now()),
              isSelected:
                  selectedDate != null && _isSameDate(date, selectedDate!),
              dotColors: dotColors,
              onTap: dayEvents.isEmpty ? null : () => onSelectDate(date),
            );
          },
        ),
      ],
    );
  }
}

/// EN: A single day cell in the month grid.
/// KO: 월간 그리드의 단일 일자 셀입니다.
class _CalendarGridCell extends StatelessWidget {
  const _CalendarGridCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.dotColors,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final List<Color> dotColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final secondary = isDark ? GBTColors.darkSecondary : GBTColors.secondary;
    final textColor = isToday
        ? GBTColors.textInverse
        : (isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary);

    return Semantics(
      label:
          '$day일'
          '${dotColors.isNotEmpty ? ', 이벤트 있음' : ''}'
          '${isToday ? ', 오늘' : ''}'
          '${isSelected ? ', 선택됨' : ''}',
      button: onTap != null,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // EN: Today gets a solid filled primary circle.
              // KO: 오늘은 primary로 채워진 원으로 표시됩니다.
              color: isToday ? primary : Colors.transparent,
              // EN: A selected (non-today) day gets a secondary ring.
              // KO: 선택된 날(오늘이 아닌 경우)은 secondary 링으로 표시됩니다.
              border: (isSelected && !isToday)
                  ? Border.all(color: secondary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GBTTypography.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                if (dotColors.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in dotColors)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isToday ? GBTColors.textInverse : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
