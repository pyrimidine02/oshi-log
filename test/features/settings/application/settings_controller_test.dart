import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/providers/core_providers.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/settings/application/settings_controller.dart';
import 'package:oshi_log/features/settings/domain/entities/account_tools.dart';
import 'package:oshi_log/features/settings/domain/entities/consent_history.dart';
import 'package:oshi_log/features/settings/domain/entities/notification_settings.dart';
import 'package:oshi_log/features/settings/domain/entities/privacy_rights.dart';
import 'package:oshi_log/features/settings/domain/entities/user_profile.dart';
import 'package:oshi_log/features/settings/domain/repositories/settings_repository.dart';

void main() {
  group('UserProfileController', () {
    test('emits null profile when unauthenticated', () async {
      final container = ProviderContainer(
        overrides: [isAuthenticatedProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userProfileControllerProvider.notifier);
      await notifier.load();

      final state = container.read(userProfileControllerProvider);
      expect(state.valueOrNull, isNull);
      expect(state.hasError, isFalse);
    });
  });

  group('ProjectRoleRequestsController', () {
    const projectUuid = '550e8400-e29b-41d4-a716-446655440001';

    test('rejects unsupported requested role before repository call', () async {
      final repository = _FakeSettingsRepository(
        fetchSettingsResult: Result.success(NotificationSettings.initial()),
        updateSettingsResult: Result.success(NotificationSettings.initial()),
        deactivateResult: const Result.success(null),
        projectRoleRequestsResult: const Result.success(<ProjectRoleRequest>[]),
      );
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          selectedProjectIdProvider.overrideWith((ref) => projectUuid),
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        projectRoleRequestsControllerProvider.notifier,
      );
      final result = await notifier.create(
        requestedRole: 'ADMIN',
        justification: '유효하지 않은 역할 요청을 검증합니다. 테스트용 사유입니다.',
      );

      expect(result, isA<Err<ProjectRoleRequest>>());
      final failure = (result as Err<ProjectRoleRequest>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'invalid_requested_role');
      expect(repository.createRoleRequestCalls, 0);
    });

    test('requires UUID project id for role request body', () async {
      final repository = _FakeSettingsRepository(
        fetchSettingsResult: Result.success(NotificationSettings.initial()),
        updateSettingsResult: Result.success(NotificationSettings.initial()),
        deactivateResult: const Result.success(null),
        projectRoleRequestsResult: const Result.success(<ProjectRoleRequest>[]),
      );
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          selectedProjectIdProvider.overrideWith((ref) => 'girls-band-cry'),
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        projectRoleRequestsControllerProvider.notifier,
      );
      final result = await notifier.create(
        requestedRole: 'PLACE_EDITOR',
        justification: '프로젝트 UUID 필수 검증을 위한 충분한 길이의 테스트 사유입니다.',
      );

      expect(result, isA<Err<ProjectRoleRequest>>());
      final failure = (result as Err<ProjectRoleRequest>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'project_uuid_required');
      expect(repository.createRoleRequestCalls, 0);
    });

    test(
      'normalizes allowed role and forwards request to repository',
      () async {
        final created = ProjectRoleRequest(
          id: 'req-1',
          projectId: projectUuid,
          requestedRole: 'COMMUNITY_MODERATOR',
          status: 'PENDING',
          justification: '프로젝트 커뮤니티 운영 지원을 위해 권한을 요청합니다.',
          createdAt: DateTime.utc(2026, 3, 10),
        );
        final repository = _FakeSettingsRepository(
          fetchSettingsResult: Result.success(NotificationSettings.initial()),
          updateSettingsResult: Result.success(NotificationSettings.initial()),
          deactivateResult: const Result.success(null),
          projectRoleRequestsResult: const Result.success(
            <ProjectRoleRequest>[],
          ),
          createRoleRequestResult: Result.success(created),
        );
        final container = ProviderContainer(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => true),
            selectedProjectIdProvider.overrideWith((ref) => projectUuid),
            settingsRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          projectRoleRequestsControllerProvider.notifier,
        );
        final result = await notifier.create(
          requestedRole: 'community_moderator',
          justification: '커뮤니티 운영 지원을 위한 테스트 요청입니다. 충분히 긴 설명입니다.',
        );

        expect(result, isA<Success<ProjectRoleRequest>>());
        expect(repository.createRoleRequestCalls, 1);
        expect(repository.lastRequestedRole, 'COMMUNITY_MODERATOR');
        expect(repository.lastRequestedProjectId, projectUuid);
      },
    );
  });

  group('NotificationSettingsController', () {
    test('keeps OFF and succeeds when device deactivation succeeds', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        SecureStorageKeys.notificationDeviceId: 'secure-123',
        SecureStorageKeys.notificationPushToken: 'secure-token',
      });
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.notificationDeviceIdLegacy: 'legacy-ios-123',
        LocalStorageKeys.notificationPushToken: 'legacy-token',
      });
      final storage = await LocalStorage.create();
      final secureStorage = SecureStorage();
      const offSettings = NotificationSettings(
        pushEnabled: false,
        emailEnabled: true,
        categories: <String>[NotificationSettings.categoryComments],
      );

      final repository = _FakeSettingsRepository(
        fetchSettingsResult: Result.success(NotificationSettings.initial()),
        updateSettingsResult: const Result.success(offSettings),
        deactivateResult: const Result.success(null),
      );

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          localStorageProvider.overrideWith((ref) async => storage),
          secureStorageProvider.overrideWithValue(secureStorage),
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        notificationSettingsControllerProvider.notifier,
      );
      await notifier.load(forceRefresh: true);
      final result = await notifier.updateSettings(offSettings);

      expect(result, isA<Success<NotificationSettings>>());
      expect(repository.deactivateCalls, 1);
      expect(repository.lastDeactivatedDeviceId, 'secure-123');
      expect(await secureStorage.getNotificationDeviceId(), isNull);
      expect(await secureStorage.getNotificationPushToken(), isNull);
      expect(
        storage.getString(LocalStorageKeys.notificationDeviceIdLegacy),
        isNull,
      );
      expect(storage.getString(LocalStorageKeys.notificationPushToken), isNull);
      expect(
        container
            .read(notificationSettingsControllerProvider)
            .valueOrNull
            ?.pushEnabled,
        isFalse,
      );
    });

    test(
      'keeps OFF and succeeds even when device deactivation fails',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        SharedPreferences.setMockInitialValues({
          LocalStorageKeys.notificationDeviceIdLegacy: 'legacy-ios-456',
        });
        final storage = await LocalStorage.create();
        final secureStorage = SecureStorage();
        const offSettings = NotificationSettings(
          pushEnabled: false,
          emailEnabled: true,
          categories: <String>[NotificationSettings.categoryComments],
        );

        final repository = _FakeSettingsRepository(
          fetchSettingsResult: Result.success(NotificationSettings.initial()),
          updateSettingsResult: const Result.success(offSettings),
          deactivateResult: const Result.failure(
            NetworkFailure('Connection error', code: 'connection_error'),
          ),
        );

        final container = ProviderContainer(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => true),
            localStorageProvider.overrideWith((ref) async => storage),
            secureStorageProvider.overrideWithValue(secureStorage),
            settingsRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );
        await notifier.load(forceRefresh: true);
        final result = await notifier.updateSettings(offSettings);

        expect(result, isA<Success<NotificationSettings>>());
        expect(repository.deactivateCalls, 1);
        expect(
          container
              .read(notificationSettingsControllerProvider)
              .valueOrNull
              ?.pushEnabled,
          isFalse,
        );
        expect(
          storage.getString(LocalStorageKeys.notificationDeviceIdLegacy),
          'legacy-ios-456',
        );
        expect(await secureStorage.getNotificationDeviceId(), isNull);
        expect(await secureStorage.getNotificationPushToken(), isNull);
      },
    );

    test('serializes rapid updates and keeps latest settings', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      const initialSettings = NotificationSettings(
        pushEnabled: true,
        emailEnabled: true,
        categories: <String>[NotificationSettings.categoryComments],
      );
      const offSettings = NotificationSettings(
        pushEnabled: false,
        emailEnabled: true,
        categories: <String>[NotificationSettings.categoryComments],
      );
      const latestSettings = NotificationSettings(
        pushEnabled: false,
        emailEnabled: false,
        categories: <String>[NotificationSettings.categoryComments],
      );

      final firstCallRelease = Completer<void>();
      var updateCallCount = 0;
      final repository = _FakeSettingsRepository(
        fetchSettingsResult: const Result.success(initialSettings),
        updateSettingsResult: const Result.success(initialSettings),
        deactivateResult: const Result.success(null),
        onUpdateSettings: (settings) async {
          updateCallCount += 1;
          if (updateCallCount == 1) {
            await firstCallRelease.future;
          }
          return Result.success(settings);
        },
      );

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          localStorageProvider.overrideWith((ref) async => storage),
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        notificationSettingsControllerProvider.notifier,
      );
      await notifier.load(forceRefresh: true);

      final firstFuture = notifier.updateSettings(offSettings);
      final secondFuture = notifier.updateSettings(latestSettings);
      await Future<void>.delayed(Duration.zero);
      firstCallRelease.complete();

      final firstResult = await firstFuture;
      final secondResult = await secondFuture;

      expect(firstResult, isA<Success<NotificationSettings>>());
      expect(secondResult, isA<Success<NotificationSettings>>());
      expect(updateCallCount, 2);
      expect(repository.updateSettingsCalls, 2);
      expect(
        container
            .read(notificationSettingsControllerProvider)
            .valueOrNull
            ?.pushEnabled,
        isFalse,
      );
      expect(
        container
            .read(notificationSettingsControllerProvider)
            .valueOrNull
            ?.emailEnabled,
        isFalse,
      );
    });

    test('retries once for transient server error and then succeeds', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.create();
      const initialSettings = NotificationSettings(
        pushEnabled: true,
        emailEnabled: true,
        categories: <String>[NotificationSettings.categoryComments],
      );
      const offSettings = NotificationSettings(
        pushEnabled: false,
        emailEnabled: true,
        categories: <String>[NotificationSettings.categoryComments],
      );
      var updateCallCount = 0;
      final repository = _FakeSettingsRepository(
        fetchSettingsResult: const Result.success(initialSettings),
        updateSettingsResult: const Result.success(offSettings),
        deactivateResult: const Result.success(null),
        onUpdateSettings: (settings) async {
          updateCallCount += 1;
          if (updateCallCount == 1) {
            return const Result.failure(
              ServerFailure('Temporary server error', code: '500'),
            );
          }
          return Result.success(settings);
        },
      );

      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => true),
          localStorageProvider.overrideWith((ref) async => storage),
          settingsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        notificationSettingsControllerProvider.notifier,
      );
      await notifier.load(forceRefresh: true);
      final result = await notifier.updateSettings(offSettings);

      expect(result, isA<Success<NotificationSettings>>());
      expect(updateCallCount, 2);
      expect(repository.updateSettingsCalls, 2);
      expect(
        container
            .read(notificationSettingsControllerProvider)
            .valueOrNull
            ?.pushEnabled,
        isFalse,
      );
    });

    test(
      'retries with details.current snapshot for notification version conflict',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.create();
        const initialSettings = NotificationSettings(
          pushEnabled: true,
          emailEnabled: true,
          categories: <String>[
            NotificationSettings.categoryComments,
            NotificationSettings.categoryLiveEvents,
          ],
          version: 12,
        );
        const desiredSettings = NotificationSettings(
          pushEnabled: true,
          emailEnabled: false,
          categories: <String>[
            NotificationSettings.categoryComments,
            NotificationSettings.categoryFollowingPost,
          ],
          version: 12,
        );

        var updateCallCount = 0;
        NotificationSettings? retriedPayload;
        final repository = _FakeSettingsRepository(
          fetchSettingsResult: const Result.success(initialSettings),
          updateSettingsResult: const Result.success(desiredSettings),
          deactivateResult: const Result.success(null),
          onUpdateSettings: (settings) async {
            updateCallCount += 1;
            if (updateCallCount == 1) {
              return Result.failure(
                ValidationFailure(
                  'conflict',
                  code: 'NOTIFICATION_SETTINGS_VERSION_CONFLICT',
                  details: {
                    'expectedVersion': 12,
                    'currentVersion': 13,
                    'current': {
                      'pushEnabled': true,
                      'emailEnabled': true,
                      'categories': ['COMMENT', 'FAVORITE', 'FOLLOWING_POST'],
                      'version': 13,
                      'updatedAt': '2026-03-10T03:13:41.641Z',
                    },
                  },
                ),
              );
            }
            retriedPayload = settings;
            return Result.success(settings.copyWith(version: 14));
          },
        );

        final container = ProviderContainer(
          overrides: [
            isAuthenticatedProvider.overrideWith((ref) => true),
            localStorageProvider.overrideWith((ref) async => storage),
            settingsRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );
        await notifier.load(forceRefresh: true);
        final result = await notifier.updateSettings(desiredSettings);

        expect(result, isA<Success<NotificationSettings>>());
        expect(updateCallCount, 2);
        expect(retriedPayload, isNotNull);
        expect(retriedPayload!.version, 13);
        expect(retriedPayload!.emailEnabled, isFalse);
        expect(retriedPayload!.followingPostsEnabled, isTrue);
        expect(
          container
              .read(notificationSettingsControllerProvider)
              .valueOrNull
              ?.version,
          14,
        );
      },
    );
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    required this.fetchSettingsResult,
    required this.updateSettingsResult,
    required this.deactivateResult,
    this.projectRoleRequestsResult = const Result.success(
      <ProjectRoleRequest>[],
    ),
    this.createRoleRequestResult = const Result.failure(
      UnknownFailure('project role request result not configured'),
    ),
    this.onUpdateSettings,
  });

  final Result<NotificationSettings> fetchSettingsResult;
  final Result<NotificationSettings> updateSettingsResult;
  final Result<void> deactivateResult;
  final Result<List<ProjectRoleRequest>> projectRoleRequestsResult;
  final Result<ProjectRoleRequest> createRoleRequestResult;
  final Future<Result<NotificationSettings>> Function(
    NotificationSettings settings,
  )?
  onUpdateSettings;
  int deactivateCalls = 0;
  int updateSettingsCalls = 0;
  int createRoleRequestCalls = 0;
  String? lastRequestedProjectId;
  String? lastRequestedRole;
  String? lastDeactivatedDeviceId;

  @override
  Future<Result<NotificationSettings>> getNotificationSettings({
    bool forceRefresh = false,
  }) async {
    return fetchSettingsResult;
  }

  @override
  Future<Result<NotificationSettings>> updateNotificationSettings({
    required NotificationSettings settings,
  }) async {
    updateSettingsCalls += 1;
    final callback = onUpdateSettings;
    if (callback != null) {
      return callback(settings);
    }
    return updateSettingsResult;
  }

  @override
  Future<Result<void>> deactivateNotificationDevice({
    required String deviceId,
  }) async {
    deactivateCalls += 1;
    lastDeactivatedDeviceId = deviceId;
    return deactivateResult;
  }

  @override
  Future<Result<PrivacySettings>> getPrivacySettings({
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<PrivacySettings>> updatePrivacySettings({
    required bool allowAutoTranslation,
    int? version,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<PrivacyRequestRecord>>> getPrivacyRequests({
    bool forceRefresh = false,
    int page = 0,
    int size = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<PrivacyRequestRecord>> createPrivacyRequest({
    required String requestType,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ConsentHistoryItem>>> getConsentHistory({
    bool forceRefresh = false,
    int page = 0,
    int size = 50,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Map<String, dynamic>>> getMandatoryConsentStatus() {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> submitMandatoryConsents({
    required List<Map<String, dynamic>> consents,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deleteAccount() {
    throw UnimplementedError();
  }

  @override
  Future<Result<UserProfile>> getUserProfile({bool forceRefresh = false}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<UserProfile>> getUserProfileById({
    required String userId,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<UserProfile>> updateUserProfile({
    required String displayName,
    String? avatarUrl,
    String? bio,
    String? coverImageUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<UserBlock>>> getUserBlocks({bool forceRefresh = false}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> unblockUser({required String targetUserId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ProjectRoleRequest>>> getProjectRoleRequests({
    bool forceRefresh = false,
    String? status,
  }) async {
    return projectRoleRequestsResult;
  }

  @override
  Future<Result<ProjectRoleRequest>> createProjectRoleRequest({
    required String projectId,
    required String requestedRole,
    required String justification,
  }) async {
    createRoleRequestCalls += 1;
    lastRequestedProjectId = projectId;
    lastRequestedRole = requestedRole;
    return createRoleRequestResult;
  }

  @override
  Future<Result<void>> cancelProjectRoleRequest({required String requestId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<VerificationAppeal>>> getVerificationAppeals({
    required String projectId,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<VerificationAppeal>> createVerificationAppeal({
    required String projectId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
    List<String> evidenceUrls = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<RestoreAccountResult>> restoreAccount() {
    throw UnimplementedError();
  }
}
