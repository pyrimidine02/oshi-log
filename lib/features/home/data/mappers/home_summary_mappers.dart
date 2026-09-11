/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import 'package:intl/intl.dart';
import '../../../../core/utils/media_url.dart';
import '../dto/home_summary_dto.dart';
import '../../domain/entities/home_summary.dart';

extension HomeSummaryDtoDomainMapper on HomeSummaryDto {
  HomeSummary toDomain() {
    final dto = this;

    return HomeSummary(
      recommendedPlaces: List.unmodifiable(
        dto.recommendedPlaces.map((item) => item.toDomain()).toList(),
      ),
      trendingLiveEvents: List.unmodifiable(
        dto.trendingLiveEvents.map((item) => item.toDomain()).toList(),
      ),
      latestNews: List.unmodifiable(
        dto.latestNews.map((item) => item.toDomain()).toList(),
      ),
      metadata: dto.metadata.toDomain(),
    );
  }
}

extension HomeSummaryByProjectItemDtoDomainMapper
    on HomeSummaryByProjectItemDto {
  HomeSummaryByProjectItem toDomain() {
    final dto = this;

    return HomeSummaryByProjectItem(
      projectId: dto.projectId,
      projectCode: dto.projectCode,
      summary: dto.summary.toDomain(),
    );
  }
}

extension HomeSummaryMetadataDtoDomainMapper on HomeSummaryMetadataDto {
  HomeSummaryMetadata toDomain() {
    final dto = this;

    return HomeSummaryMetadata(
      sourceCounts: dto.sourceCounts.toDomain(),
      fallbackApplied: dto.fallbackApplied.toDomain(),
    );
  }
}

extension HomeSourceCountsDtoDomainMapper on HomeSourceCountsDto {
  HomeSourceCounts toDomain() {
    final dto = this;

    return HomeSourceCounts(
      places: dto.places,
      liveEvents: dto.liveEvents,
      news: dto.news,
    );
  }
}

extension HomeFallbackAppliedDtoDomainMapper on HomeFallbackAppliedDto {
  HomeFallbackApplied toDomain() {
    final dto = this;

    return HomeFallbackApplied(
      recommendedPlaces: dto.recommendedPlaces,
      trendingLiveEvents: dto.trendingLiveEvents,
    );
  }
}

extension HomeRecommendedPlaceDtoDomainMapper on HomeRecommendedPlaceDto {
  HomePlaceItem toDomain() {
    final dto = this;

    return HomePlaceItem(
      id: dto.id,
      name: dto.name,
      visitCount: dto.count,
      imageUrl: dto.imageUrl == null ? null : resolveMediaUrl(dto.imageUrl!),
      location: dto.location,
    );
  }
}

extension HomeTrendingLiveEventDtoDomainMapper on HomeTrendingLiveEventDto {
  HomeEventItem toDomain() {
    final dto = this;

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

extension HomeLatestNewsDtoDomainMapper on HomeLatestNewsDto {
  HomeNewsItem toDomain() {
    final dto = this;

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
