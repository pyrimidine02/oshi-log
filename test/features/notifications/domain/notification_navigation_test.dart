import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/notifications/domain/entities/notification_navigation.dart';

void main() {
  test('normalizeNotificationType maps legacy aliases', () {
    expect(
      normalizeNotificationType('FOLLOWING_POST'),
      notificationTypePostCreated,
    );
    expect(
      normalizeNotificationType('FOLLOWING_POST_CREATED'),
      notificationTypePostCreated,
    );
    expect(
      normalizeNotificationType('MY_POST_COMMENT_CREATED'),
      'COMMENT_CREATED',
    );
    expect(
      normalizeNotificationType('POST_COMMENT_CREATED'),
      'COMMENT_CREATED',
    );
    expect(
      normalizeNotificationType('MY_COMMENT_REPLY_CREATED'),
      'COMMENT_REPLY_CREATED',
    );
    expect(
      normalizeNotificationType('POST_COMMENT_REPLY_CREATED'),
      'COMMENT_REPLY_CREATED',
    );
    expect(normalizeNotificationType('REPLY_CREATED'), 'COMMENT_REPLY_CREATED');
    expect(
      normalizeNotificationType('SYSTEM_BROADCAST'),
      notificationTypeSystemNotice,
    );
  });

  test(
    'resolveNotificationNavigationPath resolves post detail via deeplink',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'POST_CREATED',
        deeplink: '/board/posts/38f55757-6953-44d4-abb8-8ab0ec35003e',
        actionUrl: '/notifications',
      );

      expect(path, '/overlay/board/posts/38f55757-6953-44d4-abb8-8ab0ec35003e');
    },
  );

  test(
    'resolveNotificationNavigationPath converts API actionUrl to app path',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'POST_CREATED',
        actionUrl:
            'https://api.noraneko.cc/api/v1/projects/girls-band-cry/posts/38f55757-6953-44d4-abb8-8ab0ec35003e',
      );

      expect(path, '/overlay/board/posts/38f55757-6953-44d4-abb8-8ab0ec35003e');
    },
  );

  test(
    'resolveNotificationNavigationPath routes SYSTEM_NOTICE without link to inbox',
    () {
      final path = resolveNotificationNavigationPath(type: 'SYSTEM_NOTICE');
      expect(path, '/notifications');
    },
  );

  test(
    'resolveNotificationNavigationPath prioritizes deeplink over actionUrl',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'SYSTEM_NOTICE',
        deeplink: '/board/posts/abc-123',
        actionUrl: '/notifications',
      );
      expect(path, '/overlay/board/posts/abc-123');
    },
  );

  test(
    'resolveNotificationNavigationPath routes POST_CREATED without post id to community',
    () {
      final path = resolveNotificationNavigationPath(type: 'POST_CREATED');
      expect(path, '/community');
    },
  );

  test(
    'resolveNotificationNavigationPath converts /community/posts to /overlay/board/posts',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'COMMENT_CREATED',
        deeplink: '/community/posts/38f55757-6953-44d4-abb8-8ab0ec35003e',
      );
      expect(path, '/overlay/board/posts/38f55757-6953-44d4-abb8-8ab0ec35003e');
    },
  );

  test(
    'resolveNotificationNavigationPath routes comment-like types using entity id',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'COMMENT_REPLY_CREATED',
        entityId: '38f55757-6953-44d4-abb8-8ab0ec35003e',
      );
      expect(path, '/overlay/board/posts/38f55757-6953-44d4-abb8-8ab0ec35003e');
    },
  );

  test('normalizeNotificationType maps COMMUNITY_LIKE to POST_LIKED', () {
    expect(normalizeNotificationType('COMMUNITY_LIKE'), 'POST_LIKED');
  });

  test('normalizeNotificationType maps TITLE_GRANTED to TITLE_EARNED', () {
    expect(
      normalizeNotificationType('TITLE_GRANTED'),
      notificationTypeTitleEarned,
    );
  });

  test(
    'resolveNotificationNavigationPath routes TITLE_EARNED to title-picker with entityId',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'TITLE_EARNED',
        entityId: 'some-title-id',
      );
      expect(path, '/title-picker?titleId=some-title-id');
    },
  );

  test(
    'resolveNotificationNavigationPath routes TITLE_GRANTED to title-picker',
    () {
      final path = resolveNotificationNavigationPath(type: 'TITLE_GRANTED');
      expect(path, '/title-picker');
    },
  );

  test(
    'resolveNotificationNavigationPath routes LIVE_EVENT_UPDATED with entityId to event detail',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'LIVE_EVENT_UPDATED',
        entityId: '38f55757-6953-44d4-abb8-8ab0ec35003e',
      );
      expect(path, '/overlay/events/38f55757-6953-44d4-abb8-8ab0ec35003e');
    },
  );

  test(
    'resolveNotificationNavigationPath routes LIVE_EVENT_CANCELLED without entityId to live tab',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'LIVE_EVENT_CANCELLED',
      );
      expect(path, '/visits?tab=live');
    },
  );

  test(
    'resolveNotificationNavigationPath routes LIVE_EVENT_ATTENDANCE_VERIFIED to live tab',
    () {
      final path = resolveNotificationNavigationPath(
        type: 'LIVE_EVENT_ATTENDANCE_VERIFIED',
      );
      expect(path, '/visits?tab=live');
    },
  );

  test(
    'resolveNotificationNavigationPath routes MODERATION to notifications',
    () {
      final path = resolveNotificationNavigationPath(type: 'MODERATION');
      expect(path, '/notifications');
    },
  );
}
