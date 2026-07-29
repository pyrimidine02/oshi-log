import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/settings/data/dto/notification_settings_dto.dart';

void main() {
  test(
    'NotificationSettingsDto parses categories aliases + version metadata',
    () {
      final json = {
        'push': true,
        'email_enabled': 'false',
        'categories': ['LIVE_EVENTS', 'FOLLOWING_POSTS'],
        'version': 12,
        'updatedAt': '2026-03-10T03:13:41.641Z',
      };

      final dto = NotificationSettingsDto.fromJson(json);
      expect(dto.pushEnabled, true);
      expect(dto.emailEnabled, false);
      expect(dto.categories, const ['LIVE_EVENT', 'FOLLOWING_POST']);
      expect(dto.version, 12);
      expect(dto.updatedAt, DateTime.parse('2026-03-10T03:13:41.641Z'));
    },
  );

  test(
    'NotificationSettingsDto normalizes categories and includes version in PUT',
    () {
      final dto = NotificationSettingsDto(
        pushEnabled: true,
        emailEnabled: false,
        categories: const ['LIVE_EVENTS', 'COMMENT', 'FOLLOWING_POSTS', 'NEWS'],
        version: 13,
      );

      final json = dto.toRequestJson();
      expect(json['version'], 13);
      expect(json['categories'], const [
        'LIVE_EVENT',
        'COMMENT',
        'FOLLOWING_POST',
        'NEWS',
      ]);
    },
  );

  test(
    'NotificationSettingsDto normalizes social alias categories to COMMENT/FOLLOWING_POST',
    () {
      final dto = NotificationSettingsDto(
        pushEnabled: true,
        emailEnabled: true,
        categories: const [
          'FOLLOWING_POST_CREATED',
          'MY_POST_COMMENT_CREATED',
          'MY_COMMENT_REPLY_CREATED',
        ],
      );

      expect(dto.toRequestJson()['categories'], const [
        'FOLLOWING_POST',
        'COMMENT',
      ]);
    },
  );

  test('NotificationSettingsDto cache JSON keeps updatedAt metadata', () {
    final dto = NotificationSettingsDto(
      pushEnabled: true,
      emailEnabled: true,
      categories: const ['LIVE_EVENT', 'COMMENT', 'FOLLOWING_POST'],
      version: 7,
      updatedAt: DateTime.parse('2026-03-10T04:22:10.000Z'),
    );

    final json = dto.toJson();
    expect(json['updatedAt'], '2026-03-10T04:22:10.000Z');
  });
}
