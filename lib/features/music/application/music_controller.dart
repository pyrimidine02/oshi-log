/// EN: Music controllers and providers.
/// KO: 악곡 컨트롤러 및 프로바이더입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/music_remote_data_source.dart';
import '../data/repositories/music_repository_impl.dart';
import '../domain/entities/music_entities.dart';
import '../domain/repositories/music_repository.dart';

class MusicCursorState<T> {
  const MusicCursorState({
    this.items = const [],
    this.nextCursor,
    this.hasNext = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasNext;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;

  MusicCursorState<T> copyWith({
    List<T>? items,
    Object? nextCursor = _kMusicNoChange,
    bool? hasNext,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return MusicCursorState<T>(
      items: items ?? this.items,
      nextCursor: identical(nextCursor, _kMusicNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      hasNext: hasNext ?? this.hasNext,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

const Object _kMusicNoChange = Object();

class MusicAlbumsController
    extends StateNotifier<MusicCursorState<MusicAlbumSummary>> {
  MusicAlbumsController(this._ref, this._projectId)
    : super(const MusicCursorState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final String _projectId;
  int _loadGeneration = 0;

  Future<void> load({bool forceRefresh = false}) async {
    final generation = ++_loadGeneration;
    final projectId = _projectId.trim();
    if (projectId.isEmpty || !mounted) {
      state = const MusicCursorState(
        items: [],
        isLoading: false,
        hasNext: false,
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      items: const [],
      hasNext: false,
      nextCursor: null,
      clearFailure: true,
    );
    final repository = await _ref.read(musicRepositoryProvider.future);
    if (!mounted || generation != _loadGeneration) return;
    final albumsById = <String, MusicAlbumSummary>{};
    final seenCursors = <String>{};
    String? cursor;
    Failure? failure;
    var completed = false;

    for (var page = 0; page < 100; page++) {
      if (!mounted || generation != _loadGeneration) return;
      final result = await repository.getAlbums(
        projectId: projectId,
        cursor: cursor,
        size: 100,
      );
      if (!mounted || generation != _loadGeneration) return;
      if (result case Success<MusicCursorPage<MusicAlbumSummary>>(
        :final data,
      )) {
        for (final album in data.items) {
          albumsById.putIfAbsent(album.id, () => album);
        }
        state = state.copyWith(
          items: albumsById.values.toList(growable: false),
          isLoading: true,
          clearFailure: true,
        );
        final nextCursor = data.nextCursor?.trim();
        if (!data.hasNext) {
          completed = true;
          break;
        }
        if (nextCursor == null || nextCursor.isEmpty) {
          failure = const UnknownFailure(
            'Album catalog hasNext without a next cursor',
            code: 'music_album_cursor_missing',
          );
          break;
        }
        if (!seenCursors.add(nextCursor)) {
          failure = const UnknownFailure(
            'Album catalog repeated a cursor',
            code: 'music_album_cursor_repeated',
          );
          break;
        }
        cursor = nextCursor;
        continue;
      }
      failure = result.failureOrNull;
      break;
    }
    if (!completed && failure == null) {
      failure = const UnknownFailure(
        'Album catalog exceeded the page safety limit',
        code: 'music_album_page_limit',
      );
    }

    if (!mounted || generation != _loadGeneration) return;
    state = state.copyWith(
      items: albumsById.values.toList(growable: false),
      hasNext: false,
      nextCursor: null,
      isLoading: false,
      failure: failure,
      clearFailure: failure == null,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;
    await load(forceRefresh: true);
  }
}

class MusicSongsController
    extends StateNotifier<MusicCursorState<MusicSongSummary>> {
  MusicSongsController(this._ref, this._projectId)
    : super(const MusicCursorState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final String _projectId;
  int _loadGeneration = 0;

  Future<void> load({bool forceRefresh = false}) async {
    final generation = ++_loadGeneration;
    final projectId = _projectId.trim();
    if (projectId.isEmpty || !mounted) {
      state = const MusicCursorState(
        items: [],
        isLoading: false,
        hasNext: false,
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      items: const [],
      hasNext: false,
      nextCursor: null,
      clearFailure: true,
    );
    final repository = await _ref.read(musicRepositoryProvider.future);
    if (!mounted || generation != _loadGeneration) return;
    final songsById = <String, MusicSongSummary>{};
    final seenCursors = <String>{};
    String? cursor;
    Failure? failure;
    var completed = false;

    for (var page = 0; page < 100; page++) {
      if (!mounted || generation != _loadGeneration) return;
      final result = await repository.getSongs(
        projectId: projectId,
        cursor: cursor,
        size: 100,
      );
      if (!mounted || generation != _loadGeneration) return;
      if (result case Success<MusicCursorPage<MusicSongSummary>>(:final data)) {
        for (final song in data.items) {
          songsById.putIfAbsent(song.id, () => song);
        }
        // EN: Publish each completed page so the catalog stays responsive
        //     while the remaining cursor chain continues in the background.
        // KO: 남은 페이지를 백그라운드에서 가져오는 동안에도 카탈로그가
        //     반응하도록 완료된 페이지를 즉시 공개합니다.
        state = state.copyWith(
          items: songsById.values.toList(growable: false),
          isLoading: true,
          clearFailure: true,
        );
        final nextCursor = data.nextCursor?.trim();
        if (!data.hasNext) {
          completed = true;
          break;
        }
        if (nextCursor == null || nextCursor.isEmpty) {
          failure = const UnknownFailure(
            'Song catalog hasNext without a next cursor',
            code: 'music_song_cursor_missing',
          );
          break;
        }
        if (!seenCursors.add(nextCursor)) {
          failure = const UnknownFailure(
            'Song catalog repeated a cursor',
            code: 'music_song_cursor_repeated',
          );
          break;
        }
        cursor = nextCursor;
        continue;
      }
      failure = result.failureOrNull;
      break;
    }
    if (!completed && failure == null) {
      failure = const UnknownFailure(
        'Song catalog exceeded the page safety limit',
        code: 'music_song_page_limit',
      );
    }

    if (!mounted || generation != _loadGeneration) return;
    state = state.copyWith(
      items: songsById.values.toList(growable: false),
      hasNext: false,
      nextCursor: null,
      isLoading: false,
      failure: failure,
      clearFailure: failure == null,
    );
  }
}

typedef MusicAlbumKey = ({String projectId, String albumId});
typedef MusicSongKey = ({String projectId, String songId});
typedef MusicSongVersionKey = ({
  String projectId,
  String songId,
  String versionCode,
});
typedef MusicSetlistKey = ({String projectId, String liveEventId});
typedef MusicAvailabilityKey = ({
  String projectId,
  String songId,
  String? country,
});
typedef MusicLyricsKey = ({
  String projectId,
  String songId,
  String? lang,
  String? version,
  bool includeRomanized,
  bool includeTranslated,
});
typedef MusicPartsKey = ({
  String projectId,
  String songId,
  String? lang,
  String? version,
});
typedef MusicCallGuideKey = ({
  String projectId,
  String songId,
  String? lang,
  String? version,
});
typedef MusicLiveContextKey = ({
  String projectId,
  String songId,
  String eventId,
  String? lang,
  String? version,
  bool includeRomanized,
  bool includeTranslated,
});

final musicRepositoryProvider = FutureProvider<MusicRepository>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return MusicRepositoryImpl(
    remoteDataSource: MusicRemoteDataSource(apiClient),
  );
});

final musicAlbumsControllerProvider = StateNotifierProvider.autoDispose
    .family<MusicAlbumsController, MusicCursorState<MusicAlbumSummary>, String>(
      (ref, projectId) {
        return MusicAlbumsController(ref, projectId);
      },
    );

final musicSongsControllerProvider = StateNotifierProvider.autoDispose
    .family<MusicSongsController, MusicCursorState<MusicSongSummary>, String>((
      ref,
      projectId,
    ) {
      return MusicSongsController(ref, projectId);
    });

final musicAlbumDetailProvider = FutureProvider.autoDispose
    .family<MusicAlbumDetail, MusicAlbumKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getAlbumDetail(
        projectId: key.projectId,
        albumId: key.albumId,
      );
      if (result case Success<MusicAlbumDetail>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music album detail provider state',
            code: 'unknown_music_album_detail_provider',
          );
    });

final musicSongDetailProvider = FutureProvider.autoDispose
    .family<MusicSongDetail, MusicSongKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongDetail(
        projectId: key.projectId,
        songId: key.songId,
      );
      if (result case Success<MusicSongDetail>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music song detail provider state',
            code: 'unknown_music_song_detail_provider',
          );
    });

final musicSongLyricsProvider = FutureProvider.autoDispose
    .family<MusicLyricsPayload, MusicLyricsKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongLyrics(
        projectId: key.projectId,
        songId: key.songId,
        lang: key.lang,
        version: key.version,
        includeRomanized: key.includeRomanized,
        includeTranslated: key.includeTranslated,
      );
      if (result case Success<MusicLyricsPayload>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music lyrics provider state',
            code: 'unknown_music_lyrics_provider',
          );
    });

final musicSongPartsProvider = FutureProvider.autoDispose
    .family<MusicPartsPayload, MusicPartsKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongParts(
        projectId: key.projectId,
        songId: key.songId,
        lang: key.lang,
        version: key.version,
      );
      if (result case Success<MusicPartsPayload>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music parts provider state',
            code: 'unknown_music_parts_provider',
          );
    });

final musicSongCallGuideProvider = FutureProvider.autoDispose
    .family<MusicCallGuidePayload, MusicCallGuideKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongCallGuide(
        projectId: key.projectId,
        songId: key.songId,
        lang: key.lang,
        version: key.version,
      );
      if (result case Success<MusicCallGuidePayload>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music call-guide provider state',
            code: 'unknown_music_call_guide_provider',
          );
    });

final musicSongVersionsProvider = FutureProvider.autoDispose
    .family<List<MusicSongVersionInfo>, MusicSongKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongVersions(
        projectId: key.projectId,
        songId: key.songId,
      );
      if (result case Success<List<MusicSongVersionInfo>>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music versions provider state',
            code: 'unknown_music_versions_provider',
          );
    });

final musicSongVersionDetailProvider = FutureProvider.autoDispose
    .family<MusicSongVersionInfo, MusicSongVersionKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongVersionDetail(
        projectId: key.projectId,
        songId: key.songId,
        versionCode: key.versionCode,
      );
      if (result case Success<MusicSongVersionInfo>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music version detail provider state',
            code: 'unknown_music_version_detail_provider',
          );
    });

final musicSongCreditsProvider = FutureProvider.autoDispose
    .family<List<MusicCreditGroup>, MusicSongKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongCredits(
        projectId: key.projectId,
        songId: key.songId,
      );
      if (result case Success<List<MusicCreditGroup>>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music credits provider state',
            code: 'unknown_music_credits_provider',
          );
    });

final musicSongDifficultyProvider = FutureProvider.autoDispose
    .family<MusicDifficulty, MusicSongKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongDifficulty(
        projectId: key.projectId,
        songId: key.songId,
      );
      if (result case Success<MusicDifficulty>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music difficulty provider state',
            code: 'unknown_music_difficulty_provider',
          );
    });

final musicSongMediaLinksProvider = FutureProvider.autoDispose
    .family<MusicMediaLinks, MusicSongKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongMediaLinks(
        projectId: key.projectId,
        songId: key.songId,
      );
      if (result case Success<MusicMediaLinks>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music media-links provider state',
            code: 'unknown_music_media_links_provider',
          );
    });

final musicSongAvailabilityProvider = FutureProvider.autoDispose
    .family<MusicAvailability, MusicAvailabilityKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongAvailability(
        projectId: key.projectId,
        songId: key.songId,
        country: key.country,
      );
      if (result case Success<MusicAvailability>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music availability provider state',
            code: 'unknown_music_availability_provider',
          );
    });

final musicSongLiveContextProvider = FutureProvider.autoDispose
    .family<MusicSongLiveContext, MusicLiveContextKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getSongLiveContext(
        projectId: key.projectId,
        songId: key.songId,
        eventId: key.eventId,
        lang: key.lang,
        version: key.version,
        includeRomanized: key.includeRomanized,
        includeTranslated: key.includeTranslated,
      );
      if (result case Success<MusicSongLiveContext>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown music live-context provider state',
            code: 'unknown_music_live_context_provider',
          );
    });

final liveEventSetlistProvider = FutureProvider.autoDispose
    .family<MusicLiveSetlist, MusicSetlistKey>((ref, key) async {
      final repository = await ref.watch(musicRepositoryProvider.future);
      final result = await repository.getLiveSetlist(
        projectId: key.projectId,
        liveEventId: key.liveEventId,
      );
      if (result case Success<MusicLiveSetlist>(:final data)) {
        return data;
      }
      throw result.failureOrNull ??
          const UnknownFailure(
            'Unknown live-event setlist provider state',
            code: 'unknown_live_event_setlist_provider',
          );
    });
