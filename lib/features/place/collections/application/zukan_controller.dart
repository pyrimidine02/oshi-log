/// EN: Riverpod providers for zukan collections.
/// KO: 도감 컬렉션을 위한 Riverpod 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/features/place/collections/data/datasources/zukan_remote_data_source.dart';
import 'package:oshi_log/features/place/collections/data/repositories/zukan_repository_impl.dart';
import 'package:oshi_log/features/place/collections/domain/entities/zukan_collection.dart';
import 'package:oshi_log/features/place/collections/domain/repositories/zukan_repository.dart';

/// EN: Provides the [ZukanRepository] backed by the remote data source.
/// KO: 원격 데이터 소스를 사용하는 [ZukanRepository]를 제공합니다.
final zukanRepositoryProvider = Provider<ZukanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ZukanRepositoryImpl(
    remoteDataSource: ZukanRemoteDataSource(apiClient: apiClient),
  );
});

/// EN: Fetches the summary list of zukan collections, scoped to [projectId].
/// KO: [projectId]로 범위가 제한된 도감 컬렉션 요약 목록을 가져옵니다.
final zukanCollectionsProvider = FutureProvider.autoDispose
    .family<List<ZukanCollectionSummary>, String?>((ref, projectId) async {
      final repo = ref.watch(zukanRepositoryProvider);
      final result = await repo.fetchCollections(projectId: projectId);
      return result.when(
        success: (list) => list,
        failure: (f) {
          // EN: 404 means no collections yet — return empty list, not an error.
          // KO: 404는 아직 도감이 없는 것이므로 에러가 아닌 빈 목록으로 반환합니다.
          if (f is NotFoundFailure) return const <ZukanCollectionSummary>[];
          throw f;
        },
      );
    });

/// EN: Fetches the full detail of a single zukan collection by [collectionId].
/// KO: [collectionId]로 단일 도감 컬렉션의 전체 상세 정보를 가져옵니다.
final zukanCollectionDetailProvider = FutureProvider.autoDispose
    .family<ZukanCollection?, String>((ref, collectionId) async {
      final repo = ref.watch(zukanRepositoryProvider);
      final result = await repo.fetchCollectionDetail(collectionId);
      return result.when(
        success: (c) => c,
        failure: (f) {
          // EN: 404 means this collection doesn't exist — return null for empty state.
          // KO: 404는 해당 도감이 없는 것이므로 빈 상태용 null을 반환합니다.
          if (f is NotFoundFailure) return null;
          throw f;
        },
      );
    });
