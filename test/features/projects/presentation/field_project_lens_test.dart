import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/storage/local_storage.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/projects/application/projects_controller.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';
import 'package:girlsbandtabi_app/features/projects/domain/repositories/projects_repository.dart';
import 'package:girlsbandtabi_app/features/projects/presentation/widgets/field_project_lens.dart';

void main() {
  testWidgets('lens leaves initial project ownership to selection controller', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = _MockLocalStorage();
    final repository = _MockProjectsRepository();
    late _RecordingProjectSelectionController selectionController;
    when(storage.getSelectedProjectKey).thenReturn(null);
    when(storage.getSelectedProjectId).thenReturn(null);
    when(storage.getSelectedUnitIds).thenReturn(const []);
    when(
      () => repository.getProjects(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Success(<Project>[]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWith((ref) async => storage),
          projectsRepositoryProvider.overrideWith((ref) async => repository),
          projectsControllerProvider.overrideWith(
            (ref) => _SeededProjectsController(ref),
          ),
          projectSelectionControllerProvider.overrideWith((ref) {
            selectionController = _RecordingProjectSelectionController(ref);
            return selectionController;
          }),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: FieldProjectLens()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Girls Band Cry'), findsOneWidget);
    expect(find.text('TRAVEL CONTEXT'), findsOneWidget);
    expect(find.text('SWITCH'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('field-project-lens-control')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(
      find.bySemanticsLabel('Current project Girls Band Cry'),
      findsOneWidget,
    );
    final lensNode = tester.getSemantics(
      find.bySemanticsLabel('Current project Girls Band Cry'),
    );
    expect(lensNode.flagsCollection.isButton, isTrue);
    expect(lensNode.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(
      lensNode.getSemanticsData().hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    expect(selectionController.selectCalls, 0);

    await tester.tap(find.bySemanticsLabel('Current project Girls Band Cry'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you want to travel?'), findsOneWidget);

    final currentProjectRow = find.byKey(
      const ValueKey('field-project-row-project-1'),
    );
    await tester.ensureVisible(currentProjectRow);
    await tester.pumpAndSettle();
    await tester.tap(currentProjectRow);
    await tester.pumpAndSettle();

    // EN: Selecting the current context closes the sheet without a write.
    // KO: 현재 컨텍스트를 다시 선택하면 저장 호출 없이 시트만 닫힙니다.
    expect(selectionController.selectCalls, 0);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _RecordingProjectSelectionController extends ProjectSelectionController {
  _RecordingProjectSelectionController(super.ref);

  int selectCalls = 0;

  @override
  Future<void> selectProject(String? projectKey, {String? projectId}) async {
    selectCalls += 1;
  }
}

class _SeededProjectsController extends ProjectsController {
  _SeededProjectsController(super.ref) {
    state = const AsyncData([
      Project(
        id: 'project-1',
        code: 'girls-band-cry',
        name: 'Girls Band Cry',
        status: 'ACTIVE',
        defaultTimezone: 'Asia/Tokyo',
      ),
    ]);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _MockLocalStorage extends Mock implements LocalStorage {}

class _MockProjectsRepository extends Mock implements ProjectsRepository {}
