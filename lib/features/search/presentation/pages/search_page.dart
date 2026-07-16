/// EN: Search page with unified search across all content.
/// KO: 모든 콘텐츠를 통합 검색하는 검색 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../../core/widgets/navigation/gbt_search_app_bar.dart';
import '../../application/search_controller.dart';
import '../../domain/entities/search_entities.dart';
import '../../../projects/application/projects_controller.dart';

/// EN: Search page widget.
/// KO: 검색 페이지 위젯.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  /// EN: Initial search query from deep link.
  /// KO: 딥링크에서 전달받은 초기 검색어.
  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const int _discoveryLimit = 10;

  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _hasShownDiscoveryFailureToast = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _query = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchControllerProvider.notifier).search(_query);
      });
    }
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      ref.read(searchControllerProvider.notifier).search('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchControllerProvider.notifier).search(value);
    });
  }

  Future<void> _onSubmit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    unawaited(ref.read(analyticsServiceProvider).logSearch(trimmed));
    await ref.read(searchHistoryControllerProvider.notifier).addSearch(trimmed);
  }

  Future<void> _onRefresh() async {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      await Future.wait([
        ref.refresh(searchPopularDiscoveryProvider(_discoveryLimit).future),
        ref.refresh(searchCategoryDiscoveryProvider(_discoveryLimit).future),
      ]);
      return;
    }
    await ref
        .read(searchControllerProvider.notifier)
        .search(trimmed, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryControllerProvider);
    final resultsState = ref.watch(searchControllerProvider);
    final shouldShowDiscovery = _query.isEmpty;
    final popularState = shouldShowDiscovery
        ? ref.watch(searchPopularDiscoveryProvider(_discoveryLimit))
        : null;
    final categoryState = shouldShowDiscovery
        ? ref.watch(searchCategoryDiscoveryProvider(_discoveryLimit))
        : null;
    if (shouldShowDiscovery && popularState != null && categoryState != null) {
      _showDiscoveryFailureToastIfNeeded(popularState, categoryState);
    }

    return Scaffold(
      appBar: GBTSearchAppBar(
        controller: _searchController,
        focusNode: _focusNode,
        hintText: context.l10n(
          ko: '장소·이벤트·밴드·성우·유저 검색',
          en: 'Search places, events, bands, voice actors, users',
          ja: '場所・イベント・バンド・声優・ユーザーを検索',
        ),
        backTooltip: context.l10n(ko: '뒤로가기', en: 'Back', ja: '戻る'),
        onChanged: _onQueryChanged,
        onSubmitted: _onSubmit,
        onClear: () {
          _searchController.clear();
          _onQueryChanged('');
        },
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _query.isEmpty
            ? _RecentSearches(
                items: history,
                popularState: popularState!,
                categoryState: categoryState!,
                onSelect: (value) {
                  _searchController.text = value;
                  _onQueryChanged(value);
                  _onSubmit(value);
                },
                onRemove: (value) => ref
                    .read(searchHistoryControllerProvider.notifier)
                    .removeSearch(value),
                onClear: () =>
                    ref.read(searchHistoryControllerProvider.notifier).clear(),
                onRetryPopular: () => ref.invalidate(
                  searchPopularDiscoveryProvider(_discoveryLimit),
                ),
                onRetryCategories: () => ref.invalidate(
                  searchCategoryDiscoveryProvider(_discoveryLimit),
                ),
              )
            : _SearchResults(
                query: _query,
                state: resultsState,
                onRetry: () => ref
                    .read(searchControllerProvider.notifier)
                    .search(_query, forceRefresh: true),
              ),
      ),
    );
  }

  void _showDiscoveryFailureToastIfNeeded(
    AsyncValue<SearchPopularDiscovery> popularState,
    AsyncValue<SearchCategoryDiscovery> categoryState,
  ) {
    if (_hasShownDiscoveryFailureToast) return;
    if (!(popularState.hasError || categoryState.hasError)) return;
    _hasShownDiscoveryFailureToast = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '일부 검색 추천 데이터를 불러오지 못했어요. 검색은 계속 사용할 수 있어요.',
              en: 'Some discovery data failed to load. Search is still available.',
              ja: '一部の検索おすすめデータの読み込みに失敗しました。検索は引き続き利用できます。',
            ),
          ),
        ),
      );
    });
  }
}

// ============================================================
// EN: Recent searches — horizontal chip row + trending tags
// KO: 최근 검색 — 수평 칩 행 + 트렌딩 태그
// ============================================================

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.items,
    required this.popularState,
    required this.categoryState,
    required this.onSelect,
    required this.onRemove,
    required this.onClear,
    required this.onRetryPopular,
    required this.onRetryCategories,
  });

  final List<String> items;
  final AsyncValue<SearchPopularDiscovery> popularState;
  final AsyncValue<SearchCategoryDiscovery> categoryState;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final VoidCallback onRetryPopular;
  final VoidCallback onRetryCategories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final chipItems = items.take(6).toList();
    final popularKeywords = _resolvePopularKeywords(context);
    final quickItems = _resolveCategoryItems();
    final exploreTopics = _buildExploreTopics(context);
    final popularUpdatedLabel = _resolveUpdatedLabel(
      context,
      popularState.valueOrNull?.updatedAt,
    );
    final categoriesUpdatedLabel = _resolveUpdatedLabel(
      context,
      categoryState.valueOrNull?.updatedAt,
    );
    final showCategoriesSection = quickItems.isNotEmpty;
    final showCategoriesRetry =
        !showCategoriesSection && categoryState.hasError;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.sm,
        GBTSpacing.md,
        GBTSpacing.xl,
      ),
      children: [
        if (chipItems.isNotEmpty)
          SizedBox(
            height: GBTSpacing.touchTarget,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: chipItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: GBTSpacing.xs),
              itemBuilder: (context, index) {
                final item = chipItems[index];
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SearchHistoryChip(
                    label: item,
                    isDark: isDark,
                    onTap: () => onSelect(item),
                    onRemove: () => onRemove(item),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history_rounded, size: 16, color: tertiaryColor),
                const SizedBox(width: GBTSpacing.xs),
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '자주 찾는 키워드를 빠르게 다시 검색할 수 있어요.',
                      en:
                          'Your frequent keywords will appear here for '
                          'quick search.',
                      ja: 'よく使うキーワードをここですぐ再検索できます。',
                    ),
                    style: GBTTypography.bodySmall.copyWith(
                      color: tertiaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (chipItems.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.xs,
                  vertical: GBTSpacing.xxs,
                ),
              ),
              child: Text(
                context.l10n(
                  ko: '최근 검색어 전체 삭제',
                  en: 'Clear recent',
                  ja: '最近検索を削除',
                ),
                style: GBTTypography.labelSmall.copyWith(color: tertiaryColor),
              ),
            ),
          ),
        const SizedBox(height: GBTSpacing.md),
        _DiscoverySectionHeader(
          title: context.l10n(
            ko: '인기 통합 검색',
            en: 'Popular searches',
            ja: '人気統合検索',
          ),
          trailing: popularUpdatedLabel,
        ),
        const SizedBox(height: GBTSpacing.sm),
        if (popularState.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetryPopular,
                child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
              ),
            ),
          ),
        ...popularKeywords.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final keyword = entry.value;
          return _DiscoveryRankRow(
            rank: rank,
            title: keyword,
            onTap: () => onSelect(keyword),
          );
        }),
        const SizedBox(height: GBTSpacing.xl),
        if (showCategoriesSection) ...[
          _DiscoverySectionHeader(
            title: context.l10n(
              ko: '인기 탐색 카테고리',
              en: 'Popular explore categories',
              ja: '人気探索カテゴリ',
            ),
            trailing: categoriesUpdatedLabel,
          ),
          const SizedBox(height: GBTSpacing.sm),
          ...quickItems.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            return _DiscoveryQuickRow(
              rank: rank,
              subtitle: item.subtitle,
              title: item.title,
              trailing: context.l10n(
                ko: '${item.contentCount}건',
                en: '${item.contentCount} items',
                ja: '${item.contentCount}件',
              ),
              onTap: () => onSelect(item.query),
            );
          }),
          const SizedBox(height: GBTSpacing.xl),
        ] else if (showCategoriesRetry) ...[
          _DiscoverySectionHeader(
            title: context.l10n(
              ko: '인기 탐색 카테고리',
              en: 'Popular explore categories',
              ja: '人気探索カテゴリ',
            ),
            trailing: categoriesUpdatedLabel,
          ),
          const SizedBox(height: GBTSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetryCategories,
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ),
          const SizedBox(height: GBTSpacing.lg),
        ],
        Row(
          children: [
            Text(
              context.l10n(ko: '검색 둘러보기', en: 'Explore topics', ja: '検索トピック'),
              style: GBTTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n(ko: '전체보기', en: 'View all', ja: 'すべて表示'),
              style: GBTTypography.bodyMedium.copyWith(color: secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.sm),
        SizedBox(
          height: GBTSpacing.touchTarget,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: exploreTopics.length,
            separatorBuilder: (_, __) => const SizedBox(width: GBTSpacing.xs),
            itemBuilder: (context, index) {
              final topic = exploreTopics[index];
              return _ExploreTopicChip(
                label: topic,
                isDark: isDark,
                onTap: () => onSelect(topic),
              );
            },
          ),
        ),
        const SizedBox(height: GBTSpacing.xl),
      ],
    );
  }

  List<String> _resolvePopularKeywords(BuildContext context) {
    final fromServer =
        popularState.valueOrNull?.popularKeywords
            .map((item) => item.keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (fromServer.isNotEmpty) {
      return fromServer.take(5).toList(growable: false);
    }

    final defaults = <String>[
      context.l10n(ko: '토게나시 토게아리', en: 'Togenashi Togeari', ja: 'トゲナシトゲアリ'),
      context.l10n(ko: 'BanG Dream!', en: 'BanG Dream!', ja: 'BanG Dream!'),
      context.l10n(ko: 'Zepp', en: 'Zepp', ja: 'Zepp'),
      context.l10n(ko: '성지순례', en: 'Pilgrimage', ja: '聖地巡礼'),
      context.l10n(ko: '이벤트 일정', en: 'Event schedule', ja: 'イベント日程'),
    ];
    final merged = <String>[];
    for (final item in items) {
      final value = item.trim();
      if (value.isEmpty) continue;
      if (merged.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        continue;
      }
      merged.add(value);
      if (merged.length == 5) {
        return merged;
      }
    }
    for (final item in defaults) {
      if (merged.any(
        (existing) => existing.toLowerCase() == item.toLowerCase(),
      )) {
        continue;
      }
      merged.add(item);
      if (merged.length == 5) {
        break;
      }
    }
    return merged;
  }

  List<_DiscoveryQuickItem> _resolveCategoryItems() {
    final categories = categoryState.valueOrNull?.categories ?? const [];
    return categories
        .where((item) => item.label.trim().isNotEmpty)
        .map(
          (item) => _DiscoveryQuickItem(
            subtitle: item.code,
            title: item.label,
            query: item.label,
            contentCount: item.contentCount,
          ),
        )
        .toList(growable: false);
  }

  List<String> _buildExploreTopics(BuildContext context) {
    return [
      context.l10n(ko: '오늘의 이벤트', en: 'Today events', ja: '今日のイベント'),
      context.l10n(ko: '성지 순례 루트', en: 'Pilgrimage routes', ja: '聖地巡礼ルート'),
      context.l10n(ko: '공연장 근처', en: 'Near venue', ja: '会場周辺'),
      context.l10n(ko: '팬 후기', en: 'Fan reviews', ja: 'ファンレビュー'),
      context.l10n(ko: '신규 뉴스', en: 'Latest news', ja: '最新ニュース'),
    ];
  }

  String _resolveUpdatedLabel(BuildContext context, DateTime? updatedAt) {
    if (updatedAt == null) {
      return context.l10n(ko: '방금 기준', en: 'Updated just now', ja: 'ただいま更新');
    }
    final localTime = updatedAt.toLocal();
    final timeLabel = DateFormat('HH:mm').format(localTime);
    return context.l10n(
      ko: '오늘 $timeLabel 기준',
      en: 'Updated $timeLabel',
      ja: '本日 $timeLabel 時点',
    );
  }
}

/// EN: Search-history action with independent 48dp open and remove targets.
/// KO: 열기와 삭제 동작에 각각 48dp 영역을 제공하는 검색 기록 제어입니다.
class SearchHistoryChip extends StatelessWidget {
  const SearchHistoryChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.onRemove,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // EN: Warm primary-tinted pill — distinguishes "you searched this" chips
    //     from the neutral-grey explore-topic chips below.
    // KO: 웜 프라이머리 톤 필 — 아래 뉴트럴 그레이 탐색 토픽 칩과
    //     "내가 검색했던" 칩을 시각적으로 구분합니다.
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final bgColor = primary.withValues(alpha: isDark ? 0.16 : 0.08);
    final textColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final iconColor = primary.withValues(alpha: 0.7);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: GBTSpacing.touchTarget,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: GBTSpacing.touchTarget,
                  minHeight: GBTSpacing.touchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: GBTSpacing.sm2,
                    right: GBTSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: iconColor),
                      const SizedBox(width: GBTSpacing.xxs),
                      Text(
                        label,
                        style: GBTTypography.labelMedium.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: context.l10n(
                ko: '$label 검색어 삭제',
                en: 'Remove $label from search history',
                ja: '$label を検索履歴から削除',
              ),
              icon: Icon(Icons.close_rounded, size: 18, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverySectionHeader extends StatelessWidget {
  const _DiscoverySectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          title,
          style: GBTTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: GBTTypography.bodyMedium.copyWith(
            color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _DiscoveryRankRow extends StatelessWidget {
  const _DiscoveryRankRow({
    required this.rank,
    required this.title,
    required this.onTap,
  });

  final int rank;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: GBTTypography.titleSmall.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Text(
                title,
                style: GBTTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryQuickRow extends StatelessWidget {
  const _DiscoveryQuickRow({
    required this.rank,
    required this.subtitle,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final int rank;
  final String subtitle;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final subtitleColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: GBTTypography.headlineSmall.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: GBTTypography.bodySmall.copyWith(
                      color: subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GBTTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Text(
              trailing,
              style: GBTTypography.headlineSmall.copyWith(
                color: isDark
                    ? GBTSemanticColors.darkAccentBlue
                    : GBTColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreTopicChip extends StatelessWidget {
  const _ExploreTopicChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? GBTColors.darkSurfaceVariant
              : GBTColors.surfaceVariant,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        ),
        child: Text(
          label,
          style: GBTTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DiscoveryQuickItem {
  const _DiscoveryQuickItem({
    required this.subtitle,
    required this.title,
    required this.query,
    required this.contentCount,
  });

  final String subtitle;
  final String title;
  final String query;
  final int contentCount;
}

// ============================================================
// EN: Search results with tab filter
// KO: 탭 필터가 있는 검색 결과
// ============================================================

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.state,
    required this.onRetry,
  });

  final String query;
  final AsyncValue<List<SearchItem>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final allTab = context.l10n(ko: '전체', en: 'All', ja: '全体');
    final placesTab = context.l10n(ko: '장소', en: 'Places', ja: '場所');
    final eventsTab = context.l10n(ko: '이벤트', en: 'Events', ja: 'イベント');
    final newsTab = context.l10n(ko: '뉴스', en: 'News', ja: 'ニュース');
    final peopleTab = context.l10n(
      ko: '팬·유저',
      en: 'Fans & people',
      ja: 'ファン・ユーザー',
    );

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          GBTSegmentedTabBar(
            margin: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
            isScrollable: true,
            tabs: [
              Tab(text: allTab),
              Tab(text: placesTab),
              Tab(text: eventsTab),
              Tab(text: newsTab),
              Tab(text: peopleTab),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Expanded(
            child: state.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
                children: [
                  GBTListSkeleton(
                    itemCount: 5,
                    padding: EdgeInsets.zero,
                    spacing: GBTSpacing.sm,
                    itemBuilder: (_) => const GBTNewsCardSkeleton(),
                  ),
                ],
              ),
              error: (error, _) {
                final message = error is Failure
                    ? _errorDisplayText(error)
                    : context.l10n(
                        ko: '검색 결과를 불러오지 못했어요',
                        en: 'Failed to load search results',
                        ja: '検索結果を読み込めませんでした',
                      );
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: GBTSpacing.paddingPage,
                  children: [
                    const SizedBox(height: GBTSpacing.lg),
                    GBTErrorState(message: message, onRetry: onRetry),
                  ],
                );
              },
              data: (items) {
                final visibleItems = _filterCurrentMobileItems(items);
                return TabBarView(
                  children: [
                    _SearchResultList(query: query, items: visibleItems),
                    _SearchResultList(
                      query: query,
                      items: _filterByType(visibleItems, SearchItemType.place),
                    ),
                    _SearchResultList(
                      query: query,
                      items: _filterByType(
                        visibleItems,
                        SearchItemType.liveEvent,
                      ),
                    ),
                    _SearchResultList(
                      query: query,
                      items: _filterByType(visibleItems, SearchItemType.news),
                    ),
                    _SearchResultList(
                      query: query,
                      items: _filterFanAndPeople(visibleItems),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _errorDisplayText(Failure failure) {
  final code = failure.code?.trim();
  if (code != null && code.isNotEmpty) {
    return '[$code] ${failure.message}';
  }
  return failure.message;
}

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({required this.query, required this.items});

  final String query;
  final List<SearchItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GBTSpacing.paddingPage,
        children: [
          const SizedBox(height: GBTSpacing.lg),
          GBTEmptyState(
            icon: Icons.search_off_rounded,
            title: context.l10n(
              ko: '검색 결과가 없어요',
              en: 'No search results',
              ja: '検索結果がありません',
            ),
            subtitle: context.l10n(
              ko: '다른 키워드로 검색해보세요.',
              en: 'Try another keyword.',
              ja: '別のキーワードで検索してください。',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: GBTSpacing.xxl),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        // EN: Indent aligns with text content start (thumbnail 48 + gap 12 + horizontal 16)
        // KO: 들여쓰기가 텍스트 시작점과 정렬됨 (썸네일 48 + 간격 12 + 수평 16)
        indent: GBTSpacing.md + 48 + GBTSpacing.md,
        endIndent: GBTSpacing.md,
        color: isDark
            ? GBTColors.darkBorder.withValues(alpha: 0.4)
            : GBTColors.border.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, index) => _SearchResultItem(item: items[index]),
    );
  }
}

/// EN: Search result item — clean row without Card, thumbnail + text + type badge.
/// KO: 검색 결과 아이템 — Card 없는 클린 행, 썸네일 + 텍스트 + 타입 배지.
class _SearchResultItem extends ConsumerWidget {
  const _SearchResultItem({required this.item});

  final SearchItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeLabel = _typeLabel(context, item.type);
    final accentColor = _typeAccentColor(item.type, isDark: isDark);
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Semantics(
      label: '$typeLabel: ${item.title}',
      button: true,
      child: InkWell(
        onTap: () => _handleTap(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: GBTSpacing.sm + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // EN: Thumbnail — image or tinted icon box
              // KO: 썸네일 — 이미지 또는 틴트 아이콘 박스
              _SearchThumbnail(
                imageUrl: item.imageUrl,
                fallbackIcon: _typeIcon(item.type),
                accentColor: accentColor,
                isDark: isDark,
              ),
              const SizedBox(width: GBTSpacing.md),
              // EN: Title + subtitle stack
              // KO: 제목 + 부제목 스택
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GBTTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleText(context, item),
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              // EN: Type badge pill
              // KO: 타입 배지 필
              _TypeBadge(
                label: typeLabel,
                accentColor: accentColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: 48×48 thumbnail widget for search result rows.
/// KO: 검색 결과 행용 48×48 썸네일 위젯.
class _SearchThumbnail extends StatelessWidget {
  const _SearchThumbnail({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.accentColor,
    required this.isDark,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        child: GBTImage(
          imageUrl: imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          semanticLabel: context.l10n(
            ko: '검색 결과 이미지',
            en: 'Search result image',
            ja: '検索結果画像',
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Icon(fallbackIcon, color: accentColor, size: 22),
    );
  }
}

/// EN: Pill-shaped type badge for search result items.
/// KO: 검색 결과 아이템용 필 형태의 타입 배지.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.accentColor,
    required this.isDark,
  });

  final String label;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: GBTTypography.labelSmall.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// EN: Helper functions
// KO: 헬퍼 함수
// ============================================================

List<SearchItem> _filterByType(List<SearchItem> items, SearchItemType type) {
  return items.where((item) => item.type == type).toList();
}

List<SearchItem> _filterCurrentMobileItems(List<SearchItem> items) {
  return items
      .where(
        (item) =>
            item.type != SearchItemType.artist &&
            item.type != SearchItemType.anime,
      )
      .toList(growable: false);
}

List<SearchItem> _filterFanAndPeople(List<SearchItem> items) {
  const types = {
    SearchItemType.project,
    SearchItemType.unit,
    SearchItemType.voiceActor,
    SearchItemType.user,
  };
  return items.where((item) => types.contains(item.type)).toList();
}

String _typeLabel(BuildContext context, SearchItemType type) {
  return switch (type) {
    SearchItemType.place => context.l10n(ko: '장소', en: 'Places', ja: '場所'),
    SearchItemType.liveEvent => context.l10n(
      ko: '이벤트',
      en: 'Events',
      ja: 'イベント',
    ),
    SearchItemType.news => context.l10n(ko: '뉴스', en: 'News', ja: 'ニュース'),
    SearchItemType.post => context.l10n(
      ko: '커뮤니티',
      en: 'Community',
      ja: 'コミュニティ',
    ),
    SearchItemType.unit => context.l10n(
      ko: '밴드·유닛',
      en: 'Band / unit',
      ja: 'バンド・ユニット',
    ),
    SearchItemType.project => context.l10n(
      ko: '프로젝트',
      en: 'Project',
      ja: 'プロジェクト',
    ),
    SearchItemType.voiceActor => context.l10n(
      ko: '성우',
      en: 'Voice actor',
      ja: '声優',
    ),
    SearchItemType.artist => context.l10n(
      ko: '아티스트',
      en: 'Artist',
      ja: 'アーティスト',
    ),
    SearchItemType.anime => context.l10n(ko: '애니메이션', en: 'Anime', ja: 'アニメ'),
    SearchItemType.user => context.l10n(ko: '유저', en: 'User', ja: 'ユーザー'),
    SearchItemType.unknown => context.l10n(ko: '기타', en: 'Other', ja: 'その他'),
  };
}

IconData _typeIcon(SearchItemType type) {
  return switch (type) {
    SearchItemType.place => Icons.place_rounded,
    SearchItemType.liveEvent => Icons.event_rounded,
    SearchItemType.news => Icons.article_rounded,
    SearchItemType.post => Icons.forum_rounded,
    SearchItemType.unit => Icons.group_rounded,
    SearchItemType.project => Icons.folder_rounded,
    SearchItemType.voiceActor => Icons.record_voice_over_rounded,
    SearchItemType.artist => Icons.mic_external_on_rounded,
    SearchItemType.anime => Icons.movie_filter_rounded,
    SearchItemType.user => Icons.person_rounded,
    SearchItemType.unknown => Icons.search_rounded,
  };
}

/// EN: Accent color per search item type — distinct, accessible colors.
/// KO: 검색 아이템 타입별 강조 색상 — 구분 가능하고 접근성 있는 색상.
Color _typeAccentColor(SearchItemType type, {required bool isDark}) {
  return switch (type) {
    SearchItemType.place =>
      isDark
          ? GBTSemanticColors.darkMetadataDistance
          : GBTColors.accentTeal, // teal — location
    SearchItemType.liveEvent =>
      isDark
          ? GBTColors.darkSecondary
          : GBTColors.secondary, // pink — live event
    SearchItemType.news =>
      isDark
          ? GBTSemanticColors.darkAccentBlue
          : GBTColors.accentBlue, // blue — news
    SearchItemType.post =>
      isDark ? GBTColors.darkPrimary : GBTColors.primary, // indigo — community
    SearchItemType.unit =>
      isDark ? GBTColors.darkAccent : GBTColors.accent, // gold — unit/band
    SearchItemType.project =>
      isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary,
    SearchItemType.voiceActor =>
      isDark ? GBTSemanticColors.darkAccentBlue : GBTColors.accentBlue,
    SearchItemType.artist =>
      isDark ? GBTColors.darkSecondary : GBTColors.secondary,
    SearchItemType.anime => isDark ? GBTColors.darkPrimary : GBTColors.primary,
    SearchItemType.user => isDark ? GBTColors.darkPrimary : GBTColors.primary,
    SearchItemType.unknown =>
      isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
  };
}

String _subtitleText(BuildContext context, SearchItem item) {
  if (item.subtitle != null && item.subtitle!.isNotEmpty) {
    return item.subtitle!;
  }
  if (item.category != null && item.category!.isNotEmpty) {
    return item.category!;
  }
  if (item.dateLabel.isNotEmpty) {
    return item.dateLabel;
  }
  return context.l10n(
    ko: '상세 정보를 확인해보세요',
    en: 'Check the details',
    ja: '詳細を確認してください',
  );
}

void _handleTap(BuildContext context, WidgetRef ref, SearchItem item) {
  switch (item.type) {
    case SearchItemType.place:
      context.goToPlaceDetail(item.id);
      break;
    case SearchItemType.liveEvent:
      context.goToEventDetail(item.id);
      break;
    case SearchItemType.news:
      context.goToNewsDetail(item.id);
      break;
    case SearchItemType.post:
      context.goToPostDetail(item.id);
      break;
    case SearchItemType.unit:
      final projectId = _projectContextOrNotify(context, item);
      if (projectId == null) return;
      context.goToUnitDetailByIdentifier(item.sourceId, projectId: projectId);
      break;
    case SearchItemType.project:
      final projectKey = item.projectKey;
      if (projectKey == null || item.sourceId.isEmpty) {
        _showUnavailableResultMessage(context);
        return;
      }
      unawaited(
        ref
            .read(projectSelectionControllerProvider.notifier)
            .selectProject(projectKey, projectId: item.sourceId),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '여행 기준을 ${item.title}(으)로 변경했어요.',
              en: 'Travel context changed to ${item.title}.',
              ja: '旅行の基準を${item.title}に変更しました。',
            ),
          ),
        ),
      );
      break;
    case SearchItemType.voiceActor:
      final projectId = _projectContextOrNotify(context, item);
      if (projectId == null) return;
      context.goToVoiceActorDetail(
        item.sourceId,
        projectId: projectId,
        fallbackName: item.title,
      );
      break;
    case SearchItemType.artist:
    case SearchItemType.anime:
      if (item.id.isEmpty) {
        _showUnavailableResultMessage(context);
        return;
      }
      context.goToFanSubjectDetail(item.id);
      break;
    case SearchItemType.user:
      if (item.sourceId.isEmpty) {
        _showUnavailableResultMessage(context);
        return;
      }
      context.goToUserProfile(item.sourceId);
      break;
    case SearchItemType.unknown:
      if (item.navigationTargetType?.toUpperCase() == 'FAN_SUBJECT' &&
          item.id.isNotEmpty) {
        context.goToFanSubjectDetail(item.id);
      }
      break;
  }
}

String? _projectContextOrNotify(BuildContext context, SearchItem item) {
  final projectId = item.projectId?.trim();
  if (projectId != null && projectId.isNotEmpty && item.sourceId.isNotEmpty) {
    return projectId;
  }
  _showUnavailableResultMessage(context);
  return null;
}

void _showUnavailableResultMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.l10n(
          ko: '해당 항목의 상세 정보를 준비 중이에요.',
          en: 'Details for this result are not available yet.',
          ja: 'この検索結果の詳細は現在準備中です。',
        ),
      ),
    ),
  );
}
