/// EN: Concrete implementation of [FanLevelRepository] backed by the remote API.
/// KO: 원격 API를 기반으로 한 [FanLevelRepository]의 구체적인 구현체.
library;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/fan_level.dart';
import '../../domain/repositories/fan_level_repository.dart';
import '../datasources/fan_level_remote_data_source.dart';

/// EN: Implementation of [FanLevelRepository] that delegates all network calls
///     to [FanLevelRemoteDataSource] and maps responses to domain entities.
/// KO: 모든 네트워크 호출을 [FanLevelRemoteDataSource]에 위임하고
///     응답을 도메인 엔티티로 매핑하는 [FanLevelRepository] 구현체.
class FanLevelRepositoryImpl implements FanLevelRepository {
  const FanLevelRepositoryImpl({
    required FanLevelRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final FanLevelRemoteDataSource _remoteDataSource;

  @override
  Future<Result<FanLevelProfile>> fetchProfile() async {
    try {
      final result = await _remoteDataSource.fetchProfile();
      return switch (result) {
        Success(:final data) => Result.success(data.toEntity()),
        Err(:final failure) => Result.failure(failure),
      };
    } on Failure catch (f) {
      return Result.failure(f);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<CheckInResult>> checkIn() async {
    try {
      final result = await _remoteDataSource.checkIn();
      return switch (result) {
        Success(:final data) => Result.success(data.toEntity()),
        Err(:final failure) => Result.failure(failure),
      };
    } on Failure catch (f) {
      return Result.failure(f);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }
}
