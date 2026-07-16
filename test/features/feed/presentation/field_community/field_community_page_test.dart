import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/feed/application/board_controller.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_community/field_community_page.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/field_community/field_community_providers.dart';

void main() {
  final post = PostSummary(
    id: 'post-1',
    projectId: 'bandori',
    authorId: 'traveler-1',
    title: 'Shimokitazawa venue access notes',
    content: 'The north exit is the clearest meeting point after the show.',
    topic: 'Field note',
    tags: const ['access', 'live'],
    authorName: 'Mina',
    commentCount: 3,
    likeCount: 12,
    createdAt: DateTime.utc(2026, 7, 15, 6),
  );

  Widget buildSubject({
    int initialSectionIndex = 0,
    CommunityFeedViewState? state,
    _RecordingCommunityActions? actions,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        fieldCommunityFeedStateProvider.overrideWith(
          (ref) =>
              state ??
              CommunityFeedViewState(posts: [post], isInitialLoading: false),
        ),
        fieldCommunityActionsProvider.overrideWith(
          (ref) => actions ?? _RecordingCommunityActions(),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        theme: GBTTheme.light,
        home: FieldCommunityPage(initialSectionIndex: initialSectionIndex),
      ),
    );
  }

  testWidgets('renders real community posts as edge-to-edge field reports', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('FIELD REPORTS'), findsOneWidget);
    expect(find.text('Shimokitazawa venue access notes'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('discover opens on the real trending feed mode', (tester) async {
    final actions = _RecordingCommunityActions();

    await tester.pumpWidget(
      buildSubject(initialSectionIndex: 1, actions: actions),
    );
    await tester.pump();

    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(actions.selectedModes, [CommunityFeedMode.trending]);
    expect(find.text('Shimokitazawa venue access notes'), findsOneWidget);
  });

  testWidgets('travel notes is an honest beta instead of mock reviews', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(initialSectionIndex: 2));
    await tester.pump();

    expect(
      find.byKey(const Key('field-community-travel-beta')),
      findsOneWidget,
    );
    expect(find.text('Travel notes are in honest beta'), findsOneWidget);
    expect(find.textContaining('test review'), findsNothing);
    expect(find.textContaining('Tokyo pilgrimage day'), findsNothing);
  });

  testWidgets('mode controls and compose action remain usable at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    for (final key in const [
      Key('field-community-mode-recommended'),
      Key('field-community-mode-following'),
      Key('field-community-compose'),
    ]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }
    expect(find.byKey(const Key('field-community-section-feed')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owns realtime sync exactly once per feed lifecycle', (
    tester,
  ) async {
    final actions = _RecordingCommunityActions();

    await tester.pumpWidget(buildSubject(actions: actions));
    await tester.pump();
    expect(actions.realtimeStartCount, 1);

    // EN: Feed-to-discover keeps the same live community lifecycle.
    // KO: 피드에서 발견으로 이동해도 동일한 실시간 수명주기를 유지합니다.
    await tester.pumpWidget(
      buildSubject(initialSectionIndex: 1, actions: actions),
    );
    await tester.pump();
    expect(actions.realtimeStartCount, 1);
    expect(actions.realtimeStopCount, 0);

    // EN: The beta travel section has no live feed and releases the sync.
    // KO: 베타 여행 섹션에는 실제 피드가 없어 동기화를 해제합니다.
    await tester.pumpWidget(
      buildSubject(initialSectionIndex: 2, actions: actions),
    );
    await tester.pump();
    expect(actions.realtimeStopCount, 1);

    await tester.pumpWidget(buildSubject(actions: actions));
    await tester.pump();
    expect(actions.realtimeStartCount, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(actions.realtimeStopCount, 2);
  });

  testWidgets('polls only while resumed and refreshes on foreground return', (
    tester,
  ) async {
    final actions = _RecordingCommunityActions();
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    await tester.pumpWidget(buildSubject(actions: actions));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 26));
    expect(actions.backgroundRefreshIntervals, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(actions.backgroundRefreshIntervals, [const Duration(seconds: 25)]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _RecordingCommunityActions implements FieldCommunityActions {
  final List<CommunityFeedMode> selectedModes = [];
  final List<Duration> backgroundRefreshIntervals = [];
  int realtimeStartCount = 0;
  int realtimeStopCount = 0;

  @override
  void applyPendingPosts() {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> refreshInBackground({required Duration minInterval}) async {
    backgroundRefreshIntervals.add(minInterval);
  }

  @override
  Future<void> selectMode(CommunityFeedMode mode) async {
    selectedModes.add(mode);
  }

  @override
  Future<void> startRealtimeSync() async {
    realtimeStartCount += 1;
  }

  @override
  Future<void> stopRealtimeSync() async {
    realtimeStopCount += 1;
  }
}
