/// EN: Editorial field-note sections for a zukan specimen detail.
/// KO: 도감 표본 상세를 위한 에디토리얼 필드 노트 섹션입니다.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_stamp_badge.dart';
import '../../domain/entities/zukan_collection.dart';

/// EN: Scrollable specimen file with a ruled station index.
/// KO: 규칙선형 방문 지점 색인을 포함한 스크롤 가능한 표본 파일입니다.
class FieldZukanDetailBody extends StatelessWidget {
  const FieldZukanDetailBody({super.key, required this.collection});

  final ZukanCollection collection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
      ),
      children: [
        _SpecimenHeader(collection: collection),
        if (collection.isCompleted &&
            collection.rewardDescription?.trim().isNotEmpty == true) ...[
          const SizedBox(height: GBTSpacing.lg),
          _RewardFieldNote(description: collection.rewardDescription!),
        ],
        const SizedBox(height: GBTSpacing.lg),
        const _StationIndexHeading(),
        for (final (index, stamp) in collection.stamps.indexed)
          _StationIndexRow(stamp: stamp, stationNumber: index + 1),
      ],
    );
  }
}

/// EN: Specimen identity and progress without a floating dashboard card.
/// KO: 떠 있는 대시보드 카드 없이 표본의 정체성과 진행률을 보여줍니다.
class _SpecimenHeader extends StatelessWidget {
  const _SpecimenHeader({required this.collection});

  final ZukanCollection collection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final specimenNumber = collection.sortOrder > 0 ? collection.sortOrder : 1;
    final statusLabel = _collectionStatusLabel(context, collection);
    final progressColor = collection.isCompleted
        ? colors.secondary
        : colors.primary;
    final progressLabel = context.l10n(
      ko: '전체 ${collection.totalCount}개 중 ${collection.stampedCount}개 수집',
      en: '${collection.stampedCount} of ${collection.totalCount} collected',
      ja: '${collection.totalCount}件中${collection.stampedCount}件を収集',
    );

    return Semantics(
      container: true,
      header: true,
      label: context.l10n(
        ko: '도감 표본 파일, ${collection.title}, $progressLabel, $statusLabel',
        en: 'Zukan specimen file, ${collection.title}, $progressLabel, $statusLabel',
        ja: '図鑑標本ファイル、${collection.title}、$progressLabel、$statusLabel',
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              key: const ValueKey('field-zukan-detail-blue-rule'),
              color: colors.primary,
              child: const SizedBox(height: 4),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GBTSpacing.md,
              runSpacing: GBTSpacing.xs,
              children: [
                Text(
                  'SPECIMEN FILE / ${specimenNumber.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.05,
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
            const SizedBox(height: GBTSpacing.sm),
            Text(
              collection.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
            if (collection.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: GBTSpacing.sm),
              Text(
                collection.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: GBTSpacing.lg),
            Wrap(
              spacing: GBTSpacing.lg,
              runSpacing: GBTSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  '${collection.stampedCount} / ${collection.totalCount}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
                  child: Text(
                    context.l10n(
                      ko: '수집된 방문 표본',
                      en: 'VISITED SPECIMENS',
                      ja: '収集済み訪問標本',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.65,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              child: LinearProgressIndicator(
                key: const ValueKey('field-zukan-detail-progress'),
                minHeight: 5,
                value: collection.progressRatio.clamp(0, 1).toDouble(),
                color: progressColor,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: Completion reward presented as a margin note between blue rules.
/// KO: 완료 보상을 파란 규칙선 사이의 여백 메모처럼 표현합니다.
class _RewardFieldNote extends StatelessWidget {
  const _RewardFieldNote({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n(
        ko: '완주 기록, $description',
        en: 'Completion note, $description',
        ja: 'コンプリート記録、$description',
      ),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.primary),
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(
                  ko: 'COMPLETION NOTE / 완주 기록',
                  en: 'COMPLETION NOTE / REWARD',
                  ja: 'COMPLETION NOTE / コンプリート記録',
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Rule-led heading for the ordered station ledger.
/// KO: 순서형 방문 지점 원장을 위한 규칙선 제목입니다.
class _StationIndexHeading extends StatelessWidget {
  const _StationIndexHeading();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
        child: Text(
          context.l10n(
            ko: 'STATION INDEX / 방문 지점',
            en: 'STATION INDEX / VISIT LOG',
            ja: 'STATION INDEX / 訪問スポット',
          ),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.95,
          ),
        ),
      ),
    );
  }
}

/// EN: One ruled station record; only collected records open place details.
/// KO: 하나의 규칙선형 지점 기록이며, 수집된 기록만 장소 상세를 엽니다.
class _StationIndexRow extends StatelessWidget {
  const _StationIndexRow({required this.stamp, required this.stationNumber});

  final ZukanStamp stamp;
  final int stationNumber;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isStamped = stamp.isStamped;
    final statusLabel = _stampStatusLabel(context, stamp);
    final dateLabel = _formatStampDate(stamp.visitedAt);
    final detailParts = [
      statusLabel,
      if (dateLabel.isNotEmpty) dateLabel,
      if (stamp.episodeHint?.trim().isNotEmpty == true) stamp.episodeHint!,
    ];
    final semanticsLabel = [
      stationNumber.toString().padLeft(2, '0'),
      stamp.placeName,
      ...detailParts,
    ].join(', ');
    final VoidCallback? openPlace = isStamped
        ? () => context.goToPlaceDetail(stamp.placeId)
        : null;

    return Semantics(
      key: ValueKey('field-zukan-stamp-row-${stamp.id}'),
      container: true,
      button: isStamped,
      enabled: isStamped,
      label: semanticsLabel,
      onTap: openPlace,
      hint: isStamped
          ? context.l10n(
              ko: '탭하면 장소 상세 보기',
              en: 'Tap for place detail',
              ja: 'タップして場所の詳細を表示',
            )
          : context.l10n(
              ko: '방문 전에는 잠금 상태입니다',
              en: 'Locked until visited',
              ja: '訪問するまでロック中です',
            ),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openPlace,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      stationNumber.toString().padLeft(2, '0'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 52,
                    color: isStamped ? colors.primary : colors.outlineVariant,
                  ),
                  const SizedBox(width: GBTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stamp.placeName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (stamp.episodeHint?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: GBTSpacing.xs),
                          Text(
                            stamp.episodeHint!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ],
                        const SizedBox(height: GBTSpacing.xs2),
                        Wrap(
                          spacing: GBTSpacing.sm,
                          runSpacing: GBTSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              statusLabel,
                              key: ValueKey(
                                'field-zukan-stamp-status-${stamp.id}',
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: isStamped
                                        ? colors.secondary
                                        : colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.55,
                                  ),
                            ),
                            if (dateLabel.isNotEmpty)
                              Text(
                                dateLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
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
                  _StationStampMark(stamp: stamp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Compact stamp mark that keeps the row action visible at narrow widths.
/// KO: 좁은 화면에서도 행의 행동 가능 여부를 드러내는 작은 스탬프 표식입니다.
class _StationStampMark extends StatelessWidget {
  const _StationStampMark({required this.stamp});

  final ZukanStamp stamp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isStamped = stamp.isStamped;
    return GBTStampBadge(
      size: 42,
      unlocked: isStamped,
      color: colors.secondary,
      animateOnUnlock: false,
      child: stamp.placeImageUrl?.trim().isNotEmpty == true && isStamped
          ? ClipOval(
              child: GBTImage(
                imageUrl: stamp.placeImageUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                semanticLabel: stamp.placeName,
              ),
            )
          : Icon(
              isStamped
                  ? Icons.arrow_outward_rounded
                  : Icons.lock_outline_rounded,
              size: GBTSpacing.iconSm,
              color: isStamped ? colors.secondary : colors.onSurfaceVariant,
            ),
    );
  }
}

String _collectionStatusLabel(
  BuildContext context,
  ZukanCollection collection,
) {
  if (collection.isCompleted) {
    return context.l10n(ko: '완료', en: 'COMPLETE', ja: '完了');
  }
  if (collection.stampedCount > 0) {
    return context.l10n(ko: '수집 중', en: 'IN PROGRESS', ja: '収集中');
  }
  return context.l10n(ko: '수집 전', en: 'NOT STARTED', ja: '未着手');
}

String _stampStatusLabel(BuildContext context, ZukanStamp stamp) {
  return stamp.isStamped
      ? context.l10n(ko: '방문 완료', en: 'VISITED', ja: '訪問済み')
      : context.l10n(ko: '미방문', en: 'NOT VISITED', ja: '未訪問');
}

String _formatStampDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('yyyy.MM.dd').format(date.toLocal());
}
