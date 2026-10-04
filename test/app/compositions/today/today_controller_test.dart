import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oshi_log/app/compositions/today/application/today_controller.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

class _Storage extends Mock implements LocalStorage {}

void main() {
  late _Storage storage;
  late Map<String, Map<String, dynamic>> saved;
  var userId = 'a';
  var now = DateTime.utc(2026, 10, 3, 16);
  var saveSucceeds = true;
  var downloadFails = false;
  var downloadFromCache = false;
  TodayController create() => TodayController(
    storage: () async => storage,
    readUserId: () async => userId,
    now: () => now,
    fetchDetail: (project, place) async {
      if (downloadFails) throw StateError('offline');
      return PlaceDetail(
        id: place,
        name: 'Place $place',
        address: 'Address',
        types: const [],
        description: 'Respect residents',
        isFromCache: downloadFromCache,
      );
    },
  );
  const first = PlaceDetail(
    id: '1',
    name: 'First',
    address: 'Tokyo',
    types: [],
  );
  const second = PlaceDetail(
    id: '2',
    name: 'Second',
    address: 'Kawasaki',
    types: [],
  );

  setUp(() {
    storage = _Storage();
    saved = {};
    userId = 'a';
    now = DateTime.utc(2026, 10, 3, 16);
    saveSucceeds = true;
    downloadFails = false;
    downloadFromCache = false;
    when(
      () => storage.getJson(any()),
    ).thenAnswer((invocation) => saved[invocation.positionalArguments.first]);
    when(() => storage.setJson(any(), any())).thenAnswer((invocation) async {
      if (!saveSucceeds) return false;
      saved[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as Map<String, dynamic>;
      return true;
    });
  });

  test(
    'manual order and skips restore after restart with project-scoped IDs',
    () async {
      final controller = create();
      await controller.ready;
      await controller.addDetail(projectKey: 'p', detail: first);
      await controller.addDetail(projectKey: 'q', detail: first);
      await controller.addDetail(projectKey: 'p', detail: second);
      await controller.move(2, 0);
      await controller.toggleSkipped('p:2');
      controller.dispose();
      final restored = create();
      await restored.ready;
      expect(restored.state.plan!.entries.map((e) => e.key), [
        'p:2',
        'p:1',
        'q:1',
      ]);
      expect(restored.state.plan!.entries.first.skipped, isTrue);
      expect(restored.state.plan!.date, '2026-10-04');
      restored.dispose();
    },
  );

  test('save failure keeps previous durable order', () async {
    final controller = create();
    await controller.ready;
    await controller.addDetail(projectKey: 'p', detail: first);
    saveSucceeds = false;
    expect(
      await controller.addDetail(projectKey: 'p', detail: second),
      isFalse,
    );
    expect(controller.state.plan!.entries.length, 1);
    expect(controller.state.failure, TodayFailure.save);
    controller.dispose();
  });

  test('cached fallback cannot claim a newly downloaded text pack', () async {
    final controller = create();
    await controller.ready;
    await controller.addDetail(projectKey: 'p', detail: first);
    downloadFromCache = true;
    expect(await controller.downloadText('p:1'), isFalse);
    expect(controller.state.plan!.entries.single.text, isNull);
    expect(controller.state.failedDownloads, contains('p:1'));
    controller.dispose();
  });

  test(
    'unreadable persisted JSON is a load error rather than an empty plan',
    () async {
      when(() => storage.getString(any())).thenReturn('{broken');
      final controller = create();
      await controller.ready;
      expect(controller.state.plan, isNull);
      expect(controller.state.failure, TodayFailure.load);
      controller.dispose();
    },
  );

  test('download failure retains saved text and original timestamp', () async {
    final controller = create();
    await controller.ready;
    await controller.addDetail(projectKey: 'p', detail: first);
    await controller.downloadText('p:1');
    final savedAt = controller.state.plan!.entries.single.text!.savedAt;
    now = now.add(const Duration(hours: 1));
    downloadFails = true;
    expect(await controller.downloadText('p:1'), isFalse);
    final entry = controller.state.plan!.entries.single;
    expect(entry.text!.description, 'Respect residents');
    expect(entry.text!.savedAt, savedAt);
    expect(controller.state.failedDownloads, contains('p:1'));
    controller.dispose();
  });

  test('account switch cannot read or write another account list', () async {
    final controller = create();
    await controller.ready;
    await controller.addDetail(projectKey: 'p', detail: first);
    userId = 'b';
    expect(
      await controller.addDetail(projectKey: 'p', detail: second),
      isFalse,
    );
    expect(controller.state.plan, isNull);
    final other = create();
    await other.ready;
    expect(other.state.plan!.entries, isEmpty);
    await other.addDetail(projectKey: 'p', detail: second);
    userId = 'a';
    final restored = create();
    await restored.ready;
    expect(restored.state.plan!.entries.single.placeId, '1');
    controller.dispose();
    other.dispose();
    restored.dispose();
  });

  test('new JST day retains old dated plan until explicit reset', () async {
    final controller = create();
    await controller.ready;
    await controller.addDetail(projectKey: 'p', detail: first);
    now = DateTime.utc(2026, 10, 4, 15);
    final restored = create();
    await restored.ready;
    expect(restored.state.plan!.date, '2026-10-04');
    expect(await restored.addDetail(projectKey: 'p', detail: second), isFalse);
    expect(restored.state.failure, TodayFailure.dateMismatch);
    await restored.startToday();
    expect(restored.state.plan!.date, '2026-10-05');
    expect(restored.state.plan!.entries, isEmpty);
    controller.dispose();
    restored.dispose();
  });
}
