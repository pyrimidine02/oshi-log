import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/platform/constants/api_constants.dart';
import 'package:oshi_log/platform/network/api_client.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/place/places/data/datasources/places_remote_data_source.dart';
import 'package:oshi_log/features/place/places/data/dto/place_stats_dto.dart';
import 'package:oshi_log/features/place/places/data/dto/place_comment_dto.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_comment_entities.dart';

void main() {
  test(
    'Tips call structured server filter endpoints with bounded results',
    () async {
      final api = _MockApiClient();
      final dataSource = PlacesRemoteDataSource(api);
      when(
        () => api.get<List<PlaceCommentDetailDto>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((call) async {
        final decode =
            call.namedArguments[#fromJson]
                as List<PlaceCommentDetailDto> Function(dynamic);
        return Result.success(
          decode({
            'comments': [
              {
                'id': 'c',
                'bodyMarkdown': '入口はこちら',
                'bestRoute': '南口',
                'advice': '通行を妨げない',
                'accessibility': 'MODERATE',
              },
            ],
          }),
        );
      });
      final paths = {
        PlaceTipCategory.access: ApiEndpoints.placeCommentsFilterAccessibility(
          'p',
        ),
        PlaceTipCategory.routes: ApiEndpoints.placeCommentsFilterRoutes('p'),
        PlaceTipCategory.advice: ApiEndpoints.placeCommentsFilterAdvice('p'),
        PlaceTipCategory.pinned: ApiEndpoints.placeCommentsPinned('p'),
      };
      for (final entry in paths.entries) {
        final result = await dataSource.fetchPlaceTips(
          placeId: 'p',
          category: entry.key,
        );
        final comment = result.dataOrNull!.single;
        expect(comment.bestRoute, '南口');
        expect(comment.advice, '通行を妨げない');
        expect(comment.accessibility, 'MODERATE');
        expect(comment.isPreview, isFalse);
        verify(
          () => api.get<List<PlaceCommentDetailDto>>(
            entry.value,
            queryParameters: {
              'page': 0,
              'size': entry.key == PlaceTipCategory.pinned ? 20 : 3,
              'sort': 'createdAt,desc',
            },
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      }
      verifyNoMoreInteractions(api);
    },
  );

  test('fetches exact place stats from one project-scoped endpoint', () async {
    final apiClient = _MockApiClient();
    final dataSource = PlacesRemoteDataSource(apiClient);
    when(
      () =>
          apiClient.get<PlaceStatsDto>(any(), fromJson: any(named: 'fromJson')),
    ).thenAnswer(
      (_) async =>
          const Result.success(PlaceStatsDto(visitCount: 12, favoriteCount: 7)),
    );

    final result = await dataSource.fetchPlaceStats(
      projectId: 'bang-dream',
      placeId: 'place-1',
    );

    expect(result, isA<Success<PlaceStatsDto>>());
    verify(
      () => apiClient.get<PlaceStatsDto>(
        ApiEndpoints.placeStats('bang-dream', 'place-1'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
    verifyNoMoreInteractions(apiClient);
  });
}

class _MockApiClient extends Mock implements ApiClient {}
