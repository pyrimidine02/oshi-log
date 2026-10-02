/// EN: Concrete implementation of [ZukanRepository].
/// KO: [ZukanRepository]의 구체적인 구현체.
library;

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/place/collections/domain/entities/zukan_collection.dart';
import 'package:oshi_log/features/place/collections/domain/repositories/zukan_repository.dart';
import 'package:oshi_log/features/place/collections/data/datasources/zukan_remote_data_source.dart';

/// EN: Repository implementation that delegates to [ZukanRemoteDataSource].
/// KO: [ZukanRemoteDataSource]에 위임하는 리포지토리 구현체.
class ZukanRepositoryImpl implements ZukanRepository {
  const ZukanRepositoryImpl({required this.remoteDataSource});

  final ZukanRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<ZukanCollectionSummary>>> fetchCollections({
    String? projectId,
  }) async {
    final result = await remoteDataSource.fetchCollections(
      projectId: projectId,
    );
    return result.map((dtos) {
      final entities = dtos.map((d) => d.toEntity()).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return entities;
    });
  }

  @override
  Future<Result<ZukanCollection>> fetchCollectionDetail(
    String collectionId,
  ) async {
    final result = await remoteDataSource.fetchCollectionDetail(collectionId);
    return result.map((dto) => dto.toEntity());
  }
}
