import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_agenda_widgets.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_detail_widgets.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/live_schedule_status_badge.dart';

void main() {
  Widget host(Widget child, {String locale = 'ko'}) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
    theme: GBTTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  LiveEventDetail detail(String scheduleStatus, {String? rescheduledId}) =>
      LiveEventDetail(
        id: 'live-1',
        title: 'FIELD SHOW',
        showStartTime: DateTime(2026, 11, 20, 18),
        status: 'SCHEDULED',
        projectIds: const ['p1'],
        unitIds: const [],
        scheduleStatus: scheduleStatus,
        rescheduledEventId: rescheduledId,
      );

  Future<({int toggles, int tickets, int reschedules})> pumpDocument(
    WidgetTester tester,
    LiveEventDetail event,
  ) async {
    var toggles = 0, tickets = 0, reschedules = 0;
    await tester.pumpWidget(
      host(
        FieldEventTicketDocument(
          event: event,
          attendance: LiveAttendanceViewState(
            attendance: LiveAttendanceState.none(event.id),
          ),
          onAttendanceToggle: () => toggles++,
          onTicketTap: () => tickets++,
          onRescheduledTap: () => reschedules++,
        ),
      ),
    );
    await tester.tap(find.byType(FieldAttendanceStamp), warnIfMissed: false);
    if (find.text('새 일정 보기').evaluate().isNotEmpty) {
      await tester.tap(find.text('새 일정 보기'));
    }
    return (toggles: toggles, tickets: tickets, reschedules: reschedules);
  }

  testWidgets('agenda row shows 취소 badge only for cancelled events', (
    tester,
  ) async {
    LiveEventSummary summary(String status) => LiveEventSummary(
      id: status,
      title: 'ROW $status',
      showStartTime: DateTime(2026, 11, 20, 18),
      status: 'SCHEDULED',
      projectIds: const ['p1'],
      unitIds: const [],
      scheduleStatus: status,
    );

    await tester.pumpWidget(
      host(
        Column(
          children: [
            FieldEventAgendaRow(
              event: summary(LiveScheduleStatus.cancelled),
              attended: false,
              onTap: () {},
            ),
            FieldEventAgendaRow(
              event: summary(LiveScheduleStatus.scheduled),
              attended: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('취소'), findsOneWidget);
    expect(find.text('연기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('badge is localized for en and ja', (tester) async {
    const badge = LiveScheduleStatusBadge(status: LiveScheduleStatus.postponed);
    await tester.pumpWidget(host(badge, locale: 'en'));
    expect(find.text('Postponed'), findsOneWidget);
    await tester.pumpWidget(host(badge, locale: 'ja'));
    expect(find.text('延期'), findsOneWidget);
  });

  testWidgets('cancelled detail hides ticket and disables attendance', (
    tester,
  ) async {
    final taps = await pumpDocument(
      tester,
      detail(LiveScheduleStatus.cancelled),
    );

    expect(find.text('취소'), findsOneWidget);
    expect(find.text('이 공연은 취소되었습니다'), findsOneWidget);
    expect(find.text('티켓 페이지 열기'), findsNothing);
    expect(find.text('새 일정 보기'), findsNothing);
    expect(taps.toggles, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('postponed detail with new event links to it', (tester) async {
    final taps = await pumpDocument(
      tester,
      detail(LiveScheduleStatus.postponed, rescheduledId: 'live-2'),
    );

    expect(find.text('연기'), findsOneWidget);
    expect(find.text('새 일정 보기'), findsOneWidget);
    expect(taps.reschedules, 1);
    expect(taps.toggles, 0);
    expect(find.text('티켓 페이지 열기'), findsOneWidget);
  });

  testWidgets('postponed detail without new event says date is TBA', (
    tester,
  ) async {
    final taps = await pumpDocument(
      tester,
      detail(LiveScheduleStatus.postponed),
    );

    expect(find.text('연기 — 새 일정 미정'), findsOneWidget);
    expect(find.text('새 일정 보기'), findsNothing);
    expect(taps.toggles, 1);
  });

  testWidgets('scheduled detail keeps attendance and no badge', (tester) async {
    final taps = await pumpDocument(
      tester,
      detail(LiveScheduleStatus.scheduled),
    );

    expect(find.text('취소'), findsNothing);
    expect(find.text('연기'), findsNothing);
    expect(taps.toggles, 1);
  });

  test('recognizes not-attendable server failures', () {
    expect(
      isLiveNotAttendableFailure(
        const ValidationFailure('x', code: 'LIVE_EVENT_NOT_ATTENDABLE'),
      ),
      isTrue,
    );
    expect(
      isLiveNotAttendableFailure(
        const ValidationFailure(
          'Live event is not open for attendance (cancelled or rescheduled)',
          code: 'ATTENDANCE_UPDATE_FAILED',
        ),
      ),
      isTrue,
    );
    expect(
      isLiveNotAttendableFailure(
        const ValidationFailure('x', code: 'ATTENDANCE_UPDATE_FAILED'),
      ),
      isFalse,
    );
    expect(
      const ValidationFailure(
        'x',
        code: 'LIVE_EVENT_NOT_ATTENDABLE',
      ).userMessage,
      contains('취소'),
    );
  });
}
