/// EN: Live events list page with calendar and list view
/// KO: 캘린더 및 리스트 뷰를 포함한 라이브 이벤트 목록 페이지
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/cards/gbt_event_card.dart';
import '../../../../core/widgets/common/themed_builder.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_profile_action.dart';
import '../../application/live_events_controller.dart';
import '../../domain/entities/live_event_entities.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../settings/application/settings_controller.dart';

/// EN: Live events page widget
/// KO: 라이브 이벤트 페이지 위젯
class LiveEventsPage extends ConsumerStatefulWidget {
  const LiveEventsPage({super.key, this.embedded = false});

  /// EN: Omits the standalone app bar inside the Explore workspace.
  /// KO: 탐방 워크스페이스 내부에서는 독립 앱 바를 생략합니다.
  final bool embedded;

  @override
  ConsumerState<LiveEventsPage> createState() => _LiveEventsPageState();
}

class _LiveEventsPageState extends ConsumerState<LiveEventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventsState = ref.watch(liveEventsListControllerProvider);
    final selectedBandIds = ref.watch(selectedLiveBandIdsProvider);
    final selectedYear = ref.watch(selectedLiveEventYearProvider);
    final availableYears = eventsState.maybeWhen(
      data: _sortedCompletedEventYears,
      orElse: () => const <int>[],
    );
    final effectiveSelectedYear =
        selectedYear != null && availableYears.contains(selectedYear)
        ? selectedYear
        : null;
    final showYearFilter = _tabController.index == 1;
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final projectId = ref.watch(selectedProjectIdProvider);
    final currentNavIndex = ref.watch(currentNavIndexProvider);
    final isTabActive = currentNavIndex == NavIndex.explore;
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : (projectId ?? '');
    final unitsState = isTabActive && resolvedProjectKey.isNotEmpty
        ? ref.watch(projectUnitsControllerProvider(resolvedProjectKey))
        : const AsyncValue<List<Unit>>.data([]);
    final attendanceHistoryState = ref.watch(
      liveAttendanceHistoryControllerProvider,
    );
    final attendedEventIds = attendanceHistoryState.items
        .where((record) => record.attended && !record.isNone)
        .map((record) => record.eventId)
        .toSet();
    final avatarUrl = ref
        .watch(userProfileControllerProvider)
        .valueOrNull
        ?.avatarUrl;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _EventList(
                isUpcoming: true,
                state: eventsState,
                attendedEventIds: attendedEventIds,
                selectedYear: null,
                selectedBandIds: selectedBandIds,
                topPadding: 44.0,
                onRefresh: () => ref
                    .read(liveEventsListControllerProvider.notifier)
                    .load(forceRefresh: true),
                onRetry: () => ref
                    .read(liveEventsListControllerProvider.notifier)
                    .load(forceRefresh: true),
              ),
              _EventList(
                isUpcoming: false,
                state: eventsState,
                attendedEventIds: attendedEventIds,
                selectedYear: effectiveSelectedYear,
                selectedBandIds: selectedBandIds,
                topPadding: showYearFilter ? 88.0 : 44.0,
                onRefresh: () => ref
                    .read(liveEventsListControllerProvider.notifier)
                    .load(forceRefresh: true),
                onRetry: () => ref
                    .read(liveEventsListControllerProvider.notifier)
                    .load(forceRefresh: true),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: (isDark ? GBTColors.darkSurface : GBTColors.surface)
                      .withValues(alpha: 0.8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // EN: Single chip filter row: project → unit → upcoming/done.
                      // KO: 단일 칩 필터 행: 프로젝트 → 유닛 → 예정/완료.
                      _LiveChipFilterRow(
                        tabController: _tabController,
                        unitsState: unitsState,
                        selectedBandIds: selectedBandIds,
                        isDark: isDark,
                      ),
                      if (showYearFilter)
                        _YearChipFilterRow(
                          years: availableYears,
                          selectedYear: effectiveSelectedYear,
                          onSelectAll: () {
                            ref
                                    .read(
                                      selectedLiveEventYearProvider.notifier,
                                    )
                                    .state =
                                null;
                          },
                          onSelectYear: (year) {
                            ref
                                    .read(
                                      selectedLiveEventYearProvider.notifier,
                                    )
                                    .state =
                                year;
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'live-calendar-fab',
        onPressed: () => _showCalendar(
          eventsState,
          selectedYear: showYearFilter ? effectiveSelectedYear : null,
        ),
        tooltip: context.l10n(
          ko: '캘린더로 이벤트 보기',
          en: 'View events in calendar',
          ja: 'カレンダーでライブイベントを見る',
        ),
        child: const Icon(Icons.calendar_month_outlined),
      ),
    );
  }

  void _showCalendar(
    AsyncValue<List<LiveEventSummary>> state, {
    int? selectedYear,
  }) {
    final loadedEvents = state.maybeWhen(
      data: (items) => items,
      orElse: () => null,
    );
    final events = selectedYear == null || loadedEvents == null
        ? loadedEvents
        : loadedEvents
              .where(
                (event) => event.showStartTime.toLocal().year == selectedYear,
              )
              .toList();
    if (events == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '이벤트 정보를 불러오는 중입니다',
              en: 'Loading event information',
              ja: 'ライブ情報を読み込み中です',
            ),
          ),
        ),
      );
      return;
    }
    if (events.isEmpty && selectedYear != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '$selectedYear년 이벤트가 없습니다',
              en: 'No events in $selectedYear',
              ja: '$selectedYear年のライブイベントはありません',
            ),
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final earliest = events.isEmpty
        ? now.subtract(const Duration(days: 365))
        : events
              .map((event) => event.showStartTime.toLocal())
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = events.isEmpty
        ? now.add(const Duration(days: 365))
        : events
              .map((event) => event.showStartTime.toLocal())
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final firstDate = earliest.isBefore(now)
        ? earliest
        : now.subtract(const Duration(days: 365));
    final lastDate = latest.isAfter(now)
        ? latest
        : now.add(const Duration(days: 365));

    final eventDateKeys = events
        .map((event) => _dateKey(event.showStartTime.toLocal()))
        .toSet();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var selectedDate = DateTime(now.year, now.month, now.day);
        var visibleMonth = DateTime(selectedDate.year, selectedDate.month);
        final minMonth = DateTime(firstDate.year, firstDate.month);
        final maxMonth = DateTime(lastDate.year, lastDate.month);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered =
                events
                    .where(
                      (event) => _isSameDate(
                        event.showStartTime.toLocal(),
                        selectedDate,
                      ),
                    )
                    .toList()
                  ..sort((a, b) => a.showStartTime.compareTo(b.showStartTime));
            final dateLabel = DateFormat('yyyy.MM.dd').format(selectedDate);

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n(
                              ko: '캘린더',
                              en: 'Calendar',
                              ja: 'カレンダー',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            context.l10n(
                              ko: '$dateLabel · ${filtered.length}개',
                              en: '$dateLabel · ${filtered.length}',
                              ja: '$dateLabel ・ ${filtered.length}件',
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.md,
                      ),
                      child: _EventCalendar(
                        selectedDate: selectedDate,
                        visibleMonth: visibleMonth,
                        minMonth: minMonth,
                        maxMonth: maxMonth,
                        eventDateKeys: eventDateKeys,
                        onSelectDate: (date) {
                          setModalState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            visibleMonth = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                            );
                          });
                        },
                        onChangeMonth: (month) {
                          setModalState(() {
                            visibleMonth = month;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: GBTEmptyState(
                                icon: Icons.event_busy,
                                message: context.l10n(
                                  ko: '해당 날짜에 이벤트가 없습니다',
                                  en: 'No events on this date',
                                  ja: 'この日にライブイベントはありません',
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: GBTSpacing.paddingPage,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final event = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: GBTSpacing.md,
                                  ),
                                  child: GBTEventCard(
                                    eventId: event.id,
                                    title: event.title,
                                    subtitle: event.statusLabel,
                                    meta: event.metaLabel,
                                    date: event.dateLabel,
                                    dDayLabel: event.dDayLabel,
                                    posterUrl: event.bannerUrl,
                                    isLive:
                                        event.statusLabel.toLowerCase() ==
                                        'live',
                                    isUpcoming: event.isUpcoming,
                                    onTap: () =>
                                        context.goToEventDetail(event.id),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// EN: Event list widget
/// KO: 이벤트 리스트 위젯
class _EventList extends StatelessWidget {
  const _EventList({
    required this.isUpcoming,
    required this.state,
    required this.attendedEventIds,
    required this.selectedYear,
    required this.selectedBandIds,
    required this.topPadding,
    required this.onRefresh,
    required this.onRetry,
  });

  final bool isUpcoming;
  final AsyncValue<List<LiveEventSummary>> state;
  final Set<String> attendedEventIds;
  final int? selectedYear;
  // EN: Unit/band IDs to filter client-side — empty means show all.
  // KO: 클라이언트 사이드 필터링용 유닛/밴드 ID 목록 — 비어있으면 전체 표시.
  final List<String> selectedBandIds;
  final double topPadding;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: state.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            0,
            topPadding + GBTSpacing.sm,
            0,
            GBTSpacing.sm,
          ),
          children: [
            GBTListSkeleton(
              itemCount: 4,
              padding: EdgeInsets.zero,
              spacing: GBTSpacing.sm,
              itemBuilder: (_) => const GBTEventCardSkeleton(),
            ),
          ],
        ),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '이벤트를 불러오지 못했어요',
                  en: 'Failed to load events',
                  ja: 'ライブイベントを読み込めませんでした',
                );
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              topPadding + GBTSpacing.lg,
              GBTSpacing.pageHorizontal,
              GBTSpacing.lg,
            ),
            children: [GBTErrorState(message: message, onRetry: onRetry)],
          );
        },
        data: (events) {
          final filtered =
              events.where((event) {
                if (event.isUpcoming != isUpcoming) return false;
                if (selectedYear != null &&
                    event.showStartTime.toLocal().year != selectedYear) {
                  return false;
                }
                // EN: Client-side unit filter — check if event belongs to any
                //     selected band. Empty = show all.
                // KO: 클라이언트 사이드 유닛 필터 — 선택된 밴드에 해당하는 이벤트만
                //     표시. 비어있으면 전체 표시.
                if (selectedBandIds.isNotEmpty &&
                    !event.unitIds.any(selectedBandIds.contains)) {
                  return false;
                }
                return true;
              }).toList()..sort((a, b) {
                final first = a.showStartTime;
                final second = b.showStartTime;
                return isUpcoming
                    ? first.compareTo(second)
                    : second.compareTo(first);
              });

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                topPadding + GBTSpacing.lg,
                GBTSpacing.pageHorizontal,
                GBTSpacing.lg,
              ),
              children: [
                GBTEmptyState(
                  icon: isUpcoming ? Icons.event_available : Icons.event_busy,
                  message: isUpcoming
                      ? context.l10n(
                          ko: selectedYear != null
                              ? '$selectedYear년 예정된 이벤트가 없습니다'
                              : '예정된 이벤트가 없습니다',
                          en: selectedYear != null
                              ? 'No upcoming events in $selectedYear'
                              : 'No upcoming events',
                          ja: selectedYear != null
                              ? '$selectedYear年の予定イベントはありません'
                              : '予定されたイベントがありません',
                        )
                      : context.l10n(
                          ko: selectedYear != null
                              ? '$selectedYear년 완료된 이벤트가 없습니다'
                              : '완료된 이벤트가 없습니다',
                          en: selectedYear != null
                              ? 'No finished events in $selectedYear'
                              : 'No finished events',
                          ja: selectedYear != null
                              ? '$selectedYear年の終了イベントはありません'
                              : '終了したイベントがありません',
                        ),
                ),
              ],
            );
          }

          // EN: In upcoming tab, feature only one event:
          // EN: the nearest upcoming event among today's events.
          // EN: Fallback to the nearest SCHEDULED-status event if there is no today event.
          // KO: 예정 탭에서는 피처드 카드를 1개만 노출합니다:
          // KO: 당일 이벤트 중 현재 시각 기준 가장 가까운 예정 이벤트를 강조합니다.
          // KO: 당일 이벤트가 없으면 SCHEDULED 상태 이벤트 중 가장 가까운 항목을 대체 강조합니다.
          String? featuredEventId;
          if (isUpcoming) {
            final now = DateTime.now();
            final todayCandidates =
                filtered.where((event) {
                  final local = event.showStartTime.toLocal();
                  return local.year == now.year &&
                      local.month == now.month &&
                      local.day == now.day;
                }).toList()..sort((a, b) {
                  final deltaA = a.showStartTime
                      .toLocal()
                      .difference(now)
                      .abs();
                  final deltaB = b.showStartTime
                      .toLocal()
                      .difference(now)
                      .abs();
                  return deltaA.compareTo(deltaB);
                });
            if (todayCandidates.isNotEmpty) {
              featuredEventId = todayCandidates.first.id;
            } else {
              final todayDate = DateTime(now.year, now.month, now.day);
              final scheduledCandidates =
                  filtered
                      .where(
                        (event) =>
                            event.statusLabel.toLowerCase() == 'scheduled',
                      )
                      .toList()
                    ..sort((a, b) {
                      final localA = a.showStartTime.toLocal();
                      final localB = b.showStartTime.toLocal();
                      final dateA = DateTime(
                        localA.year,
                        localA.month,
                        localA.day,
                      );
                      final dateB = DateTime(
                        localB.year,
                        localB.month,
                        localB.day,
                      );
                      final dayDiffA = dateA.difference(todayDate).inDays.abs();
                      final dayDiffB = dateB.difference(todayDate).inDays.abs();
                      if (dayDiffA != dayDiffB) {
                        return dayDiffA.compareTo(dayDiffB);
                      }
                      final timeDiffA = localA.difference(now).abs();
                      final timeDiffB = localB.difference(now).abs();
                      return timeDiffA.compareTo(timeDiffB);
                    });
              if (scheduledCandidates.isNotEmpty) {
                featuredEventId = scheduledCandidates.first.id;
              }
            }
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              GBTSpacing.md,
              topPadding + GBTSpacing.sm,
              GBTSpacing.md,
              GBTSpacing.xl,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final event = filtered[index];
              final isLive = event.statusLabel.toLowerCase() == 'live';
              final isFeatured = isUpcoming && featuredEventId == event.id;
              final isAttended = attendedEventIds.contains(event.id);
              final timeStr = DateFormat(
                'HH:mm',
              ).format(event.showStartTime.toLocal());

              // EN: Featured card is rendered only for selected single event.
              // KO: 피처드 카드는 선정된 단일 이벤트에만 렌더링합니다.
              if (isFeatured) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: GBTSpacing.md),
                  child: GBTFeaturedEventCard(
                    eventId: event.id,
                    title: event.title,
                    subtitle: event.statusLabel,
                    meta: '$timeStr · ${event.metaLabel}',
                    date: event.dateLabel,
                    posterUrl: event.bannerUrl,
                    isLive: isLive,
                    onTap: () => context.goToEventDetail(event.id),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
                child: GBTEventCard(
                  eventId: event.id,
                  title: event.title,
                  subtitle: event.statusLabel,
                  meta: '$timeStr · ${event.metaLabel}',
                  date: event.dateLabel,
                  dDayLabel: event.dDayLabel,
                  posterUrl: event.bannerUrl,
                  isLive: isLive,
                  isUpcoming: event.isUpcoming,
                  highlightBorderColor: isAttended
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? GBTColors.darkSecondary
                            : GBTColors.secondary)
                      : null,
                  onTap: () => context.goToEventDetail(event.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ========================================
// EN: Live chip filter row — project → unit → upcoming/done (single row)
// KO: 라이브 칩 필터 행 — 프로젝트 → 유닛 → 예정/완료 (단일 행)
// ========================================

/// EN: Single scrollable chip row: project pill → unit pill → 예정/완료 toggle chips.
/// KO: 단일 스크롤 칩 행: 프로젝트 필 → 유닛 필 → 예정/완료 토글 칩.
class _LiveChipFilterRow extends StatelessWidget {
  const _LiveChipFilterRow({
    required this.tabController,
    required this.unitsState,
    required this.selectedBandIds,
    required this.isDark,
  });

  final TabController tabController;
  final AsyncValue<List<Unit>> unitsState;
  final List<String> selectedBandIds;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final units = unitsState.maybeWhen(
          data: (u) => u,
          orElse: () => const <Unit>[],
        );
        final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.xs2,
            ),
            children: [
              // EN: Project selector pill.
              // KO: 프로젝트 선택기 필 칩.
              _LiveProjectChip(isDark: isDark),
              if (units.isNotEmpty) ...[
                const SizedBox(width: GBTSpacing.xs2),
                // EN: Unit selector pill.
                // KO: 유닛 선택기 필 칩.
                _LiveUnitChip(
                  isDark: isDark,
                  units: units,
                  selectedBandIds: selectedBandIds,
                ),
              ],
              const SizedBox(width: 6),
              // EN: Thin divider separating pills from tab chips.
              // KO: 필 칩과 탭 칩을 분리하는 얇은 세로 구분선.
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: borderColor,
              ),
              const SizedBox(width: 6),
              // EN: 예정 (upcoming) tab chip.
              // KO: 예정 탭 칩.
              _BandChip(
                label: context.l10n(ko: '예정', en: 'Upcoming', ja: '予定'),
                isSelected: tabController.index == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  tabController.animateTo(0);
                },
              ),
              const SizedBox(width: GBTSpacing.xs2),
              // EN: 완료 (done) tab chip.
              // KO: 완료 탭 칩.
              _BandChip(
                label: context.l10n(ko: '완료', en: 'Done', ja: '完了'),
                isSelected: tabController.index == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  tabController.animateTo(1);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========================================
// EN: Live unit selector chip
// KO: 라이브 유닛 선택 칩
// ========================================

/// EN: Solid primary pill chip showing the selected unit(s); opens a multi-select
/// bottom sheet picker on tap — same visual style as _LiveProjectChip.
/// KO: 선택된 유닛을 표시하는 solid primary 필 칩. 탭 시 멀티셀렉트 바텀시트를 엽니다.
/// _LiveProjectChip과 동일한 시각 스타일을 사용합니다.
class _LiveUnitChip extends StatelessWidget {
  const _LiveUnitChip({
    required this.isDark,
    required this.units,
    required this.selectedBandIds,
  });

  final bool isDark;
  final List<Unit> units;
  final List<String> selectedBandIds;

  String _label(BuildContext context) {
    if (selectedBandIds.isEmpty) {
      return context.l10n(ko: '전체', en: 'All', ja: '全体');
    }
    if (selectedBandIds.length == 1) {
      final unit = units.cast<Unit?>().firstWhere(
        (u) => u?.id == selectedBandIds.first,
        orElse: () => null,
      );
      if (unit != null) {
        return unit.displayName.isNotEmpty ? unit.displayName : unit.code;
      }
    }
    return context.l10n(
      ko: '유닛 ${selectedBandIds.length}개',
      en: '${selectedBandIds.length} units',
      ja: '${selectedBandIds.length}ユニット',
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final textColor = isDark ? GBTColors.darkBackground : Colors.white;

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _LiveUnitPickerSheet(units: units),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(context),
              style: GBTTypography.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: textColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Live project selector chip
// KO: 라이브 프로젝트 선택 칩
// ========================================

/// EN: Solid primary pill chip that shows the currently selected project name
/// and opens a bottom sheet picker on tap.
/// KO: 현재 선택된 프로젝트 이름을 표시하고 탭 시 바텀시트 선택기를 여는
/// solid primary 필 칩.
class _LiveProjectChip extends ConsumerWidget {
  const _LiveProjectChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    final label = projectsState.maybeWhen(
      data: (projects) {
        if (projects.isEmpty) {
          return context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
        }
        final selected = projects.cast<Project?>().firstWhere(
          (p) =>
              p?.code == selection.projectKey || p?.id == selection.projectKey,
          orElse: () => projects.first,
        );
        return selected?.name ??
            context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト');
      },
      orElse: () => context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
    );

    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final textColor = isDark ? GBTColors.darkBackground : Colors.white;

    return GestureDetector(
      onTap: () => _showLiveProjectPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GBTTypography.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: textColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveProjectPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _LiveProjectPickerSheet(),
    );
  }
}

// ============================================================
// EN: Live project picker sheet — selects the active project
// KO: 라이브 프로젝트 선택 시트 — 활성 프로젝트를 선택합니다
// ============================================================

class _LiveProjectPickerSheet extends ConsumerWidget {
  const _LiveProjectPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsControllerProvider);
    final selection = ref.watch(projectSelectionControllerProvider);

    final title = context.l10n(
      ko: '프로젝트 선택',
      en: 'Select project',
      ja: 'プロジェクト選択',
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: projectsState.when(
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveSheetTitleRow(title: title),
              const SizedBox(height: GBTSpacing.md),
              GBTLoading(
                message: context.l10n(
                  ko: '프로젝트를 불러오는 중...',
                  en: 'Loading projects...',
                  ja: 'プロジェクトを読み込み中...',
                ),
              ),
              const SizedBox(height: GBTSpacing.md),
            ],
          ),
          error: (error, _) {
            final message = error is Failure
                ? error.userMessage
                : context.l10n(
                    ko: '프로젝트를 불러오지 못했어요',
                    en: 'Failed to load projects',
                    ja: 'プロジェクトを読み込めませんでした',
                  );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LiveSheetTitleRow(title: title),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  message,
                  style: GBTTypography.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextButton(
                  onPressed: () => ref
                      .read(projectsControllerProvider.notifier)
                      .load(forceRefresh: true),
                  child: Text(
                    context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                  ),
                ),
              ],
            );
          },
          data: (projects) {
            if (projects.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LiveSheetTitleRow(title: title),
                  const SizedBox(height: GBTSpacing.lg),
                  Text(
                    context.l10n(
                      ko: '등록된 프로젝트가 없습니다',
                      en: 'No projects available',
                      ja: '登録されたプロジェクトがありません',
                    ),
                    style: GBTTypography.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GBTSpacing.md),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LiveSheetTitleRow(title: title),
                const SizedBox(height: GBTSpacing.md),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final key = project.code.isNotEmpty
                          ? project.code
                          : project.id;
                      final isSelected =
                          selection.projectKey == key ||
                          selection.projectKey == project.id;
                      final primaryColor = Theme.of(
                        context,
                      ).colorScheme.primary;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryColor : null,
                        ),
                        title: Text(project.name),
                        onTap: () {
                          ref
                              .read(projectSelectionControllerProvider.notifier)
                              .selectProject(key, projectId: project.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// EN: Live unit picker sheet — multi-select unit filter
// KO: 라이브 유닛 선택 시트 — 멀티셀렉트 유닛 필터
// ============================================================

class _LiveUnitPickerSheet extends ConsumerWidget {
  const _LiveUnitPickerSheet({required this.units});

  final List<Unit> units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedLiveBandIdsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveSheetTitleRow(
              title: context.l10n(ko: '유닛 선택', en: 'Select unit', ja: 'ユニット選択'),
            ),
            const SizedBox(height: GBTSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selectedIds.isEmpty
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selectedIds.isEmpty ? primaryColor : null,
              ),
              title: Text(context.l10n(ko: '전체', en: 'All', ja: '全体')),
              onTap: () =>
                  ref.read(selectedLiveBandIdsProvider.notifier).state = [],
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final label = unit.displayName.isNotEmpty
                      ? unit.displayName
                      : unit.code;
                  final isSelected = selectedIds.contains(unit.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? primaryColor : null,
                    ),
                    title: Text(label),
                    onTap: () {
                      final current = ref.read(selectedLiveBandIdsProvider);
                      ref
                          .read(selectedLiveBandIdsProvider.notifier)
                          .state = isSelected
                          ? current.where((id) => id != unit.id).toList()
                          : [...current, unit.id];
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EN: Sheet title row — title + close button for live bottom sheets
// KO: 시트 제목 행 — 라이브 바텀시트에 공통으로 사용하는 제목 + 닫기 버튼
// ============================================================

class _LiveSheetTitleRow extends StatelessWidget {
  const _LiveSheetTitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GBTTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: GBTSpacing.minTouchTarget,
            minHeight: GBTSpacing.minTouchTarget,
          ),
          tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
        ),
      ],
    );
  }
}

// ========================================
// EN: Inline band chip filter row (legacy — kept for _YearChipFilterRow sibling)
// KO: 인라인 밴드 칩 필터 행 (레거시 — _YearChipFilterRow 형제를 위해 유지)
// ========================================

/// EN: Horizontal row for selecting event year.
/// KO: 이벤트 연도 선택을 위한 가로 필터 행입니다.
class _YearChipFilterRow extends StatelessWidget {
  const _YearChipFilterRow({
    required this.years,
    required this.selectedYear,
    required this.onSelectAll,
    required this.onSelectYear,
  });

  final List<int> years;
  final int? selectedYear;
  final VoidCallback onSelectAll;
  final ValueChanged<int> onSelectYear;

  @override
  Widget build(BuildContext context) {
    if (years.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.none,
          GBTSpacing.md,
          GBTSpacing.xs2,
        ),
        children: [
          _BandChip(
            label: context.l10n(ko: '전체 연도', en: 'All years', ja: '全年度'),
            isSelected: selectedYear == null,
            onTap: onSelectAll,
          ),
          ...years.map((year) {
            return Padding(
              padding: const EdgeInsets.only(left: GBTSpacing.xs2),
              child: _BandChip(
                label: context.l10n(ko: '$year년', en: '$year', ja: '$year年'),
                isSelected: selectedYear == year,
                onTap: () => onSelectYear(year),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// EN: Single band filter chip with animated selected state.
/// KO: 애니메이션 선택 상태를 가진 단일 밴드 필터 칩.
class _BandChip extends StatelessWidget {
  const _BandChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final bgColor = isSelected
        ? primaryColor.withValues(alpha: isDark ? 0.20 : 0.10)
        : (isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant);
    final textColor = isSelected
        ? primaryColor
        : (isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary);
    final borderColor = isSelected ? primaryColor : Colors.transparent;

    return Semantics(
      label:
          '$label ${context.l10n(ko: "밴드", en: "band", ja: "バンド")}${isSelected ? ', ${context.l10n(ko: "선택됨", en: "selected", ja: "選択済み")}' : ''}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: GBTAnimations.fast,
          curve: GBTAnimations.defaultCurve,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: GBTAnimations.fast,
              curve: GBTAnimations.defaultCurve,
              style: GBTTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<int> _sortedCompletedEventYears(List<LiveEventSummary> events) {
  final years =
      events
          .where((event) => !event.isUpcoming)
          .map((event) => event.showStartTime.toLocal().year)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  return years;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _EventCalendar extends StatelessWidget {
  const _EventCalendar({
    required this.selectedDate,
    required this.visibleMonth,
    required this.minMonth,
    required this.maxMonth,
    required this.eventDateKeys,
    required this.onSelectDate,
    required this.onChangeMonth,
  });

  final DateTime selectedDate;
  final DateTime visibleMonth;
  final DateTime minMonth;
  final DateTime maxMonth;
  final Set<String> eventDateKeys;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTime> onChangeMonth;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(localeTag).format(visibleMonth);
    final canGoPrev = !_isSameMonth(visibleMonth, minMonth);
    final canGoNext = !_isSameMonth(visibleMonth, maxMonth);
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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: context.l10n(
                ko: '이전 달',
                en: 'Previous month',
                ja: '前の月',
              ),
              onPressed: canGoPrev
                  ? () {
                      final prevMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month - 1,
                      );
                      onChangeMonth(prevMonth);
                    }
                  : null,
            ),
            Text(monthLabel, style: Theme.of(context).textTheme.titleSmall),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: context.l10n(ko: '다음 달', en: 'Next month', ja: '次の月'),
              onPressed: canGoNext
                  ? () {
                      final nextMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month + 1,
                      );
                      onChangeMonth(nextMonth);
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _WeekdayLabel(context.l10n(ko: '일', en: 'S', ja: '日')),
            _WeekdayLabel(context.l10n(ko: '월', en: 'M', ja: '月')),
            _WeekdayLabel(context.l10n(ko: '화', en: 'T', ja: '火')),
            _WeekdayLabel(context.l10n(ko: '수', en: 'W', ja: '水')),
            _WeekdayLabel(context.l10n(ko: '목', en: 'T', ja: '木')),
            _WeekdayLabel(context.l10n(ko: '금', en: 'F', ja: '金')),
            _WeekdayLabel(context.l10n(ko: '토', en: 'S', ja: '土')),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalSlots,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
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
            final isSelected = _isSameDate(date, selectedDate);
            final hasEvent = eventDateKeys.contains(_dateKey(date));
            return _CalendarDayCell(
              date: date,
              isSelected: isSelected,
              hasEvent: hasEvent,
              onTap: () => onSelectDate(date),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected ? colorScheme.primary : Colors.transparent;
    final textColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final dotColor = isSelected ? colorScheme.onPrimary : colorScheme.primary;

    // EN: Format date for accessibility label
    // KO: 접근성 라벨을 위한 날짜 포맷
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.MMMd(localeTag).format(date);
    final eventLabel = hasEvent
        ? ', ${context.l10n(ko: "이벤트 있음", en: "has event", ja: "イベントあり")}'
        : '';
    final selectedLabel = isSelected
        ? ', ${context.l10n(ko: "선택됨", en: "selected", ja: "選択済み")}'
        : '';

    return Semantics(
      label: '$dateLabel$eventLabel$selectedLabel',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasEvent)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}
