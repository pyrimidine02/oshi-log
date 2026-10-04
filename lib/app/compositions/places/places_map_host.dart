/// EN: App-level host wiring visits and catalog pickers into PlacesMapPage
///     so the places feature stays free of visits/catalog dependencies.
/// KO: visits·catalog 피커를 PlacesMapPage에 연결하는 app 레벨 호스트.
///     places feature가 visits·catalog에 직접 의존하지 않도록 합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/band_filter_sheet.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_picker_sheet.dart';
import 'package:oshi_log/features/place/places/presentation/pages/places_map_page.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';

/// EN: Hosts PlacesMapPage with visited-place IDs and catalog picker
///     callbacks supplied from the app composition layer.
/// KO: 방문 장소 ID와 catalog 피커 콜백을 app 조합 레이어에서 공급하여
///     PlacesMapPage를 호스팅합니다.
class PlacesMapHost extends ConsumerStatefulWidget {
  const PlacesMapHost({
    super.key,
    this.embedded = false,
    this.isActive = true,
    this.topOverlayClearance = 0,
    this.bottomInset = 0,
    this.modeLabels = const [],
    this.selectedModeIndex = 0,
    this.onModeSelected,
  });

  final bool embedded;
  final bool isActive;
  final double topOverlayClearance;
  final double bottomInset;
  final List<String> modeLabels;
  final int selectedModeIndex;
  final ValueChanged<int>? onModeSelected;

  @override
  ConsumerState<PlacesMapHost> createState() => _PlacesMapHostState();
}

class _PlacesMapHostState extends ConsumerState<PlacesMapHost> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted && ref.read(isAuthenticatedProvider)) {
        ref.read(userVisitsControllerProvider.notifier).load();
      }
    });
  }

  Future<void> _showBandFilter(
    BuildContext context,
    String projectKey,
    List<String> selectedBandIds,
    ValueChanged<List<String>> onApply,
  ) {
    return showBandFilterSheet(
      context: context,
      ref: ref,
      projectKey: projectKey,
      selectedBandIds: selectedBandIds,
      onApply: onApply,
    );
  }

  Future<Project?> _showProjectPicker(
    BuildContext context,
    List<Project> projects,
    Project selectedProject,
  ) {
    return showFieldProjectPicker(
      context: context,
      projects: projects,
      selectedProject: selectedProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isAuthenticatedProvider, (_, next) {
      if (next) ref.read(userVisitsControllerProvider.notifier).load();
    });
    final visits = ref.watch(isAuthenticatedProvider)
        ? ref.watch(userVisitsControllerProvider).valueOrNull
        : null;
    final visitedPlaceIds = Set<String>.unmodifiable(
      (visits ?? const []).map((visit) => visit.placeId),
    );
    return PlacesMapPage(
      embedded: widget.embedded,
      isActive: widget.isActive,
      topOverlayClearance: widget.topOverlayClearance,
      bottomInset: widget.bottomInset,
      modeLabels: widget.modeLabels,
      selectedModeIndex: widget.selectedModeIndex,
      onModeSelected: widget.onModeSelected,
      visitedPlaceIds: visitedPlaceIds,
      onShowBandFilter: _showBandFilter,
      onShowProjectPicker: _showProjectPicker,
    );
  }
}
