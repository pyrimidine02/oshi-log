import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/shared/notifications/application/notifications_controller.dart';
import 'package:oshi_log/features/shared/notifications/domain/entities/notification_entities.dart';
import 'package:oshi_log/features/shared/notifications/domain/repositories/notifications_repository.dart';
import 'package:oshi_log/platform/notifications/local_notifications_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed single and bulk deletion preserve notifications for retry',
    () async {
      final repository = _Repository()..items = [_item('one'), _item('two')];
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          notificationsRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        notificationsControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.deleteNotification('one');
      expect(
        container.read(notificationsControllerProvider).value!.map((e) => e.id),
        ['one', 'two'],
      );
      await controller.deleteAllNotifications();
      expect(
        container.read(notificationsControllerProvider).value!.map((e) => e.id),
        ['one', 'two'],
      );
      repository.failDelete = false;
      await controller.deleteNotification('one');
      expect(
        container.read(notificationsControllerProvider).value!.map((e) => e.id),
        ['two'],
      );
      await controller.deleteAllNotifications();
      expect(container.read(notificationsControllerProvider).value, isEmpty);
    },
  );

  test(
    'incoming unread reads permission, never prompts, and follows permission changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _Repository();
      final local = _Local();
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          notificationsRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
          localStorageProvider.overrideWith((ref) => LocalStorage.create()),
          localNotificationsServiceProvider.overrideWithValue(local),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(local.dispose);
      final controller = container.read(
        notificationsControllerProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);

      repository.items = [_item('denied')];
      await controller.refreshInBackground(minInterval: Duration.zero);
      expect(local.requests, 0);
      expect(local.shown, isEmpty);
      expect(container.read(notificationsControllerProvider).value!.length, 1);

      local.granted = true;
      repository.items = [_item('granted'), ...repository.items];
      await controller.refreshInBackground(minInterval: Duration.zero);
      expect(local.requests, 0);
      expect(local.shown, ['granted']);

      local.granted = false;
      repository.items = [_item('revoked'), ...repository.items];
      await controller.refreshInBackground(minInterval: Duration.zero);
      expect(local.requests, 0);
      expect(local.shown, ['granted']);
    },
  );
}

NotificationItem _item(String id) => NotificationItem(
  id: id,
  title: id,
  body: 'Notice',
  createdAt: DateTime(2026, 10, 4),
  isRead: false,
);

class _Repository implements NotificationsRepository {
  List<NotificationItem> items = [];
  bool failDelete = true;
  @override
  Future<Result<void>> deleteNotification(String notificationId) async =>
      failDelete
      ? const Result.failure(NetworkFailure('offline'))
      : const Result.success(null);
  @override
  Future<Result<void>> deleteAllNotifications() async => failDelete
      ? const Result.failure(NetworkFailure('offline'))
      : const Result.success(null);
  @override
  Future<Result<List<NotificationItem>>> getNotifications({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async => Result.success(items);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Local extends LocalNotificationsService {
  bool granted = false;
  int requests = 0;
  final shown = <String>[];
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<bool> requestPermissions() async {
    requests++;
    return granted;
  }

  @override
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? type,
    String? deeplink,
    String? actionUrl,
    String? entityId,
    String? projectCode,
  }) async {
    shown.add(id);
  }
}
