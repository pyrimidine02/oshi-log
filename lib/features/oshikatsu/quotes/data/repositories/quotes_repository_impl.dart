/// EN: Concrete implementation of [QuotesRepository].
/// KO: [QuotesRepository]의 구체적인 구현체.
library;

import 'package:oshi_log/platform/error/error_handler.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/quotes/domain/entities/quote_card.dart';
import 'package:oshi_log/features/oshikatsu/quotes/domain/repositories/quotes_repository.dart';
import 'package:oshi_log/features/oshikatsu/quotes/data/datasources/quotes_remote_data_source.dart';
import 'package:oshi_log/features/oshikatsu/quotes/data/dto/quote_card_dto.dart';

/// EN: Bridges the remote data source to the domain repository contract.
/// KO: 원격 데이터 소스를 도메인 리포지토리 계약에 연결합니다.
class QuotesRepositoryImpl implements QuotesRepository {
  const QuotesRepositoryImpl({required this.remoteDataSource});

  final QuotesRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<QuoteCard>>> fetchQuotes({
    String? projectId,
    String? cursor,
  }) async {
    try {
      final result = await remoteDataSource.fetchQuotes(
        projectId: projectId,
        cursor: cursor,
      );
      if (result case Success<List<QuoteCardDto>>(:final data)) {
        return Result.success(
          data.map((dto) => dto.toEntity()).toList(growable: false),
        );
      }
      if (result case Err<List<QuoteCardDto>>(:final failure)) {
        return Result.failure(failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown quotes list result',
          code: 'unknown_quotes_list',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> likeQuote(String quoteId) async {
    try {
      final result = await remoteDataSource.likeQuote(quoteId);
      if (result case Err<void>(:final failure)) {
        return Result.failure(failure);
      }
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> unlikeQuote(String quoteId) async {
    try {
      final result = await remoteDataSource.unlikeQuote(quoteId);
      if (result case Err<void>(:final failure)) {
        return Result.failure(failure);
      }
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }
}
