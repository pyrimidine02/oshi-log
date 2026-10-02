/// EN: DTOs for place region filtering endpoints.
/// KO: 장소 지역 필터링 엔드포인트용 DTO.
library;

class RegionOptionDto {
  const RegionOptionDto({
    required this.code,
    required this.name,
    required this.level,
    required this.placeCount,
    required this.hasChildren,
    required this.displayOrder,
    this.nameEn,
    this.nameJa,
    this.parentCode,
  });

  final String code;
  final String name;
  final String? nameEn;
  final String? nameJa;
  final int level;
  final int placeCount;
  final bool hasChildren;
  final String? parentCode;
  final int displayOrder;

  factory RegionOptionDto.fromJson(Map<String, dynamic> json) {
    return RegionOptionDto(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String?,
      nameJa: json['nameJa'] as String?,
      level: _int(json['level']),
      placeCount: _int(json['placeCount']),
      hasChildren: json['hasChildren'] as bool? ?? false,
      parentCode: json['parentCode'] as String?,
      displayOrder: _int(json['displayOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nameEn': nameEn,
      'nameJa': nameJa,
      'level': level,
      'placeCount': placeCount,
      'hasChildren': hasChildren,
      'parentCode': parentCode,
      'displayOrder': displayOrder,
    };
  }
}

class RegionFilterOptionsDto {
  const RegionFilterOptionsDto({
    required this.countries,
    required this.popularRegions,
    required this.totalRegions,
    required this.totalPlaces,
    required this.lastUpdated,
  });

  final List<RegionOptionDto> countries;
  final List<RegionOptionDto> popularRegions;
  final int totalRegions;
  final int totalPlaces;
  final String lastUpdated;

  factory RegionFilterOptionsDto.fromJson(Map<String, dynamic> json) {
    return RegionFilterOptionsDto(
      countries: _parseOptions(json['countries']),
      popularRegions: _parseOptions(json['popularRegions']),
      totalRegions: _int(json['totalRegions']),
      totalPlaces: _int(json['totalPlaces']),
      lastUpdated: json['lastUpdated'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countries': countries.map((option) => option.toJson()).toList(),
      'popularRegions': popularRegions
          .map((option) => option.toJson())
          .toList(),
      'totalRegions': totalRegions,
      'totalPlaces': totalPlaces,
      'lastUpdated': lastUpdated,
    };
  }
}

class CoordinateDto {
  const CoordinateDto({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory CoordinateDto.fromJson(Map<String, dynamic> json) {
    return CoordinateDto(
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class RegionMapBoundsDto {
  const RegionMapBoundsDto({
    required this.northEast,
    required this.southWest,
    required this.center,
    required this.zoom,
  });

  final CoordinateDto northEast;
  final CoordinateDto southWest;
  final CoordinateDto center;
  final int zoom;

  factory RegionMapBoundsDto.fromJson(Map<String, dynamic> json) {
    return RegionMapBoundsDto(
      northEast: CoordinateDto.fromJson(
        json['northEast'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      southWest: CoordinateDto.fromJson(
        json['southWest'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      center: CoordinateDto.fromJson(
        json['center'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      zoom: _int(json['zoom']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'northEast': northEast.toJson(),
      'southWest': southWest.toJson(),
      'center': center.toJson(),
      'zoom': zoom,
    };
  }
}

List<RegionOptionDto> _parseOptions(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RegionOptionDto.fromJson)
        .toList();
  }
  return <RegionOptionDto>[];
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
