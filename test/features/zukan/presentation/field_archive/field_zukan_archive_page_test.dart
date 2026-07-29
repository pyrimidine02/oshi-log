import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';
import 'package:oshi_log/features/projects/domain/repositories/projects_repository.dart';
import 'package:oshi_log/features/zukan/application/zukan_controller.dart';
import 'package:oshi_log/features/zukan/domain/entities/zukan_collection.dart';
import 'package:oshi_log/features/zukan/presentation/field_archive/field_zukan_archive_page.dart';

void main() {
  const collections = [
    ZukanCollectionSummary(
      id: 'route-notes',
      title: '가와사키 로케이션 노트',
      totalCount: 5,
      stampedCount: 3,
      projectId: 'girls-band-cry',
      description: '작품 속 이동 동선을 따라 기록하는 표본집',
      sortOrder: 1,
    ),
    ZukanCollectionSummary(
      id: 'station-index',
      title: '역과 광장 색인',
      totalCount: 4,
      stampedCount: 4,
      projectId: 'girls-band-cry',
      isCompleted: true,
      sortOrder: 2,
    ),
    ZukanCollectionSummary(
      id: 'night-scenes',
      title: '야간 장면 표본',
      totalCount: 6,
      stampedCount: 0,
      projectId: 'girls-band-cry',
      sortOrder: 3,
    ),
  ];

  testWidgets('scopes the archive to the selected project and uses an index', (
    tester,
  ) async {
    String? requestedProject;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
          zukanCollectionsProvider.overrideWith((ref, projectId) {
            requestedProject = projectId;
            return Future.value(collections);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          home: const FieldZukanArchivePage(embedded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedProject, 'girls-band-cry');
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('여행 표본 아카이브'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('field-zukan-featured-route-notes')),
      findsOneWidget,
    );
    expect(find.text('7 / 15'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field-zukan-row-station-index')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('field-zukan-row-station-index')),
      findsOneWidget,
    );
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the existing named zukan detail route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const FieldZukanArchivePage(embedded: true),
        ),
        GoRoute(
          path: '/zukan/:collectionId',
          name: AppRoutes.zukanDetail,
          builder: (_, state) => Scaffold(
            body: Text('detail:${state.pathParameters['collectionId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
          zukanCollectionsProvider.overrideWith(
            (ref, _) => Future.value(collections),
          ),
        ],
        child: MaterialApp.router(theme: GBTTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field-zukan-row-station-index')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('field-zukan-row-station-index')),
    );
    await tester.pumpAndSettle();

    expect(find.text('detail:station-index'), findsOneWidget);
  });

  testWidgets('remains usable at 320dp with 200 percent text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
          zukanCollectionsProvider.overrideWith(
            (ref, _) => Future.value(collections),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(2),
            ),
            child: FieldZukanArchivePage(embedded: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRAVEL SPECIMEN ARCHIVE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field-zukan-row-station-index')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('field-zukan-row-station-index')))
          .height,
      greaterThanOrEqualTo(64),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses blue for action and teal for completed specimens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedProjectKeyProvider.overrideWith((ref) => 'girls-band-cry'),
          zukanCollectionsProvider.overrideWith(
            (ref, _) => Future.value(collections),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.dark,
          home: const FieldZukanArchivePage(embedded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final actionIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('field-zukan-featured-action-icon')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field-zukan-complete-station-index')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    final completedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('field-zukan-complete-station-index')),
    );
    expect(actionIcon.color, GBTColors.darkPrimary);
    expect(completedIcon.color, GBTColors.darkSecondary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for project context instead of requesting all projects', (
    tester,
  ) async {
    var requestCount = 0;
    final storageRead = Completer<LocalStorage>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageRead.future),
          selectedProjectKeyProvider.overrideWith((ref) => null),
          selectedProjectIdProvider.overrideWith((ref) => null),
          projectsControllerProvider.overrideWith(
            (ref) => _LoadingProjectsController(ref),
          ),
          zukanCollectionsProvider.overrideWith((ref, _) {
            requestCount += 1;
            return Future.value(collections);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          home: const FieldZukanArchivePage(embedded: true),
        ),
      ),
    );
    await tester.pump();

    expect(requestCount, 0);
    expect(find.text('표본 색인을 열고 있어요'), findsOneWidget);
  });

  testWidgets('shows an empty project state instead of loading forever', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalStorage(preferences);
    final repository = _MockProjectsRepository();
    var requestCount = 0;
    when(
      () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Success(<Project>[]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith((ref) async => storage),
          projectsRepositoryProvider.overrideWith((ref) async => repository),
          zukanCollectionsProvider.overrideWith((ref, _) {
            requestCount += 1;
            return Future.value(collections);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          home: const FieldZukanArchivePage(embedded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('선택할 프로젝트가 없어요'), findsOneWidget);
    expect(find.text('표본 색인을 열고 있어요'), findsNothing);
    expect(requestCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offers project choice when stored selection cannot be restored',
    (tester) async {
      final repository = _MockProjectsRepository();
      String? requestedProject;
      when(
        () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer(
        (_) async => const Success(<Project>[
          Project(
            id: 'project-1',
            code: 'girls-band-cry',
            name: 'Girls Band Cry',
            status: 'ACTIVE',
            defaultTimezone: 'Asia/Tokyo',
          ),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWith(
              (ref) =>
                  Future<LocalStorage>.error(StateError('storage unavailable')),
            ),
            projectsRepositoryProvider.overrideWith((ref) async => repository),
            zukanCollectionsProvider.overrideWith((ref, projectId) {
              requestedProject = projectId;
              return Future.value(collections);
            }),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
            theme: GBTTheme.light,
            home: const FieldZukanArchivePage(embedded: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('도감을 열 프로젝트를 선택해 주세요'), findsOneWidget);
      expect(find.text('프로젝트 선택'), findsOneWidget);

      await tester.tap(find.text('프로젝트 선택'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('field-project-row-project-1')),
      );
      await tester.pumpAndSettle();

      expect(requestedProject, 'girls-band-cry');
      expect(find.text('여행 표본 아카이브'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restores project context when archive opens directly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.selectedProjectKey: 'girls-band-cry',
      LocalStorageKeys.selectedProjectId: 'project-1',
      LocalStorageKeys.selectedUnitIds: <String>[],
    });
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalStorage(preferences);
    final repository = _MockProjectsRepository();
    String? requestedProject;
    when(
      () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => const Success(<Project>[
        Project(
          id: 'project-1',
          code: 'girls-band-cry',
          name: 'Girls Band Cry',
          status: 'ACTIVE',
          defaultTimezone: 'Asia/Tokyo',
        ),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith((ref) async => storage),
          projectsRepositoryProvider.overrideWith((ref) async => repository),
          zukanCollectionsProvider.overrideWith((ref, projectId) {
            requestedProject = projectId;
            return Future.value(collections);
          }),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          home: const FieldZukanArchivePage(embedded: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedProject, 'girls-band-cry');
    expect(find.text('여행 표본 아카이브'), findsOneWidget);
  });
}

class _MockProjectsRepository extends Mock implements ProjectsRepository {}

class _LoadingProjectsController extends ProjectsController {
  _LoadingProjectsController(super.ref);

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}
