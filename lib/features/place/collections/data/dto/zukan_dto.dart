/// EN: DTOs for zukan collection API responses.
/// KO: 도감 컬렉션 API 응답의 DTO.
library;

import 'package:oshi_log/features/place/collections/domain/entities/zukan_collection.dart';

/// EN: Data Transfer Object for a single zukan stamp.
/// KO: 단일 도감 스탬프의 데이터 전송 객체.
class ZukanStampDto {
  const ZukanStampDto({
    required this.id,
    required this.placeId,
    required this.placeName,
    this.status,
    this.placeImageUrl,
    this.episodeHint,
    this.visitedAt,
    this.sortOrder = 0,
  });

  factory ZukanStampDto.fromJson(Map<String, dynamic> json) {
    return ZukanStampDto(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? json['place_id'] as String? ?? '',
      placeName:
          json['placeName'] as String? ?? json['place_name'] as String? ?? '',
      status: json['status'] as String?,
      placeImageUrl:
          json['placeImageUrl'] as String? ??
          json['place_image_url'] as String?,
      episodeHint:
          json['episodeHint'] as String? ?? json['episode_hint'] as String?,
      visitedAt: json['visitedAt'] != null
          ? DateTime.tryParse(json['visitedAt'] as String)
          : json['visited_at'] != null
          ? DateTime.tryParse(json['visited_at'] as String)
          : null,
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String placeId;
  final String placeName;
  final String? status;
  final String? placeImageUrl;
  final String? episodeHint;
  final DateTime? visitedAt;
  final int sortOrder;

  /// EN: Converts this DTO to its domain entity.
  /// KO: 이 DTO를 도메인 엔티티로 변환합니다.
  ZukanStamp toEntity() => ZukanStamp(
    id: id,
    placeId: placeId,
    placeName: placeName,
    status: StampStatus.fromString(status),
    placeImageUrl: placeImageUrl,
    episodeHint: episodeHint,
    visitedAt: visitedAt,
    sortOrder: sortOrder,
  );
}

/// EN: Data Transfer Object for a full zukan collection with stamps.
/// KO: 스탬프를 포함한 전체 도감 컬렉션의 데이터 전송 객체.
class ZukanCollectionDto {
  const ZukanCollectionDto({
    required this.id,
    required this.title,
    this.projectId,
    this.description,
    this.coverImageUrl,
    this.rewardBadgeImageUrl,
    this.rewardDescription,
    this.sortOrder = 0,
    this.stamps = const [],
  });

  factory ZukanCollectionDto.fromJson(Map<String, dynamic> json) {
    final stampsJson = json['stamps'] as List<dynamic>? ?? [];
    return ZukanCollectionDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      description: json['description'] as String?,
      coverImageUrl:
          json['coverImageUrl'] as String? ??
          json['cover_image_url'] as String?,
      rewardBadgeImageUrl:
          json['rewardBadgeImageUrl'] as String? ??
          json['reward_badge_image_url'] as String?,
      rewardDescription:
          json['rewardDescription'] as String? ??
          json['reward_description'] as String?,
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
      stamps: stampsJson
          .whereType<Map<String, dynamic>>()
          .map(ZukanStampDto.fromJson)
          .toList(),
    );
  }

  final String id;
  final String title;
  final String? projectId;
  final String? description;
  final String? coverImageUrl;
  final String? rewardBadgeImageUrl;
  final String? rewardDescription;
  final int sortOrder;
  final List<ZukanStampDto> stamps;

  /// EN: Converts this DTO to its domain entity, sorting stamps by [sortOrder].
  /// KO: 이 DTO를 도메인 엔티티로 변환하며, 스탬프를 [sortOrder]로 정렬합니다.
  ZukanCollection toEntity() => ZukanCollection(
    id: id,
    title: title,
    stamps: (stamps.map((s) => s.toEntity()).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))),
    projectId: projectId,
    description: description,
    coverImageUrl: coverImageUrl,
    rewardBadgeImageUrl: rewardBadgeImageUrl,
    rewardDescription: rewardDescription,
    sortOrder: sortOrder,
  );
}

/// EN: Data Transfer Object for a zukan collection summary (list view).
/// KO: 도감 컬렉션 요약의 데이터 전송 객체 (목록 뷰용).
class ZukanCollectionSummaryDto {
  const ZukanCollectionSummaryDto({
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

  factory ZukanCollectionSummaryDto.fromJson(Map<String, dynamic> json) {
    return ZukanCollectionSummaryDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalCount:
          json['totalCount'] as int? ?? json['total_count'] as int? ?? 0,
      stampedCount:
          json['stampedCount'] as int? ?? json['stamped_count'] as int? ?? 0,
      projectId: json['projectId'] as String? ?? json['project_id'] as String?,
      description: json['description'] as String?,
      coverImageUrl:
          json['coverImageUrl'] as String? ??
          json['cover_image_url'] as String?,
      isCompleted:
          json['isCompleted'] as bool? ??
          json['is_completed'] as bool? ??
          false,
      sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
    );
  }

  final String id;
  final String title;
  final int totalCount;
  final int stampedCount;
  final String? projectId;
  final String? description;
  final String? coverImageUrl;
  final bool isCompleted;
  final int sortOrder;

  /// EN: Converts this DTO to its domain entity.
  /// KO: 이 DTO를 도메인 엔티티로 변환합니다.
  ZukanCollectionSummary toEntity() => ZukanCollectionSummary(
    id: id,
    title: title,
    totalCount: totalCount,
    stampedCount: stampedCount,
    projectId: projectId,
    description: description,
    coverImageUrl: coverImageUrl,
    isCompleted: isCompleted,
    sortOrder: sortOrder,
  );
}
