/// EN: Live events repository interface.
/// KO: 라이브 이벤트 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';

abstract class LiveEventsRepository {
  /// EN: Get all live events for a project (full dataset, client-side filtered).
  /// KO: 프로젝트의 전체 라이브 이벤트를 가져옵니다 (클라이언트 사이드 필터링).
  Future<Result<List<LiveEventSummary>>> getLiveEvents({
    required String projectId,
    int page = 0,
    int size = 500,
    bool forceRefresh = false,
  });

  Future<Result<LiveEventDetail>> getLiveEventDetail({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  });

  Future<Result<LiveAttendanceState>> getLiveAttendanceState({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  });

  Future<Result<LiveAttendanceHistoryPageData>> getLiveAttendanceHistory({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<LiveAttendanceState>> toggleLiveAttendance({
    required String projectId,
    required String eventId,
    required bool attended,
  });
}
