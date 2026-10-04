/// EN: Agenda-first clean-sheet event calendar.
/// KO: 일정 우선으로 새로 설계한 이벤트 캘린더.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_image.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_empty_state.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart'
    hide GBTEmptyState;
import 'package:oshi_log/design_system/widgets/layout/gbt_field_primitives.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/live_schedule_status_badge.dart';
import 'package:oshi_log/features/oshikatsu/live/application/calendar_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/calendar_event.dart';
import 'calendar_view_data.dart';
import 'field_month_grid.dart';
import '../../domain/event_time_policy.dart';
import '../../domain/entities/live_event_entities.dart';
import '../../application/live_events_controller.dart';
import '../field_events/field_event_agenda_widgets.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';

/// EN: Calendar answers what is happening and when.
/// KO: 언제 무슨 일이 있는지 답하는 일정 화면입니다.
class FieldCalendarPage extends ConsumerStatefulWidget {
  const FieldCalendarPage({
    super.key,
    required this.projectLens,
    this.embedded = false,
  });

  final bool embedded;

  /// EN: Injectable to avoid a direct catalog presentation dependency.
  /// KO: catalog presentation 직접 의존을 피하기 위한 주입 지점입니다.
  final Widget projectLens;

  @override
  ConsumerState<FieldCalendarPage> createState() => _FieldCalendarPageState();
}

class _FieldCalendarPageState extends ConsumerState<FieldCalendarPage> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  bool _showCalendar = false;
  String? _unitId;
  String? _region;
  Set<CalendarEventType> _selectedTypes = const {};

  @override
  void initState() {
    super.initState();
    final now = EventTimePolicy.inJst(DateTime.now());
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedProjectKeyProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _unitId = null;
          _region = null;
        });
      }
    });
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final query = (
      year: _visibleMonth.year,
      month: _visibleMonth.month,
      projectKey: projectKey?.isNotEmpty == true ? projectKey : null,
    );
    final eventsAsync = ref.watch(calendarEventsProvider(query));
    final events = eventsAsync.valueOrNull ?? const <CalendarEvent>[];
    final gridEvents = filterCalendarGridEvents(
      _refineEvents(events),
      selectedTypes: _selectedTypes,
    );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : gbtStandardAppBar(
              context,
              title: context.l10n(ko: '일정', en: 'Schedule', ja: '予定'),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(calendarEventsProvider(query));
          await ref.read(calendarEventsProvider(query).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _CalendarPageWidth(
                top: GBTSpacing.sm,
                child: widget.projectLens,
              ),
            ),
            SliverToBoxAdapter(
              child: _CalendarPageWidth(
                top: GBTSpacing.md,
                child: _MonthNavigation(
                  month: _visibleMonth,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onToday: _goToToday,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CalendarPageWidth(
                top: GBTSpacing.sm,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton.filledTonal(
                    tooltip: _showCalendar
                        ? context.l10n(
                            ko: '월별 목록',
                            en: 'Month list',
                            ja: '月の一覧',
                          )
                        : context.l10n(
                            ko: '월 캘린더',
                            en: 'Month calendar',
                            ja: '月カレンダー',
                          ),
                    icon: Icon(
                      _showCalendar
                          ? Icons.view_list_outlined
                          : Icons.calendar_month,
                    ),
                    onPressed: () => setState(() {
                      _showCalendar = !_showCalendar;
                      _selectedDate = null;
                    }),
                  ),
                ),
              ),
            ),
            if (_showCalendar)
              SliverToBoxAdapter(
                child: _CalendarPageWidth(
                  horizontalGutter: 4,
                  top: GBTSpacing.sm,
                  child: FieldMonthGrid(
                    visibleMonth: _visibleMonth,
                    events: gridEvents,
                    selectedDate: _selectedDate,
                    onSelectDate: _toggleDate,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: GBTSpacing.md),
                child: FieldCalendarEventTypeRail(
                  selectedTypes: _selectedTypes,
                  onToggle: _toggleType,
                  onClear: () => setState(() => _selectedTypes = const {}),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CalendarPageWidth(
                top: GBTSpacing.sm,
                child: _ScheduleRefinements(
                  unitId: _unitId,
                  region: _region,
                  onUnit: (value) => setState(() => _unitId = value),
                  onRegion: (value) => setState(() => _region = value),
                ),
              ),
            ),
            ..._buildAgendaSlivers(context, query, eventsAsync),
            SliverToBoxAdapter(
              child: SizedBox(height: GBTSpacing.bottomNavClearanceOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAgendaSlivers(
    BuildContext context,
    CalendarEventsQuery query,
    AsyncValue<List<CalendarEvent>> eventsAsync,
  ) {
    if (eventsAsync.isLoading && !eventsAsync.hasValue) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(GBTSpacing.xl),
            child: GBTLoading(),
          ),
        ),
      ];
    }
    if (eventsAsync.hasError && !eventsAsync.hasValue) {
      final error = eventsAsync.error;
      final message = error is Failure
          ? error.userMessage
          : context.l10n(
              ko: '일정을 불러오지 못했어요',
              en: 'Could not load the schedule',
              ja: '予定を読み込めませんでした',
            );
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: GBTErrorState(
              message: message,
              onRetry: () => ref.invalidate(calendarEventsProvider(query)),
            ),
          ),
        ),
      ];
    }

    final liveEvents =
        ref.watch(liveEventsListControllerProvider).valueOrNull ??
        const <LiveEventSummary>[];
    final liveById = {for (final live in liveEvents) live.id: live};
    final attendedIds = ref
        .watch(liveAttendanceHistoryControllerProvider)
        .items
        .where((item) => item.attended && !item.isNone)
        .map((item) => item.eventId)
        .toSet();
    final filtered = filterCalendarEvents(
      _refineEvents(eventsAsync.valueOrNull ?? const []),
      selectedDate: _selectedDate,
      selectedTypes: _selectedTypes,
    );
    final groups = groupCalendarEvents(filtered);
    if (groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _CalendarPageWidth(
            top: GBTSpacing.lg,
            child: _InlineCalendarEmpty(
              hasFilters:
                  _selectedDate != null ||
                  _selectedTypes.isNotEmpty ||
                  _unitId != null ||
                  _region != null,
              onClear: () => setState(() {
                _selectedDate = null;
                _selectedTypes = const {};
                _unitId = null;
                _region = null;
              }),
            ),
          ),
        ),
      ];
    }

    final slivers = <Widget>[];
    for (final group in groups) {
      slivers
        ..add(
          SliverToBoxAdapter(
            child: _CalendarPageWidth(
              top: GBTSpacing.lg,
              bottom: GBTSpacing.xs,
              child: _AgendaDateHeader(
                date: group.date,
                eventCount: group.events.length,
              ),
            ),
          ),
        )
        ..add(
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width <= 340 ? 16 : 20,
            ),
            sliver: SliverList.builder(
              itemCount: group.events.length,
              itemBuilder: (context, index) {
                final calendarEvent = group.events[index];
                final destination = _eventDestination(calendarEvent);
                final live = liveById[destination];
                if (live != null) {
                  return FieldEventAgendaRow(
                    event: live,
                    attended: attendedIds.contains(live.id),
                    onTap: () => context.goToEventDetail(live.id),
                  );
                }
                return _FieldEventTicket(
                  event: calendarEvent,
                  onTap: destination == null
                      ? null
                      : () => context.goToEventDetail(destination),
                );
              },
            ),
          ),
        );
    }
    return slivers;
  }

  String? _eventDestination(CalendarEvent event) {
    final id = event.relatedEntityId?.trim();
    if (event.type != CalendarEventType.live || id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  Iterable<CalendarEvent> _refineEvents(Iterable<CalendarEvent> events) {
    if (_unitId == null && _region == null) return events;
    final liveEvents =
        ref.watch(liveEventsListControllerProvider).valueOrNull ??
        const <LiveEventSummary>[];
    final liveById = {for (final live in liveEvents) live.id: live};
    return events.where((event) {
      final live = liveById[_eventDestination(event)];
      return live != null &&
          (_unitId == null || live.unitIds.contains(_unitId)) &&
          (_region == null || live.regionCodes.contains(_region));
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = null;
    });
  }

  void _goToToday() {
    final now = EventTimePolicy.inJst(DateTime.now());
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _toggleDate(DateTime date) {
    setState(() {
      _selectedDate =
          _selectedDate != null && isSameCalendarDate(_selectedDate!, date)
          ? null
          : date;
    });
  }

  void _toggleType(CalendarEventType type) {
    final next = Set<CalendarEventType>.of(_selectedTypes);
    if (!next.add(type)) next.remove(type);
    setState(() => _selectedTypes = Set.unmodifiable(next));
  }
}

class _MonthNavigation extends StatelessWidget {
  const _MonthNavigation({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: context.l10n(ko: '이전 달', en: 'Previous month', ja: '前月'),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(locale).format(month).toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: context.l10n(ko: '다음 달', en: 'Next month', ja: '翌月'),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        TextButton(
          onPressed: onToday,
          child: Text(context.l10n(ko: '오늘', en: 'Today', ja: '今日')),
        ),
      ],
    );
  }
}

/// EN: Horizontally scrollable event type filters for compact screens.
/// KO: 작은 화면에서도 가로로 스크롤되는 이벤트 유형 필터입니다.
class FieldCalendarEventTypeRail extends StatelessWidget {
  const FieldCalendarEventTypeRail({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
    required this.onClear,
  });

  final Set<CalendarEventType> selectedTypes;
  final ValueChanged<CalendarEventType> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width <= 340 ? 16 : 20,
      ),
      child: Row(
        children: [
          FilterChip(
            label: Text(context.l10n(ko: '전체', en: 'All', ja: 'すべて')),
            selected: selectedTypes.isEmpty,
            onSelected: (_) => onClear(),
          ),
          const SizedBox(width: GBTSpacing.sm),
          for (final type in CalendarEventType.values) ...[
            FilterChip(
              avatar: Icon(_eventTypeIcon(type), size: 16),
              label: Text(_eventTypeLabel(context, type)),
              selected: selectedTypes.contains(type),
              onSelected: (_) => onToggle(type),
            ),
            const SizedBox(width: GBTSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AgendaDateHeader extends StatelessWidget {
  const _AgendaDateHeader({required this.date, required this.eventCount});

  final DateTime date;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GBTFieldSectionHeader(
            eyebrow: context.l10n(ko: '아젠다', en: 'AGENDA', ja: 'AGENDA'),
            title: DateFormat.MMMEd(locale).format(date),
          ),
        ),
        GBTFieldBadge(
          label: context.l10n(
            ko: '$eventCount개 일정',
            en: '$eventCount events',
            ja: '$eventCount件の予定',
          ),
          icon: Icons.event_note_outlined,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }
}

class _FieldEventTicket extends StatelessWidget {
  const _FieldEventTicket({required this.event, this.onTap});

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = calendarEventTypeColor(event.type, context);
    final local = calendarEventDate(event);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scheduleLabel = liveScheduleStatusLabel(
      context,
      event.scheduleStatus,
    );
    final ticket = Container(
      constraints: const BoxConstraints(minHeight: 104),
      margin: const EdgeInsets.only(bottom: GBTSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(GBTSpacing.radiusMd - 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.MMM(locale).format(local).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${local.day}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  DateFormat.E(locale).format(local).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 72, color: colors.outlineVariant),
          const SizedBox(width: GBTSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: GBTSpacing.xs,
                    runSpacing: GBTSpacing.xs,
                    children: [
                      Icon(_eventTypeIcon(event.type), size: 15, color: accent),
                      const SizedBox(width: GBTSpacing.xs),
                      Text(
                        _eventTypeLabel(context, event.type).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      if (scheduleLabel != null) ...[
                        const SizedBox(width: GBTSpacing.xs),
                        LiveScheduleStatusBadge(status: event.scheduleStatus),
                      ],
                    ],
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    isAllDayCalendarEvent(event)
                        ? context.l10n(ko: '종일', en: 'All day', ja: '終日')
                        : '${DateFormat.Hm(locale).format(local)} JST',
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      event.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (event.imageUrl?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.all(GBTSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                child: GBTImage(
                  imageUrl: event.imageUrl!,
                  width: 60,
                  height: 72,
                  fit: BoxFit.cover,
                  semanticLabel: event.title,
                ),
              ),
            )
          else if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(right: GBTSpacing.sm),
              child: Icon(Icons.chevron_right_rounded, color: colors.primary),
            ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: [
        event.title,
        _eventTypeLabel(context, event.type),
        ?scheduleLabel,
      ].join(', '),
      excludeSemantics: true,
      child: onTap == null
          ? ticket
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                excludeFromSemantics: true,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                child: ticket,
              ),
            ),
    );
  }
}

class _InlineCalendarEmpty extends StatelessWidget {
  const _InlineCalendarEmpty({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GBTEmptyState(
      icon: Icons.event_busy_outlined,
      title: hasFilters
          ? context.l10n(
              ko: '선택한 조건의 일정이 없어요',
              en: 'No events match these filters',
              ja: '選択した条件の予定はありません',
            )
          : context.l10n(
              ko: '이번 달 일정이 없어요',
              en: 'No events this month',
              ja: '今月の予定はありません',
            ),
      subtitle: context.l10n(
        ko: '달력은 계속 탐색할 수 있어요.',
        en: 'You can keep exploring the calendar.',
        ja: 'カレンダーは引き続き探索できます。',
      ),
      actionLabel: hasFilters
          ? context.l10n(ko: '월 전체 보기', en: 'Show whole month', ja: '月全体を見る')
          : null,
      onAction: hasFilters ? onClear : null,
    );
  }
}

class _CalendarPageWidth extends StatelessWidget {
  const _CalendarPageWidth({
    required this.child,
    this.top = 0,
    this.bottom = 0,
    this.horizontalGutter,
  });

  final Widget child;
  final double top;
  final double bottom;
  final double? horizontalGutter;

  @override
  Widget build(BuildContext context) {
    final gutter =
        horizontalGutter ??
        (MediaQuery.sizeOf(context).width <= 340 ? 16.0 : 20.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, top, gutter, bottom),
          child: child,
        ),
      ),
    );
  }
}

IconData _eventTypeIcon(CalendarEventType type) {
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

String _eventTypeLabel(BuildContext context, CalendarEventType type) {
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

class _ScheduleRefinements extends ConsumerWidget {
  const _ScheduleRefinements({
    required this.unitId,
    required this.region,
    required this.onUnit,
    required this.onRegion,
  });
  final String? unitId;
  final String? region;
  final ValueChanged<String?> onUnit;
  final ValueChanged<String?> onRegion;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project =
        ref.watch(selectedProjectKeyProvider) ??
        ref.watch(selectedProjectIdProvider);
    final units = project == null || project.isEmpty
        ? null
        : ref.watch(projectUnitsControllerProvider(project)).valueOrNull;
    final events =
        ref.watch(liveEventsListControllerProvider).valueOrNull ??
        const <LiveEventSummary>[];
    final regions = events.expand((event) => event.regionCodes).toSet().toList()
      ..sort();
    if ((units == null || units.isEmpty) && regions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: GBTSpacing.md,
      runSpacing: GBTSpacing.sm,
      children: [
        if (units != null && units.isNotEmpty)
          DropdownButton<String>(
            isExpanded: true,
            value: units.any((unit) => unit.id == unitId) ? unitId : null,
            hint: Text(
              context.l10n(ko: '모든 밴드', en: 'All bands', ja: 'すべてのバンド'),
            ),
            onChanged: onUnit,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  context.l10n(ko: '모든 밴드', en: 'All bands', ja: 'すべてのバンド'),
                ),
              ),
              for (final unit in units)
                DropdownMenuItem(value: unit.id, child: Text(unit.displayName)),
            ],
          ),
        if (regions.isNotEmpty)
          DropdownButton<String>(
            isExpanded: true,
            value: regions.contains(region) ? region : null,
            hint: Text(
              context.l10n(ko: '모든 지역', en: 'All areas', ja: 'すべての地域'),
            ),
            onChanged: onRegion,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  context.l10n(ko: '모든 지역', en: 'All areas', ja: 'すべての地域'),
                ),
              ),
              for (final code in regions)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
          ),
      ],
    );
  }
}
