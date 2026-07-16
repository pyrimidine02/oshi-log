import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/constants/api_constants.dart';
import 'package:girlsbandtabi_app/core/network/api_client.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/search/data/datasources/search_remote_data_source.dart';
import 'package:girlsbandtabi_app/features/search/data/dto/search_item_dto.dart';

void main() {
  test('sends selected project and unit scope to global search', () async {
    final apiClient = _MockApiClient();
    final dataSource = SearchRemoteDataSource(apiClient);
    when(
      () => apiClient.get<List<SearchItemDto>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const Result.success(<SearchItemDto>[]));

    await dataSource.search(
      query: 'MyGO',
      projectId: 'project-1',
      unitIds: const ['unit-2', 'unit-1'],
    );

    final query =
        verify(
              () => apiClient.get<List<SearchItemDto>>(
                ApiEndpoints.search,
                queryParameters: captureAny(named: 'queryParameters'),
                cancelToken: any(named: 'cancelToken'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(query['projectId'], 'project-1');
    expect(query['unitIds'], 'unit-2,unit-1');
  });
}

class _MockApiClient extends Mock implements ApiClient {}
