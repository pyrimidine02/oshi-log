/// EN: Remote data source for zukan collections.
/// KO: 도감 컬렉션의 원격 데이터 소스.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/zukan_dto.dart';

/// EN: Communicates with the zukan collection API endpoints.
///     All methods return [Result] so callers can handle errors without try/catch.
/// KO: 도감 컬렉션 API 엔드포인트와 통신합니다.
///     모든 메서드는 [Result]를 반환하므로 호출자가 try/catch 없이 오류를 처리할 수 있습니다.
class ZukanRemoteDataSource {
  const ZukanRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// EN: Fetches the summary list of all collections, optionally filtered by project.
  /// KO: 모든 컬렉션의 요약 목록을 가져옵니다 (프로젝트 필터 선택적).
  Future<Result<List<ZukanCollectionSummaryDto>>> fetchCollections({
    String? projectId,
  }) {
    return _apiClient.get<List<ZukanCollectionSummaryDto>>(
      ApiEndpoints.zukanCollections,
      queryParameters: {if (projectId != null) 'projectId': projectId},
      fromJson: (json) {
        // EN: The API may return a root list or a map with a collections/items/data key.
        // KO: API는 최상위 배열이나 collections/items/data 키를 가진 맵을 반환할 수 있습니다.
        final List<dynamic> items;
        if (json is List) {
          items = json;
        } else if (json is Map<String, dynamic>) {
          items =
              (json['collections'] ??
                      json['items'] ??
                      json['data'] ??
                      <dynamic>[])
                  as List<dynamic>;
        } else {
          items = [];
        }
        return items
            .whereType<Map<String, dynamic>>()
            .map(ZukanCollectionSummaryDto.fromJson)
            .toList();
      },
    );
  }

  /// EN: Fetches the full detail of a single collection including stamps.
  /// KO: 스탬프를 포함한 단일 컬렉션의 전체 상세 정보를 가져옵니다.
  Future<Result<ZukanCollectionDto>> fetchCollectionDetail(
    String collectionId,
  ) {
    return _apiClient.get<ZukanCollectionDto>(
      ApiEndpoints.zukanCollection(collectionId),
      fromJson: (json) => ZukanCollectionDto.fromJson(
        json is Map<String, dynamic> ? json : const <String, dynamic>{},
      ),
    );
  }
}
