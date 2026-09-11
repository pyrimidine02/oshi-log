/// EN: Live events repository implementation with caching.
/// KO: 캐시를 포함한 라이브 이벤트 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/live_event_entities.dart';
import '../../domain/repositories/live_events_repository.dart';
import '../datasources/live_events_remote_data_source.dart';
import '../dto/live_event_dto.dart';
import '../mappers/live_event_entities_mappers.dart';

class LiveEventsRepositoryImpl implements LiveEventsRepository {
  LiveEventsRepositoryImpl({
    required LiveEventsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final LiveEventsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<LiveEventSummary>>> getLiveEvents({
    required String projectId,
    int page = 0,
    int size = 500,
    bool forceRefresh = false,
  }) async {
    // EN: Cache key includes only projectId — unit filtering is done client-side
    //     so the same cached dataset is reused across all filter states.
    // KO: 캐시 키는 projectId만 포함합니다 — 유닛 필터링은 클라이언트에서 처리하므로
    //     동일한 캐시 데이터를 모든 필터 상태에서 재사용합니다.
    final cacheKey = _listCacheKey(projectId, page, size);
    final profile = CacheProfiles.liveEventsList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<LiveEventSummaryDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchLiveEvents(projectId, page, size),
            toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(LiveEventSummaryDto.fromJson)
                    .toList();
              }
              return <LiveEventSummaryDto>[];
            },
          );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();

      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<LiveEventDetail>> getLiveEventDetail({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _detailCacheKey(projectId, eventId);
    // EN: Use staleWhileRevalidate for event detail — show cached data first.
    // KO: 이벤트 상세에 staleWhileRevalidate 사용 — 캐시 데이터 먼저 표시.
    final profile = CacheProfiles.liveEventDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<LiveEventDetailDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchLiveEventDetail(projectId, eventId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => LiveEventDetailDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<LiveAttendanceState>> getLiveAttendanceState({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.fetchLiveAttendanceState(
        projectId: projectId,
        eventId: eventId,
      );

      if (result case Success<LiveAttendanceStateDto>(:final data)) {
        return Result.success(data.toDomain());
      }
      if (result case Err<LiveAttendanceStateDto>(:final failure)) {
        return Result.failure(failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown live attendance state result',
          code: 'unknown_live_attendance_state',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<LiveAttendanceHistoryPageData>> getLiveAttendanceHistory({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.fetchLiveAttendances(
        projectId: projectId,
        page: page,
        size: size,
      );

      if (result case Success<LiveAttendancePageDto>(:final data)) {
        final items = data.items
            .map(
              (dto) => LiveAttendanceHistoryRecord.fromState(
                projectKey: projectId,
                state: dto.toDomain(),
              ),
            )
            .where((record) => record.attended && !record.isNone)
            .toList(growable: false);

        return Result.success(
          LiveAttendanceHistoryPageData(
            items: items,
            currentPage: data.currentPage,
            pageSize: data.pageSize,
            hasNext: data.hasNext,
          ),
        );
      }
      if (result case Err<LiveAttendancePageDto>(:final failure)) {
        return Result.failure(failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown live attendance history result',
          code: 'unknown_live_attendance_history',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<LiveEventSummaryDto>> _fetchLiveEvents(
    String projectId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchLiveEvents(
      projectId: projectId,
      page: page,
      size: size,
    );

    if (result is Success<List<LiveEventSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<LiveEventSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown live events result',
      code: 'unknown_live_events',
    );
  }

  Future<LiveEventDetailDto> _fetchLiveEventDetail(
    String projectId,
    String eventId,
  ) async {
    final result = await _remoteDataSource.fetchLiveEventDetail(
      projectId: projectId,
      eventId: eventId,
    );

    if (result is Success<LiveEventDetailDto>) {
      return result.data;
    }
    if (result is Err<LiveEventDetailDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown live event detail result',
      code: 'unknown_live_event_detail',
    );
  }

  @override
  Future<Result<LiveAttendanceState>> toggleLiveAttendance({
    required String projectId,
    required String eventId,
    required bool attended,
  }) async {
    try {
      final result = await _remoteDataSource.toggleLiveAttendance(
        projectId: projectId,
        eventId: eventId,
        attended: attended,
      );

      if (result case Success<LiveAttendanceStateDto>(:final data)) {
        return Result.success(data.toDomain());
      }
      if (result case Err<LiveAttendanceStateDto>(:final failure)) {
        return Result.failure(failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown live attendance toggle result',
          code: 'unknown_live_attendance_toggle',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  String _listCacheKey(String projectId, int page, int size) {
    return 'live_events:$projectId:p$page:s$size';
  }

  String _detailCacheKey(String projectId, String eventId) {
    return 'live_event_detail:$projectId:$eventId';
  }
}
