import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/identity/social/data/datasources/social_remote_data_source.dart';
import 'package:oshi_log/features/identity/social/data/dto/social_dto.dart';
import 'package:oshi_log/features/identity/social/data/repositories/social_repository_impl.dart';
import 'package:oshi_log/features/identity/social/domain/entities/social_entities.dart';

class MockSocialRemoteDataSource extends Mock
    implements SocialRemoteDataSource {}

void main() {
  test('getFollowStatus maps follow DTO into domain entity', () async {
    final remoteDataSource = MockSocialRemoteDataSource();
    final repository = SocialRepositoryImpl(remoteDataSource: remoteDataSource);

    when(
      () => remoteDataSource.getFollowStatus(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Result.success(
        UserFollowStatusDto(
          targetUserId: 'user-1',
          following: true,
          followedByTarget: false,
          followedAt: '2026-03-01T00:00:00Z',
          targetFollowerCount: 12,
          targetFollowingCount: 8,
        ),
      ),
    );

    final result = await repository.getFollowStatus(userId: 'user-1');

    expect(result, isA<Success<UserFollowStatus>>());
    final status = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(status.targetUserId, 'user-1');
    expect(status.following, true);
    expect(status.followedByTarget, false);
    expect(status.targetFollowerCount, 12);
    expect(status.targetFollowingCount, 8);
    expect(status.followedAt, DateTime.parse('2026-03-01T00:00:00Z'));
  });

  test('unfollowUser delegates to remote datasource', () async {
    final remoteDataSource = MockSocialRemoteDataSource();
    final repository = SocialRepositoryImpl(remoteDataSource: remoteDataSource);

    when(
      () => remoteDataSource.unfollowUser(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const Result.success(null));

    final result = await repository.unfollowUser(userId: 'user-1');

    expect(result, isA<Success<void>>());
    verify(() => remoteDataSource.unfollowUser(userId: 'user-1')).called(1);
  });

  test('followUser delegates and returns mapped follow status', () async {
    final remoteDataSource = MockSocialRemoteDataSource();
    final repository = SocialRepositoryImpl(remoteDataSource: remoteDataSource);

    when(
      () => remoteDataSource.followUser(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Result.success(
        UserFollowStatusDto(
          targetUserId: 'user-2',
          following: true,
          followedByTarget: true,
          followedAt: null,
          targetFollowerCount: 30,
          targetFollowingCount: 15,
        ),
      ),
    );

    final result = await repository.followUser(userId: 'user-2');

    expect(result, isA<Success<UserFollowStatus>>());
    final status = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(status.following, true);
    expect(status.followedByTarget, true);
    expect(status.targetFollowerCount, 30);
    expect(status.targetFollowingCount, 15);
    verify(() => remoteDataSource.followUser(userId: 'user-2')).called(1);
  });

  test('getFollowers maps follow summary list', () async {
    final remoteDataSource = MockSocialRemoteDataSource();
    final repository = SocialRepositoryImpl(remoteDataSource: remoteDataSource);

    when(
      () => remoteDataSource.getFollowers(
        userId: any(named: 'userId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const Result.success([
        UserFollowSummaryDto(
          userId: 'user-3',
          displayName: '테스트3',
          avatarUrl: null,
          bio: 'hello',
          followedAt: '2026-03-01T00:00:00Z',
        ),
      ]),
    );

    final result = await repository.getFollowers(userId: 'user-3');

    expect(result, isA<Success<List<UserFollowSummary>>>());
    final list = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(list.single.userId, 'user-3');
    expect(list.single.displayName, '테스트3');
    expect(list.single.bio, 'hello');
  });

  test('getFollowing maps follow summary list', () async {
    final remoteDataSource = MockSocialRemoteDataSource();
    final repository = SocialRepositoryImpl(remoteDataSource: remoteDataSource);

    when(
      () => remoteDataSource.getFollowing(
        userId: any(named: 'userId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const Result.success([
        UserFollowSummaryDto(
          userId: 'user-4',
          displayName: '테스트4',
          avatarUrl: null,
          bio: null,
          followedAt: '2026-03-01T00:00:00Z',
        ),
      ]),
    );

    final result = await repository.getFollowing(userId: 'user-4');

    expect(result, isA<Success<List<UserFollowSummary>>>());
    final list = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(list.single.userId, 'user-4');
    expect(list.single.displayName, '테스트4');
  });
}
