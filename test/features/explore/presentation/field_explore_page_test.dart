import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_mode_dock.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_page.dart';
import 'package:girlsbandtabi_app/features/places/presentation/pages/places_map_page.dart';
import 'package:girlsbandtabi_app/features/projects/application/projects_controller.dart';
import 'package:girlsbandtabi_app/features/settings/application/settings_controller.dart';
import 'package:girlsbandtabi_app/features/visits/application/visits_controller.dart';

void main() {
  testWidgets('FieldExplorePage follows an updated initial tab index', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        userProfileControllerProvider.overrideWith(
          (ref) => _EmptyUserProfileController(ref),
        ),
        projectsControllerProvider.overrideWith(
          (ref) => _LoadingProjectsController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    Future<void> pumpExplore(int initialTabIndex) {
      return tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FieldExplorePage(
              key: const ValueKey('field-explore'),
              initialTabIndex: initialTabIndex,
            ),
          ),
        ),
      );
    }

    // EN: Start away from the map so this state-sync test remains isolated
    // EN: from map repositories and platform location services.
    // KO: 상태 동기화 테스트가 지도 저장소/플랫폼 위치 서비스와 분리되도록
    // KO: 지도 탭이 아닌 위치에서 시작합니다.
    await pumpExplore(3);
    expect(find.text('FIELD MAP'), findsNothing);
    expect(
      tester
          .widget<FieldExploreModeDock>(find.byType(FieldExploreModeDock))
          .selectedIndex,
      3,
    );
    final inactiveMap =
        tester.widget<TabBarView>(find.byType(TabBarView)).children.first
            as PlacesMapPage;
    expect(inactiveMap.isActive, isFalse);
    expect(inactiveMap.topOverlayClearance, 0);
    expect(inactiveMap.bottomInset, 0);
    expect(inactiveMap.modeLabels, const ['Map', 'Events', 'Visits', 'Stamps']);
    expect(inactiveMap.selectedModeIndex, 3);

    await pumpExplore(2);
    expect(
      tester
          .widget<FieldExploreModeDock>(find.byType(FieldExploreModeDock))
          .selectedIndex,
      2,
    );
  });

  testWidgets('Explore mode control stays at bottom on non-map pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        userProfileControllerProvider.overrideWith(
          (ref) => _EmptyUserProfileController(ref),
        ),
        projectsControllerProvider.overrideWith(
          (ref) => _LoadingProjectsController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FieldExplorePage(initialTabIndex: 3)),
      ),
    );

    final dockRect = tester.getRect(find.byType(FieldExploreModeDock));
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('field-explore-content')),
    );
    expect(dockRect.top, greaterThan(680));
    expect(dockRect.bottom, closeTo(772, 0.01));
    expect(contentRect.top, lessThanOrEqualTo(dockRect.top));
    expect(contentRect.bottom, 844);
    expect(
      find.byKey(const ValueKey('field-explore-bottom-mode-rail')),
      findsOneWidget,
    );
  });

  testWidgets('scaffold-injected navigation padding is not counted twice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        userProfileControllerProvider.overrideWith(
          (ref) => _EmptyUserProfileController(ref),
        ),
        projectsControllerProvider.overrideWith(
          (ref) => _LoadingProjectsController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 74),
            ),
            child: FieldExplorePage(initialTabIndex: 3),
          ),
        ),
      ),
    );

    final dockRect = tester.getRect(find.byType(FieldExploreModeDock));
    // EN: The inherited 74dp already contains the extended main navigation.
    // KO: 상속된 74dp에는 extendBody 하단 내비게이션 높이가 이미 포함됩니다.
    expect(dockRect.bottom, closeTo(762, 0.01));

    final map =
        tester.widget<TabBarView>(find.byType(TabBarView)).children.first
            as PlacesMapPage;
    expect(map.bottomInset, 74);
  });

  testWidgets('map bleeds edge to edge while embedded content stays safe', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        userProfileControllerProvider.overrideWith(
          (ref) => _EmptyUserProfileController(ref),
        ),
        projectsControllerProvider.overrideWith(
          (ref) => _LoadingProjectsController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    const cases = [
      (
        name: 'old-android-status-bar',
        size: Size(390, 844),
        insets: EdgeInsets.only(top: 24),
      ),
      (
        name: 'dynamic-island',
        size: Size(390, 844),
        insets: EdgeInsets.only(top: 59, bottom: 34),
      ),
      (
        name: 'landscape-cutout',
        size: Size(844, 390),
        insets: EdgeInsets.fromLTRB(59, 0, 59, 21),
      ),
    ];

    for (final testCase in cases) {
      tester.view.physicalSize = testCase.size;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            key: ValueKey(testCase.name),
            home: MediaQuery(
              data: MediaQueryData(
                size: testCase.size,
                padding: testCase.insets,
                viewPadding: testCase.insets,
              ),
              child: const FieldExplorePage(initialTabIndex: 3),
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.byKey(const ValueKey('field-explore-content'))),
        Offset.zero & testCase.size,
        reason: testCase.name,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('field-explore-safe-content-3')),
        ),
        Rect.fromLTRB(
          testCase.insets.left,
          testCase.insets.top,
          testCase.size.width - testCase.insets.right,
          testCase.size.height,
        ),
        reason: testCase.name,
      );
    }
  });

  testWidgets('map canvas and controls split full bleed from safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        currentNavIndexProvider.overrideWith((ref) => 0),
        userProfileControllerProvider.overrideWith(
          (ref) => _EmptyUserProfileController(ref),
        ),
        projectsControllerProvider.overrideWith(
          (ref) => _LoadingProjectsController(ref),
        ),
        userVisitsControllerProvider.overrideWith(
          (ref) => _EmptyVisitsController(ref),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.fromLTRB(12, 59, 14, 74),
              viewPadding: EdgeInsets.fromLTRB(12, 59, 14, 34),
            ),
            child: FieldExplorePage(),
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(const Key('field-map-canvas'))),
      const Rect.fromLTWH(0, 0, 390, 844),
    );
    final searchRect = tester.getRect(
      find.byKey(const Key('field-map-mission-strip')),
    );
    expect(searchRect.top, greaterThanOrEqualTo(63));
    expect(searchRect.left, greaterThanOrEqualTo(28));
    expect(searchRect.right, lessThanOrEqualTo(360));
    expect(
      tester.getRect(find.byKey(const Key('field-map-current-location'))).right,
      lessThanOrEqualTo(360),
    );
    final sheetContentRect = tester.getRect(
      find.byKey(const Key('field-map-sheet-safe-content')),
    );
    expect(sheetContentRect.left, 12);
    expect(sheetContentRect.right, 376);
    expect(sheetContentRect.bottom, 770);
    expect(
      tester.getRect(find.byKey(const Key('field-map-sheet-surface'))).bottom,
      770,
    );
    expect(tester.takeException(), isNull);
  });
}

class _EmptyUserProfileController extends UserProfileController {
  _EmptyUserProfileController(super.ref) {
    state = const AsyncData(null);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _LoadingProjectsController extends ProjectsController {
  _LoadingProjectsController(super.ref);

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _EmptyVisitsController extends UserVisitsController {
  _EmptyVisitsController(super.ref) {
    state = const AsyncData([]);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}
