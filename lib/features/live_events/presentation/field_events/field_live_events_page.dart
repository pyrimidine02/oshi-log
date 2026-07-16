/// EN: Clean-sheet event desk for live schedules and attendance history.
/// KO: 라이브 일정과 방문 기록을 위한 신규 이벤트 데스크입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_profile_action.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../projects/presentation/widgets/field_project_lens.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/live_events_controller.dart';
import '../../domain/entities/live_event_entities.dart';
import 'field_event_agenda_widgets.dart';
import 'field_event_view_data.dart';

/// EN: Event root that keeps repository, filters, routes, and refresh behavior.
/// KO: 리포지토리, 필터, 라우트, 새로고침 동작을 유지하는 이벤트 루트입니다.
class FieldLiveEventsPage extends ConsumerStatefulWidget {
  const FieldLiveEventsPage({
    super.key,
    this.embedded = false,
    this.projectLens = const FieldProjectLens(),
  });

  final bool embedded;

  /// EN: Injectable only to keep the provider-bound page independently testable.
  /// KO: 프로바이더 연결 페이지를 독립적으로 테스트하기 위한 주입 지점입니다.
  final Widget projectLens;

  @override
  ConsumerState<FieldLiveEventsPage> createState() =>
      _FieldLiveEventsPageState();
}

class _FieldLiveEventsPageState extends ConsumerState<FieldLiveEventsPage> {
  FieldEventMode _mode = FieldEventMode.upcoming;

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(liveEventsListControllerProvider);
    final selectedUnits = ref.watch(selectedLiveBandIdsProvider);
    final selectedYear = ref.watch(selectedLiveEventYearProvider);
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final projectId = ref.watch(selectedProjectIdProvider);
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : (projectId ?? '');
    final unitsState = resolvedProjectKey.isEmpty
        ? const AsyncData<List<Unit>>([])
        : ref.watch(projectUnitsControllerProvider(resolvedProjectKey));
    final history = ref.watch(liveAttendanceHistoryControllerProvider);
    final attendedIds = history.items
        .where((record) => record.attended && !record.isNone)
        .map((record) => record.eventId)
        .toSet();
    final years = eventsState.maybeWhen(
      data: completedFieldEventYears,
      orElse: () => const <int>[],
    );
    final effectiveYear = years.contains(selectedYear) ? selectedYear : null;
    final avatarUrl = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.avatarUrl;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント')),
              actions: [
                GBTAppBarIconButton(
                  icon: Icons.history_rounded,
                  tooltip: context.l10n(
                    ko: '이벤트 방문 기록',
                    en: 'Event attendance history',
                    ja: 'イベント参加履歴',
                  ),
                  onPressed: () => context.goToVisitHistory(showLiveTab: true),
                ),
                GBTProfileAction(avatarUrl: avatarUrl),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                widget.embedded ? GBTSpacing.xs : GBTSpacing.md,
                GBTSpacing.pageHorizontal,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  _CompactScheduleDeskHeader(
                    projectLens: widget.projectLens,
                    mode: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                    unitsState: unitsState,
                    selectedUnitIds: selectedUnits,
                    years: years,
                    selectedYear: effectiveYear,
                    onApplyFilters: (selection) {
                      ref.read(selectedLiveBandIdsProvider.notifier).state =
                          List.unmodifiable(selection.unitIds);
                      ref.read(selectedLiveEventYearProvider.notifier).state =
                          selection.year;
                    },
                  ),
                  const SizedBox(height: GBTSpacing.md),
                ],
              ),
            ),
            ..._eventSlivers(
              context,
              eventsState,
              attendedIds: attendedIds,
              selectedUnits: selectedUnits,
              effectiveYear: effectiveYear,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: GBTSpacing.xl)),
          ],
        ),
      ),
    );
  }

  List<Widget> _eventSlivers(
    BuildContext context,
    AsyncValue<List<LiveEventSummary>> state, {
    required Set<String> attendedIds,
    required List<String> selectedUnits,
    required int? effectiveYear,
  }) {
    return state.when(
      loading: () => const [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          sliver: SliverToBoxAdapter(child: _AgendaSkeleton()),
        ),
      ],
      error: (error, _) => [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          sliver: SliverToBoxAdapter(
            child: GBTErrorState(
              message: error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '이벤트를 불러오지 못했어요',
                      en: 'Could not load events',
                      ja: 'イベントを読み込めませんでした',
                    ),
              onRetry: _refresh,
            ),
          ),
        ),
      ],
      data: (events) {
        final filtered = selectFieldEvents(
          events,
          filter: FieldEventFilter(
            mode: _mode,
            unitIds: selectedUnits,
            year: _mode == FieldEventMode.archive ? effectiveYear : null,
          ),
        );
        if (filtered.isEmpty) {
          return [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
              sliver: SliverToBoxAdapter(
                child: GBTEmptyState(
                  icon: _mode == FieldEventMode.upcoming
                      ? Icons.event_available_outlined
                      : Icons.history_rounded,
                  title: _mode == FieldEventMode.upcoming
                      ? context.l10n(
                          ko: '예정된 이벤트가 없어요',
                          en: 'No upcoming events',
                          ja: '予定されたイベントはありません',
                        )
                      : context.l10n(
                          ko: '지난 이벤트가 없어요',
                          en: 'No archived events',
                          ja: '過去のイベントはありません',
                        ),
                  subtitle: context.l10n(
                    ko: '프로젝트와 유닛 필터를 확인해보세요.',
                    en: 'Check the project and unit filters.',
                    ja: 'プロジェクトとユニットフィルターを確認してください。',
                  ),
                ),
              ),
            ),
          ];
        }

        final feature = _mode == FieldEventMode.upcoming
            ? filtered.first
            : null;
        final agenda = feature == null ? filtered : filtered.skip(1).toList();
        return [
          if (feature != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                0,
                GBTSpacing.md,
                GBTSpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: FieldEventPosterFeature(
                  event: feature,
                  onTap: () => context.goToEventDetail(feature.id),
                ),
              ),
            ),
          if (agenda.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
              sliver: SliverToBoxAdapter(
                child: _AgendaHeading(count: agenda.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
              sliver: SliverList.builder(
                itemCount: agenda.length,
                itemBuilder: (context, index) {
                  final event = agenda[index];
                  return FieldEventAgendaRow(
                    event: event,
                    attended: attendedIds.contains(event.id),
                    onTap: () => context.goToEventDetail(event.id),
                  );
                },
              ),
            ),
          ],
        ];
      },
    );
  }

  Future<void> _refresh() {
    return ref
        .read(liveEventsListControllerProvider.notifier)
        .load(forceRefresh: true);
  }
}

class _CompactScheduleDeskHeader extends StatelessWidget {
  const _CompactScheduleDeskHeader({
    required this.projectLens,
    required this.mode,
    required this.onChanged,
    required this.unitsState,
    required this.selectedUnitIds,
    required this.years,
    required this.selectedYear,
    required this.onApplyFilters,
  });

  final Widget projectLens;
  final FieldEventMode mode;
  final ValueChanged<FieldEventMode> onChanged;
  final AsyncValue<List<Unit>> unitsState;
  final List<String> selectedUnitIds;
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<_ScheduleFilterSelection> onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('field-event-schedule-desk-header'),
      height: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: GBTSpacing.touchTarget, child: projectLens),
          const SizedBox(height: GBTSpacing.xs),
          SizedBox(
            height: GBTSpacing.touchTarget,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _EventModeRail(mode: mode, onChanged: onChanged),
                ),
                const SizedBox(width: GBTSpacing.xs),
                _ScheduleFilterButton(
                  mode: mode,
                  unitsState: unitsState,
                  selectedUnitIds: selectedUnitIds,
                  years: years,
                  selectedYear: selectedYear,
                  onApply: onApplyFilters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventModeRail extends StatelessWidget {
  const _EventModeRail({required this.mode, required this.onChanged});

  final FieldEventMode mode;
  final ValueChanged<FieldEventMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: context.l10n(ko: '예정', en: 'Upcoming', ja: '予定'),
              semanticLabel: context.l10n(
                ko: '예정 이벤트',
                en: 'Upcoming events',
                ja: '予定イベント',
              ),
              selected: mode == FieldEventMode.upcoming,
              onTap: () => onChanged(FieldEventMode.upcoming),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: colors.outline),
          Expanded(
            child: _ModeButton(
              label: context.l10n(ko: '아카이브', en: 'Archive', ja: 'アーカイブ'),
              semanticLabel: context.l10n(
                ko: '지난 이벤트',
                en: 'Archived events',
                ja: '過去のイベント',
              ),
              selected: mode == FieldEventMode.archive,
              onTap: () => onChanged(FieldEventMode.archive),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: true,
      selected: selected,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primary : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleFilterButton extends StatelessWidget {
  const _ScheduleFilterButton({
    required this.mode,
    required this.unitsState,
    required this.selectedUnitIds,
    required this.years,
    required this.selectedYear,
    required this.onApply,
  });

  final FieldEventMode mode;
  final AsyncValue<List<Unit>> unitsState;
  final List<String> selectedUnitIds;
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<_ScheduleFilterSelection> onApply;

  @override
  Widget build(BuildContext context) {
    final units = unitsState.valueOrNull ?? const <Unit>[];
    final hasYear = mode == FieldEventMode.archive && selectedYear != null;
    final activeCount = selectedUnitIds.length + (hasYear ? 1 : 0);
    final unitLabel = selectedUnitIds.isEmpty
        ? context.l10n(ko: '전체 유닛', en: 'all units', ja: 'すべてのユニット')
        : context.l10n(
            ko: '유닛 ${selectedUnitIds.length}개',
            en: '${selectedUnitIds.length} units',
            ja: '${selectedUnitIds.length}ユニット',
          );
    final semanticLabel = context.l10n(
      ko: '일정 필터, $unitLabel${hasYear ? ', $selectedYear년' : ''}',
      en: 'Filter schedule, $unitLabel${hasYear ? ', year $selectedYear' : ''}',
      ja: 'スケジュールフィルター、$unitLabel${hasYear ? '、$selectedYear年' : ''}',
    );
    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      onTap: () => _openFilterSheet(context, units),
      excludeSemantics: true,
      child: Material(
        color: activeCount > 0
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
          side: BorderSide(
            color: activeCount > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openFilterSheet(context, units),
          child: SizedBox(
            width: GBTSpacing.touchTarget,
            height: GBTSpacing.touchTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (activeCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$activeCount',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context, List<Unit> units) async {
    final result = await showModalBottomSheet<_ScheduleFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ScheduleFilterSheet(
        mode: mode,
        units: units,
        years: years,
        initialUnitIds: selectedUnitIds,
        initialYear: selectedYear,
      ),
    );
    if (result != null && context.mounted) onApply(result);
  }
}

class _ScheduleFilterSelection {
  const _ScheduleFilterSelection({required this.unitIds, required this.year});

  final List<String> unitIds;
  final int? year;
}

class _ScheduleFilterSheet extends StatefulWidget {
  const _ScheduleFilterSheet({
    required this.mode,
    required this.units,
    required this.years,
    required this.initialUnitIds,
    required this.initialYear,
  });

  final FieldEventMode mode;
  final List<Unit> units;
  final List<int> years;
  final List<String> initialUnitIds;
  final int? initialYear;

  @override
  State<_ScheduleFilterSheet> createState() => _ScheduleFilterSheetState();
}

class _ScheduleFilterSheetState extends State<_ScheduleFilterSheet> {
  late List<String> _unitIds;
  late int? _year;

  @override
  void initState() {
    super.initState();
    _unitIds = List.unmodifiable(widget.initialUnitIds);
    _year = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    return SizedBox(
      height: maxHeight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.lg,
              GBTSpacing.xs,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '일정 필터',
                      en: 'Schedule filter',
                      ja: 'スケジュールフィルター',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _unitIds = const [];
                    _year = null;
                  }),
                  child: Text(context.l10n(ko: '초기화', en: 'Reset', ja: 'リセット')),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.lg,
              ),
              children: [
                if (widget.mode == FieldEventMode.archive &&
                    widget.years.isNotEmpty) ...[
                  _FilterSectionLabel(
                    label: context.l10n(ko: '연도', en: 'YEAR', ja: '年'),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Wrap(
                    spacing: GBTSpacing.sm,
                    runSpacing: GBTSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(
                          context.l10n(ko: '전체 연도', en: 'All years', ja: '全年度'),
                        ),
                        selected: _year == null,
                        onSelected: (_) => setState(() => _year = null),
                      ),
                      for (final year in widget.years)
                        ChoiceChip(
                          label: Text('$year'),
                          selected: _year == year,
                          onSelected: (_) => setState(() => _year = year),
                        ),
                    ],
                  ),
                  const SizedBox(height: GBTSpacing.lg),
                ],
                _FilterSectionLabel(
                  label: context.l10n(ko: '유닛', en: 'UNITS', ja: 'ユニット'),
                ),
                const SizedBox(height: GBTSpacing.sm),
                if (widget.units.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.lg,
                    ),
                    child: Text(
                      context.l10n(
                        ko: '이 프로젝트에는 선택할 유닛이 없어요.',
                        en: 'This project has no unit filters.',
                        ja: 'このプロジェクトにはユニットフィルターがありません。',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final unit in widget.units)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _unitIds.contains(unit.id),
                      title: Text(unit.displayName),
                      subtitle: Text(unit.code),
                      onChanged: (selected) {
                        setState(() {
                          _unitIds = selected == true
                              ? List.unmodifiable([..._unitIds, unit.id])
                              : List.unmodifiable(
                                  _unitIds.where((id) => id != unit.id),
                                );
                        });
                      },
                    ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(GBTSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _ScheduleFilterSelection(
                      unitIds: List.unmodifiable(_unitIds),
                      year: widget.mode == FieldEventMode.archive
                          ? _year
                          : null,
                    ),
                  ),
                  child: Text(
                    context.l10n(
                      ko: '필터 적용',
                      en: 'Apply filters',
                      ja: 'フィルターを適用',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _AgendaHeading extends StatelessWidget {
  const _AgendaHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n(ko: '공연 아젠다', en: 'SHOW AGENDA', ja: '公演アジェンダ'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaSkeleton extends StatelessWidget {
  const _AgendaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          const GBTShimmerContainer(height: 92, width: double.infinity),
          const SizedBox(height: GBTSpacing.sm),
        ],
      ],
    );
  }
}
