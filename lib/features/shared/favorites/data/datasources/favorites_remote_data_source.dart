/// EN: Remote data source for favorites APIs.
/// KO: 즐겨찾기 API 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/shared/favorites/data/dto/favorite_dto.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Fetch paginated favorites for the current user.
  /// KO: 현재 사용자의 페이지네이션된 즐겨찾기를 조회합니다.
  Future<Result<List<FavoriteItemDto>>> fetchFavorites({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<FavoriteItemDto>>(
      ApiEndpoints.userFavorites,
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(FavoriteItemDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          const listKeys = ['items', 'content', 'data', 'results'];
          for (final key in listKeys) {
            final value = json[key];
            if (value is List) {
              return value
                  .whereType<Map<String, dynamic>>()
                  .map(FavoriteItemDto.fromJson)
                  .toList();
            }
          }
        }
        return <FavoriteItemDto>[];
      },
    );
  }

  Future<Result<FavoriteItemDto>> addFavorite({
    required String entityId,
    required String entityType,
  }) {
    return _apiClient.post<FavoriteItemDto>(
      ApiEndpoints.userFavorites,
      data: {'entityId': entityId, 'entityType': entityType},
      fromJson: (json) =>
          FavoriteItemDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> removeFavorite({
    required String entityId,
    required String entityType,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.userFavorites,
      data: {'entityId': entityId, 'entityType': entityType},
      fromJson: (_) {},
    );
  }
}
