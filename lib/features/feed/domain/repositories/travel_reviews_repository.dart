/// EN: Repository contract for project-scoped travel reviews.
/// KO: 프로젝트 범위 여행 후기 저장소 계약입니다.
library;

import '../../../../core/utils/result.dart';
import '../entities/travel_review.dart';

abstract interface class TravelReviewsRepository {
  Future<Result<List<TravelReviewSummary>>> getReviews({
    required String projectCode,
    int page = 0,
    int size = 20,
  });

  Future<Result<TravelReviewDetail>> getReview({
    required String projectCode,
    required String reviewId,
  });

  Future<Result<TravelReviewDetail>> create({
    required String projectCode,
    required TravelReviewDraft draft,
  });

  Future<Result<TravelReviewDetail>> update({
    required String projectCode,
    required String reviewId,
    required TravelReviewPatch patch,
  });

  Future<Result<void>> delete({
    required String projectCode,
    required String reviewId,
  });
}
