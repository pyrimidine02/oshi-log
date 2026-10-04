/// EN: Independently recoverable visit and attendance sources in one timeline.
/// KO: 방문과 참전 소스를 독립 복구할 수 있는 통합 타임라인입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/place/visits/domain/entities/visit_entities.dart';
import 'field_event_ledger.dart';
import 'field_place_ledger.dart';
import 'field_visit_ledger_view_data.dart';

class UnifiedRecordTimeline extends StatelessWidget {
  const UnifiedRecordTimeline({
    super.key,
    required this.header,
    required this.visitsState,
    required this.placesMapState,
    required this.attendanceState,
    required this.projectNames,
    required this.onRefreshPlaces,
    required this.onRefreshEvents,
    required this.onOpenVisit,
    required this.onOpenEvent,
    required this.bottomClearance,
    this.onLoadMoreEvents,
  });

  final Widget header;
  final AsyncValue<List<VisitEvent>> visitsState;
  final AsyncValue<Map<String, FieldVisitPlaceMetadata>> placesMapState;
  final LiveAttendanceHistoryViewState attendanceState;
  final Map<String, String> projectNames;
  final Future<void> Function() onRefreshPlaces;
  final Future<void> Function() onRefreshEvents;
  final Future<void> Function()? onLoadMoreEvents;
  final ValueChanged<FieldPlaceLedgerEntry> onOpenVisit;
  final ValueChanged<LiveAttendanceHistoryRecord> onOpenEvent;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    final visits = FieldPlaceLedgerData.from(
      visits: visitsState.valueOrNull ?? const [],
      places: placesMapState.valueOrNull ?? const {},
    );
    final events = FieldEventLedgerData.from(
      records: attendanceState.items,
      projectNames: projectNames,
    );
    final records = composeUnifiedRecords(
      visits: visits.entries,
      events: events.entries,
    );
    final loading = visitsState.isLoading || attendanceState.isInitialLoading;
    final failed = visitsState.hasError || attendanceState.failure != null;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([onRefreshPlaces(), onRefreshEvents()]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: header),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(GBTSpacing.md),
              child: Text(
                context.l10n(
                  ko: '전체 장소 방문 · 선택한 프로젝트의 참전 기록\n불러온 기록을 최신순으로 표시합니다.',
                  en: 'All place visits · attendances in the selected project\nLoaded records, newest first.',
                  ja: 'すべての場所訪問・選択中プロジェクトの参加記録\n読み込み済みの記録を新しい順に表示します。',
                ),
              ),
            ),
          ),
          if (visitsState.hasError)
            _retry(
              context,
              'timeline-visits-retry',
              context.l10n(
                ko: '방문 기록을 불러오지 못했어요',
                en: 'Could not load visits',
                ja: '訪問記録を読み込めませんでした',
              ),
              onRefreshPlaces,
            ),
          if (placesMapState.hasError)
            _retry(
              context,
              'timeline-places-retry',
              context.l10n(
                ko: '장소 이름을 불러오지 못했어요. 기록은 유지됩니다.',
                en: 'Place names unavailable. Your records are retained.',
                ja: '場所名を読み込めません。記録は保持されています。',
              ),
              onRefreshPlaces,
            ),
          if (attendanceState.failure != null)
            _retry(
              context,
              'timeline-events-retry',
              context.l10n(
                ko: '참전 기록을 불러오지 못했어요',
                en: 'Could not load attendances',
                ja: '参加記録を読み込めませんでした',
              ),
              attendanceState.items.isNotEmpty && attendanceState.hasNext
                  ? onLoadMoreEvents ?? onRefreshEvents
                  : onRefreshEvents,
            ),
          if (loading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (records.isEmpty && !loading && !failed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(GBTSpacing.lg),
                child: Text(
                  context.l10n(
                    ko: '아직 방문·참전 기록이 없어요.',
                    en: 'No visit or attendance records yet.',
                    ja: '訪問・参加記録はまだありません。',
                  ),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return KeyedSubtree(
                key: ValueKey(record.id),
                child: record.visit != null
                    ? FieldPlaceLedgerRow(
                        entry: record.visit!,
                        onTap: () => onOpenVisit(record.visit!),
                      )
                    : FieldEventLedgerRow(
                        entry: record.event!,
                        onTap: () => onOpenEvent(record.event!.record),
                      ),
              );
            },
          ),
          if (attendanceState.isLoadingMore)
            const SliverToBoxAdapter(child: LinearProgressIndicator())
          else if (attendanceState.hasNext && onLoadMoreEvents != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(GBTSpacing.md),
                child: OutlinedButton(
                  key: const Key('timeline-load-more'),
                  onPressed: onLoadMoreEvents,
                  child: Text(
                    context.l10n(
                      ko: '참전 기록 더 보기',
                      en: 'More attendances',
                      ja: '参加記録をもっと見る',
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
        ],
      ),
    );
  }

  Widget _retry(
    BuildContext context,
    String key,
    String message,
    VoidCallback retry,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            TextButton(
              key: Key(key),
              onPressed: retry,
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ],
        ),
      ),
    );
  }
}
