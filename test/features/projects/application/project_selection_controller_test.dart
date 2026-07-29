import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';
import 'package:oshi_log/features/projects/domain/repositories/projects_repository.dart';

void main() {
  const projects = <Project>[
    Project(
      id: 'project-a-id',
      code: 'project-a',
      name: 'Project A',
      status: 'ACTIVE',
      defaultTimezone: 'Asia/Tokyo',
    ),
    Project(
      id: 'project-b-id',
      code: 'project-b',
      name: 'Project B',
      status: 'ACTIVE',
      defaultTimezone: 'Asia/Tokyo',
    ),
  ];

  test(
    'user selection wins when stored selection resolves after the interaction',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.selectedProjectKey: 'project-a',
        LocalStorageKeys.selectedProjectId: 'project-a-id',
        LocalStorageKeys.selectedUnitIds: <String>['unit-a'],
      });
      final preferences = await SharedPreferences.getInstance();
      final storage = LocalStorage(preferences);
      final storageRead = Completer<LocalStorage>();
      final repository = _MockProjectsRepository();
      when(
        () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) async => const Success(projects));
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageRead.future),
          projectsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        projectSelectionControllerProvider.notifier,
      );
      final userSelection = controller.selectProject(
        'project-b',
        projectId: 'project-b-id',
      );

      expect(controller.state.projectKey, 'project-b');
      storageRead.complete(storage);
      await userSelection;
      await pumpEventQueue(times: 20);

      expect(controller.state.projectKey, 'project-b');
      expect(container.read(selectedProjectKeyProvider), 'project-b');
      expect(container.read(selectedProjectIdProvider), 'project-b-id');
      expect(container.read(selectedUnitIdsProvider), isEmpty);
      expect(storage.getSelectedProjectKey(), 'project-b');
      expect(storage.getSelectedProjectId(), 'project-b-id');
      expect(storage.getSelectedUnitIds(), isEmpty);
    },
  );

  test(
    'late persistence from an older selection cannot replace the latest',
    () async {
      final storage = _MockLocalStorage();
      final repository = _MockProjectsRepository();
      final repositoryRead = Completer<Result<List<Project>>>();
      final firstWriteStarted = Completer<void>();
      final releaseFirstWrite = Completer<void>();
      String? persistedProjectKey;
      String? persistedProjectId;
      List<String> persistedUnitIds = const [];

      when(storage.getSelectedProjectKey).thenReturn(null);
      when(storage.getSelectedProjectId).thenReturn(null);
      when(storage.getSelectedUnitIds).thenReturn(const []);
      when(() => storage.setSelectedProjectKey(any())).thenAnswer((call) async {
        final projectKey = call.positionalArguments.single as String;
        if (projectKey == 'project-a') {
          if (!firstWriteStarted.isCompleted) {
            firstWriteStarted.complete();
          }
          await releaseFirstWrite.future;
        }
        persistedProjectKey = projectKey;
        return true;
      });
      when(() => storage.setSelectedProjectId(any())).thenAnswer((call) async {
        persistedProjectId = call.positionalArguments.single as String;
        return true;
      });
      when(() => storage.setSelectedUnitIds(any())).thenAnswer((call) async {
        persistedUnitIds = List<String>.from(
          call.positionalArguments.single as List<String>,
        );
        return true;
      });
      when(
        () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
      ).thenAnswer((_) => repositoryRead.future);
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) async => storage),
          projectsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        projectSelectionControllerProvider.notifier,
      );
      final firstSelection = controller.selectProject(
        'project-a',
        projectId: 'project-a-id',
      );
      await firstWriteStarted.future;
      final latestSelection = controller.selectProject(
        'project-b',
        projectId: 'project-b-id',
      );
      await pumpEventQueue(times: 5);
      releaseFirstWrite.complete();
      await Future.wait([firstSelection, latestSelection]);
      await pumpEventQueue(times: 20);

      expect(controller.state.projectKey, 'project-b');
      expect(persistedProjectKey, 'project-b');
      expect(persistedProjectId, 'project-b-id');
      expect(persistedUnitIds, isEmpty);
    },
  );
}

class _MockLocalStorage extends Mock implements LocalStorage {}

class _MockProjectsRepository extends Mock implements ProjectsRepository {}
