import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_event_view_data.dart';

void main() {
  final now = DateTime(2026, 7, 15, 12);
  final events = <LiveEventSummary>[
    _event('past', DateTime(2025, 5, 1), unitIds: const ['u1']),
    _event('later', DateTime(2026, 8, 10), unitIds: const ['u2']),
    _event('next', DateTime(2026, 7, 20), unitIds: const ['u1']),
  ];

  test('upcoming field agenda is chronological and does not mutate input', () {
    final originalOrder = events.map((event) => event.id).toList();

    final result = selectFieldEvents(
      events,
      filter: FieldEventFilter(mode: FieldEventMode.upcoming),
      now: now,
    );

    expect(result.map((event) => event.id), ['next', 'later']);
    expect(events.map((event) => event.id), originalOrder);
  });

  test('archive supports immutable year and unit filters', () {
    final filter = FieldEventFilter(mode: FieldEventMode.archive);
    final narrowed = filter.copyWith(unitIds: const ['u1'], year: 2025);

    expect(filter.unitIds, isEmpty);
    expect(narrowed.unitIds, ['u1']);
    expect(
      selectFieldEvents(
        events,
        filter: narrowed,
        now: now,
      ).map((event) => event.id),
      ['past'],
    );
    expect(completedFieldEventYears(events, now: now), [2025]);
  });

  test('event windows keep an ongoing show upcoming through its end', () {
    final ongoing = _event(
      'ongoing',
      DateTime(2026, 7, 15, 10),
      endTime: DateTime(2026, 7, 15, 18),
    );
    final endedAtBoundary = _event(
      'ended-at-boundary',
      DateTime(2026, 7, 15, 10),
      endTime: now,
    );
    final malformed = _event(
      'malformed-end',
      DateTime(2026, 7, 15, 11),
      endTime: DateTime(2026, 7, 15, 9),
    );

    expect(isFieldEventUpcoming(ongoing, now: now), isTrue);
    expect(isFieldEventUpcoming(endedAtBoundary, now: now), isFalse);
    expect(effectiveFieldEventEnd(malformed), malformed.showStartTime);
    expect(
      selectFieldEvents(
        [ongoing, endedAtBoundary, malformed],
        filter: FieldEventFilter(mode: FieldEventMode.upcoming),
        now: now,
      ).map((event) => event.id),
      ['ongoing'],
    );
  });
}

LiveEventSummary _event(
  String id,
  DateTime startsAt, {
  List<String> unitIds = const [],
  DateTime? endTime,
}) {
  return LiveEventSummary(
    id: id,
    title: 'Event $id',
    showStartTime: startsAt,
    status: 'SCHEDULED',
    projectIds: const ['p1'],
    unitIds: unitIds,
    endTime: endTime,
  );
}
