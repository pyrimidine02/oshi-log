/// EN: Home summary domain entities.
/// KO: 홈 요약 도메인 엔티티.
library;

class HomeSummary {
  const HomeSummary({
    required this.recommendedPlaces,
    required this.trendingLiveEvents,
    required this.latestNews,
    required this.metadata,
  });

  final List<HomePlaceItem> recommendedPlaces;
  final List<HomeEventItem> trendingLiveEvents;
  final List<HomeNewsItem> latestNews;
  final HomeSummaryMetadata metadata;

  bool get isEmpty =>
      recommendedPlaces.isEmpty &&
      trendingLiveEvents.isEmpty &&
      latestNews.isEmpty;

  /// EN: Show hard empty only when both cards and source rows are all empty.
  /// KO: 카드/원천 데이터가 모두 없을 때만 완전 빈 상태를 노출합니다.
  bool get shouldShowNoContentEmptyState =>
      isEmpty && metadata.sourceCounts.isAllZero;

  /// EN: Show soft empty when cards are empty but source rows exist.
  /// KO: 카드가 비어도 원천 데이터가 있으면 소프트 빈 상태를 노출합니다.
  bool get shouldShowFilteredEmptyState =>
      isEmpty && !metadata.sourceCounts.isAllZero;
}

class HomeSummaryByProjectItem {
  const HomeSummaryByProjectItem({
    required this.projectId,
    required this.projectCode,
    required this.summary,
  });

  final String projectId;
  final String projectCode;
  final HomeSummary summary;

  bool matchesProject(String? projectIdentifier) {
    if (projectIdentifier == null || projectIdentifier.isEmpty) {
      return false;
    }
    return projectIdentifier == projectId || projectIdentifier == projectCode;
  }
}

class HomeSummaryMetadata {
  const HomeSummaryMetadata({
    required this.sourceCounts,
    required this.fallbackApplied,
  });

  final HomeSourceCounts sourceCounts;
  final HomeFallbackApplied fallbackApplied;
}

class HomeSourceCounts {
  const HomeSourceCounts({
    required this.places,
    required this.liveEvents,
    required this.news,
  });

  final int places;
  final int liveEvents;
  final int news;

  bool get isAllZero => places == 0 && liveEvents == 0 && news == 0;
}

class HomeFallbackApplied {
  const HomeFallbackApplied({
    required this.recommendedPlaces,
    required this.trendingLiveEvents,
  });

  final bool recommendedPlaces;
  final bool trendingLiveEvents;
}

class HomePlaceItem {
  const HomePlaceItem({
    required this.id,
    required this.name,
    this.visitCount = 0,
    this.imageUrl,
    this.location,
  });

  final String id;
  final String name;
  final int visitCount;
  final String? imageUrl;
  final String? location;
}

class HomeEventItem {
  const HomeEventItem({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.startsAt,
    this.posterUrl,
    this.ticketUrl,
    this.isLive = false,
  });

  final String id;
  final String title;
  final String dateLabel;
  final DateTime startsAt;
  final String? posterUrl;
  final String? ticketUrl;
  final bool isLive;
}

class HomeNewsItem {
  const HomeNewsItem({
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
}
