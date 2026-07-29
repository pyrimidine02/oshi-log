import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/settings/data/dto/user_access_level_dto.dart';

void main() {
  test('UserAccessLevelDto parses grants payload', () {
    final dto = UserAccessLevelDto.fromJson({
      'userId': 'user-1',
      'accountRole': 'USER',
      'baselineAccessLevel': 'USER_BASE',
      'effectiveAccessLevel': 'COMMUNITY_MODERATOR',
      'activeGrantCount': 1,
      'grants': [
        {
          'grantId': 'grant-1',
          'userId': 'user-1',
          'accessLevel': 'COMMUNITY_MODERATOR',
          'isActive': true,
          'grantedByUserId': 'admin-1',
          'grantReason': 'moderation support',
        },
      ],
    });

    expect(dto.userId, 'user-1');
    expect(dto.accountRole, 'USER');
    expect(dto.effectiveAccessLevel, 'COMMUNITY_MODERATOR');
    expect(dto.activeGrantCount, 1);
    expect(dto.grants, hasLength(1));
    expect(dto.grants.first.grantId, 'grant-1');
    expect(dto.grants.first.isActive, isTrue);
  });
}
