import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/design_system/widgets/common/spoiler_guard.dart';
import 'package:oshi_log/features/oshikatsu/music/application/music_controller.dart';
import 'package:oshi_log/features/oshikatsu/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/oshikatsu/music/presentation/pages/music_song_detail_page.dart';
import '../../../../testing/platform_golden.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Pretendard');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
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

  for (final language in ['ko', 'ja']) {
    for (final dark in [false, true]) {
      testWidgets('$language live guide fits 320dp at 200 percent, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _testApp(
            eventId: 'event',
            locale: Locale(language),
            dark: dark,
            detail: const MusicSongDetail(
              id: songId,
              projectId: projectId,
              title: '長い楽曲名と한국어 공연 준비곡',
              primaryUnitName: 'Band A',
            ),
            lyrics: const MusicLyricsPayload(
              songId: songId,
              version: 'FULL',
              lines: [],
            ),
            emptyParts: emptyParts,
            emptyCallGuide: emptyCallGuide,
            textScaler: const TextScaler.linear(2),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 1);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('song-detail-golden')),
          matchesGoldenFile(
            '$platformGoldenDirectory/song_guide_${language}_${dark ? 'dark' : 'light'}_320_200.png',
          ),
        );
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -550),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  const protectedLyrics = MusicLyricsPayload(
    songId: songId,
    version: 'FULL',
    lines: [
      MusicLyricLine(
        lineId: 'private-line',
        order: 1,
        startMs: 0,
        endMs: 1000,
        section: 'Verse',
        textOriginal: 'Rights-sensitive lyric',
      ),
    ],
  );
  for (final policy in [
    'UNKNOWN',
    'COPYRIGHT_BLOCKED',
    'PRE_RELEASE',
    'EXPIRED',
    '',
  ]) {
    testWidgets('lyrics stay hidden without confirmed rights: $policy', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var lyricCalls = 0;
        await tester.pumpWidget(
          _testApp(
            eventId: policy == 'COPYRIGHT_BLOCKED' ? 'event' : null,
            lyrics: protectedLyrics,
            emptyParts: emptyParts,
            emptyCallGuide: emptyCallGuide,
            loadLyrics: () async {
              lyricCalls++;
              return protectedLyrics;
            },
            availability: () async => MusicAvailability(
              isAvailableNow: true,
              allowedCountries: const [],
              blockedCountries: const [],
              rightsPolicy: policy,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Tab).first);
        await tester.pumpAndSettle();
        expect(find.text('Rights-sensitive lyric'), findsNothing);
        expect(find.bySemanticsLabel('Rights-sensitive lyric'), findsNothing);
        expect(lyricCalls, 0);
        expect(
          find.text(
            'Lyrics are unavailable until display rights are confirmed.',
          ),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });
  }
  testWidgets('lyrics wait for availability and require current permission', (
    tester,
  ) async {
    final availability = Completer<MusicAvailability>();
    await tester.pumpWidget(
      _testApp(
        lyrics: protectedLyrics,
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
        availability: () => availability.future,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Rights-sensitive lyric'), findsNothing);
    availability.complete(
      const MusicAvailability(
        isAvailableNow: false,
        allowedCountries: [],
        blockedCountries: [],
        rightsPolicy: 'OK',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rights-sensitive lyric'), findsNothing);
  });
  testWidgets('availability failure keeps lyrics hidden', (tester) async {
    await tester.pumpWidget(
      _testApp(
        lyrics: protectedLyrics,
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
        availability: () async => throw StateError('unavailable'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rights-sensitive lyric'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
  testWidgets('confirmed rights allow lyrics', (tester) async {
    await tester.pumpWidget(
      _testApp(
        lyrics: protectedLyrics,
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rights-sensitive lyric'), findsOneWidget);
  });
  testWidgets(
    'lyrics disappear when permission expires while page stays open',
    (tester) async {
      final until = DateTime.now().add(const Duration(minutes: 1));
      await tester.pumpWidget(
        _testApp(
          lyrics: protectedLyrics,
          emptyParts: emptyParts,
          emptyCallGuide: emptyCallGuide,
          availability: () async => MusicAvailability(
            isAvailableNow: true,
            availableUntil: until,
            allowedCountries: const [],
            blockedCountries: const [],
            rightsPolicy: 'OK',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rights-sensitive lyric'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.text('Rights-sensitive lyric'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final expired in [false, true]) {
    testWidgets(
      'lyric permission respects known ${expired ? 'expiry' : 'release'} bound',
      (tester) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          _testApp(
            lyrics: protectedLyrics,
            emptyParts: emptyParts,
            emptyCallGuide: emptyCallGuide,
            availability: () async => MusicAvailability(
              isAvailableNow: true,
              availableFrom: expired ? null : now.add(const Duration(days: 1)),
              availableUntil: expired
                  ? now.subtract(const Duration(days: 1))
                  : null,
              allowedCountries: const [],
              blockedCountries: const [],
              rightsPolicy: 'OK',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rights-sensitive lyric'), findsNothing);
      },
    );
  }
  for (final locale in [const Locale('ja', 'JP'), const Locale('ko', 'KR')]) {
    testWidgets(
      'display language does not establish lyric country rights: $locale',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            locale: locale,
            lyrics: protectedLyrics,
            emptyParts: emptyParts,
            emptyCallGuide: emptyCallGuide,
            availability: () async => const MusicAvailability(
              isAvailableNow: true,
              allowedCountries: ['JP'],
              blockedCountries: [],
              rightsPolicy: 'OK',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rights-sensitive lyric'), findsNothing);
      },
    );
  }
  testWidgets(
    'blocked countries require verified region before displaying lyrics',
    (tester) async {
      await tester.pumpWidget(
        _testApp(
          lyrics: protectedLyrics,
          emptyParts: emptyParts,
          emptyCallGuide: emptyCallGuide,
          availability: () async => const MusicAvailability(
            isAvailableNow: true,
            allowedCountries: [],
            blockedCountries: ['KR'],
            rightsPolicy: 'OK',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rights-sensitive lyric'), findsNothing);
    },
  );
  testWidgets('unconfirmed lyrics offer only provided HTTPS official links', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        lyrics: protectedLyrics,
        emptyParts: emptyParts,
        emptyCallGuide: emptyCallGuide,
        availability: () async => const MusicAvailability(
          isAvailableNow: false,
          allowedCountries: [],
          blockedCountries: [],
          rightsPolicy: 'UNKNOWN',
        ),
        media: const MusicMediaLinks(
          preview: MusicPreview(),
          streamingLinks: [
            MusicStreamingLink(
              provider: 'YouTube',
              url: 'https://www.youtube.com/watch?v=example',
            ),
            MusicStreamingLink(provider: 'Invalid', url: 'javascript:alert(1)'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('View official site'), findsOneWidget);
    expect(find.textContaining('Invalid'), findsNothing);
    expect(find.text('Rights-sensitive lyric'), findsNothing);
  });

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
                    : AppRoutes.musicSongDetail,
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

  group('performances section', () {
    Future<void> openRecordTab(
      WidgetTester tester,
      Future<List<MusicSongPerformance>> Function() performances,
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
          performances: performances,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lives featuring this song'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(TabBarView),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists performances with order, encore and upcoming', (
      tester,
    ) async {
      await openRecordTab(
        tester,
        () async => [
          MusicSongPerformance(
            eventId: 'event-new',
            title: 'Future Live',
            startTime: DateTime(2026, 12, 24, 18),
            isUpcoming: true,
            order: 3,
            isEncore: true,
          ),
          MusicSongPerformance(
            eventId: 'event-old',
            title: 'Past Live',
            startTime: DateTime(2025, 3, 1, 18),
            isUpcoming: false,
            order: 7,
            isEncore: false,
          ),
        ],
      );

      expect(find.text('Future Live'), findsNothing);
      final guard = find.ancestor(
        of: find.text('Lives featuring this song'),
        matching: find.byType(SpoilerGuard),
      );
      final reveal = find.descendant(
        of: guard,
        matching: find.text('Show spoilers'),
      );
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(find.text('Future Live'), findsOneWidget);
      expect(find.text('Past Live'), findsOneWidget);
      expect(find.text('2026.12.24 · Song #3'), findsOneWidget);
      expect(find.text('2025.03.01 · Song #7'), findsOneWidget);
      expect(find.text('Encore'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Future Live')).dy,
        lessThan(tester.getTopLeft(find.text('Past Live')).dy),
      );
      expect(
        find.text('Performer not provided · may differ from the song artist'),
        findsNWidgets(2),
      );
      final hide = find.descendant(
        of: guard,
        matching: find.text('Hide spoilers'),
      );
      await tester.ensureVisible(hide);
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(find.text('Future Live'), findsNothing);
    });

    testWidgets('shows empty state', (tester) async {
      await openRecordTab(tester, () async => const []);
      final reveal = find.text('Show spoilers').last;
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();

      expect(find.text('No performances yet.'), findsOneWidget);
    });

    testWidgets('error stays inline and keeps other sections', (tester) async {
      await openRecordTab(
        tester,
        () => Future.error(const NotFoundFailure('not deployed')),
      );
      final reveal = find.text('Show spoilers').last;
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();

      expect(find.text('요청하신 정보를 찾을 수 없습니다'), findsOneWidget);
      expect(find.text('Versions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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
    var songCalls = 0;
    String? capturedEventId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          musicSongAvailabilityProvider.overrideWith(
            (ref, key) async => _allowedAvailability,
          ),
          musicSongDetailProvider.overrideWith((ref, key) async {
            songCalls++;
            return detail;
          }),
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
              song: detail,
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
    expect(songCalls, 0);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
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
          musicSongAvailabilityProvider.overrideWith(
            (ref, key) async => _allowedAvailability,
          ),
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

    expect(lyricsCalls, 0);
    expect(partsCalls, 1);
    expect(callGuideCalls, 1);

    await tester.tap(find.byType(Tab).at(0));
    await tester.pumpAndSettle();

    expect(lyricsCalls, 1);
    expect(partsCalls, 1);
    expect(callGuideCalls, 1);
  });
}

Widget _testApp({
  GoRouter? router,
  String? eventId,
  Locale locale = const Locale('en'),
  bool dark = false,
  MusicSongDetail? detail,
  required MusicLyricsPayload lyrics,
  required MusicPartsPayload emptyParts,
  required MusicCallGuidePayload emptyCallGuide,
  TextScaler? textScaler,
  double topInset = 0,
  Future<List<MusicSongPerformance>> Function()? performances,
  Future<MusicAvailability> Function()? availability,
  Future<MusicLyricsPayload> Function()? loadLyrics,
  MusicMediaLinks? media,
}) {
  final page = RepaintBoundary(
    key: const ValueKey('song-detail-golden'),
    child: router == null
        ? MusicSongDetailPage(
            projectId: 'project',
            songId: 'song',
            eventId: eventId,
          )
        : Router.withConfig(config: router),
  );
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
      musicSongLyricsProvider.overrideWith(
        (ref, key) async => loadLyrics == null ? lyrics : await loadLyrics(),
      ),
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
        (ref, key) async =>
            media ??
            const MusicMediaLinks(
              preview: MusicPreview(),
              streamingLinks: <MusicStreamingLink>[],
            ),
      ),
      musicSongCreditsProvider.overrideWith(
        (ref, key) async => const <MusicCreditGroup>[],
      ),
      musicSongPerformancesProvider.overrideWith(
        (ref, key) => performances?.call() ?? Future.value(const []),
      ),
      musicSongAvailabilityProvider.overrideWith(
        (ref, key) =>
            availability?.call() ?? Future.value(_allowedAvailability),
      ),
    ],
    child: MaterialApp(
      theme: dark ? GBTTheme.dark : GBTTheme.light,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ko'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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

const _allowedAvailability = MusicAvailability(
  isAvailableNow: true,
  allowedCountries: [],
  blockedCountries: [],
  rightsPolicy: 'OK',
);
