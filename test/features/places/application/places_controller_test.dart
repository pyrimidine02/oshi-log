import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/places/application/places_controller.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_entities.dart';
import 'package:girlsbandtabi_app/features/places/domain/entities/place_region_entities.dart';
import 'package:girlsbandtabi_app/features/places/domain/repositories/places_repository.dart';

void main() {
  group('PlacesListController', () {
    test('keeps loading state when project is not selected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(placesListControllerProvider.notifier);
      await notifier.load();

      final state = container.read(placesListControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.hasError, isFalse);
      expect(state.hasValue, isFalse);
    });

    test(
      'project transition clears filters as one batch before requesting',
      () async {
        final repository = _DeferredPlacesRepository()
          ..completeFiltered('project-a', const <PlaceSummary>[])
          ..deferList('project-b')
          ..completeList('project-b', <PlaceSummary>[
            _place('place-b', 'Project B place'),
          ]);
        final container = _container(
          repository,
          projectKey: 'project-a',
          regionCodes: const <String>['JP-13'],
          bandIds: const <String>['band-a'],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          placesListControllerProvider,
          (_, __) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        await _flushEventQueue();

        container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
        await _flushEventQueue();

        expect(container.read(selectedPlaceRegionCodesProvider), isEmpty);
        expect(container.read(selectedPlaceBandIdsProvider), isEmpty);
        expect(
          repository.calls.where((call) => call.projectId == 'project-b'),
          hasLength(1),
        );
        expect(
          repository.calls.singleWhere((call) => call.projectId == 'project-b'),
          const _ListCall(
            projectId: 'project-b',
            regionCodes: <String>[],
            bandIds: <String>[],
          ),
        );
      },
    );

    test('late project A response cannot overwrite project B', () async {
      final repository = _DeferredPlacesRepository()
        ..deferList('project-a')
        ..deferList('project-b');
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        placesListControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await _flushEventQueue();

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _flushEventQueue();
      repository.completeList('project-b', <PlaceSummary>[
        _place('place-b', 'Project B place'),
      ]);
      await _flushEventQueue();
      expect(
        container.read(placesListControllerProvider).valueOrNull?.single.id,
        'place-b',
      );

      repository.completeList('project-a', <PlaceSummary>[
        _place('place-a', 'Project A place'),
      ]);
      await _flushEventQueue();

      expect(
        container.read(placesListControllerProvider).valueOrNull?.single.id,
        'place-b',
      );
    });
  });

  group('PlacesRegionOptionsController', () {
    test('late project A options cannot overwrite project B', () async {
      final repository = _DeferredPlacesRepository()
        ..deferRegions('project-a')
        ..deferRegions('project-b');
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        placesRegionOptionsControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await _flushEventQueue();

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _flushEventQueue();
      repository.completeRegions(
        'project-b',
        _regionOptions('project-b-region'),
      );
      await _flushEventQueue();
      expect(
        container
            .read(placesRegionOptionsControllerProvider)
            .valueOrNull
            ?.popularRegions
            .single
            .code,
        'project-b-region',
      );

      repository.completeRegions(
        'project-a',
        _regionOptions('project-a-region'),
      );
      await _flushEventQueue();

      expect(
        container
            .read(placesRegionOptionsControllerProvider)
            .valueOrNull
            ?.popularRegions
            .single
            .code,
        'project-b-region',
      );
    });
  });

  group('PlaceDetailController project boundary', () {
    test('late project A detail cannot overwrite project B', () async {
      final repository = _DeferredPlacesRepository()
        ..deferDetail('project-a')
        ..deferDetail('project-b');
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        placeDetailControllerProvider('place-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _flushEventQueue();
      expect(repository.detailRequest('project-a'), isNotNull);

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _flushEventQueue();
      expect(repository.detailRequest('project-b'), isNotNull);

      repository.completeDetail('project-b', _placeDetail('project-b'));
      await _flushEventQueue();
      expect(
        container
            .read(placeDetailControllerProvider('place-1'))
            .valueOrNull
            ?.name,
        'Place for project-b',
      );

      repository.completeDetail('project-a', _placeDetail('project-a'));
      await _flushEventQueue();

      expect(
        container
            .read(placeDetailControllerProvider('place-1'))
            .valueOrNull
            ?.name,
        'Place for project-b',
      );
    });
  });
}

ProviderContainer _container(
  PlacesRepository repository, {
  required String projectKey,
  List<String> regionCodes = const <String>[],
  List<String> bandIds = const <String>[],
}) {
  return ProviderContainer(
    overrides: <Override>[
      placesRepositoryProvider.overrideWith((ref) async => repository),
      currentNavIndexProvider.overrideWith((ref) => 1),
      selectedProjectKeyProvider.overrideWith((ref) => projectKey),
      selectedPlaceRegionCodesProvider.overrideWith((ref) => regionCodes),
      selectedPlaceBandIdsProvider.overrideWith((ref) => bandIds),
    ],
  );
}

Future<void> _flushEventQueue() async {
  for (var index = 0; index < 8; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

PlaceSummary _place(String id, String name) {
  return PlaceSummary(
    id: id,
    name: name,
    address: 'Tokyo',
    latitude: 35.0,
    longitude: 139.0,
  );
}

PlaceDetail _placeDetail(String projectId) {
  return PlaceDetail(
    id: 'place-1',
    name: 'Place for $projectId',
    address: 'Tokyo',
    types: const [],
  );
}

RegionFilterOptions _regionOptions(String code) {
  return RegionFilterOptions(
    countries: const <RegionOption>[],
    popularRegions: <RegionOption>[
      RegionOption(
        code: code,
        name: code,
        level: 1,
        placeCount: 1,
        hasChildren: false,
        displayOrder: 0,
      ),
    ],
    totalRegions: 1,
    totalPlaces: 1,
    lastUpdated: '',
  );
}

class _DeferredPlacesRepository implements PlacesRepository {
  final Map<String, Completer<Result<List<PlaceSummary>>>> _listRequests = {};
  final Map<String, Completer<Result<List<PlaceSummary>>>> _filteredRequests =
      {};
  final Map<String, Completer<Result<RegionFilterOptions>>> _regionRequests =
      {};
  final Map<String, Completer<Result<PlaceDetail>>> _detailRequests = {};
  final List<_ListCall> calls = <_ListCall>[];

  void deferList(String projectId) {
    _listRequests.putIfAbsent(projectId, Completer.new);
  }

  void completeList(String projectId, List<PlaceSummary> places) {
    final completer = _listRequests.putIfAbsent(projectId, Completer.new);
    if (!completer.isCompleted) {
      completer.complete(Result<List<PlaceSummary>>.success(places));
    }
  }

  void completeFiltered(String projectId, List<PlaceSummary> places) {
    final completer = _filteredRequests.putIfAbsent(projectId, Completer.new);
    if (!completer.isCompleted) {
      completer.complete(Result<List<PlaceSummary>>.success(places));
    }
  }

  void deferRegions(String projectId) {
    _regionRequests.putIfAbsent(projectId, Completer.new);
  }

  void completeRegions(String projectId, RegionFilterOptions options) {
    final completer = _regionRequests.putIfAbsent(projectId, Completer.new);
    if (!completer.isCompleted) {
      completer.complete(Result<RegionFilterOptions>.success(options));
    }
  }

  void deferDetail(String projectId) {
    _detailRequests.putIfAbsent(projectId, Completer.new);
  }

  Completer<Result<PlaceDetail>>? detailRequest(String projectId) {
    return _detailRequests[projectId];
  }

  void completeDetail(String projectId, PlaceDetail detail) {
    final completer = _detailRequests.putIfAbsent(projectId, Completer.new);
    if (!completer.isCompleted) {
      completer.complete(Result<PlaceDetail>.success(detail));
    }
  }

  @override
  Future<Result<List<PlaceSummary>>> getAllPlaces({
    required String projectId,
    List<String> unitIds = const <String>[],
    bool forceRefresh = false,
  }) {
    calls.add(
      _ListCall(
        projectId: projectId,
        regionCodes: const <String>[],
        bandIds: List<String>.unmodifiable(unitIds),
      ),
    );
    return _listRequests.putIfAbsent(projectId, Completer.new).future;
  }

  @override
  Future<Result<List<PlaceSummary>>> getPlacesByRegionFilter({
    required String projectId,
    required List<String> regionCodes,
    bool includeChildren = true,
    List<String> placeTypes = const <String>[],
    List<String> unitIds = const <String>[],
    int page = 0,
    int size = 20,
    List<String> sort = const <String>[],
  }) {
    calls.add(
      _ListCall(
        projectId: projectId,
        regionCodes: List<String>.unmodifiable(regionCodes),
        bandIds: List<String>.unmodifiable(unitIds),
      ),
    );
    return _filteredRequests.putIfAbsent(projectId, Completer.new).future;
  }

  @override
  Future<Result<RegionFilterOptions>> getRegionFilterOptions({
    required String projectId,
    String language = 'ko',
    int minPlaceCount = 1,
    bool hierarchical = true,
    bool forceRefresh = false,
  }) {
    return _regionRequests.putIfAbsent(projectId, Completer.new).future;
  }

  @override
  Future<Result<PlaceDetail>> getPlaceDetail({
    required String projectId,
    required String placeId,
    bool forceRefresh = false,
  }) {
    return _detailRequests.putIfAbsent(projectId, Completer.new).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ListCall {
  const _ListCall({
    required this.projectId,
    required this.regionCodes,
    required this.bandIds,
  });

  final String projectId;
  final List<String> regionCodes;
  final List<String> bandIds;

  @override
  bool operator ==(Object other) {
    return other is _ListCall &&
        other.projectId == projectId &&
        _sameStrings(other.regionCodes, regionCodes) &&
        _sameStrings(other.bandIds, bandIds);
  }

  @override
  int get hashCode => Object.hash(
    projectId,
    Object.hashAll(regionCodes),
    Object.hashAll(bandIds),
  );
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
