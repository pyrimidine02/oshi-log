import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/error/failure.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/live_events/application/live_events_controller.dart';
import 'package:girlsbandtabi_app/features/live_events/domain/entities/live_event_entities.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';
import 'package:girlsbandtabi_app/features/visits/domain/entities/visit_entities.dart';
import 'package:girlsbandtabi_app/features/visits/presentation/field_visit_ledger/field_visit_ledger_body.dart';
import 'package:girlsbandtabi_app/features/visits/presentation/field_visit_ledger/field_visit_ledger_view_data.dart';

void main() {
  testWidgets('renders a ruled place ledger without legacy tabs or cards', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    FieldPlaceLedgerEntry? openedEntry;
    var statsOpened = false;

    await _pumpLedger(
      tester,
      child: FieldVisitLedgerBody(
        visitsState: AsyncData(_visits),
        placesMapState: const AsyncData(_places),
        projects: _projects,
        attendanceState: _attendance,
        onRefreshPlaces: () async {},
        onRefreshEvents: () async {},
        onOpenVisit: (entry) => openedEntry = entry,
        onOpenEvent: (_) {},
        onOpenStats: () => statsOpened = true,
      ),
    );

    expect(find.text('TRAVEL LOGBOOK'), findsOneWidget);
    expect(find.text('장소 기록'), findsOneWidget);
    expect(find.text('장소 방문'), findsOneWidget);
    expect(find.text('이벤트 출석'), findsOneWidget);
    expect(find.text('여정 원장'), findsNothing);
    expect(find.byKey(const Key('field-ledger-place-row')), findsNWidgets(2));
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Club Citta'), findsOneWidget);
    final placeRowNode = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Club Citta.*2026년 7월 15일.*GPS 현장 인증')),
    );
    expect(placeRowNode.flagsCollection.isButton, isTrue);
    expect(placeRowNode.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(
      placeRowNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.text('Club Citta'));
    expect(openedEntry?.visit.id, 'visit-new');
    expect(openedEntry?.metadata?.projectId, 'project-1');

    await tester.tap(find.byKey(const Key('field-ledger-stats-action')));
    expect(statsOpened, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('switches to real event attendance and preserves navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? openedEvent;

    await _pumpLedger(
      tester,
      child: FieldVisitLedgerBody(
        visitsState: AsyncData(_visits),
        placesMapState: const AsyncData(_places),
        projects: _projects,
        attendanceState: _attendance,
        onRefreshPlaces: () async {},
        onRefreshEvents: () async {},
        onOpenVisit: (_) {},
        onOpenEvent: (record) => openedEvent = record.eventId,
        onOpenStats: () {},
      ),
    );

    await tester.tap(find.byKey(const Key('field-ledger-kind-events')));
    await tester.pumpAndSettle();

    expect(find.text('Field Notes Tour'), findsOneWidget);
    expect(find.text('범위'), findsOneWidget);
    expect(find.text('현재'), findsOneWidget);
    expect(find.byKey(const Key('field-ledger-event-row')), findsOneWidget);
    final eventRowNode = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp('Field Notes Tour.*2026년 7월 14일.*인증 완료.*인증 방식 GPS'),
      ),
    );
    expect(eventRowNode.flagsCollection.isButton, isTrue);
    expect(eventRowNode.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(
      eventRowNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(find.text('Field Notes Tour'));
    expect(openedEvent, 'event-1');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('remains readable at 320dp and 200 percent text in dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpLedger(
      tester,
      theme: GBTTheme.dark,
      textScaler: const TextScaler.linear(2),
      child: FieldVisitLedgerBody(
        visitsState: AsyncData(_visits),
        placesMapState: const AsyncData(_places),
        projects: _projects,
        attendanceState: _attendance,
        onRefreshPlaces: () async {},
        onRefreshEvents: () async {},
        onOpenVisit: (_) {},
        onOpenEvent: (_) {},
        onOpenStats: () {},
      ),
    );

    expect(find.bySemanticsLabel('장소 방문 기록 보기'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Club Citta.*2026년 7월 15일.*GPS 현장 인증')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps both empty ledgers actionable without fabricated rows', (
    tester,
  ) async {
    var mapOpened = false;
    var eventsOpened = false;
    await _pumpLedger(
      tester,
      child: FieldVisitLedgerBody(
        visitsState: const AsyncData([]),
        placesMapState: const AsyncData({}),
        projects: _projects,
        attendanceState: const LiveAttendanceHistoryViewState(),
        onRefreshPlaces: () async {},
        onRefreshEvents: () async {},
        onOpenVisit: (_) {},
        onOpenEvent: (_) {},
        onOpenStats: () {},
        onOpenMap: () => mapOpened = true,
        onOpenEvents: () => eventsOpened = true,
      ),
    );

    expect(find.textContaining('지도에서 장소를 선택하고'), findsOne);
    expect(
      find.byKey(const Key('field-ledger-empty-place-note')),
      findsOneWidget,
    );
    expect(find.text('첫 방문 기록을 남겨보세요'), findsOneWidget);
    expect(find.text('지도에서 장소 찾기'), findsOneWidget);
    expect(find.byKey(const Key('field-ledger-place-row')), findsNothing);

    await tester.tap(find.text('지도에서 장소 찾기'));
    expect(mapOpened, isTrue);

    await tester.tap(find.byKey(const Key('field-ledger-kind-events')));
    await tester.pump();

    expect(find.textContaining('이벤트 일정을 확인하고'), findsOne);
    expect(
      find.byKey(const Key('field-ledger-empty-event-note')),
      findsOneWidget,
    );
    expect(find.text('첫 이벤트 출석을 기록해보세요'), findsOneWidget);
    expect(find.text('이벤트 일정 보기'), findsOneWidget);
    expect(find.byKey(const Key('field-ledger-event-row')), findsNothing);
    expect(find.byType(Card), findsNothing);

    await tester.tap(find.text('이벤트 일정 보기'));
    expect(eventsOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows load-more failure and waits for explicit retry', (
    tester,
  ) async {
    var loadMoreCount = 0;
    const failedState = LiveAttendanceHistoryViewState(
      items: [
        LiveAttendanceHistoryRecord(
          projectKey: 'gbc',
          eventId: 'event-1',
          attended: true,
          status: LiveAttendanceStatus.declared,
          canUndo: true,
          eventTitle: 'Field Notes Tour',
        ),
      ],
      hasNext: true,
      failure: NetworkFailure('offline'),
    );

    await _pumpLedger(
      tester,
      child: FieldVisitLedgerBody(
        visitsState: AsyncData(_visits),
        placesMapState: const AsyncData(_places),
        projects: _projects,
        attendanceState: failedState,
        initialKind: FieldVisitLedgerKind.events,
        onRefreshPlaces: () async {},
        onRefreshEvents: () async {},
        onLoadMoreEvents: () async => loadMoreCount += 1,
        onOpenVisit: (_) {},
        onOpenEvent: (_) {},
        onOpenStats: () {},
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
    expect(loadMoreCount, 0);
    expect(find.text('추가 기록을 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('field-ledger-load-more-retry')));
    expect(loadMoreCount, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLedger(
  WidgetTester tester, {
  required Widget child,
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme ?? GBTTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(body: child),
      ),
    ),
  );
}

const _projects = [
  Project(
    id: 'project-1',
    code: 'gbc',
    name: 'Girls Band Cry',
    status: 'active',
    defaultTimezone: 'Asia/Tokyo',
  ),
];

final _visits = [
  VisitEvent(
    id: 'visit-old',
    placeId: 'place-a',
    visitedAt: DateTime.utc(2026, 6, 1),
  ),
  VisitEvent(
    id: 'visit-new',
    placeId: 'place-b',
    visitedAt: DateTime.utc(2026, 7, 15, 8, 30),
    status: VisitVerificationStatus.verified,
    distanceM: 3,
  ),
];

const _places = {
  'place-a': (
    place: PlaceSummary(
      id: 'place-a',
      name: 'Shimokitazawa Shelter',
      address: 'Tokyo',
      latitude: 0,
      longitude: 0,
    ),
    projectId: 'project-1',
    projectName: 'Girls Band Cry',
  ),
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

final _attendance = LiveAttendanceHistoryViewState(
  items: [
    LiveAttendanceHistoryRecord(
      projectKey: 'gbc',
      eventId: 'event-1',
      attended: true,
      status: LiveAttendanceStatus.verified,
      canUndo: false,
      verificationMethod: 'GPS',
      attendedAt: DateTime.utc(2026, 7, 14),
      eventTitle: 'Field Notes Tour',
      showStartTime: DateTime.utc(2026, 7, 13),
    ),
  ],
);
