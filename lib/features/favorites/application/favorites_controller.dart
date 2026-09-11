/// EN: Favorites controller for saved items.
/// KO: 즐겨찾기 컨트롤러.
library;

import 'dart:async' show unawaited;

import '../../../core/connectivity/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/favorites_remote_data_source.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/entities/favorite_entities.dart';
import '../domain/repositories/favorites_repository.dart';
import 'pending_favorite_mutation.dart';

class FavoritesController
    extends StateNotifier<AsyncValue<List<FavoriteItem>>> {
  FavoritesController(this._ref) : super(const AsyncLoading()) {
    _ref.onDispose(() {
      _disposed = true;
    });
    load();
    _ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (
      _,
      next,
    ) {
      if (next.valueOrNull == ConnectivityStatus.online) {
        unawaited(syncPendingMutations());
      }
    });
    _ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (previous != next) {
        _authSessionGeneration += 1;
      }
      if (next && previous != true) {
        unawaited(syncPendingMutations());
      }
      if (!next) {
        state = const AsyncData([]);
      }
    });
    unawaited(syncPendingMutations());
  }

  final Ref _ref;
  bool _isSyncingPending = false;
  bool _disposed = false;
  int _authSessionGeneration = 0;
  static const int _maxPendingMutations = 200;

  Future<void> load({bool forceRefresh = false}) async {
    if (_disposed) {
      return;
    }
    final isAuthenticated = _ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      if (!_disposed) {
        state = const AsyncData([]);
      }
      return;
    }

    final sessionGeneration = _authSessionGeneration;
    state = const AsyncLoading();
    final repository = await _ref.read(favoritesRepositoryProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    final result = await repository.getFavorites(forceRefresh: forceRefresh);

    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    if (result is Success<List<FavoriteItem>>) {
      state = AsyncData(result.data);
    } else if (result is Err<List<FavoriteItem>>) {
      state = AsyncError(result.failure, StackTrace.current);
    }
  }

  Future<Result<void>> toggleFavorite({
    required String entityId,
    required FavoriteType type,
    bool? isCurrentlyFavorite,
  }) async {
    if (_disposed) {
      return const Result.failure(
        AuthFailure(
          'Favorites controller disposed',
          code: 'controller_disposed',
        ),
      );
    }
    final isAuthenticated = _ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      return Result.failure(
        const AuthFailure('Login required', code: 'auth_required'),
      );
    }

    final sessionGeneration = _authSessionGeneration;
    final repository = await _ref.read(favoritesRepositoryProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return const Result.failure(
        AuthFailure(
          'Authentication session changed',
          code: 'auth_session_changed',
        ),
      );
    }
    final currentItems = state.maybeWhen(
      data: (items) => items,
      orElse: () {
        return <FavoriteItem>[];
      },
    );

    final currentlyFavorite =
        isCurrentlyFavorite ??
        currentItems.any(
          (item) => item.entityId == entityId && item.type == type,
        );
    final targetIsFavorite = !currentlyFavorite;
    _applyOptimisticFavoriteToggle(
      entityId: entityId,
      type: type,
      targetIsFavorite: targetIsFavorite,
    );

    final isOnline = await _ref.read(connectivityServiceProvider).isOnline;
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return const Result.failure(
        AuthFailure(
          'Authentication session changed',
          code: 'auth_session_changed',
        ),
      );
    }
    if (!isOnline) {
      await _enqueuePendingMutation(
        entityId: entityId,
        type: type,
        targetIsFavorite: targetIsFavorite,
        sessionGeneration: sessionGeneration,
      );
      return const Result.success(null);
    }

    final result = await _applyRemoteToggle(
      repository: repository,
      entityId: entityId,
      type: type,
      targetIsFavorite: targetIsFavorite,
    );
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return const Result.failure(
        AuthFailure(
          'Authentication session changed',
          code: 'auth_session_changed',
        ),
      );
    }
    if (result is Success<void>) {
      await _dequeuePendingMutation(
        entityId: entityId,
        type: type,
        sessionGeneration: sessionGeneration,
      );
      await load(forceRefresh: true);
      return const Result.success(null);
    }
    if (result is Err<void>) {
      if (_shouldQueueForRetry(result.failure)) {
        await _enqueuePendingMutation(
          entityId: entityId,
          type: type,
          targetIsFavorite: targetIsFavorite,
          sessionGeneration: sessionGeneration,
        );
        return const Result.success(null);
      }
      await load(forceRefresh: true);
      return Result.failure(result.failure);
    }

    return Result.failure(
      const UnknownFailure(
        'Unknown favorite toggle result',
        code: 'unknown_favorite_toggle',
      ),
    );
  }

  Future<void> syncPendingMutations() async {
    if (_disposed) {
      return;
    }
    if (_isSyncingPending) {
      return;
    }
    if (!_ref.read(isAuthenticatedProvider)) {
      return;
    }
    final sessionGeneration = _authSessionGeneration;
    final isOnline = await _ref.read(connectivityServiceProvider).isOnline;
    if (!isOnline || !_isCurrentAuthSession(sessionGeneration)) {
      return;
    }

    _isSyncingPending = true;
    try {
      final pending = await _readPendingMutations();
      if (!_isCurrentAuthSession(sessionGeneration) || pending.isEmpty) {
        return;
      }

      final repository = await _ref.read(favoritesRepositoryProvider.future);
      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      final remaining = <PendingFavoriteMutation>[];
      var appliedCount = 0;

      for (var i = 0; i < pending.length; i += 1) {
        if (!_isCurrentAuthSession(sessionGeneration)) {
          return;
        }
        final mutation = pending[i];
        final result = await _applyRemoteToggle(
          repository: repository,
          entityId: mutation.entityId,
          type: mutation.type,
          targetIsFavorite: mutation.isFavorite,
        );
        if (!_isCurrentAuthSession(sessionGeneration)) {
          return;
        }
        if (result is Success<void>) {
          appliedCount += 1;
          continue;
        }

        if (result is Err<void>) {
          if (_shouldQueueForRetry(result.failure)) {
            remaining.add(mutation);
            remaining.addAll(pending.skip(i + 1));
            break;
          }
          // EN: Drop non-retriable mutation.
          // KO: 재시도 불가 작업은 폐기합니다.
          continue;
        }

        remaining.add(mutation);
      }

      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      await _writePendingMutations(
        remaining,
        sessionGeneration: sessionGeneration,
      );
      if (appliedCount > 0 && _isCurrentAuthSession(sessionGeneration)) {
        await load(forceRefresh: true);
      }
    } finally {
      _isSyncingPending = false;
    }
  }

  bool _isCurrentAuthSession(int generation) {
    return !_disposed &&
        generation == _authSessionGeneration &&
        _ref.read(isAuthenticatedProvider);
  }

  Future<Result<void>> _applyRemoteToggle({
    required FavoritesRepository repository,
    required String entityId,
    required FavoriteType type,
    required bool targetIsFavorite,
  }) async {
    if (targetIsFavorite) {
      final result = await repository.addFavorite(
        entityId: entityId,
        type: type,
      );
      if (result is Success<FavoriteItem>) {
        return const Result.success(null);
      }
      if (result is Err<FavoriteItem>) {
        return Result.failure(result.failure);
      }
      return const Result.failure(
        UnknownFailure(
          'Unknown add favorite toggle result',
          code: 'unknown_add_favorite_toggle',
        ),
      );
    }

    return repository.removeFavorite(entityId: entityId, type: type);
  }

  void _applyOptimisticFavoriteToggle({
    required String entityId,
    required FavoriteType type,
    required bool targetIsFavorite,
  }) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final exists = current.any(
      (item) => item.entityId == entityId && item.type == type,
    );
    if (targetIsFavorite) {
      if (exists) {
        return;
      }
      state = AsyncData([
        FavoriteItem(entityId: entityId, type: type),
        ...current,
      ]);
      return;
    }

    if (!exists) {
      return;
    }
    state = AsyncData(
      current
          .where((item) => !(item.entityId == entityId && item.type == type))
          .toList(growable: false),
    );
  }

  bool _shouldQueueForRetry(Failure failure) {
    return failure is NetworkFailure || failure is AuthFailure;
  }

  Future<void> _enqueuePendingMutation({
    required String entityId,
    required FavoriteType type,
    required bool targetIsFavorite,
    required int sessionGeneration,
  }) async {
    final pending = await _readPendingMutations();
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    pending.removeWhere(
      (mutation) => mutation.entityId == entityId && mutation.type == type,
    );
    pending.add(
      PendingFavoriteMutation(
        entityId: entityId,
        type: type,
        isFavorite: targetIsFavorite,
        queuedAt: DateTime.now(),
      ),
    );
    if (pending.length > _maxPendingMutations) {
      pending.removeRange(0, pending.length - _maxPendingMutations);
    }
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await _writePendingMutations(pending, sessionGeneration: sessionGeneration);
  }

  Future<void> _dequeuePendingMutation({
    required String entityId,
    required FavoriteType type,
    required int sessionGeneration,
  }) async {
    final pending = await _readPendingMutations();
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    final before = pending.length;
    pending.removeWhere(
      (mutation) => mutation.entityId == entityId && mutation.type == type,
    );
    if (pending.length != before) {
      if (!_isCurrentAuthSession(sessionGeneration)) {
        return;
      }
      await _writePendingMutations(
        pending,
        sessionGeneration: sessionGeneration,
      );
    }
  }

  Future<List<PendingFavoriteMutation>> _readPendingMutations() async {
    final storage = await _ref.read(localStorageProvider.future);
    final raw = storage.getPendingFavoriteMutations();
    return raw
        .map(PendingFavoriteMutation.fromJson)
        .where(
          (mutation) =>
              mutation.entityId.isNotEmpty &&
              mutation.type != FavoriteType.unknown,
        )
        .toList(growable: true);
  }

  Future<void> _writePendingMutations(
    List<PendingFavoriteMutation> pending, {
    required int sessionGeneration,
  }) async {
    final storage = await _ref.read(localStorageProvider.future);
    if (!_isCurrentAuthSession(sessionGeneration)) {
      return;
    }
    await storage.setPendingFavoriteMutations(
      pending.map((mutation) => mutation.toJson()).toList(growable: false),
    );
  }
}

/// EN: Favorites repository provider.
/// KO: 즐겨찾기 리포지토리 프로바이더.
final favoritesRepositoryProvider = FutureProvider<FavoritesRepository>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = await ref.read(cacheManagerProvider.future);
  return FavoritesRepositoryImpl(
    remoteDataSource: FavoritesRemoteDataSource(apiClient),
    cacheManager: cacheManager,
  );
});

/// EN: Favorites controller provider.
/// KO: 즐겨찾기 컨트롤러 프로바이더.
final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, AsyncValue<List<FavoriteItem>>>((
      ref,
    ) {
      return FavoritesController(ref);
    });
