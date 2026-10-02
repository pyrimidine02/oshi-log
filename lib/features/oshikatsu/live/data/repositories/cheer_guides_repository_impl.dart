/// EN: Concrete implementation of [CheerGuidesRepository].
/// KO: [CheerGuidesRepository]의 구체적인 구현체.
library;

import 'package:oshi_log/core/error/error_handler.dart';
import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/cheer_guide.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/repositories/cheer_guides_repository.dart';
import 'package:oshi_log/features/oshikatsu/live/data/datasources/cheer_guides_remote_data_source.dart';
import 'package:oshi_log/features/oshikatsu/live/data/dto/cheer_guide_dto.dart';

/// EN: Implements [CheerGuidesRepository] using a remote data source.
/// KO: 원격 데이터 소스를 사용하는 [CheerGuidesRepository] 구현체입니다.
class CheerGuidesRepositoryImpl implements CheerGuidesRepository {
  const CheerGuidesRepositoryImpl({required this.remoteDataSource});

  final CheerGuidesRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<CheerGuideSummary>>> fetchSummaries({
    String? projectId,
  }) async {
    try {
      final result = await remoteDataSource.fetchSummaries(
        projectId: projectId,
      );
      if (result case Success<List<CheerGuideSummaryDto>>(:final data)) {
        return Result.success(
          data.map((dto) => dto.toEntity()).toList(growable: false),
        );
      }
      if (result case Err<List<CheerGuideSummaryDto>>(:final failure)) {
        return Result.failure(failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown cheer guides list result',
          code: 'unknown_cheer_guides_list',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<CheerGuide>> fetchGuideDetail(String guideId) async {
    try {
      final result = await remoteDataSource.fetchGuideDetail(guideId);
      if (result case Success<CheerGuideDto>(:final data)) {
        return Result.success(data.toEntity());
      }
      if (result case Err<CheerGuideDto>(:final failure)) {
        return Result.failure(failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown cheer guide detail result',
          code: 'unknown_cheer_guide_detail',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }
}
