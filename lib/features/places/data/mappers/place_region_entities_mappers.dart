/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/place_region_filter_dto.dart';
import '../../domain/entities/place_region_entities.dart';

extension RegionOptionDtoDomainMapper on RegionOptionDto {
  RegionOption toDomain() {
    final dto = this;

    return RegionOption(
      code: dto.code,
      name: dto.name,
      level: dto.level,
      placeCount: dto.placeCount,
      hasChildren: dto.hasChildren,
      parentCode: dto.parentCode,
      displayOrder: dto.displayOrder,
    );
  }
}

extension RegionFilterOptionsDtoDomainMapper on RegionFilterOptionsDto {
  RegionFilterOptions toDomain() {
    final dto = this;

    return RegionFilterOptions(
      countries: List.unmodifiable(
        dto.countries.map((value) => value.toDomain()).toList(),
      ),
      popularRegions: List.unmodifiable(
        dto.popularRegions.map((value) => value.toDomain()).toList(),
      ),
      totalRegions: dto.totalRegions,
      totalPlaces: dto.totalPlaces,
      lastUpdated: dto.lastUpdated,
    );
  }
}

extension CoordinateDtoDomainMapper on CoordinateDto {
  Coordinate toDomain() {
    final dto = this;

    return Coordinate(latitude: dto.latitude, longitude: dto.longitude);
  }
}

extension RegionMapBoundsDtoDomainMapper on RegionMapBoundsDto {
  RegionMapBounds toDomain() {
    final dto = this;

    return RegionMapBounds(
      northEast: dto.northEast.toDomain(),
      southWest: dto.southWest.toDomain(),
      center: dto.center.toDomain(),
      zoom: dto.zoom,
    );
  }
}
