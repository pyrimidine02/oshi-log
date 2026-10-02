/// EN: Domain entities for the Zukan pilgrimage stamp collection.
/// KO: 성지순례 도감 스탬프 컬렉션의 도메인 엔티티.
library;

/// EN: Completion status of a stamp in a collection.
/// KO: 컬렉션 내 스탬프 완료 상태.
enum StampStatus {
  /// EN: Not yet visited.
  /// KO: 아직 방문하지 않음.
  notVisited,

  /// EN: Place visited and stamp earned.
  /// KO: 장소 방문 및 스탬프 획득.
  stamped;

  /// EN: Parses a raw string value into [StampStatus].
  /// KO: 원시 문자열 값을 [StampStatus]로 파싱합니다.
  static StampStatus fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'stamped' => StampStatus.stamped,
      _ => StampStatus.notVisited,
    };
  }
}

/// EN: A single place stamp within a zukan collection.
/// KO: 도감 컬렉션 내 단일 장소 스탬프.
class ZukanStamp {
  const ZukanStamp({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.status,
    this.placeImageUrl,
    this.episodeHint,
    this.visitedAt,
    this.sortOrder = 0,
  });

  final String id;
  final String placeId;
  final String placeName;
  final StampStatus status;
  final String? placeImageUrl;

  /// EN: Episode or scene hint (e.g. "Ep.3 - Cafe scene").
  /// KO: 에피소드 또는 장면 힌트 (예: "3화 - 카페 장면").
  final String? episodeHint;
  final DateTime? visitedAt;
  final int sortOrder;

  /// EN: Whether this stamp has been earned.
  /// KO: 스탬프 획득 여부.
  bool get isStamped => status == StampStatus.stamped;
}

/// EN: A zukan collection — a thematic group of places.
/// KO: 도감 컬렉션 — 테마별 장소 그룹.
class ZukanCollection {
  const ZukanCollection({
    required this.id,
    required this.title,
    required this.stamps,
    this.projectId,
    this.description,
    this.coverImageUrl,
    this.rewardBadgeImageUrl,
    this.rewardDescription,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final List<ZukanStamp> stamps;
  final String? projectId;
  final String? description;
  final String? coverImageUrl;
  final String? rewardBadgeImageUrl;
  final String? rewardDescription;
  final int sortOrder;

  /// EN: Total number of stamps in this collection.
  /// KO: 이 컬렉션의 전체 스탬프 수.
  int get totalCount => stamps.length;

  /// EN: Number of stamps that have been earned.
  /// KO: 획득한 스탬프 수.
  int get stampedCount => stamps.where((s) => s.isStamped).length;

  /// EN: Whether all stamps in this collection have been earned.
  /// KO: 이 컬렉션의 모든 스탬프를 획득했는지 여부.
  bool get isCompleted => totalCount > 0 && stampedCount >= totalCount;

  /// EN: Ratio of stamps earned (0.0 – 1.0).
  /// KO: 획득된 스탬프 비율 (0.0 – 1.0).
  double get progressRatio => totalCount > 0 ? stampedCount / totalCount : 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZukanCollection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// EN: Summary info for listing collections (no stamps detail).
/// KO: 컬렉션 목록 표시용 요약 정보 (스탬프 상세 없음).
class ZukanCollectionSummary {
  const ZukanCollectionSummary({
    required this.id,
    required this.title,
    required this.totalCount,
    required this.stampedCount,
    this.projectId,
    this.description,
    this.coverImageUrl,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final int totalCount;
  final int stampedCount;
  final String? projectId;
  final String? description;
  final String? coverImageUrl;
  final bool isCompleted;
  final int sortOrder;

  /// EN: Ratio of stamps earned (0.0 – 1.0).
  /// KO: 획득된 스탬프 비율 (0.0 – 1.0).
  double get progressRatio => totalCount > 0 ? stampedCount / totalCount : 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZukanCollectionSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
