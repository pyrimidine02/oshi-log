/// EN: Immutable view-data policies for the clean-sheet Field Desk home.
/// KO: 새 Field Desk 홈을 위한 불변 뷰 데이터 정책입니다.
library;

import '../../domain/entities/home_summary.dart';

/// EN: Honest presentation state for the home content area.
/// KO: 홈 콘텐츠 영역을 정직하게 표현하기 위한 상태입니다.
enum FieldHomeContentState {
  /// EN: At least one card can be presented now.
  /// KO: 지금 표시할 수 있는 카드가 하나 이상 있습니다.
  content,

  /// EN: Neither cards nor source content exist.
  /// KO: 카드와 원천 콘텐츠가 모두 없습니다.
  hardEmpty,

  /// EN: Source content exists, but no card passes current presentation rules.
  /// KO: 원천 콘텐츠는 있지만 현재 표시 조건을 통과한 카드가 없습니다.
  softEmpty,
}

/// EN: A de-duplicated home itinerary with one lead and ordered follow-ups.
/// KO: 하나의 대표 항목과 정렬된 후속 항목으로 구성한 중복 없는 홈 여정입니다.
class FieldHomeComposition {
  FieldHomeComposition({
    required this.leadEvent,
    required this.leadPlace,
    required Iterable<HomeEventItem> agendaEvents,
    required Iterable<HomePlaceItem> pilgrimagePlaces,
  }) : agendaEvents = List.unmodifiable(agendaEvents),
       pilgrimagePlaces = List.unmodifiable(pilgrimagePlaces);

  final HomeEventItem? leadEvent;
  final HomePlaceItem? leadPlace;
  final List<HomeEventItem> agendaEvents;
  final List<HomePlaceItem> pilgrimagePlaces;
}

/// EN: Distinguishes missing source content from presentation-filtered content.
/// KO: 원천 콘텐츠 부재와 표시 조건으로 걸러진 상태를 구분합니다.
FieldHomeContentState resolveFieldHomeContentState(
  HomeSummary summary, {
  required DateTime now,
}) {
  final hasVisibleContent =
      summary.recommendedPlaces.isNotEmpty ||
      summary.latestNews.isNotEmpty ||
      summary.trendingLiveEvents.any((event) => !event.startsAt.isBefore(now));
  if (hasVisibleContent) return FieldHomeContentState.content;
  if (summary.shouldShowNoContentEmptyState) {
    return FieldHomeContentState.hardEmpty;
  }
  return FieldHomeContentState.softEmpty;
}

/// EN: Returns a new chronological list containing only events that have not
///     started before [now]. The source collection is never mutated.
/// KO: [now]보다 먼저 시작하지 않은 이벤트만 새 시간순 목록으로 반환하며,
///     원본 컬렉션은 변경하지 않습니다.
List<HomeEventItem> selectUpcomingHomeEvents(
  Iterable<HomeEventItem> events, {
  required DateTime now,
}) {
  final upcoming = events
      .where((event) => !event.startsAt.isBefore(now))
      .toList(growable: false);
  return [...upcoming]
    ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
}

/// EN: Builds an event-first briefing and removes the lead from lower sections.
/// KO: 일정 우선 브리핑을 만들고 대표 항목을 아래 섹션에서 제거합니다.
FieldHomeComposition composeFieldHome(
  HomeSummary summary, {
  required DateTime now,
}) {
  final events = selectUpcomingHomeEvents(summary.trendingLiveEvents, now: now);
  if (events.isNotEmpty) {
    return FieldHomeComposition(
      leadEvent: events.first,
      leadPlace: null,
      agendaEvents: events.skip(1),
      pilgrimagePlaces: summary.recommendedPlaces,
    );
  }

  final places = summary.recommendedPlaces;
  return FieldHomeComposition(
    leadEvent: null,
    leadPlace: places.isEmpty ? null : places.first,
    agendaEvents: const [],
    pilgrimagePlaces: places.skip(1),
  );
}
