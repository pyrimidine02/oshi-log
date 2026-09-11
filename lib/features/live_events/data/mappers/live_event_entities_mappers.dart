/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/live_event_dto.dart';
import '../../domain/entities/live_event_entities.dart';

extension LiveEventSummaryDtoDomainMapper on LiveEventSummaryDto {
  LiveEventSummary toDomain() {
    final dto = this;

    return LiveEventSummary(
      id: dto.id,
      title: dto.title,
      placeId: dto.placeId,
      venue: dto.venue,
      venueTypes: List.unmodifiable(dto.venueTypes),
      address: dto.address,
      regionCodes: List.unmodifiable(dto.regionCodes),
      showStartTime: dto.showStartTime,
      doorsOpenTime: dto.doorsOpenTime,
      endTime: dto.endTime,
      status: dto.status,
      projectIds: List.unmodifiable(dto.projectIds),
      unitIds: List.unmodifiable(dto.unitIds),
      bannerUrl: dto.bannerUrl,
      ticketUrl: dto.ticketUrl,
    );
  }
}

extension LiveEventDetailDtoDomainMapper on LiveEventDetailDto {
  LiveEventDetail toDomain() {
    final dto = this;

    return LiveEventDetail(
      id: dto.id,
      title: dto.title,
      placeId: dto.placeId,
      venue: dto.venue,
      venueTypes: List.unmodifiable(dto.venueTypes),
      address: dto.address,
      regionCodes: List.unmodifiable(dto.regionCodes),
      description: dto.description,
      showStartTime: dto.showStartTime,
      doorsOpenTime: dto.doorsOpenTime,
      endTime: dto.endTime,
      status: dto.status,
      projectIds: List.unmodifiable(dto.projectIds),
      unitIds: List.unmodifiable(dto.unitIds),
      bannerUrl: dto.banner?.url,
      ticketUrl: dto.ticketUrl,
    );
  }
}

extension LiveAttendanceStateDtoDomainMapper on LiveAttendanceStateDto {
  LiveAttendanceState toDomain() {
    final dto = this;

    return LiveAttendanceState(
      attendanceId: dto.attendanceId,
      liveEventId: dto.liveEventId,
      attended: dto.attended,
      status: LiveAttendanceStatus.normalize(dto.status),
      canUndo: dto.canUndo,
      verificationMethod: dto.verificationMethod,
      attendedAt: dto.attendedAt,
    );
  }
}
