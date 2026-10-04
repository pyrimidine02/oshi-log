/// EN: Home repository interface.
/// KO: 홈 리포지토리 인터페이스.
library;

import '../../../../../platform/utils/result.dart';
import '../entities/home_summary.dart';

abstract class HomeRepository {
  Future<Result<List<HomeSummaryByProjectItem>>> getHomeSummariesByProject({
    List<String> projectIds = const [],
    List<String> unitIds = const [],
    bool forceRefresh = false,
  });

  Future<Result<HomeSummary>> getHomeSummary({
    required String projectId,
    List<String> unitIds = const [],
    bool forceRefresh = false,
  });
}
