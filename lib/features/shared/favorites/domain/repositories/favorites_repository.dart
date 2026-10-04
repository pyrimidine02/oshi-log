/// EN: Favorites repository interface.
/// KO: 즐겨찾기 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/shared/favorites/domain/entities/favorite_entities.dart';

abstract class FavoritesRepository {
  /// EN: Get paginated favorites for the current user.
  /// KO: 현재 사용자의 페이지네이션된 즐겨찾기를 가져옵니다.
  Future<Result<List<FavoriteItem>>> getFavorites({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<FavoriteItem>> addFavorite({
    required String entityId,
    required FavoriteType type,
  });

  Future<Result<void>> removeFavorite({
    required String entityId,
    required FavoriteType type,
  });
}
