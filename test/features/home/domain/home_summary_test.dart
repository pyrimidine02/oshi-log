import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/home/data/dto/home_summary_dto.dart';
import 'package:oshi_log/features/home/domain/entities/home_summary.dart';

void main() {
  group('HomeSummary empty-state policy', () {
    test('shows hard empty when both cards and source counts are empty', () {
      const dto = HomeSummaryDto(
        recommendedPlaces: [],
        trendingLiveEvents: [],
        latestNews: [],
        metadata: HomeSummaryMetadataDto(
          sourceCounts: HomeSourceCountsDto(places: 0, liveEvents: 0, news: 0),
        ),
      );

      final summary = HomeSummary.fromDto(dto);

      expect(summary.isEmpty, true);
      expect(summary.shouldShowNoContentEmptyState, true);
      expect(summary.shouldShowFilteredEmptyState, false);
    });

    test('shows soft empty when cards are empty but source counts exist', () {
      const dto = HomeSummaryDto(
        recommendedPlaces: [],
        trendingLiveEvents: [],
        latestNews: [],
        metadata: HomeSummaryMetadataDto(
          sourceCounts: HomeSourceCountsDto(places: 12, liveEvents: 0, news: 0),
        ),
      );

      final summary = HomeSummary.fromDto(dto);

      expect(summary.isEmpty, true);
      expect(summary.shouldShowNoContentEmptyState, false);
      expect(summary.shouldShowFilteredEmptyState, true);
    });
  });

  test('HomeSummaryByProjectItem matches code and id', () {
    final item = HomeSummaryByProjectItem.fromDto(
      const HomeSummaryByProjectItemDto(
        projectId: '550e8400-e29b-41d4-a716-446655440001',
        projectCode: 'girls-band-cry',
        summary: HomeSummaryDto(
          recommendedPlaces: [],
          trendingLiveEvents: [],
          latestNews: [],
        ),
      ),
    );

    expect(item.matchesProject('550e8400-e29b-41d4-a716-446655440001'), true);
    expect(item.matchesProject('girls-band-cry'), true);
    expect(item.matchesProject('bang-dream'), false);
  });
}
