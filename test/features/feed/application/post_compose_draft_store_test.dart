import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/feed/application/post_compose_draft_store.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PostComposeDraft', () {
    test('fromJson restores valid payload', () {
      final draft = PostComposeDraft.fromJson({
        'title': '제목',
        'content': '내용',
        'imagePaths': ['/tmp/a.jpg', '/tmp/b.webp'],
        'savedAt': '2026-03-05T15:40:00.000Z',
        'projectCode': 'girls-band-cry',
        'topic': '정보',
        'tags': ['라이브', '굿즈'],
      });

      expect(draft, isNotNull);
      expect(draft!.title, '제목');
      expect(draft.content, '내용');
      expect(draft.imagePaths, ['/tmp/a.jpg', '/tmp/b.webp']);
      expect(draft.projectCode, 'girls-band-cry');
      expect(draft.topic, '정보');
      expect(draft.tags, ['라이브', '굿즈']);
      expect(draft.isEmpty, isFalse);
    });

    test('fromJson returns null when savedAt is invalid', () {
      final draft = PostComposeDraft.fromJson({
        'title': '제목',
        'content': '내용',
        'imagePaths': ['/tmp/a.jpg'],
        'savedAt': 'invalid-datetime',
      });

      expect(draft, isNull);
    });

    test('toJson keeps fields needed for roundtrip', () {
      final original = PostComposeDraft(
        title: '제목',
        content: '내용',
        imagePaths: const ['/tmp/a.jpg'],
        savedAt: DateTime.parse('2026-03-05T15:40:00.000Z'),
        projectCode: 'girls-band-cry',
        topic: '질문',
        tags: const ['태그1', '태그2'],
      );

      final restored = PostComposeDraft.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.title, original.title);
      expect(restored.content, original.content);
      expect(restored.imagePaths, original.imagePaths);
      expect(restored.projectCode, original.projectCode);
      expect(restored.topic, original.topic);
      expect(restored.tags, original.tags);
      expect(
        restored.savedAt.toUtc().toIso8601String(),
        original.savedAt.toUtc().toIso8601String(),
      );
    });
  });

  group('PostComposeDraftStore', () {
    test('read removes expired draft and returns null', () async {
      final now = DateTime.parse('2026-03-12T09:00:00.000Z');
      final harness = await _createStore(
        now: () => now,
        retention: const Duration(days: 7),
      );
      final store = harness.store;
      final storage = harness.storage;

      const key = 'feed_post_create_draft_v1';
      await store.write(
        key,
        PostComposeDraft(
          title: '오래된 제목',
          content: '오래된 내용',
          imagePaths: const ['/tmp/old.jpg'],
          savedAt: now.subtract(const Duration(days: 8)),
          projectCode: 'girls-band-cry',
        ),
      );

      final restored = await store.read(key);

      expect(restored, isNull);
      expect(storage.containsKey(key), isFalse);
    });
  });
}

Future<({PostComposeDraftStore store, LocalStorage storage})> _createStore({
  DateTime Function()? now,
  Duration? retention,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);
  return (
    store: PostComposeDraftStore(
      storage,
      now: now,
      retention: retention ?? const Duration(days: 7),
    ),
    storage: storage,
  );
}
