/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/place_dto.dart';
import '../dto/place_stats_dto.dart';
import '../../domain/entities/place_entities.dart';

extension PlaceSummaryDtoDomainMapper on PlaceSummaryDto {
  PlaceSummary toDomain() {
    final dto = this;

    return PlaceSummary(
      id: dto.id,
      name: dto.name,
      address: dto.regionSummary?.primaryName ?? '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      types: List.unmodifiable(dto.types),
      tags: List.unmodifiable(dto.tags),
      imageUrl: dto.thumbnailUrl,
      distanceLabel: null,
      isVerified: false,
      isFavorite: false,
      rating: null,
      regionCode: dto.regionSummary?.code,
      regionName: dto.regionSummary?.primaryName,
      regionPath: dto.regionSummary?.path,
      directions: dto.directions?.toDomain(),
    );
  }
}

extension PlaceDetailDtoDomainMapper on PlaceDetailDto {
  PlaceDetail toDomain({PlaceStatsDto? stats}) {
    final dto = this;

    final imageUrls = dto.images.map((image) => image.url).toList();
    final heroImageUrl =
        dto.primaryImage?.url ??
        (imageUrls.isNotEmpty ? imageUrls.first : null);

    return PlaceDetail(
      id: dto.id,
      name: dto.name,
      address: dto.address ?? '',
      types: List.unmodifiable(dto.types),
      description: dto.description,
      heroImageUrl: heroImageUrl,
      imageUrls: List.unmodifiable(imageUrls),
      isVerified: false,
      isFavorite: false,
      rating: null,
      visitCount: stats?.visitCount,
      favoriteCount: stats?.favoriteCount,
      tags: List.unmodifiable(dto.tags),
      directions: dto.directions?.toDomain(),
    );
  }
}

extension PlaceDirectionProviderDtoDomainMapper on PlaceDirectionProviderDto {
  PlaceDirectionProvider toDomain() {
    final dto = this;

    return PlaceDirectionProvider(
      provider: dto.provider,
      label: dto.label,
      url: dto.url,
    );
  }
}

extension PlaceDirectionsDtoDomainMapper on PlaceDirectionsDto {
  PlaceDirections toDomain() {
    final dto = this;

    return PlaceDirections(
      countryCode: dto.countryCode,
      providers: List.unmodifiable(
        dto.providers
            .map((value) => value.toDomain())
            .where((provider) => provider.url.isNotEmpty)
            .toList(),
      ),
    );
  }
}
