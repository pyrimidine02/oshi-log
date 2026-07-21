/// EN: Shared ruled-ledger primitives for place and event records.
/// KO: 장소와 이벤트 기록이 공유하는 규칙선 원장 구성요소입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';

enum FieldVisitLedgerKind { places, events }

class FieldLedgerKindSwitch extends StatelessWidget {
  const FieldLedgerKindSwitch({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onOpenStats,
  });

  final FieldVisitLedgerKind selected;
  final ValueChanged<FieldVisitLedgerKind> onSelected;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final isPlaces = selected == FieldVisitLedgerKind.places;
    final title = isPlaces
        ? context.l10n(ko: '장소 기록', en: 'Place records', ja: '場所記録')
        : context.l10n(ko: '이벤트 출석', en: 'Event attendance', ja: 'イベント参加');
    final titleBlock = Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAVEL LOGBOOK',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
    final statsAction = TextButton.icon(
      key: const Key('field-ledger-stats-action'),
      onPressed: onOpenStats,
      icon: const Icon(Icons.query_stats_rounded, size: 20),
      label: Text(context.l10n(ko: '방문 통계', en: 'Visit stats', ja: '訪問統計')),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.sm,
          GBTSpacing.md,
          GBTSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              titleBlock,
              if (isPlaces)
                Align(alignment: Alignment.centerLeft, child: statsAction),
            ] else
              Row(
                children: [
                  Expanded(child: titleBlock),
                  if (isPlaces) statsAction,
                ],
              ),
            const SizedBox(height: GBTSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: GBTSpacing.touchTarget,
              ),
              child: SegmentedButton<FieldVisitLedgerKind>(
                key: const Key('field-ledger-kind-switch'),
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                    value: FieldVisitLedgerKind.places,
                    label: Semantics(
                      key: const Key('field-ledger-kind-places'),
                      label: context.l10n(
                        ko: '장소 방문 기록 보기',
                        en: 'Show place visit records',
                        ja: '場所訪問記録を表示',
                      ),
                      excludeSemantics: true,
                      child: Text(
                        context.l10n(
                          ko: '장소 방문',
                          en: 'Place visits',
                          ja: '場所訪問',
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: FieldVisitLedgerKind.events,
                    label: Semantics(
                      key: const Key('field-ledger-kind-events'),
                      label: context.l10n(
                        ko: '이벤트 출석 기록 보기',
                        en: 'Show event attendance records',
                        ja: 'イベント参加記録を表示',
                      ),
                      excludeSemantics: true,
                      child: Text(
                        context.l10n(
                          ko: '이벤트 출석',
                          en: 'Event attendance',
                          ja: 'イベント参加',
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) => onSelected(selection.first),
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(0, GBTSpacing.touchTarget),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldLedgerSummaryRule extends StatelessWidget {
  const FieldLedgerSummaryRule({super.key, required this.facts});

  final List<({String label, String value})> facts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < facts.length; index++)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                    vertical: GBTSpacing.md2,
                  ),
                  decoration: BoxDecoration(
                    border: index == facts.length - 1
                        ? null
                        : Border(
                            right: BorderSide(color: colors.outlineVariant),
                          ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        facts[index].value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.xxs),
                      Text(
                        facts[index].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FieldLedgerMonthRule extends StatelessWidget {
  const FieldLedgerMonthRule({super.key, required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = date == null
        ? context.l10n(ko: '날짜 미상', en: 'DATE UNKNOWN', ja: '日付不明')
        : '${date!.year} / ${date!.month.toString().padLeft(2, '0')}';
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.md,
          GBTSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class FieldLedgerDateRail extends StatelessWidget {
  const FieldLedgerDateRail({super.key, required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localDate = date?.toLocal();
    return SizedBox(
      width: 66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localDate?.day.toString().padLeft(2, '0') ?? '--',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            localDate == null
                ? context.l10n(ko: '미상', en: 'N/A', ja: '不明')
                : '${localDate.month.toString().padLeft(2, '0')}.${localDate.year.toString().substring(2)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class FieldLedgerMessageList extends StatelessWidget {
  const FieldLedgerMessageList({
    super.key,
    required this.header,
    required this.message,
    required this.bottomClearance,
    this.isLoading = false,
    this.actionLabel,
    this.onAction,
    this.noteKey,
    this.noteIcon,
    this.noteEyebrow,
    this.noteTitle,
  });

  final Widget header;
  final String message;
  final double bottomClearance;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? noteKey;
  final IconData? noteIcon;
  final String? noteEyebrow;
  final String? noteTitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomClearance),
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.md,
            GBTSpacing.md,
            GBTSpacing.lg,
          ),
          child: Column(
            children: [
              if (isLoading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: GBTSpacing.lg),
              ],
              if (noteIcon != null && noteEyebrow != null && noteTitle != null)
                _FieldLedgerEmptyNote(
                  key: noteKey,
                  icon: noteIcon!,
                  eyebrow: noteEyebrow!,
                  title: noteTitle!,
                  message: message,
                  actionLabel: actionLabel,
                  onAction: onAction,
                )
              else
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (noteTitle == null &&
                  actionLabel != null &&
                  onAction != null) ...[
                const SizedBox(height: GBTSpacing.md),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// EN: Intentional ruled empty state that reads like an unused field-note row.
/// KO: 아직 쓰이지 않은 현장 노트 행처럼 보이는 규칙선 기반 빈 상태입니다.
class _FieldLedgerEmptyNote extends StatelessWidget {
  const _FieldLedgerEmptyNote({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.lg2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: GBTSpacing.touchTarget,
                    height: GBTSpacing.touchTarget,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: colors.primary),
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.md),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: GBTSpacing.md),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(icon, size: 20),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String fieldLedgerRowSemantics(
  String title,
  String projectName, {
  String? dateLabel,
  String? verificationLabel,
  String? verificationMethod,
}) {
  return [
    title,
    projectName,
    dateLabel,
    verificationLabel,
    verificationMethod,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
}

String fieldLedgerSemanticDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return context.l10n(ko: '날짜 미상', en: 'Date unknown', ja: '日付不明');
  }
  final localDate = date.toLocal();
  return context.l10n(
    ko: '${localDate.year}년 ${localDate.month}월 ${localDate.day}일',
    en: '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}',
    ja: '${localDate.year}年${localDate.month}月${localDate.day}日',
  );
}
