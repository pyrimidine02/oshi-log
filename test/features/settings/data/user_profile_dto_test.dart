import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/settings/data/dto/user_access_level_dto.dart';
import 'package:oshi_log/features/settings/data/dto/user_profile_dto.dart';

void main() {
  test('UserProfileDto parses swagger keys', () {
    final json = {
      'userId': 'user-1',
      'displayName': '탭비',
      'emailAddress': 'tabi@example.com',
      'profileImageUrl': 'https://example.com/avatar.png',
      'role': 'USER',
      'accountRole': 'ADMIN',
      'baselineAccessLevel': 'PLATFORM_SUPER_ADMIN',
      'effectiveAccessLevel': 'PLATFORM_SUPER_ADMIN',
      'createdAt': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.id, 'user-1');
    expect(dto.email, 'tabi@example.com');
    expect(dto.displayName, '탭비');
    expect(dto.avatarUrl, 'https://example.com/avatar.png');
    expect(dto.role, 'USER');
    expect(dto.accountRole, 'ADMIN');
    expect(dto.baselineAccessLevel, 'PLATFORM_SUPER_ADMIN');
    expect(dto.effectiveAccessLevel, 'PLATFORM_SUPER_ADMIN');
    expect(dto.grants, isEmpty);
    expect(dto.createdAt, isNotNull);
  });

  test('UserProfileDto falls back to account-role baseline only', () {
    final json = {
      'userId': 'user-legacy',
      'displayName': 'Legacy Admin',
      'emailAddress': 'legacy@example.com',
      'accountRole': 'USER',
      'role': 'MODERATOR',
      'createdAt': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.accountRole, 'USER');
    expect(dto.effectiveAccessLevel, 'USER_BASE');
    expect(dto.baselineAccessLevel, 'USER_BASE');
    expect(dto.grants, isEmpty);
  });

  test('UserProfileDto supports snake_case and role list aliases', () {
    final json = {
      'user_id': 'user-admin',
      'display_name': 'Admin Legacy',
      'email_address': 'admin@example.com',
      'roles': ['ROLE_ADMIN'],
      'effective_access_level': 'admin_non_sensitive',
      'created_at': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.id, 'user-admin');
    expect(dto.displayName, 'Admin Legacy');
    expect(dto.email, 'admin@example.com');
    expect(dto.accountRole, 'ADMIN');
    expect(dto.role, 'ADMIN');
    expect(dto.effectiveAccessLevel, 'ADMIN_NON_SENSITIVE');
    expect(dto.baselineAccessLevel, 'PLATFORM_SUPER_ADMIN');
    expect(dto.grants, isEmpty);
  });

  test('UserProfileDto derives admin fallback when accountRole is missing', () {
    final json = {
      'userId': 'user-admin-2',
      'displayName': 'Role Admin',
      'emailAddress': 'role-admin@example.com',
      'role': 'ROLE_ADMIN',
      'createdAt': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.accountRole, 'ADMIN');
    expect(dto.effectiveAccessLevel, 'PLATFORM_SUPER_ADMIN');
    expect(dto.baselineAccessLevel, 'PLATFORM_SUPER_ADMIN');
    expect(dto.grants, isEmpty);
  });

  test('UserProfileDto parses project role map payload', () {
    final json = {
      'userId': 'user-3',
      'displayName': 'Project Mod',
      'emailAddress': 'project-mod@example.com',
      'accountRole': 'USER',
      'projectRoles': {
        'girls-band-cry': ['COMMUNITY_MODERATOR', 'MEMBER'],
        'project-uuid-1': ['PLACE_EDITOR'],
      },
      'createdAt': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.projectRolesByProject['girls-band-cry'], isNotNull);
    expect(
      dto.projectRolesByProject['girls-band-cry'],
      contains('COMMUNITY_MODERATOR'),
    );
    expect(
      dto.projectRolesByProject['project-uuid-1'],
      contains('PLACE_EDITOR'),
    );
  });

  test('UserProfileDto parses project role list payload', () {
    final json = {
      'userId': 'user-4',
      'displayName': 'Project Admin',
      'emailAddress': 'project-admin@example.com',
      'accountRole': 'USER',
      'project_roles': [
        {
          'projectId': 'uuid-a',
          'roles': ['ADMIN', 'MEMBER'],
        },
        {'projectCode': 'girls-band-cry', 'role': 'COMMUNITY_MODERATOR'},
      ],
      'createdAt': '2026-01-28T00:00:00Z',
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.projectRolesByProject['uuid-a'], contains('ADMIN'));
    expect(
      dto.projectRolesByProject['girls-band-cry'],
      contains('COMMUNITY_MODERATOR'),
    );
  });

  test('UserProfileDto merges access-level payload and grants', () {
    final base = UserProfileDto.fromJson({
      'userId': 'user-5',
      'displayName': 'Operator',
      'emailAddress': 'operator@example.com',
      'accountRole': 'USER',
      'effectiveAccessLevel': 'USER_BASE',
      'createdAt': '2026-01-28T00:00:00Z',
    });
    final merged = base.mergeAccessLevel(
      UserAccessLevelDto.fromJson({
        'userId': 'user-5',
        'accountRole': 'USER',
        'baselineAccessLevel': 'USER_BASE',
        'effectiveAccessLevel': 'COMMUNITY_MODERATOR',
        'activeGrantCount': 1,
        'grants': [
          {
            'grantId': 'grant-1',
            'userId': 'user-5',
            'accessLevel': 'COMMUNITY_MODERATOR',
            'isActive': true,
          },
        ],
      }),
    );

    expect(merged.effectiveAccessLevel, 'COMMUNITY_MODERATOR');
    expect(merged.baselineAccessLevel, 'USER_BASE');
    expect(merged.accountRole, 'USER');
    expect(merged.grants, hasLength(1));
    expect(merged.grants.first.grantId, 'grant-1');
    expect(merged.grants.first.isActive, isTrue);
  });

  test('UserProfileDto parses activity stats from top-level fields', () {
    final json = {
      'userId': 'user-6',
      'displayName': 'Stats Top Level',
      'emailAddress': 'stats-top@example.com',
      'createdAt': '2026-01-28T00:00:00Z',
      'totalXp': 1280,
      'fanLevel': 14,
      'fanGrade': 'Enthusiast',
      'uniquePlacesVisited': 23,
      'totalVisits': 57,
      'liveAttendanceCount': 11,
      'postCount': 39,
      'commentCount': 84,
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.totalXp, 1280);
    expect(dto.fanLevel, 14);
    expect(dto.fanGrade, 'Enthusiast');
    expect(dto.uniquePlacesVisited, 23);
    expect(dto.totalVisits, 57);
    expect(dto.liveAttendanceCount, 11);
    expect(dto.postCount, 39);
    expect(dto.commentCount, 84);
  });

  test('UserProfileDto parses activity stats from nested stats object', () {
    final json = {
      'userId': 'user-7',
      'displayName': 'Stats Nested',
      'emailAddress': 'stats-nested@example.com',
      'createdAt': '2026-01-28T00:00:00Z',
      'stats': {
        'xp': '980',
        'level': '9',
        'grade': 'Devotee',
        'unique_places': 17,
        'attendance_count': 6,
        'posts_count': 21,
        'comments_count': 45,
      },
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.totalXp, 980);
    expect(dto.fanLevel, 9);
    expect(dto.fanGrade, 'Devotee');
    expect(dto.uniquePlacesVisited, 17);
    expect(dto.liveAttendanceCount, 6);
    expect(dto.postCount, 21);
    expect(dto.commentCount, 45);
  });

  test('UserProfileDto parses canonical users endpoint payload', () {
    final json = {
      'id': 'u_123',
      'displayName': '홍길동',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'bio': '안녕하세요',
      'coverImageUrl': 'https://example.com/cover.jpg',
      'createdAt': '2026-03-26T00:00:00Z',
      'totalXp': 0,
      'fanLevel': 1,
      'fanGrade': '일반인',
      'uniquePlacesVisited': 0,
      'totalVisits': 0,
      'liveAttendanceCount': 0,
      'postCount': 0,
      'commentCount': 0,
    };

    final dto = UserProfileDto.fromJson(json);
    expect(dto.id, 'u_123');
    expect(dto.displayName, '홍길동');
    expect(dto.avatarUrl, 'https://example.com/avatar.jpg');
    expect(dto.bio, '안녕하세요');
    expect(dto.coverImageUrl, 'https://example.com/cover.jpg');
    expect(dto.totalXp, 0);
    expect(dto.fanLevel, 1);
    expect(dto.fanGrade, '일반인');
    expect(dto.uniquePlacesVisited, 0);
    expect(dto.totalVisits, 0);
    expect(dto.liveAttendanceCount, 0);
    expect(dto.postCount, 0);
    expect(dto.commentCount, 0);
  });
}
