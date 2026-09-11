import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/cache/cache_manager.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/titles/data/datasources/titles_remote_data_source.dart';
import 'package:oshi_log/features/titles/data/dto/title_dto.dart';
import 'package:oshi_log/features/titles/data/repositories/titles_repository_impl.dart';
import 'package:oshi_log/features/titles/domain/entities/title_entities.dart';

void main() {
  test('maps cache write failures to a Result failure', () async {
    final remoteDataSource = _MockTitlesRemoteDataSource();
    final cacheManager = _MockCacheManager();
    final repository = TitlesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      cacheManager: cacheManager,
    );
    const dto = ActiveTitleItemDto(
      titleId: 'title-1',
      code: 'FIRST_TRIP',
      name: 'First trip',
      category: 'ACTIVITY',
    );

    when(
      () => remoteDataSource.setMyActiveTitle('title-1', projectKey: null),
    ).thenAnswer((_) async => const Result.success(dto));
    when(
      () => cacheManager.setJson(any(), any(), ttl: any(named: 'ttl')),
    ).thenAnswer(
      (_) => Future<void>.error(
        const CacheFailure('cache unavailable', code: 'cache_write_failed'),
      ),
    );

    final result = await repository.setMyActiveTitle('title-1');

    expect(result, isA<Err<ActiveTitleItem>>());
    expect(result.failureOrNull, isA<CacheFailure>());
  });
}

class _MockTitlesRemoteDataSource extends Mock
    implements TitlesRemoteDataSource {}

class _MockCacheManager extends Mock implements CacheManager {}
