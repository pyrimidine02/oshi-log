/// EN: Editorial archive sections for the clean-sheet zukan experience.
/// KO: 클린시트 도감 경험을 위한 에디토리얼 아카이브 섹션입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../domain/entities/zukan_collection.dart';
import 'field_zukan_archive_view_data.dart';

/// EN: Compact scrollable masthead with aggregate collection progress.
/// KO: 전체 수집 진행을 담은 간결한 스크롤형 마스트헤드입니다.
class FieldArchiveMasthead extends StatelessWidget {
  const FieldArchiveMasthead({super.key, required this.data});

  final FieldZukanArchiveData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      header: true,
      label: context.l10n(
        ko: '여행 표본 아카이브, ${data.collectedStampCount}개 수집, 전체 ${data.totalStampCount}개',
        en: 'Travel specimen archive, ${data.collectedStampCount} of ${data.totalStampCount} collected',
        ja: '旅の標本アーカイブ、${data.totalStampCount}件中${data.collectedStampCount}件を収集',
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: colors.outlineVariant),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: 'ARCHIVE / PILGRIMAGE SPECIMENS',
                en: 'ARCHIVE / PILGRIMAGE SPECIMENS',
                ja: 'ARCHIVE / PILGRIMAGE SPECIMENS',
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.15,
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '여행 표본 아카이브',
                en: 'TRAVEL SPECIMEN ARCHIVE',
                ja: '旅の標本アーカイブ',
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Wrap(
              spacing: GBTSpacing.lg,
              runSpacing: GBTSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ArchiveMetric(
                  value:
                      '${data.collectedStampCount} / ${data.totalStampCount}',
                  label: context.l10n(ko: '수집 표본', en: 'COLLECTED', ja: '収集済み'),
                ),
                _ArchiveMetric(
                  value:
                      '${data.completedCollectionCount} / ${data.collections.length}',
                  label: context.l10n(
                    ko: '완료 보관함',
                    en: 'COMPLETE FILES',
                    ja: '完了ファイル',
                  ),
                  complete: data.completedCollectionCount > 0,
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: data.progressRatio,
                color: data.progressRatio >= 1
                    ? colors.secondary
                    : colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveMetric extends StatelessWidget {
  const _ArchiveMetric({
    required this.value,
    required this.label,
    this.complete = false,
  });

  final String value;
  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: complete ? colors.secondary : colors.onSurface,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: GBTSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// EN: A single large specimen plate for the current active collection.
/// KO: 현재 진행 컬렉션 한 개를 크게 보여주는 표본 플레이트입니다.
class FieldFeaturedSpecimen extends StatelessWidget {
  const FieldFeaturedSpecimen({
    super.key,
    required this.collection,
    required this.archiveNumber,
    required this.onTap,
  });

  final ZukanCollectionSummary collection;
  final int archiveNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progressLabel = _progressLabel(context, collection);
    final statusLabel = _statusLabel(context, collection);
    return Semantics(
      button: true,
      label: '${collection.title}, $progressLabel, $statusLabel',
      child: Material(
        key: ValueKey('field-zukan-featured-${collection.id}'),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: collection.coverImageUrl?.trim().isNotEmpty == true
                    ? GBTImage(
                        imageUrl: collection.coverImageUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: collection.title,
                      )
                    : _SpecimenPlate(number: archiveNumber),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colors.primary, width: 4),
                  ),
                ),
                padding: const EdgeInsets.all(GBTSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n(
                                  ko: '진행 중인 표본',
                                  en: 'ACTIVE SPECIMEN',
                                  ja: '進行中の標本',
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                              ),
                              const SizedBox(height: GBTSpacing.xs),
                              Text(
                                collection.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: GBTSpacing.sm),
                        Icon(
                          Icons.arrow_outward_rounded,
                          key: const ValueKey(
                            'field-zukan-featured-action-icon',
                          ),
                          color: colors.primary,
                          size: GBTSpacing.iconMd,
                        ),
                      ],
                    ),
                    if (collection.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      Text(
                        collection.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: GBTSpacing.md),
                    _SpecimenProgress(
                      collection: collection,
                      statusLabel: statusLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecimenPlate extends StatelessWidget {
  const _SpecimenPlate({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.primaryContainer),
      child: CustomPaint(
        painter: _ArchiveRulePainter(
          lineColor: colors.primary.withValues(alpha: 0.18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.lg),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'SPECIMEN / ${number.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_outlined,
                  color: colors.primary,
                  size: 52,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: colors.primary.withValues(alpha: 0.28),
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveRulePainter extends CustomPainter {
  const _ArchiveRulePainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArchiveRulePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _SpecimenProgress extends StatelessWidget {
  const _SpecimenProgress({
    required this.collection,
    required this.statusLabel,
  });

  final ZukanCollectionSummary collection;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progressColor = collection.isCompleted
        ? colors.secondary
        : colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: GBTSpacing.md,
          runSpacing: GBTSpacing.xs,
          children: [
            Text(
              '${collection.stampedCount} / ${collection.totalCount}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs2),
        ClipRRect(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: collection.progressRatio.clamp(0, 1).toDouble(),
            color: progressColor,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

/// EN: Rule-led heading for the collection index below the featured plate.
/// KO: 대표 표본 아래 컬렉션 색인을 위한 규칙선형 제목입니다.
class FieldArchiveIndexHeading extends StatelessWidget {
  const FieldArchiveIndexHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: colors.outline),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          context.l10n(
            ko: 'SPECIMEN INDEX / 보관함 색인',
            en: 'SPECIMEN INDEX / FILES',
            ja: 'SPECIMEN INDEX / 保管庫索引',
          ),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// EN: A ruled archive index row, replacing the legacy two-column card grid.
/// KO: 구형 2열 카드 그리드를 대체하는 규칙선형 아카이브 색인 행입니다.
class FieldArchiveIndexRow extends StatelessWidget {
  const FieldArchiveIndexRow({
    super.key,
    required this.collection,
    required this.archiveNumber,
    required this.onTap,
  });

  final ZukanCollectionSummary collection;
  final int archiveNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusLabel = _statusLabel(context, collection);
    final progressColor = collection.isCompleted
        ? colors.secondary
        : colors.primary;
    return Semantics(
      button: true,
      label:
          '${collection.title}, ${_progressLabel(context, collection)}, $statusLabel',
      child: Material(
        key: ValueKey('field-zukan-row-${collection.id}'),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    archiveNumber.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Container(
                  width: 3,
                  height: 40,
                  color: progressColor.withValues(
                    alpha: collection.stampedCount == 0 ? 0.32 : 1,
                  ),
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: GBTSpacing.xs),
                      Wrap(
                        spacing: GBTSpacing.xs2,
                        runSpacing: GBTSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (collection.isCompleted)
                            Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey(
                                'field-zukan-complete-${collection.id}',
                              ),
                              size: GBTSpacing.iconXs,
                              color: colors.secondary,
                            ),
                          Text(
                            '${collection.stampedCount} / ${collection.totalCount}  ·  $statusLabel',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: collection.isCompleted
                                      ? colors.secondary
                                      : colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.primary,
                  size: GBTSpacing.iconMd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _progressLabel(BuildContext context, ZukanCollectionSummary collection) {
  return context.l10n(
    ko: '전체 ${collection.totalCount}개 중 ${collection.stampedCount}개 수집',
    en: '${collection.stampedCount} of ${collection.totalCount} collected',
    ja: '${collection.totalCount}件中${collection.stampedCount}件を収集',
  );
}

String _statusLabel(BuildContext context, ZukanCollectionSummary collection) {
  if (collection.isCompleted) {
    return context.l10n(ko: '완료', en: 'COMPLETE', ja: '完了');
  }
  if (collection.stampedCount > 0) {
    return context.l10n(ko: '수집 중', en: 'IN PROGRESS', ja: '収集中');
  }
  return context.l10n(ko: '미수집', en: 'UNFILED', ja: '未収集');
}
