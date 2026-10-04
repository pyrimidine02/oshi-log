/// EN: Riverpod providers for quote cards.
/// KO: 명대사 카드를 위한 Riverpod 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/oshikatsu/quotes/data/datasources/quotes_remote_data_source.dart';
import 'package:oshi_log/features/oshikatsu/quotes/data/repositories/quotes_repository_impl.dart';
import 'package:oshi_log/features/oshikatsu/quotes/domain/entities/quote_card.dart';
import 'package:oshi_log/features/oshikatsu/quotes/domain/repositories/quotes_repository.dart';

/// EN: Provides the [QuotesRepository] backed by remote API.
/// KO: 원격 API를 기반으로 하는 [QuotesRepository]를 제공합니다.
final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuotesRepositoryImpl(
    remoteDataSource: QuotesRemoteDataSource(apiClient: apiClient),
  );
});

/// EN: Manages quote cards list with like/unlike mutations.
/// KO: 좋아요/취소 변이를 포함한 명대사 카드 목록을 관리합니다.
class QuotesNotifier extends StateNotifier<AsyncValue<List<QuoteCard>>> {
  QuotesNotifier(this._repository, this._projectId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  final QuotesRepository _repository;
  final String? _projectId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    final result = await _repository.fetchQuotes(projectId: _projectId);
    if (!mounted) return;
    state = result.when(
      success: AsyncValue.data,
      failure: (f) {
        // EN: 404 means no quotes exist yet — show empty list, not an error.
        // KO: 404는 아직 명대사가 없는 것이므로 에러가 아닌 빈 목록으로 표시합니다.
        if (f is NotFoundFailure) return const AsyncValue.data(<QuoteCard>[]);
        return AsyncValue.error(f, StackTrace.current);
      },
    );
  }

  /// EN: Re-fetches the full quotes list from the API.
  /// KO: API에서 전체 명대사 목록을 다시 가져옵니다.
  Future<void> refresh() => _load();

  /// EN: Toggles like on a quote with optimistic update.
  /// KO: 낙관적 업데이트로 명대사 좋아요를 토글합니다.
  Future<void> toggleLike(String quoteId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((q) => q.id == quoteId);
    if (index < 0) return;
    final quote = current[index];
    final wasLiked = quote.isLiked;

    // EN: Optimistic update — reflect change immediately in UI.
    // KO: 낙관적 업데이트 — UI에 변경 사항을 즉시 반영합니다.
    final updated = List<QuoteCard>.from(current);
    updated[index] = quote.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? quote.likeCount - 1 : quote.likeCount + 1,
    );
    state = AsyncValue.data(updated);

    final result = wasLiked
        ? await _repository.unlikeQuote(quoteId)
        : await _repository.likeQuote(quoteId);

    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (_) {
        // EN: Roll back on API failure to restore consistent state.
        // KO: API 실패 시 일관된 상태 복원을 위해 롤백합니다.
        final rollback = List<QuoteCard>.from(state.valueOrNull ?? []);
        final rollbackIndex = rollback.indexWhere((q) => q.id == quoteId);
        if (rollbackIndex >= 0) {
          rollback[rollbackIndex] = quote;
          state = AsyncValue.data(rollback);
        }
      },
    );
  }
}

/// EN: Auto-dispose family provider keyed by optional projectId.
/// KO: 선택적 projectId로 키가 지정된 자동 해제 패밀리 프로바이더입니다.
final quotesControllerProvider = StateNotifierProvider.autoDispose
    .family<QuotesNotifier, AsyncValue<List<QuoteCard>>, String?>((
      ref,
      projectId,
    ) {
      final repository = ref.watch(quotesRepositoryProvider);
      return QuotesNotifier(repository, projectId);
    });
