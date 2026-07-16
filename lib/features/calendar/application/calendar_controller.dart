/// EN: Riverpod providers for calendar events.
/// KO: 캘린더 이벤트를 위한 Riverpod 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../data/datasources/calendar_remote_data_source.dart';
import '../data/repositories/calendar_repository_impl.dart';
import '../domain/entities/calendar_event.dart';
import '../domain/repositories/calendar_repository.dart';

/// EN: Provides a [CalendarRepository] backed by the shared [ApiClient].
/// KO: 공유 [ApiClient]를 사용하는 [CalendarRepository]를 제공합니다.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarRepositoryImpl(
    remoteDataSource: CalendarRemoteDataSource(apiClient: apiClient),
  );
});

/// EN: Query parameters for fetching calendar events.
/// KO: 캘린더 이벤트 조회 쿼리 파라미터.
typedef CalendarEventsQuery = ({int year, int month, String? projectKey});

/// EN: Family provider — loads events for a specific year/month.
/// EN: Returns empty list on 404 (no events yet); throws on other failures.
/// KO: Family 프로바이더 — 특정 연도/월의 이벤트를 로드합니다.
/// KO: 404(이벤트 없음)는 빈 목록 반환, 그 외 실패는 throw합니다.
final calendarEventsProvider = FutureProvider.autoDispose
    .family<List<CalendarEvent>, CalendarEventsQuery>((ref, query) async {
      final repo = ref.watch(calendarRepositoryProvider);
      final result = await repo.fetchEvents(
        year: query.year,
        month: query.month,
        projectKey: query.projectKey,
      );
      return result.when(
        success: (events) => events,
        failure: (f) {
          // EN: 404 means no events this month — return empty list, not an error.
          // KO: 404는 해당 월에 이벤트가 없는 것이므로 에러가 아닌 빈 목록을 반환합니다.
          if (f is NotFoundFailure) return const <CalendarEvent>[];
          throw f;
        },
      );
    });
