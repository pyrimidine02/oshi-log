/// EN: DTO to domain mappings for news.
/// KO: 뉴스 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/news_dto.dart';
import '../../domain/entities/news_entities.dart';

extension NewsSummaryDtoDomainMapper on NewsSummaryDto {
  NewsSummary toDomain() {
    final dto = this;

    return NewsSummary(
      id: dto.id,
      title: dto.title,
      publishedAt: dto.publishedAt,
      thumbnailUrl: dto.thumbnailUrl,
    );
  }
}

extension NewsDetailDtoDomainMapper on NewsDetailDto {
  NewsDetail toDomain() {
    final dto = this;

    final images = dto.images.map((image) => image.url).toList();
    final cover =
        dto.coverImage?.url ?? (images.isNotEmpty ? images.first : null);

    return NewsDetail(
      id: dto.id,
      title: dto.title,
      body: dto.body,
      status: dto.status,
      publishedAt: dto.publishedAt,
      coverImageUrl: cover,
      imageUrls: List.unmodifiable(images),
    );
  }
}
