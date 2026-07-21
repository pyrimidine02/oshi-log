import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:girlsbandtabi_app/core/error/failure.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/music/application/music_controller.dart';
import 'package:girlsbandtabi_app/features/music/domain/entities/music_entities.dart';
import 'package:girlsbandtabi_app/features/music/domain/repositories/music_repository.dart';

class _MockMusicRepository extends Mock implements MusicRepository {}

void main() {
  test(
    'song controller collects every cursor page and removes duplicates',
    () async {
      final repository = _MockMusicRepository();
      when(
        () => repository.getSongs(
          projectId: 'project',
          cursor: null,
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => Result.success(
          const MusicCursorPage(
            items: [
              MusicSongSummary(id: '1', projectId: 'project', title: 'One'),
              MusicSongSummary(id: '2', projectId: 'project', title: 'Two'),
            ],
            hasNext: true,
            nextCursor: 'next-1',
          ),
        ),
      );
      when(
        () => repository.getSongs(
          projectId: 'project',
          cursor: 'next-1',
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => Result.success(
          const MusicCursorPage(
            items: [
              MusicSongSummary(id: '2', projectId: 'project', title: 'Two'),
              MusicSongSummary(id: '3', projectId: 'project', title: 'Three'),
            ],
            hasNext: false,
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          musicRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = musicSongsControllerProvider('project');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      for (var attempt = 0; attempt < 10; attempt++) {
        await container.pump();
        if (!container.read(provider).isLoading) break;
      }

      final state = container.read(provider);
      expect(state.items.map((song) => song.id), ['1', '2', '3']);
      expect(state.hasNext, isFalse);
      expect(state.nextCursor, isNull);
      verify(
        () => repository.getSongs(
          projectId: 'project',
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        ),
      ).called(2);
    },
  );

  test('song controller stops when the API repeats a cursor', () async {
    final repository = _MockMusicRepository();
    when(
      () => repository.getSongs(
        projectId: 'project',
        cursor: null,
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const MusicCursorPage(
          items: [
            MusicSongSummary(id: '1', projectId: 'project', title: 'One'),
          ],
          hasNext: true,
          nextCursor: 'repeated',
        ),
      ),
    );
    when(
      () => repository.getSongs(
        projectId: 'project',
        cursor: 'repeated',
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const MusicCursorPage(
          items: [
            MusicSongSummary(id: '2', projectId: 'project', title: 'Two'),
          ],
          hasNext: true,
          nextCursor: 'repeated',
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        musicRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final provider = musicSongsControllerProvider('project');
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    for (var attempt = 0; attempt < 10; attempt++) {
      await container.pump();
      if (!container.read(provider).isLoading) break;
    }

    final state = container.read(provider);
    expect(state.items.map((song) => song.id), ['1', '2']);
    expect(state.hasNext, isFalse);
    expect(state.failure?.code, 'music_song_cursor_repeated');
    verify(
      () => repository.getSongs(
        projectId: 'project',
        cursor: any(named: 'cursor'),
        size: any(named: 'size'),
      ),
    ).called(2);
  });

  test(
    'song controller exposes a later-page failure with partial songs',
    () async {
      final repository = _MockMusicRepository();
      when(
        () => repository.getSongs(
          projectId: 'project',
          cursor: null,
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => Result.success(
          const MusicCursorPage(
            items: [
              MusicSongSummary(id: '1', projectId: 'project', title: 'One'),
            ],
            hasNext: true,
            nextCursor: 'next',
          ),
        ),
      );
      when(
        () => repository.getSongs(
          projectId: 'project',
          cursor: 'next',
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(NetworkFailure('offline')),
      );

      final container = ProviderContainer(
        overrides: [
          musicRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);
      final provider = musicSongsControllerProvider('project');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      for (var attempt = 0; attempt < 10; attempt++) {
        await container.pump();
        if (!container.read(provider).isLoading) break;
      }

      final state = container.read(provider);
      expect(state.items.map((song) => song.id), ['1']);
      expect(state.failure, isA<NetworkFailure>());
    },
  );

  test('song controller publishes each completed page progressively', () async {
    final repository = _MockMusicRepository();
    final secondPage = Completer<Result<MusicCursorPage<MusicSongSummary>>>();
    when(
      () => repository.getSongs(
        projectId: 'project',
        cursor: null,
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        const MusicCursorPage(
          items: [
            MusicSongSummary(id: '1', projectId: 'project', title: 'One'),
          ],
          hasNext: true,
          nextCursor: 'next',
        ),
      ),
    );
    when(
      () => repository.getSongs(
        projectId: 'project',
        cursor: 'next',
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) => secondPage.future);

    final container = ProviderContainer(
      overrides: [
        musicRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final provider = musicSongsControllerProvider('project');
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    for (var attempt = 0; attempt < 10; attempt++) {
      await container.pump();
      if (container.read(provider).items.isNotEmpty) break;
    }

    final partial = container.read(provider);
    expect(partial.items.map((song) => song.id), ['1']);
    expect(partial.isLoading, isTrue);

    secondPage.complete(
      Result.success(
        const MusicCursorPage(
          items: [
            MusicSongSummary(id: '2', projectId: 'project', title: 'Two'),
          ],
          hasNext: false,
        ),
      ),
    );
    for (var attempt = 0; attempt < 10; attempt++) {
      await container.pump();
      if (!container.read(provider).isLoading) break;
    }

    expect(container.read(provider).items.map((song) => song.id), ['1', '2']);
  });

  test('disposing the song controller stops the cursor chain', () async {
    final repository = _MockMusicRepository();
    final firstPage = Completer<Result<MusicCursorPage<MusicSongSummary>>>();
    when(
      () => repository.getSongs(
        projectId: 'project',
        cursor: null,
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) => firstPage.future);

    final container = ProviderContainer(
      overrides: [
        musicRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    final provider = musicSongsControllerProvider('project');
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    await container.pump();
    subscription.close();
    await container.pump();

    firstPage.complete(
      Result.success(
        const MusicCursorPage(
          items: [
            MusicSongSummary(id: '1', projectId: 'project', title: 'One'),
          ],
          hasNext: true,
          nextCursor: 'next',
        ),
      ),
    );
    await container.pump();

    verifyNever(
      () => repository.getSongs(
        projectId: 'project',
        cursor: 'next',
        size: any(named: 'size'),
      ),
    );
  });
}
