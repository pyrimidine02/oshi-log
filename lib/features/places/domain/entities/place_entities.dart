/// EN: Place domain entities.
/// KO: 장소 도메인 엔티티.
library;

import '../../data/dto/place_dto.dart';
import '../../data/dto/place_stats_dto.dart';

class PlaceSummary {
  const PlaceSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.types = const [],
    this.tags = const [],
    this.imageUrl,
    this.distanceLabel,
    this.isVerified = false,
    this.isFavorite = false,
    this.rating,
    this.regionCode,
    this.regionName,
    this.regionPath,
    this.directions,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> types;
  final List<String> tags;
  final String? imageUrl;
  final String? distanceLabel;
  final bool isVerified;
  final bool isFavorite;
  final double? rating;
  final String? regionCode;
  final String? regionName;
  final String? regionPath;
  final PlaceDirections? directions;

  factory PlaceSummary.fromDto(PlaceSummaryDto dto) {
    return PlaceSummary(
      id: dto.id,
      name: dto.name,
      address: dto.regionSummary?.primaryName ?? '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      types: dto.types,
      tags: dto.tags,
      imageUrl: dto.thumbnailUrl,
      distanceLabel: null,
      isVerified: false,
      isFavorite: false,
      rating: null,
      regionCode: dto.regionSummary?.code,
      regionName: dto.regionSummary?.primaryName,
      regionPath: dto.regionSummary?.path,
      directions: dto.directions != null
          ? PlaceDirections.fromDto(dto.directions!)
          : null,
    );
  }

  /// EN: Returns an immutable copy with selected presentation enrichments.
  /// KO: 선택한 프레젠테이션 보강값을 반영한 불변 복사본을 반환합니다.
  PlaceSummary copyWith({
    bool? isVerified,
    bool? isFavorite,
    String? distanceLabel,
  }) {
    return PlaceSummary(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      types: types,
      tags: tags,
      imageUrl: imageUrl,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      isVerified: isVerified ?? this.isVerified,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating,
      regionCode: regionCode,
      regionName: regionName,
      regionPath: regionPath,
      directions: directions,
    );
  }
}

class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.types,
    this.description,
    this.heroImageUrl,
    this.imageUrls = const [],
    this.isVerified = false,
    this.isFavorite = false,
    this.rating,
    this.visitCount,
    this.favoriteCount,
    this.tags = const [],
    this.directions,
  });

  final String id;
  final String name;
  final String address;
  final List<String> types;
  final String? description;
  final String? heroImageUrl;
  final List<String> imageUrls;
  final bool isVerified;
  final bool isFavorite;
  final double? rating;
  final int? visitCount;
  final int? favoriteCount;
  final List<String> tags;
  final PlaceDirections? directions;

  factory PlaceDetail.fromDto(PlaceDetailDto dto, {PlaceStatsDto? stats}) {
    final imageUrls = dto.images.map((image) => image.url).toList();
    final heroImageUrl =
        dto.primaryImage?.url ??
        (imageUrls.isNotEmpty ? imageUrls.first : null);

    return PlaceDetail(
      id: dto.id,
      name: dto.name,
      address: dto.address ?? '',
      types: dto.types,
      description: dto.description,
      heroImageUrl: heroImageUrl,
      imageUrls: imageUrls,
      isVerified: false,
      isFavorite: false,
      rating: null,
      visitCount: stats?.visitCount,
      favoriteCount: stats?.favoriteCount,
      tags: dto.tags,
      directions: dto.directions != null
          ? PlaceDirections.fromDto(dto.directions!)
          : null,
    );
  }
}

class PlaceDirectionProvider {
  const PlaceDirectionProvider({
    required this.provider,
    required this.label,
    required this.url,
  });

  final String provider;
  final String label;
  final String url;

  factory PlaceDirectionProvider.fromDto(PlaceDirectionProviderDto dto) {
    return PlaceDirectionProvider(
      provider: dto.provider,
      label: dto.label,
      url: dto.url,
    );
  }
}

class PlaceDirections {
  const PlaceDirections({required this.countryCode, required this.providers});

  final String countryCode;
  final List<PlaceDirectionProvider> providers;

  factory PlaceDirections.fromDto(PlaceDirectionsDto dto) {
    return PlaceDirections(
      countryCode: dto.countryCode,
      providers: dto.providers
          .map(PlaceDirectionProvider.fromDto)
          .where((provider) => provider.url.isNotEmpty)
          .toList(),
    );
  }

  bool get hasProviders => providers.isNotEmpty;
}
