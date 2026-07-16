/// EN: Visit history page — Timeline-style cards with image previews.
/// KO: 방문 기록 페이지 — 이미지 프리뷰가 있는 타임라인 스타일 카드.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/cards/gbt_ticket_card.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_pressable.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../places/domain/entities/place_entities.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../live_events/presentation/pages/live_attendance_history_page.dart';
import '../../application/visits_controller.dart';
import '../../domain/entities/visit_entities.dart';

/// EN: Visit history page widget — premium timeline design.
/// KO: 방문 기록 페이지 위젯 — 프리미엄 타임라인 디자인.
enum VisitHistoryTab { places, live }

class VisitHistoryPage extends ConsumerStatefulWidget {
  const VisitHistoryPage({
    super.key,
    this.initialTab = VisitHistoryTab.places,
    this.embedded = false,
  });

  final VisitHistoryTab initialTab;

  /// EN: Moves the local places/events switch into the body when embedded.
  /// KO: 포함 모드에서는 장소/이벤트 전환을 본문으로 이동합니다.
  final bool embedded;

  @override
  ConsumerState<VisitHistoryPage> createState() => _VisitHistoryPageState();
}

class _VisitHistoryPageState extends ConsumerState<VisitHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userVisitsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(userVisitsControllerProvider);
    final allPlacesMapState = ref.watch(visitAllProjectsPlacesMapProvider);
    final orderedProjects =
        ref.watch(projectsControllerProvider).valueOrNull ?? const <Project>[];
    final localTabBar = TabBar(
      controller: _tabController,
      tabs: [
        Tab(
          text: context.l10n(ko: '장소', en: 'Places', ja: '場所'),
        ),
        Tab(
          text: context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント'),
        ),
      ],
    );
    final tabBody = TabBarView(
      controller: _tabController,
      children: [
        _buildPlaceHistoryBody(
          context,
          visitsState,
          allPlacesMapState,
          orderedProjects,
        ),
        const LiveAttendanceHistoryBody(),
      ],
    );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : gbtStandardAppBar(
              context,
              title: context.l10n(ko: '방문 기록', en: 'Visit history', ja: '訪問履歴'),
              bottom: localTabBar,
              actions: [
                GBTAppBarIconButton(
                  icon: Icons.bar_chart_rounded,
                  tooltip: context.l10n(ko: '통계', en: 'Stats', ja: '統計'),
                  onPressed: () => context.goToVisitStats(),
                ),
              ],
            ),
      body: widget.embedded
          ? Column(
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: localTabBar,
                ),
                Expanded(child: tabBody),
              ],
            )
          : tabBody,
    );
  }

  Widget _buildPlaceHistoryBody(
    BuildContext context,
    AsyncValue<List<VisitEvent>> visitsState,
    AsyncValue<
      Map<String, ({PlaceSummary place, String projectId, String projectName})>
    >
    allPlacesMapState,
    List<Project> orderedProjects,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(userVisitsControllerProvider.notifier)
          .load(forceRefresh: true),
      child: visitsState.when(
        loading: () => _buildVisitShimmer(isDark, borderColor),
        error: (error, _) {
          final message = error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '방문 기록을 불러오지 못했습니다.',
                  en: 'Could not load visit history.',
                  ja: '訪問履歴を読み込めませんでした。',
                );
          return _VisitEmptyState(
            message: message,
            onRetry: () => ref
                .read(userVisitsControllerProvider.notifier)
                .load(forceRefresh: true),
          );
        },
        data: (visits) {
          if (visits.isEmpty) {
            return _VisitEmptyState(
              message: context.l10n(
                ko: '아직 방문 기록이 없습니다.\n장소를 방문하고 인증해보세요!',
                en: 'No visit history yet.\nVisit a place and verify your visit!',
                ja: 'まだ訪問履歴がありません。\n場所を訪問して認証してみましょう！',
              ),
            );
          }

          // EN: Show shimmer while the all-projects places map is loading
          //     to avoid a flash of mis-grouped visits.
          // KO: 프로젝트 장소 맵 로딩 중에는 쉬머를 표시하여
          //     잘못 그룹화된 방문이 반짝이는 현상을 방지합니다.
          if (allPlacesMapState is AsyncLoading) {
            return _buildVisitShimmer(isDark, borderColor);
          }

          final sorted = [...visits]..sort((a, b) => _compareVisitedAt(b, a));
          final allPlacesMap = allPlacesMapState.valueOrNull ?? const {};

          // EN: Partition visits into project buckets via place → project lookup.
          //     Visits whose placeId is not found in any project land in the
          //     unknown bucket and are rendered last under "기타".
          // KO: 장소 → 프로젝트 조회로 방문을 프로젝트 버킷으로 분류합니다.
          //     어떤 프로젝트에도 속하지 않는 방문은 미확인 버킷에 들어가
          //     마지막 "기타" 섹션으로 렌더됩니다.
          const unknownProjectId = '__unknown__';
          final buckets = <String, List<VisitEvent>>{};
          for (final visit in sorted) {
            final meta = allPlacesMap[visit.placeId];
            final key = meta?.projectId ?? unknownProjectId;
            (buckets[key] ??= []).add(visit);
          }

          // EN: Order: projects in API list order, then unknown bucket last.
          // KO: 순서: API 목록 순서대로 프로젝트, 미확인 버킷은 마지막.
          final orderedKeys = [
            for (final p in orderedProjects)
              if (buckets.containsKey(p.id)) p.id,
            if (buckets.containsKey(unknownProjectId)) unknownProjectId,
          ];
          final projectNameOf = {for (final p in orderedProjects) p.id: p.name};

          // EN: Build a flat sliver list: project header → month header → tiles.
          // KO: 프로젝트 헤더 → 월별 헤더 → 타일 순의 평탄한 슬리버 리스트 구성.
          final slivers = <Widget>[
            SliverToBoxAdapter(
              child: _SummaryHeader(
                totalVisits: sorted.length,
                uniquePlaces: sorted.map((v) => v.placeId).toSet().length,
              ),
            ),
          ];

          for (final projectId in orderedKeys) {
            final label = projectId == unknownProjectId
                ? context.l10n(ko: '기타', en: 'Other', ja: 'その他')
                : (projectNameOf[projectId] ?? '');
            slivers.add(
              SliverToBoxAdapter(child: _ProjectHeader(label: label)),
            );

            final grouped = _groupByMonth(buckets[projectId]!, context);
            for (final entry in grouped.entries) {
              slivers.add(
                SliverToBoxAdapter(child: _MonthHeader(label: entry.key)),
              );
              slivers.add(
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.pageHorizontal,
                  ),
                  sliver: SliverList.separated(
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: GBTSpacing.sm),
                    itemBuilder: (ctx, index) {
                      final visit = entry.value[index];
                      final meta = allPlacesMap[visit.placeId];
                      return _VisitCard(
                        visit: visit,
                        place: meta?.place,
                        isLoading: false,
                        onTap: () => context.goToVisitDetail(
                          visitId: visit.id,
                          placeId: visit.placeId,
                          visitedAt: visit.visitedAt?.toIso8601String(),
                        ),
                      );
                    },
                  ),
                ),
              );
              slivers.add(
                const SliverToBoxAdapter(
                  child: SizedBox(height: GBTSpacing.md),
                ),
              );
            }
          }

          slivers.add(
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + GBTSpacing.lg,
              ),
            ),
          );

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          );
        },
      ),
    );
  }

  Widget _buildVisitShimmer(bool isDark, Color borderColor) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.lg,
      ),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: GBTSpacing.sm),
      itemBuilder: (context, index) => GBTShimmer(
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: isDark
                ? GBTColors.darkSurfaceVariant
                : GBTColors.surfaceVariant,
            border: Border.all(color: borderColor, width: 0.5),
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  int _compareVisitedAt(VisitEvent a, VisitEvent b) {
    final aDate = a.visitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.visitedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  }

  Map<String, List<VisitEvent>> _groupByMonth(
    List<VisitEvent> visits,
    BuildContext context,
  ) {
    final grouped = <String, List<VisitEvent>>{};
    for (final visit in visits) {
      final dt = visit.visitedAt;
      final key = dt != null
          ? context.l10n(
              ko: '${dt.year}년 ${dt.month}월',
              en: '${dt.year}-${dt.month.toString().padLeft(2, '0')}',
              ja: '${dt.year}年${dt.month}月',
            )
          : context.l10n(ko: '날짜 미상', en: 'Unknown date', ja: '日付不明');
      grouped.putIfAbsent(key, () => []).add(visit);
    }
    return grouped;
  }
}

// ---------------------------------------------------------------------------
// EN: Summary header with total visits and unique places
// KO: 총 방문 및 고유 장소 요약 헤더
// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.totalVisits, required this.uniquePlaces});

  final int totalVisits;
  final int uniquePlaces;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
      ),
      padding: const EdgeInsets.all(GBTSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        border: Border.all(
          color: isDark ? GBTColors.darkBorder : GBTColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              icon: Icons.check_circle_rounded,
              iconColor: GBTSemanticColors.getDistanceColor(
                Theme.of(context).brightness,
              ),
              label: context.l10n(ko: '총 방문', en: 'Total visits', ja: '総訪問'),
              value: context.l10n(
                ko: '$totalVisits회',
                en: '$totalVisits',
                ja: '$totalVisits回',
              ),
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark
                ? GBTColors.darkBorder
                : GBTColors.primary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _SummaryItem(
              icon: Icons.place_rounded,
              label: context.l10n(
                ko: '방문 장소',
                en: 'Visited places',
                ja: '訪問場所',
              ),
              value: context.l10n(
                ko: '$uniquePlaces곳',
                en: '$uniquePlaces',
                ja: '$uniquePlacesか所',
              ),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color:
              iconColor ?? (isDark ? GBTColors.darkPrimary : GBTColors.primary),
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          value,
          style: GBTTypography.statNumber.copyWith(
            fontSize: 22,
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GBTTypography.bodySmall.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Project section header
// KO: 프로젝트 섹션 헤더
// ---------------------------------------------------------------------------

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xxs,
      ),
      child: Text(
        label,
        style: GBTTypography.headlineSmall.copyWith(
          color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Month section header
// KO: 월별 섹션 헤더
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xs,
      ),
      child: Text(
        label,
        style: GBTTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Visit card rendered as a small ticket stub — place info in the body,
// visited date + chevron torn off below the perforation line.
// KO: 작은 티켓 스텁으로 렌더링되는 방문 카드 — 본문에 장소 정보, 절취선
// 아래에 방문 날짜와 화살표를 배치합니다.
// ---------------------------------------------------------------------------

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.place,
    required this.isLoading,
    required this.onTap,
  });

  final VisitEvent visit;
  final PlaceSummary? place;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeName =
        place?.name ??
        context.l10n(ko: '장소 정보 없음', en: 'No place info', ja: '場所情報なし');
    final mutedText = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Semantics(
      label: isLoading
          ? context.l10n(
              ko: '방문 기록: 장소 이름 로딩 중, ${visit.visitedAtLabel}',
              en: 'Visit record: loading place name, ${visit.visitedAtLabel}',
              ja: '訪問記録: 場所名読み込み中, ${visit.visitedAtLabel}',
            )
          : context.l10n(
              ko: '방문 기록: $placeName, ${visit.visitedAtLabel}',
              en: 'Visit record: $placeName, ${visit.visitedAtLabel}',
              ja: '訪問記録: $placeName, ${visit.visitedAtLabel}',
            ),
      button: true,
      child: GBTPressable(
        onTap: onTap,
        child: GBTTicketCard(
          stubHeight: 40,
          padding: const EdgeInsets.all(GBTSpacing.sm),
          stubPadding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          body: Row(
            children: [
              // EN: Place thumbnail
              // KO: 장소 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildThumbnail(context, isDark),
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              // EN: Place name + address
              // KO: 장소 이름 + 주소
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      _buildShimmer(isDark)
                    else
                      Text(
                        placeName,
                        style: GBTTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? GBTColors.darkTextPrimary
                              : GBTColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (place != null && place!.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: mutedText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place!.address,
                              style: GBTTypography.bodySmall.copyWith(
                                color: mutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          stub: Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: mutedText),
              const SizedBox(width: 4),
              Text(
                visit.visitedAtLabel.isNotEmpty ? visit.visitedAtLabel : '-',
                style: GBTTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 18, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark) {
    if (place?.imageUrl != null && place!.imageUrl!.isNotEmpty) {
      return GBTImage(
        imageUrl: place!.imageUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '${place!.name} 썸네일',
          en: '${place!.name} thumbnail',
          ja: '${place!.name} サムネイル',
        ),
      );
    }
    return Container(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.place_rounded,
          size: 32,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return GBTShimmer(
      child: Container(
        height: 16,
        width: 120,
        decoration: BoxDecoration(
          color: isDark
              ? GBTColors.darkSurfaceVariant
              : GBTColors.surfaceVariant,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Empty state
// KO: 빈 상태
// ---------------------------------------------------------------------------

class _VisitEmptyState extends StatelessWidget {
  const _VisitEmptyState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: GBTSpacing.paddingPage,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          Icons.explore_outlined,
          size: 64,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        ),
        const SizedBox(height: GBTSpacing.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GBTTypography.bodyLarge.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: GBTSpacing.lg),
          Center(
            child: FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ),
        ],
      ],
    );
  }
}
