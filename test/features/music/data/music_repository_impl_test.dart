import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/music/data/datasources/music_remote_data_source.dart';
import 'package:oshi_log/features/music/data/dto/music_dto.dart';
import 'package:oshi_log/features/music/data/repositories/music_repository_impl.dart';
import 'package:oshi_log/features/music/domain/entities/music_entities.dart';

void main() {
  late _MockMusicRemoteDataSource remote;
  late MusicRepositoryImpl repository;

  setUp(() {
    remote = _MockMusicRemoteDataSource();
    repository = MusicRepositoryImpl(remoteDataSource: remote);
  });

  MusicSongPerformanceDto dto(String id, String startTime) =>
      MusicSongPerformanceDto(
        eventId: id,
        title: id,
        startTime: startTime,
        isUpcoming: false,
        order: 1,
        isEncore: false,
      );

  test('song performances map to domain newest first', () async {
    when(
      () =>
          remote.fetchSongPerformances(projectId: 'p', songId: 's', lang: 'ko'),
    ).thenAnswer(
      (_) async => Result.success([
        dto('old', '2024-01-01T10:00:00Z'),
        dto('unknown', ''),
        dto('new', '2026-12-24T10:00:00Z'),
        dto('mid', '2025-06-01T10:00:00Z'),
      ]),
    );

    final result = await repository.getSongPerformances(
      projectId: 'p',
      songId: 's',
      lang: 'ko',
    );

    final data = (result as Success<List<MusicSongPerformance>>).data;
    expect(data.map((p) => p.eventId), ['new', 'mid', 'old', 'unknown']);
  });

  test('song performances pass through remote failures', () async {
    when(
      () =>
          remote.fetchSongPerformances(projectId: 'p', songId: 's', lang: null),
    ).thenAnswer((_) async => const Result.failure(NotFoundFailure('missing')));

    final result = await repository.getSongPerformances(
      projectId: 'p',
      songId: 's',
    );

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}

class _MockMusicRemoteDataSource extends Mock
    implements MusicRemoteDataSource {}
