import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/settings/data/dto/notification_device_dto.dart';

void main() {
  group('NotificationDeviceDeactivationDto', () {
    test('parses explicit deactivated=false response', () {
      final dto = NotificationDeviceDeactivationDto.fromJson({
        'deviceId': 'ios-123',
        'deactivated': false,
      });

      expect(dto.deviceId, 'ios-123');
      expect(dto.deactivated, isFalse);
    });

    test('defaults to deactivated=true when field is absent', () {
      final dto = NotificationDeviceDeactivationDto.fromJson(const {});

      expect(dto.deviceId, isEmpty);
      expect(dto.deactivated, isTrue);
    });
  });
}
