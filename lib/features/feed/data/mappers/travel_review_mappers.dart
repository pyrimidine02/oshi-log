/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/travel_review_dto.dart';
import '../../domain/entities/travel_review.dart';
import '../mappers/feed_entities_mappers.dart';

extension TravelReviewPlaceSummaryDtoDomainMapper
    on TravelReviewPlaceSummaryDto {
  TravelReviewPlace toDomain() {
    final dto = this;

    return TravelReviewPlace(
      id: dto.id,
      name: dto.name,
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
    );
  }
}

extension TravelReviewLiveEventSummaryDtoDomainMapper
    on TravelReviewLiveEventSummaryDto {
  TravelReviewLiveEvent toDomain() {
    final dto = this;

    return TravelReviewLiveEvent(
      id: dto.id,
      title: dto.title,
      startTime: dto.startTime,
      endTime: dto.endTime,
      placeId: dto.placeId,
      posterUrl: dto.posterUrl,
    );
  }
}

extension TravelReviewStopDtoDomainMapper on TravelReviewStopDto {
  TravelReviewStop toDomain() {
    final dto = this;

    return TravelReviewStop(
      order: dto.order,
      place: dto.place.toDomain(),
      verified: dto.verified,
      verifiedVisitId: dto.verifiedVisitId,
      note: dto.note,
    );
  }
}

extension TravelReviewEventDtoDomainMapper on TravelReviewEventDto {
  TravelReviewEvent toDomain() {
    final dto = this;

    return TravelReviewEvent(
      order: dto.order,
      event: dto.event.toDomain(),
      verified: dto.verified,
      verifiedAttendanceId: dto.verifiedAttendanceId,
      note: dto.note,
    );
  }
}

extension TravelReviewFanSubjectSummaryDtoDomainMapper
    on TravelReviewFanSubjectSummaryDto {
  TravelReviewFanSubject toDomain() {
    final dto = this;

    return TravelReviewFanSubject(
      id: dto.id,
      type: dto.type,
      name: dto.name,
      imageUrl: dto.imageUrl,
      primary: dto.primary,
    );
  }
}

extension TravelReviewSummaryDtoDomainMapper on TravelReviewSummaryDto {
  TravelReviewSummary toDomain() {
    final dto = this;

    return TravelReviewSummary(
      id: dto.id,
      postId: dto.postId,
      projectId: dto.projectId,
      post: dto.post.toDomain(),
      tripStartedOn: dto.tripStartedOn,
      tripEndedOn: dto.tripEndedOn,
      routeNote: dto.routeNote,
      stops: List.unmodifiable(
        dto.stops.map((value) => value.toDomain()).toList(growable: false),
      ),
      events: List.unmodifiable(
        dto.events.map((value) => value.toDomain()).toList(growable: false),
      ),
      fanSubjects: List.unmodifiable(
        dto.fanSubjects
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}

extension TravelReviewDetailDtoDomainMapper on TravelReviewDetailDto {
  TravelReviewDetail toDomain() {
    final dto = this;

    return TravelReviewDetail(
      id: dto.id,
      postId: dto.postId,
      projectId: dto.projectId,
      post: dto.post.toDomain(),
      tripStartedOn: dto.tripStartedOn,
      tripEndedOn: dto.tripEndedOn,
      routeNote: dto.routeNote,
      stops: List.unmodifiable(
        dto.stops.map((value) => value.toDomain()).toList(growable: false),
      ),
      events: List.unmodifiable(
        dto.events.map((value) => value.toDomain()).toList(growable: false),
      ),
      fanSubjects: List.unmodifiable(
        dto.fanSubjects
            .map((value) => value.toDomain())
            .toList(growable: false),
      ),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
