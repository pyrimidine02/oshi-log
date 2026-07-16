/// EN: Home summary domain entities.
/// KO: 홈 요약 도메인 엔티티.
library;

import 'package:intl/intl.dart';

import '../../../../core/utils/media_url.dart';
import '../../data/dto/home_summary_dto.dart';

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

  factory HomeSummary.fromDto(HomeSummaryDto dto) {
    return HomeSummary(
      recommendedPlaces: dto.recommendedPlaces
          .map((item) => HomePlaceItem.fromDto(item))
          .toList(),
      trendingLiveEvents: dto.trendingLiveEvents
          .map((item) => HomeEventItem.fromDto(item))
          .toList(),
      latestNews: dto.latestNews
          .map((item) => HomeNewsItem.fromDto(item))
          .toList(),
      metadata: HomeSummaryMetadata.fromDto(dto.metadata),
    );
  }
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

  factory HomeSummaryByProjectItem.fromDto(HomeSummaryByProjectItemDto dto) {
    return HomeSummaryByProjectItem(
      projectId: dto.projectId,
      projectCode: dto.projectCode,
      summary: HomeSummary.fromDto(dto.summary),
    );
  }
}

class HomeSummaryMetadata {
  const HomeSummaryMetadata({
    required this.sourceCounts,
    required this.fallbackApplied,
  });

  final HomeSourceCounts sourceCounts;
  final HomeFallbackApplied fallbackApplied;

  factory HomeSummaryMetadata.fromDto(HomeSummaryMetadataDto dto) {
    return HomeSummaryMetadata(
      sourceCounts: HomeSourceCounts.fromDto(dto.sourceCounts),
      fallbackApplied: HomeFallbackApplied.fromDto(dto.fallbackApplied),
    );
  }
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

  factory HomeSourceCounts.fromDto(HomeSourceCountsDto dto) {
    return HomeSourceCounts(
      places: dto.places,
      liveEvents: dto.liveEvents,
      news: dto.news,
    );
  }
}

class HomeFallbackApplied {
  const HomeFallbackApplied({
    required this.recommendedPlaces,
    required this.trendingLiveEvents,
  });

  final bool recommendedPlaces;
  final bool trendingLiveEvents;

  factory HomeFallbackApplied.fromDto(HomeFallbackAppliedDto dto) {
    return HomeFallbackApplied(
      recommendedPlaces: dto.recommendedPlaces,
      trendingLiveEvents: dto.trendingLiveEvents,
    );
  }
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

  factory HomePlaceItem.fromDto(HomeRecommendedPlaceDto dto) {
    return HomePlaceItem(
      id: dto.id,
      name: dto.name,
      visitCount: dto.count,
      imageUrl: dto.imageUrl == null ? null : resolveMediaUrl(dto.imageUrl!),
      location: dto.location,
    );
  }
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

  factory HomeEventItem.fromDto(HomeTrendingLiveEventDto dto) {
    return HomeEventItem(
      id: dto.id,
      title: dto.title,
      dateLabel: _formatDate(dto.showStartTime),
      startsAt: dto.showStartTime,
      posterUrl: dto.bannerUrl == null ? null : resolveMediaUrl(dto.bannerUrl!),
      ticketUrl: dto.ticketUrl,
      isLive: false,
    );
  }
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

  factory HomeNewsItem.fromDto(HomeLatestNewsDto dto) {
    return HomeNewsItem(
      id: dto.id,
      title: dto.title,
      summary: dto.summary,
      imageUrl: dto.imageUrl == null ? null : resolveMediaUrl(dto.imageUrl!),
      publishedAt: dto.publishedAt,
    );
  }
}

String _formatDate(DateTime dateTime) {
  return DateFormat('M월 d일').format(dateTime.toLocal());
}
