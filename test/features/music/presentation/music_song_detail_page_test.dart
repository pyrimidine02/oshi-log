import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/music/application/music_controller.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/music/presentation/pages/music_song_detail_page.dart';

void main() {
  const projectId = 'project';
  const songId = 'song';
  const detail = MusicSongDetail(
    id: songId,
    projectId: projectId,
    title: 'Test song',
  );
  const emptyParts = MusicPartsPayload(
    songId: songId,
    version: 'FULL',
    segments: <MusicPartSegment>[],
  );
  const emptyCallGuide = MusicCallGuidePayload(
    songId: songId,
    version: 'FULL',
    cues: <MusicCallCue>[],
  );

  for (final fromSetlist in [false, true]) {
    testWidgets(
      'song entry and back work from ${fromSetlist ? 'setlist' : 'catalog'}',
      (tester) async {
        const linkedSongId = '11111111-1111-4111-8111-111111111111';
        const linkedEventId = '22222222-2222-4222-8222-222222222222';
        final origin = fromSetlist ? '/overlay/event' : '/information';
        final router = GoRouter(
          initialLocation: origin,
          routes: [
            GoRoute(
              path: origin,
              builder: (context, state) => Scaffold(
                body: TextButton(
                  onPressed: () => context.goToSongDetail(
                    linkedSongId,
                    projectId: projectId,
                    eventId: fromSetlist ? linkedEventId : null,
                  ),
                  child: const Text('Open song'),
                ),
              ),
            ),
            for (final overlay in [false, true])
              GoRoute(
                path: overlay
                    ? '/overlay/music/songs/:songId'
                    : '/information/songs/:songId',
                name: overlay
                    ? AppRoutes.overlaySongDetail
                    : AppRoutes.songDetail,
                builder: (context, state) => MusicSongDetailPage(
                  projectId: state.uri.queryParameters['projectId']!,
                  songId: state.pathParameters['songId']!,
                  eventId: state.uri.queryParameters['eventId'],
                ),
              ),
          ],
        );
        await tester.pumpWidget(
          _testApp(
            router: router,
            lyrics: const MusicLyricsPayload(
              songId: linkedSongId,
              version: 'FULL',
              lines: <MusicLyricLine>[],
            ),
            emptyParts: emptyParts,
            emptyCallGuide: emptyCallGuide,
            textScaler: const TextScaler.linear(1.8),
          ),
        );
        await tester.tap(find.text('Open song'));
        await tester.pumpAndSettle();
        final page = tester.widget<MusicSongDetailPage>(
          find.byType(MusicSongDetailPage),
        );
        expect(page.songId, linkedSongId);
        expect(page.eventId, fromSetlist ? linkedEventId : null);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open song'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      },
    );
  }

  testWidgets('notched phone header stays above tabs on every tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _testApp(
        detail: const MusicSongDetail(
          id: songId,
          projectId: projectId,
          title: 'ジャイアント・キラー・チューン',
          primaryUnitName: '一家Dumb Rock!',
          bpm: 192,
          durationMs: 368000,
        ),
        lyrics: const MusicLyricsPayload(
          songId: songId,
          version: 'FULL',
          lines: [],
        ),
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
        textScaler: TextScaler.noScaling,
        topInset: 62,
      ),
    );
    await tester.pumpAndSettle();
    for (final index in [0, 1, 2]) {
      await tester.tap(find.byType(Tab).at(index));
      await tester.pumpAndSettle();
      final header = find.byKey(const Key('music-song-dossier'));
      final metadata = find.descendant(
        of: header,
        matching: find.textContaining('BPM 192'),
      );
      expect(
        tester.getBottomLeft(metadata).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(TabBar)).dy),
      );
      expect(tester.takeException(), isNull);
    }
  });

  for (final scale in [1.5, 1.8]) {
    testWidgets('populated song header fits at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _testApp(
          detail: const MusicSongDetail(
            id: songId,
            projectId: projectId,
            title: '아주 긴 곡 제목을 가진 도쿄 공연의 마지막 앙코르',
            primaryUnitName: 'MyGO!!!!! and Ave Mujica collaboration',
            bpm: 192,
            durationMs: 368000,
            isTitleTrack: true,
          ),
          lyrics: const MusicLyricsPayload(
            songId: songId,
            version: 'FULL',
            lines: <MusicLyricLine>[],
          ),
          emptyParts: emptyParts,
          emptyCallGuide: emptyCallGuide,
          textScaler: TextScaler.linear(scale),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses three task-focused tabs and a compact song dossier', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        lyrics: const MusicLyricsPayload(
          songId: songId,
          version: 'FULL',
          lines: <MusicLyricLine>[],
        ),
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(Tab), findsNWidgets(3));
    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('Live guide'), findsOneWidget);
    expect(find.text('Song record'), findsOneWidget);
    expect(find.text('More'), findsNothing);
    expect(find.text('Display options'), findsOneWidget);

    final dossier = find.byKey(const Key('music-song-dossier'));
    expect(dossier, findsOneWidget);
    expect(tester.getSize(dossier).height, lessThanOrEqualTo(220));
  });

  testWidgets(
    'shows every linked album appearance without unknown placeholders',
    (tester) async {
      await tester.pumpWidget(
        _testApp(
          detail: const MusicSongDetail(
            id: songId,
            projectId: projectId,
            title: 'A song with reissues',
            trackNo: null,
            albums: [
              MusicAlbumSummary(
                id: 'album-primary',
                projectId: projectId,
                title: 'Primary release',
                type: 'SINGLE',
                releaseDate: '2026-09-12',
                trackNo: 1,
              ),
              MusicAlbumSummary(
                id: 'album-compilation',
                projectId: projectId,
                title: 'Compilation release',
                type: 'ALBUM',
                releaseDateText: '2027년 봄',
                trackNo: null,
                trackCount: null,
              ),
            ],
          ),
          lyrics: const MusicLyricsPayload(
            songId: songId,
            version: 'FULL',
            lines: <MusicLyricLine>[],
          ),
          emptyParts: emptyParts,
          emptyCallGuide: emptyCallGuide,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      expect(find.text('Primary release'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Compilation release'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(TabBarView),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Compilation release'), findsOneWidget);
      expect(find.textContaining('2027년 봄'), findsOneWidget);
      expect(find.text('0곡'), findsNothing);
      expect(find.text('null'), findsNothing);
    },
  );

  testWidgets('remains usable at 300 percent text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        detail: const MusicSongDetail(
          id: songId,
          projectId: projectId,
          title: 'A very long journey soundtrack title for the final encore',
          primaryUnitName: 'MyGO!!!!! and Ave Mujica special collaboration',
          bpm: 192,
          durationMs: 368000,
          isTitleTrack: true,
        ),
        lyrics: const MusicLyricsPayload(
          songId: songId,
          version: 'FULL',
          lines: <MusicLyricLine>[],
        ),
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
        textScaler: const TextScaler.linear(3),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.textContaining('BPM 192'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('BPM 192').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TabBar),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(3));
    for (final tab in tester.widgetList<Tab>(find.byType(Tab))) {
      expect(tab, isNotNull);
    }
    for (var index = 0; index < 3; index++) {
      expect(
        tester.getSize(find.byType(Tab).at(index)).height,
        greaterThanOrEqualTo(48),
      );
    }

    await tester.ensureVisible(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('live guide builds long timelines lazily', (tester) async {
    final parts = MusicPartsPayload(
      songId: songId,
      version: 'FULL',
      segments: List<MusicPartSegment>.generate(
        500,
        (index) => MusicPartSegment(
          segmentId: 'segment-$index',
          startMs: index * 1000,
          endMs: (index + 1) * 1000,
          memberId: 'member-${index % 5}',
          memberName: 'Member ${index % 5}',
          partType: 'Part $index',
        ),
      ),
    );
    final calls = MusicCallGuidePayload(
      songId: songId,
      version: 'FULL',
      cues: List<MusicCallCue>.generate(
        500,
        (index) => MusicCallCue(
          cueId: 'cue-$index',
          startMs: index * 1000,
          endMs: (index + 1) * 1000,
          cueType: 'call',
          cueText: 'Call $index',
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        lyrics: const MusicLyricsPayload(
          songId: songId,
          version: 'FULL',
          lines: <MusicLyricLine>[],
        ),
        emptyParts: parts,
        emptyCallGuide: calls,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Live guide'));
    await tester.pumpAndSettle();

    expect(find.text('Part 0'), findsOneWidget);
    expect(find.text('Part 499'), findsNothing);
    expect(find.text('Call 499'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lyrics build rows lazily', (tester) async {
    final lyrics = MusicLyricsPayload(
      songId: songId,
      version: 'FULL',
      lines: List<MusicLyricLine>.generate(
        200,
        (index) => MusicLyricLine(
          lineId: 'line-$index',
          order: index,
          startMs: index * 1000,
          endMs: (index + 1) * 1000,
          section: 'Verse',
          textOriginal: 'Lyric line $index',
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        lyrics: lyrics,
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Lyric line 0'), findsOneWidget);
    expect(find.text('Lyric line 199'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Lyric line 199'),
      800,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Lyric line 199'), findsOneWidget);
  });

  testWidgets('setlist entry uses live context without duplicate lyric calls', (
    tester,
  ) async {
    var lyricsCalls = 0;
    var partsCalls = 0;
    var callGuideCalls = 0;
    var liveContextCalls = 0;
    String? capturedEventId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicSongDetailProvider.overrideWith((ref, key) async => detail),
          musicSongLyricsProvider.overrideWith((ref, key) async {
            lyricsCalls++;
            return const MusicLyricsPayload(
              songId: songId,
              version: 'FULL',
              lines: <MusicLyricLine>[],
            );
          }),
          musicSongPartsProvider.overrideWith((ref, key) async {
            partsCalls++;
            return emptyParts;
          }),
          musicSongCallGuideProvider.overrideWith((ref, key) async {
            callGuideCalls++;
            return emptyCallGuide;
          }),
          musicSongLiveContextProvider.overrideWith((ref, key) async {
            liveContextCalls++;
            capturedEventId = key.eventId;
            return const MusicSongLiveContext(
              lyrics: MusicLyricsPayload(
                songId: songId,
                version: 'FULL',
                lines: <MusicLyricLine>[],
              ),
              parts: emptyParts,
              callGuide: emptyCallGuide,
            );
          }),
        ],
        child: MaterialApp(
          theme: GBTTheme.light,
          locale: const Locale('ko'),
          home: const MusicSongDetailPage(
            projectId: projectId,
            songId: songId,
            eventId: 'event',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(liveContextCalls, 1);
    expect(capturedEventId, 'event');
    expect(lyricsCalls, 0);
    expect(partsCalls, 0);
    expect(callGuideCalls, 0);

    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    expect(liveContextCalls, 1);
    expect(partsCalls, 0);
    expect(callGuideCalls, 0);
  });

  testWidgets('partial live context fetches only missing lyric resources', (
    tester,
  ) async {
    var lyricsCalls = 0;
    var partsCalls = 0;
    var callGuideCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicSongDetailProvider.overrideWith((ref, key) async => detail),
          musicSongLyricsProvider.overrideWith((ref, key) async {
            lyricsCalls++;
            return const MusicLyricsPayload(
              songId: songId,
              version: 'FULL',
              lines: <MusicLyricLine>[],
            );
          }),
          musicSongPartsProvider.overrideWith((ref, key) async {
            partsCalls++;
            return emptyParts;
          }),
          musicSongCallGuideProvider.overrideWith((ref, key) async {
            callGuideCalls++;
            return emptyCallGuide;
          }),
          musicSongLiveContextProvider.overrideWith(
            (ref, key) async => const MusicSongLiveContext(),
          ),
        ],
        child: MaterialApp(
          theme: GBTTheme.light,
          locale: const Locale('ko'),
          home: const MusicSongDetailPage(
            projectId: projectId,
            songId: songId,
            eventId: 'event',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(lyricsCalls, 1);
    expect(partsCalls, 0);
    expect(callGuideCalls, 0);

    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    expect(partsCalls, 1);
    expect(callGuideCalls, 1);
  });
}

Widget _testApp({
  GoRouter? router,
  MusicSongDetail? detail,
  required MusicLyricsPayload lyrics,
  required MusicPartsPayload emptyParts,
  required MusicCallGuidePayload emptyCallGuide,
  TextScaler? textScaler,
  double topInset = 0,
}) {
  final page = router == null
      ? const MusicSongDetailPage(projectId: 'project', songId: 'song')
      : Router.withConfig(config: router);
  return ProviderScope(
    overrides: [
      musicSongDetailProvider.overrideWith(
        (ref, key) async =>
            detail ??
            const MusicSongDetail(
              id: 'song',
              projectId: 'project',
              title: 'Test song',
            ),
      ),
      musicSongLyricsProvider.overrideWith((ref, key) async => lyrics),
      musicSongLiveContextProvider.overrideWith(
        (ref, key) async => MusicSongLiveContext(
          lyrics: lyrics,
          parts: emptyParts,
          callGuide: emptyCallGuide,
        ),
      ),
      musicSongPartsProvider.overrideWith((ref, key) async => emptyParts),
      musicSongCallGuideProvider.overrideWith(
        (ref, key) async => emptyCallGuide,
      ),
      // EN: Complete the record-tab providers so accessibility checks do not
      //     leave an indeterminate loading animation running in the fixture.
      // KO: 접근성 검사 픽스처에서 무한 로딩 애니메이션이 남지 않도록
      //     기록 탭 프로바이더도 완료된 도메인 값을 사용합니다.
      musicSongVersionsProvider.overrideWith(
        (ref, key) async => const <MusicSongVersionInfo>[],
      ),
      musicSongDifficultyProvider.overrideWith(
        (ref, key) async => const MusicDifficulty(
          difficultyLevel: 'UNKNOWN',
          callIntensity: 0,
          cueDensityPerMin: 0,
          vocalRangeScore: 0,
          tempoScore: 0,
        ),
      ),
      musicSongMediaLinksProvider.overrideWith(
        (ref, key) async => const MusicMediaLinks(
          preview: MusicPreview(),
          streamingLinks: <MusicStreamingLink>[],
        ),
      ),
      musicSongCreditsProvider.overrideWith(
        (ref, key) async => const <MusicCreditGroup>[],
      ),
      musicSongAvailabilityProvider.overrideWith(
        (ref, key) async => const MusicAvailability(
          isAvailableNow: false,
          allowedCountries: <String>[],
          blockedCountries: <String>[],
          rightsPolicy: 'UNKNOWN',
        ),
      ),
    ],
    child: MaterialApp(
      theme: GBTTheme.light,
      locale: const Locale('ko'),
      home: textScaler == null
          ? page
          : MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: textScaler,
                padding: EdgeInsets.only(top: topInset),
                viewPadding: EdgeInsets.only(top: topInset),
              ),
              child: page,
            ),
    ),
  );
}
