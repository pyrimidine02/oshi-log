import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/features/feed/application/post_compose_autosave_controller.dart';
import 'package:oshi_log/features/feed/application/post_compose_draft_store.dart';

void main() {
  group('PostComposeAutosaveController', () {
    test('loads recoverable draft from local storage', () async {
      final store = await _createStore();
      const key = 'draft_create';
      await store.write(
        key,
        PostComposeDraft(
          title: '임시 제목',
          content: '임시 내용',
          imagePaths: const ['/tmp/sample.jpg'],
          savedAt: DateTime.parse('2026-03-05T16:00:00.000Z'),
          projectCode: 'girls-band-cry',
          topic: '정보',
          tags: const ['라이브'],
        ),
      );

      final container = _createContainer(store);
      addTearDown(container.dispose);

      final notifier = container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(storageKey: key),
        ).notifier,
      );

      await notifier.loadRecoverableDraft();

      final state = container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(storageKey: key),
        ),
      );
      expect(state.recoverableDraft, isNotNull);
      expect(state.recoverableDraft!.title, '임시 제목');
      expect(state.recoverableDraft!.content, '임시 내용');
      expect(state.recoverableDraft!.topic, '정보');
      expect(state.recoverableDraft!.tags, ['라이브']);
    });

    test('saves snapshot and updates autosave message', () async {
      final store = await _createStore();
      const key = 'draft_create';
      final container = _createContainer(store);
      addTearDown(container.dispose);

      final notifier = container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(storageKey: key),
        ).notifier,
      );

      await notifier.saveSnapshot(
        title: '새 제목',
        content: '새 내용',
        imagePaths: const ['/tmp/new.jpg'],
        topic: '후기',
        tags: const ['굿즈', '라이브'],
        hasData: true,
      );

      final state = container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(storageKey: key),
        ),
      );
      final saved = await store.read(key);

      expect(state.autosaveMessage, startsWith('임시 저장됨 ·'));
      expect(saved, isNotNull);
      expect(saved!.title, '새 제목');
      expect(saved.projectCode, 'girls-band-cry');
      expect(saved.topic, '후기');
      expect(saved.tags, ['굿즈', '라이브']);
    });

    test('deletes snapshot when payload becomes empty', () async {
      final store = await _createStore();
      const key = 'draft_edit';
      await store.write(
        key,
        PostComposeDraft(
          title: '기존',
          content: '기존 내용',
          imagePaths: const [],
          savedAt: DateTime.parse('2026-03-05T16:10:00.000Z'),
          projectCode: 'girls-band-cry',
        ),
      );

      final container = _createContainer(store);
      addTearDown(container.dispose);
      final notifier = container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(storageKey: key),
        ).notifier,
      );

      await notifier.saveSnapshot(
        title: '',
        content: '',
        imagePaths: const [],
        hasData: false,
      );

      final saved = await store.read(key);
      expect(saved, isNull);
    });

    test('schedules debounced save to storage', () async {
      final store = await _createStore();
      const key = 'draft_debounce';
      final container = _createContainer(store);
      addTearDown(container.dispose);
      final provider = postComposeAutosaveControllerProvider(
        const PostComposeAutosaveConfig(storageKey: key),
      );
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      final notifier = container.read(provider.notifier);

      notifier.scheduleSave(
        title: '디바운스 제목',
        content: '디바운스 내용',
        imagePaths: const ['/tmp/debounce.jpg'],
        topic: '일상',
        tags: const ['밴드'],
        hasData: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 1300));
      final saved = await store.read(key);

      expect(saved, isNotNull);
      expect(saved!.title, '디바운스 제목');
      expect(saved.topic, '일상');
      expect(saved.tags, ['밴드']);
    });

    test('consumeRecoverableDraft clears banner state', () async {
      final store = await _createStore();
      const key = 'draft_consume';
      await store.write(
        key,
        PostComposeDraft(
          title: '제목',
          content: '내용',
          imagePaths: const ['/tmp/path.jpg'],
          savedAt: DateTime.parse('2026-03-05T16:20:00.000Z'),
          projectCode: 'girls-band-cry',
        ),
      );

      final container = _createContainer(store);
      addTearDown(container.dispose);
      final provider = postComposeAutosaveControllerProvider(
        const PostComposeAutosaveConfig(storageKey: key),
      );
      final notifier = container.read(provider.notifier);

      await notifier.loadRecoverableDraft();
      notifier.consumeRecoverableDraft(message: '복구 완료');

      final state = container.read(provider);
      expect(state.recoverableDraft, isNull);
      expect(state.autosaveMessage, '복구 완료');
    });
  });
}

ProviderContainer _createContainer(PostComposeDraftStore store) {
  return ProviderContainer(
    overrides: [
      postComposeDraftStoreProvider.overrideWith((ref) async => store),
      selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
    ],
  );
}

Future<PostComposeDraftStore> _createStore() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return PostComposeDraftStore(
    LocalStorage(prefs),
    // EN: Freeze the store clock so fixed draft fixtures never age out.
    // KO: 고정 임시저장 픽스처가 시간 경과로 만료되지 않도록 시계를 고정합니다.
    now: () => DateTime.parse('2026-03-06T00:00:00.000Z'),
  );
}
