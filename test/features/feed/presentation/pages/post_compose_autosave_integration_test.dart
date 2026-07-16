import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:girlsbandtabi_app/core/config/app_config.dart';
import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/storage/local_storage.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/feed/application/post_compose_autosave_controller.dart';
import 'package:girlsbandtabi_app/features/feed/application/post_compose_draft_store.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/post_create_page.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/post_edit_page.dart';
import 'package:girlsbandtabi_app/features/projects/application/projects_controller.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';
import 'package:girlsbandtabi_app/features/projects/domain/repositories/projects_repository.dart';

void main() {
  group('Post compose autosave integration', () {
    testWidgets(
      'create page uses solid field-note chrome at 320dp and 200 percent text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = await _createHarness();
        addTearDown(harness.container.dispose);

        await tester.pumpWidget(
          harness.wrap(
            const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 720),
                textScaler: TextScaler.linear(2),
              ),
              child: PostCreatePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('새 여행 기록'), findsOneWidget);
        final submit = find.byKey(const ValueKey('post-compose-submit'));
        expect(submit, findsOneWidget);
        expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 1300));
      },
    );

    testWidgets(
      'edit page keeps a 48dp submit action at 320dp and large text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = await _createHarness();
        addTearDown(harness.container.dispose);

        await tester.pumpWidget(
          harness.wrap(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 720),
                textScaler: TextScaler.linear(2),
              ),
              child: PostEditPage(
                post: PostDetail(
                  id: 'post-field-note',
                  projectId: '550e8400-e29b-41d4-a716-446655440001',
                  authorId: '243701ba-86d8-4356-9c17-630944e2ed8f',
                  title: '원본 제목',
                  content: '원본 내용',
                  createdAt: DateTime(2026, 3, 5),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('여행 기록 수정'), findsOneWidget);
        final submit = find.byKey(const ValueKey('post-compose-submit'));
        expect(submit, findsOneWidget);
        expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 1300));
      },
    );

    testWidgets('create page reflects autosave status message from provider', (
      tester,
    ) async {
      final harness = await _createHarness();
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(harness.wrap(const PostCreatePage()));
      await tester.pumpAndSettle();

      final notifier = harness.container.read(
        postComposeAutosaveControllerProvider(
          const PostComposeAutosaveConfig(
            storageKey: 'feed_post_create_draft_v1',
          ),
        ).notifier,
      );
      await notifier.saveSnapshot(
        title: '상태 테스트',
        content: '작성 내용',
        imagePaths: const [],
        hasData: true,
      );

      await tester.pump();
      expect(find.textContaining('임시 저장됨 ·'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
    });

    testWidgets('create page restores recoverable draft via banner action', (
      tester,
    ) async {
      final harness = await _createHarness();
      addTearDown(harness.container.dispose);
      await harness.store.write(
        'feed_post_create_draft_v1',
        PostComposeDraft(
          title: '복구된 제목',
          content: '복구된 내용',
          imagePaths: const [],
          savedAt: DateTime.parse('2026-03-05T12:00:00.000Z'),
          projectCode: 'girls-band-cry',
        ),
      );

      await tester.pumpWidget(harness.wrap(const PostCreatePage()));
      await tester.pumpAndSettle();

      expect(find.text('임시 저장된 글이 있어요'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '복구'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1300));

      expect(find.text('임시 저장된 글이 있어요'), findsNothing);
      expect(find.text('복구된 제목'), findsOneWidget);
      expect(find.text('복구된 내용'), findsOneWidget);
      expect(find.textContaining('임시 저장 글을 복구했어요'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 1300));
    });

    testWidgets('edit page delete action clears recoverable draft and banner', (
      tester,
    ) async {
      final harness = await _createHarness();
      addTearDown(harness.container.dispose);

      const postId = 'post-001';
      final draftKey = 'feed_post_edit_draft_v1_$postId';
      await harness.store.write(
        draftKey,
        PostComposeDraft(
          title: '수정 임시 제목',
          content: '수정 임시 내용',
          imagePaths: const [],
          savedAt: DateTime.parse('2026-03-05T12:10:00.000Z'),
          projectCode: 'girls-band-cry',
        ),
      );

      await tester.pumpWidget(
        harness.wrap(
          PostEditPage(
            post: PostDetail(
              id: postId,
              projectId: '550e8400-e29b-41d4-a716-446655440001',
              authorId: '243701ba-86d8-4356-9c17-630944e2ed8f',
              title: '원본 제목',
              content: '원본 내용',
              createdAt: DateTime.parse('2026-03-05T11:50:00.000Z'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('임시 저장된 글이 있어요'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pumpAndSettle();

      expect(find.text('임시 저장된 글이 있어요'), findsNothing);
      expect(await harness.store.read(draftKey), isNull);
      await tester.pump(const Duration(milliseconds: 1300));
    });
  });
}

class _Harness {
  _Harness({required this.container, required this.store});

  final ProviderContainer container;
  final PostComposeDraftStore store;

  Widget wrap(Widget child) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    );
  }
}

Future<_Harness> _createHarness() async {
  AppConfig.instance.init(
    environment: Environment.development,
    baseUrl: 'http://localhost:8080',
  );
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorage(prefs);
  final store = PostComposeDraftStore(
    localStorage,
    // EN: Keep the fixed March fixtures inside the 30-day recovery window.
    // KO: 고정된 3월 픽스처가 30일 복구 기간 안에 있도록 시계를 고정합니다.
    now: () => DateTime.parse('2026-03-06T00:00:00.000Z'),
  );
  final projectsRepository = _FakeProjectsRepository(const [
    Project(
      id: '550e8400-e29b-41d4-a716-446655440001',
      code: 'girls-band-cry',
      name: '걸즈 밴드 크라이',
      status: 'ACTIVE',
      defaultTimezone: 'Asia/Seoul',
    ),
  ]);

  final container = ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWith((ref) => true),
      selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
      selectedProjectIdProvider.overrideWith(
        (ref) => '550e8400-e29b-41d4-a716-446655440001',
      ),
      localStorageProvider.overrideWith((ref) async => localStorage),
      postComposeDraftStoreProvider.overrideWith((ref) async => store),
      projectsRepositoryProvider.overrideWith(
        (ref) async => projectsRepository,
      ),
    ],
  );

  return _Harness(container: container, store: store);
}

class _FakeProjectsRepository implements ProjectsRepository {
  const _FakeProjectsRepository(this._projects);

  final List<Project> _projects;

  @override
  Future<Result<List<Project>>> getProjects({bool forceRefresh = false}) async {
    return Success(_projects);
  }

  @override
  Future<Result<List<Unit>>> getUnits({
    required String projectId,
    bool forceRefresh = false,
  }) async {
    return const Success(<Unit>[]);
  }

  @override
  Future<Result<Unit>> getUnitDetail({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  }) async {
    return Success(
      Unit(
        id: unitIdentifier,
        code: unitIdentifier,
        displayName: unitIdentifier,
      ),
    );
  }

  @override
  Future<Result<List<UnitMember>>> getUnitMembers({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  }) async {
    return const Success(<UnitMember>[]);
  }

  @override
  Future<Result<UnitMember>> getUnitMemberDetail({
    required String projectId,
    required String unitIdentifier,
    required String memberId,
    bool forceRefresh = false,
  }) async {
    return Success(UnitMember(id: memberId, name: 'member'));
  }

  @override
  Future<Result<List<VoiceActorListItem>>> searchVoiceActors({
    required String projectId,
    String query = '',
    int page = 0,
    int size = 20,
    String? sort,
    bool forceRefresh = false,
  }) async {
    return const Success(<VoiceActorListItem>[]);
  }

  @override
  Future<Result<VoiceActorDetail>> getVoiceActorDetail({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    return Success(
      VoiceActorDetail(id: voiceActorId, displayName: 'voice-actor'),
    );
  }

  @override
  Future<Result<List<VoiceActorMemberSummary>>> getVoiceActorMembers({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    return const Success(<VoiceActorMemberSummary>[]);
  }

  @override
  Future<Result<List<VoiceActorCreditSummary>>> getVoiceActorCredits({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    return const Success(<VoiceActorCreditSummary>[]);
  }
}
