/// EN: News repository interface.
/// KO: 뉴스 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import '../entities/news_entities.dart';

abstract class NewsRepository {
  /// EN: Get paginated news for a project.
  /// KO: 프로젝트의 페이지네이션된 뉴스를 가져옵니다.
  Future<Result<List<NewsSummary>>> getNews({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  });

  /// EN: Get news detail.
  /// KO: 뉴스 상세를 가져옵니다.
  Future<Result<NewsDetail>> getNewsDetail({
    required String projectId,
    required String newsId,
    bool forceRefresh = false,
  });
}
