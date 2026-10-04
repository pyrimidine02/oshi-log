/// EN: Remote data source for live events API.
/// KO: 라이브 이벤트 API 원격 데이터 소스.
library;

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/data/dto/live_event_dto.dart';

class LiveEventsRemoteDataSource {
  LiveEventsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Fetch all live events for a project. Unit filtering is done client-side.
  /// KO: 프로젝트의 전체 라이브 이벤트를 조회합니다. 유닛 필터링은 클라이언트에서 처리합니다.
  Future<Result<List<LiveEventSummaryDto>>> fetchLiveEvents({
    required String projectId,
    int page = ApiPagination.defaultPage,
    int size = 500,
  }) {
    return _apiClient.get<List<LiveEventSummaryDto>>(
      ApiEndpoints.liveEvents(projectId),
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) => _decodeLiveEventList(json),
    );
  }

  /// EN: Fetch live event detail.
  /// KO: 라이브 이벤트 상세를 조회합니다.
  Future<Result<LiveEventDetailDto>> fetchLiveEventDetail({
    required String projectId,
    required String eventId,
  }) {
    return _apiClient.get<LiveEventDetailDto>(
      ApiEndpoints.liveEvent(projectId, eventId),
      fromJson: (json) =>
          LiveEventDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Toggle live attendance declaration (v1).
  /// KO: 라이브 방문 선언 토글(v1)을 수행합니다.
  Future<Result<LiveAttendanceStateDto>> toggleLiveAttendance({
    required String projectId,
    required String eventId,
    required bool attended,
  }) {
    return _apiClient.put<LiveAttendanceStateDto>(
      ApiEndpoints.liveEventAttendance(projectId, eventId),
      data: LiveAttendanceToggleRequestDto(attended: attended).toJson(),
      fromJson: (json) =>
          LiveAttendanceStateDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch current user's attendance state for a live event.
  /// KO: 특정 라이브 이벤트의 내 방문 상태를 조회합니다.
  Future<Result<LiveAttendanceStateDto>> fetchLiveAttendanceState({
    required String projectId,
    required String eventId,
  }) {
    return _apiClient.get<LiveAttendanceStateDto>(
      ApiEndpoints.liveEventAttendance(projectId, eventId),
      fromJson: (json) =>
          LiveAttendanceStateDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch paginated live attendance records for current user.
  /// KO: 현재 사용자의 라이브 방문 기록 목록(페이지)을 조회합니다.
  Future<Result<LiveAttendancePageDto>> fetchLiveAttendances({
    required String projectId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<LiveAttendancePageDto>(
      ApiEndpoints.liveEventAttendances(projectId),
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) => _decodeAttendancePage(json, page: page, size: size),
    );
  }
}

List<LiveEventSummaryDto> _decodeLiveEventList(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(LiveEventSummaryDto.fromJson)
        .toList();
  }
  if (json is Map<String, dynamic>) {
    const listKeys = ['items', 'content', 'data', 'results'];
    for (final key in listKeys) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map(LiveEventSummaryDto.fromJson)
            .toList();
      }
    }
  }
  return <LiveEventSummaryDto>[];
}

LiveAttendancePageDto _decodeAttendancePage(
  dynamic json, {
  required int page,
  required int size,
}) {
  if (json is List) {
    final items = json
        .whereType<Map<String, dynamic>>()
        .map(LiveAttendanceStateDto.fromJson)
        .toList();
    return LiveAttendancePageDto(
      items: items,
      currentPage: page,
      pageSize: size,
      hasNext: items.length >= size,
    );
  }

  if (json is Map<String, dynamic>) {
    final listDynamic =
        json['items'] ?? json['content'] ?? json['data'] ?? json['results'];
    final items = listDynamic is List
        ? listDynamic
              .whereType<Map<String, dynamic>>()
              .map(LiveAttendanceStateDto.fromJson)
              .toList()
        : <LiveAttendanceStateDto>[];

    final pagination = json['pagination'];
    final hasNext = pagination is Map<String, dynamic>
        ? _boolOrFallback(pagination['hasNext'], items.length >= size)
        : _boolOrFallback(json['hasNext'], items.length >= size);
    final currentPage = pagination is Map<String, dynamic>
        ? _intOrFallback(pagination['currentPage'], page)
        : _intOrFallback(json['currentPage'], page);
    final pageSize = pagination is Map<String, dynamic>
        ? _intOrFallback(pagination['pageSize'], size)
        : _intOrFallback(json['pageSize'], size);

    return LiveAttendancePageDto(
      items: items,
      currentPage: currentPage,
      pageSize: pageSize,
      hasNext: hasNext,
    );
  }

  return LiveAttendancePageDto(
    items: const <LiveAttendanceStateDto>[],
    currentPage: page,
    pageSize: size,
    hasNext: false,
  );
}

bool _boolOrFallback(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'yes' || normalized == 'y') {
      return true;
    }
    if (normalized == 'false' || normalized == 'no' || normalized == 'n') {
      return false;
    }
  }
  return fallback;
}

int _intOrFallback(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
