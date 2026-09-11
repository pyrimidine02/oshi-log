import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_agenda_widgets.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_detail_widgets.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_detail_sections.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_live_events_page.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';

void main() {
  test('field event route entries are constructible', () {
    expect(const FieldLiveEventsPage(embedded: true), isA<Widget>());
    expect(const FieldLiveEventDetailPage(eventId: 'event-1'), isA<Widget>());
  });

  testWidgets('event desk switches from next show to archive at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final seeded = [
      LiveEventSummary(
        id: 'future',
        title: 'FUTURE FIELD SHOW',
        showStartTime: now.add(const Duration(days: 10)),
        status: 'SCHEDULED',
        projectIds: const ['p1'],
        unitIds: const ['u1'],
      ),
      LiveEventSummary(
        id: 'past',
        title: 'PAST FIELD SHOW',
        showStartTime: now.subtract(const Duration(days: 10)),
        status: 'COMPLETED',
        projectIds: const ['p1'],
        unitIds: const ['u1'],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveEventsListControllerProvider.overrideWith(
            (ref) => _SeededLiveEventsController(ref, seeded),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const FieldLiveEventsPage(
            embedded: true,
            projectLens: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('FUTURE FIELD SHOW'), findsOneWidget);
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('PAST FIELD SHOW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded schedule desk keeps its controls within 104dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveEventsListControllerProvider.overrideWith(
            (ref) => _SeededLiveEventsController(ref, [_summary]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const FieldLiveEventsPage(
            embedded: true,
            projectLens: SizedBox(
              height: 48,
              child: Center(child: Text('Girls Band Cry')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final header = find.byKey(const Key('field-event-schedule-desk-header'));
    expect(header, findsOneWidget);
    expect(tester.getSize(header).height, lessThanOrEqualTo(104));
    expect(find.text('LIVE FIELD DESK'), findsNothing);
    expect(find.text('TEST LIVE TOUR'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(FieldEventPosterFeature)).dy,
      lessThan(150),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact schedule controls survive 200 percent text in dark mode',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveEventsListControllerProvider.overrideWith(
              (ref) => _SeededLiveEventsController(ref, [_summary]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            theme: GBTTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const FieldLiveEventsPage(
                embedded: true,
                projectLens: SizedBox(height: 48),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Upcoming events'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Filter schedule, all units'),
        findsOneWidget,
      );
      _expectEnabledButtonWithTap(
        tester,
        find.bySemanticsLabel('Upcoming events'),
      );
      _expectEnabledButtonWithTap(
        tester,
        find.bySemanticsLabel('Archived events'),
      );
      _expectEnabledButtonWithTap(
        tester,
        find.bySemanticsLabel('Filter schedule, all units'),
      );
      await tester.tap(find.bySemanticsLabel('Filter schedule, all units'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule filter'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('archive year lives inside the compact schedule filter', (
    tester,
  ) async {
    final archived = LiveEventSummary(
      id: 'archived-2025',
      title: 'ARCHIVED FIELD SHOW',
      showStartTime: DateTime(2025, 6, 20, 18),
      status: 'COMPLETED',
      projectIds: const ['p1'],
      unitIds: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveEventsListControllerProvider.overrideWith(
            (ref) => _SeededLiveEventsController(ref, [archived]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const FieldLiveEventsPage(
            embedded: true,
            projectLens: SizedBox(height: 48),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('All years'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Archived events'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Filter schedule, all units'));
    await tester.pumpAndSettle();

    expect(find.text('Schedule filter'), findsOneWidget);
    expect(find.text('YEAR'), findsOneWidget);
    expect(find.text('All years'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('UNITS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agenda row remains usable at 320dp with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: FieldEventAgendaRow(
              event: _summary,
              attended: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('TEST LIVE TOUR'), findsOneWidget);
    await tester.tap(find.text('TEST LIVE TOUR'));
    expect(tapped, isTrue);
  });

  testWidgets('agenda preserves the server venue identity', (tester) async {
    final event = LiveEventSummary(
      id: 'venue-event',
      title: 'TOKYO FIELD SHOW',
      showStartTime: DateTime(2026, 7, 20, 18),
      status: 'SCHEDULED',
      projectIds: const ['p1'],
      unitIds: const ['u1'],
      venue: 'Zepp DiverCity',
      address: 'Tokyo, Japan',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: Scaffold(
          body: FieldEventAgendaRow(
            event: event,
            attended: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Zepp DiverCity'), findsOneWidget);
    expect(find.textContaining('Tokyo, Japan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance stamp exposes an accessible toggle in dark mode', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.dark,
        home: Scaffold(
          body: FieldAttendanceStamp(
            attended: false,
            canUndo: false,
            isBusy: false,
            onToggle: () => toggled = true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Mark attended'), findsOneWidget);
    _expectEnabledButtonWithTap(tester, find.bySemanticsLabel('Mark attended'));
    await tester.tap(find.bySemanticsLabel('Mark attended'));
    expect(toggled, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('locked attendance remains a disabled button without tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: const Scaffold(
          body: FieldAttendanceStamp(
            attended: true,
            canUndo: false,
            isBusy: false,
            onToggle: null,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel('Verified attendance'),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  testWidgets('poster feature reflows without flex overflow at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FieldEventPosterFeature(event: _summary, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('NEXT LIVE'), findsOneWidget);
  });

  testWidgets('event document reflows at 320dp with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FieldEventTicketDocument(
                event: _detail,
                attendance: LiveAttendanceViewState(
                  attendance: LiveAttendanceState.none('live-1'),
                ),
                onAttendanceToggle: () {},
                onTicketTap: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Not provided in event data'), findsOneWidget);
    expect(find.text('No ticket information'), findsOneWidget);
  });

  testWidgets('event document exposes a real venue place route', (
    tester,
  ) async {
    var opened = false;
    final event = LiveEventDetail(
      id: 'venue-event',
      title: 'TOKYO FIELD SHOW',
      showStartTime: DateTime(2026, 7, 20, 18),
      status: 'SCHEDULED',
      projectIds: const ['p1'],
      unitIds: const ['u1'],
      placeId: 'place-zepp-divercity',
      venue: 'Zepp DiverCity',
      address: 'Tokyo, Japan',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FieldEventTicketDocument(
              event: event,
              attendance: LiveAttendanceViewState(
                attendance: LiveAttendanceState.none('venue-event'),
              ),
              onAttendanceToggle: null,
              onTicketTap: null,
              onVenueTap: () => opened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Zepp DiverCity'), findsOneWidget);
    expect(find.text('View venue place'), findsOneWidget);
    await tester.tap(find.text('View venue place'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setlist rail keeps real song navigation affordance', (
    tester,
  ) async {
    MusicSetlistItem? tapped;
    const item = MusicSetlistItem(
      order: 1,
      eventId: 'live-1',
      songId: 'song-1',
      songTitle: 'Field Notes Anthem',
      unitName: 'Test Unit',
      segmentType: 'MAIN',
      isEncore: true,
    );
    const setlist = MusicLiveSetlist(
      liveEventId: 'live-1',
      eventStatus: 'COMPLETED',
      items: [item],
      unitSetlists: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.dark,
        home: Scaffold(
          body: FieldEventSetlistSection(
            state: const AsyncData(setlist),
            onSongTap: (item) => tapped = item,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Field Notes Anthem'));
    expect(tapped?.songId, 'song-1');
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('setlist disables song navigation without project context', (
    tester,
  ) async {
    var tapCount = 0;
    const item = MusicSetlistItem(
      order: 1,
      eventId: 'live-1',
      songId: 'song-1',
      songTitle: 'Field Notes Anthem',
      segmentType: 'MAIN',
      isEncore: false,
    );
    const setlist = MusicLiveSetlist(
      liveEventId: 'live-1',
      eventStatus: 'COMPLETED',
      items: [item],
      unitSetlists: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: Scaffold(
          body: FieldEventSetlistSection(
            state: const AsyncData(setlist),
            hasProjectContext: false,
            onSongTap: (_) => tapCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Field Notes Anthem'));

    expect(tapCount, 0);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('archive ignores a selected year absent from loaded events', (
    tester,
  ) async {
    final past = LiveEventSummary(
      id: 'past-2026',
      title: 'PAST 2026 SHOW',
      showStartTime: DateTime.now().subtract(const Duration(days: 30)),
      status: 'COMPLETED',
      projectIds: const ['p1'],
      unitIds: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          liveEventsListControllerProvider.overrideWith(
            (ref) => _SeededLiveEventsController(ref, [past]),
          ),
          selectedLiveEventYearProvider.overrideWith((ref) => 1999),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const FieldLiveEventsPage(
            embedded: true,
            projectLens: SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('PAST 2026 SHOW'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectEnabledButtonWithTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(node.flagsCollection.isButton, isTrue);
  expect(node.flagsCollection.isEnabled, ui.Tristate.isTrue);
  expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
}

final _summary = LiveEventSummary(
  id: 'live-1',
  title: 'TEST LIVE TOUR',
  showStartTime: DateTime.now().add(const Duration(days: 10)),
  status: 'SCHEDULED',
  projectIds: const ['p1'],
  unitIds: const ['u1'],
);

final _detail = LiveEventDetail(
  id: 'live-1',
  title: 'TEST LIVE TOUR',
  showStartTime: DateTime.now().add(const Duration(days: 10)),
  doorsOpenTime: DateTime.now().add(const Duration(days: 10, hours: -1)),
  status: 'SCHEDULED',
  projectIds: const ['p1'],
  unitIds: const ['u1'],
);

class _SeededLiveEventsController extends LiveEventsListController {
  _SeededLiveEventsController(super.ref, this.items) {
    state = AsyncData(items);
  }

  final List<LiveEventSummary> items;

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = AsyncData(items);
  }
}
