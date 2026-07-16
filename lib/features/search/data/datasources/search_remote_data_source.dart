/// EN: Remote data source for unified search.
/// KO: 통합 검색 원격 데이터 소스.
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/search_discovery_dto.dart';
import '../dto/search_item_dto.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;
  CancelToken? _activeSearchCancelToken;

  Future<Result<List<SearchItemDto>>> search({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
  }) {
    cancelInFlightSearch();
    final cancelToken = CancelToken();
    _activeSearchCancelToken = cancelToken;

    final normalizedTypes = types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toList();
    final normalizedProjectId = projectId?.trim();
    final normalizedUnitIds = unitIds
        .map((unitId) => unitId.trim())
        .where((unitId) => unitId.isNotEmpty)
        .toList(growable: false);

    return _apiClient.get<List<SearchItemDto>>(
      ApiEndpoints.search,
      queryParameters: {
        'q': query,
        if (normalizedTypes.isNotEmpty) 'types': normalizedTypes.join(','),
        if (normalizedProjectId != null && normalizedProjectId.isNotEmpty)
          'projectId': normalizedProjectId,
        if (normalizedUnitIds.isNotEmpty)
          'unitIds': normalizedUnitIds.join(','),
        'page': page,
        'size': size.clamp(1, 50),
      },
      cancelToken: cancelToken,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(SearchItemDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['results'] ?? json['data'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(SearchItemDto.fromJson)
                .toList();
          }
        }
        return <SearchItemDto>[];
      },
    );
  }

  Future<Result<SearchPopularDiscoveryDto>> fetchPopularDiscovery({
    int limit = 10,
  }) {
    return _apiClient.get<SearchPopularDiscoveryDto>(
      ApiEndpoints.searchDiscoveryPopular,
      queryParameters: {'limit': limit.clamp(1, 20)},
      fromJson: (json) {
        final data = json is Map<String, dynamic> ? json : <String, dynamic>{};
        return SearchPopularDiscoveryDto.fromJson(data);
      },
    );
  }

  Future<Result<SearchCategoryDiscoveryDto>> fetchCategoryDiscovery({
    int limit = 10,
  }) {
    return _apiClient.get<SearchCategoryDiscoveryDto>(
      ApiEndpoints.searchDiscoveryCategories,
      queryParameters: {'limit': limit.clamp(1, 20)},
      fromJson: (json) {
        final data = json is Map<String, dynamic> ? json : <String, dynamic>{};
        return SearchCategoryDiscoveryDto.fromJson(data);
      },
    );
  }

  void cancelInFlightSearch() {
    if (_activeSearchCancelToken == null) return;
    if (!(_activeSearchCancelToken!.isCancelled)) {
      _activeSearchCancelToken!.cancel('search superseded');
    }
    _activeSearchCancelToken = null;
  }
}
