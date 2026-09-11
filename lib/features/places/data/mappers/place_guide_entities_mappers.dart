/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/place_guide_dto.dart';
import '../../domain/entities/place_guide_entities.dart';

extension PlaceGuideSummaryDtoDomainMapper on PlaceGuideSummaryDto {
  PlaceGuideSummary toDomain() {
    final dto = this;

    return PlaceGuideSummary(
      id: dto.id,
      title: dto.title,
      preview: dto.contentPreview,
      updatedAt: dto.updatedAt ?? dto.createdAt,
      hasImages: dto.hasImages,
      imageCount: dto.imageCount,
    );
  }
}
