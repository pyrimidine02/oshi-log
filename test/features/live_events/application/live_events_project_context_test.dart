import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/connectivity/connectivity_service.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/application/pending_live_attendance_mutation.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/domain/repositories/live_events_repository.dart';

void main() {
  group('resolveLiveEventProjectContext', () {
    test('prefers a selected project id included in a multi-project event', () {
      final resolved = resolveLiveEventProjectContext(
        eventProjectIds: const ['project-a', 'project-b'],
        selectedProjectKey: 'project-b-code',
        selectedProjectId: 'project-b',
      );

      expect(resolved, 'project-b');
    });

    test('falls back to the first non-empty event project', () {
      final resolved = resolveLiveEventProjectContext(
        eventProjectIds: const ['', 'project-a', 'project-b'],
        selectedProjectKey: 'project-c',
        selectedProjectId: 'project-c-id',
      );

      expect(resolved, 'project-a');
    });
  });

  group('LiveEventsListController project boundary', () {
    test('project-scoped filters reset without a list controller', () {
      final repository = _ControlledLiveEventsRepository();
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      container.read(selectedLiveBandIdsProvider.notifier).state = const [
        'unit-a',
      ];
      container.read(selectedLiveEventYearProvider.notifier).state = 2025;

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';

      expect(container.read(selectedLiveBandIdsProvider), isEmpty);
      expect(container.read(selectedLiveEventYearProvider), isNull);
    });

    test('resets filters and keeps B when late A completes', () async {
      final repository = _ControlledLiveEventsRepository();
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        liveEventsListControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      container.read(selectedLiveBandIdsProvider.notifier).state = const [
        'unit-a',
      ];
      container.read(selectedLiveEventYearProvider.notifier).state = 2025;
      await _drainMicrotasks();
      expect(repository.listRequest('project-a'), isNotNull);

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _drainMicrotasks();

      expect(container.read(selectedLiveBandIdsProvider), isEmpty);
      expect(container.read(selectedLiveEventYearProvider), isNull);
      expect(repository.listRequest('project-b'), isNotNull);

      repository
          .listRequest('project-b')!
          .complete(Result.success([_eventSummary('event-b', 'project-b')]));
      await _drainMicrotasks();
      expect(
        container.read(liveEventsListControllerProvider).valueOrNull?.single.id,
        'event-b',
      );

      repository
          .listRequest('project-a')!
          .complete(Result.success([_eventSummary('event-a', 'project-a')]));
      await _drainMicrotasks();

      expect(
        container.read(liveEventsListControllerProvider).valueOrNull?.single.id,
        'event-b',
      );
    });
  });

  group('LiveEventDetailController project boundary', () {
    test('late project A detail cannot overwrite project B', () async {
      final repository = _ControlledLiveEventsRepository()
        ..deferDetail('project-a')
        ..deferDetail('project-b');
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        liveEventDetailControllerProvider('event-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _drainMicrotasks();
      expect(repository.detailRequest('project-a'), isNotNull);

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _drainMicrotasks();
      expect(repository.detailRequest('project-b'), isNotNull);

      repository
          .detailRequest('project-b')!
          .complete(Result.success(_eventDetail('project-b')));
      await _drainMicrotasks();
      expect(
        container
            .read(liveEventDetailControllerProvider('event-1'))
            .valueOrNull
            ?.projectIds,
        ['project-b'],
      );

      repository
          .detailRequest('project-a')!
          .complete(Result.success(_eventDetail('project-a')));
      await _drainMicrotasks();

      expect(
        container
            .read(liveEventDetailControllerProvider('event-1'))
            .valueOrNull
            ?.projectIds,
        ['project-b'],
      );
    });
  });

  group('LiveAttendanceHistoryController project boundary', () {
    test('keeps B history when late A completes', () async {
      final repository = _ControlledLiveEventsRepository();
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        liveAttendanceHistoryControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _drainMicrotasks();
      expect(repository.historyRequest('project-a'), isNotNull);

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _drainMicrotasks();

      final switchingState = container.read(
        liveAttendanceHistoryControllerProvider,
      );
      expect(switchingState.items, isEmpty);
      expect(switchingState.isInitialLoading, isTrue);
      expect(repository.historyRequest('project-b'), isNotNull);

      repository
          .historyRequest('project-b')!
          .complete(Result.success(_historyPage('event-b', 'project-b')));
      await _drainMicrotasks();
      expect(
        container
            .read(liveAttendanceHistoryControllerProvider)
            .items
            .single
            .eventId,
        'event-b',
      );

      repository
          .historyRequest('project-a')!
          .complete(Result.success(_historyPage('event-a', 'project-a')));
      await _drainMicrotasks();

      expect(
        container
            .read(liveAttendanceHistoryControllerProvider)
            .items
            .single
            .eventId,
        'event-b',
      );
    });

    test('clears visible A records immediately while B loads', () async {
      final repository = _ControlledLiveEventsRepository();
      final container = _container(repository, projectKey: 'project-a');
      addTearDown(container.dispose);
      final subscription = container.listen(
        liveAttendanceHistoryControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _drainMicrotasks();
      repository
          .historyRequest('project-a')!
          .complete(Result.success(_historyPage('event-a', 'project-a')));
      await _drainMicrotasks();
      expect(
        container.read(liveAttendanceHistoryControllerProvider).items,
        hasLength(1),
      );

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';

      final switchingState = container.read(
        liveAttendanceHistoryControllerProvider,
      );
      expect(switchingState.items, isEmpty);
      expect(switchingState.isInitialLoading, isTrue);
    });
  });

  test(
    'explicit attendance family uses event project for load and toggle',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      final repository = _ControlledLiveEventsRepository();
      final container = _container(
        repository,
        projectKey: 'globally-selected-project-b',
        extraOverrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          connectivityServiceProvider.overrideWith(
            (ref) => _AlwaysOnlineConnectivityService(),
          ),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.online),
          ),
          localStorageProvider.overrideWith((ref) async => storage),
        ],
      );
      addTearDown(container.dispose);
      const context = (projectId: 'event-project-a', eventId: 'event-1');
      final subscription = container.listen(
        liveAttendanceByProjectControllerProvider(context),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _drainMicrotasks();
      expect(repository.attendanceLookups, [context]);

      final result = await container
          .read(liveAttendanceByProjectControllerProvider(context).notifier)
          .toggle(true);

      expect(result.isSuccess, isTrue);
      expect(repository.attendanceToggles, [
        (projectId: 'event-project-a', eventId: 'event-1', attended: true),
      ]);
    },
  );

  group('LiveAttendanceController async ownership', () {
    test(
      'does not write state after disposal while outbox read is pending',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.create();
        final repository = _ControlledLiveEventsRepository();
        late _ControlledLiveAttendanceOutboxController outbox;
        final container = _container(
          repository,
          projectKey: 'project-a',
          extraOverrides: [
            connectivityStatusProvider.overrideWith(
              (ref) => Stream.value(ConnectivityStatus.offline),
            ),
            localStorageProvider.overrideWith((ref) async => storage),
            liveAttendanceOutboxControllerProvider.overrideWith((ref) {
              return outbox = _ControlledLiveAttendanceOutboxController(ref);
            }),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          liveAttendanceControllerProvider('event-1'),
          (_, __) {},
          fireImmediately: true,
        );

        await _drainMicrotasks();
        outbox.deferNextFind();
        final load = container
            .read(liveAttendanceControllerProvider('event-1').notifier)
            .load(forceRefresh: true);
        await _drainMicrotasks();
        expect(outbox.pendingFind, isNotNull);

        subscription.close();
        await _drainMicrotasks();
        outbox.completeFind();

        await expectLater(load, completes);
      },
    );

    test('late outbox removal for A cannot overwrite project B', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      final repository = _ControlledLiveEventsRepository();
      late _ControlledLiveAttendanceOutboxController outbox;
      final container = _container(
        repository,
        projectKey: 'project-a',
        extraOverrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          connectivityServiceProvider.overrideWith(
            (ref) => _AlwaysOnlineConnectivityService(),
          ),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value(ConnectivityStatus.online),
          ),
          localStorageProvider.overrideWith((ref) async => storage),
          liveAttendanceOutboxControllerProvider.overrideWith((ref) {
            return outbox = _ControlledLiveAttendanceOutboxController(ref);
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        liveAttendanceControllerProvider('event-1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await _drainMicrotasks();
      outbox.deferNextRemove();
      final toggle = container
          .read(liveAttendanceControllerProvider('event-1').notifier)
          .toggle(true);
      await _drainMicrotasks();
      expect(outbox.pendingRemove, isNotNull);

      container.read(selectedProjectKeyProvider.notifier).state = 'project-b';
      await _drainMicrotasks();
      expect(
        container
            .read(liveAttendanceControllerProvider('event-1'))
            .attendance
            .status,
        LiveAttendanceStatus.verified,
      );

      outbox.completeRemove();
      await toggle;
      await _drainMicrotasks();

      expect(
        container
            .read(liveAttendanceControllerProvider('event-1'))
            .attendance
            .status,
        LiveAttendanceStatus.verified,
      );
    });
  });
}

ProviderContainer _container(
  _ControlledLiveEventsRepository repository, {
  required String projectKey,
  List<Override> extraOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      selectedProjectKeyProvider.overrideWith((ref) => projectKey),
      currentNavIndexProvider.overrideWith((ref) => 1),
      liveEventsRepositoryProvider.overrideWith((ref) async => repository),
      ...extraOverrides,
    ],
  );
}

Future<void> _drainMicrotasks() async {
  for (var i = 0; i < 8; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

LiveEventSummary _eventSummary(String id, String projectId) {
  return LiveEventSummary(
    id: id,
    title: id,
    showStartTime: DateTime.utc(2026, 7, 20),
    status: 'SCHEDULED',
    projectIds: [projectId],
    unitIds: const [],
  );
}

LiveEventDetail _eventDetail(String projectId) {
  return LiveEventDetail(
    id: 'event-1',
    title: 'Event for $projectId',
    showStartTime: DateTime.utc(2026, 7, 20),
    status: 'SCHEDULED',
    projectIds: [projectId],
    unitIds: const [],
  );
}

LiveAttendanceHistoryPageData _historyPage(String eventId, String projectId) {
  return LiveAttendanceHistoryPageData(
    items: [
      LiveAttendanceHistoryRecord(
        projectKey: projectId,
        eventId: eventId,
        attended: true,
        status: LiveAttendanceStatus.declared,
        canUndo: true,
        attendedAt: DateTime.utc(2026, 7, 20),
      ),
    ],
    currentPage: 0,
    pageSize: 20,
    hasNext: false,
  );
}

class _ControlledLiveEventsRepository implements LiveEventsRepository {
  final Map<String, Completer<Result<List<LiveEventSummary>>>> _listRequests =
      {};
  final Map<String, Completer<Result<LiveAttendanceHistoryPageData>>>
  _historyRequests = {};
  final Map<String, Completer<Result<LiveEventDetail>>> _detailRequests = {};
  final Set<String> _deferredDetailProjects = {};

  final List<({String projectId, String eventId})> attendanceLookups = [];
  final List<({String projectId, String eventId, bool attended})>
  attendanceToggles = [];

  Completer<Result<List<LiveEventSummary>>>? listRequest(String projectId) {
    return _listRequests[projectId];
  }

  Completer<Result<LiveAttendanceHistoryPageData>>? historyRequest(
    String projectId,
  ) {
    return _historyRequests[projectId];
  }

  Completer<Result<LiveEventDetail>>? detailRequest(String projectId) {
    return _detailRequests[projectId];
  }

  void deferDetail(String projectId) {
    _deferredDetailProjects.add(projectId);
    _detailRequests.putIfAbsent(projectId, Completer.new);
  }

  @override
  Future<Result<List<LiveEventSummary>>> getLiveEvents({
    required String projectId,
    int page = 0,
    int size = 500,
    bool forceRefresh = false,
  }) {
    final request = Completer<Result<List<LiveEventSummary>>>();
    _listRequests[projectId] = request;
    return request.future;
  }

  @override
  Future<Result<LiveAttendanceHistoryPageData>> getLiveAttendanceHistory({
    required String projectId,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) {
    final request = Completer<Result<LiveAttendanceHistoryPageData>>();
    _historyRequests[projectId] = request;
    return request.future;
  }

  @override
  Future<Result<LiveEventDetail>> getLiveEventDetail({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  }) {
    if (_deferredDetailProjects.contains(projectId)) {
      return _detailRequests.putIfAbsent(projectId, Completer.new).future;
    }
    return Future.value(Result.success(_eventDetail(projectId)));
  }

  @override
  Future<Result<LiveAttendanceState>> getLiveAttendanceState({
    required String projectId,
    required String eventId,
    bool forceRefresh = false,
  }) async {
    attendanceLookups.add((projectId: projectId, eventId: eventId));
    if (projectId == 'project-b') {
      return Result.success(
        LiveAttendanceState(
          liveEventId: eventId,
          attended: true,
          status: LiveAttendanceStatus.verified,
          canUndo: false,
        ),
      );
    }
    return Result.success(LiveAttendanceState.none(eventId));
  }

  @override
  Future<Result<LiveAttendanceState>> toggleLiveAttendance({
    required String projectId,
    required String eventId,
    required bool attended,
  }) async {
    attendanceToggles.add((
      projectId: projectId,
      eventId: eventId,
      attended: attended,
    ));
    return Result.success(
      LiveAttendanceState(
        liveEventId: eventId,
        attended: attended,
        status: attended
            ? LiveAttendanceStatus.declared
            : LiveAttendanceStatus.none,
        canUndo: attended,
      ),
    );
  }
}

class _AlwaysOnlineConnectivityService extends ConnectivityService {
  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<ConnectivityStatus> get statusStream =>
      Stream.value(ConnectivityStatus.online);
}

class _ControlledLiveAttendanceOutboxController
    extends LiveAttendanceOutboxController {
  _ControlledLiveAttendanceOutboxController(super.ref);

  Completer<PendingLiveAttendanceMutation?>? pendingFind;
  Completer<void>? pendingRemove;
  bool _shouldDeferFind = false;
  bool _shouldDeferRemove = false;

  void deferNextFind() {
    _shouldDeferFind = true;
  }

  void completeFind([PendingLiveAttendanceMutation? mutation]) {
    pendingFind!.complete(mutation);
  }

  void deferNextRemove() {
    _shouldDeferRemove = true;
  }

  void completeRemove() {
    pendingRemove!.complete();
  }

  @override
  Future<PendingLiveAttendanceMutation?> findPending({
    required String projectKey,
    required String eventId,
  }) {
    if (!_shouldDeferFind) {
      return Future.value();
    }
    _shouldDeferFind = false;
    final request = Completer<PendingLiveAttendanceMutation?>();
    pendingFind = request;
    return request.future;
  }

  @override
  Future<void> removePending({
    required String projectKey,
    required String eventId,
  }) {
    if (!_shouldDeferRemove) {
      return Future.value();
    }
    _shouldDeferRemove = false;
    final request = Completer<void>();
    pendingRemove = request;
    return request.future;
  }

  @override
  Future<void> syncPendingMutations() async {}
}
