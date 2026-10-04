import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review_selection_seed.dart';
import '../data/private_trip_store.dart';
import '../domain/private_trip.dart';

final privateTripStoreProvider = FutureProvider<PrivateTripStore>(
  (ref) async => PrivateTripStore(
    storage: await ref.watch(localStorageProvider.future),
    directory: await getApplicationSupportDirectory(),
  ),
);

final privateTripsControllerProvider =
    StateNotifierProvider.autoDispose<
      PrivateTripsController,
      AsyncValue<List<PrivateTrip>>
    >((ref) {
      ref.watch(authStateProvider);
      final controller = PrivateTripsController(
        store: ref.watch(privateTripStoreProvider.future),
        currentUserId: () async =>
            ref.read(authStateProvider) == AuthState.authenticated
            ? ref.read(secureStorageProvider).getUserId()
            : null,
      );
      ref.listen(authTokenRefreshTickProvider, (_, _) {
        unawaited(
          controller.ready
              .then((_) => controller.assertSession())
              .catchError((Object _) {}),
        );
      });
      return controller;
    });

/// EN: Every asynchronous boundary rechecks the owner, including export.
/// KO: 내보내기를 포함한 모든 비동기 경계에서 소유 계정을 다시 확인합니다.
class PrivateTripsController
    extends StateNotifier<AsyncValue<List<PrivateTrip>>> {
  PrivateTripsController({
    required Future<PrivateTripStore> store,
    required Future<String?> Function() currentUserId,
  }) : _storeFuture = store,
       _currentUserId = currentUserId,
       super(const AsyncLoading()) {
    ready = _load();
  }
  final Future<PrivateTripStore> _storeFuture;
  final Future<String?> Function() _currentUserId;
  late final Future<void> ready;
  String? _owner;
  String? get ownerUserId => _owner;
  bool _busy = false;

  Future<void> _load() async {
    try {
      _owner = await _currentUserId();
      if (_owner == null || _owner!.isEmpty) {
        throw StateError('Sign in required');
      }
      final store = await _storeFuture;
      await assertSession();
      final trips = await store.load(_owner!);
      await assertSession();
      if (mounted) state = AsyncData(trips);
    } catch (error, stack) {
      if (mounted) state = AsyncError(error, stack);
    }
  }

  Future<void> assertSession() async {
    if (!mounted) throw StateError('Session ended');
    final current = await _currentUserId();
    if (!mounted || current == null || current != _owner) {
      final error = StateError('Session changed');
      if (mounted) state = AsyncError(error, StackTrace.current);
      throw error;
    }
  }

  Future<void> replace(List<PrivateTrip> trips) async {
    await ready;
    await assertSession();
    if (_busy) throw StateError('A save is already running');
    _busy = true;
    try {
      final store = await _storeFuture;
      await assertSession();
      await store.save(_owner!, trips);
      await assertSession();
      state = AsyncData(List.unmodifiable(trips));
    } finally {
      _busy = false;
    }
  }

  Future<void> upsert(PrivateTrip trip) async {
    await ready;
    final trips = [...state.requireValue];
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index < 0) {
      trips.add(trip);
    } else {
      trips[index] = trip;
    }
    await replace(trips);
  }

  Future<PrivateTripPhoto> copyPhoto(String sourcePath) async {
    await ready;
    await assertSession();
    final store = await _storeFuture;
    await assertSession();
    final photo = await store.copyPhoto(_owner!, sourcePath);
    try {
      await assertSession();
    } catch (_) {
      await File(photo.path).delete();
      rethrow;
    }
    return photo;
  }

  Future<List<String>> exportPhotos(List<PrivateTripPhoto> photos) async {
    await ready;
    await assertSession();
    final store = await _storeFuture;
    final paths = <String>[];
    try {
      for (final photo in photos) {
        await assertSession();
        paths.add(await store.exportPhoto(_owner!, photo));
        await assertSession();
      }
      return paths;
    } catch (_) {
      for (final path in paths) {
        await File(path).delete();
      }
      rethrow;
    }
  }

  Future<PrivateTrip> addPhoto(PrivateTrip trip, String sourcePath) async {
    if (trip.title.trim().isEmpty) throw ArgumentError('Title required');
    final photo = await copyPhoto(sourcePath);
    final updated = trip.copyWith(photos: [...trip.photos, photo]);
    try {
      await upsert(updated);
      return updated;
    } catch (_) {
      await (await _storeFuture).deleteUnreferencedPhoto(_owner!, photo);
      rethrow;
    }
  }

  Future<void> deleteExports(TravelReviewSelectionSeed seed) async {
    await (await _storeFuture).deleteExports(seed.ownerUserId, seed.photoPaths);
  }

  Future<TravelReviewSelectionSeed> prepareSelection({
    required PrivateTrip trip,
    required Set<String> entryIds,
    required Set<String> photoIds,
    required bool includeDates,
  }) async {
    await ready;
    await assertSession();
    if (!state.requireValue.any(
      (t) => t.id == trip.id && t.projectKey == trip.projectKey,
    )) {
      throw StateError('Save the private trip first');
    }
    final entries = trip.entries.where((e) => entryIds.contains(e.id)).toList();
    final places = {
      for (final e in entries)
        if (e.place case final p?) p.id: p,
    }.values.toList();
    final events = {
      for (final e in entries)
        if (e.event case final event?) event.id: event,
    }.values.toList();
    final photos = trip.photos.where((p) => photoIds.contains(p.id)).toList();
    if (places.isEmpty ||
        places.length > 20 ||
        events.length > 10 ||
        photos.length > 10 ||
        entries.any((e) => e.projectKey != trip.projectKey) ||
        (includeDates && !trip.datesConfirmed)) {
      throw ArgumentError('Select 1–20 places, up to 10 events and 10 photos');
    }
    final paths = await exportPhotos(photos);
    return TravelReviewSelectionSeed(
      ownerUserId: _owner!,
      projectCode: trip.projectKey,
      places: places,
      events: events,
      photoPaths: paths,
      tripStartedOn: includeDates ? trip.startedOn : null,
      tripEndedOn: includeDates ? trip.endedOn : null,
    );
  }
}
