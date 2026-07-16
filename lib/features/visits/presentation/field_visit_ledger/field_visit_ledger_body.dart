/// EN: Clean-sheet field visit ledger body with a local record switch.
/// KO: 로컬 기록 전환을 제공하는 클린시트 탐방 원장 본문입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../live_events/domain/entities/live_event_entities.dart';
import '../../../projects/domain/entities/project_entities.dart';
import '../../domain/entities/visit_entities.dart';
import 'field_event_ledger.dart';
import 'field_place_ledger.dart';
import 'field_visit_ledger_common.dart';
import 'field_visit_ledger_view_data.dart';

export 'field_visit_ledger_common.dart' show FieldVisitLedgerKind;

class FieldVisitLedgerBody extends StatefulWidget {
  const FieldVisitLedgerBody({
    super.key,
    required this.visitsState,
    required this.placesMapState,
    required this.projects,
    required this.attendanceState,
    required this.onRefreshPlaces,
    required this.onRefreshEvents,
    required this.onOpenVisit,
    required this.onOpenEvent,
    required this.onOpenStats,
    this.onLoadMoreEvents,
    this.initialKind = FieldVisitLedgerKind.places,
    this.bottomClearance,
  });

  final AsyncValue<List<VisitEvent>> visitsState;
  final AsyncValue<Map<String, FieldVisitPlaceMetadata>> placesMapState;
  final List<Project> projects;
  final LiveAttendanceHistoryViewState attendanceState;
  final Future<void> Function() onRefreshPlaces;
  final Future<void> Function() onRefreshEvents;
  final Future<void> Function()? onLoadMoreEvents;
  final ValueChanged<FieldPlaceLedgerEntry> onOpenVisit;
  final ValueChanged<LiveAttendanceHistoryRecord> onOpenEvent;
  final VoidCallback onOpenStats;
  final FieldVisitLedgerKind initialKind;
  final double? bottomClearance;

  @override
  State<FieldVisitLedgerBody> createState() => _FieldVisitLedgerBodyState();
}

class _FieldVisitLedgerBodyState extends State<FieldVisitLedgerBody> {
  late FieldVisitLedgerKind _selectedKind = widget.initialKind;

  @override
  void didUpdateWidget(covariant FieldVisitLedgerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialKind != widget.initialKind &&
        _selectedKind != widget.initialKind) {
      _selectedKind = widget.initialKind;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomClearance =
        widget.bottomClearance ?? GBTSpacing.bottomNavClearanceOf(context);
    final header = FieldLedgerKindSwitch(
      selected: _selectedKind,
      onSelected: (kind) {
        if (_selectedKind == kind) return;
        setState(() => _selectedKind = kind);
      },
      onOpenStats: widget.onOpenStats,
    );

    if (_selectedKind == FieldVisitLedgerKind.events) {
      return FieldEventLedger(
        header: header,
        attendanceState: widget.attendanceState,
        projectNames: {
          for (final project in widget.projects)
            if (project.code.isNotEmpty) project.code: project.name,
          for (final project in widget.projects) project.id: project.name,
        },
        onRefresh: widget.onRefreshEvents,
        onLoadMore: widget.onLoadMoreEvents ?? () async {},
        onOpenEvent: widget.onOpenEvent,
        bottomClearance: bottomClearance,
      );
    }

    return FieldPlaceLedger(
      header: header,
      visitsState: widget.visitsState,
      placesMapState: widget.placesMapState,
      onRefresh: widget.onRefreshPlaces,
      onOpenVisit: widget.onOpenVisit,
      bottomClearance: bottomClearance,
    );
  }
}
