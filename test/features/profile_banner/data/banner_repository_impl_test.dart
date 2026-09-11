import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/cache/cache_manager.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/profile_banner/data/datasources/banner_remote_data_source.dart';
import 'package:oshi_log/features/profile_banner/data/dto/banner_dto.dart';
import 'package:oshi_log/features/profile_banner/data/repositories/banner_repository_impl.dart';
import 'package:oshi_log/features/profile_banner/domain/entities/banner_entities.dart';

void main() {
  test('maps cache write failures to a Result failure', () async {
    final remoteDataSource = _MockBannerRemoteDataSource();
    final cacheManager = _MockCacheManager();
    final repository = BannerRepositoryImpl(
      remoteDataSource: remoteDataSource,
      cacheManager: cacheManager,
    );
    const dto = ActiveBannerDto(bannerId: 'banner-1', name: 'Summer trip');

    when(
      () => remoteDataSource.setActiveBanner('banner-1'),
    ).thenAnswer((_) async => const Result.success(dto));
    when(
      () => cacheManager.setJson(any(), any(), ttl: any(named: 'ttl')),
    ).thenAnswer(
      (_) => Future<void>.error(
        const CacheFailure('cache unavailable', code: 'cache_write_failed'),
      ),
    );

    final result = await repository.setActiveBanner('banner-1');

    expect(result, isA<Err<ActiveBanner>>());
    expect(result.failureOrNull, isA<CacheFailure>());
  });
}

class _MockBannerRemoteDataSource extends Mock
    implements BannerRemoteDataSource {}

class _MockCacheManager extends Mock implements CacheManager {}
