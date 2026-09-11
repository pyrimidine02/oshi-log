/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/favorite_dto.dart';
import '../../domain/entities/favorite_entities.dart';

extension FavoriteItemDtoDomainMapper on FavoriteItemDto {
  FavoriteItem toDomain() {
    final dto = this;

    return FavoriteItem(
      entityId: dto.entityId,
      type: _mapType(dto.entityType),
      projectCode: dto.projectCode,
      title: dto.title,
      thumbnailUrl: dto.thumbnailUrl,
    );
  }
}

FavoriteType _mapType(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('place')) return FavoriteType.place;
  if (value.contains('live') || value.contains('event')) {
    return FavoriteType.liveEvent;
  }
  if (value.contains('news')) return FavoriteType.news;
  if (value.contains('post') || value.contains('community')) {
    return FavoriteType.post;
  }
  return FavoriteType.unknown;
}
