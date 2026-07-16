/// EN: Immutable presentation data for the travel-passport root.
/// KO: 여행 여권 루트 화면을 위한 불변 프레젠테이션 데이터입니다.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../fan_level/domain/entities/fan_level.dart';
import '../../../settings/domain/entities/user_profile.dart';

/// EN: Availability of authenticated profile-backed passport values.
/// KO: 인증 프로필 기반 여권 값의 가용 상태입니다.
enum PassportProfileStatus { loading, ready, unavailable }

/// EN: Availability of the current-and-next-month calendar window.
/// KO: 이번 달과 다음 달 캘린더 조회 구간의 가용 상태입니다.
enum PassportScheduleStatus { loading, ready, unavailable }

/// EN: Screen-ready data derived only from existing domain entities.
/// KO: 기존 도메인 엔티티에서만 파생한 화면용 데이터입니다.
@immutable
class TravelPassportViewData {
  TravelPassportViewData({
    required this.displayName,
    required this.avatarUrl,
    required this.memberSince,
    required this.ledger,
    required this.fanStamp,
    this.profileStatus = PassportProfileStatus.ready,
    this.scheduleStatus = PassportScheduleStatus.ready,
    List<UpcomingStopData> upcomingStops = const [],
  }) : upcomingStops = List.unmodifiable(upcomingStops);

  final String? displayName;
  final String? avatarUrl;
  final DateTime? memberSince;
  final JourneyLedgerData ledger;
  final FanStampData? fanStamp;
  final PassportProfileStatus profileStatus;
  final PassportScheduleStatus scheduleStatus;
  final List<UpcomingStopData> upcomingStops;

  /// EN: Maps profile, fan activity, and calendar sources without inventing
  ///     destinations, counters, or account metadata.
  /// KO: 목적지, 수치, 계정 메타데이터를 임의로 만들지 않고 프로필, 팬 활동,
  ///     캘린더 소스를 매핑합니다.
  factory TravelPassportViewData.fromDomain({
    required UserProfile? profile,
    required FanLevelProfile? fanProfile,
    required Iterable<CalendarEvent> calendarEvents,
    required DateTime now,
    PassportProfileStatus profileStatus = PassportProfileStatus.ready,
    PassportScheduleStatus scheduleStatus = PassportScheduleStatus.ready,
  }) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final uniqueFutureEvents = <String, CalendarEvent>{};
    for (final event in calendarEvents) {
      if (event.date.toLocal().isBefore(startOfToday)) continue;
      uniqueFutureEvents[event.id] = event;
    }
    final sortedEvents = uniqueFutureEvents.values.toList(growable: false)
      ..sort((left, right) => left.date.compareTo(right.date));

    return TravelPassportViewData(
      displayName: _nonBlank(profile?.displayName),
      avatarUrl: _nonBlank(profile?.avatarUrl),
      memberSince: profile?.createdAt,
      profileStatus: profileStatus,
      ledger: JourneyLedgerData(
        totalVisits: _nonNegative(profile?.totalVisits),
        uniquePlaces: _nonNegative(profile?.uniquePlacesVisited),
        liveAttendances: _nonNegative(profile?.liveAttendanceCount),
        sharedNotes: _nonNegative(profile?.postCount),
      ),
      fanStamp: fanProfile == null
          ? null
          : FanStampData(
              grade: fanProfile.grade,
              rank: math.max(0, fanProfile.rank),
              streakDays: math.max(0, fanProfile.consecutiveDays),
            ),
      scheduleStatus: scheduleStatus,
      upcomingStops: sortedEvents
          .take(3)
          .map(UpcomingStopData.fromCalendarEvent)
          .toList(growable: false),
    );
  }

  static int _nonNegative(int? value) => math.max(0, value ?? 0);

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// EN: Account-backed journey totals shown as a ruled ledger.
/// KO: 줄이 그어진 원장 형태로 표시하는 계정 기반 여행 합계입니다.
@immutable
class JourneyLedgerData {
  const JourneyLedgerData({
    required this.totalVisits,
    required this.uniquePlaces,
    required this.liveAttendances,
    required this.sharedNotes,
  });

  final int totalVisits;
  final int uniquePlaces;
  final int liveAttendances;
  final int sharedNotes;
}

/// EN: Compact fan-grade metadata; intentionally secondary to travel history.
/// KO: 여행 기록보다 낮은 위계로 표시하는 간결한 팬 등급 메타데이터입니다.
@immutable
class FanStampData {
  const FanStampData({
    required this.grade,
    required this.rank,
    required this.streakDays,
  });

  final FanGrade grade;
  final int rank;
  final int streakDays;
}

/// EN: A real calendar-backed upcoming stop.
/// KO: 실제 캘린더 데이터를 기반으로 한 다가오는 일정입니다.
@immutable
class UpcomingStopData {
  const UpcomingStopData({
    required this.eventId,
    required this.title,
    required this.date,
    required this.type,
    this.relatedLiveEventId,
  });

  final String eventId;
  final String title;
  final DateTime date;
  final CalendarEventType type;
  final String? relatedLiveEventId;

  factory UpcomingStopData.fromCalendarEvent(CalendarEvent event) {
    final relatedId = event.relatedEntityId?.trim();
    return UpcomingStopData(
      eventId: event.id,
      title: event.title,
      date: event.date,
      type: event.type,
      relatedLiveEventId:
          event.type == CalendarEventType.live && relatedId?.isNotEmpty == true
          ? relatedId
          : null,
    );
  }
}
