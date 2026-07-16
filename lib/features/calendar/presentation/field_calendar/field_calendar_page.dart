/// EN: Agenda-first clean-sheet event calendar.
/// KO: 일정 우선으로 새로 설계한 이벤트 캘린더.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/presentation/widgets/field_project_lens.dart';
import '../../application/calendar_controller.dart';
import '../../domain/entities/calendar_event.dart';
import 'calendar_view_data.dart';
import 'field_month_grid.dart';

/// EN: Calendar answers what is happening and when.
/// KO: 언제 무슨 일이 있는지 답하는 일정 화면입니다.
class FieldCalendarPage extends ConsumerStatefulWidget {
  const FieldCalendarPage({super.key});

  @override
  ConsumerState<FieldCalendarPage> createState() => _FieldCalendarPageState();
}

class _FieldCalendarPageState extends ConsumerState<FieldCalendarPage> {
  late DateTime _visibleMonth;
  DateTime? _selectedDate;
  Set<CalendarEventType> _selectedTypes = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final query = (
      year: _visibleMonth.year,
      month: _visibleMonth.month,
      projectKey: projectKey?.isNotEmpty == true ? projectKey : null,
    );
    final eventsAsync = ref.watch(calendarEventsProvider(query));
    final events = eventsAsync.valueOrNull ?? const <CalendarEvent>[];
    final gridEvents = filterCalendarGridEvents(
      events,
      selectedTypes: _selectedTypes,
    );

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '일정', en: 'Schedule', ja: '予定'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: _CalendarPageWidth(
              top: GBTSpacing.sm,
              child: FieldProjectLens(),
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
          ..._buildAgendaSlivers(context, query, eventsAsync),
          SliverToBoxAdapter(
            child: SizedBox(height: GBTSpacing.bottomNavClearanceOf(context)),
          ),
        ],
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

    final filtered = filterCalendarEvents(
      eventsAsync.valueOrNull ?? const [],
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
              hasFilters: _selectedDate != null || _selectedTypes.isNotEmpty,
              onClear: () => setState(() {
                _selectedDate = null;
                _selectedTypes = const {};
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
              itemBuilder: (context, index) => _FieldEventTicket(
                event: group.events[index],
                onTap: _eventDestination(group.events[index]) == null
                    ? null
                    : () => context.goToEventDetail(
                        _eventDestination(group.events[index])!,
                      ),
              ),
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

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = null;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
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
      children: [
        Expanded(
          child: Text(
            DateFormat.MMMEd(locale).format(date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          context.l10n(
            ko: '$eventCount개 일정',
            en: '$eventCount events',
            ja: '$eventCount件の予定',
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
    final local = event.date.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
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
                  Row(
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
                    ],
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
      label: '${event.title}, ${_eventTypeLabel(context, event.type)}',
      child: onTap == null
          ? ticket
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
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
