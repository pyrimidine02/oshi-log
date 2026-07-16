/// EN: Data Transfer Object for home banner API responses.
/// KO: 홈 배너 API 응답의 데이터 전송 객체.
library;

import '../../domain/entities/home_banner.dart';

/// EN: Raw JSON mapping for a single home banner slide.
/// KO: 단일 홈 배너 슬라이드의 원시 JSON 매핑.
class HomeBannerDto {
  const HomeBannerDto({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionType,
    this.actionValue,
    this.sortOrder = 0,
  });

  /// EN: Deserialises a [HomeBannerDto] from a raw JSON map.
  /// KO: 원시 JSON 맵에서 [HomeBannerDto]를 역직렬화합니다.
  factory HomeBannerDto.fromJson(Map<String, dynamic> json) {
    return HomeBannerDto(
      id: json['id'] as String? ?? '',
      // EN: Accept both camelCase and snake_case from the server.
      // KO: 서버에서 camelCase와 snake_case를 모두 허용합니다.
      imageUrl:
          json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType:
          json['actionType'] as String? ?? json['action_type'] as String?,
      actionValue:
          json['actionValue'] as String? ?? json['action_value'] as String?,
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? actionType;
  final String? actionValue;
  final int sortOrder;

  /// EN: Converts this DTO to the domain [HomeBanner] entity.
  /// KO: 이 DTO를 도메인 [HomeBanner] 엔티티로 변환합니다.
  HomeBanner toEntity() => HomeBanner(
    id: id,
    imageUrl: imageUrl,
    title: title,
    subtitle: subtitle,
    actionType: HomeBannerActionType.fromString(actionType),
    actionValue: actionValue,
    sortOrder: sortOrder,
  );
}
