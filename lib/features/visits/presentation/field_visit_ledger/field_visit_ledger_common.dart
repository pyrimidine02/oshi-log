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

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n(ko: '여정 원장', en: 'Journey ledger', ja: '旅の台帳'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (selected == FieldVisitLedgerKind.places)
              IconButton(
                key: const Key('field-ledger-stats-action'),
                tooltip: context.l10n(
                  ko: '방문 통계',
                  en: 'Visit statistics',
                  ja: '訪問統計',
                ),
                onPressed: onOpenStats,
                icon: const Icon(Icons.query_stats_rounded, size: 20),
              ),
            FieldLedgerKindButton(
              itemKey: const Key('field-ledger-kind-places'),
              icon: Icons.place_outlined,
              label: context.l10n(ko: '장소', en: 'Places', ja: '場所'),
              semanticsLabel: context.l10n(
                ko: '장소 방문 기록 보기',
                en: 'Show place visit records',
                ja: '場所訪問記録を表示',
              ),
              selected: selected == FieldVisitLedgerKind.places,
              showLabel: !compact,
              onTap: () => onSelected(FieldVisitLedgerKind.places),
            ),
            FieldLedgerKindButton(
              itemKey: const Key('field-ledger-kind-events'),
              icon: Icons.confirmation_number_outlined,
              label: context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
              semanticsLabel: context.l10n(
                ko: '이벤트 출석 기록 보기',
                en: 'Show event attendance records',
                ja: 'イベント参加記録を表示',
              ),
              selected: selected == FieldVisitLedgerKind.events,
              showLabel: !compact,
              onTap: () => onSelected(FieldVisitLedgerKind.events),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldLedgerKindButton extends StatelessWidget {
  const FieldLedgerKindButton({
    super.key,
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: GBTSpacing.touchTarget,
            minHeight: GBTSpacing.touchTarget,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 19, color: color),
                    if (showLabel) ...[
                      const SizedBox(width: GBTSpacing.xs),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  left: GBTSpacing.xs,
                  right: GBTSpacing.xs,
                  bottom: 0,
                  child: Container(height: 3, color: colors.primary),
                ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.lg,
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
            GBTSpacing.xl,
            GBTSpacing.md,
            GBTSpacing.lg,
          ),
          child: Column(
            children: [
              if (isLoading) ...[
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: GBTSpacing.lg),
              ],
              if (noteIcon != null && noteEyebrow != null)
                _FieldLedgerEmptyNote(
                  key: noteKey,
                  icon: noteIcon!,
                  eyebrow: noteEyebrow!,
                  message: message,
                )
              else
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (actionLabel != null && onAction != null) ...[
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
    required this.message,
  });

  final IconData icon;
  final String eyebrow;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$eyebrow. $message',
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(color: colors.primary, width: 3),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 72,
                    minHeight: 112,
                  ),
                  child: ColoredBox(
                    color: colors.primaryContainer,
                    child: Icon(icon, size: 30, color: colors.primary),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(GBTSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.35,
                              ),
                        ),
                        const SizedBox(height: GBTSpacing.sm),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
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
