import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/connectivity/connectivity_service.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/auth/application/auth_controller.dart';
import 'package:oshi_log/features/favorites/application/favorites_controller.dart';
import 'package:oshi_log/features/favorites/application/pending_favorite_mutation.dart';
import 'package:oshi_log/features/favorites/domain/entities/favorite_entities.dart';
import 'package:oshi_log/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:oshi_log/features/feed/application/feed_repository_provider.dart';
import 'package:oshi_log/features/feed/application/local_post_bookmarks_controller.dart';
import 'package:oshi_log/features/feed/application/pending_post_reaction_mutation.dart';
import 'package:oshi_log/features/feed/application/reaction_controller.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/domain/repositories/feed_repository.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/application/pending_live_attendance_mutation.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/domain/repositories/live_events_repository.dart';

void main() {
  test(
    'logout cleanup clears personal records only in the active API origin',
    () async {
      SharedPreferences.setMockInitialValues({LocalStorageKeys.locale: 'ko'});
      final prefs = await SharedPreferences.getInstance();
      final development = LocalStorage(prefs, namespace: 'dev.oshilog.org');
      final production = LocalStorage(prefs, namespace: 'api.oshilog.org');

      await development.setPendingFavoriteMutations([
        _favoriteMutation('dev-favorite').toJson(),
      ]);
      await development.setPendingPostReactionMutations([
        _reactionMutation('dev-post').toJson(),
      ]);
      await development.setPendingLiveAttendanceMutations([
        _attendanceMutation('dev-event').toJson(),
      ]);
      await development.setLocalPostBookmarks([_bookmark('dev-bookmark')]);
      await production.setPendingFavoriteMutations([
        _favoriteMutation('prod-favorite').toJson(),
      ]);
      await production.setPendingPostReactionMutations([
        _reactionMutation('prod-post').toJson(),
      ]);
      await production.setPendingLiveAttendanceMutations([
        _attendanceMutation('prod-event').toJson(),
      ]);
      await production.setLocalPostBookmarks([_bookmark('prod-bookmark')]);

      await clearUserScopedLocalStorage(development);

      expect(development.getPendingFavoriteMutations(), isEmpty);
      expect(development.getPendingPostReactionMutations(), isEmpty);
      expect(development.getPendingLiveAttendanceMutations(), isEmpty);
      expect(development.getLocalPostBookmarks(), isEmpty);
      expect(
        production.getPendingFavoriteMutations().single['entityId'],
        'prod-favorite',
      );
      expect(
        production.getPendingPostReactionMutations().single['postId'],
        'prod-post',
      );
      expect(
        production.getPendingLiveAttendanceMutations().single['eventId'],
        'prod-event',
      );
      expect(
        production.getLocalPostBookmarks().single['postId'],
        'prod-bookmark',
      );
      expect(prefs.getString(LocalStorageKeys.locale), 'ko');
    },
  );

  test(
    'favorite sync does not restore cleared rows after logout and login',
    () async {
      final storage = await _newStorage();
      await storage.setPendingFavoriteMutations([
        _favoriteMutation('first').toJson(),
        _favoriteMutation('second').toJson(),
      ]);
      final repository = _ControlledFavoritesRepository();
      final container = _container(
        localStorage: storage,
        overrides: [
          favoritesRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authStateProvider.notifier);
      auth.setAuthenticated();
      final controller = container.read(favoritesControllerProvider.notifier);

      await _waitUntil(() => repository.addCalls == 1);
      auth.setUnauthenticated();
      await storage.setPendingFavoriteMutations(const []);
      await _drainMicrotasks();
      auth.setAuthenticated();
      repository.completeAdd();
      await _drainMicrotasks();

      expect(storage.getPendingFavoriteMutations(), isEmpty);
      expect(repository.addCalls, 1);
      await controller.syncPendingMutations();
      expect(repository.addCalls, 1);
    },
  );

  test(
    'post reaction sync does not restore cleared rows after logout and login',
    () async {
      final storage = await _newStorage();
      await storage.setPendingPostReactionMutations([
        _reactionMutation('first').toJson(),
        _reactionMutation('second').toJson(),
      ]);
      final repository = _ControlledFeedRepository();
      final container = _container(
        localStorage: storage,
        overrides: [
          feedRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authStateProvider.notifier);
      auth.setAuthenticated();
      final controller = container.read(postReactionOutboxControllerProvider);

      await _waitUntil(() => repository.likeCalls == 1);
      auth.setUnauthenticated();
      await storage.setPendingPostReactionMutations(const []);
      await _drainMicrotasks();
      auth.setAuthenticated();
      repository.completeLike();
      await _drainMicrotasks();

      expect(storage.getPendingPostReactionMutations(), isEmpty);
      expect(repository.likeCalls, 1);
      await controller.syncPendingMutations();
      expect(repository.likeCalls, 1);
    },
  );

  test(
    'attendance sync does not restore cleared rows after logout and login',
    () async {
      final storage = await _newStorage();
      await storage.setPendingLiveAttendanceMutations([
        _attendanceMutation('first').toJson(),
        _attendanceMutation('second').toJson(),
      ]);
      final repository = _ControlledLiveEventsRepository();
      final container = _container(
        localStorage: storage,
        overrides: [
          liveEventsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.read(authStateProvider.notifier);
      auth.setAuthenticated();
      final controller = container.read(liveAttendanceOutboxControllerProvider);

      await _waitUntil(() => repository.toggleCalls == 1);
      auth.setUnauthenticated();
      await storage.setPendingLiveAttendanceMutations(const []);
      await _drainMicrotasks();
      auth.setAuthenticated();
      repository.completeToggle();
      await _drainMicrotasks();

      expect(storage.getPendingLiveAttendanceMutations(), isEmpty);
      expect(repository.toggleCalls, 1);
      await controller.syncPendingMutations();
      expect(repository.toggleCalls, 1);
    },
  );

  test(
    'bookmark write from an old auth session cannot overwrite new bookmarks',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs, namespace: 'dev.oshilog.org');
      final storageReady = Completer<LocalStorage>();
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageReady.future),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authStateProvider.notifier);
      auth.setAuthenticated();
      final controller = container.read(
        localPostBookmarksControllerProvider.notifier,
      );
      final oldEntry = LocalBookmarkedPost(
        postId: 'old-session',
        projectCode: 'project',
        title: 'Old session',
        bookmarkedAt: DateTime.utc(2026, 9, 1),
      );

      final addFuture = controller.addBookmark(oldEntry);
      await _drainMicrotasks();

      auth.setUnauthenticated();
      await _drainMicrotasks();
      await storage.setLocalPostBookmarks([_bookmark('new-session')]);
      auth.setAuthenticated();
      await _drainMicrotasks();
      storageReady.complete(storage);
      await addFuture;
      await _waitUntil(
        () => controller.state.singleOrNull?.postId == 'new-session',
      );

      expect(storage.getLocalPostBookmarks().single['postId'], 'new-session');
      expect(controller.state.single.postId, 'new-session');
    },
  );
}

ProviderContainer _container({
  required LocalStorage localStorage,
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWith((ref) async => localStorage),
      connectivityServiceProvider.overrideWithValue(_OnlineConnectivity()),
      ...overrides,
    ],
  );
}

Future<LocalStorage> _newStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return LocalStorage(prefs, namespace: 'dev.oshilog.org');
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

Future<void> _drainMicrotasks() async {
  for (var i = 0; i < 8; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

PendingFavoriteMutation _favoriteMutation(String entityId) {
  return PendingFavoriteMutation(
    entityId: entityId,
    type: FavoriteType.place,
    isFavorite: true,
    queuedAt: DateTime.utc(2026, 9, 1),
  );
}

PendingPostReactionMutation _reactionMutation(String postId) {
  return PendingPostReactionMutation(
    projectCode: 'project',
    postId: postId,
    type: PostReactionMutationType.like,
    enabled: true,
    queuedAt: DateTime.utc(2026, 9, 1),
  );
}

PendingLiveAttendanceMutation _attendanceMutation(String eventId) {
  return PendingLiveAttendanceMutation(
    projectKey: 'project',
    eventId: eventId,
    attended: true,
    queuedAt: DateTime.utc(2026, 9, 1),
  );
}

Map<String, dynamic> _bookmark(String postId) {
  return {
    'postId': postId,
    'projectCode': 'project',
    'title': postId,
    'bookmarkedAt': '2026-09-01T00:00:00.000Z',
  };
}

class _OnlineConnectivity extends ConnectivityService {
  @override
  Future<bool> get isOnline => Future<bool>.value(true);

  @override
  Stream<ConnectivityStatus> get statusStream => const Stream.empty();
}

class _ControlledFavoritesRepository implements FavoritesRepository {
  int addCalls = 0;
  Completer<Result<FavoriteItem>>? _addCompleter;

  @override
  Future<Result<FavoriteItem>> addFavorite({
    required String entityId,
    required FavoriteType type,
  }) {
    addCalls += 1;
    final completer = _addCompleter ??= Completer<Result<FavoriteItem>>();
    return completer.future;
  }

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) {
    return Future.value(const Result.success(<FavoriteItem>[]));
  }

  @override
  Future<Result<void>> removeFavorite({
    required String entityId,
    required FavoriteType type,
  }) {
    return Future.value(const Result.success(null));
  }

  void completeAdd() {
    _addCompleter?.complete(
      const Result.success(
        FavoriteItem(entityId: 'first', type: FavoriteType.place),
      ),
    );
  }
}

class _ControlledFeedRepository implements FeedRepository {
  int likeCalls = 0;
  Completer<Result<PostLikeStatus>>? _likeCompleter;

  @override
  Future<Result<PostLikeStatus>> likePost({
    required String projectCode,
    required String postId,
  }) {
    likeCalls += 1;
    final completer = _likeCompleter ??= Completer<Result<PostLikeStatus>>();
    return completer.future;
  }

  @override
  Future<Result<PostLikeStatus>> getPostLikeStatus({
    required String projectCode,
    required String postId,
  }) {
    return Future.value(
      Result.success(
        PostLikeStatus(postId: postId, isLiked: false, likeCount: 0),
      ),
    );
  }

  void completeLike() {
    _likeCompleter?.complete(
      const Result.success(
        PostLikeStatus(postId: 'first', isLiked: true, likeCount: 1),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used');
}

class _ControlledLiveEventsRepository implements LiveEventsRepository {
  int toggleCalls = 0;
  Completer<Result<LiveAttendanceState>>? _toggleCompleter;

  @override
  Future<Result<LiveAttendanceState>> toggleLiveAttendance({
    required String projectId,
    required String eventId,
    required bool attended,
  }) {
    toggleCalls += 1;
    final completer = _toggleCompleter ??=
        Completer<Result<LiveAttendanceState>>();
    return completer.future;
  }

  void completeToggle() {
    _toggleCompleter?.complete(
      const Result.success(
        LiveAttendanceState(
          liveEventId: 'first',
          attended: true,
          status: LiveAttendanceStatus.declared,
          canUndo: true,
        ),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used');
}
