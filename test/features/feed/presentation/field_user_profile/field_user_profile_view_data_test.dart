import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/feed/presentation/field_user_profile/field_user_profile_view_data.dart';
import 'package:oshi_log/features/settings/domain/entities/user_profile.dart';

void main() {
  group('FieldUserProfileViewData', () {
    test(
      'maps only factual profile data into an immutable activity ledger',
      () {
        final profile = _profile();

        final viewData = FieldUserProfileViewData.fromProfile(
          profile: profile,
          followerCount: 12,
          followingCount: 7,
        );

        expect(viewData.displayName, '마리');
        expect(viewData.bio, '도쿄의 라이브 하우스와 성지를 기록합니다.');
        expect(viewData.joinedAt, DateTime.utc(2024, 3, 2));
        expect(viewData.followerCount, 12);
        expect(viewData.followingCount, 7);
        expect(
          viewData.metrics.map((metric) => metric.kind),
          FieldProfileMetricKind.values,
        );
        expect(viewData.metrics.map((metric) => metric.value), [
          '1,250',
          'Lv.8 · Stagehand',
          '14',
          '6',
          '9',
          '21',
        ]);
        expect(
          () => viewData.metrics.add(
            const FieldProfileMetric(
              kind: FieldProfileMetricKind.posts,
              value: '0',
            ),
          ),
          throwsUnsupportedError,
        );
      },
    );

    test('uses honest unknown values instead of inventing activity', () {
      final viewData = FieldUserProfileViewData.fromProfile(
        profile: _profile(withActivity: false),
      );

      expect(viewData.bio, isNull);
      expect(viewData.followerCount, isNull);
      expect(viewData.followingCount, isNull);
      expect(viewData.metrics.every((metric) => metric.value == '—'), isTrue);
    });

    test(
      'uses real self-profile controller fallbacks when API fields are null',
      () {
        final viewData = FieldUserProfileViewData.fromProfile(
          profile: _profile(withActivity: false),
          fallbackTotalXp: 380,
          fallbackFanLevel: 3,
          fallbackFanGrade: 'Listener',
          fallbackUniquePlacesVisited: 5,
          fallbackLiveAttendanceCount: 2,
        );

        expect(viewData.metrics.take(4).map((metric) => metric.value), [
          '380',
          'Lv.3 · Listener',
          '5',
          '2',
        ]);
      },
    );
  });
}

UserProfile _profile({bool withActivity = true}) {
  return UserProfile(
    id: 'user-1',
    email: 'mari@example.com',
    displayName: '마리',
    role: 'USER',
    accountRole: 'USER',
    baselineAccessLevel: 'USER',
    effectiveAccessLevel: 'USER',
    grants: const [],
    projectRolesByProject: const {},
    createdAt: DateTime.utc(2024, 3, 2),
    avatarUrl: 'https://example.com/avatar.jpg',
    coverImageUrl: 'https://example.com/cover.jpg',
    bio: withActivity ? '도쿄의 라이브 하우스와 성지를 기록합니다.' : null,
    totalXp: withActivity ? 1250 : null,
    fanLevel: withActivity ? 8 : null,
    fanGrade: withActivity ? 'Stagehand' : null,
    uniquePlacesVisited: withActivity ? 14 : null,
    liveAttendanceCount: withActivity ? 6 : null,
    postCount: withActivity ? 9 : null,
    commentCount: withActivity ? 21 : null,
  );
}
