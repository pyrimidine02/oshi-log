import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/home/domain/entities/home_summary.dart';
import 'package:girlsbandtabi_app/features/home/presentation/field_home/field_home_view_data.dart';

void main() {
  group('resolveFieldHomeContentState', () {
    test('uses hard empty only when no source content exists', () {
      final state = resolveFieldHomeContentState(
        _summary(sourcePlaces: 0),
        now: DateTime(2026, 7, 15),
      );

      expect(state, FieldHomeContentState.hardEmpty);
    });

    test('uses soft empty when source content was filtered out', () {
      final state = resolveFieldHomeContentState(
        _summary(sourcePlaces: 12),
        now: DateTime(2026, 7, 15),
      );

      expect(state, FieldHomeContentState.softEmpty);
    });

    test('uses soft empty when the only event is already over', () {
      final state = resolveFieldHomeContentState(
        _summary(
          sourceEvents: 1,
          events: [_event('past', DateTime(2026, 7, 14))],
        ),
        now: DateTime(2026, 7, 15),
      );

      expect(state, FieldHomeContentState.softEmpty);
    });

    test('uses content when at least one visible card remains', () {
      final state = resolveFieldHomeContentState(
        _summary(
          sourceEvents: 1,
          events: [_event('next', DateTime(2026, 7, 16))],
        ),
        now: DateTime(2026, 7, 15),
      );

      expect(state, FieldHomeContentState.content);
    });
  });

  group('selectUpcomingHomeEvents', () {
    final now = DateTime(2026, 7, 15, 12);

    test('drops past events and orders the remaining itinerary', () {
      final events = [
        _event('later', DateTime(2026, 7, 18)),
        _event('past', DateTime(2026, 7, 14)),
        _event('next', DateTime(2026, 7, 16)),
      ];

      final result = selectUpcomingHomeEvents(events, now: now);

      expect(result.map((event) => event.id), ['next', 'later']);
      expect(events.map((event) => event.id), ['later', 'past', 'next']);
    });

    test('keeps an event starting exactly now', () {
      final result = selectUpcomingHomeEvents([_event('now', now)], now: now);

      expect(result.single.id, 'now');
    });
  });

  group('composeFieldHome', () {
    final now = DateTime(2026, 7, 15, 12);

    test('uses the next event once and removes it from the agenda', () {
      final next = _event('next', DateTime(2026, 7, 16));
      final later = _event('later', DateTime(2026, 7, 18));
      final summary = _summary(
        sourceEvents: 2,
        events: [later, next],
        places: const [HomePlaceItem(id: 'place-1', name: '시모키타자와')],
      );

      final result = composeFieldHome(summary, now: now);

      expect(result.leadEvent?.id, 'next');
      expect(result.leadPlace, isNull);
      expect(result.agendaEvents.map((event) => event.id), ['later']);
      expect(result.pilgrimagePlaces.map((place) => place.id), ['place-1']);
      expect(summary.trendingLiveEvents.map((event) => event.id), [
        'later',
        'next',
      ]);
    });

    test('uses a place once when no upcoming event exists', () {
      const first = HomePlaceItem(id: 'place-1', name: '시모키타자와');
      const second = HomePlaceItem(id: 'place-2', name: '카와사키');
      final summary = _summary(places: const [first, second]);

      final result = composeFieldHome(summary, now: now);

      expect(result.leadEvent, isNull);
      expect(result.leadPlace?.id, 'place-1');
      expect(result.pilgrimagePlaces.map((place) => place.id), ['place-2']);
    });
  });
}

HomeSummary _summary({
  int sourcePlaces = 0,
  int sourceEvents = 0,
  List<HomeEventItem> events = const [],
  List<HomePlaceItem> places = const [],
}) {
  return HomeSummary(
    recommendedPlaces: places,
    trendingLiveEvents: events,
    latestNews: const [],
    metadata: HomeSummaryMetadata(
      sourceCounts: HomeSourceCounts(
        places: sourcePlaces,
        liveEvents: sourceEvents,
        news: 0,
      ),
      fallbackApplied: const HomeFallbackApplied(
        recommendedPlaces: false,
        trendingLiveEvents: false,
      ),
    ),
  );
}

HomeEventItem _event(String id, DateTime startsAt) {
  return HomeEventItem(id: id, title: id, dateLabel: '', startsAt: startsAt);
}
