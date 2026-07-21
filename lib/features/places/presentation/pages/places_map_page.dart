/// EN: Places map page with map view and bottom sheet list
/// KO: 지도 뷰와 바텀시트 리스트를 포함한 장소 지도 페이지
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_map_styles.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/themed_builder.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/inputs/gbt_search_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../../projects/presentation/widgets/band_filter_sheet.dart';
import '../../../projects/presentation/widgets/field_project_picker_sheet.dart';
import '../../../visits/application/visits_controller.dart';
import '../../application/places_controller.dart';
import '../../domain/entities/place_entities.dart';
import '../../domain/entities/place_region_entities.dart';
import '../../domain/utils/place_distance_ordering.dart';
import '../../domain/utils/place_map_projection.dart';
import '../../domain/utils/place_marker_style.dart';
import '../../domain/utils/place_type_search.dart';
import '../../domain/utils/place_visit_status.dart';
import '../utils/place_directions_launcher.dart';
import '../widgets/field_map_controller_lease.dart';
import '../widgets/field_map_controls.dart';
import '../widgets/field_map_platform_gate.dart';
import '../widgets/field_place_sheet_row.dart';

/// EN: Places map page widget
/// KO: 장소 지도 페이지 위젯
class PlacesMapPage extends ConsumerStatefulWidget {
  const PlacesMapPage({
    super.key,
    this.embedded = false,
    this.isActive = true,
    this.topOverlayClearance = 0,
    this.bottomInset = 0,
    this.modeLabels = const [],
    this.selectedModeIndex = 0,
    this.onModeSelected,
  });

  /// EN: Hides duplicated shell actions when hosted by FieldExplorePage.
  /// KO: FieldExplorePage에 포함될 때 중복 셸 액션을 숨깁니다.
  final bool embedded;

  /// EN: Allows an embedded tab host to unmount the native platform map.
  /// KO: 포함한 탭 호스트가 네이티브 플랫폼 지도를 비활성화할 수 있습니다.
  final bool isActive;

  /// EN: Reserves map chrome space for a host-owned floating control.
  /// KO: 호스트가 소유한 플로팅 컨트롤을 위해 지도 크롬 여백을 둡니다.
  final double topOverlayClearance;

  /// EN: Keeps an embedded map sheet above host-owned bottom navigation.
  /// KO: 포함된 지도 시트를 호스트의 하단 내비게이션 위에 유지합니다.
  final double bottomInset;

  /// EN: Optional Explore destinations shown inside the map sheet, not canvas.
  /// KO: 지도 캔버스가 아닌 시트 안에 표시할 탐방 목적지입니다.
  final List<String> modeLabels;
  final int selectedModeIndex;
  final ValueChanged<int>? onModeSelected;

  @override
  ConsumerState<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends ConsumerState<PlacesMapPage> {
  static const double _sheetMinSize = 0.18;
  static const double _sheetHalfSize = 0.40;
  static const double _sheetMaxSize = 0.90;
  static const double _fullListThreshold = 0.72;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final FieldMapControllerLease<gmaps.GoogleMapController> _googleMapLease =
      FieldMapControllerLease<gmaps.GoogleMapController>();
  final FieldMapControllerLease<amaps.AppleMapController> _appleMapLease =
      FieldMapControllerLease<amaps.AppleMapController>();
  bool _didInitialCenter = false;
  bool _didCenterOnSafeDefault = false;
  double _currentZoom = 12;
  double _pendingZoom = 12;
  bool _centeringCallbackScheduled = false;
  bool _showFullPlaceList = false;
  bool _isSheetCollapsed = true;
  String? _selectedPlaceId;

  // EN: User's current location fetched on init.
  // KO: 초기화 시 가져온 사용자 현재 위치.
  _MapTarget? _userLocation;

  // EN: Place to center on when returning from detail page.
  // KO: 상세 페이지에서 돌아올 때 중앙에 놓을 장소.
  _MapTarget? _pendingCenterTarget;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_handleSheetSizeChange);
    _fetchInitialLocation();
    Future<void>.microtask(
      () => ref.read(userVisitsControllerProvider.notifier).load(),
    );
  }

  @override
  void didUpdateWidget(covariant PlacesMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _releaseNativeMapControllers();
    } else if (!oldWidget.isActive && widget.isActive) {
      _didInitialCenter = false;
    }
  }

  @override
  void dispose() {
    _sheetController.removeListener(_handleSheetSizeChange);
    _releaseNativeMapControllers();
    _sheetController.dispose();
    super.dispose();
  }

  /// EN: Fetches user location on startup and centers map.
  /// KO: 앱 시작 시 사용자 위치를 가져와 지도 중앙에 놓습니다.
  Future<void> _fetchInitialLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final snapshot = await locationService.getCurrentLocation();
      if (!mounted) return;
      final target = _MapTarget(snapshot.latitude, snapshot.longitude);
      setState(() => _userLocation = target);
      if (!_didInitialCenter || _didCenterOnSafeDefault) {
        _moveCameraTo(snapshot.latitude, snapshot.longitude, zoom: 14);
        _didInitialCenter = true;
        _didCenterOnSafeDefault = false;
      }
    } catch (_) {
      // EN: Location unavailable; fall back to places-based centering.
      // KO: 위치를 가져올 수 없으면 장소 기반 중심으로 대체합니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final placesState = ref.watch(placesListControllerProvider);
    final rawPlaces = placesState.maybeWhen(
      data: (items) => items,
      orElse: () => const <PlaceSummary>[],
    );
    final visits = ref.watch(userVisitsControllerProvider).valueOrNull;
    final visitedPlaceIds = Set<String>.unmodifiable(
      (visits ?? const []).map((visit) => visit.placeId),
    );
    final enrichedPlaces = applyVisitedPlaceIds(rawPlaces, visitedPlaceIds);
    // EN: Never present a fallback landmark as the user's real distance.
    //     Without permission, preserve the server's ordering and labels.
    // KO: 임의 기준점을 사용자의 실제 거리처럼 표시하지 않습니다.
    //     위치 권한이 없으면 서버 순서와 라벨을 유지합니다.
    final places = orderPlacesForUserLocation(
      enrichedPlaces,
      userLocation: _userLocation == null
          ? null
          : PlaceCoordinate(_userLocation!.latitude, _userLocation!.longitude),
    );
    final selectedPlace = resolveVisibleSelectedPlace(
      selectedPlaceId: _selectedPlaceId,
      visiblePlaces: places,
    );
    final carouselPlaces = selectedPlace == null
        ? places
        : List<PlaceSummary>.unmodifiable([
            selectedPlace,
            ...places.where((place) => place.id != selectedPlace.id),
          ]);
    final regionOptionsState = ref.watch(placesRegionOptionsControllerProvider);
    final selectedRegionCodes = ref.watch(selectedPlaceRegionCodesProvider);
    final selectedBandIds = ref.watch(selectedPlaceBandIdsProvider);
    final listMode = ref.watch(placeListModeProvider);
    final currentNavIndex = ref.watch(currentNavIndexProvider);
    ref.listen<int>(currentNavIndexProvider, (previous, next) {
      if (previous == NavIndex.explore && next != NavIndex.explore) {
        _releaseNativeMapControllers();
      } else if (previous != NavIndex.explore &&
          next == NavIndex.explore &&
          widget.isActive) {
        _didInitialCenter = false;
      }
    });
    final isTabActive = currentNavIndex == NavIndex.explore && widget.isActive;
    final projectKey = ref.watch(selectedProjectKeyProvider);
    final projectId = ref.watch(selectedProjectIdProvider);
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : (projectId ?? '');
    final unitsState = isTabActive && resolvedProjectKey.isNotEmpty
        ? ref.watch(projectUnitsControllerProvider(resolvedProjectKey))
        : const AsyncValue<List<Unit>>.data([]);
    final selectedRegionLabel = _resolveRegionLabel(
      regionOptionsState,
      selectedRegionCodes,
    );
    final selectedBandLabel = _resolveBandLabel(unitsState, selectedBandIds);
    final projectsState = ref.watch(projectsControllerProvider);
    final projectSelection = ref.watch(projectSelectionControllerProvider);
    final selectedProjectLabel = _resolveProjectLabel(
      projectsState,
      projectSelection,
    );
    final hasActiveFilters =
        selectedRegionCodes.isNotEmpty ||
        selectedBandIds.isNotEmpty ||
        listMode != PlaceListMode.all;
    final activeFilterCount =
        (selectedRegionCodes.isNotEmpty ? 1 : 0) +
        (selectedBandIds.isNotEmpty ? 1 : 0) +
        (listMode != PlaceListMode.all ? 1 : 0);
    // EN: Schedule camera centering after frame to avoid using
    //     a disposed GoogleMapController during build.
    // KO: 빌드 중 dispose된 GoogleMapController 사용을 방지하기 위해
    //     프레임 이후에 카메라 센터링을 예약합니다.
    _scheduleMaybeCenterOnMap(places, isTabActive: isTabActive);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final bottomInset = math.min(
            math.max(widget.bottomInset, 0.0),
            math.max(viewportHeight - 1.0, 0.0),
          );
          final interactiveViewportHeight = viewportHeight - bottomInset;
          final sheetHeaderHeight = widget.modeLabels.isEmpty
              ? FieldMapLedgerHeader.height
              : FieldMapLedgerHeader.modeHeight;
          final effectiveSheetMinSize = math.max(
            _sheetMinSize,
            ((sheetHeaderHeight + GBTSpacing.sm) / interactiveViewportHeight)
                .clamp(_sheetMinSize, 0.36),
          );
          return Stack(
            children: [
              // EN: Map view
              // KO: 지도 뷰
              Positioned.fill(
                child: KeyedSubtree(
                  key: const Key('field-map-canvas'),
                  child: _PlacesMapView(
                    places: places,
                    zoom: _currentZoom,
                    bottomPadding:
                        interactiveViewportHeight * effectiveSheetMinSize +
                        bottomInset,
                    isDarkMode: isDarkMode,
                    isTabActive: isTabActive,
                    initialTarget: _pendingCenterTarget ?? _userLocation,
                    onAppleMapCreated: (controller) {
                      _appleMapLease.attach(controller);
                      _maybeCenterOnMap(places);
                    },
                    onGoogleMapCreated: (controller) {
                      _googleMapLease.attach(controller);
                      _maybeCenterOnMap(places);
                    },
                    onCameraMove: _handleCameraMove,
                    onCameraIdle: _handleCameraIdle,
                    onClusterTap: _zoomToCluster,
                    onPlaceTap: _selectPlaceFromMap,
                    onMapUnavailable: _releaseNativeMapControllers,
                  ),
                ),
              ),
              // EN: Search and familiar filter chips are the only top chrome.
              // KO: 검색과 익숙한 필터 칩만 상단에 둡니다.
              Positioned(
                top: widget.topOverlayClearance,
                left: GBTSpacing.md,
                right: GBTSpacing.md,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: GBTSpacing.xs),
                      FieldMapMissionStrip(
                        onLocalSearch: () =>
                            _showMapSearch(places, regionOptionsState),
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                      FieldMapFilterChips(
                        activeFilterCount: activeFilterCount,
                        projectLabel: selectedProjectLabel,
                        regionLabel: selectedRegionLabel,
                        bandLabel: selectedBandLabel,
                        onFiltersTap: () => showFieldMapFilters(
                          context: context,
                          projectLabel: selectedProjectLabel,
                          regionLabel: selectedRegionLabel,
                          bandLabel: selectedBandLabel,
                          mode: listMode,
                          hasRegionFilter: selectedRegionCodes.isNotEmpty,
                          hasBandFilter: selectedBandIds.isNotEmpty,
                          onProjectTap: _showProjectPicker,
                          onRegionTap: () =>
                              _showRegionFilter(selectedRegionCodes),
                          onBandTap: () => _showBandFilter(selectedBandIds),
                          onModeChanged: (mode) =>
                              ref.read(placeListModeProvider.notifier).state =
                                  mode,
                          onResetFilters: _resetFilters,
                        ),
                        onProjectTap: _showProjectPicker,
                        onRegionTap: () =>
                            _showRegionFilter(selectedRegionCodes),
                        onBandTap: () => _showBandFilter(selectedBandIds),
                      ),
                    ],
                  ),
                ),
              ),

              // EN: Square instrument actions preserve 48dp hit areas.
              // KO: 각진 계기판 액션으로 48dp 터치 영역을 유지합니다.
              Positioned(
                right: GBTSpacing.md,
                bottom:
                    bottomInset +
                    interactiveViewportHeight * effectiveSheetMinSize +
                    GBTSpacing.md,
                child: SafeArea(
                  left: false,
                  top: false,
                  bottom: false,
                  child: FieldMapCanvasControls(
                    onCurrentLocation: _centerOnCurrentLocation,
                  ),
                ),
              ),

              // EN: Bottom sheet with places list
              // KO: 장소 리스트를 포함한 바텀시트
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: effectiveSheetMinSize,
                  minChildSize: effectiveSheetMinSize,
                  maxChildSize: _sheetMaxSize,
                  // EN: Snap to defined anchor points for a predictable, fluid feel.
                  // KO: 정해진 앵커 포인트에 스냅 — 예측 가능하고 부드러운 조작감.
                  snap: true,
                  snapSizes: [
                    effectiveSheetMinSize,
                    _sheetHalfSize,
                    _sheetMaxSize,
                  ],
                  builder: (context, scrollController) {
                    return Container(
                      key: const Key('field-map-sheet-surface'),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? GBTColors.darkSurface
                            : GBTColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: isDarkMode
                                ? GBTColors.darkBorder
                                : GBTColors.border,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDarkMode ? 0.32 : 0.08,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      // EN: CustomScrollView with pinned sticky header so the count
                      //     label + collapse button stay visible while the list scrolls.
                      // KO: SliverPersistentHeader로 헤더를 고정 — 리스트 스크롤 중에도
                      //     장소 개수와 닫기 버튼이 항상 보입니다.
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: RefreshIndicator(
                          key: const Key('field-map-sheet-safe-content'),
                          onRefresh: _refreshPlaces,
                          child: CustomScrollView(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _SheetStickyHeader(
                                  placeCount: places.length,
                                  modeLabels: widget.modeLabels,
                                  selectedModeIndex: widget.selectedModeIndex,
                                  onModeSelected: widget.onModeSelected,
                                  isCollapsed: _isSheetCollapsed,
                                  onCollapse: () =>
                                      _togglePlaceSheet(effectiveSheetMinSize),
                                ),
                              ),

                              if (!_showFullPlaceList && places.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: GBTSpacing.sm,
                                    ),
                                    child: FieldMapPlaceCarousel(
                                      places: carouselPlaces,
                                      selectedPlaceId: selectedPlace?.id,
                                      onOpen: _navigateToPlaceDetail,
                                      onDirections: _showDirectionsForPlace,
                                    ),
                                  ),
                                ),

                              // ── Place list ──
                              if (_showFullPlaceList || places.isEmpty)
                                _PlacesSliverList(
                                  state: placesState.whenData((_) => places),
                                  onRetry: () => ref
                                      .read(
                                        placesListControllerProvider.notifier,
                                      )
                                      .load(forceRefresh: true),
                                  onPlaceTap: _navigateToPlaceDetail,
                                  onDirectionsTap: _showDirectionsForPlace,
                                  hasActiveFilters: hasActiveFilters,
                                  onResetFilters: _resetFilters,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // EN: Keep a persistent sheet toggle so users can collapse/expand
              // from any scroll position in the list.
              // KO: 목록 스크롤 위치와 관계없이 즉시 내리고/올릴 수 있도록
              // 고정 시트 토글 버튼을 제공합니다.
            ],
          );
        },
      ),
    );
  }

  void _handleSheetSizeChange() {
    if (!_sheetController.isAttached || !mounted) return;
    final showFullPlaceList = _sheetController.size >= _fullListThreshold;
    final isSheetCollapsed = _sheetController.size < _sheetHalfSize - 0.02;
    if (showFullPlaceList == _showFullPlaceList &&
        isSheetCollapsed == _isSheetCollapsed) {
      return;
    }
    setState(() {
      _showFullPlaceList = showFullPlaceList;
      _isSheetCollapsed = isSheetCollapsed;
    });
  }

  /// EN: Centers map based on priority: pending target > user location > first place.
  /// KO: 우선순위에 따라 지도 중앙 설정: 대기 타겟 > 사용자 위치 > 첫 장소.
  void _maybeCenterOnMap(List<PlaceSummary> places) {
    if (kIsWeb) return;
    final canMove = _isAppleMap
        ? _appleMapLease.controller != null
        : _googleMapLease.controller != null;
    if (!canMove) return;

    // EN: Priority 1 — center on place from detail page return.
    // KO: 우선순위 1 — 상세 페이지에서 돌아온 경우 해당 장소 중앙.
    if (_pendingCenterTarget != null) {
      final target = _pendingCenterTarget!;
      _pendingCenterTarget = null;
      _moveCameraTo(target.latitude, target.longitude, zoom: 15);
      _didCenterOnSafeDefault = false;
      return;
    }

    if (_didInitialCenter) {
      // EN: Upgrade the emergency default once real project places arrive.
      // KO: 실제 프로젝트 장소가 도착하면 비상 기본 위치를 즉시 대체합니다.
      if (_didCenterOnSafeDefault && places.isNotEmpty) {
        final target = resolvePlaceMapCameraTarget(places: places);
        _moveCameraTo(target.latitude, target.longitude, zoom: 14);
        _didCenterOnSafeDefault = false;
      }
      return;
    }

    // EN: Priority 2 — center on user's current location.
    // KO: 우선순위 2 — 사용자 현재 위치 중앙.
    if (_userLocation != null) {
      _moveCameraTo(
        _userLocation!.latitude,
        _userLocation!.longitude,
        zoom: 14,
      );
      _didInitialCenter = true;
      _didCenterOnSafeDefault = false;
      return;
    }

    // EN: Priority 3 — first visible place; use the safe default only when
    //     the current projection is empty.
    // KO: 우선순위 3 — 현재 보이는 첫 번째 장소를 사용하고, 목록이
    //     빈 경우에만 안전 기본값을 사용합니다.
    final fallback = resolvePlaceMapCameraTarget(places: places);
    _moveCameraTo(
      fallback.latitude,
      fallback.longitude,
      zoom: fallback.source == PlaceMapTargetSource.place ? 14 : 12,
    );
    _didInitialCenter = true;
    _didCenterOnSafeDefault =
        fallback.source == PlaceMapTargetSource.safeDefault;
  }

  /// EN: Schedule map-centering once per frame to avoid callback pile-up.
  /// KO: 콜백 누적을 방지하기 위해 프레임당 1회만 지도 센터링을 예약합니다.
  void _scheduleMaybeCenterOnMap(
    List<PlaceSummary> places, {
    required bool isTabActive,
  }) {
    if (!isTabActive || _centeringCallbackScheduled) {
      return;
    }
    _centeringCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centeringCallbackScheduled = false;
      if (!mounted) return;
      _maybeCenterOnMap(places);
    });
  }

  void _handleCameraMove(double zoom) {
    _pendingZoom = zoom;
  }

  void _handleCameraIdle() {
    if ((_pendingZoom - _currentZoom).abs() >= 0.3) {
      setState(() => _currentZoom = _pendingZoom);
    }
  }

  /// EN: Saves place coordinates and navigates to detail page.
  /// KO: 장소 좌표를 저장하고 상세 페이지로 이동합니다.
  void _navigateToPlaceDetail(PlaceSummary place) {
    _pendingCenterTarget = _MapTarget(place.latitude, place.longitude);
    context.goToPlaceDetail(place.id);
  }

  /// EN: Marker taps select a place and reveal a preview before navigation.
  /// KO: 마커 탭은 바로 이동하지 않고 장소를 선택해 프리뷰를 먼저 표시합니다.
  void _selectPlaceFromMap(PlaceSummary place) {
    setState(() => _selectedPlaceId = place.id);
    if (_sheetController.isAttached) {
      unawaited(
        _sheetController.animateTo(
          _sheetHalfSize,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _showDirectionsForPlace(PlaceSummary place) async {
    final directions = place.directions;
    if (directions == null || !directions.hasProviders) return;
    await showPlaceDirectionsSheet(
      context,
      placeName: place.name,
      directions: directions,
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final snapshot = await locationService.getCurrentLocation();
      _moveCameraTo(snapshot.latitude, snapshot.longitude, zoom: 14);
    } catch (error) {
      if (!mounted) return;
      final message = error is Failure
          ? error.userMessage
          : context.l10n(
              ko: '현재 위치를 가져올 수 없습니다',
              en: 'Unable to get current location',
              ja: '現在地を取得できません',
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _moveCameraTo(double latitude, double longitude, {double zoom = 12}) {
    if (kIsWeb || !mounted) return;
    if (_isAppleMap) {
      unawaited(
        _safeAppleMapCall(
          (controller) => controller.moveCamera(
            amaps.CameraUpdate.newCameraPosition(
              amaps.CameraPosition(
                target: amaps.LatLng(latitude, longitude),
                zoom: zoom,
              ),
            ),
          ),
        ),
      );
      return;
    }
    unawaited(
      _safeGoogleMapCall(
        (controller) => controller.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: gmaps.LatLng(latitude, longitude),
              zoom: zoom,
            ),
          ),
        ),
      ),
    );
  }

  /// EN: Toggles the place list between compact and half detents.
  /// KO: 장소 목록을 컴팩트와 반 높이 사이에서 전환합니다.
  Future<void> _togglePlaceSheet(double minSize) async {
    if (!_sheetController.isAttached) {
      return;
    }
    await _sheetController.animateTo(
      _isSheetCollapsed ? _sheetHalfSize : minSize,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showPlaceInfoWindow(String placeId) async {
    if (kIsWeb || !mounted) return;
    if (_isAppleMap) {
      await _safeAppleMapCall(
        (controller) =>
            controller.showMarkerInfoWindow(amaps.AnnotationId(placeId)),
      );
      return;
    }
    await _safeGoogleMapCall(
      (controller) => controller.showMarkerInfoWindow(gmaps.MarkerId(placeId)),
    );
  }

  Future<void> _safeAppleMapCall(
    Future<void> Function(amaps.AppleMapController controller) call,
  ) {
    return _appleMapLease.run(call);
  }

  Future<void> _safeGoogleMapCall(
    Future<void> Function(gmaps.GoogleMapController controller) call,
  ) {
    return _googleMapLease.run(call);
  }

  /// EN: Invalidates controller fields before native platform disposal.
  /// KO: 네이티브 플랫폼 dispose 전에 컨트롤러 필드를 먼저 무효화합니다.
  void _releaseNativeMapControllers() {
    // EN: GoogleMap/AppleMap State owns platform disposal. Calling dispose
    //     here would race and double-dispose when the child unmounts.
    // KO: GoogleMap/AppleMap State가 플랫폼 dispose를 소유합니다.
    //     여기서 다시 호출하면 자식 unmount와 경합해 중복 dispose됩니다.
    _googleMapLease.release();
    _appleMapLease.release();
    _didInitialCenter = false;
  }

  RegionMapBounds? _buildBoundsFromPlaces(List<PlaceSummary> places) {
    if (places.isEmpty) return null;
    var minLat = places.first.latitude;
    var maxLat = places.first.latitude;
    var minLng = places.first.longitude;
    var maxLng = places.first.longitude;
    for (final place in places.skip(1)) {
      minLat = minLat < place.latitude ? minLat : place.latitude;
      maxLat = maxLat > place.latitude ? maxLat : place.latitude;
      minLng = minLng < place.longitude ? minLng : place.longitude;
      maxLng = maxLng > place.longitude ? maxLng : place.longitude;
    }
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    return RegionMapBounds(
      northEast: Coordinate(latitude: maxLat, longitude: maxLng),
      southWest: Coordinate(latitude: minLat, longitude: minLng),
      center: Coordinate(latitude: centerLat, longitude: centerLng),
      zoom: _currentZoom.round(),
    );
  }

  void _showRegionFilter(List<String> selectedCodes) {
    final projectKey = ref.read(selectedProjectKeyProvider);
    final projectId = ref.read(selectedProjectIdProvider);
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : projectId;
    if (resolvedProjectKey == null || resolvedProjectKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '프로젝트 선택 후 지역 필터를 사용할 수 있어요',
              en: 'Select a project to use region filters',
              ja: '地域フィルタはプロジェクト選択後に利用できます',
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RegionFilterSheet(
        initialSelectedCodes: selectedCodes,
        onApply: _applyRegions,
      ),
    );
  }

  void _applyRegions(List<String> regionCodes) {
    final uniqueCodes = regionCodes.toSet().toList(growable: false);
    ref.read(selectedPlaceRegionCodesProvider.notifier).state = uniqueCodes;
    _didInitialCenter = false;
    if (uniqueCodes.length == 1) {
      _moveCameraToRegion(uniqueCodes.first);
    }
  }

  Future<void> _moveCameraToRegion(String regionCode) async {
    final projectKey = ref.read(selectedProjectKeyProvider);
    final projectId = ref.read(selectedProjectIdProvider);
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : projectId;
    if (resolvedProjectKey == null || resolvedProjectKey.isEmpty) return;

    final repository = await ref.read(placesRepositoryProvider.future);
    var result = await repository.getRegionMapBounds(
      projectId: resolvedProjectKey,
      regionCode: regionCode,
    );
    if (result is Err<RegionMapBounds> &&
        projectId != null &&
        projectId.isNotEmpty &&
        projectId != resolvedProjectKey) {
      result = await repository.getRegionMapBounds(
        projectId: projectId,
        regionCode: regionCode,
      );
    }

    if (result is Success<RegionMapBounds>) {
      _moveCameraToBounds(result.data);
    }
  }

  void _moveCameraToBounds(RegionMapBounds bounds) {
    if (kIsWeb || !mounted) return;
    const padding = 48.0;
    if (_isAppleMap) {
      unawaited(
        _safeAppleMapCall(
          (controller) => controller.moveCamera(
            amaps.CameraUpdate.newLatLngBounds(
              amaps.LatLngBounds(
                southwest: amaps.LatLng(
                  bounds.southWest.latitude,
                  bounds.southWest.longitude,
                ),
                northeast: amaps.LatLng(
                  bounds.northEast.latitude,
                  bounds.northEast.longitude,
                ),
              ),
              padding,
            ),
          ),
        ),
      );
      return;
    }
    unawaited(
      _safeGoogleMapCall(
        (controller) => controller.animateCamera(
          gmaps.CameraUpdate.newLatLngBounds(
            gmaps.LatLngBounds(
              southwest: gmaps.LatLng(
                bounds.southWest.latitude,
                bounds.southWest.longitude,
              ),
              northeast: gmaps.LatLng(
                bounds.northEast.latitude,
                bounds.northEast.longitude,
              ),
            ),
            padding,
          ),
        ),
      ),
    );
  }

  void _zoomToCluster(_MapCluster cluster) {
    if (cluster.places.length == 1) return;
    final bounds = _buildBoundsFromPlaces(cluster.places);
    if (bounds != null) {
      _moveCameraToBounds(bounds);
      return;
    }
    _moveCameraTo(cluster.latitude, cluster.longitude, zoom: _currentZoom + 2);
  }

  void _resetFilters() {
    _didInitialCenter = false;
    ref.read(placesListControllerProvider.notifier).resetFilters();
  }

  void _showBandFilter(List<String> selectedBandIds) {
    final projectKey = ref.read(selectedProjectKeyProvider);
    final projectId = ref.read(selectedProjectIdProvider);
    final resolvedProjectKey = projectKey?.isNotEmpty == true
        ? projectKey!
        : (projectId ?? '');
    if (resolvedProjectKey.isEmpty) return;

    showBandFilterSheet(
      context: context,
      ref: ref,
      projectKey: resolvedProjectKey,
      selectedBandIds: selectedBandIds,
      onApply: (ids) {
        ref.read(selectedPlaceBandIdsProvider.notifier).state = ids;
      },
    );
  }

  Future<void> _refreshPlaces() async {
    _didInitialCenter = false;
    await Future.wait([
      ref.read(placesListControllerProvider.notifier).load(forceRefresh: true),
      ref
          .read(placesRegionOptionsControllerProvider.notifier)
          .load(forceRefresh: true),
    ]);
  }

  void _showMapSearch(
    List<PlaceSummary> places,
    AsyncValue<RegionFilterOptions> regionOptionsState,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FieldMapSearchSheet(
          places: places,
          regionOptionsState: regionOptionsState,
          onSelectPlace: (place) {
            _moveCameraTo(place.latitude, place.longitude, zoom: 15);
            unawaited(_showPlaceInfoWindow(place.id));
          },
          onSelectRegion: (region) {
            _applyRegions(<String>[region.code]);
          },
        );
      },
    );
  }

  String _resolveProjectLabel(
    AsyncValue<List<Project>> projectsState,
    ProjectSelectionState selection,
  ) {
    return projectsState.maybeWhen(
      data: (projects) {
        if (projects.isEmpty) {
          return context.l10n(
            ko: '프로젝트 선택',
            en: 'Select project',
            ja: 'プロジェクト選択',
          );
        }
        final selected = projects.cast<Project?>().firstWhere(
          (project) =>
              project?.code == selection.projectKey ||
              project?.id == selection.projectKey,
          orElse: () => projects.first,
        );
        return selected?.name ?? projects.first.name;
      },
      orElse: () => context.l10n(ko: '프로젝트', en: 'Project', ja: 'プロジェクト'),
    );
  }

  Future<void> _showProjectPicker() async {
    final projects = ref.read(projectsControllerProvider).valueOrNull;
    if (projects == null || projects.isEmpty) return;
    final selection = ref.read(projectSelectionControllerProvider);
    final selected = projects.firstWhere(
      (project) =>
          project.code == selection.projectKey ||
          project.id == selection.projectKey,
      orElse: () => projects.first,
    );
    final picked = await showFieldProjectPicker(
      context: context,
      projects: projects,
      selectedProject: selected,
    );
    if (picked == null || !mounted) return;
    final key = picked.code.isNotEmpty ? picked.code : picked.id;
    await ref
        .read(projectSelectionControllerProvider.notifier)
        .selectProject(key, projectId: picked.id);
  }

  String _resolveRegionLabel(
    AsyncValue<RegionFilterOptions> optionsState,
    List<String> selectedCodes,
  ) {
    if (selectedCodes.isEmpty) {
      return context.l10n(ko: '전체 지역', en: 'All regions', ja: '全地域');
    }
    return optionsState.maybeWhen(
      data: (options) {
        final allOptions = [...options.popularRegions, ...options.countries];
        final names = <String>[];
        final seen = <String>{};
        for (final code in selectedCodes) {
          if (!seen.add(code)) continue;
          final match = allOptions.cast<RegionOption?>().firstWhere(
            (option) => option?.code == code,
            orElse: () => null,
          );
          if (match != null) {
            names.add(match.name);
          }
        }
        if (names.isEmpty) {
          return context.l10n(
            ko: '지역 ${selectedCodes.length}개',
            en: '${selectedCodes.length} regions',
            ja: '地域 ${selectedCodes.length}件',
          );
        }
        if (names.length == 1) {
          return names.first;
        }
        return context.l10n(
          ko: '${names.first} 외 ${names.length - 1}',
          en: '${names.first} + ${names.length - 1} more',
          ja: '${names.first} ほか ${names.length - 1}件',
        );
      },
      orElse: () => context.l10n(
        ko: '지역 ${selectedCodes.length}개',
        en: '${selectedCodes.length} regions',
        ja: '地域 ${selectedCodes.length}件',
      ),
    );
  }

  String _resolveBandLabel(
    AsyncValue<List<Unit>> unitsState,
    List<String> selectedBandIds,
  ) {
    if (selectedBandIds.isEmpty) {
      return context.l10n(ko: '전체 밴드', en: 'All bands', ja: '全バンド');
    }

    return unitsState.maybeWhen(
      data: (units) {
        final names = units
            .where((unit) => selectedBandIds.contains(unit.id))
            .map(
              (unit) =>
                  unit.displayName.isNotEmpty ? unit.displayName : unit.code,
            )
            .toList();
        if (names.isEmpty) {
          return context.l10n(
            ko: '밴드 ${selectedBandIds.length}개',
            en: '${selectedBandIds.length} bands',
            ja: 'バンド ${selectedBandIds.length}件',
          );
        }
        if (names.length == 1) {
          return names.first;
        }
        return context.l10n(
          ko: '${names.first} 외 ${names.length - 1}',
          en: '${names.first} + ${names.length - 1} more',
          ja: '${names.first} ほか ${names.length - 1}件',
        );
      },
      orElse: () => context.l10n(
        ko: '밴드 ${selectedBandIds.length}개',
        en: '${selectedBandIds.length} bands',
        ja: 'バンド ${selectedBandIds.length}件',
      ),
    );
  }

  bool get _isAppleMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

class _PlacesSliverList extends StatelessWidget {
  const _PlacesSliverList({
    required this.state,
    required this.onRetry,
    required this.onPlaceTap,
    required this.onDirectionsTap,
    this.hasActiveFilters = false,
    this.onResetFilters,
  });

  final AsyncValue<List<PlaceSummary>> state;
  final VoidCallback onRetry;
  final ValueChanged<PlaceSummary> onPlaceTap;
  final ValueChanged<PlaceSummary> onDirectionsTap;
  final bool hasActiveFilters;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    return state.when(
      // EN: Shimmer skeleton — matches GBTPlaceCardHorizontal shape exactly.
      // KO: 쉬머 스켈레톤 — GBTPlaceCardHorizontal 형태와 정확히 일치.
      loading: () => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          GBTSpacing.sm,
          GBTSpacing.md,
          GBTSpacing.xl,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
              child: const GBTPlaceCardSkeleton(),
            ),
            childCount: 5,
          ),
        ),
      ),
      error: (error, _) {
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '장소 정보를 불러오지 못했어요',
                en: 'Failed to load place information',
                ja: '場所情報を読み込めませんでした',
              );
        return SliverToBoxAdapter(
          child: Padding(
            padding: GBTSpacing.paddingHorizontalMd,
            child: Column(
              children: [
                const SizedBox(height: GBTSpacing.lg),
                GBTErrorState(message: message, onRetry: onRetry),
              ],
            ),
          ),
        );
      },
      data: (places) {
        if (places.isEmpty) {
          return SliverToBoxAdapter(
            child: FieldMapEmptyResult(
              hasActiveFilters: hasActiveFilters,
              onResetFilters: onResetFilters,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            top: GBTSpacing.sm,
            bottom: GBTSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final place = places[index];
              final typeLabels = _placeTypeLabels(place.types);
              return FieldPlaceSheetRow(
                name: place.name,
                address: place.address,
                imageUrl: place.imageUrl,
                distanceLabel: place.distanceLabel,
                typeLabel: typeLabels.isEmpty ? null : typeLabels.first,
                isVisited: place.isVerified,
                onTap: () => onPlaceTap(place),
                onDirections: place.directions?.hasProviders == true
                    ? () => onDirectionsTap(place)
                    : null,
              );
            }, childCount: places.length),
          ),
        );
      },
    );
  }
}

class _PlacesMapView extends StatelessWidget {
  const _PlacesMapView({
    required this.places,
    required this.zoom,
    required this.bottomPadding,
    required this.isDarkMode,
    required this.isTabActive,
    required this.onAppleMapCreated,
    required this.onGoogleMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onClusterTap,
    required this.onPlaceTap,
    required this.onMapUnavailable,
    this.initialTarget,
  });

  final List<PlaceSummary> places;
  final double zoom;
  final double bottomPadding;
  final bool isDarkMode;
  final bool isTabActive;
  final ValueChanged<amaps.AppleMapController> onAppleMapCreated;
  final ValueChanged<gmaps.GoogleMapController> onGoogleMapCreated;
  final ValueChanged<double> onCameraMove;
  final VoidCallback onCameraIdle;
  final ValueChanged<_MapCluster> onClusterTap;
  final ValueChanged<PlaceSummary> onPlaceTap;
  final VoidCallback onMapUnavailable;

  /// EN: Optional override for the initial camera target.
  /// KO: 초기 카메라 타겟 오버라이드 (선택적).
  final _MapTarget? initialTarget;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    // EN: Keep map alive while popup routes (bottom sheets/dialogs) are shown.
    // KO: 바텀시트/다이얼로그 같은 팝업 라우트 표시 중에는 지도를 유지합니다.
    final isOffstageRoute = route?.offstage ?? false;
    if (!shouldRenderFieldMap(
      isActive: isTabActive,
      isRouteOffstage: isOffstageRoute,
    )) {
      // EN: Clear the parent lease before this native child unmounts.
      // KO: 이 네이티브 자식이 unmount되기 전에 부모 리스를 제거합니다.
      onMapUnavailable();
      return const SizedBox.shrink();
    }
    if (kIsWeb) {
      return _MapFallback(
        message: context.l10n(
          ko: '웹에서는 지도 기능을 지원하지 않습니다',
          en: 'Map is not supported on web',
          ja: 'Webでは地図機能をサポートしていません',
        ),
      );
    }

    final target = _initialTarget(places);
    final clusters = _clusterPlaces(places, zoom);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final appleMap = amaps.AppleMap(
        initialCameraPosition: amaps.CameraPosition(
          target: amaps.LatLng(target.latitude, target.longitude),
          zoom: 12,
        ),
        onMapCreated: onAppleMapCreated,
        onCameraMove: (position) => onCameraMove(position.zoom),
        onCameraIdle: onCameraIdle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        annotations: _buildAppleAnnotations(clusters, onPlaceTap, onClusterTap),
        padding: EdgeInsets.only(bottom: bottomPadding),
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          appleMap,
          IgnorePointer(
            child: ColoredBox(
              color: gbtAppleMapOverlayColorForDarkMode(isDarkMode),
            ),
          ),
        ],
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(target.latitude, target.longitude),
        zoom: 12,
      ),
      onMapCreated: onGoogleMapCreated,
      onCameraMove: (position) => onCameraMove(position.zoom),
      onCameraIdle: onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      zoomControlsEnabled: false,
      style: gbtGoogleMapStyleForDarkMode(isDarkMode),
      markers: _buildGoogleMarkers(clusters, onPlaceTap, onClusterTap),
      padding: EdgeInsets.only(bottom: bottomPadding),
    );
  }

  _MapTarget _initialTarget(List<PlaceSummary> places) {
    if (initialTarget != null) return initialTarget!;
    final target = resolvePlaceMapCameraTarget(places: places);
    return _MapTarget(target.latitude, target.longitude);
  }

  Set<gmaps.Marker> _buildGoogleMarkers(
    List<_MapCluster> clusters,
    ValueChanged<PlaceSummary> onPlaceTap,
    ValueChanged<_MapCluster> onClusterTap,
  ) {
    return clusters
        .map(
          (cluster) => gmaps.Marker(
            markerId: gmaps.MarkerId(cluster.markerId),
            position: gmaps.LatLng(cluster.latitude, cluster.longitude),
            infoWindow: gmaps.InfoWindow(title: cluster.title),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              cluster.isCluster
                  ? placeClusterMarkerHue
                  : placeMarkerHueForVisit(
                      isVerified: cluster.places.first.isVerified,
                    ),
            ),
            onTap: () {
              if (cluster.isCluster) {
                onClusterTap(cluster);
              } else {
                onPlaceTap(cluster.places.first);
              }
            },
          ),
        )
        .toSet();
  }

  Set<amaps.Annotation> _buildAppleAnnotations(
    List<_MapCluster> clusters,
    ValueChanged<PlaceSummary> onPlaceTap,
    ValueChanged<_MapCluster> onClusterTap,
  ) {
    return clusters
        .map(
          (cluster) => amaps.Annotation(
            annotationId: amaps.AnnotationId(cluster.markerId),
            position: amaps.LatLng(cluster.latitude, cluster.longitude),
            infoWindow: amaps.InfoWindow(title: cluster.title),
            icon: amaps.BitmapDescriptor.defaultAnnotationWithHue(
              cluster.isCluster
                  ? placeClusterMarkerHue
                  : placeMarkerHueForVisit(
                      isVerified: cluster.places.first.isVerified,
                    ),
            ),
            onTap: () {
              if (cluster.isCluster) {
                onClusterTap(cluster);
              } else {
                onPlaceTap(cluster.places.first);
              }
            },
          ),
        )
        .toSet();
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              message,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTarget {
  const _MapTarget(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class _RegionFilterSheet extends ConsumerStatefulWidget {
  const _RegionFilterSheet({
    required this.initialSelectedCodes,
    required this.onApply,
  });

  final List<String> initialSelectedCodes;
  final ValueChanged<List<String>> onApply;

  @override
  ConsumerState<_RegionFilterSheet> createState() => _RegionFilterSheetState();
}

class _RegionFilterSheetState extends ConsumerState<_RegionFilterSheet> {
  late Set<String> _draftCodes;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _draftCodes = widget.initialSelectedCodes.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RegionOption> _dedupeRegionOptions(Iterable<RegionOption> options) {
    final unique = <String, RegionOption>{};
    for (final option in options) {
      unique.putIfAbsent(option.code, () => option);
    }
    return unique.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final optionsState = ref.watch(placesRegionOptionsControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.md),
        child: optionsState.when(
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetTitleRow(
                title: context.l10n(
                  ko: '지역 선택',
                  en: 'Select regions',
                  ja: '地域選択',
                ),
              ),
              const SizedBox(height: GBTSpacing.md),
              GBTLoading(
                message: context.l10n(
                  ko: '지역 정보를 불러오는 중...',
                  en: 'Loading region information...',
                  ja: '地域情報を読み込み中...',
                ),
              ),
              const SizedBox(height: GBTSpacing.md),
            ],
          ),
          error: (error, _) {
            final message = error is Failure
                ? error.userMessage
                : context.l10n(
                    ko: '지역 정보를 불러오지 못했어요',
                    en: 'Failed to load region information',
                    ja: '地域情報を読み込めませんでした',
                  );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetTitleRow(
                  title: context.l10n(
                    ko: '지역 선택',
                    en: 'Select regions',
                    ja: '地域選択',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  message,
                  style: GBTTypography.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextButton(
                  onPressed: () => ref
                      .read(placesRegionOptionsControllerProvider.notifier)
                      .load(forceRefresh: true),
                  child: Text(
                    context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                  ),
                ),
              ],
            );
          },
          data: (options) {
            if (options.countries.isEmpty && options.popularRegions.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetTitleRow(
                    title: context.l10n(
                      ko: '지역 선택',
                      en: 'Select regions',
                      ja: '地域選択',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.lg),
                  Text(
                    context.l10n(
                      ko: '현재 프로젝트의 지역 정보가 없습니다',
                      en: 'No region information for current project',
                      ja: '現在のプロジェクトに地域情報がありません',
                    ),
                    style: GBTTypography.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GBTSpacing.md),
                ],
              );
            }
            final allOptions = _dedupeRegionOptions([
              ...options.popularRegions,
              ...options.countries,
            ]);
            final query = _query.trim();
            final filtered = query.isEmpty
                ? allOptions
                : allOptions
                      .where(
                        (o) =>
                            normalizedContains(o.name, query) ||
                            normalizedContains(o.code, query),
                      )
                      .toList(growable: false);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetTitleRow(
                  title: context.l10n(
                    ko: '지역 선택',
                    en: 'Select regions',
                    ja: '地域選択',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                GBTSearchBar(
                  controller: _searchController,
                  hint: context.l10n(
                    ko: '지역명 검색',
                    en: 'Search region name',
                    ja: '地域名検索',
                  ),
                  onChanged: (val) => setState(() => _query = val),
                  onClear: () => setState(() {
                    _query = '';
                    _searchController.clear();
                  }),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      return _RegionOptionTile(
                        option: option,
                        selected: _draftCodes.contains(option.code),
                        onChanged: (selected) {
                          setState(() {
                            if (selected) {
                              _draftCodes.add(option.code);
                            } else {
                              _draftCodes.remove(option.code);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _draftCodes.isEmpty
                            ? null
                            : () => setState(() => _draftCodes.clear()),
                        child: Text(
                          context.l10n(ko: '초기화', en: 'Reset', ja: 'リセット'),
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(_draftCodes.toList());
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          _draftCodes.isEmpty
                              ? context.l10n(
                                  ko: '전체 보기',
                                  en: 'Show all',
                                  ja: 'すべて表示',
                                )
                              : context.l10n(
                                  ko: '적용 (${_draftCodes.length})',
                                  en: 'Apply (${_draftCodes.length})',
                                  ja: '適用 (${_draftCodes.length})',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegionOptionTile extends StatelessWidget {
  const _RegionOptionTile({
    required this.option,
    required this.selected,
    required this.onChanged,
  });

  final RegionOption option;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      context.l10n(
        ko: '장소 ${option.placeCount}개',
        en: '${option.placeCount} places',
        ja: '場所 ${option.placeCount}件',
      ),
      if (option.hasChildren)
        context.l10n(ko: '하위 포함', en: 'Includes subregions', ja: '下位含む'),
    ].join(' · ');
    final leftPadding = GBTSpacing.sm + math.min(option.level * 10.0, 30.0);

    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.only(left: leftPadding, right: GBTSpacing.md),
      dense: true,
      title: Text(option.name),
      subtitle: Text(
        metadata,
        style: GBTTypography.labelSmall.copyWith(color: context.textTertiary),
      ),
    );
  }
}

class FieldMapSearchSheet extends StatefulWidget {
  const FieldMapSearchSheet({
    super.key,
    required this.places,
    required this.regionOptionsState,
    required this.onSelectPlace,
    required this.onSelectRegion,
  });

  final List<PlaceSummary> places;
  final AsyncValue<RegionFilterOptions> regionOptionsState;
  final ValueChanged<PlaceSummary> onSelectPlace;
  final ValueChanged<RegionOption> onSelectRegion;

  @override
  State<FieldMapSearchSheet> createState() => _FieldMapSearchSheetState();
}

class _FieldMapSearchSheetState extends State<FieldMapSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  bool _matchesPlaceQuery(PlaceSummary place, String query) {
    return normalizedContains(place.name, query) ||
        normalizedContains(place.address, query) ||
        matchesPlaceTypeQuery(query: query, types: place.types);
  }

  String _placeSubtitle(PlaceSummary place) {
    final typeLabels = place.types
        .map(placeTypeLabel)
        .where((label) => label.isNotEmpty)
        .take(2)
        .toList();
    final tagLabels = place.tags
        .where((tag) => tag.trim().isNotEmpty)
        .take(2)
        .map((tag) => '#${tag.trim()}')
        .toList();
    final labels = [...typeLabels, ...tagLabels];
    if (labels.isEmpty) {
      return place.address;
    }
    return '${place.address} · ${labels.join(', ')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final query = _query.trim();
    final placeResults = query.isEmpty
        ? <PlaceSummary>[]
        : widget.places
              .where((place) => _matchesPlaceQuery(place, query))
              .take(30)
              .toList();

    final regionResults = widget.regionOptionsState.maybeWhen(
      data: (options) {
        if (query.isEmpty) return <RegionOption>[];
        final all = [...options.popularRegions, ...options.countries];
        return all
            .where((option) => normalizedContains(option.name, query))
            .take(30)
            .toList();
      },
      orElse: () => <RegionOption>[],
    );

    return FractionallySizedBox(
      key: const Key('field-map-search-sheet'),
      heightFactor: 0.82,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          child: Column(
            children: [
              SizedBox(
                key: const Key('field-map-search-field-frame'),
                height: GBTSpacing.touchTarget,
                child: GBTSearchBar(
                  controller: _controller,
                  hint: context.l10n(
                    ko: '장소/유형/지역 검색',
                    en: 'Search places/types/regions',
                    ja: '場所/タイプ/地域を検索',
                  ),
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() => _query = ''),
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Expanded(
                child: ListView(
                  key: const Key('field-map-search-results'),
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.viewInsetsOf(context).bottom + GBTSpacing.md,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (widget.regionOptionsState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: GBTSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (query.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: GBTSpacing.md,
                        ),
                        child: Text(
                          context.l10n(
                            ko: '지역, 장소 이름, 장소 유형을 입력하세요',
                            en: 'Enter a region, place name, or place type',
                            ja: '地域、場所名、場所タイプを入力してください',
                          ),
                          style: GBTTypography.bodyMedium.copyWith(
                            color: secondaryColor,
                          ),
                        ),
                      )
                    else ...[
                      if (regionResults.isNotEmpty) ...[
                        _MapSearchResultHeading(
                          label: context.l10n(ko: '지역', en: 'Region', ja: '地域'),
                        ),
                        ...regionResults.map(
                          (option) => ListTile(
                            title: Text(option.name),
                            subtitle: Text(
                              context.l10n(
                                ko: '장소 ${option.placeCount}개',
                                en: '${option.placeCount} places',
                                ja: '場所 ${option.placeCount}件',
                              ),
                            ),
                            onTap: () {
                              widget.onSelectRegion(option);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                      if (placeResults.isNotEmpty) ...[
                        _MapSearchResultHeading(
                          label: context.l10n(ko: '장소', en: 'Places', ja: '場所'),
                        ),
                        ...placeResults.map(
                          (place) => ListTile(
                            title: Text(place.name),
                            subtitle: Text(_placeSubtitle(place)),
                            onTap: () {
                              widget.onSelectPlace(place);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                      if (regionResults.isEmpty && placeResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: GBTSpacing.md,
                          ),
                          child: Text(
                            context.l10n(
                              ko: '검색 결과가 없습니다',
                              en: 'No search results',
                              ja: '検索結果がありません',
                            ),
                            style: GBTTypography.bodyMedium.copyWith(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                    ],
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

class _MapSearchResultHeading extends StatelessWidget {
  const _MapSearchResultHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.sm, bottom: GBTSpacing.xs),
      child: Text(
        label,
        style: GBTTypography.labelMedium.copyWith(color: context.textSecondary),
      ),
    );
  }
}

class _MapCluster {
  const _MapCluster({
    required this.places,
    required this.latitude,
    required this.longitude,
    required this.markerId,
  });

  final List<PlaceSummary> places;
  final double latitude;
  final double longitude;
  final String markerId;

  bool get isCluster => places.length > 1;

  String get title => isCluster ? '${places.length}' : places.first.name;
}

List<_MapCluster> _clusterPlaces(List<PlaceSummary> places, double zoom) {
  if (places.isEmpty) return const [];
  final grid = _clusterGridSize(zoom);
  if (grid <= 0) {
    return places
        .map(
          (place) => _MapCluster(
            places: [place],
            latitude: place.latitude,
            longitude: place.longitude,
            markerId: place.id,
          ),
        )
        .toList();
  }

  final buckets = <String, List<PlaceSummary>>{};
  for (final place in places) {
    final latKey = (place.latitude / grid).round();
    final lngKey = (place.longitude / grid).round();
    final key = '$latKey:$lngKey';
    buckets.putIfAbsent(key, () => <PlaceSummary>[]).add(place);
  }

  final clusters = <_MapCluster>[];
  var index = 0;
  for (final entry in buckets.entries) {
    final group = entry.value;
    if (group.length == 1) {
      final place = group.first;
      clusters.add(
        _MapCluster(
          places: group,
          latitude: place.latitude,
          longitude: place.longitude,
          markerId: place.id,
        ),
      );
      continue;
    }
    final averageLat =
        group.map((place) => place.latitude).reduce((a, b) => a + b) /
        group.length;
    final averageLng =
        group.map((place) => place.longitude).reduce((a, b) => a + b) /
        group.length;
    clusters.add(
      _MapCluster(
        places: group,
        latitude: averageLat,
        longitude: averageLng,
        markerId: 'cluster_${index++}',
      ),
    );
  }
  return clusters;
}

double _clusterGridSize(double zoom) {
  if (zoom >= 15) return 0;
  if (zoom >= 13) return 0.01;
  if (zoom >= 11) return 0.02;
  if (zoom >= 9) return 0.05;
  return 0.1;
}

class _SheetStickyHeader extends SliverPersistentHeaderDelegate {
  const _SheetStickyHeader({
    required this.placeCount,
    required this.onCollapse,
    required this.modeLabels,
    required this.selectedModeIndex,
    required this.onModeSelected,
    required this.isCollapsed,
  });

  final int placeCount;
  final VoidCallback onCollapse;
  final List<String> modeLabels;
  final int selectedModeIndex;
  final ValueChanged<int>? onModeSelected;
  final bool isCollapsed;

  double get _height => modeLabels.isEmpty
      ? FieldMapLedgerHeader.height
      : FieldMapLedgerHeader.modeHeight;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return FieldMapLedgerHeader(
      placeCount: placeCount,
      onCollapse: onCollapse,
      modeLabels: modeLabels,
      selectedModeIndex: selectedModeIndex,
      onModeSelected: onModeSelected,
      isCollapsed: isCollapsed,
    );
  }

  @override
  bool shouldRebuild(_SheetStickyHeader old) =>
      placeCount != old.placeCount ||
      selectedModeIndex != old.selectedModeIndex ||
      isCollapsed != old.isCollapsed ||
      modeLabels != old.modeLabels;
}

// ============================================================
// EN: Sheet title row — title + close button for all bottom sheets
// KO: 시트 제목 행 — 모든 바텀시트에 공통으로 사용하는 제목 + 닫기 버튼
// ============================================================

class _SheetTitleRow extends StatelessWidget {
  const _SheetTitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GBTTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: GBTSpacing.minTouchTarget,
            minHeight: GBTSpacing.minTouchTarget,
          ),
          tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
        ),
      ],
    );
  }
}

List<String> _placeTypeLabels(List<String> types) {
  return types
      .map(placeTypeLabel)
      .where((label) => label.isNotEmpty)
      .take(2)
      .toList(growable: false);
}
