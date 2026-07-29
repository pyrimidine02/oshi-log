import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/calendar/domain/entities/calendar_event.dart';
import 'package:oshi_log/features/fan_level/domain/entities/fan_level.dart';
import 'package:oshi_log/features/my/presentation/travel_passport/travel_passport_view_data.dart';
import 'package:oshi_log/features/settings/domain/entities/user_profile.dart';

void main() {
  group('TravelPassportViewData', () {
    test('maps only real profile and fan-level values', () {
      final profile = _profile();
      const fanProfile = FanLevelProfile(
        userId: 'traveler-01',
        grade: FanGrade.devotee,
        totalXp: 4200,
        currentLevelXp: 200,
        nextLevelXp: 1000,
        rank: 27,
        consecutiveDays: 9,
      );

      final data = TravelPassportViewData.fromDomain(
        profile: profile,
        fanProfile: fanProfile,
        calendarEvents: const [],
        now: DateTime(2026, 7, 15, 12),
      );

      expect(data.displayName, 'Hina');
      expect(data.memberSince, DateTime(2024, 3, 7));
      expect(data.ledger.totalVisits, 18);
      expect(data.ledger.uniquePlaces, 12);
      expect(data.ledger.liveAttendances, 4);
      expect(data.ledger.sharedNotes, 7);
      expect(data.fanStamp?.grade, FanGrade.devotee);
      expect(data.fanStamp?.rank, 27);
      expect(data.fanStamp?.streakDays, 9);
    });

    test('keeps only future schedule rows, sorted and immutable', () {
      final events = <CalendarEvent>[
        CalendarEvent(
          id: 'late',
          title: 'Late live',
          date: DateTime(2026, 7, 28),
          type: CalendarEventType.live,
          relatedEntityId: 'live-28',
          relatedEntityType: 'LIVE_EVENT',
        ),
        CalendarEvent(
          id: 'past',
          title: 'Past live',
          date: DateTime(2026, 7, 14),
          type: CalendarEventType.live,
        ),
        CalendarEvent(
          id: 'today',
          title: 'Today ticket sale',
          date: DateTime(2026, 7, 15, 9),
          type: CalendarEventType.ticketSale,
        ),
        CalendarEvent(
          id: 'next',
          title: 'Next release',
          date: DateTime(2026, 7, 19),
          type: CalendarEventType.release,
        ),
      ];

      final data = TravelPassportViewData.fromDomain(
        profile: _profile(),
        fanProfile: null,
        calendarEvents: events,
        now: DateTime(2026, 7, 15, 18),
      );

      expect(data.upcomingStops.map((stop) => stop.eventId), [
        'today',
        'next',
        'late',
      ]);
      expect(data.upcomingStops.first.relatedLiveEventId, isNull);
      expect(data.upcomingStops.last.relatedLiveEventId, 'live-28');
      expect(
        () => data.upcomingStops.add(data.upcomingStops.first),
        throwsUnsupportedError,
      );
    });

    test(
      'does not fabricate profile, grade, or counters when data is absent',
      () {
        final data = TravelPassportViewData.fromDomain(
          profile: null,
          fanProfile: null,
          calendarEvents: const [],
          now: DateTime(2026, 7, 15),
        );

        expect(data.displayName, isNull);
        expect(data.memberSince, isNull);
        expect(data.avatarUrl, isNull);
        expect(data.fanStamp, isNull);
        expect(data.profileStatus, PassportProfileStatus.ready);
        expect(data.scheduleStatus, PassportScheduleStatus.ready);
        expect(data.ledger.totalVisits, 0);
        expect(data.upcomingStops, isEmpty);
      },
    );
  });
}

UserProfile _profile() {
  return UserProfile(
    id: 'traveler-01',
    email: 'hina@example.com',
    displayName: 'Hina',
    role: 'USER',
    accountRole: 'USER',
    baselineAccessLevel: 'MEMBER',
    effectiveAccessLevel: 'MEMBER',
    grants: const [],
    projectRolesByProject: const {},
    createdAt: DateTime(2024, 3, 7),
    avatarUrl: 'https://example.com/avatar.jpg',
    totalVisits: 18,
    uniquePlacesVisited: 12,
    liveAttendanceCount: 4,
    postCount: 7,
  );
}
