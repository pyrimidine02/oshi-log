/// EN: Home repository implementation with caching.
/// KO: 캐시를 포함한 홈 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../dto/home_summary_dto.dart';
import '../mappers/home_summary_mappers.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final HomeRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<HomeSummaryByProjectItem>>> getHomeSummariesByProject({
    List<String> projectIds = const [],
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    final normalizedProjectIds = _normalizeIdentifiers(projectIds);
    final normalizedUnitIds = _normalizeIdentifiers(unitIds);
    final cacheKey = _buildBatchCacheKey(
      normalizedProjectIds,
      normalizedUnitIds,
    );
    final profile = CacheProfiles.homeSummary;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<HomeSummaryByProjectItemDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchSummaryByProject(
              projectIds: normalizedProjectIds,
              unitIds: normalizedUnitIds,
            ),
            toJson: (items) => {
              'items': items.map((item) => item.toJson()).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is! List) {
                return const <HomeSummaryByProjectItemDto>[];
              }
              return items
                  .whereType<Map<String, dynamic>>()
                  .map(HomeSummaryByProjectItemDto.fromJson)
                  .toList(growable: false);
            },
          );

      final entities = cacheResult.data
          .map((value) => value.toDomain())
          .toList(growable: false);
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<HomeSummary>> getHomeSummary({
    required String projectId,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  }) async {
    final normalizedUnitIds = _normalizeIdentifiers(unitIds);
    final cacheKey = _buildCacheKey(projectId, normalizedUnitIds);
    final profile = CacheProfiles.homeSummary;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<HomeSummaryDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchSummary(projectId, normalizedUnitIds),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => HomeSummaryDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<HomeSummaryByProjectItemDto>> _fetchSummaryByProject({
    required List<String> projectIds,
    required List<String> unitIds,
  }) async {
    final result = await _remoteDataSource.fetchSummaryByProject(
      projectIds: projectIds,
      unitIds: unitIds,
    );

    if (result is Success<List<HomeSummaryByProjectItemDto>>) {
      return _hydrateMissingLivePostersByProject(result.data);
    }
    if (result is Err<List<HomeSummaryByProjectItemDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown home summary by-project result',
      code: 'unknown_home_summary_by_project',
    );
  }

  Future<HomeSummaryDto> _fetchSummary(
    String projectId,
    List<String> unitIds,
  ) async {
    final result = await _remoteDataSource.fetchSummary(
      projectId: projectId,
      unitIds: unitIds,
    );

    if (result is Success<HomeSummaryDto>) {
      return _hydrateMissingLivePosters(
        projectId: projectId,
        summary: result.data,
      );
    }
    if (result is Err<HomeSummaryDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown home summary result',
      code: 'unknown_home_summary',
    );
  }

  Future<List<HomeSummaryByProjectItemDto>> _hydrateMissingLivePostersByProject(
    List<HomeSummaryByProjectItemDto> items,
  ) async {
    if (items.isEmpty) {
      return items;
    }

    return Future.wait(
      items.map((item) async {
        final projectKey = _resolveProjectRouteKey(
          projectCode: item.projectCode,
          projectId: item.projectId,
        );
        if (projectKey == null) {
          return item;
        }

        final hydratedSummary = await _hydrateMissingLivePosters(
          projectId: projectKey,
          summary: item.summary,
        );
        return item.copyWith(summary: hydratedSummary);
      }),
    );
  }

  /// EN: Some home-summary payloads omit poster URLs for trending live items.
  /// EN: For those rows only, fallback to live-detail posters to keep cards visual.
  /// KO: 일부 홈 요약 payload는 트렌딩 라이브 포스터를 생략합니다.
  /// KO: 누락된 행만 라이브 상세 포스터로 보강해 카드 비주얼을 유지합니다.
  Future<HomeSummaryDto> _hydrateMissingLivePosters({
    required String projectId,
    required HomeSummaryDto summary,
  }) async {
    final missingPosterEvents = summary.trendingLiveEvents
        .where(
          (event) =>
              event.id.isNotEmpty &&
              (event.bannerUrl == null || event.bannerUrl!.trim().isEmpty),
        )
        .toList(growable: false);

    if (missingPosterEvents.isEmpty) {
      return summary;
    }

    final posterEntries = await Future.wait(
      missingPosterEvents.map((event) async {
        final result = await _remoteDataSource.fetchLiveEventPosterUrl(
          projectId: projectId,
          eventId: event.id,
        );
        if (result case Success<String?>(:final data)) {
          final url = data?.trim();
          if (url != null && url.isNotEmpty) {
            return MapEntry(event.id, url);
          }
        }
        return null;
      }),
    );

    final posterByEventId = <String, String>{
      for (final entry in posterEntries.whereType<MapEntry<String, String>>())
        entry.key: entry.value,
    };

    if (posterByEventId.isEmpty) {
      return summary;
    }

    final mergedTrendingEvents = summary.trendingLiveEvents
        .map((event) {
          final hasPoster =
              event.bannerUrl != null && event.bannerUrl!.trim().isNotEmpty;
          if (hasPoster) {
            return event;
          }
          final fallbackPoster = posterByEventId[event.id];
          if (fallbackPoster == null || fallbackPoster.isEmpty) {
            return event;
          }
          return event.copyWith(bannerUrl: fallbackPoster);
        })
        .toList(growable: false);

    return summary.copyWith(trendingLiveEvents: mergedTrendingEvents);
  }

  String _buildCacheKey(String projectId, List<String> unitIds) {
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    return 'home_summary:$projectId:$units';
  }

  String _buildBatchCacheKey(List<String> projectIds, List<String> unitIds) {
    final projects = projectIds.isEmpty ? 'all' : projectIds.join(',');
    final units = unitIds.isEmpty ? 'all' : unitIds.join(',');
    return 'home_summary_by_project:$projects:$units';
  }

  List<String> _normalizeIdentifiers(List<String> values) {
    if (values.isEmpty) {
      return const <String>[];
    }

    final seen = <String>{};
    final normalized = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      normalized.add(trimmed);
    }
    return normalized;
  }

  String? _resolveProjectRouteKey({
    required String projectCode,
    required String projectId,
  }) {
    final code = projectCode.trim();
    if (code.isNotEmpty) {
      return code;
    }
    final id = projectId.trim();
    if (id.isNotEmpty) {
      return id;
    }
    return null;
  }
}
