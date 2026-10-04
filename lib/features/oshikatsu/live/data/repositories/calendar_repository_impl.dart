/// EN: Concrete implementation of [CalendarRepository].
/// KO: [CalendarRepository]의 구체적인 구현체.
library;

import 'package:oshi_log/platform/error/error_handler.dart';
import '../../domain/event_time_policy.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/calendar_event.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/repositories/calendar_repository.dart';
import 'package:oshi_log/features/oshikatsu/live/data/datasources/calendar_remote_data_source.dart';
import 'package:oshi_log/features/oshikatsu/live/data/dto/calendar_event_dto.dart';

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
  final localStart = source.scheduleDate;
  final parsedEnd = dto.endDate == null
      ? null
      : source.isAllDay
      ? DateTime.utc(dto.endDate!.year, dto.endDate!.month, dto.endDate!.day)
      : EventTimePolicy.inJst(dto.endDate!);
  final localEnd = parsedEnd == null || parsedEnd.isBefore(localStart)
      ? localStart
      : parsedEnd;
  final monthStart = DateTime.utc(year, month);
  final monthEnd = DateTime.utc(year, month + 1, 0);
  final startDay = DateTime.utc(
    localStart.year,
    localStart.month,
    localStart.day,
  );
  final endDay = DateTime.utc(localEnd.year, localEnd.month, localEnd.day);
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
      date: isStartDay
          ? source.date
          : source.isAllDay
          ? day
          : day.subtract(EventTimePolicy.jstOffset),
      type: source.type,
      description: source.description,
      imageUrl: source.imageUrl,
      projectId: source.projectId,
      projectCode: source.projectCode,
      relatedEntityId: source.relatedEntityId,
      relatedEntityType: source.relatedEntityType,
      isRecurringAnnually: source.isRecurringAnnually,
      scheduleStatus: source.scheduleStatus,
    );
    day = DateTime.utc(day.year, day.month, day.day + 1);
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
