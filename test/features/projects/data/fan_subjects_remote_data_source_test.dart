import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/projects/data/datasources/fan_subjects_remote_data_source.dart';
import 'package:oshi_log/features/projects/data/dto/fan_subject_dto.dart';
import 'package:oshi_log/features/projects/domain/entities/fan_subject.dart';

void main() {
  late _MockApiClient apiClient;
  late FanSubjectsRemoteDataSource dataSource;

  setUp(() {
    apiClient = _MockApiClient();
    dataSource = FanSubjectsRemoteDataSource(apiClient);
    when(
      () => apiClient.get<List<FanSubjectDto>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const Result.success(<FanSubjectDto>[]));
  });

  test(
    'sends generalized type and project scope without legacy unit fields',
    () async {
      await dataSource.fetchSubjects(
        const FanSubjectQuery(
          kind: FanSubjectKind.voiceActor,
          projectId: 'bang-dream',
          query: '  아이미  ',
          page: -1,
          size: 500,
        ),
      );

      final query =
          verify(
                () => apiClient.get<List<FanSubjectDto>>(
                  ApiEndpoints.fanSubjects,
                  queryParameters: captureAny(named: 'queryParameters'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(query, {
        'type': 'VOICE_ACTOR',
        'projectId': 'bang-dream',
        'q': '아이미',
        'page': 0,
        'size': 100,
      });
    },
  );

  test(
    'uses one idempotent endpoint for every selectable subject kind',
    () async {
      when(
        () => apiClient.put<FanSubjectSubscriptionDto>(
          any(),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer(
        (_) async => Result.success(
          FanSubjectSubscriptionDto(
            subject: const FanSubjectDto(
              id: 'subject-1',
              type: FanSubjectKind.unit,
              entityId: 'unit-1',
              key: 'unit:mygo',
              name: 'MyGO!!!!!',
            ),
            subscribed: true,
          ),
        ),
      );

      await dataSource.subscribe('subject-1');

      verify(
        () => apiClient.put<FanSubjectSubscriptionDto>(
          ApiEndpoints.myFanSubject('subject-1'),
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    },
  );

  test('loads one fan subject by generic subject identifier', () async {
    when(
      () =>
          apiClient.get<FanSubjectDto>(any(), fromJson: any(named: 'fromJson')),
    ).thenAnswer(
      (_) async => const Result.success(
        FanSubjectDto(
          id: 'subject-artist',
          type: FanSubjectKind.artist,
          entityId: 'artist-source',
          key: 'artist:ado',
          name: 'Ado',
        ),
      ),
    );

    await dataSource.fetchSubject('subject-artist');

    verify(
      () => apiClient.get<FanSubjectDto>(
        ApiEndpoints.fanSubject('subject-artist'),
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('sends artist and anime as first-class type filters', () async {
    await dataSource.fetchSubjects(
      const FanSubjectQuery(kind: FanSubjectKind.artist),
    );
    await dataSource.fetchSubjects(
      const FanSubjectQuery(kind: FanSubjectKind.anime),
    );

    final queries = verify(
      () => apiClient.get<List<FanSubjectDto>>(
        ApiEndpoints.fanSubjects,
        queryParameters: captureAny(named: 'queryParameters'),
        fromJson: any(named: 'fromJson'),
      ),
    ).captured.cast<Map<String, dynamic>>();

    expect(queries.map((query) => query['type']), ['ARTIST', 'ANIME']);
  });

  test('sends generic scope while preserving legacy project scope', () async {
    await dataSource.fetchSubjects(
      const FanSubjectQuery(
        scopeSubjectId: '  subject-root  ',
        projectId: 'bang-dream',
      ),
    );

    final query =
        verify(
              () => apiClient.get<List<FanSubjectDto>>(
                ApiEndpoints.fanSubjects,
                queryParameters: captureAny(named: 'queryParameters'),
                fromJson: any(named: 'fromJson'),
              ),
            ).captured.single
            as Map<String, dynamic>;

    expect(query['scopeSubjectId'], 'subject-root');
    expect(query['projectId'], 'bang-dream');
  });

  test('generic scope participates in query identity', () {
    const first = FanSubjectQuery(
      kind: FanSubjectKind.artist,
      scopeSubjectId: 'subject-root',
    );
    const same = FanSubjectQuery(
      kind: FanSubjectKind.artist,
      scopeSubjectId: 'subject-root',
    );
    const different = FanSubjectQuery(
      kind: FanSubjectKind.artist,
      scopeSubjectId: 'subject-other',
    );

    expect(first, same);
    expect({first}.contains(same), isTrue);
    expect(first, isNot(different));
  });
}

class _MockApiClient extends Mock implements ApiClient {}
