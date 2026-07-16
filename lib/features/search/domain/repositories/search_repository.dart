/// EN: Search repository interface.
/// KO: 검색 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/search_entities.dart';

abstract class SearchRepository {
  Future<Result<List<SearchItem>>> search({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  Future<Result<SearchPopularDiscovery>> getPopularDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  });

  Future<Result<SearchCategoryDiscovery>> getCategoryDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  });

  void cancelInFlightSearch();
}
