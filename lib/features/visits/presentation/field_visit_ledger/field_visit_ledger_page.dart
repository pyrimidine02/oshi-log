/// EN: Provider-wired clean-sheet journey ledger page.
/// KO: 실제 프로바이더에 연결된 클린시트 여정 원장 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../projects/application/projects_controller.dart';
import '../../application/visits_controller.dart';
import 'field_visit_ledger_body.dart';
import 'field_visit_ledger_navigation.dart';
import 'field_visit_ledger_view_data.dart';

class FieldVisitLedgerPage extends ConsumerStatefulWidget {
  const FieldVisitLedgerPage({
    super.key,
    this.embedded = false,
    this.initialKind = FieldVisitLedgerKind.places,
    this.bottomClearance,
  });

  final bool embedded;
  final FieldVisitLedgerKind initialKind;
  final double? bottomClearance;

  @override
  ConsumerState<FieldVisitLedgerPage> createState() =>
      _FieldVisitLedgerPageState();
}

class _FieldVisitLedgerPageState extends ConsumerState<FieldVisitLedgerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(userVisitsControllerProvider.notifier).load();
    });
  }

  Future<void> _refreshPlaces() async {
    ref.invalidate(visitAllProjectsPlacesMapProvider);
    await Future.wait<Object?>([
      ref.read(userVisitsControllerProvider.notifier).load(forceRefresh: true),
      ref.read(visitAllProjectsPlacesMapProvider.future),
    ]);
  }

  Future<void> _openVisit(FieldPlaceLedgerEntry entry) async {
    final projects =
        ref.read(projectsControllerProvider).valueOrNull ?? const [];
    FieldVisitNavigationResult result;
    try {
      result = await openFieldVisitLedgerEntry(
        entry: entry,
        projects: projects,
        selectedProjectKey: ref.read(selectedProjectKeyProvider),
        selectedProjectId: ref.read(selectedProjectIdProvider),
        selectProject: (projectKey, projectId) => ref
            .read(projectSelectionControllerProvider.notifier)
            .selectProject(projectKey, projectId: projectId),
        navigate: () {
          if (!mounted) return;
          context.goToVisitDetail(
            visitId: entry.visit.id,
            placeId: entry.visit.placeId,
            visitedAt: entry.visit.visitedAt?.toIso8601String(),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showProjectContextError();
      return;
    }
    if (!mounted) return;
    if (result == FieldVisitNavigationResult.missingProjectContext) {
      _showProjectContextError();
    }
  }

  void _showProjectContextError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '이 기록의 프로젝트를 확인할 수 없어 상세를 열지 못했습니다.',
            en: 'Could not identify this record\'s project, so its detail was not opened.',
            ja: 'この記録のプロジェクトを確認できず、詳細を開けませんでした。',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = FieldVisitLedgerBody(
      visitsState: ref.watch(userVisitsControllerProvider),
      placesMapState: ref.watch(visitAllProjectsPlacesMapProvider),
      projects: ref.watch(projectsControllerProvider).valueOrNull ?? const [],
      attendanceState: ref.watch(liveAttendanceHistoryControllerProvider),
      onRefreshPlaces: _refreshPlaces,
      onRefreshEvents: () => ref
          .read(liveAttendanceHistoryControllerProvider.notifier)
          .load(forceRefresh: true),
      onLoadMoreEvents: () =>
          ref.read(liveAttendanceHistoryControllerProvider.notifier).loadMore(),
      onOpenVisit: _openVisit,
      onOpenEvent: (record) => context.goToEventDetail(record.eventId),
      onOpenStats: context.goToVisitStats,
      initialKind: widget.initialKind,
      bottomClearance: widget.bottomClearance,
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '여정 원장', en: 'Journey ledger', ja: '旅の台帳'),
      ),
      body: body,
    );
  }
}
