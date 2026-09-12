import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/connectivity/connectivity_service.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/providers/registrant_provider.dart';
import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/feed/presentation/field_guide/field_guide_providers.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/live_events/presentation/field_events/field_live_event_detail_page.dart';
import 'package:oshi_log/features/music/application/music_controller.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/music/domain/repositories/music_repository.dart';
import 'package:oshi_log/features/music/presentation/pages/music_song_detail_page.dart';

class _MusicRepository extends Mock implements MusicRepository {}

class _SeededEventDetailController extends LiveEventDetailController {
  _SeededEventDetailController(super.ref, super.eventId) {
    state = AsyncData(_event);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {
    state = AsyncData(_event);
  }
}

class _SeededAttendanceController extends LiveAttendanceController {
  _SeededAttendanceController(super.ref, super.eventId)
    : super(explicitProjectKey: _projectId);

  @override
  Future<Result<LiveAttendanceState>> load({bool forceRefresh = false}) async {
    final attendance = LiveAttendanceState.none(eventId);
    state = LiveAttendanceViewState(attendance: attendance);
    return Success(attendance);
  }
}

void main() {
  testWidgets(
    'setlist song opens from GoRouter overlay with event context',
    (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.mount(tester);

      harness.router.go('/overlay/events/$_eventId');
      await tester.pumpAndSettle();

      await harness.openSetlistSong(tester);

      verify(
        () => harness.music.getSongLiveContext(
          projectId: _projectId,
          songId: _songId,
          eventId: _eventId,
          lang: any(named: 'lang'),
          version: any(named: 'version'),
          includeRomanized: true,
          includeTranslated: true,
        ),
      ).called(greaterThanOrEqualTo(1));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'setlist song opens after pushing the actual event overlay',
    (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.mount(tester);

      unawaited(
        harness.router.pushNamed<void>(
          AppRoutes.overlayEventDetail,
          pathParameters: {'eventId': _eventId},
        ),
      );
      await tester.pumpAndSettle();

      await harness.openSetlistSong(tester);

      expect(find.byType(FieldLiveEventDetailPage), findsOneWidget);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.iOS,
      TargetPlatform.android,
    }),
  );
}

class _Harness {
  _Harness() {
    _stubMusic();
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(SecureStorage()),
        localStorageProvider.overrideWith(
          (ref) => Completer<LocalStorage>().future,
        ),
        connectivityStatusProvider.overrideWith(
          (ref) => const Stream<ConnectivityStatus>.empty(),
        ),
        contributorsProvider.overrideWith((ref, key) async => const []),
        fieldGuideProjectKeyProvider.overrideWith((ref) => _projectId),
        fieldGuideUpdatesProvider.overrideWith((ref) => const AsyncData([])),
        fieldGuideArtistsProvider.overrideWith((ref) => const AsyncData([])),
        liveEventDetailControllerProvider.overrideWith(
          (ref, eventId) => _SeededEventDetailController(ref, eventId),
        ),
        liveAttendanceByProjectControllerProvider.overrideWith(
          (ref, key) => _SeededAttendanceController(ref, key.eventId),
        ),
        musicRepositoryProvider.overrideWith((ref) async => music),
      ],
    );
    router = container.read(appRouterProvider)..go('/information');
  }

  final _MusicRepository music = _MusicRepository();
  late final ProviderContainer container;
  late final GoRouter router;

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: GBTTheme.light,
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSetlistSong(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(_songTitle),
      300,
      scrollable: find
          .descendant(
            of: find.byType(FieldLiveEventDetailPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text(_songTitle), findsOneWidget);
    await tester.tap(find.text(_songTitle));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(MusicSongDetailPage), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.byType(MusicSongDetailPage), findsNothing);
    expect(find.text(_songTitle), findsOneWidget);
  }

  void dispose() {
    router.dispose();
    container.dispose();
  }

  void _stubMusic() {
    when(
      () => music.getLiveSetlist(projectId: _projectId, liveEventId: _eventId),
    ).thenAnswer((_) async => const Success(_setlist));
    when(
      () => music.getSongDetail(projectId: _projectId, songId: _songId),
    ).thenAnswer((_) async => const Success(_song));
    when(
      () => music.getSongLiveContext(
        projectId: _projectId,
        songId: _songId,
        eventId: _eventId,
        lang: any(named: 'lang'),
        version: any(named: 'version'),
        includeRomanized: true,
        includeTranslated: true,
      ),
    ).thenAnswer((_) async => const Success(MusicSongLiveContext()));
    when(
      () => music.getSongLyrics(
        projectId: _projectId,
        songId: _songId,
        lang: any(named: 'lang'),
        version: any(named: 'version'),
        includeRomanized: true,
        includeTranslated: true,
      ),
    ).thenAnswer((_) async => const Success(_lyrics));
  }
}

const _projectId = 'bandori';
const _eventId = 'event-1';
const _songId = '11111111-1111-4111-8111-111111111111';
const _songTitle = '春日影';

final _event = LiveEventDetail(
  id: _eventId,
  title: 'Field Live',
  description: 'Setlist regression route',
  showStartTime: DateTime(2026, 9, 12, 18),
  status: 'COMPLETED',
  projectIds: [_projectId],
  unitIds: [],
);

const _setlist = MusicLiveSetlist(
  liveEventId: _eventId,
  eventStatus: 'COMPLETED',
  items: [
    MusicSetlistItem(
      order: 1,
      eventId: _eventId,
      songId: _songId,
      songTitle: _songTitle,
      segmentType: 'MAIN',
      isEncore: false,
    ),
  ],
  unitSetlists: [],
);

const _song = MusicSongDetail(
  id: _songId,
  projectId: _projectId,
  title: _songTitle,
);

const _lyrics = MusicLyricsPayload(songId: _songId, version: 'FULL', lines: []);
