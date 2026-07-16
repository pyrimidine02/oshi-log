/// EN: Remote boundary for project-scoped travel reviews.
/// KO: 프로젝트 범위 여행 후기 원격 경계입니다.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/travel_review_dto.dart';

class TravelReviewsRemoteDataSource {
  const TravelReviewsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<List<TravelReviewSummaryDto>>> list({
    required String projectCode,
    int page = 0,
    int size = 20,
  }) {
    return _apiClient.get<List<TravelReviewSummaryDto>>(
      ApiEndpoints.travelReviews(projectCode),
      queryParameters: {
        'page': page < 0 ? 0 : page,
        'size': size.clamp(1, 100),
      },
      fromJson: (json) => _decodeList(json, TravelReviewSummaryDto.fromJson),
    );
  }

  Future<Result<TravelReviewDetailDto>> detail({
    required String projectCode,
    required String reviewId,
  }) {
    return _apiClient.get<TravelReviewDetailDto>(
      ApiEndpoints.travelReview(projectCode, reviewId),
      fromJson: (json) => TravelReviewDetailDto.fromJson(_asMap(json)),
    );
  }

  Future<Result<TravelReviewDetailDto>> create({
    required String projectCode,
    required TravelReviewCreateRequestDto request,
  }) {
    return _apiClient.post<TravelReviewDetailDto>(
      ApiEndpoints.travelReviews(projectCode),
      data: request.toJson(),
      fromJson: (json) => TravelReviewDetailDto.fromJson(_asMap(json)),
    );
  }

  Future<Result<TravelReviewDetailDto>> update({
    required String projectCode,
    required String reviewId,
    required TravelReviewUpdateRequestDto request,
  }) {
    return _apiClient.patch<TravelReviewDetailDto>(
      ApiEndpoints.travelReview(projectCode, reviewId),
      data: request.toJson(),
      fromJson: (json) => TravelReviewDetailDto.fromJson(_asMap(json)),
    );
  }

  Future<Result<void>> delete({
    required String projectCode,
    required String reviewId,
  }) {
    return _apiClient.delete<void>(
      ApiEndpoints.travelReview(projectCode, reviewId),
      fromJson: (_) {},
    );
  }
}

List<T> _decodeList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final source = json is List
      ? json
      : json is Map<String, dynamic>
      ? json['items'] ?? json['content'] ?? json['data']
      : null;
  if (source is! List) return <T>[];
  return source
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

Map<String, dynamic> _asMap(dynamic json) {
  return json is Map<String, dynamic> ? json : const <String, dynamic>{};
}
