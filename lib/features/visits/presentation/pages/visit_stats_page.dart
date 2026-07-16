/// EN: Visit statistics presented as a field ledger, not a dashboard.
/// KO: 대시보드가 아닌 필드 장부 형식으로 표현하는 방문 통계 화면입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../places/domain/entities/place_entities.dart';
import '../../application/visits_controller.dart';
import '../../domain/entities/visit_entities.dart';

/// EN: Shows accumulated visit records as a readable travel ledger.
/// KO: 누적 방문 기록을 읽기 쉬운 여행 장부로 표시합니다.
class VisitStatsPage extends ConsumerStatefulWidget {
  const VisitStatsPage({super.key});

  @override
  ConsumerState<VisitStatsPage> createState() => _VisitStatsPageState();
}

class _VisitStatsPageState extends ConsumerState<VisitStatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userVisitsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(userVisitsControllerProvider);
    final placesMapState = ref.watch(visitPlacesMapProvider);
    final rankingState = ref.watch(userRankingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '방문 통계', en: 'Visit stats', ja: '訪問統計'),
        actions: [
          GBTAppBarIconButton(
            icon: Icons.history_rounded,
            tooltip: context.l10n(ko: '방문 기록', en: 'Visit history', ja: '訪問履歴'),
            onPressed: () => context.goToVisitHistory(),
          ),
        ],
      ),
      body: visitsState.when(
        loading: () => Center(
          child: GBTLoading(
            message: context.l10n(
              ko: '통계를 불러오는 중...',
              en: 'Loading stats...',
              ja: '統計を読み込み中...',
            ),
          ),
        ),
        error: (error, _) => _StatsEmptyState(
          message: error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '통계를 불러오지 못했습니다.',
                  en: 'Could not load stats.',
                  ja: '統計を読み込めませんでした。',
                ),
          onRetry: () => ref
              .read(userVisitsControllerProvider.notifier)
              .load(forceRefresh: true),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return _StatsEmptyState(
              message: context.l10n(
                ko: '아직 통계가 없습니다.\n장소를 방문하면 기록이 쌓입니다.',
                en: 'No stats yet.\nRecords appear after you visit places.',
                ja: 'まだ統計がありません。\n場所を訪問すると記録されます。',
              ),
            );
          }

          final stats = _VisitStats.fromVisits(visits);
          final places =
              placesMapState.valueOrNull ?? const <String, PlaceSummary>{};
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRankingProvider);
              await ref
                  .read(userVisitsControllerProvider.notifier)
                  .load(forceRefresh: true);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: GBTPageHeader(
                    eyebrow: 'FIELD TOTALS',
                    title: context.l10n(
                      ko: '나의 탐방 장부',
                      en: 'My field ledger',
                      ja: '私の探訪台帳',
                    ),
                    description: context.l10n(
                      ko: '다녀온 장소와 시간을 한눈에 확인합니다.',
                      en: 'A concise record of your places and dates.',
                      ja: '訪れた場所と日付を一覧で確認します。',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: VisitStatsDocumentSummary(
                    totalVisits: context.l10n(
                      ko: '${stats.totalVisits}회',
                      en: '${stats.totalVisits} visits',
                      ja: '${stats.totalVisits}回',
                    ),
                    uniquePlaces: context.l10n(
                      ko: '${stats.uniquePlaces}곳',
                      en: '${stats.uniquePlaces} places',
                      ja: '${stats.uniquePlaces}か所',
                    ),
                    firstVisit: stats.firstVisitLabel,
                    latestVisit: stats.lastVisitLabel,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _RankingRecord(rankingState: rankingState),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GBTSpacing.md,
                      GBTSpacing.xl,
                      GBTSpacing.md,
                      0,
                    ),
                    child: _StatsSectionHeader(
                      indexLabel: '03',
                      title: context.l10n(
                        ko: '자주 방문한 장소',
                        en: 'Most visited places',
                        ja: 'よく訪れた場所',
                      ),
                    ),
                  ),
                ),
                if (stats.topPlaces.isEmpty)
                  SliverToBoxAdapter(
                    child: _SectionMessage(
                      message: context.l10n(
                        ko: '표시할 방문 기록이 없습니다.',
                        en: 'No visit records to display.',
                        ja: '表示する訪問記録がありません。',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.md,
                    ),
                    sliver: SliverList.builder(
                      itemCount: stats.topPlaces.length,
                      itemBuilder: (context, index) {
                        final item = stats.topPlaces[index];
                        return _TopPlaceRow(
                          index: index + 1,
                          place: places[item.placeId],
                          visitCount: item.count,
                          isLoading:
                              placesMapState.isLoading &&
                              !places.containsKey(item.placeId),
                          onTap: () => context.goToPlaceDetail(item.placeId),
                        );
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        MediaQuery.paddingOf(context).bottom + GBTSpacing.xl,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// EN: Linear summary of the four canonical visit facts.
/// KO: 네 가지 핵심 방문 사실을 선형으로 정리한 요약입니다.
class VisitStatsDocumentSummary extends StatelessWidget {
  const VisitStatsDocumentSummary({
    super.key,
    required this.totalVisits,
    required this.uniquePlaces,
    required this.firstVisit,
    required this.latestVisit,
  });

  final String totalVisits;
  final String uniquePlaces;
  final String firstVisit;
  final String latestVisit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('visit-stats-document-summary'),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xl,
        GBTSpacing.md,
        0,
      ),
      child: Column(
        children: [
          _StatsSectionHeader(
            indexLabel: '01',
            title: context.l10n(ko: '누적 기록', en: 'Totals', ja: '累計記録'),
          ),
          _StatsDatum(
            label: context.l10n(ko: '총 방문', en: 'Total visits', ja: '総訪問'),
            value: totalVisits,
          ),
          _StatsDatum(
            label: context.l10n(ko: '방문 장소', en: 'Visited places', ja: '訪問場所'),
            value: uniquePlaces,
          ),
          _StatsDatum(
            label: context.l10n(ko: '첫 방문', en: 'First visit', ja: '初回訪問'),
            value: firstVisit,
          ),
          _StatsDatum(
            label: context.l10n(ko: '최근 방문', en: 'Latest visit', ja: '最近の訪問'),
            value: latestVisit,
          ),
        ],
      ),
    );
  }
}

class _RankingRecord extends StatelessWidget {
  const _RankingRecord({required this.rankingState});

  final AsyncValue<UserRanking?> rankingState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.xl,
        GBTSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsSectionHeader(
            indexLabel: '02',
            title: context.l10n(ko: '탐방 순위', en: 'Field rank', ja: '探訪順位'),
          ),
          rankingState.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
              child: GBTShimmer(
                child: GBTShimmerContainer(height: 52, width: double.infinity),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (ranking) {
              if (ranking == null) return const SizedBox.shrink();
              final topPercent = ranking.totalUsers > 0
                  ? ((ranking.rank / ranking.totalUsers) * 100).toStringAsFixed(
                      0,
                    )
                  : '0';
              return _StatsDatum(
                label: context.l10n(
                  ko: '현재 순위',
                  en: 'Current rank',
                  ja: '現在順位',
                ),
                value: context.l10n(
                  ko: '${ranking.rank}위 · 상위 $topPercent%',
                  en: '#${ranking.rank} · top $topPercent%',
                  ja: '${ranking.rank}位 · 上位$topPercent%',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsSectionHeader extends StatelessWidget {
  const _StatsSectionHeader({required this.indexLabel, required this.title});

  final String indexLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              indexLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsDatum extends StatelessWidget {
  const _StatsDatum({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final useStacked = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final labelWidget = Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
    final valueWidget = Text(
      value,
      textAlign: useStacked ? TextAlign.start : TextAlign.end,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: useStacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: GBTSpacing.xs),
                valueWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: labelWidget),
                const SizedBox(width: GBTSpacing.md),
                Flexible(child: valueWidget),
              ],
            ),
    );
  }
}

class _TopPlaceRow extends StatelessWidget {
  const _TopPlaceRow({
    required this.index,
    required this.place,
    required this.visitCount,
    required this.isLoading,
    required this.onTap,
  });

  final int index;
  final PlaceSummary? place;
  final int visitCount;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final placeName =
        place?.name ??
        context.l10n(ko: '장소 정보 없음', en: 'No place info', ja: '場所情報なし');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '$index'.padLeft(2, '0'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: place?.imageUrl != null && place!.imageUrl!.isNotEmpty
                    ? GBTImage(
                        imageUrl: place!.imageUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: placeName,
                      )
                    : ColoredBox(
                        color: colors.surfaceContainer,
                        child: Icon(
                          Icons.place_outlined,
                          color: colors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: isLoading
                    ? const GBTShimmer(
                        child: GBTShimmerContainer(height: 18, width: 120),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: GBTSpacing.xxs),
                          Text(
                            context.l10n(
                              ko: '$visitCount회 방문',
                              en: '$visitCount visits',
                              ja: '$visitCount回訪問',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitStats {
  const _VisitStats({
    required this.totalVisits,
    required this.uniquePlaces,
    required this.firstVisit,
    required this.lastVisit,
    required this.topPlaces,
  });

  final int totalVisits;
  final int uniquePlaces;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final List<_PlaceCount> topPlaces;

  String get firstVisitLabel => _formatDate(firstVisit);
  String get lastVisitLabel => _formatDate(lastVisit);

  static _VisitStats fromVisits(List<VisitEvent> visits) {
    final counts = <String, int>{};
    DateTime? first;
    DateTime? last;
    for (final visit in visits) {
      counts[visit.placeId] = (counts[visit.placeId] ?? 0) + 1;
      final date = visit.visitedAt;
      if (date == null) continue;
      if (first == null || date.isBefore(first)) first = date;
      if (last == null || date.isAfter(last)) last = date;
    }
    final topPlaces =
        counts.entries
            .map((entry) => _PlaceCount(entry.key, entry.value))
            .toList(growable: false)
          ..sort((left, right) => right.count.compareTo(left.count));
    return _VisitStats(
      totalVisits: visits.length,
      uniquePlaces: counts.length,
      firstVisit: first,
      lastVisit: last,
      topPlaces: List.unmodifiable(topPlaces.take(5)),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd').format(date.toLocal());
  }
}

class _PlaceCount {
  const _PlaceCount(this.placeId, this.count);

  final String placeId;
  final int count;
}

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: GBTSpacing.paddingPage,
      children: [
        const SizedBox(height: GBTSpacing.xxl),
        GBTPageHeader(
          eyebrow: 'FIELD TOTALS',
          title: context.l10n(
            ko: '나의 탐방 장부',
            en: 'My field ledger',
            ja: '私の探訪台帳',
          ),
          description: message,
          padding: EdgeInsets.zero,
          showDivider: false,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: GBTSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
