/// EN: Zukan collections list page — a stamp-collection shelf with an
/// overall completion meter and a grid of collectible ticket stamps.
/// KO: 도감 컬렉션 목록 페이지 — 전체 완료도 미터와 수집 스탬프 그리드로
/// 구성된 스탬프 컬렉션 진열장.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_pressable.dart';
import '../../../../core/widgets/common/gbt_stamp_badge.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/zukan_controller.dart';
import '../../domain/entities/zukan_collection.dart';

/// EN: Displays the full list of zukan stamp collections for the selected project.
/// KO: 선택된 프로젝트의 전체 도감 스탬프 컬렉션 목록을 표시합니다.
class ZukanPage extends ConsumerWidget {
  const ZukanPage({super.key, this.embedded = false});

  /// EN: Omits the standalone app bar inside the Explore workspace.
  /// KO: 탐방 워크스페이스 내부에서는 독립 앱 바를 생략합니다.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectId = ref.watch(selectedProjectKeyProvider);
    // EN: Use null when projectId is absent so the API returns all collections.
    // KO: projectId가 없을 때 null을 사용해 API가 모든 컬렉션을 반환하도록 합니다.
    final pid = (projectId?.isNotEmpty == true) ? projectId : null;
    final collectionsAsync = ref.watch(zukanCollectionsProvider(pid));

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: embedded
          ? null
          : gbtStandardAppBar(
              context,
              title: context.l10n(
                ko: '성지순례 도감',
                en: 'Place Collection',
                ja: '聖地巡礼図鑑',
              ),
            ),
      body: collectionsAsync.when(
        loading: () => const _ZukanShimmerGrid(),
        error: (_, __) => GBTEmptyState(
          icon: Icons.cloud_off_rounded,
          title: context.l10n(
            ko: '도감을 불러오지 못했어요',
            en: 'Could not load collections',
            ja: '図鑑を読み込めませんでした',
          ),
          actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
          onAction: () => ref.refresh(zukanCollectionsProvider(pid)),
        ),
        data: (collections) => collections.isEmpty
            ? GBTEmptyState(
                icon: Icons.auto_awesome_outlined,
                title: context.l10n(
                  ko: '아직 도감이 없어요',
                  en: 'No collections yet',
                  ja: '図鑑はまだありません',
                ),
                subtitle: context.l10n(
                  ko: '성지를 방문하고 첫 스탬프를 모아보세요',
                  en: 'Visit a pilgrimage spot to earn your first stamp',
                  ja: '聖地を訪れて最初のスタンプを集めましょう',
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GBTSpacing.pageHorizontal,
                        GBTSpacing.md,
                        GBTSpacing.pageHorizontal,
                        GBTSpacing.sm,
                      ),
                      child: _ZukanOverviewHeader(collections: collections),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      GBTSpacing.pageHorizontal,
                      0,
                      GBTSpacing.pageHorizontal,
                      GBTSpacing.xl,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: GBTSpacing.md,
                            mainAxisSpacing: GBTSpacing.md,
                            childAspectRatio: 0.78,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final collection = collections[index];
                        return _CollectionGridCard(
                          collection: collection,
                          onTap: () => context.pushNamed(
                            AppRoutes.zukanDetail,
                            pathParameters: {'collectionId': collection.id},
                          ),
                        );
                      }, childCount: collections.length),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// EN: Shimmer placeholder grid shown while collections are loading.
/// KO: 컬렉션 로딩 중 표시되는 쉬머 플레이스홀더 그리드.
class _ZukanShimmerGrid extends StatelessWidget {
  const _ZukanShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: GBTSpacing.md,
        mainAxisSpacing: GBTSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => GBTShimmer(
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? GBTColors.darkSurfaceVariant
                : GBTColors.surfaceVariant,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}

/// EN: Overall completion summary — big gold stat number and a segmented
/// ticket-perforation styled progress meter across all collections.
/// KO: 전체 완료 요약 — 큰 골드 스탯 숫자와 전체 컬렉션에 걸친 티켓 절취선
/// 스타일의 세그먼트 진행 미터.
class _ZukanOverviewHeader extends StatelessWidget {
  const _ZukanOverviewHeader({required this.collections});

  final List<ZukanCollectionSummary> collections;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = isDark ? GBTColors.darkAccent : GBTColors.accent;
    final stamped = collections.fold<int>(0, (sum, c) => sum + c.stampedCount);
    final total = collections.fold<int>(0, (sum, c) => sum + c.totalCount);
    final ratio = total > 0 ? stamped / total : 0.0;
    final percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurface : GBTColors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        boxShadow: isDark ? GBTShadows.darkSm : GBTShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$stamped',
                style: GBTTypography.statNumber.copyWith(
                  color: gold,
                  fontSize: 32,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(
                  '/$total',
                  style: GBTTypography.titleMedium.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.sm,
                  vertical: GBTSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
                child: Text(
                  '$percent%',
                  style: GBTTypography.labelMedium.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(ko: '수집한 스탬프', en: 'Stamps collected', ja: '集めたスタンプ'),
            style: GBTTypography.bodySmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          _SegmentedProgressBar(ratio: ratio, color: gold),
        ],
      ),
    );
  }
}

/// EN: Gold segmented progress bar — a ticket-perforation styled completion
/// meter, used instead of a plain bar for stronger "collection" flavor.
/// KO: 골드 세그먼트 진행 바 — 단순 바 대신 "수집" 느낌을 강화하기 위한
/// 티켓 절취선 스타일의 완료도 미터.
class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const int _segments = 16;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filled = (ratio.clamp(0.0, 1.0) * _segments).round();
    final track = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Row(
      children: List.generate(_segments, (index) {
        final isFilled = index < filled;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == _segments - 1 ? 0 : 3),
            height: 8,
            decoration: BoxDecoration(
              color: isFilled ? color : track,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
            ),
          ),
        );
      }),
    );
  }
}

/// EN: Grid card for a single zukan collection — a stamp badge with cover
/// art that only renders in full color once the collection is complete.
/// KO: 단일 도감 컬렉션의 그리드 카드 — 컬렉션이 완료됐을 때만 풀 컬러로
/// 렌더링되는 커버 아트 스탬프 배지.
class _CollectionGridCard extends StatelessWidget {
  const _CollectionGridCard({required this.collection, required this.onTap});

  final ZukanCollectionSummary collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlocked = collection.isCompleted;
    final mint = GBTSemanticColors.getDistanceColor(
      Theme.of(context).brightness,
    );

    return Semantics(
      button: true,
      label: collection.title,
      hint: context.l10n(
        ko: '${collection.stampedCount}/${collection.totalCount} 방문. 탭하면 상세 보기',
        en: '${collection.stampedCount}/${collection.totalCount} visited. Tap for detail',
        ja: '${collection.stampedCount}/${collection.totalCount}訪問。タップで詳細表示',
      ),
      child: GBTPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(GBTSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? GBTColors.darkSurface : GBTColors.surface,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
            border: Border.all(
              color: isDark ? GBTColors.darkBorderSubtle : GBTColors.border,
            ),
          ),
          child: Column(
            children: [
              GBTStampBadge(
                size: 72,
                unlocked: unlocked,
                // EN: Grid cells rebuild on scroll — suppress the unlock pop
                //     so it doesn't replay for already-collected stamps.
                // KO: 그리드 셀은 스크롤 시 재빌드됨 — 이미 수집된 스탬프에서
                //     해금 팝이 재생되지 않도록 비활성화.
                animateOnUnlock: false,
                child: collection.coverImageUrl != null
                    ? ClipOval(
                        child: GBTImage(
                          imageUrl: collection.coverImageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          semanticLabel: collection.title,
                        ),
                      )
                    : Icon(
                        Icons.photo_album_outlined,
                        size: 28,
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                      ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                collection.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GBTTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    unlocked
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    size: 14,
                    color: unlocked
                        ? mint
                        : (isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary),
                  ),
                  const SizedBox(width: GBTSpacing.xxs),
                  Text(
                    '${collection.stampedCount}/${collection.totalCount}',
                    style: GBTTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? mint
                          : (isDark
                                ? GBTColors.darkTextSecondary
                                : GBTColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
