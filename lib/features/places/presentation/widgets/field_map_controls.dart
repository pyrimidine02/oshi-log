/// EN: Field-note controls for the clean-sheet places map.
/// KO: 새 장소 지도를 위한 필드 노트형 컨트롤입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../application/places_controller.dart';
import '../../domain/entities/place_entities.dart';

/// EN: One familiar 48dp search pill leaves the map as the primary surface.
/// KO: 익숙한 48dp 검색 필 하나로 지도를 주요 화면으로 남깁니다.
class FieldMapMissionStrip extends StatelessWidget {
  const FieldMapMissionStrip({
    super.key,
    required this.onLocalSearch,
    this.trailing,
  });

  final VoidCallback onLocalSearch;
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
    return SizedBox(
      key: const Key('field-map-mission-strip'),
      height: 48,
      child: Material(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.shadow.withValues(alpha: 0.14),
        clipBehavior: Clip.antiAlias,
        shape: const StadiumBorder(),
        child: Row(
          children: [
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
                        horizontal: GBTSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
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
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (trailing != null)
              SizedBox(width: 48, height: 48, child: Center(child: trailing)),
          ],
        ),
      ),
    );
  }
}

/// EN: Familiar horizontally scrolling filters used by mainstream map apps.
/// KO: 주요 지도 앱처럼 가로로 스크롤하는 필터입니다.
class FieldMapFilterChips extends StatelessWidget {
  const FieldMapFilterChips({
    super.key,
    required this.activeFilterCount,
    required this.projectLabel,
    required this.regionLabel,
    required this.bandLabel,
    required this.onFiltersTap,
    required this.onProjectTap,
    required this.onRegionTap,
    required this.onBandTap,
  });

  final int activeFilterCount;
  final String projectLabel;
  final String regionLabel;
  final String bandLabel;
  final VoidCallback onFiltersTap;
  final VoidCallback onProjectTap;
  final VoidCallback onRegionTap;
  final VoidCallback onBandTap;

  @override
  Widget build(BuildContext context) {
    final filterLabel = activeFilterCount > 0
        ? context.l10n(
            ko: '필터 $activeFilterCount',
            en: 'Filters $activeFilterCount',
            ja: 'フィルター $activeFilterCount',
          )
        : context.l10n(ko: '필터', en: 'Filters', ja: 'フィルター');

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MapFilterChip(
              chipKey: const Key('field-map-filter-all'),
              label: filterLabel,
              icon: Icons.tune_rounded,
              emphasized: activeFilterCount > 0,
              onPressed: onFiltersTap,
            ),
            const SizedBox(width: GBTSpacing.xs),
            _MapFilterChip(
              chipKey: const Key('field-map-filter-project'),
              label: projectLabel,
              onPressed: onProjectTap,
            ),
            const SizedBox(width: GBTSpacing.xs),
            _MapFilterChip(
              chipKey: const Key('field-map-filter-region'),
              label: regionLabel,
              onPressed: onRegionTap,
            ),
            const SizedBox(width: GBTSpacing.xs),
            _MapFilterChip(
              chipKey: const Key('field-map-filter-band'),
              label: bandLabel,
              onPressed: onBandTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
    required this.chipKey,
    required this.label,
    required this.onPressed,
    this.icon,
    this.emphasized = false,
  });

  final Key chipKey;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActionChip(
      key: chipKey,
      avatar: icon == null ? null : Icon(icon, size: 17),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 152),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      onPressed: onPressed,
      backgroundColor: emphasized ? colors.primaryContainer : colors.surface,
      side: BorderSide(
        color: emphasized ? colors.primary : colors.outlineVariant,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

/// EN: A plain value list for project, region, band, and result order.
/// KO: 프로젝트·지역·밴드·결과 순서를 보여주는 단순한 값 목록입니다.
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
    final textScaler = MediaQuery.textScalerOf(context);
    final cellHeight = (24 + textScaler.scale(24)).clamp(48.0, 96.0).toDouble();

    final ruleColor = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: cellHeight * 4,
      child: Material(
        key: const Key('field-map-index-ledger'),
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
          side: BorderSide(color: ruleColor),
        ),
        child: Column(
          children: [
            Expanded(
              child: _FieldMapIndexCell(
                key: const Key('field-map-index-project'),
                height: cellHeight,
                category: context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
                value: projectLabel,
                isActive: true,
                onTap: onProjectTap,
              ),
            ),
            _FieldMapIndexRule(color: ruleColor),
            Expanded(
              child: _FieldMapIndexCell(
                key: const Key('field-map-index-region'),
                height: cellHeight,
                category: context.l10n(ko: '지역', en: 'Region', ja: '地域'),
                value: regionLabel,
                isActive: hasRegionFilter,
                onTap: onRegionTap,
              ),
            ),
            _FieldMapIndexRule(color: ruleColor),
            Expanded(
              child: _FieldMapIndexCell(
                key: const Key('field-map-index-band'),
                height: cellHeight,
                category: context.l10n(ko: '밴드', en: 'Band', ja: 'バンド'),
                value: bandLabel,
                isActive: hasBandFilter,
                onTap: onBandTap,
              ),
            ),
            _FieldMapIndexRule(color: ruleColor),
            Expanded(
              child: _FieldMapIndexCell(
                key: const Key('field-map-index-mode'),
                height: cellHeight,
                category: context.l10n(ko: '목록 순서', en: 'Order', ja: '並び順'),
                value: modeLabel,
                isActive: mode == PlaceListMode.nearby,
                onTap: () => onModeChanged(
                  mode == PlaceListMode.nearby
                      ? PlaceListMode.all
                      : PlaceListMode.nearby,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldMapIndexRule extends StatelessWidget {
  const _FieldMapIndexRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('field-map-index-row-rule'),
      height: 0,
      child: OverflowBox(
        minHeight: 1,
        maxHeight: 1,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// EN: Horizontal result cards keep the map visible at peek and half heights.
/// KO: 가로 결과 카드로 피크·하프 높이에서도 지도를 보여줍니다.
class FieldMapPlaceCarousel extends StatelessWidget {
  const FieldMapPlaceCarousel({
    super.key,
    required this.places,
    required this.onOpen,
    required this.onDirections,
    this.selectedPlaceId,
  });

  final List<PlaceSummary> places;
  final String? selectedPlaceId;
  final ValueChanged<PlaceSummary> onOpen;
  final ValueChanged<PlaceSummary> onDirections;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final carouselHeight = (144 + ((textScale - 1) * 48)).clamp(144.0, 240.0);
    return SizedBox(
      key: const Key('field-map-place-carousel'),
      height: carouselHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 48).clamp(260.0, 320.0);
          return ListView.separated(
            key: ValueKey<String>(
              'field-map-place-carousel-${selectedPlaceId ?? 'default'}',
            ),
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(width: GBTSpacing.sm),
            itemBuilder: (context, index) {
              final place = places[index];
              return SizedBox(
                width: cardWidth,
                child: _FieldMapCarouselCard(
                  place: place,
                  selected: place.id == selectedPlaceId,
                  onOpen: () => onOpen(place),
                  onDirections: place.directions?.hasProviders == true
                      ? () => onDirections(place)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FieldMapCarouselCard extends StatelessWidget {
  const _FieldMapCarouselCard({
    required this.place,
    required this.selected,
    required this.onOpen,
    this.onDirections,
  });

  final PlaceSummary place;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final metadata = [
      place.address,
      place.distanceLabel,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    return Material(
      key: ValueKey<String>('field-map-carousel-card-${place.id}'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: double.infinity,
              child: place.imageUrl?.trim().isNotEmpty == true
                  ? GBTImage(
                      imageUrl: place.imageUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: place.name,
                    )
                  : ColoredBox(
                      color: colors.secondaryContainer,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(GBTSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (textScale < 1.6) ...[
                      Text(
                        context.l10n(
                          ko: '현장 기록',
                          en: 'FIELD NOTE',
                          ja: 'フィールドノート',
                        ),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.xs),
                    ],
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        metadata,
                        maxLines: textScale >= 1.6 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onDirections != null)
              IconButton(
                onPressed: onDirections,
                tooltip: context.l10n(ko: '길찾기', en: 'Directions', ja: '経路'),
                icon: const Icon(Icons.navigation_outlined),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: GBTSpacing.sm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// EN: Opens the scoped map filters as a familiar value-list sheet.
/// KO: 지도 필터를 익숙한 값 목록 시트로 엽니다.
Future<void> showFieldMapFilters({
  required BuildContext context,
  required String projectLabel,
  required String regionLabel,
  required String bandLabel,
  required PlaceListMode mode,
  required bool hasRegionFilter,
  required bool hasBandFilter,
  required VoidCallback onProjectTap,
  required VoidCallback onRegionTap,
  required VoidCallback onBandTap,
  required ValueChanged<PlaceListMode> onModeChanged,
  required VoidCallback onResetFilters,
}) {
  final title = context.l10n(ko: '지도 필터', en: 'Map filters', ja: '地図フィルター');
  final hasActiveFilters =
      hasRegionFilter || hasBandFilter || mode != PlaceListMode.all;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      void closeThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) => action());
      }

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            0,
            GBTSpacing.pageHorizontal,
            GBTSpacing.pageHorizontal +
                MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(sheetContext).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (hasActiveFilters)
                    TextButton(
                      onPressed: () => closeThen(onResetFilters),
                      child: Text(
                        sheetContext.l10n(ko: '초기화', en: 'Reset', ja: 'リセット'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: GBTSpacing.md),
              FieldMapFieldIndex(
                projectLabel: projectLabel,
                regionLabel: regionLabel,
                bandLabel: bandLabel,
                mode: mode,
                hasRegionFilter: hasRegionFilter,
                hasBandFilter: hasBandFilter,
                onProjectTap: () => closeThen(onProjectTap),
                onRegionTap: () => closeThen(onRegionTap),
                onBandTap: () => closeThen(onBandTap),
                onModeChanged: (nextMode) =>
                    closeThen(() => onModeChanged(nextMode)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FieldMapIndexCell extends StatelessWidget {
  const _FieldMapIndexCell({
    super.key,
    required this.height,
    required this.category,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  final double height;
  final String category;
  final String value;
  final bool isActive;
  final VoidCallback onTap;

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
          height: height,
          child: Ink(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 2,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Compact feedback for an empty map result inside the draggable sheet.
/// KO: 드래그 시트 안에서 빈 지도 결과를 간결하게 안내합니다.
class FieldMapEmptyResult extends StatelessWidget {
  const FieldMapEmptyResult({
    super.key,
    required this.hasActiveFilters,
    this.onResetFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = hasActiveFilters
        ? context.l10n(
            ko: '선택한 조건에 맞는 장소가 없습니다',
            en: 'No places match selected filters',
            ja: '選択した条件に一致する場所がありません',
          )
        : context.l10n(
            ko: '아직 등록된 장소가 없습니다',
            en: 'No places registered yet',
            ja: 'まだ登録された場所がありません',
          );
    final resetLabel = context.l10n(
      ko: '필터 초기화',
      en: 'Reset filters',
      ja: 'フィルタ初期化',
    );

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.sm,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  size: 20,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasActiveFilters && onResetFilters != null) ...[
              const SizedBox(width: GBTSpacing.xs),
              TextButton(onPressed: onResetFilters, child: Text(resetLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

/// EN: One current-location action avoids competing with map content.
/// KO: 현재 위치 액션 하나만 두어 지도 콘텐츠와의 경쟁을 줄입니다.
class FieldMapCanvasControls extends StatelessWidget {
  const FieldMapCanvasControls({super.key, required this.onCurrentLocation});

  final VoidCallback onCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
      child: Material(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.shadow.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: Icon(icon, color: colors.primary),
        ),
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
    required this.onCollapse,
    this.modeLabels = const [],
    this.selectedModeIndex = 0,
    this.onModeSelected,
    this.isCollapsed = true,
  });

  static const double height = 56;
  static const double modeHeight = 104;

  final int placeCount;
  final VoidCallback onCollapse;
  final List<String> modeLabels;
  final int selectedModeIndex;
  final ValueChanged<int>? onModeSelected;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countLabel = context.l10n(
      ko: '현장 목록 · $placeCount곳',
      en: 'Field ledger · $placeCount spots',
      ja: 'フィールド一覧 · $placeCount件',
    );
    final toggleLabel = isCollapsed
        ? context.l10n(ko: '목록 펼치기', en: 'Expand list', ja: 'リストを開く')
        : context.l10n(ko: '목록 접기', en: 'Collapse list', ja: 'リストを閉じる');

    return Semantics(
      container: true,
      explicitChildNodes: true,
      header: true,
      label: countLabel,
      child: SizedBox(
        height: modeLabels.isEmpty ? height : modeHeight,
        child: ColoredBox(
          color: colors.surface,
          child: Column(
            children: [
              const SizedBox(height: GBTSpacing.xs),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
              ),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(left: GBTSpacing.md),
                          child: Text(
                            countLabel,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      enabled: true,
                      label: toggleLabel,
                      onTap: onCollapse,
                      excludeSemantics: true,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: onCollapse,
                          tooltip: toggleLabel,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isCollapsed
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (modeLabels.isNotEmpty && onModeSelected != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    0,
                    GBTSpacing.md,
                    GBTSpacing.xs,
                  ),
                  child: SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      key: const Key('field-map-mode-switcher'),
                      showSelectedIcon: false,
                      segments: [
                        for (var index = 0; index < modeLabels.length; index++)
                          ButtonSegment<int>(
                            value: index,
                            label: Text(
                              modeLabels[index],
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                      ],
                      selected: {
                        selectedModeIndex.clamp(0, modeLabels.length - 1),
                      },
                      onSelectionChanged: (selection) =>
                          onModeSelected!(selection.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
                        ),
                        textStyle: WidgetStatePropertyAll(
                          Theme.of(context).textTheme.labelMedium,
                        ),
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
