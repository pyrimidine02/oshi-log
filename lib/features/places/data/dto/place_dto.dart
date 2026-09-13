/// EN: Place DTOs aligned with Swagger schema.
/// KO: Swagger 스키마에 맞춘 장소 DTO.
library;

import '../../../../core/models/image_meta_dto.dart';

class PlaceDirectionProviderDto {
  const PlaceDirectionProviderDto({
    required this.provider,
    required this.label,
    required this.url,
  });

  final String provider;
  final String label;
  final String url;

  factory PlaceDirectionProviderDto.fromJson(Map<String, dynamic> json) {
    return PlaceDirectionProviderDto(
      provider: json['provider'] as String? ?? '',
      label: json['label'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'provider': provider, 'label': label, 'url': url};
  }
}

class PlaceDirectionsDto {
  const PlaceDirectionsDto({
    required this.countryCode,
    required this.providers,
  });

  final String countryCode;
  final List<PlaceDirectionProviderDto> providers;

  factory PlaceDirectionsDto.fromJson(Map<String, dynamic> json) {
    final providersRaw = json['providers'];
    final providers = <PlaceDirectionProviderDto>[];
    if (providersRaw is List) {
      providers.addAll(
        providersRaw.whereType<Map<String, dynamic>>().map(
          PlaceDirectionProviderDto.fromJson,
        ),
      );
    }
    return PlaceDirectionsDto(
      countryCode: json['countryCode'] as String? ?? '',
      providers: providers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'providers': providers.map((provider) => provider.toJson()).toList(),
    };
  }
}

class RegionHierarchyNodeDto {
  const RegionHierarchyNodeDto({
    required this.code,
    required this.nameKo,
    required this.nameEn,
    required this.level,
    this.nameJa,
  });

  final String code;
  final String nameKo;
  final String nameEn;
  final String? nameJa;
  final int level;

  factory RegionHierarchyNodeDto.fromJson(Map<String, dynamic> json) {
    return RegionHierarchyNodeDto(
      code: json['code'] as String? ?? '',
      nameKo: json['nameKo'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameJa: json['nameJa'] as String?,
      level: _int(json['level']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'nameKo': nameKo,
      'nameEn': nameEn,
      'nameJa': nameJa,
      'level': level,
    };
  }
}

class PlaceRegionSummaryDto {
  const PlaceRegionSummaryDto({
    required this.code,
    required this.nameKo,
    required this.nameEn,
    required this.level,
    required this.hierarchy,
    required this.primaryName,
    required this.path,
    this.nameJa,
  });

  final String code;
  final String nameKo;
  final String nameEn;
  final String? nameJa;
  final int level;
  final List<RegionHierarchyNodeDto> hierarchy;
  final String primaryName;
  final String path;

  factory PlaceRegionSummaryDto.fromJson(Map<String, dynamic> json) {
    final hierarchyRaw = json['hierarchy'];
    final hierarchy = <RegionHierarchyNodeDto>[];
    if (hierarchyRaw is List) {
      hierarchy.addAll(
        hierarchyRaw.whereType<Map<String, dynamic>>().map(
          RegionHierarchyNodeDto.fromJson,
        ),
      );
    }

    return PlaceRegionSummaryDto(
      code: json['code'] as String? ?? '',
      nameKo: json['nameKo'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameJa: json['nameJa'] as String?,
      level: _int(json['level']),
      hierarchy: hierarchy,
      primaryName: json['primaryName'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'nameKo': nameKo,
      'nameEn': nameEn,
      'nameJa': nameJa,
      'level': level,
      'hierarchy': hierarchy.map((node) => node.toJson()).toList(),
      'primaryName': primaryName,
      'path': path,
    };
  }
}

class PlaceSummaryDto {
  const PlaceSummaryDto({
    required this.id,
    required this.name,
    required this.types,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.introText,
    this.thumbnailUrl,
    this.thumbnailFilename,
    this.thumbnailSize,
    this.regionSummary,
    this.directions,
  });

  final String id;
  final String name;
  final List<String> types;
  final List<String> tags;
  final String? introText;
  final double latitude;
  final double longitude;
  final String? thumbnailUrl;
  final String? thumbnailFilename;
  final int? thumbnailSize;
  final PlaceRegionSummaryDto? regionSummary;
  final PlaceDirectionsDto? directions;

  factory PlaceSummaryDto.fromJson(Map<String, dynamic> json) {
    return PlaceSummaryDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      types: _stringList(json['types']),
      tags: _stringList(json['tags']),
      introText: json['introText'] as String?,
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailFilename: json['thumbnailFilename'] as String?,
      thumbnailSize: _intOrNull(json['thumbnailSize']),
      regionSummary: json['regionSummary'] is Map<String, dynamic>
          ? PlaceRegionSummaryDto.fromJson(
              json['regionSummary'] as Map<String, dynamic>,
            )
          : null,
      directions: json['directions'] is Map<String, dynamic>
          ? PlaceDirectionsDto.fromJson(
              json['directions'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'types': types,
      'tags': tags,
      'introText': introText,
      'latitude': latitude,
      'longitude': longitude,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailFilename': thumbnailFilename,
      'thumbnailSize': thumbnailSize,
      'regionSummary': regionSummary?.toJson(),
      'directions': directions?.toJson(),
    };
  }
}

class PlaceDetailDto {
  const PlaceDetailDto({
    required this.id,
    required this.name,
    required this.types,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.images,
    this.introText,
    this.description,
    this.address,
    this.primaryImage,
    this.regionSummary,
    this.directions,
    this.unitIds = const [],
    this.projectIds = const [],
    this.characterIds = const [],
  });

  final String id;
  final String name;
  final List<String> types;
  final String? introText;
  final double latitude;
  final double longitude;
  final String? description;
  final String? address;
  final List<String> tags;
  final ImageMetaDto? primaryImage;
  final List<ImageMetaDto> images;
  final PlaceRegionSummaryDto? regionSummary;
  final PlaceDirectionsDto? directions;
  final List<String> unitIds;
  final List<String> projectIds;
  final List<String> characterIds;

  factory PlaceDetailDto.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final images = <ImageMetaDto>[];
    if (imagesRaw is List) {
      images.addAll(
        imagesRaw.whereType<Map<String, dynamic>>().map(ImageMetaDto.fromJson),
      );
    }

    return PlaceDetailDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      types: _stringList(json['types']),
      introText: json['introText'] as String?,
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      description: _firstNonEmptyString(
        json['description'],
        json['descriptionMarkdown'] ?? json['description_markdown'],
      ),
      address: json['address'] as String?,
      tags: _stringList(json['tags']),
      primaryImage: json['primaryImage'] is Map<String, dynamic>
          ? ImageMetaDto.fromJson(json['primaryImage'] as Map<String, dynamic>)
          : null,
      images: images,
      regionSummary: json['regionSummary'] is Map<String, dynamic>
          ? PlaceRegionSummaryDto.fromJson(
              json['regionSummary'] as Map<String, dynamic>,
            )
          : null,
      directions: json['directions'] is Map<String, dynamic>
          ? PlaceDirectionsDto.fromJson(
              json['directions'] as Map<String, dynamic>,
            )
          : null,
      unitIds: _stringList(json['unitIds'] ?? json['unit_ids']),
      projectIds: _stringList(json['projectIds'] ?? json['project_ids']),
      characterIds: _stringList(json['characterIds'] ?? json['character_ids']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'types': types,
      'introText': introText,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'address': address,
      'tags': tags,
      'primaryImage': primaryImage?.toJson(),
      'images': images.map((image) => image.toJson()).toList(),
      'regionSummary': regionSummary?.toJson(),
      'directions': directions?.toJson(),
      'unitIds': unitIds,
      'projectIds': projectIds,
      'characterIds': characterIds,
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return <String>[];
}

String? _firstNonEmptyString(dynamic primary, dynamic fallback) {
  if (primary is String && primary.isNotEmpty) return primary;
  if (fallback is String && fallback.isNotEmpty) return fallback;
  return null;
}
