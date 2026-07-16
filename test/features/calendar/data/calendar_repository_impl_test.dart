import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/error/failure.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:girlsbandtabi_app/features/calendar/data/dto/calendar_event_dto.dart';
import 'package:girlsbandtabi_app/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:girlsbandtabi_app/features/calendar/domain/entities/calendar_event.dart';

void main() {
  late _MockCalendarRemoteDataSource remoteDataSource;
  late CalendarRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockCalendarRemoteDataSource();
    repository = CalendarRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  test('merges monthly live events into calendar events', () async {
    when(
      () => remoteDataSource.fetchEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer((_) async => Result.success([_fanEvent]));
    when(
      () => remoteDataSource.fetchLiveEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer((_) async => Result.success([_liveEvent]));

    final result = await repository.fetchEvents(
      year: 2026,
      month: 7,
      projectKey: 'bang-dream',
    );

    final events = result.dataOrNull!;
    expect(events, hasLength(2));
    expect(events.first.id, _fanEvent.id);
    expect(events.last.id, _liveEvent.id);
    expect(events.last.type, CalendarEventType.live);
    expect(events.last.relatedEntityId, 'live-1');
  });

  test('normalizes UTC live start times to the device calendar date', () async {
    final utcLive = CalendarEventDto(
      id: 'live:utc-live',
      title: 'UTC live',
      date: DateTime.parse('2026-07-17T15:00:00Z'),
      type: 'live',
      relatedEntityId: 'utc-live',
      relatedEntityType: 'live_event',
    );
    when(
      () => remoteDataSource.fetchEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => remoteDataSource.fetchLiveEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer((_) async => Result.success([utcLive]));

    final result = await repository.fetchEvents(
      year: 2026,
      month: 7,
      projectKey: 'bang-dream',
    );

    final event = result.dataOrNull!.single;
    expect(event.date, utcLive.date.toLocal());
    expect(event.date.isUtc, isFalse);
  });

  test(
    'keeps live schedules available when fan calendar is unauthorized',
    () async {
      when(
        () => remoteDataSource.fetchEvents(
          year: 2026,
          month: 7,
          projectKey: 'bang-dream',
        ),
      ).thenAnswer(
        (_) async => const Result.failure(
          AuthFailure('Authentication required', code: '401'),
        ),
      );
      when(
        () => remoteDataSource.fetchLiveEvents(
          year: 2026,
          month: 7,
          projectKey: 'bang-dream',
        ),
      ).thenAnswer((_) async => Result.success([_liveEvent]));

      final result = await repository.fetchEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      );

      expect(result, isA<Success<List<CalendarEvent>>>());
      expect(result.dataOrNull!.single.id, _liveEvent.id);
    },
  );

  test(
    'does not request project live events without a project selection',
    () async {
      when(
        () => remoteDataSource.fetchEvents(
          year: 2026,
          month: 7,
          projectKey: null,
        ),
      ).thenAnswer((_) async => Result.success([_fanEvent]));

      final result = await repository.fetchEvents(year: 2026, month: 7);

      expect(result.dataOrNull, hasLength(1));
      verifyNever(
        () => remoteDataSource.fetchLiveEvents(
          year: any(named: 'year'),
          month: any(named: 'month'),
          projectKey: any(named: 'projectKey'),
        ),
      );
    },
  );

  test('does not claim an empty month when one source failed', () async {
    when(
      () => remoteDataSource.fetchEvents(
        year: 2026,
        month: 8,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => remoteDataSource.fetchLiveEvents(
        year: 2026,
        month: 8,
        projectKey: 'bang-dream',
      ),
    ).thenAnswer(
      (_) async => const Result.failure(NetworkFailure('Live API failed')),
    );

    final result = await repository.fetchEvents(
      year: 2026,
      month: 8,
      projectKey: 'bang-dream',
    );

    expect(result, isA<Err<List<CalendarEvent>>>());
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test(
    'projects each day of a multi-day live into the visible month',
    () async {
      final multiDayLive = CalendarEventDto(
        id: 'live:mygo-9th',
        title: 'MyGO!!!!! 9th LIVE',
        date: DateTime(2026, 7, 18),
        endDate: DateTime(2026, 7, 19, 23, 59),
        type: 'live',
        relatedEntityId: 'mygo-9th',
        relatedEntityType: 'live_event',
      );
      when(
        () => remoteDataSource.fetchEvents(
          year: 2026,
          month: 7,
          projectKey: 'bang-dream',
        ),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => remoteDataSource.fetchLiveEvents(
          year: 2026,
          month: 7,
          projectKey: 'bang-dream',
        ),
      ).thenAnswer((_) async => Result.success([multiDayLive]));

      final result = await repository.fetchEvents(
        year: 2026,
        month: 7,
        projectKey: 'bang-dream',
      );

      final events = result.dataOrNull!;
      expect(events, hasLength(2));
      expect(events.map((event) => event.date.day), [18, 19]);
      expect(events.map((event) => event.relatedEntityId).toSet(), {
        'mygo-9th',
      });
    },
  );
}

class _MockCalendarRemoteDataSource extends Mock
    implements CalendarRemoteDataSource {}

final _fanEvent = CalendarEventDto(
  id: 'fan-1',
  title: 'Fan anniversary',
  date: DateTime(2026, 7, 1),
  type: 'EVENT',
);

final _liveEvent = CalendarEventDto(
  id: 'live:live-1',
  title: 'MyGO!!!!! 9th LIVE',
  date: DateTime(2026, 7, 18),
  type: 'live',
  projectId: 'project-id',
  projectCode: 'bang-dream',
  relatedEntityId: 'live-1',
  relatedEntityType: 'live_event',
);
