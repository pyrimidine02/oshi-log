import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oshi_log/platform/router/navigation_state.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/repositories/places_repository.dart';

class _Repository extends Mock implements PlacesRepository {}

void main() {
  test(
    'area search uses viewport bounds and clears conflicting region mode',
    () async {
      final repository = _Repository();
      when(
        () => repository.getPlacesByRegionFilter(
          projectId: 'project',
          regionCodes: ['JP-13'],
          unitIds: ['band'],
        ),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => repository.getPlacesWithinBounds(
          projectId: 'project',
          swLat: 35,
          swLng: 139,
          neLat: 36,
          neLng: 140,
          unitIds: ['band'],
          forceRefresh: true,
        ),
      ).thenAnswer((_) async => const Result.success([]));
      final container = ProviderContainer(
        overrides: [
          placesRepositoryProvider.overrideWith((_) async => repository),
          selectedProjectKeyProvider.overrideWith((_) => 'project'),
          selectedProjectIdProvider.overrideWith((_) => 'project'),
          currentNavIndexProvider.overrideWith((_) => NavIndex.map),
          selectedPlaceRegionCodesProvider.overrideWith((_) => ['JP-13']),
          selectedPlaceBandIdsProvider.overrideWith((_) => ['band']),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(placesListControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.searchBounds((
        south: 35,
        west: 139,
        north: 36,
        east: 140,
      ));
      expect(container.read(selectedPlaceRegionCodesProvider), isEmpty);
      expect(container.read(selectedPlaceBandIdsProvider), ['band']);
      expect(container.read(selectedPlaceBoundsProvider), isNotNull);
      verify(
        () => repository.getPlacesWithinBounds(
          projectId: 'project',
          swLat: 35,
          swLng: 139,
          neLat: 36,
          neLng: 140,
          unitIds: ['band'],
          forceRefresh: true,
        ),
      ).called(1);
      controller.resetFilters(reload: false);
      expect(container.read(selectedPlaceBoundsProvider), isNull);
    },
  );
}
