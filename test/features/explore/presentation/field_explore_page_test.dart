import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_mode_dock.dart';
import 'package:girlsbandtabi_app/features/explore/presentation/field_explore/field_explore_page.dart';
import 'package:girlsbandtabi_app/features/places/presentation/pages/places_map_page.dart';
import 'package:girlsbandtabi_app/features/projects/application/projects_controller.dart';
import 'package:girlsbandtabi_app/features/settings/application/settings_controller.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_spacing.dart';

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

    await pumpExplore(2);
    expect(
      tester
          .widget<FieldExploreModeDock>(find.byType(FieldExploreModeDock))
          .selectedIndex,
      2,
    );
  });

  testWidgets('Explore modes float above main navigation without a top rail', (
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
    expect(dockRect.top, greaterThan(844 / 2));
    expect(
      dockRect.bottom,
      lessThanOrEqualTo(844 - GBTSpacing.bottomNavHeight - GBTSpacing.sm),
    );
    expect(contentRect.bottom, lessThanOrEqualTo(dockRect.top - GBTSpacing.sm));
    expect(
      find.byKey(const ValueKey('field-explore-top-mode-rail')),
      findsNothing,
    );
  });

  testWidgets('Scaffold-injected bottom padding is not counted twice', (
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
    expect(dockRect.bottom, closeTo(844 - 74 - GBTSpacing.sm, 0.01));
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
