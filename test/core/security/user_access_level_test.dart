import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/security/user_access_level.dart';

void main() {
  group('UserAccessLevelX.resolve', () {
    test('uses explicit effective access level first', () {
      final resolved = UserAccessLevelX.resolve(
        effectiveAccessLevel: 'CONTENT_EDITOR',
        accountRole: 'USER',
      );
      expect(resolved, UserAccessLevel.contentEditor);
    });

    test('falls back to account role when access level is missing', () {
      final resolved = UserAccessLevelX.resolve(accountRole: 'ADMIN');
      expect(resolved, UserAccessLevel.platformSuperAdmin);
    });

    test('supports role-prefixed and alias account-role values', () {
      expect(
        UserAccessLevelX.resolve(accountRole: 'ROLE_ADMIN'),
        UserAccessLevel.platformSuperAdmin,
      );
      expect(
        UserAccessLevelX.resolve(accountRole: 'ROLE_USER'),
        UserAccessLevel.userBase,
      );
      expect(
        UserAccessLevelX.resolve(accountRole: 'super-admin'),
        UserAccessLevel.platformSuperAdmin,
      );
    });

    test('returns unknown for unsupported values', () {
      final resolved = UserAccessLevelX.resolve(
        effectiveAccessLevel: 'SOMETHING_NEW',
        accountRole: 'UNKNOWN',
      );
      expect(resolved, UserAccessLevel.unknown);
    });
  });

  group('UserAccessLevelX.fromApiValue', () {
    test('normalizes mixed separators and legacy aliases', () {
      expect(
        UserAccessLevelX.fromApiValue('community-moderator'),
        UserAccessLevel.communityModerator,
      );
      expect(
        UserAccessLevelX.fromApiValue('ROLE_ADMIN'),
        UserAccessLevel.platformSuperAdmin,
      );
      expect(
        UserAccessLevelX.fromApiValue('super admin'),
        UserAccessLevel.platformSuperAdmin,
      );
    });
  });

  group('hasAdminOpsAccess', () {
    test('requires ADMIN_NON_SENSITIVE or higher', () {
      expect(
        hasAdminOpsAccess(effectiveAccessLevel: 'COMMUNITY_MODERATOR'),
        isFalse,
      );
      expect(
        hasAdminOpsAccess(effectiveAccessLevel: 'ADMIN_NON_SENSITIVE'),
        isTrue,
      );
      expect(hasAdminOpsAccess(accountRole: 'ADMIN'), isTrue);
    });
  });

  group('canModerateCommunity', () {
    test('requires community moderator level or higher', () {
      expect(canModerateCommunity(effectiveAccessLevel: 'USER_BASE'), isFalse);
      expect(
        canModerateCommunity(effectiveAccessLevel: 'COMMUNITY_MODERATOR'),
        isTrue,
      );
      expect(
        canModerateCommunity(effectiveAccessLevel: 'ADMIN_NON_SENSITIVE'),
        isTrue,
      );
    });
  });

  group('canModerateProjectCommunity', () {
    test(
      'allows project moderators with project role even when global level is low',
      () {
        expect(
          canModerateProjectCommunity(
            effectiveAccessLevel: 'USER_BASE',
            accountRole: 'USER',
            projectCode: 'girls-band-cry',
            projectRolesByProject: const {
              'girls-band-cry': ['COMMUNITY_MODERATOR'],
            },
          ),
          isTrue,
        );
        expect(
          canModerateProjectCommunity(
            effectiveAccessLevel: 'USER_BASE',
            accountRole: 'USER',
            projectCode: 'other-project',
            projectRolesByProject: const {
              'girls-band-cry': ['COMMUNITY_MODERATOR'],
            },
          ),
          isFalse,
        );
      },
    );
  });
}
