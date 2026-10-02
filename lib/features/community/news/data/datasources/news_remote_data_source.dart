/// EN: Remote data source for news.
/// KO: 뉴스 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import '../dto/news_dto.dart';

class NewsRemoteDataSource {
  NewsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _pageableQuery({required int page, required int size}) {
    return {
      // EN: Keep both legacy (`page`,`size`) and v3 (`pageable`) query styles.
      // KO: 레거시(`page`,`size`)와 v3(`pageable`) 쿼리 스타일을 함께 전송합니다.
      'page': page,
      'size': size,
      'pageable': '$page,$size',
    };
  }

  /// EN: Fetch paginated news for a project.
  /// KO: 프로젝트의 페이지네이션된 뉴스를 조회합니다.
  Future<Result<List<NewsSummaryDto>>> fetchNews({
    required String projectId,
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<NewsSummaryDto>>(
      ApiEndpoints.news(projectId),
      queryParameters: _pageableQuery(page: page, size: size),
      fromJson: (json) => _decodeList(json, NewsSummaryDto.fromJson),
    );
  }

  Future<Result<NewsDetailDto>> fetchNewsDetail({
    required String projectId,
    required String newsId,
  }) {
    return _apiClient.get<NewsDetailDto>(
      ApiEndpoints.newsDetail(projectId, newsId),
      fromJson: (json) => NewsDetailDto.fromJson(json as Map<String, dynamic>),
    );
  }
}

List<T> _decodeList<T>(dynamic json, T Function(Map<String, dynamic>) mapper) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().map(mapper).toList();
  }
  if (json is Map<String, dynamic>) {
    const listKeys = ['items', 'content', 'data', 'results'];
    for (final key in listKeys) {
      final value = json[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().map(mapper).toList();
      }
    }
  }
  return <T>[];
}
