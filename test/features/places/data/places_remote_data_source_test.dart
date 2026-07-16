import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/constants/api_constants.dart';
import 'package:girlsbandtabi_app/core/network/api_client.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/places/data/datasources/places_remote_data_source.dart';
import 'package:girlsbandtabi_app/features/places/data/dto/place_stats_dto.dart';

void main() {
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
