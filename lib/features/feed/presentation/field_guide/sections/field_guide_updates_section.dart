/// EN: Editorial update stream for the Field Guide.
/// KO: Field Guide를 위한 에디토리얼 업데이트 스트림.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/widgets/common/gbt_image.dart';
import '../../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../domain/entities/feed_entities.dart';
import '../field_guide_providers.dart';

enum _UpdateArchiveOrder { latest, oldest }

class FieldGuideUpdatesSection extends ConsumerStatefulWidget {
  const FieldGuideUpdatesSection({
    super.key,
    required this.onRefresh,
    required this.onUpdateTap,
  });

  final Future<void> Function() onRefresh;
  final ValueChanged<NewsSummary> onUpdateTap;

  @override
  ConsumerState<FieldGuideUpdatesSection> createState() =>
      _FieldGuideUpdatesSectionState();
}

class _FieldGuideUpdatesSectionState
    extends ConsumerState<FieldGuideUpdatesSection> {
  final TextEditingController _searchController = TextEditingController();
  _UpdateArchiveOrder _order = _UpdateArchiveOrder.latest;
  String _query = '';
  int? _selectedYear;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldGuideUpdatesProvider);

    return state.when(
      loading: () => const _UpdatesSkeleton(),
      error: (error, _) => _UpdatesFailure(
        message: error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '업데이트를 불러오지 못했어요',
                en: 'Could not load updates',
                ja: '更新を読み込めませんでした',
              ),
        onRetry: widget.onRefresh,
      ),
      data: (updates) {
        if (updates.isEmpty) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                GBTSpacing.xl,
                GBTSpacing.pageHorizontal,
                GBTSpacing.bottomNavClearanceOf(context),
              ),
              children: [
                GBTEmptyState(
                  icon: Icons.mark_email_unread_outlined,
                  title: context.l10n(
                    ko: '아직 도착한 업데이트가 없어요',
                    en: 'No field updates yet',
                    ja: 'まだ更新はありません',
                  ),
                  subtitle: context.l10n(
                    ko: '새로운 공연과 현장 정보가 도착하면 여기에 정리됩니다.',
                    en: 'New shows and on-site notes will appear here.',
                    ja: '新しい公演や現地情報がここに届きます。',
                  ),
                ),
              ],
            ),
          );
        }

        final years =
            updates
                .map((update) => update.publishedAt.toLocal().year)
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));
        final effectiveYear = years.contains(_selectedYear)
            ? _selectedYear
            : null;
        final normalizedQuery = _query.trim().toLowerCase();
        final visible =
            updates
                .where(
                  (update) =>
                      (effectiveYear == null ||
                          update.publishedAt.toLocal().year == effectiveYear) &&
                      (normalizedQuery.isEmpty ||
                          update.title.toLowerCase().contains(normalizedQuery)),
                )
                .toList(growable: false)
              ..sort((a, b) {
                final comparison = a.publishedAt.compareTo(b.publishedAt);
                return _order == _UpdateArchiveOrder.latest
                    ? -comparison
                    : comparison;
              });
        final showFeature =
            _order == _UpdateArchiveOrder.latest &&
            normalizedQuery.isEmpty &&
            effectiveYear == null;

        return Column(
          children: [
            _UpdateArchiveToolbar(
              controller: _searchController,
              order: _order,
              years: years,
              selectedYear: effectiveYear,
              onQueryChanged: (value) => setState(() => _query = value),
              onClear: () => setState(() {
                _searchController.clear();
                _query = '';
              }),
              onOrderChanged: (value) => setState(() => _order = value),
              onYearChanged: (value) => setState(() => _selectedYear = value),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _FilteredUpdatesEmpty(
                      onRefresh: widget.onRefresh,
                      onClear: () => setState(() {
                        _searchController.clear();
                        _query = '';
                        _selectedYear = null;
                      }),
                    )
                  : _UpdatesArchiveList(
                      updates: visible,
                      showFeature: showFeature,
                      onRefresh: widget.onRefresh,
                      onUpdateTap: widget.onUpdateTap,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UpdateArchiveToolbar extends StatelessWidget {
  const _UpdateArchiveToolbar({
    required this.controller,
    required this.order,
    required this.years,
    required this.selectedYear,
    required this.onQueryChanged,
    required this.onClear,
    required this.onOrderChanged,
    required this.onYearChanged,
  });

  final TextEditingController controller;
  final _UpdateArchiveOrder order;
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_UpdateArchiveOrder> onOrderChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filterLabel = [
      order == _UpdateArchiveOrder.latest
          ? context.l10n(ko: '최신순', en: 'Latest first', ja: '新着順')
          : context.l10n(ko: '오래된순', en: 'Oldest first', ja: '古い順'),
      selectedYear?.toString() ??
          context.l10n(ko: '전체 연도', en: 'All years', ja: '全年'),
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.xs,
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('field-guide-update-search'),
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n(
                  ko: '기사 제목 검색',
                  en: 'Search article titles',
                  ja: '記事タイトルを検索',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.l10n(
                          ko: '검색어 지우기',
                          en: 'Clear search',
                          ja: '検索語を消去',
                        ),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                isDense: true,
                constraints: const BoxConstraints(
                  minHeight: GBTSpacing.touchTarget,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                leadingIcon: order == _UpdateArchiveOrder.latest
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                onPressed: () => onOrderChanged(_UpdateArchiveOrder.latest),
                child: Text(
                  context.l10n(ko: '최신순', en: 'Latest first', ja: '新着順'),
                ),
              ),
              MenuItemButton(
                leadingIcon: order == _UpdateArchiveOrder.oldest
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                onPressed: () => onOrderChanged(_UpdateArchiveOrder.oldest),
                child: Text(
                  context.l10n(ko: '오래된순', en: 'Oldest first', ja: '古い順'),
                ),
              ),
              const Divider(),
              MenuItemButton(
                leadingIcon: selectedYear == null
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
                onPressed: () => onYearChanged(null),
                child: Text(
                  context.l10n(ko: '전체 연도', en: 'All years', ja: '全年'),
                ),
              ),
              for (final year in years)
                MenuItemButton(
                  leadingIcon: selectedYear == year
                      ? const Icon(Icons.check_rounded)
                      : const SizedBox(width: 24),
                  onPressed: () => onYearChanged(year),
                  child: Text('$year'),
                ),
            ],
            builder: (context, controller, _) => Semantics(
              button: true,
              label: filterLabel,
              child: IconButton.outlined(
                key: const Key('field-guide-update-filter-menu'),
                tooltip: filterLabel,
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                icon: Icon(
                  Icons.tune_rounded,
                  color:
                      selectedYear != null ||
                          order == _UpdateArchiveOrder.oldest
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesArchiveList extends StatelessWidget {
  const _UpdatesArchiveList({
    required this.updates,
    required this.showFeature,
    required this.onRefresh,
    required this.onUpdateTap,
  });

  final List<NewsSummary> updates;
  final bool showFeature;
  final Future<void> Function() onRefresh;
  final ValueChanged<NewsSummary> onUpdateTap;

  @override
  Widget build(BuildContext context) {
    final featured = showFeature ? updates.first : null;
    final rows = featured == null ? updates : updates.skip(1).toList();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const Key('field-guide-updates-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              GBTSpacing.md,
              GBTSpacing.pageHorizontal,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionIntro(count: updates.length),
            ),
          ),
          if (featured != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                GBTSpacing.md,
                GBTSpacing.pageHorizontal,
                GBTSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: _FeaturedUpdate(
                  update: featured,
                  onTap: () => onUpdateTap(featured),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.pageHorizontal,
            ),
            sliver: SliverList.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final update = rows[index];
                return _UpdateRow(
                  update: update,
                  onTap: () => onUpdateTap(update),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: GBTSpacing.bottomNavClearanceOf(context)),
          ),
        ],
      ),
    );
  }
}

class _FilteredUpdatesEmpty extends StatelessWidget {
  const _FilteredUpdatesEmpty({required this.onRefresh, required this.onClear});

  final Future<void> Function() onRefresh;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(GBTSpacing.md),
        children: [
          GBTEmptyState(
            icon: Icons.manage_search_rounded,
            title: context.l10n(
              ko: '조건에 맞는 기사가 없어요',
              en: 'No matching articles',
              ja: '条件に合う記事がありません',
            ),
            subtitle: context.l10n(
              ko: '검색어나 연도 필터를 바꾸어보세요.',
              en: 'Try another title or year.',
              ja: '検索語や年のフィルターを変えてください。',
            ),
            actionLabel: context.l10n(
              ko: '검색·필터 초기화',
              en: 'Clear search and filters',
              ja: '検索・フィルターをリセット',
            ),
            onAction: onClear,
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(
                  ko: '최신 현장 브리핑',
                  en: 'Latest dispatches',
                  ja: '最新フィールド便り',
                ),
                style: GBTTypography.titleLarge.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                context.l10n(
                  ko: '공연, 팝업, 여행 정보를 날짜순으로 확인하세요.',
                  en: 'Shows, pop-ups, and travel notes in one timeline.',
                  ja: '公演・ポップアップ・旅情報を時系列で確認。',
                ),
                style: GBTTypography.bodySmall.copyWith(color: muted),
              ),
            ],
          ),
        ),
        Text(
          '$count',
          style: GBTTypography.titleLarge.copyWith(
            color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FeaturedUpdate extends StatelessWidget {
  const _FeaturedUpdate({required this.update, required this.onTap});

  final NewsSummary update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final imageUrl = update.thumbnailUrl?.trim();

    return Semantics(
      button: true,
      label: update.title,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? GBTImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        semanticLabel: update.title,
                      )
                    : const _FieldMapPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.all(GBTSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: GBTSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n(
                              ko: '최신 브리핑',
                              en: 'LATEST DISPATCH',
                              ja: '最新便り',
                            ),
                            style: GBTTypography.labelSmall.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        Text(
                          _dateLabel(context, update.publishedAt),
                          style: GBTTypography.labelSmall.copyWith(
                            color: isDark
                                ? GBTColors.darkTextSecondary
                                : GBTColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    Text(
                      update.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GBTTypography.titleMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
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

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update, required this.onTap});

  final NewsSummary update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final localDate = update.publishedAt.toLocal();

    return Semantics(
      button: true,
      label: update.title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      DateFormat(
                        'MMM',
                        _localeName(context),
                      ).format(localDate).toUpperCase(),
                      style: GBTTypography.labelSmall.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(localDate),
                      style: GBTTypography.titleMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Expanded(
                child: Text(
                  update.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Icon(Icons.arrow_outward_rounded, size: 20, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldMapPlaceholder extends StatelessWidget {
  const _FieldMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _RouteLinePainter(isDark: isDark)),
          Center(
            child: Icon(
              Icons.route_rounded,
              size: 44,
              color: isDark ? GBTColors.darkSecondary : GBTColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? GBTColors.darkBorder : GBTColors.border).withValues(
        alpha: 0.58,
      )
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 18.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final routePaint = Paint()
      ..color = isDark ? GBTColors.darkSecondary : GBTColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.22,
        size.width * 0.65,
        size.height * 0.9,
        size.width * 0.92,
        size.height * 0.18,
      );
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

class _UpdatesFailure extends StatelessWidget {
  const _UpdatesFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
        GBTSpacing.pageHorizontal,
        GBTSpacing.bottomNavClearanceOf(context),
      ),
      children: [GBTErrorState(message: message, onRetry: onRetry)],
    );
  }
}

class _UpdatesSkeleton extends StatelessWidget {
  const _UpdatesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.bottomNavClearanceOf(context),
      ),
      children: [
        GBTShimmer(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: GBTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: GBTSpacing.md),
        GBTShimmer(
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: GBTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
            ),
          ),
        ),
      ],
    );
  }
}

String _localeName(BuildContext context) {
  return Localizations.localeOf(context).toLanguageTag();
}

String _dateLabel(BuildContext context, DateTime date) {
  return DateFormat.yMMMd(_localeName(context)).format(date.toLocal());
}
