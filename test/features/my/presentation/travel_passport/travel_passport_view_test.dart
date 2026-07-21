import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:girlsbandtabi_app/features/fan_level/domain/entities/fan_level.dart';
import 'package:girlsbandtabi_app/features/my/presentation/travel_passport/passport_sections.dart';
import 'package:girlsbandtabi_app/features/my/presentation/travel_passport/travel_passport_view.dart';
import 'package:girlsbandtabi_app/features/my/presentation/travel_passport/travel_passport_view_data.dart';

void main() {
  testWidgets('passport section heading reflows and remains a header at 300%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PassportSectionHeading(
                index: '02',
                title: 'Upcoming schedule',
                eyebrow: 'NEXT DEPARTURES',
                actionLabel: 'Open calendar',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final header = tester.getSemantics(
      find.bySemanticsLabel('02 Upcoming schedule'),
    );
    expect(header.flagsCollection.isHeader, isTrue);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Open calendar'),
              matching: find.byType(TextButton),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets(
    'renders a document-led passport hierarchy without glass or gradients',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: TravelPassportView(
            data: _data(),
            onRefresh: () async {},
            onOpenSettings: () {},
            onOpenFanLevel: () {},
            onOpenCalendar: () {},
            onOpenStop: (_) {},
            onOpenVisits: () {},
            onOpenCollection: () {},
            onOpenBookmarks: () {},
            onOpenFavorites: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('travel-passport-document')), findsOneWidget);
      expect(find.byKey(const Key('journey-ledger')), findsOneWidget);
      expect(find.byKey(const Key('next-stops')), findsOneWidget);
      expect(find.byKey(const Key('travel-archive')), findsOneWidget);
      expect(find.byKey(const Key('fan-grade-stamp')), findsOneWidget);
      expect(find.text('Hina'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Tokyo live'), findsOneWidget);
      expect(find.text('18 total visit records'), findsOneWidget);
      expect(find.textContaining('verified visit'), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('MY FIELD LOG'), findsNothing);
      expect(find.text('TRAVEL DOCUMENT  /  JP'), findsNothing);
      expect(find.text('Travel passport'), findsOneWidget);
      expect(find.text('GIRLS BAND TABI · TRAVEL PASSPORT'), findsOneWidget);
      final sectionHeadings = find.byType(PassportSectionHeading);
      for (final folio in const ['01', '02', '03']) {
        expect(
          find.descendant(of: sectionHeadings, matching: find.text(folio)),
          findsOneWidget,
        );
      }
      expect(find.text('JOURNEY LEDGER'), findsNothing);
      expect(find.text('NEXT DEPARTURES'), findsNothing);
      expect(find.text('ARCHIVE INDEX'), findsNothing);
    },
  );

  testWidgets('archive and schedule rows expose 48dp targets and callbacks', (
    tester,
  ) async {
    var visitsOpened = false;
    String? openedStop;
    await tester.pumpWidget(
      _TestApp(
        child: TravelPassportView(
          data: _data(),
          onRefresh: () async {},
          onOpenSettings: () {},
          onOpenFanLevel: () {},
          onOpenCalendar: () {},
          onOpenStop: (stop) => openedStop = stop.eventId,
          onOpenVisits: () => visitsOpened = true,
          onOpenCollection: () {},
          onOpenBookmarks: () {},
          onOpenFavorites: () {},
        ),
      ),
    );

    final visitsFinder = find.byKey(const Key('archive-visits'));
    final stopFinder = find.byKey(const Key('next-stop-live-01'));
    await tester.ensureVisible(visitsFinder);
    await tester.pumpAndSettle();
    expect(tester.getSize(visitsFinder).height, greaterThanOrEqualTo(48));
    await tester.tap(visitsFinder);
    expect(visitsOpened, isTrue);

    await tester.ensureVisible(stopFinder);
    await tester.pumpAndSettle();
    expect(tester.getSize(stopFinder).height, greaterThanOrEqualTo(48));
    await tester.tap(stopFinder);
    expect(openedStop, 'live-01');
  });

  testWidgets('fits a narrow phone without layout exceptions', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _TestApp(
        child: TravelPassportView(
          data: _data(),
          onRefresh: () async {},
          onOpenSettings: () {},
          onOpenFanLevel: () {},
          onOpenCalendar: () {},
          onOpenStop: (_) {},
          onOpenVisits: () {},
          onOpenCollection: () {},
          onOpenBookmarks: () {},
          onOpenFavorites: () {},
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('distinguishes schedule failure from a truthful empty state', (
    tester,
  ) async {
    final data = TravelPassportViewData(
      displayName: null,
      avatarUrl: null,
      memberSince: null,
      ledger: const JourneyLedgerData(
        totalVisits: 0,
        uniquePlaces: 0,
        liveAttendances: 0,
        sharedNotes: 0,
      ),
      fanStamp: null,
      scheduleStatus: PassportScheduleStatus.unavailable,
    );
    await tester.pumpWidget(
      _TestApp(
        child: TravelPassportView(
          data: data,
          onRefresh: () async {},
          onOpenSettings: () {},
          onOpenFanLevel: () {},
          onOpenCalendar: () {},
          onOpenStop: (_) {},
          onOpenVisits: () {},
          onOpenCollection: () {},
          onOpenBookmarks: () {},
          onOpenFavorites: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('next-stops')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not load upcoming schedule'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('travel-passport-retry')), findsOneWidget);
    expect(find.text('Traveler'), findsOneWidget);
    expect(find.byKey(const Key('fan-grade-stamp')), findsNothing);
  });

  testWidgets(
    'shows schedule loading separately from the two-month empty state',
    (tester) async {
      final data = TravelPassportViewData(
        displayName: 'Hina',
        avatarUrl: null,
        memberSince: DateTime(2024, 3, 7),
        ledger: const JourneyLedgerData(
          totalVisits: 18,
          uniquePlaces: 12,
          liveAttendances: 4,
          sharedNotes: 7,
        ),
        fanStamp: null,
        scheduleStatus: PassportScheduleStatus.loading,
      );
      await tester.pumpWidget(
        _TestApp(
          child: TravelPassportView(
            data: data,
            onRefresh: () async {},
            onOpenSettings: () {},
            onOpenFanLevel: () {},
            onOpenCalendar: () {},
            onOpenStop: (_) {},
            onOpenVisits: () {},
            onOpenCollection: () {},
            onOpenBookmarks: () {},
            onOpenFavorites: () {},
          ),
        ),
      );

      expect(find.textContaining('Loading upcoming schedule'), findsOneWidget);
      expect(
        find.textContaining('No schedule through next month'),
        findsNothing,
      );
    },
  );

  testWidgets('does not present profile loading as a real zero-value account', (
    tester,
  ) async {
    final data = TravelPassportViewData(
      displayName: null,
      avatarUrl: null,
      memberSince: null,
      profileStatus: PassportProfileStatus.loading,
      ledger: const JourneyLedgerData(
        totalVisits: 0,
        uniquePlaces: 0,
        liveAttendances: 0,
        sharedNotes: 0,
      ),
      fanStamp: null,
    );
    await tester.pumpWidget(
      _TestApp(
        child: TravelPassportView(
          data: data,
          onRefresh: () async {},
          onOpenSettings: () {},
          onOpenFanLevel: () {},
          onOpenCalendar: () {},
          onOpenStop: (_) {},
          onOpenVisits: () {},
          onOpenCollection: () {},
          onOpenBookmarks: () {},
          onOpenFavorites: () {},
        ),
      ),
    );

    expect(find.text('Loading profile…'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.textContaining('0 total visit records'), findsNothing);
    expect(
      find.textContaining('No schedule through next month'),
      findsOneWidget,
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData.light(), home: child);
  }
}

TravelPassportViewData _data() {
  return TravelPassportViewData(
    displayName: 'Hina',
    avatarUrl: null,
    memberSince: DateTime(2024, 3, 7),
    ledger: const JourneyLedgerData(
      totalVisits: 18,
      uniquePlaces: 12,
      liveAttendances: 4,
      sharedNotes: 7,
    ),
    fanStamp: const FanStampData(
      grade: FanGrade.devotee,
      rank: 27,
      streakDays: 9,
    ),
    upcomingStops: [
      UpcomingStopData(
        eventId: 'live-01',
        title: 'Tokyo live',
        date: DateTime(2026, 7, 28),
        type: CalendarEventType.live,
        relatedLiveEventId: 'live-01',
      ),
    ],
  );
}
