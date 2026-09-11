/// EN: Concrete implementation of [CalendarRepository].
/// KO: [CalendarRepository]의 구체적인 구현체.
library;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_data_source.dart';
import '../dto/calendar_event_dto.dart';

/// EN: Implements [CalendarRepository] by delegating to the remote data source.
/// KO: 원격 데이터 소스에 위임하여 [CalendarRepository]를 구현합니다.
class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl({required this.remoteDataSource});

  final CalendarRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<CalendarEvent>>> fetchEvents({
    required int year,
    required int month,
    String? projectKey,
  }) async {
    try {
      final calendarFuture = remoteDataSource.fetchEvents(
        year: year,
        month: month,
        projectKey: projectKey,
      );
      final liveFuture = projectKey == null || projectKey.isEmpty
          ? null
          : remoteDataSource.fetchLiveEvents(
              year: year,
              month: month,
              projectKey: projectKey,
            );
      // EN: Await both sources together so a failure from one source is
      // observed while the sibling future is also given an error handler.
      // KO: 한 소스의 실패를 관찰하면서 형제 Future에도 오류 핸들러를
      // 연결하도록 두 소스를 함께 기다립니다.
      final sourceFutures = <Future<Result<List<CalendarEventDto>>>>[
        calendarFuture,
        if (liveFuture != null) liveFuture,
      ];
      final sourceResults = await Future.wait(sourceFutures);
      final calendarResult = sourceResults.first;
      final liveResult = sourceResults.length > 1 ? sourceResults[1] : null;

      final calendarDtos = calendarResult.dataOrNull;
      final liveDtos = liveResult?.dataOrNull;
      if (calendarDtos == null && liveDtos == null) {
        return Result.failure(
          calendarResult.failureOrNull ??
              liveResult?.failureOrNull ??
              UnknownFailure('Calendar schedule unavailable'),
        );
      }

      // EN: A partial source failure must not hide a healthy schedule source.
      // KO: 일부 데이터 소스 실패가 정상 일정 소스까지 숨기지 않도록 병합합니다.
      final eventsById = <String, CalendarEvent>{};
      for (final dto in [...?calendarDtos, ...?liveDtos]) {
        for (final event in _projectIntoMonth(dto, year: year, month: month)) {
          eventsById[event.id] = event;
        }
      }
      final events = eventsById.values.toList(growable: false)
        ..sort((a, b) => a.date.compareTo(b.date));
      final partialFailure =
          calendarResult.failureOrNull ?? liveResult?.failureOrNull;
      if (events.isEmpty && partialFailure != null) {
        return Result.failure(partialFailure);
      }
      return Result.success(List<CalendarEvent>.unmodifiable(events));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }
}

Iterable<CalendarEvent> _projectIntoMonth(
  CalendarEventDto dto, {
  required int year,
  required int month,
}) sync* {
  final source = dto.toEntity();
  final localStart = source.date.toLocal();
  final parsedEnd = dto.endDate?.toLocal();
  final localEnd = parsedEnd == null || parsedEnd.isBefore(localStart)
      ? localStart
      : parsedEnd;
  final monthStart = DateTime(year, month);
  final monthEnd = DateTime(year, month + 1, 0);
  final startDay = DateTime(localStart.year, localStart.month, localStart.day);
  final endDay = DateTime(localEnd.year, localEnd.month, localEnd.day);
  // EN: Clamp malformed or very wide source ranges before iterating. A
  // multi-year event only needs the visible month projected into the grid.
  // KO: 비정상적으로 넓은 원본 범위를 순회하기 전에 잘라냅니다. 여러 해에
  // 걸친 이벤트도 현재 달만 그리드에 투영하면 됩니다.
  var day = startDay.isAfter(monthStart) ? startDay : monthStart;
  final visibleEnd = endDay.isBefore(monthEnd) ? endDay : monthEnd;
  if (day.isAfter(visibleEnd)) {
    return;
  }

  while (!day.isAfter(visibleEnd)) {
    final isStartDay =
        day.year == localStart.year &&
        day.month == localStart.month &&
        day.day == localStart.day;
    yield CalendarEvent(
      id: isStartDay ? source.id : '${source.id}:${_dateKey(day)}',
      title: source.title,
      date: isStartDay ? localStart : day,
      type: source.type,
      description: source.description,
      imageUrl: source.imageUrl,
      projectId: source.projectId,
      projectCode: source.projectCode,
      relatedEntityId: source.relatedEntityId,
      relatedEntityType: source.relatedEntityType,
      isRecurringAnnually: source.isRecurringAnnually,
    );
    day = DateTime(day.year, day.month, day.day + 1);
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
