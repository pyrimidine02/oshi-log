/// EN: DTO for a single contributor returned by the contributors endpoint.
/// KO: contributors 엔드포인트가 반환하는 개별 기여자 DTO.
library;

/// EN: One entry in `GET /api/v1/{entityType}/{entityId}/contributors`.
///     Deduplicated by actorId; sorted by lastModifiedAt DESC.
/// KO: `GET /api/v1/{entityType}/{entityId}/contributors` 응답의 항목 1개.
///     actorId 기준 중복 제거, lastModifiedAt 내림차순 정렬.
class ContributorDto {
  const ContributorDto({
    required this.actorId,
    this.nickname,
    this.lastModifiedAt,
    required this.isRegistrant,
  });

  /// EN: Unique actor UUID. System revisions (null actorId) are excluded server-side.
  /// KO: 고유 액터 UUID. 시스템 리비전(actorId가 null인 것)은 서버에서 제외됩니다.
  final String actorId;

  /// EN: Display nickname at the time of the request. May be null if account deleted.
  /// KO: 요청 시점의 표시 닉네임. 계정 삭제 시 null일 수 있습니다.
  final String? nickname;

  /// EN: UTC timestamp of this actor's most recent modification to the entity.
  /// KO: 해당 액터의 가장 최근 수정 UTC 타임스탬프.
  final DateTime? lastModifiedAt;

  /// EN: True if this actor authored the initial CREATE revision.
  /// KO: 최초 CREATE 리비전을 작성한 액터면 true.
  final bool isRegistrant;

  factory ContributorDto.fromJson(Map<String, dynamic> json) {
    final atStr = json['lastModifiedAt'] as String?;
    return ContributorDto(
      actorId: json['actorId'] as String? ?? '',
      nickname: json['nickname'] as String?,
      lastModifiedAt: atStr != null ? DateTime.tryParse(atStr) : null,
      isRegistrant: json['isRegistrant'] as bool? ?? false,
    );
  }
}
