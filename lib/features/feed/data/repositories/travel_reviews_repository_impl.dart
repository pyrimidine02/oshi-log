/// EN: Maps the travel-review wire contract into immutable domain objects.
/// KO: 여행 후기 전송 계약을 불변 도메인 객체로 변환합니다.
library;

import '../../../../core/utils/result.dart';
import '../../domain/entities/travel_review.dart';
import '../../domain/repositories/travel_reviews_repository.dart';
import '../datasources/travel_reviews_remote_data_source.dart';
import '../dto/travel_review_dto.dart';
import '../mappers/travel_review_mappers.dart';

class TravelReviewsRepositoryImpl implements TravelReviewsRepository {
  const TravelReviewsRepositoryImpl(this._remoteDataSource);

  final TravelReviewsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TravelReviewSummary>>> getReviews({
    required String projectCode,
    int page = 0,
    int size = 20,
  }) async {
    final result = await _remoteDataSource.list(
      projectCode: projectCode,
      page: page,
      size: size,
    );
    return result.map(
      (items) => items.map((value) => value.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<Result<TravelReviewDetail>> getReview({
    required String projectCode,
    required String reviewId,
  }) async {
    final result = await _remoteDataSource.detail(
      projectCode: projectCode,
      reviewId: reviewId,
    );
    return result.map((value) => value.toDomain());
  }

  @override
  Future<Result<TravelReviewDetail>> create({
    required String projectCode,
    required TravelReviewDraft draft,
  }) async {
    final result = await _remoteDataSource.create(
      projectCode: projectCode,
      request: TravelReviewCreateRequestDto(
        title: draft.title,
        content: draft.content,
        imageUploadIds: draft.imageUploadIds,
        tags: draft.tags,
        stops: draft.stops.map(_stopRequest).toList(growable: false),
        events: draft.events.map(_eventRequest).toList(growable: false),
        fanSubjectIds: draft.fanSubjectIds,
        tripStartedOn: draft.tripStartedOn,
        tripEndedOn: draft.tripEndedOn,
        routeNote: draft.routeNote,
      ),
    );
    return result.map((value) => value.toDomain());
  }

  @override
  Future<Result<TravelReviewDetail>> update({
    required String projectCode,
    required String reviewId,
    required TravelReviewPatch patch,
  }) async {
    final result = await _remoteDataSource.update(
      projectCode: projectCode,
      reviewId: reviewId,
      request: TravelReviewUpdateRequestDto(
        title: patch.title,
        content: patch.content,
        imageUploadIds: patch.imageUploadIds,
        tags: patch.tags,
        stops: patch.stops?.map(_stopRequest).toList(growable: false),
        events: patch.events?.map(_eventRequest).toList(growable: false),
        fanSubjectIds: patch.fanSubjectIds,
        tripStartedOn: patch.tripStartedOn,
        tripEndedOn: patch.tripEndedOn,
        routeNote: patch.routeNote,
      ),
    );
    return result.map((value) => value.toDomain());
  }

  @override
  Future<Result<void>> delete({
    required String projectCode,
    required String reviewId,
  }) {
    return _remoteDataSource.delete(
      projectCode: projectCode,
      reviewId: reviewId,
    );
  }
}

TravelReviewStopRequestDto _stopRequest(TravelReviewStopDraft stop) {
  return TravelReviewStopRequestDto(
    placeId: stop.placeId,
    verifiedVisitId: stop.verifiedVisitId,
    note: stop.note,
  );
}

TravelReviewEventRequestDto _eventRequest(TravelReviewEventDraft event) {
  return TravelReviewEventRequestDto(
    liveEventId: event.liveEventId,
    verifiedAttendanceId: event.verifiedAttendanceId,
    note: event.note,
  );
}
