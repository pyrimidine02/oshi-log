import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/platform/notifications/local_notifications_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('permission status on $platform reads without requesting', () async {
      debugDefaultTargetPlatformOverride = platform;
      if (platform == TargetPlatform.android) {
        AndroidFlutterLocalNotificationsPlugin.registerWith();
      } else {
        IOSFlutterLocalNotificationsPlugin.registerWith();
      }
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <String>[];
      var enabled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'areNotificationsEnabled') {
              return enabled;
            }
            if (call.method == 'checkPermissions') {
              return {
                'isEnabled': enabled,
                'isSoundEnabled': enabled,
                'isAlertEnabled': enabled,
                'isBadgeEnabled': enabled,
                'isProvisionalEnabled': false,
                'isCriticalEnabled': false,
                'isProvidesAppNotificationSettingsEnabled': false,
              };
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final service = LocalNotificationsService();
      addTearDown(service.dispose);
      expect(await service.hasPermission(), isFalse);
      enabled = true;
      expect(await service.hasPermission(), isTrue);
      expect(calls, [
        platform == TargetPlatform.android
            ? 'areNotificationsEnabled'
            : 'checkPermissions',
        platform == TargetPlatform.android
            ? 'areNotificationsEnabled'
            : 'checkPermissions',
      ]);
    });
  }

  test('unsupported platform permission is unknown', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final service = LocalNotificationsService();
    addTearDown(service.dispose);
    expect(await service.hasPermission(), isNull);
  });
}
