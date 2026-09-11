/// EN: Chronological, ruled ledger for real event attendance.
/// KO: 실제 이벤트 출석을 위한 시간순 규칙선 원장입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/layout/gbt_field_primitives.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../live_events/domain/entities/live_event_entities.dart';
import 'field_visit_ledger_common.dart';
import 'field_visit_ledger_view_data.dart';

class FieldEventLedger extends StatelessWidget {
  const FieldEventLedger({
    super.key,
    required this.header,
    required this.attendanceState,
    required this.projectNames,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenEvent,
    required this.bottomClearance,
    this.onOpenEvents,
  });

  final Widget header;
  final LiveAttendanceHistoryViewState attendanceState;
  final Map<String, String> projectNames;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final ValueChanged<LiveAttendanceHistoryRecord> onOpenEvent;
  final double bottomClearance;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    if (attendanceState.isInitialLoading) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: FieldLedgerMessageList(
          header: header,
          message: context.l10n(
            ko: '이벤트 출석 원장을 불러오는 중입니다.',
            en: 'Loading the attendance ledger.',
            ja: 'イベント参加台帳を読み込み中です。',
          ),
          bottomClearance: bottomClearance,
          isLoading: true,
        ),
      );
    }

    if (attendanceState.failure != null && attendanceState.items.isEmpty) {
      final failure = attendanceState.failure;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: FieldLedgerMessageList(
          header: header,
          message: failure is Failure
              ? failure.userMessage
              : context.l10n(
                  ko: '이벤트 출석 원장을 불러오지 못했습니다.',
                  en: 'Could not load the attendance ledger.',
                  ja: 'イベント参加台帳を読み込めませんでした。',
                ),
          bottomClearance: bottomClearance,
          actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
          onAction: onRefresh,
        ),
      );
    }

    if (attendanceState.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: FieldLedgerMessageList(
          header: header,
          message: context.l10n(
            ko: '이벤트 일정을 확인하고 상세에서 출석을 기록하면 라이브의 추억이 이곳에 쏓여요.',
            en: 'Open an event and record attendance to keep your live memories here.',
            ja: 'イベント詳細で参加を記録すると、ライブの思い出がここに残ります。',
          ),
          bottomClearance: bottomClearance,
          noteKey: const Key('field-ledger-empty-event-note'),
          noteIcon: Icons.confirmation_number_outlined,
          noteEyebrow: context.l10n(
            ko: '라이브의 첫 기록',
            en: 'FIRST LIVE ENTRY',
            ja: 'ライブの最初の記録',
          ),
          noteTitle: context.l10n(
            ko: '첫 이벤트 출석을 기록해보세요',
            en: 'Record your first event attendance',
            ja: '最初のイベント参加を記録しましょう',
          ),
          actionLabel: onOpenEvents == null
              ? null
              : context.l10n(
                  ko: '이벤트 일정 보기',
                  en: 'View event schedule',
                  ja: 'イベント予定を見る',
                ),
          onAction: onOpenEvents,
        ),
      );
    }

    final data = FieldEventLedgerData.from(
      records: attendanceState.items,
      projectNames: projectNames,
    );
    final groups = _groupEventEntries(data.entries);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 240 &&
              attendanceState.hasNext &&
              !attendanceState.isLoadingMore &&
              attendanceState.failure == null) {
            onLoadMore();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header),
            SliverToBoxAdapter(
              child: FieldLedgerSummaryRule(
                facts: [
                  (
                    label: context.l10n(ko: '총 출석', en: 'ATTENDED', ja: '総参加'),
                    value: '${data.totalRecords}',
                  ),
                  (
                    label: context.l10n(
                      ko: '인증 완료',
                      en: 'VERIFIED',
                      ja: '認証済み',
                    ),
                    value: '${data.verifiedRecords}',
                  ),
                  (
                    label: context.l10n(ko: '범위', en: 'SCOPE', ja: '範囲'),
                    value: context.l10n(ko: '현재', en: 'CURRENT', ja: '現在'),
                  ),
                ],
              ),
            ),
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: FieldLedgerMonthRule(date: group.month),
              ),
              SliverList.builder(
                itemCount: group.entries.length,
                itemBuilder: (context, index) {
                  final entry = group.entries[index];
                  return FieldEventLedgerRow(
                    entry: entry,
                    onTap: () => onOpenEvent(entry.record),
                  );
                },
              ),
            ],
            if (attendanceState.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(GBTSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (attendanceState.failure != null)
              SliverToBoxAdapter(child: _LoadMoreFailure(onRetry: onLoadMore)),
            SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
          ],
        ),
      ),
    );
  }
}

class FieldEventLedgerRow extends StatelessWidget {
  const FieldEventLedgerRow({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final FieldEventLedgerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final record = entry.record;
    final status = LiveAttendanceStatus.normalize(record.status);
    final statusLabel = switch (status) {
      LiveAttendanceStatus.verified => context.l10n(
        ko: '인증 완료',
        en: 'VERIFIED',
        ja: '認証済み',
      ),
      LiveAttendanceStatus.declared => context.l10n(
        ko: '출석 기록',
        en: 'DECLARED',
        ja: '参加記録',
      ),
      _ => context.l10n(ko: '기록', en: 'RECORDED', ja: '記録'),
    };
    final statusColor = status == LiveAttendanceStatus.verified
        ? colors.secondary
        : colors.primary;
    final title = record.titleFallback;
    final verificationMethod =
        record.verificationMethod?.trim().isNotEmpty == true
        ? context.l10n(
            ko: '인증 방식 ${record.verificationMethod}',
            en: 'Verification method ${record.verificationMethod}',
            ja: '認証方法 ${record.verificationMethod}',
          )
        : null;

    return Semantics(
      button: true,
      enabled: true,
      onTap: onTap,
      label: fieldLedgerRowSemantics(
        title,
        entry.projectName,
        dateLabel: fieldLedgerSemanticDate(context, entry.recordedAt),
        verificationLabel: statusLabel,
        verificationMethod: verificationMethod,
      ),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Container(
            key: const Key('field-ledger-event-row'),
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.md2,
              GBTSpacing.sm,
              GBTSpacing.md2,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLedgerDateRail(date: entry.recordedAt),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: GBTSpacing.md),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          entry.projectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GBTFieldBadge(
                              label: statusLabel,
                              icon: status == LiveAttendanceStatus.verified
                                  ? Icons.verified_outlined
                                  : Icons.event_available_outlined,
                              color: statusColor,
                            ),
                            if (record.verificationMethod?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(width: GBTSpacing.xs),
                              Expanded(
                                child: Text(
                                  record.verificationMethod!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreFailure extends StatelessWidget {
  const _LoadMoreFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.md2,
          GBTSpacing.md,
          GBTSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sync_problem_rounded, size: 18, color: colors.error),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '추가 기록을 불러오지 못했습니다.',
                      en: 'Could not load more records.',
                      ja: '追加の記録を読み込めませんでした。',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('field-ledger-load-more-retry'),
                onPressed: onRetry,
                child: Text(
                  context.l10n(ko: '다시 불러오기', en: 'Retry', ja: '再読み込み'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMonthGroup {
  const _EventMonthGroup({required this.month, required this.entries});

  final DateTime? month;
  final List<FieldEventLedgerEntry> entries;
}

List<_EventMonthGroup> _groupEventEntries(List<FieldEventLedgerEntry> entries) {
  final result = <_EventMonthGroup>[];
  for (final entry in entries) {
    final date = entry.recordedAt?.toLocal();
    final month = date == null ? null : DateTime(date.year, date.month);
    final isSameMonth =
        result.isNotEmpty &&
        result.last.month?.year == month?.year &&
        result.last.month?.month == month?.month;
    if (isSameMonth) {
      final previous = result.removeLast();
      result.add(
        _EventMonthGroup(
          month: previous.month,
          entries: List.unmodifiable([...previous.entries, entry]),
        ),
      );
    } else {
      result.add(_EventMonthGroup(month: month, entries: [entry]));
    }
  }
  return List.unmodifiable(result);
}
