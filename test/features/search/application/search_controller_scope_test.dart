import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/search/application/search_controller.dart';
import 'package:oshi_log/features/search/domain/entities/search_entities.dart';
import 'package:oshi_log/features/search/domain/repositories/search_repository.dart';

void main() {
  test('forwards the active project and unit lens to the repository', () async {
    final repository = _RecordingSearchRepository();
    final container = ProviderContainer(
      overrides: [
        selectedProjectIdProvider.overrideWith((ref) => 'project-1'),
        selectedUnitIdsProvider.overrideWith(
          (ref) => const ['unit-2', 'unit-1'],
        ),
        searchRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(searchControllerProvider.notifier).search('  MyGO  ');

    expect(repository.query, 'MyGO');
    expect(repository.projectId, 'project-1');
    expect(repository.unitIds, const ['unit-2', 'unit-1']);
  });
}

class _RecordingSearchRepository implements SearchRepository {
  String? query;
  String? projectId;
  List<String> unitIds = const [];

  @override
  Future<Result<List<SearchItem>>> search({
    required String query,
    List<String> types = const [],
    String? projectId,
    List<String> unitIds = const [],
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    this.query = query;
    this.projectId = projectId;
    this.unitIds = List<String>.unmodifiable(unitIds);
    return const Result.success(<SearchItem>[]);
  }

  @override
  void cancelInFlightSearch() {}

  @override
  Future<Result<SearchCategoryDiscovery>> getCategoryDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<SearchPopularDiscovery>> getPopularDiscovery({
    int limit = 10,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }
}
