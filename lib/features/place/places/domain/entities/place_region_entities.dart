/// EN: Place region filter entities.
/// KO: 장소 지역 필터 엔티티.
library;

class RegionOption {
  const RegionOption({
    required this.code,
    required this.name,
    required this.level,
    required this.placeCount,
    required this.hasChildren,
    required this.displayOrder,
    this.parentCode,
  });

  final String code;
  final String name;
  final int level;
  final int placeCount;
  final bool hasChildren;
  final String? parentCode;
  final int displayOrder;
}

class RegionFilterOptions {
  const RegionFilterOptions({
    required this.countries,
    required this.popularRegions,
    required this.totalRegions,
    required this.totalPlaces,
    required this.lastUpdated,
  });

  final List<RegionOption> countries;
  final List<RegionOption> popularRegions;
  final int totalRegions;
  final int totalPlaces;
  final String lastUpdated;
}

class Coordinate {
  const Coordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class RegionMapBounds {
  const RegionMapBounds({
    required this.northEast,
    required this.southWest,
    required this.center,
    required this.zoom,
  });

  final Coordinate northEast;
  final Coordinate southWest;
  final Coordinate center;
  final int zoom;
}
