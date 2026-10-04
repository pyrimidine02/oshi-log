import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/event_time_policy.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/event_preparation.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/field_event_detail_sections.dart';
import 'package:oshi_log/features/oshikatsu/live/presentation/field_events/field_live_event_detail_page.dart';
import '../../../../testing/platform_golden.dart';

void main() {
  testWidgets('before, day and after expose only their primary actions', (
    tester,
  ) async {
    var ticketOpens = 0;
    Future<void> render(EventPhase phase) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventActionBar(
            phase: phase,
            onTicket: () => ticketOpens++,
            onDirections: () {},
            onCheerGuide: () {},
            onRecord: () {},
            onReport: () {},
          ),
        ),
      ),
    );
    await render(EventPhase.before);
    expect(find.text('Official tickets'), findsOneWidget);
    expect(find.text('Record attendance'), findsNothing);
    await tester.tap(find.text('Official tickets'));
    expect(ticketOpens, 1);
    await render(EventPhase.today);
    expect(find.text('Official tickets'), findsNothing);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Cheer guides'), findsOneWidget);
    await render(EventPhase.after);
    expect(find.text('Directions'), findsNothing);
    expect(find.text('Official tickets'), findsNothing);
    expect(find.text('Record attendance'), findsOneWidget);
    expect(find.text('Write a report'), findsOneWidget);
  });

  testWidgets('setlist failure retries independently of usable venue access', (
    tester,
  ) async {
    var retries = 0;
    var directions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              EventAccessSection(
                event: _event,
                onDirections: () => directions++,
              ),
              FieldEventSetlistSection(
                state: AsyncError(StateError('setlist'), StackTrace.empty),
                onSongTap: (_) {},
                onRetry: () => retries++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Directions'));
    await tester.tap(find.text('Retry'));
    expect(directions, 1);
    expect(retries, 1);
    expect(find.text('Tokyo venue address'), findsOneWidget);
  });

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('preparation golden $locale dark=$dark 320dp 200%', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: const [Locale('ja'), Locale('ko')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: dark ? GBTTheme.dark : GBTTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: RepaintBoundary(
                key: const ValueKey('preparation'),
                child: Scaffold(
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FieldEventTicketDocument(
                        event: _event,
                        attendance: const LiveAttendanceViewState(
                          attendance: LiveAttendanceState(
                            liveEventId: 'event-1',
                            attended: false,
                            status: 'NONE',
                            canUndo: false,
                          ),
                        ),
                        onAttendanceToggle: null,
                        onTicketTap: null,
                        showActions: false,
                        now: DateTime.utc(2026, 10, 3),
                      ),
                      const SizedBox(height: 24),
                      EventAccessSection(event: _event, onDirections: () {}),
                      const SizedBox(height: 24),
                      EventPreparationSection(
                        onCheerGuide: () {},
                        onReturnRoute: () {},
                      ),
                    ],
                  ),
                  bottomNavigationBar: EventActionBar(
                    phase: EventPhase.before,
                    onTicket: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(locale == 'ja' ? '公式チケット' : '공식 티켓'), findsOneWidget);
        await expectLater(
          find.byKey(const ValueKey('preparation')),
          matchesGoldenFile(
            '$platformGoldenDirectory/event_preparation_${locale}_${dark ? 'dark' : 'light'}_320_200.png',
          ),
        );
      });
    }
  }
}

final _event = LiveEventDetail(
  id: 'event-1',
  title: 'LIVE TOUR TOKYO',
  venue: 'TOKYO HALL',
  address: 'Tokyo venue address',
  showStartTime: DateTime.utc(2026, 10, 4, 9),
  status: 'SCHEDULED',
  projectIds: const ['project-1'],
  unitIds: const [],
);
