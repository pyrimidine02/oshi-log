import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/feed/presentation/field_guide/field_guide_providers.dart';
import 'package:oshi_log/features/music/application/music_controller.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/music/domain/repositories/music_repository.dart';
import 'package:oshi_log/features/music/presentation/pages/music_song_detail_page.dart';
import 'package:oshi_log/features/projects/application/projects_controller.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';

class _MusicRepository extends Mock implements MusicRepository {}

class _ProjectSelection extends ProjectSelectionController {
  _ProjectSelection(super.ref) {
    state = const ProjectSelectionState(projectKey: 'bandori', unitIds: []);
  }
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final fromAlbum in [false, true]) {
      testWidgets(
        'actual ${fromAlbum ? 'album sheet' : 'song list'} title opens on ${platform.name}',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const songId = '11111111-1111-4111-8111-111111111111';
          const songTitle = '春日影';
          const albumTitle = '迷跡波';
          final repository = _MusicRepository();
          final songResponse = Completer<Result<MusicSongDetail>>();
          final lyricsResponse = Completer<Result<MusicLyricsPayload>>();
          when(
            () => repository.getAlbums(
              projectId: 'bandori',
              cursor: any(named: 'cursor'),
              size: 100,
            ),
          ).thenAnswer(
            (_) async => const Success(
              MusicCursorPage<MusicAlbumSummary>(
                items: [
                  MusicAlbumSummary(
                    id: 'album-1',
                    projectId: 'bandori',
                    title: albumTitle,
                    type: 'ALBUM',
                    trackCount: 1,
                  ),
                ],
                hasNext: false,
              ),
            ),
          );
          when(
            () => repository.getSongs(projectId: 'bandori', size: 100),
          ).thenAnswer(
            (_) async => const Success(
              MusicCursorPage(
                hasNext: false,
                items: [
                  MusicSongSummary(
                    id: songId,
                    projectId: 'bandori',
                    title: songTitle,
                    albumId: 'album-1',
                  ),
                ],
              ),
            ),
          );
          when(
            () => repository.getAlbumDetail(
              projectId: 'bandori',
              albumId: 'album-1',
            ),
          ).thenAnswer(
            (_) async => const Success(
              MusicAlbumDetail(
                id: 'album-1',
                projectId: 'bandori',
                title: albumTitle,
                type: 'ALBUM',
                tracks: [
                  MusicAlbumTrack(songId: songId, trackNo: 1, title: songTitle),
                ],
              ),
            ),
          );
          when(
            () =>
                repository.getSongDetail(projectId: 'bandori', songId: songId),
          ).thenAnswer((_) => songResponse.future);
          when(
            () => repository.getSongLyrics(
              projectId: 'bandori',
              songId: songId,
              lang: any(named: 'lang'),
              includeRomanized: true,
              includeTranslated: true,
            ),
          ).thenAnswer((_) => lyricsResponse.future);
          final container = ProviderContainer(
            overrides: [
              secureStorageProvider.overrideWithValue(SecureStorage()),
              localStorageProvider.overrideWith(
                (ref) => Completer<LocalStorage>().future,
              ),
              projectSelectionControllerProvider.overrideWith(
                _ProjectSelection.new,
              ),
              fieldGuideProjectKeyProvider.overrideWith((ref) => 'bandori'),
              fieldGuideUpdatesProvider.overrideWith(
                (ref) => const AsyncData([]),
              ),
              fieldGuideArtistsProvider.overrideWith(
                (ref) => const AsyncData([]),
              ),
              musicRepositoryProvider.overrideWith((ref) async => repository),
            ],
          );
          addTearDown(container.dispose);
          final router = container.read(appRouterProvider)..go('/information');
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: GBTTheme.light.copyWith(platform: platform),
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
          await tester.tap(find.byKey(const Key('field-guide-section-kit')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('field-kit-route-music')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(fromAlbum ? albumTitle : '곡'));
          await tester.pumpAndSettle();
          expect(find.text(songTitle), findsOneWidget);
          await tester.tap(find.text(songTitle));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.byType(MusicSongDetailPage), findsOneWidget);
          songResponse.complete(
            const Success(
              MusicSongDetail(
                id: songId,
                projectId: 'bandori',
                title: songTitle,
              ),
            ),
          );
          lyricsResponse.complete(
            const Success(
              MusicLyricsPayload(songId: songId, version: 'FULL', lines: []),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('뒤로'));
          await tester.pumpAndSettle();
          expect(find.byType(MusicSongDetailPage), findsNothing);
          expect(find.text(fromAlbum ? albumTitle : songTitle), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant({platform}),
      );
    }
  }
}
