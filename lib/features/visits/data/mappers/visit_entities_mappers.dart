/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/user_ranking_dto.dart';
import '../dto/visit_dto.dart';
import '../../domain/entities/visit_entities.dart';

extension VisitEventDetailDtoDomainMapper on VisitEventDetailDto {
  VisitEvent toDomain() {
    return VisitEvent(
      id: id,
      placeId: placeId,
      visitedAt: visitedAt,
      status: VisitVerificationStatus.normalize(status),
      distanceM: distanceM,
      accuracy: accuracy,
    );
  }
}

extension VisitEventDtoDomainMapper on VisitEventDto {
  VisitEvent toDomain() {
    final dto = this;

    return VisitEvent(
      id: dto.id,
      placeId: dto.placeId,
      visitedAt: dto.visitedAt,
      status: VisitVerificationStatus.normalize(dto.status),
      distanceM: dto.distanceM,
    );
  }
}

extension VisitSummaryDtoDomainMapper on VisitSummaryDto {
  VisitSummary toDomain() {
    final dto = this;

    return VisitSummary(
      placeId: dto.placeId,
      visitCount: dto.visitCount,
      firstVisitedAt: dto.firstVisitedAt,
      lastVisitedAt: dto.lastVisitedAt,
    );
  }
}

extension UserRankingDtoDomainMapper on UserRankingDto {
  UserRanking toDomain() {
    final dto = this;

    return UserRanking(
      rank: dto.rank,
      totalVisits: dto.totalVisits,
      uniquePlaces: dto.uniquePlaces,
      totalUsers: dto.totalUsers,
    );
  }
}
