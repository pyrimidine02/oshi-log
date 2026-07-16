/// EN: Remote data source for calendar events.
/// KO: 캘린더 이벤트의 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/calendar_event_dto.dart';

/// EN: Fetches calendar events from the remote API.
/// KO: 원격 API에서 캘린더 이벤트를 조회합니다.
class CalendarRemoteDataSource {
  const CalendarRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// EN: Fetches events for the given year and month, optionally filtered by project.
  /// KO: 주어진 연도/월의 이벤트를 조회합니다. 프로젝트로 필터링할 수 있습니다.
  Future<Result<List<CalendarEventDto>>> fetchEvents({
    required int year,
    required int month,
    String? projectKey,
  }) {
    return apiClient.get<List<CalendarEventDto>>(
      ApiEndpoints.calendarEvents,
      queryParameters: {
        'year': year,
        'month': month,
        if (projectKey != null) 'projectKey': projectKey,
      },
      fromJson: (json) {
        // EN: Accept both a root list and an object with a named items key.
        // KO: 최상위 배열과 named items 키를 가진 객체를 모두 허용합니다.
        final List<dynamic> items;
        if (json is List) {
          items = json;
        } else if (json is Map<String, dynamic>) {
          items =
              (json['events'] ??
                      json['items'] ??
                      json['data'] ??
                      const <dynamic>[])
                  as List<dynamic>;
        } else {
          items = const <dynamic>[];
        }
        return items
            .whereType<Map<String, dynamic>>()
            .map(CalendarEventDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Fetches live events constrained to the visible local calendar month.
  /// KO: 현재 보이는 로컬 캘린더 월로 범위를 제한해 라이브 이벤트를 조회합니다.
  Future<Result<List<CalendarEventDto>>> fetchLiveEvents({
    required int year,
    required int month,
    required String projectKey,
  }) async {
    // EN: Include the previous month so an event crossing the month boundary
    //     can still be projected when its end time overlaps the visible month.
    // KO: 이전 달에 시작해 현재 달까지 이어지는 이벤트도 투영할 수 있도록
    //     조회 시작 범위에 이전 달을 포함합니다.
    final rangeStart = DateTime(year, month - 1);
    final nextMonthStart = DateTime(year, month + 1);
    final rangeEnd = nextMonthStart.subtract(const Duration(microseconds: 1));
    const pageSize = 100;
    const maxPages = 20;
    final events = <CalendarEventDto>[];

    for (var page = 0; page < maxPages; page++) {
      final result = await apiClient.get<List<CalendarEventDto>>(
        ApiEndpoints.liveEvents(projectKey),
        queryParameters: {
          'from': rangeStart.toUtc().toIso8601String(),
          'to': rangeEnd.toUtc().toIso8601String(),
          'page': page,
          'size': pageSize,
        },
        fromJson: (json) => _decodeItems(json)
            .map(
              (item) => CalendarEventDto.fromLiveEventJson(
                item,
                projectKey: projectKey,
              ),
            )
            .toList(growable: false),
      );
      final pageEvents = result.dataOrNull;
      if (pageEvents == null) {
        return Result.failure(result.failureOrNull!);
      }
      events.addAll(pageEvents);
      if (pageEvents.length < pageSize) {
        break;
      }
    }
    return Result.success(List<CalendarEventDto>.unmodifiable(events));
  }
}

List<Map<String, dynamic>> _decodeItems(dynamic json) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  if (json is Map<String, dynamic>) {
    final items =
        json['events'] ??
        json['items'] ??
        json['content'] ??
        json['data'] ??
        const <dynamic>[];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList(growable: false);
    }
  }
  return const [];
}
