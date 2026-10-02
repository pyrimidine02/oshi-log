/// EN: Data Transfer Objects for the profile banner feature.
/// KO: 프로필 배너 기능의 데이터 전송 객체(DTO).
library;

import 'package:oshi_log/features/identity/progression/domain/entities/banner_entities.dart';

/// EN: DTO for a single banner catalog item returned from the API.
/// KO: API에서 반환된 단일 배너 카탈로그 아이템 DTO.
class BannerItemDto {
  const BannerItemDto({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.rarity,
    required this.unlockType,
    required this.isUnlocked,
    required this.isActive,
    this.unlockDescription,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;

  /// EN: Raw string rarity value from API (e.g., "common", "rare").
  /// KO: API의 원시 희귀도 문자열 값 (예: "common", "rare").
  final String rarity;

  /// EN: Raw string unlock type from API (e.g., "tier", "title").
  /// KO: API의 원시 해금 유형 문자열 값 (예: "tier", "title").
  final String unlockType;
  final bool isUnlocked;
  final bool isActive;
  final String? unlockDescription;

  /// EN: Deserializes a [BannerItemDto] from a JSON map.
  /// KO: JSON 맵에서 [BannerItemDto]를 역직렬화합니다.
  factory BannerItemDto.fromJson(Map<String, dynamic> json) {
    return BannerItemDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      rarity: json['rarity'] as String? ?? 'common',
      unlockType: json['unlockType'] as String? ?? 'defaultBanner',
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      unlockDescription: json['unlockDescription'] as String?,
    );
  }

  /// EN: Serializes this DTO to a JSON map.
  /// KO: 이 DTO를 JSON 맵으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'rarity': rarity,
      'unlockType': unlockType,
      'isUnlocked': isUnlocked,
      'isActive': isActive,
      if (unlockDescription != null) 'unlockDescription': unlockDescription,
    };
  }
}

/// EN: DTO for the active banner response from the API.
/// KO: API 활성 배너 응답 DTO.
class ActiveBannerDto {
  const ActiveBannerDto({
    this.bannerId,
    this.imageUrl,
    this.thumbnailUrl,
    this.name,
  });

  final String? bannerId;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? name;

  /// EN: Deserializes an [ActiveBannerDto] from a JSON map.
  /// KO: JSON 맵에서 [ActiveBannerDto]를 역직렬화합니다.
  factory ActiveBannerDto.fromJson(Map<String, dynamic> json) {
    return ActiveBannerDto(
      bannerId: json['bannerId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      name: json['name'] as String?,
    );
  }

  /// EN: Serializes this DTO to a JSON map.
  /// KO: 이 DTO를 JSON 맵으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      if (bannerId != null) 'bannerId': bannerId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (name != null) 'name': name,
    };
  }
}

/// EN: Extension for mapping [BannerItemDto] to the domain [BannerItem].
/// KO: [BannerItemDto]를 도메인 [BannerItem]으로 매핑하는 확장.
extension BannerItemDtoMapping on BannerItemDto {
  /// EN: Converts this DTO into a domain [BannerItem].
  /// KO: 이 DTO를 도메인 [BannerItem]으로 변환합니다.
  BannerItem toDomain() {
    return BannerItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      rarity: BannerRarity.fromString(rarity),
      unlockType: BannerUnlockType.fromString(unlockType),
      unlockDescription: unlockDescription,
      isUnlocked: isUnlocked,
      isActive: isActive,
    );
  }
}

/// EN: Extension for mapping [ActiveBannerDto] to the domain [ActiveBanner].
/// KO: [ActiveBannerDto]를 도메인 [ActiveBanner]로 매핑하는 확장.
extension ActiveBannerDtoMapping on ActiveBannerDto {
  /// EN: Converts this DTO into a domain [ActiveBanner].
  /// KO: 이 DTO를 도메인 [ActiveBanner]로 변환합니다.
  ActiveBanner toDomain() {
    return ActiveBanner(
      bannerId: bannerId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      name: name,
    );
  }
}
