import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/constants/api_constants.dart';
import 'package:girlsbandtabi_app/core/network/api_client.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:girlsbandtabi_app/features/calendar/data/dto/calendar_event_dto.dart';

void main() {
  late _MockApiClient apiClient;
  late CalendarRemoteDataSource dataSource;

  setUp(() {
    apiClient = _MockApiClient();
    dataSource = CalendarRemoteDataSource(apiClient: apiClient);
    when(
      () => apiClient.get<List<CalendarEventDto>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const Result.success([]));
  });

  test('sends the selected project as projectKey to calendar API', () async {
    await dataSource.fetchEvents(
      year: 2026,
      month: 7,
      projectKey: 'bang-dream',
    );

    final captured =
        verify(
              () => apiClient.get<List<CalendarEventDto>>(
                ApiEndpoints.calendarEvents,
                queryParameters: captureAny(named: 'queryParameters'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['projectKey'], 'bang-dream');
    expect(captured, isNot(contains('projectId')));
  });

  test('requests live events with a previous-month overlap buffer', () async {
    await dataSource.fetchLiveEvents(
      year: 2026,
      month: 7,
      projectKey: 'bang-dream',
    );

    final captured =
        verify(
              () => apiClient.get<List<CalendarEventDto>>(
                ApiEndpoints.liveEvents('bang-dream'),
                queryParameters: captureAny(named: 'queryParameters'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    final from = DateTime.parse(captured['from'] as String).toLocal();
    final to = DateTime.parse(captured['to'] as String).toLocal();

    expect(from, DateTime(2026, 6));
    expect(to.add(const Duration(microseconds: 1)), DateTime(2026, 8));
    expect(captured['page'], 0);
    expect(captured['size'], 100);
  });

  test('continues through full live-event pages', () async {
    var requestCount = 0;
    when(
      () => apiClient.get<List<CalendarEventDto>>(
        ApiEndpoints.liveEvents('bang-dream'),
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((invocation) async {
      requestCount += 1;
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      final page = query['page'] as int;
      if (page == 0) {
        return Result.success(
          List.generate(
            100,
            (index) => CalendarEventDto(
              id: 'live:$index',
              title: 'Live $index',
              date: DateTime(2026, 7, 1),
              type: 'live',
              relatedEntityId: '$index',
            ),
          ),
        );
      }
      return Result.success([
        CalendarEventDto(
          id: 'live:100',
          title: 'Live 100',
          date: DateTime(2026, 7, 2),
          type: 'live',
          relatedEntityId: '100',
        ),
      ]);
    });

    final result = await dataSource.fetchLiveEvents(
      year: 2026,
      month: 7,
      projectKey: 'bang-dream',
    );

    expect(result.dataOrNull, hasLength(101));
    expect(requestCount, 2);
  });
}

class _MockApiClient extends Mock implements ApiClient {}
