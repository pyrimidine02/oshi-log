/// EN: Chronological, ruled ledger for real place visits.
/// KO: 실제 장소 방문을 위한 시간순 규칙선 원장입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/visit_entities.dart';
import 'field_visit_ledger_common.dart';
import 'field_visit_ledger_view_data.dart';

class FieldPlaceLedger extends StatelessWidget {
  const FieldPlaceLedger({
    super.key,
    required this.header,
    required this.visitsState,
    required this.placesMapState,
    required this.onRefresh,
    required this.onOpenVisit,
    required this.bottomClearance,
  });

  final Widget header;
  final AsyncValue<List<VisitEvent>> visitsState;
  final AsyncValue<Map<String, FieldVisitPlaceMetadata>> placesMapState;
  final Future<void> Function() onRefresh;
  final ValueChanged<FieldPlaceLedgerEntry> onOpenVisit;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: visitsState.when(
        loading: () => FieldLedgerMessageList(
          header: header,
          message: context.l10n(
            ko: '방문 원장을 불러오는 중입니다.',
            en: 'Loading the visit ledger.',
            ja: '訪問台帳を読み込み中です。',
          ),
          bottomClearance: bottomClearance,
          isLoading: true,
        ),
        error: (error, _) => FieldLedgerMessageList(
          header: header,
          message: error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '방문 원장을 불러오지 못했습니다.',
                  en: 'Could not load the visit ledger.',
                  ja: '訪問台帳を読み込めませんでした。',
                ),
          bottomClearance: bottomClearance,
          actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
          onAction: onRefresh,
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return FieldLedgerMessageList(
              header: header,
              message: context.l10n(
                ko: '아직 장소 방문 기록이 없습니다.\n지도에서 현장 방문을 기록해보세요.',
                en: 'No place visits yet.\nRecord a field visit from the map.',
                ja: 'まだ場所訪問はありません。\nマップから現地訪問を記録しましょう。',
              ),
              bottomClearance: bottomClearance,
              noteKey: const Key('field-ledger-empty-place-note'),
              noteIcon: Icons.route_outlined,
              noteEyebrow: context.l10n(
                ko: '첫 번째 현장 기록',
                en: 'YOUR FIRST FIELD NOTE',
                ja: '最初の現地記録',
              ),
            );
          }
          if (placesMapState.isLoading && !placesMapState.hasValue) {
            return FieldLedgerMessageList(
              header: header,
              message: context.l10n(
                ko: '장소 정보와 기록을 연결하는 중입니다.',
                en: 'Matching places to your records.',
                ja: '場所情報と記録を結び付けています。',
              ),
              bottomClearance: bottomClearance,
              isLoading: true,
            );
          }

          final data = FieldPlaceLedgerData.from(
            visits: visits,
            places: placesMapState.valueOrNull ?? const {},
          );
          return _PlaceLedgerList(
            header: header,
            data: data,
            onOpenVisit: onOpenVisit,
            bottomClearance: bottomClearance,
          );
        },
      ),
    );
  }
}

class _PlaceLedgerList extends StatelessWidget {
  const _PlaceLedgerList({
    required this.header,
    required this.data,
    required this.onOpenVisit,
    required this.bottomClearance,
  });

  final Widget header;
  final FieldPlaceLedgerData data;
  final ValueChanged<FieldPlaceLedgerEntry> onOpenVisit;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    final groups = _groupPlaceEntries(data.entries);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: FieldLedgerSummaryRule(
            facts: [
              (
                label: context.l10n(ko: '총 기록', en: 'RECORDS', ja: '総記録'),
                value: '${data.totalRecords}',
              ),
              (
                label: context.l10n(ko: '방문 장소', en: 'PLACES', ja: '訪問場所'),
                value: '${data.uniquePlaces}',
              ),
              (
                label: context.l10n(ko: '프로젝트', en: 'PROJECTS', ja: 'プロジェクト'),
                value: '${data.projectCount}',
              ),
            ],
          ),
        ),
        for (final group in groups) ...[
          SliverToBoxAdapter(child: FieldLedgerMonthRule(date: group.month)),
          SliverList.builder(
            itemCount: group.entries.length,
            itemBuilder: (context, index) {
              final entry = group.entries[index];
              return FieldPlaceLedgerRow(
                entry: entry,
                onTap: () => onOpenVisit(entry),
              );
            },
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
      ],
    );
  }
}

class FieldPlaceLedgerRow extends StatelessWidget {
  const FieldPlaceLedgerRow({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final FieldPlaceLedgerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final place = entry.place;
    final title =
        place?.name ??
        context.l10n(ko: '알 수 없는 장소', en: 'Unknown place', ja: '不明な場所');
    final projectName =
        entry.projectName ??
        context.l10n(ko: '프로젝트 미확인', en: 'Project unknown', ja: 'プロジェクト不明');
    final verificationLabel = entry.isGpsVerified
        ? context.l10n(
            ko: 'GPS 현장 인증',
            en: 'GPS field verified',
            ja: 'GPS 現地認証',
          )
        : context.l10n(
            ko: '일반 방문 기록',
            en: 'Standard visit record',
            ja: '通常の訪問記録',
          );

    return Semantics(
      button: true,
      enabled: true,
      label: fieldLedgerRowSemantics(
        title,
        projectName,
        dateLabel: fieldLedgerSemanticDate(context, entry.recordedAt),
        verificationLabel: verificationLabel,
      ),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            key: const Key('field-ledger-place-row'),
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
                          projectName,
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
                          children: [
                            Icon(
                              entry.isGpsVerified
                                  ? Icons.gps_fixed_rounded
                                  : Icons.edit_note_rounded,
                              size: 15,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: GBTSpacing.xs),
                            Expanded(
                              child: Text(
                                entry.isGpsVerified
                                    ? context.l10n(
                                        ko: 'GPS 현장 인증',
                                        en: 'GPS FIELD VERIFIED',
                                        ja: 'GPS 現地認証',
                                      )
                                    : (place?.address.isNotEmpty == true
                                          ? place!.address
                                          : entry.visit.placeId),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
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

class _PlaceMonthGroup {
  const _PlaceMonthGroup({required this.month, required this.entries});

  final DateTime? month;
  final List<FieldPlaceLedgerEntry> entries;
}

List<_PlaceMonthGroup> _groupPlaceEntries(List<FieldPlaceLedgerEntry> entries) {
  final result = <_PlaceMonthGroup>[];
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
        _PlaceMonthGroup(
          month: previous.month,
          entries: List.unmodifiable([...previous.entries, entry]),
        ),
      );
    } else {
      result.add(_PlaceMonthGroup(month: month, entries: [entry]));
    }
  }
  return List.unmodifiable(result);
}
