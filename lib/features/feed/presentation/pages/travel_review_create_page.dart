import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_map_styles.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../../core/utils/result.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../live_events/domain/entities/live_event_entities.dart';
import '../../../places/domain/entities/place_entities.dart';
import '../../../projects/domain/entities/fan_subject.dart';
import '../../../visits/application/visits_controller.dart';
import '../../../visits/domain/entities/visit_entities.dart';
import '../../application/travel_reviews_controller.dart';
import '../../domain/entities/travel_review.dart';
import '../widgets/travel_review_compose_sections.dart';
import '../widgets/travel_review_place_picker_sheet.dart';

/// EN: Travel Review creation page.
/// KO: 여행 후기 작성 페이지.
class TravelReviewCreatePage extends ConsumerStatefulWidget {
  const TravelReviewCreatePage({super.key});

  @override
  ConsumerState<TravelReviewCreatePage> createState() =>
      _TravelReviewCreatePageState();
}

class _TravelReviewCreatePageState
    extends ConsumerState<TravelReviewCreatePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _routeNoteController = TextEditingController();

  // EN: Selected places for the review
  // KO: 후기에 선택된 장소들
  final List<PlaceSummary> _selectedPlaces = [];
  final List<LiveEventSummary> _selectedEvents = [];
  final List<FanSubject> _selectedSubjects = [];

  DateTime? _tripStartedOn;
  DateTime? _tripEndedOn;

  bool _isSubmitting = false;

  bool get _isAppleMap => !kIsWeb && Platform.isIOS;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _selectedPlaces.isNotEmpty &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateState);
    _contentController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_updateState);
    _contentController.removeListener(_updateState);
    _titleController.dispose();
    _contentController.dispose();
    _routeNoteController.dispose();
    super.dispose();
  }

  void _addPlace(PlaceSummary place) {
    if (_selectedPlaces.length >= 20 &&
        !_selectedPlaces.any((selected) => selected.id == place.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('방문 장소는 최대 20곳까지 추가할 수 있어요.')),
      );
      return;
    }
    setState(() {
      if (!_selectedPlaces.any((p) => p.id == place.id)) {
        _selectedPlaces.add(place);
      }
    });
    if (ref.read(userVisitsControllerProvider).valueOrNull == null) {
      unawaited(ref.read(userVisitsControllerProvider.notifier).load());
    }
  }

  void _removePlace(int index) {
    setState(() {
      _selectedPlaces.removeAt(index);
    });
  }

  void _reorderPlaces(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      final place = _selectedPlaces.removeAt(oldIndex);
      _selectedPlaces.insert(newIndex, place);
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요')));
      return;
    }
    if (_selectedPlaces.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1개 이상의 장소를 추가해주세요')));
      return;
    }

    final projectCode = ref.read(selectedProjectKeyProvider)?.trim();
    if (projectCode == null || projectCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행을 기록할 프로젝트를 먼저 선택해주세요.')));
      return;
    }
    if (_tripStartedOn != null &&
        _tripEndedOn != null &&
        _tripEndedOn!.isBefore(_tripStartedOn!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료일은 시작일보다 빠를 수 없어요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    if (ref.read(userVisitsControllerProvider).valueOrNull == null) {
      await ref.read(userVisitsControllerProvider.notifier).load();
      if (!mounted) return;
    }
    final visits =
        ref.read(userVisitsControllerProvider).valueOrNull ??
        const <VisitEvent>[];
    final attendanceRecords = await _loadAttendanceProofRecords();
    if (!mounted) return;
    final result = await ref
        .read(travelReviewMutationControllerProvider.notifier)
        .create(
          projectCode: projectCode,
          draft: TravelReviewDraft(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            stops: _selectedPlaces
                .map(
                  (place) => TravelReviewStopDraft(
                    placeId: place.id,
                    verifiedVisitId: verifiedVisitProofId(visits, place.id),
                  ),
                )
                .toList(growable: false),
            events: _selectedEvents
                .map(
                  (event) => TravelReviewEventDraft(
                    liveEventId: event.id,
                    verifiedAttendanceId: verifiedAttendanceProofId(
                      attendanceRecords,
                      event.id,
                    ),
                  ),
                )
                .toList(growable: false),
            fanSubjectIds: _selectedSubjects
                .map((subject) => subject.id)
                .toList(growable: false),
            tripStartedOn: _tripStartedOn,
            tripEndedOn: _tripEndedOn,
            routeNote: _routeNoteController.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    switch (result) {
      case Success():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행 후기가 등록되었습니다.')));
        context.pop();
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visits =
        ref.watch(userVisitsControllerProvider).valueOrNull ??
        const <VisitEvent>[];
    final attendanceRecords = _selectedEvents.isEmpty
        ? const <LiveAttendanceHistoryRecord>[]
        : ref.watch(liveAttendanceHistoryControllerProvider).items;
    final verifiedEventIds = attendanceRecords
        .where(
          (record) =>
              record.isVerified &&
              record.attendanceId?.trim().isNotEmpty == true,
        )
        .map((record) => record.eventId)
        .toSet();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: '후기 작성',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: GBTSpacing.xs),
            child: FilledButton(
              key: const ValueKey('travel-review-submit'),
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 48),
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
              ),
              child: const Text('등록'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(
                child: GBTPageHeader(
                  eyebrow: 'FIELD REPORT',
                  title: '오늘의 순례를 기록하세요',
                  description: '방문한 순서와 현장의 감정을 함께 남기면 다음 여행의 지도가 됩니다.',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.md,
                  GBTSpacing.lg,
                  GBTSpacing.md,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'TRAVEL NOTE',
                      style: GBTTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    TextField(
                      controller: _titleController,
                      maxLines: 2,
                      maxLength: 255,
                      style: GBTTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        labelText: '제목',
                        hintText: '이번 여행은 어떠셨나요?',
                        filled: false,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      minLines: 5,
                      maxLength: 20000,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        hintText: '자세한 후기를 남겨주세요.',
                        alignLabelWithHint: true,
                        filled: false,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xl2),
                    TravelReviewComposeMetadata(
                      routeNoteController: _routeNoteController,
                      tripStartedOn: _tripStartedOn,
                      tripEndedOn: _tripEndedOn,
                      selectedEvents: _selectedEvents,
                      verifiedEventIds: verifiedEventIds,
                      selectedSubjects: _selectedSubjects,
                      onPickStartDate: () => _pickDate(isStart: true),
                      onPickEndDate: () => _pickDate(isStart: false),
                      onPickEvents: _showEventPicker,
                      onPickSubjects: _showFanSubjectPicker,
                      onRemoveEvent: (eventId) => setState(
                        () => _selectedEvents.removeWhere(
                          (event) => event.id == eventId,
                        ),
                      ),
                      onRemoveSubject: (subjectId) => setState(
                        () => _selectedSubjects.removeWhere(
                          (subject) => subject.id == subjectId,
                        ),
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xl2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROUTE',
                          style: GBTTypography.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          '방문 순서',
                          style: GBTTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          _selectedPlaces.isEmpty
                              ? '장소를 추가하면 이동 순서를 지도에 그려드려요.'
                              : '총 ${_selectedPlaces.length}곳 · 길게 눌러 순서를 바꿀 수 있어요.',
                          style: GBTTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: _showPlacePicker,
                          icon: const Icon(Icons.add),
                          label: const Text('장소 추가'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusSm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.md),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: _buildMapSection(colorScheme, isDark),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: GBTSpacing.sm)),
              SliverReorderableList(
                itemCount: _selectedPlaces.length,
                onReorderItem: _reorderPlaces,
                itemBuilder: (context, index) {
                  final place = _selectedPlaces[index];
                  return DecoratedBox(
                    key: ValueKey(place.id),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.md,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        minVerticalPadding: GBTSpacing.sm,
                        leading: SizedBox(
                          width: 32,
                          child: Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: GBTTypography.labelLarge.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: GBTTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.address, style: GBTTypography.bodySmall),
                            if (verifiedVisitProofId(visits, place.id) != null)
                              Text(
                                '인증된 방문 기록 연결',
                                style: GBTTypography.labelSmall.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removePlace(index),
                              tooltip: '${place.name} 제거',
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection(ColorScheme colorScheme, bool isDark) {
    if (_selectedPlaces.isEmpty) {
      return SizedBox(
        height: 168,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 36,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                '아직 표시할 여정이 없어요',
                textAlign: TextAlign.center,
                style: GBTTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAppleMap) {
      final amaps.Polyline polyline = amaps.Polyline(
        polylineId: amaps.PolylineId('route'),
        points: _selectedPlaces
            .map((p) => amaps.LatLng(p.latitude, p.longitude))
            .toList(),
        color: colorScheme.primary,
        width: 4,
        jointType: amaps.JointType.round,
      );

      final Set<amaps.Annotation> markers = {};
      for (int i = 0; i < _selectedPlaces.length; i++) {
        final place = _selectedPlaces[i];
        markers.add(
          amaps.Annotation(
            annotationId: amaps.AnnotationId(place.id),
            position: amaps.LatLng(place.latitude, place.longitude),
            infoWindow: amaps.InfoWindow(title: '${i + 1}. ${place.name}'),
          ),
        );
      }

      return SizedBox(
        height: 184,
        child: Stack(
          fit: StackFit.expand,
          children: [
            amaps.AppleMap(
              initialCameraPosition: amaps.CameraPosition(
                target: amaps.LatLng(
                  _selectedPlaces.first.latitude,
                  _selectedPlaces.first.longitude,
                ),
                zoom: 12,
              ),
              polylines: {polyline},
              annotations: markers,
            ),
            IgnorePointer(
              child: ColoredBox(
                color: gbtAppleMapOverlayColorForDarkMode(isDark),
              ),
            ),
          ],
        ),
      );
    } else {
      final gmaps.Polyline polyline = gmaps.Polyline(
        polylineId: const gmaps.PolylineId('route'),
        points: _selectedPlaces
            .map((p) => gmaps.LatLng(p.latitude, p.longitude))
            .toList(),
        color: colorScheme.primary,
        width: 4,
        jointType: gmaps.JointType.round,
      );

      final Set<gmaps.Marker> markers = {};
      for (int i = 0; i < _selectedPlaces.length; i++) {
        final place = _selectedPlaces[i];
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(place.id),
            position: gmaps.LatLng(place.latitude, place.longitude),
            infoWindow: gmaps.InfoWindow(title: '${i + 1}. ${place.name}'),
          ),
        );
      }

      return SizedBox(
        height: 184,
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(
              _selectedPlaces.first.latitude,
              _selectedPlaces.first.longitude,
            ),
            zoom: 12,
          ),
          style: gbtGoogleMapStyleForDarkMode(isDark),
          polylines: {polyline},
          markers: markers,
        ),
      );
    }
  }

  Future<List<LiveAttendanceHistoryRecord>>
  _loadAttendanceProofRecords() async {
    if (_selectedEvents.isEmpty) return const [];

    final provider = liveAttendanceHistoryControllerProvider;
    final notifier = ref.read(provider.notifier);
    var history = ref.read(provider);
    if (history.isInitialLoading) {
      await notifier.load(forceRefresh: true);
      if (!mounted) return const [];
      history = ref.read(provider);
    }

    final selectedEventIds = _selectedEvents
        .map((event) => event.id.trim())
        .where((eventId) => eventId.isNotEmpty)
        .toSet();
    while (history.hasNext &&
        !history.items
            .map((record) => record.eventId.trim())
            .toSet()
            .containsAll(selectedEventIds)) {
      final previousPage = history.nextPage;
      await notifier.loadMore();
      if (!mounted) return const [];
      history = ref.read(provider);
      if (history.nextPage <= previousPage) break;
    }
    return history.items;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_tripStartedOn ?? DateTime.now())
        : (_tripEndedOn ?? _tripStartedOn ?? DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (isStart) {
        _tripStartedOn = selected;
        if (_tripEndedOn != null && _tripEndedOn!.isBefore(selected)) {
          _tripEndedOn = selected;
        }
      } else {
        _tripEndedOn = selected;
      }
    });
  }

  Future<void> _showEventPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return TravelEventPickerSheet(
            selectedIds: _selectedEvents.map((event) => event.id).toSet(),
            onToggle: (event) {
              setState(() {
                final index = _selectedEvents.indexWhere(
                  (selected) => selected.id == event.id,
                );
                if (index >= 0) {
                  _selectedEvents.removeAt(index);
                } else if (_selectedEvents.length < 10) {
                  _selectedEvents.add(event);
                }
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  Future<void> _showFanSubjectPicker() async {
    final projectCode = ref.read(selectedProjectKeyProvider)?.trim();
    if (projectCode == null || projectCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로젝트를 먼저 선택해주세요.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return TravelFanSubjectPickerSheet(
            projectCode: projectCode,
            selectedIds: _selectedSubjects.map((subject) => subject.id).toSet(),
            onToggle: (subject) {
              setState(() {
                final index = _selectedSubjects.indexWhere(
                  (selected) => selected.id == subject.id,
                );
                if (index >= 0) {
                  _selectedSubjects.removeAt(index);
                } else if (_selectedSubjects.length < 20) {
                  _selectedSubjects.add(subject);
                }
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  // EN: Open the real place picker sheet backed by placesListControllerProvider.
  // KO: placesListControllerProvider를 사용한 실제 장소 선택 시트를 엽니다.
  Future<void> _showPlacePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusLg),
        ),
      ),
      builder: (_) => TravelReviewPlacePickerSheet(
        selectedIds: _selectedPlaces.map((p) => p.id).toSet(),
        onAdd: _addPlace,
      ),
    );
  }
}
