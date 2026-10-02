/// EN: DTOs for cheer guide API responses.
/// KO: 응원 가이드 API 응답의 DTO.
library;

import '../../domain/entities/cheer_guide.dart';

/// EN: DTO for a single cheer section returned by the API.
/// KO: API가 반환하는 단일 응원 섹션 DTO.
class CheerSectionDto {
  const CheerSectionDto({
    required this.id,
    required this.sectionName,
    this.cheerType,
    this.lyrics,
    this.cheerText,
    this.penlightColors = const [],
    this.timing,
    this.notes,
    this.sortOrder = 0,
  });

  factory CheerSectionDto.fromJson(Map<String, dynamic> json) {
    final rawColors =
        json['penlightColors'] as List<dynamic>? ??
        json['penlight_colors'] as List<dynamic>? ??
        const [];
    return CheerSectionDto(
      id: json['id'] as String? ?? '',
      sectionName:
          json['sectionName'] as String? ??
          json['section_name'] as String? ??
          '',
      cheerType: json['cheerType'] as String? ?? json['cheer_type'] as String?,
      lyrics: json['lyrics'] as String?,
      cheerText: json['cheerText'] as String? ?? json['cheer_text'] as String?,
      penlightColors: rawColors.whereType<String>().toList(growable: false),
      timing: json['timing'] as String?,
      notes: json['notes'] as String?,
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String sectionName;
  final String? cheerType;
  final String? lyrics;
  final String? cheerText;
  final List<String> penlightColors;
  final String? timing;
  final String? notes;
  final int sortOrder;

  /// EN: Convert DTO to domain [CheerSection] entity.
  /// KO: DTO를 도메인 [CheerSection] 엔티티로 변환합니다.
  CheerSection toEntity() => CheerSection(
    id: id,
    sectionName: sectionName,
    cheerType: CheerType.fromString(cheerType),
    lyrics: lyrics,
    cheerText: cheerText,
    penlightColors: penlightColors,
    timing: timing,
    notes: notes,
    sortOrder: sortOrder,
  );
}

/// EN: DTO for a full cheer guide returned by the API.
/// KO: API가 반환하는 전체 응원 가이드 DTO.
class CheerGuideDto {
  const CheerGuideDto({
    required this.id,
    required this.songId,
    required this.songTitle,
    this.projectId,
    this.artistName,
    this.difficulty,
    this.overallNotes,
    this.lastUpdatedAt,
    this.sections = const [],
  });

  factory CheerGuideDto.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'] as List<dynamic>? ?? const [];
    return CheerGuideDto(
      id: json['id'] as String? ?? '',
      songId: json['songId'] as String? ?? json['song_id'] as String? ?? '',
      songTitle:
          json['songTitle'] as String? ?? json['song_title'] as String? ?? '',
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      artistName:
          json['artistName'] as String? ?? json['artist_name'] as String?,
      difficulty: _parseDifficulty(json['difficulty']),
      overallNotes:
          json['overallNotes'] as String? ?? json['overall_notes'] as String?,
      lastUpdatedAt: _parseDate(
        json['lastUpdatedAt'] as String? ?? json['last_updated_at'] as String?,
      ),
      sections: sectionsRaw
          .whereType<Map<String, dynamic>>()
          .map(CheerSectionDto.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String songId;
  final String songTitle;
  final String? projectId;
  final String? artistName;
  final int? difficulty;
  final String? overallNotes;
  final DateTime? lastUpdatedAt;
  final List<CheerSectionDto> sections;

  /// EN: Convert DTO to domain [CheerGuide] entity (sections sorted by sortOrder).
  /// KO: DTO를 도메인 [CheerGuide] 엔티티로 변환합니다 (섹션은 sortOrder 기준 정렬).
  CheerGuide toEntity() {
    final sorted = sections.map((s) => s.toEntity()).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CheerGuide(
      id: id,
      songId: songId,
      songTitle: songTitle,
      sections: sorted,
      projectId: projectId,
      artistName: artistName,
      difficulty: difficulty,
      overallNotes: overallNotes,
      lastUpdatedAt: lastUpdatedAt,
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

// EN: Parses difficulty from either a numeric int or a string enum (e.g. "BEGINNER").
// KO: difficulty 값을 int 또는 문자열 열거형("BEGINNER" 등)으로부터 파싱합니다.
int? _parseDifficulty(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is String) {
    return switch (raw.toUpperCase()) {
      'BEGINNER' => 1,
      'INTERMEDIATE' => 2,
      'ADVANCED' => 3,
      _ => null,
    };
  }
  return null;
}

/// EN: DTO for a cheer guide summary item in a list response.
/// KO: 목록 응답의 응원 가이드 요약 항목 DTO.
class CheerGuideSummaryDto {
  const CheerGuideSummaryDto({
    required this.id,
    required this.songId,
    required this.songTitle,
    this.projectId,
    this.artistName,
    this.difficulty,
    this.sectionCount = 0,
  });

  factory CheerGuideSummaryDto.fromJson(Map<String, dynamic> json) {
    return CheerGuideSummaryDto(
      id: json['id'] as String? ?? '',
      songId: json['songId'] as String? ?? json['song_id'] as String? ?? '',
      songTitle:
          json['songTitle'] as String? ?? json['song_title'] as String? ?? '',
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      artistName:
          json['artistName'] as String? ?? json['artist_name'] as String?,
      difficulty: _parseDifficulty(json['difficulty']),
      sectionCount:
          json['sectionCount'] as int? ?? json['section_count'] as int? ?? 0,
    );
  }

  final String id;
  final String songId;
  final String songTitle;
  final String? projectId;
  final String? artistName;
  final int? difficulty;
  final int sectionCount;

  /// EN: Convert DTO to domain [CheerGuideSummary] entity.
  /// KO: DTO를 도메인 [CheerGuideSummary] 엔티티로 변환합니다.
  CheerGuideSummary toEntity() => CheerGuideSummary(
    id: id,
    songId: songId,
    songTitle: songTitle,
    projectId: projectId,
    artistName: artistName,
    difficulty: difficulty,
    sectionCount: sectionCount,
  );
}
