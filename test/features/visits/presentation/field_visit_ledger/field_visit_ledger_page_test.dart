import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';
import 'package:oshi_log/features/visits/application/visits_controller.dart';
import 'package:oshi_log/features/visits/domain/entities/visit_entities.dart';
import 'package:oshi_log/features/visits/presentation/field_visit_ledger/field_visit_ledger_page.dart';

void main() {
  testWidgets('provider-wired page renders API-backed visit state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userVisitsControllerProvider.overrideWith(
            (ref) => _SeededVisitsController(ref),
          ),
          visitAllProjectsPlacesMapProvider.overrideWith(
            (ref) async => _places,
          ),
          projectsControllerProvider.overrideWith(
            (ref) => _SeededProjectsController(ref),
          ),
          liveAttendanceHistoryControllerProvider.overrideWith(
            (ref) => _SeededAttendanceController(ref),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: GBTTheme.light,
          home: const Scaffold(
            body: FieldVisitLedgerPage(embedded: true, bottomClearance: 16),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Club Citta'), findsOneWidget);
    expect(find.text('장소 기록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone ledger uses the shared compact app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userVisitsControllerProvider.overrideWith(
            (ref) => _SeededVisitsController(ref),
          ),
          visitAllProjectsPlacesMapProvider.overrideWith(
            (ref) async => _places,
          ),
          projectsControllerProvider.overrideWith(
            (ref) => _SeededProjectsController(ref),
          ),
          liveAttendanceHistoryControllerProvider.overrideWith(
            (ref) => _SeededAttendanceController(ref),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: GBTTheme.light,
          home: const FieldVisitLedgerPage(bottomClearance: 16),
        ),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.scrolledUnderElevation, 0);
    expect(find.text('여행 기록'), findsOneWidget);
    expect(find.text('장소 기록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SeededVisitsController extends UserVisitsController {
  _SeededVisitsController(super.ref) {
    state = AsyncData([
      VisitEvent(
        id: 'visit-new',
        placeId: 'place-b',
        visitedAt: DateTime.utc(2026, 7, 15),
      ),
    ]);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _SeededProjectsController extends ProjectsController {
  _SeededProjectsController(super.ref) {
    state = const AsyncData([
      Project(
        id: 'project-1',
        code: 'gbc',
        name: 'Girls Band Cry',
        status: 'active',
        defaultTimezone: 'Asia/Tokyo',
      ),
    ]);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _SeededAttendanceController extends LiveAttendanceHistoryController {
  _SeededAttendanceController(super.ref) {
    state = _attendance;
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  @override
  Future<void> loadMore() async {}
}

const _places = {
  'place-b': (
    place: PlaceSummary(
      id: 'place-b',
      name: 'Club Citta',
      address: 'Kawasaki',
      latitude: 0,
      longitude: 0,
    ),
    projectId: 'project-1',
    projectName: 'Girls Band Cry',
  ),
};

const _attendance = LiveAttendanceHistoryViewState(
  items: [
    LiveAttendanceHistoryRecord(
      projectKey: 'gbc',
      eventId: 'event-1',
      attended: true,
      status: LiveAttendanceStatus.verified,
      canUndo: false,
    ),
  ],
);
