/// EN: Data Transfer Objects for the titles feature.
/// KO: 칭호(Title) 기능의 데이터 전송 객체(DTO).
library;

import 'package:oshi_log/features/identity/progression/domain/entities/title_entities.dart';

// =============================================================================
// EN: TitleCatalogItemDto — catalog entry returned from GET /api/v1/titles
// KO: GET /api/v1/titles 에서 반환되는 카탈로그 항목 DTO
// =============================================================================

/// EN: DTO for a single title catalog item returned from the API.
///     [isEarned] and [isActive] are null when the caller is unauthenticated.
/// KO: API에서 반환된 단일 칭호 카탈로그 아이템 DTO.
///     [isEarned]와 [isActive]는 비인증 호출 시 null입니다.
class TitleCatalogItemDto {
  const TitleCatalogItemDto({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.sortOrder,
    this.description,
    this.projectId,
    this.isEarned,
    this.isActive,
  });

  /// EN: Unique identifier of the title.
  /// KO: 칭호의 고유 식별자.
  final String id;

  /// EN: Short machine-readable code for the title (e.g., "first_pilgrim").
  /// KO: 칭호의 짧은 기계 판독 코드 (예: "first_pilgrim").
  final String code;

  /// EN: Human-readable display name.
  /// KO: 사람이 읽을 수 있는 표시 이름.
  final String name;

  /// EN: Optional description explaining the unlock condition.
  /// KO: 해금 조건을 설명하는 선택적 설명.
  final String? description;

  /// EN: Category of the title (raw string from API).
  /// KO: 칭호의 카테고리 (API에서 반환된 원시 문자열).
  final String category;

  /// EN: Project scope identifier, null for global titles.
  /// KO: 프로젝트 범위 식별자. 전역 칭호의 경우 null.
  final String? projectId;

  /// EN: Sort order for catalog display.
  /// KO: 카탈로그 표시 순서.
  final int sortOrder;

  /// EN: Whether the authenticated user has earned this title.
  ///     Null when unauthenticated.
  /// KO: 인증된 사용자가 이 칭호를 획득했는지 여부.
  ///     비인증 시 null.
  final bool? isEarned;

  /// EN: Whether this is the authenticated user's currently active title.
  ///     Null when unauthenticated.
  /// KO: 인증된 사용자가 현재 활성화한 칭호인지 여부.
  ///     비인증 시 null.
  final bool? isActive;

  /// EN: Deserializes a [TitleCatalogItemDto] from a JSON map.
  /// KO: JSON 맵에서 [TitleCatalogItemDto]를 역직렬화합니다.
  factory TitleCatalogItemDto.fromJson(Map<String, dynamic> json) {
    return TitleCatalogItemDto(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'activity',
      projectId: json['projectId'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isEarned: json['isEarned'] as bool?,
      isActive: json['isActive'] as bool?,
    );
  }

  /// EN: Serializes this DTO to a JSON map.
  /// KO: 이 DTO를 JSON 맵으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      if (description != null) 'description': description,
      'category': category,
      if (projectId != null) 'projectId': projectId,
      'sortOrder': sortOrder,
      if (isEarned != null) 'isEarned': isEarned,
      if (isActive != null) 'isActive': isActive,
    };
  }
}

// =============================================================================
// EN: ActiveTitleItemDto — active title returned from user-scoped endpoints
// KO: 사용자 범위 엔드포인트에서 반환되는 활성 칭호 DTO
// =============================================================================

/// EN: DTO for the active title item returned from user-scoped title endpoints.
///     Returned as HTTP 200 when a title is set; endpoint returns HTTP 204 when
///     no title is active (caller must handle null gracefully).
/// KO: 사용자 범위 칭호 엔드포인트에서 반환되는 활성 칭호 아이템 DTO.
///     칭호가 설정된 경우 HTTP 200으로 반환되며, 활성 칭호가 없으면
///     엔드포인트가 HTTP 204를 반환합니다 (호출자는 null을 적절히 처리해야 합니다).
class ActiveTitleItemDto {
  const ActiveTitleItemDto({
    required this.titleId,
    required this.code,
    required this.name,
    required this.category,
    this.description,
  });

  /// EN: Identifier of the active title.
  /// KO: 활성 칭호의 식별자.
  final String titleId;

  /// EN: Short machine-readable code.
  /// KO: 짧은 기계 판독 코드.
  final String code;

  /// EN: Human-readable display name.
  /// KO: 사람이 읽을 수 있는 표시 이름.
  final String name;

  /// EN: Optional description of the title.
  /// KO: 칭호에 대한 선택적 설명.
  final String? description;

  /// EN: Category of the title (raw string from API).
  /// KO: 칭호의 카테고리 (API에서 반환된 원시 문자열).
  final String category;

  /// EN: Deserializes an [ActiveTitleItemDto] from a JSON map.
  /// KO: JSON 맵에서 [ActiveTitleItemDto]를 역직렬화합니다.
  factory ActiveTitleItemDto.fromJson(Map<String, dynamic> json) {
    return ActiveTitleItemDto(
      titleId: json['titleId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'activity',
    );
  }

  /// EN: Serializes this DTO to a JSON map.
  /// KO: 이 DTO를 JSON 맵으로 직렬화합니다.
  Map<String, dynamic> toJson() {
    return {
      'titleId': titleId,
      'code': code,
      'name': name,
      if (description != null) 'description': description,
      'category': category,
    };
  }
}

// =============================================================================
// EN: Domain mapping extensions
// KO: 도메인 매핑 확장
// =============================================================================

/// EN: Extension for mapping [TitleCatalogItemDto] to the domain
///     [TitleCatalogItem].
/// KO: [TitleCatalogItemDto]를 도메인 [TitleCatalogItem]으로 매핑하는 확장.
extension TitleCatalogItemDtoMapping on TitleCatalogItemDto {
  /// EN: Converts this DTO into a domain [TitleCatalogItem].
  /// KO: 이 DTO를 도메인 [TitleCatalogItem]으로 변환합니다.
  TitleCatalogItem toDomain() {
    return TitleCatalogItem(
      id: id,
      code: code,
      name: name,
      description: description,
      category: TitleCategory.fromString(category),
      projectId: projectId,
      sortOrder: sortOrder,
      isEarned: isEarned,
      isActive: isActive,
    );
  }
}

/// EN: Extension for mapping [ActiveTitleItemDto] to the domain
///     [ActiveTitleItem].
/// KO: [ActiveTitleItemDto]를 도메인 [ActiveTitleItem]으로 매핑하는 확장.
extension ActiveTitleItemDtoMapping on ActiveTitleItemDto {
  /// EN: Converts this DTO into a domain [ActiveTitleItem].
  /// KO: 이 DTO를 도메인 [ActiveTitleItem]으로 변환합니다.
  ActiveTitleItem toDomain() {
    return ActiveTitleItem(
      titleId: titleId,
      code: code,
      name: name,
      description: description,
      category: TitleCategory.fromString(category),
    );
  }
}
