/// EN: Domain entities for the cheer guide feature.
/// KO: 응원 가이드 기능의 도메인 엔티티.
library;

/// EN: Type of audience participation for a cheer section.
/// KO: 응원 섹션의 관중 참여 유형.
enum CheerType {
  /// EN: Audience calls out together.
  /// KO: 관중이 함께 소리칩니다.
  call,

  /// EN: Audience responds to performer.
  /// KO: 관중이 퍼포머에 응답합니다.
  response,

  /// EN: Silence / listen.
  /// KO: 조용히 / 듣기.
  silence,

  /// EN: Everyone waves lights together.
  /// KO: 모두 함께 라이트를 흔듭니다.
  unified,

  /// EN: No specific action.
  /// KO: 특별한 동작 없음.
  none;

  /// EN: Parse a raw string into a [CheerType], defaulting to [none].
  /// KO: 원시 문자열을 [CheerType]으로 파싱합니다. 기본값은 [none].
  static CheerType fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'call' => CheerType.call,
      'response' => CheerType.response,
      'silence' => CheerType.silence,
      'unified' => CheerType.unified,
      _ => CheerType.none,
    };
  }
}

/// EN: A single section of a cheer guide (verse, chorus, bridge, etc.)
/// KO: 응원 가이드의 단일 섹션 (버스, 코러스, 브릿지 등).
class CheerSection {
  const CheerSection({
    required this.id,
    required this.sectionName,
    required this.cheerType,
    this.lyrics,
    this.cheerText,
    this.penlightColors = const [],
    this.timing,
    this.notes,
    this.sortOrder = 0,
  });

  final String id;

  /// EN: Section label e.g. "Verse 1", "Chorus", "Bridge".
  /// KO: 섹션 레이블 예: "버스 1", "코러스", "브릿지".
  final String sectionName;

  /// EN: Type of audience participation for this section.
  /// KO: 이 섹션의 관중 참여 유형.
  final CheerType cheerType;

  /// EN: Original lyrics for this section.
  /// KO: 이 섹션의 원래 가사.
  final String? lyrics;

  /// EN: What the audience should say/do.
  /// KO: 관중이 해야 할 말/동작.
  final String? cheerText;

  /// EN: Penlight hex color codes (e.g. ["#FF6B6B", "#FFD93D"]).
  /// KO: 펜라이트 16진수 색상 코드 (예: ["#FF6B6B", "#FFD93D"]).
  final List<String> penlightColors;

  /// EN: Timing hint (e.g. "0:35 - 1:02").
  /// KO: 타이밍 힌트 (예: "0:35 - 1:02").
  final String? timing;

  /// EN: Additional notes for this section.
  /// KO: 이 섹션에 대한 추가 메모.
  final String? notes;

  /// EN: Sort order within the guide.
  /// KO: 가이드 내 정렬 순서.
  final int sortOrder;
}

/// EN: A complete cheer guide for one song.
/// KO: 한 곡의 완전한 응원 가이드.
class CheerGuide {
  const CheerGuide({
    required this.id,
    required this.songId,
    required this.songTitle,
    required this.sections,
    this.projectId,
    this.artistName,
    this.difficulty,
    this.overallNotes,
    this.lastUpdatedAt,
  });

  final String id;

  /// EN: Associated song ID.
  /// KO: 연관된 곡 ID.
  final String songId;

  /// EN: Song title for display.
  /// KO: 표시용 곡 제목.
  final String songTitle;

  /// EN: Ordered list of cheer sections.
  /// KO: 정렬된 응원 섹션 목록.
  final List<CheerSection> sections;

  /// EN: Project / franchise this guide belongs to.
  /// KO: 이 가이드가 속한 프로젝트/프랜차이즈.
  final String? projectId;

  /// EN: Artist or band name.
  /// KO: 아티스트 또는 밴드 이름.
  final String? artistName;

  /// EN: Difficulty: 1 (easy) – 5 (expert).
  /// KO: 난이도: 1 (쉬움) – 5 (전문가).
  final int? difficulty;

  /// EN: Overall notes displayed at the top of the guide.
  /// KO: 가이드 상단에 표시되는 전체 메모.
  final String? overallNotes;

  /// EN: Timestamp of the last content update.
  /// KO: 마지막 콘텐츠 업데이트 타임스탬프.
  final DateTime? lastUpdatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheerGuide && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// EN: Summary of a cheer guide for list display.
/// KO: 목록 표시용 응원 가이드 요약.
class CheerGuideSummary {
  const CheerGuideSummary({
    required this.id,
    required this.songId,
    required this.songTitle,
    this.projectId,
    this.artistName,
    this.difficulty,
    this.sectionCount = 0,
  });

  final String id;
  final String songId;
  final String songTitle;
  final String? projectId;
  final String? artistName;

  /// EN: Difficulty: 1 (easy) – 5 (expert).
  /// KO: 난이도: 1 (쉬움) – 5 (전문가).
  final int? difficulty;

  /// EN: Total number of sections in the guide.
  /// KO: 가이드의 전체 섹션 수.
  final int sectionCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheerGuideSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
