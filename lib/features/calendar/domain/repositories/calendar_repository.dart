/// EN: Repository interface for calendar events.
/// KO: 캘린더 이벤트 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/calendar_event.dart';

/// EN: Defines the contract for fetching calendar events.
/// KO: 캘린더 이벤트 조회 계약을 정의합니다.
abstract class CalendarRepository {
  /// EN: Fetches events for the given year and month.
  /// KO: 주어진 연도/월의 이벤트를 조회합니다.
  Future<Result<List<CalendarEvent>>> fetchEvents({
    required int year,
    required int month,
    String? projectKey,
  });
}
