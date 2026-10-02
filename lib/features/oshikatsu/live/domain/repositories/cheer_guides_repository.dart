/// EN: Repository interface for cheer guides.
/// KO: 응원 가이드 리포지토리 인터페이스.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/cheer_guide.dart';

/// EN: Defines the contract for fetching cheer guide data.
/// KO: 응원 가이드 데이터 조회 계약을 정의합니다.
abstract class CheerGuidesRepository {
  /// EN: Fetch all cheer guide summaries, optionally filtered by [projectId].
  /// KO: 모든 응원 가이드 요약을 가져옵니다 ([projectId]로 선택적 필터링).
  Future<Result<List<CheerGuideSummary>>> fetchSummaries({String? projectId});

  /// EN: Fetch the full cheer guide detail for [guideId].
  /// KO: [guideId]에 대한 전체 응원 가이드 상세 정보를 가져옵니다.
  Future<Result<CheerGuide>> fetchGuideDetail(String guideId);
}
