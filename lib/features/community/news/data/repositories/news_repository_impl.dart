/// EN: News repository implementation with caching.
/// KO: 캐시를 포함한 뉴스 리포지토리 구현.
library;

import 'package:oshi_log/platform/cache/cache_manager.dart';
import 'package:oshi_log/platform/cache/cache_profiles.dart';
import 'package:oshi_log/platform/error/error_handler.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/utils/result.dart';
import '../../domain/entities/news_entities.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_data_source.dart';
import '../dto/news_dto.dart';
import '../mappers/news_entities_mappers.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl({
    required NewsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final NewsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<List<NewsSummary>>> getNews({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _newsListCacheKey(projectId, page, size);
    final profile = CacheProfiles.feedNews;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<NewsSummaryDto>>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchNews(projectId, page, size),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(NewsSummaryDto.fromJson)
                .toList();
          }
          return <NewsSummaryDto>[];
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
  Future<Result<NewsDetail>> getNewsDetail({
    required String projectId,
    required String newsId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _newsDetailCacheKey(projectId, newsId);
    final profile = CacheProfiles.feedNews;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<NewsDetailDto>(
        key: cacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchNewsDetail(projectId, newsId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => NewsDetailDto.fromJson(json),
      );

      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<NewsSummaryDto>> _fetchNews(
    String projectId,
    int page,
    int size,
  ) async {
    final result = await _remoteDataSource.fetchNews(
      projectId: projectId,
      page: page,
      size: size,
    );

    if (result is Success<List<NewsSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<NewsSummaryDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown news list result',
      code: 'unknown_news_list',
    );
  }

  Future<NewsDetailDto> _fetchNewsDetail(
    String projectId,
    String newsId,
  ) async {
    final result = await _remoteDataSource.fetchNewsDetail(
      projectId: projectId,
      newsId: newsId,
    );

    if (result is Success<NewsDetailDto>) {
      return result.data;
    }
    if (result is Err<NewsDetailDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown news detail result',
      code: 'unknown_news_detail',
    );
  }

  String _newsListCacheKey(String projectId, int page, int size) {
    return 'news_list:$projectId:p$page:s$size';
  }

  String _newsDetailCacheKey(String projectId, String newsId) {
    return 'news_detail:$projectId:$newsId';
  }
}
