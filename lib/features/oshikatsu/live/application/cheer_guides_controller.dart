/// EN: Riverpod providers for the cheer guides feature.
/// KO: 응원 가이드 기능을 위한 Riverpod 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/live/data/datasources/cheer_guides_remote_data_source.dart';
import 'package:oshi_log/features/oshikatsu/live/data/repositories/cheer_guides_repository_impl.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/cheer_guide.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/repositories/cheer_guides_repository.dart';

// ========================================
// EN: Infrastructure providers
// KO: 인프라 프로바이더
// ========================================

/// EN: Provides a fully-wired [CheerGuidesRepository].
/// KO: 완전히 연결된 [CheerGuidesRepository]를 제공합니다.
final cheerGuidesRepositoryProvider = FutureProvider<CheerGuidesRepository>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return CheerGuidesRepositoryImpl(
    remoteDataSource: CheerGuidesRemoteDataSource(apiClient: apiClient),
  );
});

// ========================================
// EN: Feature providers
// KO: 기능 프로바이더
// ========================================

/// EN: Returns the list of [CheerGuideSummary] items, optionally scoped to a
/// project ID. Throws [Failure] so Riverpod surfaces the error state.
/// KO: [CheerGuideSummary] 목록을 반환합니다 (선택적으로 프로젝트 ID로 범위 설정).
/// 오류 상태를 노출하기 위해 [Failure]를 throw합니다.
final cheerGuidesListProvider = FutureProvider.autoDispose
    .family<List<CheerGuideSummary>, String?>((ref, projectId) async {
      final repository = await ref.watch(cheerGuidesRepositoryProvider.future);
      final result = await repository.fetchSummaries(
        projectId: projectId?.isNotEmpty == true ? projectId : null,
      );
      if (result case Success<List<CheerGuideSummary>>(:final data)) {
        return data;
      }
      final failure =
          result.failureOrNull ??
          const UnknownFailure(
            'Unknown cheer guides list provider state',
            code: 'unknown_cheer_guides_list_provider',
          );
      // EN: 404 means no guides exist yet — treat as empty list, not an error.
      // KO: 404는 아직 가이드가 없는 것이므로 에러가 아닌 빈 목록으로 처리합니다.
      if (failure is NotFoundFailure) return const [];
      throw failure;
    });

/// EN: Returns the full [CheerGuide] detail for a given guide ID.
/// Throws [Failure] so Riverpod surfaces the error state.
/// KO: 주어진 가이드 ID의 전체 [CheerGuide] 상세 정보를 반환합니다.
/// 오류 상태를 노출하기 위해 [Failure]를 throw합니다.
final cheerGuideDetailProvider = FutureProvider.autoDispose
    .family<CheerGuide, String>((ref, guideId) async {
      final repository = await ref.watch(cheerGuidesRepositoryProvider.future);
      final result = await repository.fetchGuideDetail(guideId);
      if (result case Success<CheerGuide>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown cheer guide detail provider state',
            code: 'unknown_cheer_guide_detail_provider',
          );
    });
