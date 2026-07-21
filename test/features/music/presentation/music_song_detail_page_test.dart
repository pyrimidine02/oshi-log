import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/music/application/music_controller.dart';
import 'package:girlsbandtabi_app/features/music/domain/entities/music_entities.dart';
import 'package:girlsbandtabi_app/features/music/presentation/pages/music_song_detail_page.dart';

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
    expect(
      tester.getSize(find.byKey(const Key('music-song-dossier'))).height,
      lessThanOrEqualTo(320),
    );
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
  MusicSongDetail? detail,
  required MusicLyricsPayload lyrics,
  required MusicPartsPayload emptyParts,
  required MusicCallGuidePayload emptyCallGuide,
  TextScaler? textScaler,
}) {
  const page = MusicSongDetailPage(projectId: 'project', songId: 'song');
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
      musicSongPartsProvider.overrideWith((ref, key) async => emptyParts),
      musicSongCallGuideProvider.overrideWith(
        (ref, key) async => emptyCallGuide,
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
              ),
              child: page,
            ),
    ),
  );
}
