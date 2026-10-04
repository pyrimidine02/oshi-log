/// EN: Repository interface for quote cards.
/// KO: 명대사 카드 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/quotes/domain/entities/quote_card.dart';

/// EN: Contract for fetching and mutating quote cards.
/// KO: 명대사 카드 조회 및 변이를 위한 계약입니다.
abstract class QuotesRepository {
  /// EN: Fetches a list of quotes, optionally scoped to a project.
  /// KO: 선택적으로 프로젝트 범위를 지정한 명대사 목록을 가져옵니다.
  Future<Result<List<QuoteCard>>> fetchQuotes({
    String? projectId,
    String? cursor,
  });

  /// EN: Records a like for [quoteId].
  /// KO: [quoteId]에 좋아요를 기록합니다.
  Future<Result<void>> likeQuote(String quoteId);

  /// EN: Removes the like for [quoteId].
  /// KO: [quoteId]의 좋아요를 제거합니다.
  Future<Result<void>> unlikeQuote(String quoteId);
}
