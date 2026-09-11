/// EN: Visits repository implementation with caching.
/// KO: 캐시를 포함한 방문 기록 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/visit_entities.dart';
import '../../domain/repositories/visits_repository.dart';
import '../datasources/visits_remote_data_source.dart';
import '../dto/user_ranking_dto.dart';
import '../dto/visit_dto.dart';
import '../mappers/visit_entities_mappers.dart';

class VisitsRepositoryImpl implements VisitsRepository {
  VisitsRepositoryImpl({
    required VisitsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final VisitsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<VisitEvent>>> getVisits({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.visitsList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<VisitEventDto>>(
        key: _visitsCacheKey(page, size),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchVisits(page: page, size: size),
        toJson: _encodeVisitList,
        fromJson: _decodeVisitList,
      );

      final entities = cacheResult.data
          .map((value) => value.toDomain())
          .toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<VisitEvent>>> getAllVisits({
    int pageSize = 50,
    bool forceRefresh = false,
  }) async {
    final allVisits = <VisitEvent>[];
    var page = 0;
    var shouldRefresh = forceRefresh;

    while (true) {
      final result = await getVisits(
        page: page,
        size: pageSize,
        forceRefresh: shouldRefresh,
      );
      if (result is Err<List<VisitEvent>>) {
        return Result.failure(result.failure);
      }
      if (result is! Success<List<VisitEvent>>) {
        return Result.failure(
          const UnknownFailure(
            'Unknown visits page result',
            code: 'unknown_visits_page_result',
          ),
        );
      }
      final visits = result.data;
      allVisits.addAll(visits);
      if (visits.length < pageSize) break;
      page += 1;
      shouldRefresh = false;
    }

    return Result.success(allVisits);
  }

  @override
  Future<Result<VisitSummary>> getVisitSummary({
    required String placeId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.visitsSummary;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<VisitSummaryDto>(
        key: _summaryCacheKey(placeId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchSummary(placeId: placeId),
        toJson: (dto) => dto.toJson(),
        fromJson: VisitSummaryDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<VisitEvent>> getVisitDetail({
    required String visitId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.visitDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<VisitEventDetailDto>(
        key: _detailCacheKey(visitId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchVisitDetail(visitId: visitId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => VisitEventDetailDto.fromJson(json),
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<List<VisitEventDto>> _fetchVisits({
    required int page,
    required int size,
  }) async {
    final result = await _remoteDataSource.fetchUserVisits(
      page: page,
      size: size,
    );
    if (result is Success<List<VisitEventDto>>) {
      return result.data;
    }
    if (result is Err<List<VisitEventDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown visit list result',
      code: 'unknown_visit_list',
    );
  }

  Future<VisitEventDetailDto> _fetchVisitDetail({
    required String visitId,
  }) async {
    final result = await _remoteDataSource.fetchVisitDetail(visitId: visitId);
    if (result is Success<VisitEventDetailDto>) {
      return result.data;
    }
    if (result is Err<VisitEventDetailDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown visit detail result',
      code: 'unknown_visit_detail',
    );
  }

  Future<VisitSummaryDto> _fetchSummary({required String placeId}) async {
    final result = await _remoteDataSource.fetchVisitSummary(placeId: placeId);
    if (result is Success<VisitSummaryDto>) {
      return result.data;
    }
    if (result is Err<VisitSummaryDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown visit summary result',
      code: 'unknown_visit_summary',
    );
  }

  @override
  Future<Result<UserRanking>> getUserRanking({
    required String projectId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.userRanking;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<UserRankingDto>(
        key: _rankingCacheKey(projectId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchUserRanking(projectId: projectId),
        toJson: (dto) => dto.toJson(),
        fromJson: UserRankingDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<UserRankingDto> _fetchUserRanking({required String projectId}) async {
    final result = await _remoteDataSource.fetchUserRanking(
      projectId: projectId,
    );
    if (result is Success<UserRankingDto>) {
      return result.data;
    }
    if (result is Err<UserRankingDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown user ranking result',
      code: 'unknown_user_ranking',
    );
  }
}

String _visitsCacheKey(int page, int size) =>
    'user_visits_page_${page}_size_$size';
String _summaryCacheKey(String placeId) => 'user_visits_summary_$placeId';
String _detailCacheKey(String visitId) => 'user_visit_detail_$visitId';
String _rankingCacheKey(String projectId) => 'user_ranking_$projectId';

Map<String, dynamic> _encodeVisitList(List<VisitEventDto> items) {
  return {'items': items.map((item) => item.toJson()).toList()};
}

List<VisitEventDto> _decodeVisitList(Map<String, dynamic> json) {
  final raw = json['items'];
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(VisitEventDto.fromJson)
        .toList();
  }
  return <VisitEventDto>[];
}
