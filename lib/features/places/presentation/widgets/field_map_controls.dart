/// EN: Field-note controls for the clean-sheet places map.
/// KO: 새 장소 지도를 위한 필드 노트형 컨트롤입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../application/places_controller.dart';

/// EN: A single 56dp mission strip replacing stacked map search chrome.
/// KO: 겹쳐 있던 지도 검색 크롬을 대체하는 단일 56dp 미션 스트립입니다.
class FieldMapMissionStrip extends StatelessWidget {
  const FieldMapMissionStrip({
    super.key,
    required this.placeCount,
    required this.onLocalSearch,
    required this.onUnifiedSearch,
    this.trailing,
  });

  final int placeCount;
  final VoidCallback onLocalSearch;
  final VoidCallback onUnifiedSearch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localLabel = context.l10n(
      ko: '장소·지역 찾기',
      en: 'Search this field map',
      ja: '場所・地域を検索',
    );
    final localSemanticLabel = context.l10n(
      ko: '지도 내 장소·지역 검색',
      en: 'Search places and regions on this map',
      ja: '地図内の場所・地域を検索',
    );
    final unifiedLabel = context.l10n(
      ko: '통합 검색',
      en: 'Unified search',
      ja: '統合検索',
    );
    final countLabel = context.l10n(
      ko: '$placeCount개 지점',
      en: '$placeCount spots',
      ja: '$placeCount件',
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SizedBox(
      key: const Key('field-map-mission-strip'),
      height: 56,
      child: Material(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.shadow.withValues(alpha: 0.16),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: 48,
                  height: 56,
                  child: ColoredBox(
                    color: colors.primary,
                    child: Icon(
                      Icons.route_outlined,
                      color: colors.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  enabled: true,
                  label: localSemanticLabel,
                  onTap: onLocalSearch,
                  child: ExcludeSemantics(
                    child: InkWell(
                      key: const Key('field-map-local-search'),
                      onTap: onLocalSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.md2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 19,
                              color: colors.primary,
                            ),
                            const SizedBox(width: GBTSpacing.sm),
                            Expanded(
                              child: Text(
                                localLabel,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (textScale <= 1.3) ...[
                              const SizedBox(width: GBTSpacing.sm),
                              Text(
                                countLabel.toUpperCase(),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _FieldMapStripAction(
                key: const Key('field-map-unified-search'),
                icon: Icons.manage_search_rounded,
                tooltip: unifiedLabel,
                onPressed: onUnifiedSearch,
              ),
              if (trailing != null)
                SizedBox(width: 48, height: 48, child: Center(child: trailing)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldMapStripAction extends StatelessWidget {
  const _FieldMapStripAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: true,
      label: tooltip,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.outlineVariant)),
            ),
            child: IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: Icon(icon, color: colors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: A ruled, horizontally scrollable index for project and map filters.
/// KO: 프로젝트와 지도 필터를 위한 가로 스크롤 눈금형 인덱스입니다.
class FieldMapFieldIndex extends StatelessWidget {
  const FieldMapFieldIndex({
    super.key,
    required this.projectLabel,
    required this.regionLabel,
    required this.bandLabel,
    required this.mode,
    required this.hasRegionFilter,
    required this.hasBandFilter,
    required this.onProjectTap,
    required this.onRegionTap,
    required this.onBandTap,
    required this.onModeChanged,
  });

  final String projectLabel;
  final String regionLabel;
  final String bandLabel;
  final PlaceListMode mode;
  final bool hasRegionFilter;
  final bool hasBandFilter;
  final VoidCallback onProjectTap;
  final VoidCallback onRegionTap;
  final VoidCallback onBandTap;
  final ValueChanged<PlaceListMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final modeLabel = mode == PlaceListMode.nearby
        ? context.l10n(ko: '주변 순', en: 'Nearby', ja: '周辺順')
        : context.l10n(ko: '전체', en: 'All', ja: 'すべて');

    return SizedBox(
      height: 49,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FieldMapIndexCell(
              key: const Key('field-map-index-project'),
              width: 148,
              number: '01',
              category: context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
              value: projectLabel,
              isActive: true,
              onTap: onProjectTap,
            ),
            _FieldMapIndexCell(
              key: const Key('field-map-index-region'),
              width: 124,
              number: '02',
              category: context.l10n(ko: '지역', en: 'Region', ja: '地域'),
              value: regionLabel,
              isActive: hasRegionFilter,
              onTap: onRegionTap,
            ),
            _FieldMapIndexCell(
              key: const Key('field-map-index-band'),
              width: 140,
              number: '03',
              category: context.l10n(ko: '밴드', en: 'Band', ja: 'バンド'),
              value: bandLabel,
              isActive: hasBandFilter,
              onTap: onBandTap,
            ),
            _FieldMapIndexCell(
              key: const Key('field-map-index-mode'),
              width: 116,
              number: '04',
              category: context.l10n(ko: '목록', en: 'Order', ja: '並び'),
              value: modeLabel,
              isActive: mode == PlaceListMode.nearby,
              showTrailingRule: false,
              onTap: () => onModeChanged(
                mode == PlaceListMode.nearby
                    ? PlaceListMode.all
                    : PlaceListMode.nearby,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldMapIndexCell extends StatelessWidget {
  const _FieldMapIndexCell({
    super.key,
    required this.width,
    required this.number,
    required this.category,
    required this.value,
    required this.isActive,
    required this.onTap,
    this.showTrailingRule = true,
  });

  final double width;
  final String number;
  final String category;
  final String value;
  final bool isActive;
  final VoidCallback onTap;
  final bool showTrailingRule;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: true,
      selected: isActive,
      label: '$category, $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: 49,
          child: Material(
            color: isActive ? colors.primaryContainer : colors.surface,
            child: InkWell(
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: showTrailingRule
                        ? BorderSide(color: colors.outlineVariant)
                        : BorderSide.none,
                    bottom: BorderSide(
                      color: isActive ? colors.primary : colors.outlineVariant,
                      width: isActive ? 3 : 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        number,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: GBTSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    height: 1,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              value,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Square map-canvas actions aligned like field instrument controls.
/// KO: 현장 계기판처럼 정렬된 각진 지도 캔버스 액션입니다.
class FieldMapCanvasControls extends StatelessWidget {
  const FieldMapCanvasControls({
    super.key,
    required this.onFitPlaces,
    required this.onCurrentLocation,
  });

  final VoidCallback onFitPlaces;
  final VoidCallback onCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.primary, width: 3),
            left: BorderSide(color: colors.outlineVariant),
            right: BorderSide(color: colors.outlineVariant),
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FieldMapCanvasAction(
              key: const Key('field-map-fit-places'),
              icon: Icons.zoom_out_map_rounded,
              tooltip: context.l10n(
                ko: '모든 장소 보기',
                en: 'Show all places',
                ja: 'すべての場所を見る',
              ),
              onPressed: onFitPlaces,
            ),
            Divider(height: 1, color: colors.outlineVariant),
            _FieldMapCanvasAction(
              key: const Key('field-map-current-location'),
              icon: Icons.my_location_rounded,
              tooltip: context.l10n(
                ko: '내 위치로 이동',
                en: 'Go to my location',
                ja: '現在地へ移動',
              ),
              onPressed: onCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldMapCanvasAction extends StatelessWidget {
  const _FieldMapCanvasAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(icon, color: colors.primary),
      ),
    );
  }
}

/// EN: Pinned ledger heading for the draggable places index.
/// KO: 드래그 가능한 장소 인덱스를 위한 고정 장부 헤더입니다.
class FieldMapLedgerHeader extends StatelessWidget {
  const FieldMapLedgerHeader({
    super.key,
    required this.placeCount,
    required this.hasActiveFilters,
    required this.onCollapse,
    this.onResetFilters,
  });

  static const double height = 56;

  final int placeCount;
  final bool hasActiveFilters;
  final VoidCallback onCollapse;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countLabel = context.l10n(
      ko: '현장 목록 · $placeCount곳',
      en: 'Field ledger · $placeCount spots',
      ja: 'フィールド一覧 · $placeCount件',
    );
    final resetLabel = context.l10n(
      ko: '필터 초기화',
      en: 'Reset filters',
      ja: 'フィルタをリセット',
    );
    final collapseLabel = context.l10n(
      ko: '목록 접기',
      en: 'Collapse list',
      ja: 'リストを閉じる',
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      header: true,
      label: countLabel,
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: colors.surface,
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: height,
                        child: ColoredBox(color: colors.primary),
                      ),
                      const SizedBox(width: GBTSpacing.md),
                      Text(
                        'MAP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: GBTSpacing.sm),
                      Expanded(
                        child: Text(
                          countLabel,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasActiveFilters && onResetFilters != null)
                Semantics(
                  button: true,
                  enabled: true,
                  label: resetLabel,
                  onTap: onResetFilters,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: onResetFilters,
                      tooltip: resetLabel,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.filter_alt_off_outlined,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              Semantics(
                button: true,
                enabled: true,
                label: collapseLabel,
                onTap: onCollapse,
                excludeSemantics: true,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: onCollapse,
                    tooltip: collapseLabel,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.onSurfaceVariant,
                    ),
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
