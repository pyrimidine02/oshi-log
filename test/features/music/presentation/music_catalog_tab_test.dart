import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/music/application/music_controller.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/music/domain/repositories/music_repository.dart';
import 'package:oshi_log/features/music/presentation/widgets/music_catalog_tab.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';

class _ProjectSelection extends ProjectSelectionController {
  _ProjectSelection(super.ref) {
    state = const ProjectSelectionState(projectKey: 'project', unitIds: []);
  }
}

const _longUnitName = '토게나시 토게아리 초장문 원정 기록 유닛';

class _CatalogRepository implements MusicRepository {
  _CatalogRepository({this.failSecondAlbumPage = false});

  bool failSecondAlbumPage;
  bool albumPageTwoRecovered = false;
  int albumCalls = 0;

  @override
  Future<Result<MusicCursorPage<MusicAlbumSummary>>> getAlbums({
    required String projectId,
    String? cursor,
    int size = 20,
  }) async {
    albumCalls++;
    if (cursor == 'next' && failSecondAlbumPage && !albumPageTwoRecovered) {
      return const Result.failure(NetworkFailure('offline'));
    }
    if (cursor == 'next') {
      return const Result.success(
        MusicCursorPage(
          items: [
            MusicAlbumSummary(
              id: 'album-2',
              projectId: 'project',
              title: 'Newest Single',
              type: 'single',
              releaseDate: '2026-02-01',
              unitId: 'unit-a',
              unitName: _longUnitName,
            ),
          ],
          hasNext: false,
        ),
      );
    }
    return const Result.success(
      MusicCursorPage(
        items: [
          MusicAlbumSummary(
            id: 'album-1',
            projectId: 'project',
            title: 'Older Album',
            type: 'album',
            releaseDate: '2024-01-01',
            unitId: 'unit-a',
            unitName: _longUnitName,
          ),
        ],
        hasNext: true,
        nextCursor: 'next',
      ),
    );
  }

  @override
  Future<Result<MusicCursorPage<MusicSongSummary>>> getSongs({
    required String projectId,
    String? cursor,
    int size = 20,
  }) async {
    return const Result.success(
      MusicCursorPage(
        items: [
          MusicSongSummary(
            id: 'song-old',
            projectId: 'project',
            title: 'Blue',
            albumId: 'album-1',
            primaryUnitId: 'unit-a',
            primaryUnitName: _longUnitName,
          ),
          MusicSongSummary(
            id: 'song-new',
            projectId: 'project',
            title: 'Amber',
            albumId: 'album-2',
            primaryUnitId: 'unit-a',
            primaryUnitName: _longUnitName,
          ),
        ],
        hasNext: false,
      ),
    );
  }

  @override
  Future<Result<MusicAlbumDetail>> getAlbumDetail({
    required String projectId,
    required String albumId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicSongDetail>> getSongDetail({
    required String projectId,
    required String songId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicLyricsPayload>> getSongLyrics({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicPartsPayload>> getSongParts({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicCallGuidePayload>> getSongCallGuide({
    required String projectId,
    required String songId,
    String? lang,
    String? version,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicSongLiveContext>> getSongLiveContext({
    required String projectId,
    required String songId,
    required String eventId,
    String? lang,
    String? version,
    bool includeRomanized = false,
    bool includeTranslated = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<MusicSongVersionInfo>>> getSongVersions({
    required String projectId,
    required String songId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicSongVersionInfo>> getSongVersionDetail({
    required String projectId,
    required String songId,
    required String versionCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<MusicCreditGroup>>> getSongCredits({
    required String projectId,
    required String songId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicDifficulty>> getSongDifficulty({
    required String projectId,
    required String songId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicMediaLinks>> getSongMediaLinks({
    required String projectId,
    required String songId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicAvailability>> getSongAvailability({
    required String projectId,
    required String songId,
    String? country,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MusicLiveSetlist>> getLiveSetlist({
    required String projectId,
    required String liveEventId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('album catalog filters by search, unit, type and newest release', () {
    final albums = [
      const MusicAlbumSummary(
        id: 'album-old',
        projectId: 'project',
        title: 'Old Live',
        type: 'album',
        releaseDate: '2024-01-01',
        unitId: 'unit-a',
        unitName: _longUnitName,
      ),
      const MusicAlbumSummary(
        id: 'album-new',
        projectId: 'project',
        title: 'New Single',
        type: 'single',
        releaseDate: '2026-02-01',
        unitId: 'unit-a',
        unitName: _longUnitName,
      ),
      const MusicAlbumSummary(
        id: 'album-other',
        projectId: 'project',
        title: 'Other Unit Single',
        type: 'single',
        releaseDate: '2025-05-01',
        unitId: 'unit-b',
        unitName: 'Other',
      ),
    ];

    final result = filterAndSortMusicAlbums(
      albums,
      songs: const [],
      unitKey: 'id:unit-a',
      albumType: 'single',
      query: 'single',
      sortOrder: MusicCatalogSortOrder.releaseNewest,
    );

    expect(result.map((album) => album.id), ['album-new']);
  });

  test('song catalog can search album titles and sort by album release', () {
    final albumsById = {
      'album-old': const MusicAlbumSummary(
        id: 'album-old',
        projectId: 'project',
        title: 'First Album',
        type: 'album',
        releaseDate: '2024-01-01',
      ),
      'album-new': const MusicAlbumSummary(
        id: 'album-new',
        projectId: 'project',
        title: 'Latest Album',
        type: 'album',
        releaseDate: '2026-01-01',
      ),
    };
    final songs = [
      const MusicSongSummary(
        id: 'song-old',
        projectId: 'project',
        title: 'Blue',
        albumId: 'album-old',
        primaryUnitId: 'unit-a',
        primaryUnitName: _longUnitName,
      ),
      const MusicSongSummary(
        id: 'song-new',
        projectId: 'project',
        title: 'Amber',
        albumId: 'album-new',
        primaryUnitId: 'unit-a',
        primaryUnitName: _longUnitName,
      ),
      const MusicSongSummary(
        id: 'song-other',
        projectId: 'project',
        title: 'Other',
        primaryUnitId: 'unit-b',
        primaryUnitName: 'Other',
      ),
    ];

    final result = filterAndSortMusicSongs(
      songs,
      albumsById: albumsById,
      unitKey: 'id:unit-a',
      query: 'album',
      sortOrder: MusicCatalogSortOrder.releaseNewest,
    );

    expect(result.map((song) => song.id), ['song-new', 'song-old']);
  });

  test('album type options are unique and case-insensitive', () {
    final types = musicCatalogAlbumTypes(const [
      MusicAlbumSummary(
        id: 'album-1',
        projectId: 'project',
        title: 'A',
        type: 'Single',
      ),
      MusicAlbumSummary(
        id: 'album-2',
        projectId: 'project',
        title: 'B',
        type: 'single',
      ),
      MusicAlbumSummary(
        id: 'album-3',
        projectId: 'project',
        title: 'C',
        type: 'Album',
      ),
    ]);

    expect(types, ['Album', 'Single']);
  });

  testWidgets(
    'catalog widget filters and sorts through real controls at narrow large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _CatalogRepository();

      final keyboardInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
      addTearDown(keyboardInsets.dispose);

      await _pumpCatalog(tester, repository, viewInsets: keyboardInsets);
      await _pumpUntilFound(tester, find.text('Newest Single'));

      expect(find.text('Newest Single'), findsOneWidget);
      await _scrollAlbumGridUntilFound(tester, find.text('Older Album'));
      expect(find.text('Older Album'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('music-catalog-search')));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      keyboardInsets.value = const EdgeInsets.only(bottom: 300);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );

      final keyboardTop = 640 - 300;
      expect(
        tester
            .getBottomLeft(find.byKey(const ValueKey('music-catalog-search')))
            .dy,
        lessThan(keyboardTop),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('유닛 필터'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<String> &&
              widget.value == 'id:unit-a',
        ),
      );
      await tester.pumpAndSettle();

      keyboardInsets.value = EdgeInsets.zero;
      await tester.pumpAndSettle();

      expect(find.text(_longUnitName), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(_longUnitName)).dx,
        greaterThanOrEqualTo(0),
      );
      expect(
        tester.getBottomRight(find.text(_longUnitName)).dx,
        lessThanOrEqualTo(320),
      );

      await tester.enterText(
        find.byKey(const ValueKey('music-catalog-search')),
        'single',
      );
      await tester.pumpAndSettle();

      expect(find.text('Newest Single'), findsOneWidget);
      expect(find.text('Older Album'), findsNothing);

      await tester.tap(find.byTooltip('앨범 유형'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<String> &&
              widget.value == 'single',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Newest Single'), findsOneWidget);
      expect(find.text('Older Album'), findsNothing);

      await tester.tap(find.byTooltip('정렬'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CheckedPopupMenuItem<MusicCatalogSortOrder> &&
              widget.value == MusicCatalogSortOrder.titleAsc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('제목순'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalog widget drains album pages without a pagination button', (
    tester,
  ) async {
    final repository = _CatalogRepository();

    await _pumpCatalog(tester, repository);
    await _pumpUntilFound(tester, find.text('Newest Single'));

    expect(repository.albumCalls, 2);
    expect(find.text('Newest Single'), findsOneWidget);
    await _scrollAlbumGridUntilFound(tester, find.text('Older Album'));
    expect(find.text('Older Album'), findsOneWidget);
    expect(find.text('더 보기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog widget shows partial album retry and recovers', (
    tester,
  ) async {
    final repository = _CatalogRepository(failSecondAlbumPage: true);

    await _pumpCatalog(tester, repository);
    await _pumpUntilFound(tester, find.text('일부 앨범만 불러왔습니다.'));

    await _scrollAlbumGridUntilFound(tester, find.text('Older Album'));
    expect(find.text('Older Album'), findsOneWidget);
    expect(find.text('Newest Single'), findsNothing);

    repository.albumPageTwoRecovered = true;
    await tester.tap(find.text('다시 시도'));
    await _pumpUntilFound(tester, find.text('Newest Single'));

    expect(find.text('일부 앨범만 불러왔습니다.'), findsNothing);
    expect(find.text('Newest Single'), findsOneWidget);
    await _scrollAlbumGridUntilFound(tester, find.text('Older Album'));
    expect(find.text('Older Album'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCatalog(
  WidgetTester tester,
  _CatalogRepository repository, {
  ValueListenable<EdgeInsets>? viewInsets,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWith(
          (ref) => Completer<LocalStorage>().future,
        ),
        projectSelectionControllerProvider.overrideWith(_ProjectSelection.new),
        musicRepositoryProvider.overrideWith((ref) async => repository),
      ],
      child: MaterialApp(
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: GBTTheme.light,
        builder: (context, child) {
          Widget buildWithInsets(EdgeInsets insets) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                size: const Size(320, 640),
                textScaler: const TextScaler.linear(2),
                viewInsets: insets,
              ),
              child: child!,
            );
          }

          final listenable = viewInsets;
          if (listenable == null) return buildWithInsets(EdgeInsets.zero);
          return ValueListenableBuilder<EdgeInsets>(
            valueListenable: listenable,
            builder: (context, insets, _) => buildWithInsets(insets),
          );
        },
        home: const Scaffold(body: MusicCatalogTab()),
      ),
    ),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _scrollAlbumGridUntilFound(
  WidgetTester tester,
  Finder finder,
) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(find.byType(GridView), const Offset(0, -260));
    await tester.pumpAndSettle();
  }
}
