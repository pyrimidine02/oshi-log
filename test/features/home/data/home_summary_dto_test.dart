import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/home/data/dto/home_summary_dto.dart';

void main() {
  test('HomeSummaryDto parses swagger keys', () {
    final json = {
      'recommendedPlaces': [
        {
          'id': 'place-1',
          'name': 'Tokyo Dome',
          'thumbnailUrl': 'https://example.com/place.png',
          'location': '도쿄',
          'types': ['VENUE'],
          'latitude': 35.7056,
          'longitude': 139.7519,
        },
      ],
      'trendingLiveEvents': [
        {
          'id': 'event-1',
          'title': 'Live Show',
          'showStartTime': '2026-02-01T00:00:00Z',
          'status': 'UPCOMING',
          'projectIds': ['proj-1'],
          'unitIds': ['unit-1'],
          'banner': {'url': 'https://example.com/live-poster.png'},
        },
      ],
      'latestNews': [
        {
          'id': 'news-1',
          'title': 'News Title',
          'summary': 'summary',
          'imageUrl': 'https://example.com/news.png',
          'publishedAt': '2026-01-28T00:00:00Z',
        },
      ],
      'metadata': {
        'sourceCounts': {'places': 10, 'liveEvents': 4, 'news': 2},
        'fallbackApplied': {
          'recommendedPlaces': true,
          'trendingLiveEvents': false,
        },
      },
    };

    final dto = HomeSummaryDto.fromJson(json);
    expect(dto.recommendedPlaces.length, 1);
    expect(dto.trendingLiveEvents.length, 1);
    expect(dto.latestNews.length, 1);
    expect(
      dto.recommendedPlaces.first.imageUrl,
      'https://example.com/place.png',
    );
    expect(
      dto.trendingLiveEvents.first.bannerUrl,
      'https://example.com/live-poster.png',
    );
    expect(dto.latestNews.first.imageUrl, 'https://example.com/news.png');
    expect(dto.metadata.sourceCounts.places, 10);
    expect(dto.metadata.sourceCounts.liveEvents, 4);
    expect(dto.metadata.sourceCounts.news, 2);
    expect(dto.metadata.fallbackApplied.recommendedPlaces, true);
    expect(dto.metadata.fallbackApplied.trendingLiveEvents, false);
  });

  test('HomeSummaryByProjectItemDto parses project row', () {
    final json = {
      'projectId': '550e8400-e29b-41d4-a716-446655440001',
      'projectCode': 'girls-band-cry',
      'summary': {
        'recommendedPlaces': [],
        'trendingLiveEvents': [],
        'latestNews': [],
        'metadata': {
          'sourceCounts': {'places': 0, 'liveEvents': 0, 'news': 0},
          'fallbackApplied': {
            'recommendedPlaces': false,
            'trendingLiveEvents': true,
          },
        },
      },
    };

    final dto = HomeSummaryByProjectItemDto.fromJson(json);
    expect(dto.projectId, '550e8400-e29b-41d4-a716-446655440001');
    expect(dto.projectCode, 'girls-band-cry');
    expect(dto.summary.metadata.fallbackApplied.trendingLiveEvents, true);
  });
}
