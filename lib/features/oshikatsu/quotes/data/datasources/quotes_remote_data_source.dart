/// EN: Remote data source for quote cards.
/// KO: 명대사 카드의 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/quotes/data/dto/quote_card_dto.dart';

/// EN: Fetches quote card data from the remote API.
/// KO: 원격 API에서 명대사 카드 데이터를 가져옵니다.
class QuotesRemoteDataSource {
  const QuotesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// EN: Fetches a paginated list of quotes, optionally filtered by project.
  /// KO: 선택적으로 프로젝트로 필터링된 페이지네이션 명대사 목록을 가져옵니다.
  Future<Result<List<QuoteCardDto>>> fetchQuotes({
    String? projectId,
    String? cursor,
    int limit = 20,
  }) {
    return apiClient.get<List<QuoteCardDto>>(
      ApiEndpoints.quotes,
      queryParameters: {
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
      fromJson: (json) {
        List<dynamic> items;
        if (json is List) {
          items = json;
        } else if (json is Map<String, dynamic>) {
          items =
              (json['quotes'] ?? json['items'] ?? json['data'] ?? const [])
                  as List<dynamic>;
        } else {
          items = const [];
        }
        return items
            .whereType<Map<String, dynamic>>()
            .map(QuoteCardDto.fromJson)
            .toList(growable: false);
      },
    );
  }

  /// EN: Sends a like for the given quote.
  /// KO: 주어진 명대사에 좋아요를 보냅니다.
  Future<Result<void>> likeQuote(String quoteId) {
    return apiClient.post<void>(ApiEndpoints.quoteLike(quoteId));
  }

  /// EN: Removes a like from the given quote.
  /// KO: 주어진 명대사의 좋아요를 취소합니다.
  Future<Result<void>> unlikeQuote(String quoteId) {
    return apiClient.delete<void>(ApiEndpoints.quoteLike(quoteId));
  }
}
