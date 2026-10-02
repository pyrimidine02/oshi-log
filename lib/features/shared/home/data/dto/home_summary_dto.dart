/// EN: Home summary DTO aligned with server response schema.
/// KO: 서버 응답 스키마에 맞춘 홈 요약 DTO.
library;

/// EN: Per-project payload from /api/v1/home/summary/by-project.
/// KO: /api/v1/home/summary/by-project 의 프로젝트별 payload 입니다.
class HomeSummaryByProjectItemDto {
  const HomeSummaryByProjectItemDto({
    required this.projectId,
    required this.projectCode,
    required this.summary,
  });

  final String projectId;
  final String projectCode;
  final HomeSummaryDto summary;

  factory HomeSummaryByProjectItemDto.fromJson(Map<String, dynamic> json) {
    return HomeSummaryByProjectItemDto(
      projectId: json['projectId'] as String? ?? '',
      projectCode: json['projectCode'] as String? ?? '',
      summary: HomeSummaryDto.fromJson(_map(json['summary'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectCode': projectCode,
      'summary': summary.toJson(),
    };
  }

  HomeSummaryByProjectItemDto copyWith({
    String? projectId,
    String? projectCode,
    HomeSummaryDto? summary,
  }) {
    return HomeSummaryByProjectItemDto(
      projectId: projectId ?? this.projectId,
      projectCode: projectCode ?? this.projectCode,
      summary: summary ?? this.summary,
    );
  }
}

/// EN: Home summary returned from /api/v1/home/summary.
/// KO: /api/v1/home/summary 에서 반환되는 홈 요약입니다.
///
/// EN: The server returns lightweight summary items (not full detail DTOs).
/// KO: 서버는 경량 요약 항목을 반환합니다(상세 DTO 아님).
class HomeSummaryDto {
  const HomeSummaryDto({
    required this.recommendedPlaces,
    required this.trendingLiveEvents,
    required this.latestNews,
    this.metadata = const HomeSummaryMetadataDto(),
  });

  final List<HomeRecommendedPlaceDto> recommendedPlaces;
  final List<HomeTrendingLiveEventDto> trendingLiveEvents;
  final List<HomeLatestNewsDto> latestNews;
  final HomeSummaryMetadataDto metadata;

  factory HomeSummaryDto.fromJson(Map<String, dynamic> json) {
    return HomeSummaryDto(
      recommendedPlaces: _parseList(
        json['recommendedPlaces'],
        HomeRecommendedPlaceDto.fromJson,
      ),
      trendingLiveEvents: _parseList(
        json['trendingLiveEvents'],
        HomeTrendingLiveEventDto.fromJson,
      ),
      latestNews: _parseList(json['latestNews'], HomeLatestNewsDto.fromJson),
      metadata: HomeSummaryMetadataDto.fromJson(_map(json['metadata'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendedPlaces': recommendedPlaces.map((e) => e.toJson()).toList(),
      'trendingLiveEvents': trendingLiveEvents.map((e) => e.toJson()).toList(),
      'latestNews': latestNews.map((e) => e.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }

  HomeSummaryDto copyWith({
    List<HomeRecommendedPlaceDto>? recommendedPlaces,
    List<HomeTrendingLiveEventDto>? trendingLiveEvents,
    List<HomeLatestNewsDto>? latestNews,
    HomeSummaryMetadataDto? metadata,
  }) {
    return HomeSummaryDto(
      recommendedPlaces: recommendedPlaces ?? this.recommendedPlaces,
      trendingLiveEvents: trendingLiveEvents ?? this.trendingLiveEvents,
      latestNews: latestNews ?? this.latestNews,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// EN: Metadata for source diagnostics and fallback visibility.
/// KO: 원천 데이터 진단과 폴백 여부를 위한 메타데이터입니다.
class HomeSummaryMetadataDto {
  const HomeSummaryMetadataDto({
    this.sourceCounts = const HomeSourceCountsDto(),
    this.fallbackApplied = const HomeFallbackAppliedDto(),
  });

  final HomeSourceCountsDto sourceCounts;
  final HomeFallbackAppliedDto fallbackApplied;

  factory HomeSummaryMetadataDto.fromJson(Map<String, dynamic> json) {
    return HomeSummaryMetadataDto(
      sourceCounts: HomeSourceCountsDto.fromJson(_map(json['sourceCounts'])),
      fallbackApplied: HomeFallbackAppliedDto.fromJson(
        _map(json['fallbackApplied']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceCounts': sourceCounts.toJson(),
      'fallbackApplied': fallbackApplied.toJson(),
    };
  }
}

/// EN: Server-reported source counts for home sections.
/// KO: 홈 섹션별 서버 원천 데이터 개수입니다.
class HomeSourceCountsDto {
  const HomeSourceCountsDto({
    this.places = 0,
    this.liveEvents = 0,
    this.news = 0,
  });

  final int places;
  final int liveEvents;
  final int news;

  factory HomeSourceCountsDto.fromJson(Map<String, dynamic> json) {
    return HomeSourceCountsDto(
      places: _int(json['places']),
      liveEvents: _int(json['liveEvents'] ?? json['live_events']),
      news: _int(json['news']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'places': places, 'liveEvents': liveEvents, 'news': news};
  }
}

/// EN: Flags that indicate whether server fallback logic was used.
/// KO: 서버 폴백 로직 사용 여부를 나타내는 플래그입니다.
class HomeFallbackAppliedDto {
  const HomeFallbackAppliedDto({
    this.recommendedPlaces = false,
    this.trendingLiveEvents = false,
  });

  final bool recommendedPlaces;
  final bool trendingLiveEvents;

  factory HomeFallbackAppliedDto.fromJson(Map<String, dynamic> json) {
    return HomeFallbackAppliedDto(
      recommendedPlaces: _bool(
        json['recommendedPlaces'] ?? json['recommended_places'],
      ),
      trendingLiveEvents: _bool(
        json['trendingLiveEvents'] ?? json['trending_live_events'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendedPlaces': recommendedPlaces,
      'trendingLiveEvents': trendingLiveEvents,
    };
  }
}

// ========================================
// EN: Recommended Place (lightweight)
// KO: 추천 장소 (경량)
// ========================================

/// EN: Lightweight place item returned by the home summary endpoint.
/// KO: 홈 요약 엔드포인트에서 반환되는 경량 장소 항목.
class HomeRecommendedPlaceDto {
  const HomeRecommendedPlaceDto({
    required this.id,
    required this.name,
    required this.count,
    this.location,
    this.imageUrl,
  });

  final String id;
  final String name;
  final int count;
  final String? location;
  final String? imageUrl;

  factory HomeRecommendedPlaceDto.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = _firstNonEmptyString([
      json['imageUrl'],
      json['image_url'],
      json['thumbnailUrl'],
      json['thumbnail_url'],
      json['posterUrl'],
      _nestedString(json['image'], 'url'),
      _nestedString(json['thumbnail'], 'url'),
    ]);

    return HomeRecommendedPlaceDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      count: _int(json['count']),
      location: _firstNonEmptyString([
        json['location'],
        json['address'],
        json['regionName'],
      ]),
      imageUrl: rawImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      if (location != null) 'location': location,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

// ========================================
// EN: Trending Live Event (lightweight)
// KO: 트렌딩 라이브 이벤트 (경량)
// ========================================

/// EN: Lightweight live event item from the home summary endpoint.
/// KO: 홈 요약 엔드포인트에서 반환되는 경량 라이브 이벤트 항목.
class HomeTrendingLiveEventDto {
  const HomeTrendingLiveEventDto({
    required this.id,
    required this.title,
    required this.startTime,
    required this.showStartTime,
    required this.projectIds,
    this.doorsOpenTime,
    this.ticketUrl,
    this.bannerUrl,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime showStartTime;
  final DateTime? doorsOpenTime;
  final String? ticketUrl;
  final List<String> projectIds;

  // EN: Poster/banner image URL.
  // KO: 포스터/배너 이미지 URL.
  final String? bannerUrl;

  factory HomeTrendingLiveEventDto.fromJson(Map<String, dynamic> json) {
    final startTimeRaw = _firstNonEmptyString([
      json['startTime'],
      json['start_time'],
      json['showStartTime'],
      json['show_start_time'],
    ]);
    final showStartTimeRaw = _firstNonEmptyString([
      json['showStartTime'],
      json['show_start_time'],
      json['startTime'],
      json['start_time'],
    ]);

    final rawBannerUrl = _firstNonEmptyString([
      json['bannerUrl'],
      json['banner_url'],
      json['posterUrl'],
      json['poster_url'],
      json['posterImageUrl'],
      json['poster_image_url'],
      json['coverImageUrl'],
      json['cover_image_url'],
      json['imageUrl'],
      json['image_url'],
      json['thumbnailUrl'],
      json['thumbnail_url'],
      _nestedString(json['banner'], 'url'),
      _nestedString(json['banner'], 'publicUrl'),
      _nestedString(json['banner'], 'fileUrl'),
      _nestedString(json['poster'], 'url'),
      _nestedString(json['thumbnail'], 'url'),
      _nestedString(json['image'], 'url'),
      _nestedPathString(json, ['banner', 'file', 'url']),
      _nestedPathString(json, ['banner', 'file', 'publicUrl']),
      _nestedPathString(json, ['poster', 'file', 'url']),
      _nestedPathString(json, ['poster', 'file', 'publicUrl']),
    ]);

    return HomeTrendingLiveEventDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: _dateTime(startTimeRaw),
      showStartTime: _dateTime(showStartTimeRaw),
      doorsOpenTime: _dateTimeOrNull(json['doorsOpenTime']),
      ticketUrl: _string(json['ticketUrl']),
      projectIds: _stringList(json['projectIds']),
      bannerUrl: rawBannerUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'showStartTime': showStartTime.toIso8601String(),
      'doorsOpenTime': doorsOpenTime?.toIso8601String(),
      'ticketUrl': ticketUrl,
      'projectIds': projectIds,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
    };
  }

  HomeTrendingLiveEventDto copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? showStartTime,
    DateTime? doorsOpenTime,
    String? ticketUrl,
    List<String>? projectIds,
    String? bannerUrl,
  }) {
    return HomeTrendingLiveEventDto(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      showStartTime: showStartTime ?? this.showStartTime,
      doorsOpenTime: doorsOpenTime ?? this.doorsOpenTime,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      projectIds: projectIds ?? this.projectIds,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }
}

// ========================================
// EN: Latest News (lightweight)
// KO: 최신 소식 (경량)
// ========================================

/// EN: Lightweight news item from the home summary endpoint.
/// KO: 홈 요약 엔드포인트에서 반환되는 경량 뉴스 항목.
class HomeLatestNewsDto {
  const HomeLatestNewsDto({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final DateTime? publishedAt;

  factory HomeLatestNewsDto.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = _firstNonEmptyString([
      json['imageUrl'],
      json['image_url'],
      json['thumbnailUrl'],
      json['thumbnail_url'],
      json['coverImageUrl'],
      _nestedString(json['image'], 'url'),
      _nestedString(json['thumbnail'], 'url'),
    ]);

    return HomeLatestNewsDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: _firstNonEmptyString([
        json['summary'],
        json['description'],
        json['excerpt'],
      ]),
      imageUrl: rawImageUrl,
      publishedAt: _dateTimeOrNull(json['publishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (summary != null) 'summary': summary,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    };
  }
}

// ========================================
// EN: Parsing helpers
// KO: 파싱 헬퍼
// ========================================

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
  if (raw is! List) return <T>[];
  return raw.whereType<Map<String, dynamic>>().map(parser).toList();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return const <String, dynamic>{};
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _bool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

DateTime _dateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return <String>[];
}

String? _string(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final value = _string(candidate);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _nestedString(dynamic raw, String key) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  return _string(raw[key]);
}

String? _nestedPathString(Map<String, dynamic> raw, List<String> path) {
  dynamic current = raw;
  for (final key in path) {
    if (current is! Map<String, dynamic>) {
      return null;
    }
    current = current[key];
  }
  return _string(current);
}
