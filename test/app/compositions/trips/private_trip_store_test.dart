import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/app/compositions/trips/application/private_trips_controller.dart';
import 'package:oshi_log/app/compositions/trips/data/private_trip_store.dart';
import 'package:oshi_log/app/compositions/trips/domain/private_trip.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LocalStorage storage;
  late PrivateTripStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorage.create();
    directory = await Directory.systemTemp.createTemp('private-trips-test-');
    store = PrivateTripStore(storage: storage, directory: directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  const entry = PrivateTripEntry(
    id: 'visit:one',
    resourceId: 'place-one',
    title: 'Place one',
    kind: TripEntryKind.place,
    projectKey: 'project',
    verified: true,
  );

  test(
    'candidate has no asserted trip date and merge/split preserves sources',
    () {
      final first = PrivateTrip(
        id: 'one',
        projectKey: 'project',
        title: 'One',
        entries: [entry],
      );
      final second = PrivateTrip(
        id: 'two',
        projectKey: 'project',
        title: 'Two',
        entries: [entry.copyWith(id: 'visit:two')],
      );
      final merged = first.merge(second);
      expect(merged.startedOn, isNull);
      expect(merged.datesConfirmed, isFalse);
      expect(merged.entries.map((e) => e.id), ['visit:one', 'visit:two']);
      final split = merged.split({'visit:two'}, newId: 'three');
      expect(split.$1.entries.single.id, 'visit:one');
      expect(split.$2.entries.single.id, 'visit:two');
      expect(
        () =>
            first.merge(PrivateTrip(id: 'x', projectKey: 'other', title: 'X')),
        throwsArgumentError,
      );
    },
  );

  test(
    'restart restores private dates and memo without exposing another account',
    () async {
      final trip = PrivateTrip(
        id: 'one',
        projectKey: 'project',
        title: 'Private title',
        memo: 'Private lodging details',
        entries: [entry],
        startedOn: DateTime(2026, 10, 1),
        endedOn: DateTime(2026, 10, 2),
        datesConfirmed: true,
      );
      await store.save('user-a', [trip]);
      final reopened = PrivateTripStore(storage: storage, directory: directory);
      final restored = await reopened.load('user-a');
      expect(restored.single.memo, trip.memo);
      expect(restored.single.startedOn, trip.startedOn);
      expect(await reopened.load('user-b'), isEmpty);
      expect(() => reopened.load(''), throwsArgumentError);
    },
  );

  test(
    'photo survives original picker file removal and store recreation',
    () async {
      final source = File('${directory.path}/picker.jpg');
      await source.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));
      final photo = await store.copyPhoto('user-a', source.path);
      await store.save('user-a', [
        PrivateTrip(
          id: 'one',
          projectKey: 'project',
          title: 'Trip',
          photos: [photo],
        ),
      ]);
      await source.delete();
      final reopened = PrivateTripStore(storage: storage, directory: directory);
      final restored = (await reopened.load('user-a')).single;
      expect(await File(restored.photos.single.path).readAsBytes(), [
        1,
        2,
        3,
        4,
      ]);
      expect(restored.photos.single.path, isNot(source.path));
      expect(await reopened.load('user-b'), isEmpty);
      final relocated = await Directory(
        '${directory.path}/new-sandbox',
      ).create();
      await Directory(
        '${directory.path}/private_trips',
      ).rename('${relocated.path}/private_trips');
      final movedStore = PrivateTripStore(
        storage: storage,
        directory: relocated,
      );
      final moved = (await movedStore.load('user-a')).single.photos.single;
      expect(moved.path, startsWith(relocated.path));
      expect(await File(moved.path).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test('account change while storage loads drops old private result', () async {
    await store.save('user-a', [
      const PrivateTrip(id: 'one', projectKey: 'project', title: 'Private A'),
    ]);
    String? currentUser = 'user-a';
    final pending = Completer<PrivateTripStore>();
    final controller = PrivateTripsController(
      store: pending.future,
      currentUserId: () async => currentUser,
    );
    await Future<void>.delayed(Duration.zero);
    currentUser = 'user-b';
    pending.complete(store);
    await controller.ready;
    expect(controller.state.hasError, isTrue);
    expect(controller.state.valueOrNull, isNull);
    controller.dispose();
  });

  test(
    'token refresh preserves same-account editing and rejects a changed owner',
    () async {
      final secure = _UserStorage('user-a');
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(secure),
          authStateProvider.overrideWith(
            (ref) => AuthStateNotifier(secure)..setAuthenticated(),
          ),
          privateTripStoreProvider.overrideWith((ref) async => store),
        ],
      );
      addTearDown(container.dispose);
      container.listen(privateTripsControllerProvider, (_, _) {});
      final controller = container.read(
        privateTripsControllerProvider.notifier,
      );
      await controller.ready;
      container.read(authTokenRefreshTickProvider.notifier).state++;
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(privateTripsControllerProvider.notifier),
        same(controller),
      );
      expect(container.read(privateTripsControllerProvider).hasError, isFalse);
      secure.userId = 'user-b';
      container.read(authTokenRefreshTickProvider.notifier).state++;
      await Future<void>.delayed(Duration.zero);
      expect(container.read(privateTripsControllerProvider).hasError, isTrue);
      expect(
        container.read(privateTripsControllerProvider).valueOrNull,
        isNull,
      );
    },
  );

  test(
    'logout rejects save and keeps previously persisted private trip',
    () async {
      String? currentUser = 'user-a';
      final controller = PrivateTripsController(
        store: Future.value(store),
        currentUserId: () async => currentUser,
      );
      await controller.ready;
      await controller.upsert(
        const PrivateTrip(
          id: 'one',
          projectKey: 'project',
          title: 'Before logout',
        ),
      );
      currentUser = null;
      await expectLater(
        controller.upsert(
          const PrivateTrip(
            id: 'one',
            projectKey: 'project',
            title: 'After logout',
          ),
        ),
        throwsStateError,
      );
      expect((await store.load('user-a')).single.title, 'Before logout');
      controller.dispose();
    },
  );

  test(
    'explicit export includes selected places and sanitized photos only',
    () async {
      final controller = PrivateTripsController(
        store: Future.value(store),
        currentUserId: () async => 'user-a',
      );
      await controller.ready;
      final source = File('${directory.path}/private-original.png');
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawColor(const ui.Color(0xff00ff00), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      await source.writeAsBytes([
        ...png,
        ...utf8.encode('PRIVATE GPS 35.123,139.456'),
      ]);
      final selected = await controller.copyPhoto(source.path);
      final unselected = await controller.copyPhoto(source.path);
      const place = PlaceSummary(
        id: 'place-one',
        name: 'Place one',
        address: 'Tokyo',
        latitude: 35,
        longitude: 139,
      );
      final trip = PrivateTrip(
        id: 'one',
        projectKey: 'project',
        title: 'Private lodging',
        memo: 'Private meeting time',
        entries: [
          const PrivateTripEntry(
            id: 'place:one',
            resourceId: 'place-one',
            title: 'Place one',
            kind: TripEntryKind.place,
            projectKey: 'project',
            place: place,
          ),
          entry,
        ],
        photos: [selected, unselected],
        startedOn: DateTime(2026, 10, 1),
        endedOn: DateTime(2026, 10, 2),
        datesConfirmed: true,
      );
      await controller.upsert(trip);
      final seed = await controller.prepareSelection(
        trip: trip,
        entryIds: {'place:one'},
        photoIds: {selected.id},
        includeDates: false,
      );
      expect(seed.places.map((p) => p.id), ['place-one']);
      expect(seed.tripStartedOn, isNull);
      expect(seed.tripEndedOn, isNull);
      expect(seed.photoPaths, hasLength(1));
      expect(seed.photoPaths.single, isNot(selected.path));
      expect(seed.photoPaths.single, endsWith('.png'));
      expect(
        utf8.decode(
          await File(seed.photoPaths.single).readAsBytes(),
          allowMalformed: true,
        ),
        isNot(contains('PRIVATE GPS')),
      );
      expect(await File(selected.path).readAsBytes(), [
        ...png,
        ...utf8.encode('PRIVATE GPS 35.123,139.456'),
      ]);
      expect((await store.load('user-a')).single.memo, 'Private meeting time');
      final withDates = await controller.prepareSelection(
        trip: trip,
        entryIds: {'place:one'},
        photoIds: {},
        includeDates: true,
      );
      expect(withDates.tripStartedOn, DateTime(2026, 10, 1));
      expect(withDates.photoPaths, isEmpty);
      await controller.deleteExports(seed);
      expect(await File(seed.photoPaths.single).exists(), isFalse);
      expect(await File(selected.path).exists(), isTrue);
      await expectLater(
        store.deleteExports('user-a', [selected.path]),
        throwsArgumentError,
      );
      controller.dispose();
    },
  );

  test(
    'selection accepts ten events and rejects eleven before photo export',
    () async {
      final exportSpy = _ExportSpyStore(storage: storage, directory: directory);
      final controller = PrivateTripsController(
        store: Future.value(exportSpy),
        currentUserId: () async => 'user-a',
      );
      addTearDown(controller.dispose);
      await controller.ready;
      final source = await File(
        '${directory.path}/picker.jpg',
      ).writeAsBytes([1, 2, 3]);
      final photo = await controller.copyPhoto(source.path);
      final trip = PrivateTrip(
        id: 'event-limit',
        projectKey: 'project',
        title: 'Private trip',
        entries: [
          const PrivateTripEntry(
            id: 'place:one',
            resourceId: 'place-one',
            title: 'Place one',
            kind: TripEntryKind.place,
            projectKey: 'project',
            place: PlaceSummary(
              id: 'place-one',
              name: 'Place one',
              address: 'Tokyo',
              latitude: 35,
              longitude: 139,
            ),
          ),
          for (var i = 0; i < 11; i++)
            PrivateTripEntry(
              id: 'live:$i',
              resourceId: 'event-$i',
              title: 'Event $i',
              kind: TripEntryKind.live,
              projectKey: 'project',
              eventStart: DateTime(2026, 10, 1),
            ),
        ],
        photos: [photo],
      );
      await controller.upsert(trip);

      final allowed = await controller.prepareSelection(
        trip: trip,
        entryIds: {'place:one', for (var i = 0; i < 10; i++) 'live:$i'},
        photoIds: {},
        includeDates: false,
      );
      expect(allowed.events, hasLength(10));
      await expectLater(
        controller.prepareSelection(
          trip: trip,
          entryIds: trip.entries.map((entry) => entry.id).toSet(),
          photoIds: {photo.id},
          includeDates: false,
        ),
        throwsArgumentError,
      );
      expect(exportSpy.exportCalls, 0);
      expect(await File(photo.path).exists(), isTrue);
    },
  );

  test('another account cannot load or export private photo paths', () async {
    final source = await File(
      '${directory.path}/picker.jpg',
    ).writeAsBytes([1, 2, 3]);
    final photo = await store.copyPhoto('user-a', source.path);
    await expectLater(store.exportPhoto('user-b', photo), throwsArgumentError);
    await expectLater(
      store.save('user-b', [
        PrivateTrip(
          id: 'one',
          projectKey: 'project',
          title: 'Trip',
          photos: [photo],
        ),
      ]),
      throwsFormatException,
    );
  });

  test(
    'invalid stored album fails instead of replacing private data with empty',
    () async {
      await storage.setJson('trips_v1:user-a', {'version': 99, 'trips': []});
      await expectLater(store.load('user-a'), throwsFormatException);
      expect(storage.getJson('trips_v1:user-a')?['version'], 99);
    },
  );

  test(
    'failed photo metadata save removes copied orphan and keeps old album',
    () async {
      final failing = _FailSaveStore(storage: storage, directory: directory);
      final controller = PrivateTripsController(
        store: Future.value(failing),
        currentUserId: () async => 'user-a',
      );
      await controller.ready;
      const trip = PrivateTrip(
        id: 'one',
        projectKey: 'project',
        title: 'Original',
      );
      await controller.upsert(trip);
      final source = await File(
        '${directory.path}/picker.jpg',
      ).writeAsBytes([1, 2, 3]);
      failing.failSave = true;
      await expectLater(
        controller.addPhoto(trip, source.path),
        throwsA(isA<FileSystemException>()),
      );
      expect((await failing.load('user-a')).single.photos, isEmpty);
      expect(
        await directory
            .list(recursive: true)
            .where((f) => f.path.endsWith('.original'))
            .toList(),
        isEmpty,
      );
      controller.dispose();
    },
  );
}

class _ExportSpyStore extends PrivateTripStore {
  _ExportSpyStore({required super.storage, required super.directory});
  int exportCalls = 0;

  @override
  Future<String> exportPhoto(String userId, PrivateTripPhoto photo) async {
    exportCalls++;
    throw StateError('Invalid selection must not reach photo export');
  }
}

class _FailSaveStore extends PrivateTripStore {
  _FailSaveStore({required super.storage, required super.directory});
  bool failSave = false;
  @override
  Future<void> save(String userId, List<PrivateTrip> trips) {
    if (failSave) throw const FileSystemException('Test write failure');
    return super.save(userId, trips);
  }
}

class _UserStorage implements SecureStorage {
  _UserStorage(this.userId);
  String? userId;
  @override
  Future<String?> getUserId() async => userId;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
