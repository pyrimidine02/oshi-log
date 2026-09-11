/// EN: Settings repository implementation with caching.
/// KO: 캐시를 포함한 설정 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/account_tools.dart';
import '../../domain/entities/consent_history.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/privacy_rights.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../dto/account_tools_dto.dart';
import '../dto/consent_history_dto.dart';
import '../dto/notification_device_dto.dart';
import '../dto/notification_settings_dto.dart';
import '../dto/privacy_rights_dto.dart';
import '../dto/user_access_level_dto.dart';
import '../dto/user_profile_dto.dart';
import '../mappers/account_tools_mappers.dart';
import '../mappers/consent_history_mappers.dart';
import '../mappers/notification_settings_mappers.dart';
import '../mappers/privacy_rights_mappers.dart';
import '../mappers/user_profile_mappers.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final SettingsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  @override
  Future<Result<UserProfile>> getUserProfile({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsUserProfile;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<UserProfileDto>(
        key: _profileCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchUserProfile,
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => UserProfileDto.fromJson(json),
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UserProfile>> getUserProfileById({
    required String userId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsUserProfileById;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<UserProfileDto>(
        key: _userProfileCacheKey(userId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchUserProfileById(userId),
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => UserProfileDto.fromJson(json),
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UserProfile>> updateUserProfile({
    required String displayName,
    String? avatarUrl,
    String? bio,
    String? coverImageUrl,
  }) async {
    try {
      final result = await _remoteDataSource.updateUserProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
        coverImageUrl: coverImageUrl,
      );

      if (result is Success<UserProfileDto>) {
        await _cacheManager.setJson(
          _profileCacheKey,
          result.data.toJson(),
          ttl: CacheProfiles.settingsUserProfile.ttl,
        );
        return Result.success(result.data.toDomain());
      }
      if (result is Err<UserProfileDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown user profile update result',
          code: 'unknown_profile_update',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<NotificationSettings>> getNotificationSettings({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsNotificationSettings;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<NotificationSettingsDto>(
        key: _notificationCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchNotificationSettings,
        toJson: (dto) => dto.toJson(),
        fromJson: (json) => NotificationSettingsDto.fromJson(json),
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<NotificationSettings>> updateNotificationSettings({
    required NotificationSettings settings,
  }) async {
    try {
      final dto = NotificationSettingsDto(
        pushEnabled: settings.pushEnabled,
        emailEnabled: settings.emailEnabled,
        categories: settings.categories,
        version: settings.version,
      );
      final result = await _remoteDataSource.updateNotificationSettings(
        settings: dto,
      );

      if (result is Success<NotificationSettingsDto>) {
        await _cacheManager.setJson(
          _notificationCacheKey,
          result.data.toJson(),
          ttl: CacheProfiles.settingsNotificationSettings.ttl,
        );
        return Result.success(result.data.toDomain());
      }
      if (result is Err<NotificationSettingsDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown notification settings update result',
          code: 'unknown_notification_update',
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void>> deactivateNotificationDevice({
    required String deviceId,
  }) async {
    try {
      final result = await _remoteDataSource.deactivateNotificationDevice(
        deviceId: deviceId,
      );

      if (result is Success<NotificationDeviceDeactivationDto>) {
        // EN: Treat any 200 success as successful deactivation intent.
        // KO: 200 성공 응답은 deactivated 값과 무관하게 해제 의도 성공으로 처리합니다.
        return const Result.success(null);
      }
      if (result is Err<NotificationDeviceDeactivationDto>) {
        return Result.failure(result.failure);
      }

      return Result.failure(
        const UnknownFailure(
          'Unknown notification device deactivate result',
          code: 'unknown_notification_device_deactivate',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<PrivacySettings>> getPrivacySettings({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsPrivacySettings;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    try {
      final cacheResult = await _cacheManager.resolve<PrivacySettingsDto>(
        key: _privacySettingsCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchPrivacySettings,
        toJson: (dto) => <String, dynamic>{
          'allowAutoTranslation': dto.allowAutoTranslation,
          if (dto.version != null) 'version': dto.version,
          if (dto.updatedAt != null)
            'updatedAt': dto.updatedAt!.toIso8601String(),
        },
        fromJson: PrivacySettingsDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<PrivacySettings>> updatePrivacySettings({
    required bool allowAutoTranslation,
    int? version,
  }) async {
    try {
      final result = await _remoteDataSource.updatePrivacySettings(
        allowAutoTranslation: allowAutoTranslation,
        version: version,
      );
      if (result is Success<PrivacySettingsDto>) {
        await _cacheManager.setJson(_privacySettingsCacheKey, <String, dynamic>{
          'allowAutoTranslation': result.data.allowAutoTranslation,
          if (result.data.version != null) 'version': result.data.version,
          if (result.data.updatedAt != null)
            'updatedAt': result.data.updatedAt!.toIso8601String(),
        }, ttl: CacheProfiles.settingsPrivacySettings.ttl);
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PrivacySettingsDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown privacy settings update result',
          code: 'unknown_privacy_settings_update',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<PrivacyRequestRecord>>> getPrivacyRequests({
    bool forceRefresh = false,
    int page = 0,
    int size = 20,
  }) async {
    final profile = CacheProfiles.settingsPrivacyRequests;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey = _privacyRequestsCacheKey(page, size);
    try {
      final cacheResult = await _cacheManager
          .resolve<List<PrivacyRequestRecordDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchPrivacyRequests(page: page, size: size),
            toJson: (dtos) => <String, dynamic>{
              'items': dtos.map((dto) => dto.toJson()).toList(growable: false),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is! List) {
                return const <PrivacyRequestRecordDto>[];
              }
              return items
                  .whereType<Map<String, dynamic>>()
                  .map(PrivacyRequestRecordDto.fromJson)
                  .toList(growable: false);
            },
          );
      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<PrivacyRequestRecord>> createPrivacyRequest({
    required String requestType,
    required String reason,
  }) async {
    try {
      final result = await _remoteDataSource.createPrivacyRequest(
        requestType: requestType,
        reason: reason,
      );
      if (result is Success<PrivacyRequestRecordDto>) {
        await _cacheManager.removeByPrefix('privacy_requests:');
        return Result.success(result.data.toDomain());
      }
      if (result is Err<PrivacyRequestRecordDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown privacy request create result',
          code: 'unknown_privacy_request_create',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ConsentHistoryItem>>> getConsentHistory({
    bool forceRefresh = false,
    int page = 0,
    int size = 50,
  }) async {
    final profile = CacheProfiles.settingsConsentHistory;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey = _consentHistoryCacheKey(page, size);
    try {
      final cacheResult = await _cacheManager
          .resolve<List<ConsentHistoryItemDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchConsentHistory(page: page, size: size),
            toJson: (dtos) => <String, dynamic>{
              'items': dtos.map((dto) => dto.toJson()).toList(growable: false),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is! List) {
                return const <ConsentHistoryItemDto>[];
              }
              return items
                  .whereType<Map<String, dynamic>>()
                  .map(ConsentHistoryItemDto.fromJson)
                  .toList(growable: false);
            },
          );
      final mapped = cacheResult.data
          .map((value) => value.toDomain())
          .toList(growable: false);
      mapped.sort((a, b) {
        final bTime = b.agreedAt;
        final aTime = a.agreedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return Result.success(mapped);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getMandatoryConsentStatus() async {
    try {
      final result = await _remoteDataSource.fetchMandatoryConsentStatus();
      if (result is Success<Map<String, dynamic>>) {
        return Result.success(result.data);
      }
      if (result is Err<Map<String, dynamic>>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown mandatory consent status result',
          code: 'unknown_mandatory_consent_status',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> submitMandatoryConsents({
    required List<Map<String, dynamic>> consents,
  }) async {
    try {
      final result = await _remoteDataSource.submitMandatoryConsents(
        consents: consents,
      );
      if (result is Success<void>) {
        await _cacheManager.removeByPrefix('consent_history:');
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown mandatory consent submit result',
          code: 'unknown_mandatory_consent_submit',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      final result = await _remoteDataSource.deleteAccount();
      if (result is Success<void>) {
        return const Result.success(null);
      }
      if (result is Err<void>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown delete account result',
          code: 'unknown_delete_account',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<RestoreAccountResult>> restoreAccount() async {
    try {
      final result = await _remoteDataSource.restoreAccount();
      if (result is Success<RestoreAccountResultDto>) {
        return Result.success(result.data.toDomain());
      }
      if (result is Err<RestoreAccountResultDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown restore account result',
          code: 'unknown_restore_account',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<UserBlock>>> getUserBlocks({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsUserBlocks;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    try {
      final cacheResult = await _cacheManager.resolve<List<UserBlockDto>>(
        key: _userBlocksCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchUserBlocks,
        toJson: (dtos) => {'items': dtos.map(_userBlockToJson).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(UserBlockDto.fromJson)
                .toList(growable: false);
          }
          return const <UserBlockDto>[];
        },
      );
      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> unblockUser({required String targetUserId}) async {
    try {
      final result = await _remoteDataSource.unblockUser(
        targetUserId: targetUserId,
      );
      if (result is Success<void>) {
        await _cacheManager.remove(_userBlocksCacheKey);
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<ProjectRoleRequest>>> getProjectRoleRequests({
    bool forceRefresh = false,
    String? status,
  }) async {
    final profile = CacheProfiles.settingsProjectRoleRequests;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey = _projectRoleRequestsCacheKey(status);
    try {
      final cacheResult = await _cacheManager
          .resolve<List<ProjectRoleRequestDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchProjectRoleRequests(status: status),
            toJson: (dtos) => {
              'items': dtos.map(_projectRoleRequestToJson).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(ProjectRoleRequestDto.fromJson)
                    .toList(growable: false);
              }
              return const <ProjectRoleRequestDto>[];
            },
          );
      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<ProjectRoleRequest>> createProjectRoleRequest({
    required String projectId,
    required String requestedRole,
    required String justification,
  }) async {
    final normalizedRole = requestedRole.trim().toUpperCase();
    if (normalizedRole != 'PLACE_EDITOR' &&
        normalizedRole != 'COMMUNITY_MODERATOR') {
      return const Result.failure(
        ValidationFailure(
          'Requested role must be PLACE_EDITOR or COMMUNITY_MODERATOR',
          code: 'invalid_requested_role',
        ),
      );
    }

    try {
      final result = await _remoteDataSource.createProjectRoleRequest(
        request: ProjectRoleRequestCreateRequestDto(
          projectId: projectId,
          requestedRole: normalizedRole,
          justification: justification,
        ),
      );
      if (result is Success<ProjectRoleRequestDto>) {
        await _cacheManager.removeByPrefix('project_role_requests:');
        return Result.success(result.data.toDomain());
      }
      if (result is Err<ProjectRoleRequestDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown project role request create result',
          code: 'unknown_project_role_request_create',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> cancelProjectRoleRequest({
    required String requestId,
  }) async {
    try {
      final result = await _remoteDataSource.cancelProjectRoleRequest(
        requestId: requestId,
      );
      if (result is Success<void>) {
        await _cacheManager.removeByPrefix('project_role_requests:');
      }
      return result;
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<List<VerificationAppeal>>> getVerificationAppeals({
    required String projectId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.settingsVerificationAppeals;
    final policy = profile.policyFor(forceRefresh: forceRefresh);
    final cacheKey = _verificationAppealsCacheKey(projectId);
    try {
      final cacheResult = await _cacheManager
          .resolve<List<VerificationAppealDto>>(
            key: cacheKey,
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchVerificationAppeals(projectId),
            toJson: (dtos) => {
              'items': dtos.map(_verificationAppealToJson).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(VerificationAppealDto.fromJson)
                    .toList(growable: false);
              }
              return const <VerificationAppealDto>[];
            },
          );
      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<VerificationAppeal>> createVerificationAppeal({
    required String projectId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
    List<String> evidenceUrls = const [],
  }) async {
    try {
      final result = await _remoteDataSource.createVerificationAppeal(
        projectId: projectId,
        request: VerificationAppealCreateRequestDto(
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          description: description,
          evidenceUrls: evidenceUrls,
        ),
      );
      if (result is Success<VerificationAppealDto>) {
        await _cacheManager.remove(_verificationAppealsCacheKey(projectId));
        return Result.success(result.data.toDomain());
      }
      if (result is Err<VerificationAppealDto>) {
        return Result.failure(result.failure);
      }
      return Result.failure(
        const UnknownFailure(
          'Unknown verification appeal create result',
          code: 'unknown_verification_appeal_create',
        ),
      );
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  Future<UserProfileDto> _fetchUserProfile() async {
    final profileFuture = _remoteDataSource.fetchUserProfile();
    final accessLevelFuture = _remoteDataSource.fetchUserAccessLevel();

    final profileResult = await profileFuture;
    if (profileResult is! Success<UserProfileDto>) {
      if (profileResult is Err<UserProfileDto>) {
        throw profileResult.failure;
      }
      throw const UnknownFailure(
        'Unknown user profile result',
        code: 'unknown_profile',
      );
    }

    final profileDto = profileResult.data;
    final accessLevelResult = await accessLevelFuture;
    if (accessLevelResult is Success<UserAccessLevelDto>) {
      return profileDto.mergeAccessLevel(accessLevelResult.data);
    }
    if (accessLevelResult is Err<UserAccessLevelDto>) {
      if (accessLevelResult.failure is AuthFailure) {
        throw accessLevelResult.failure;
      }
      AppLogger.warning(
        'Failed to fetch /users/me/access-level; fallback to /users/me payload',
        data: accessLevelResult.failure,
        tag: 'SettingsRepository',
      );
      return profileDto;
    }

    return profileDto;
  }

  Future<UserProfileDto> _fetchUserProfileById(String userId) async {
    final result = await _remoteDataSource.fetchUserProfileById(userId);

    if (result is Success<UserProfileDto>) {
      return result.data;
    }
    if (result is Err<UserProfileDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown user profile by id result',
      code: 'unknown_profile_by_id',
    );
  }

  Future<NotificationSettingsDto> _fetchNotificationSettings() async {
    final result = await _remoteDataSource.fetchNotificationSettings();

    if (result is Success<NotificationSettingsDto>) {
      return result.data;
    }
    if (result is Err<NotificationSettingsDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown notification settings result',
      code: 'unknown_notification_settings',
    );
  }

  Future<PrivacySettingsDto> _fetchPrivacySettings() async {
    final result = await _remoteDataSource.fetchPrivacySettings();
    if (result is Success<PrivacySettingsDto>) {
      return result.data;
    }
    if (result is Err<PrivacySettingsDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown privacy settings result',
      code: 'unknown_privacy_settings',
    );
  }

  Future<List<PrivacyRequestRecordDto>> _fetchPrivacyRequests({
    required int page,
    required int size,
  }) async {
    final result = await _remoteDataSource.fetchPrivacyRequests(
      page: page,
      size: size,
    );
    if (result is Success<List<PrivacyRequestRecordDto>>) {
      return result.data;
    }
    if (result is Err<List<PrivacyRequestRecordDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown privacy requests result',
      code: 'unknown_privacy_requests',
    );
  }

  Future<List<ConsentHistoryItemDto>> _fetchConsentHistory({
    required int page,
    required int size,
  }) async {
    final result = await _remoteDataSource.fetchConsentHistory(
      page: page,
      size: size,
    );
    if (result is Success<List<ConsentHistoryItemDto>>) {
      return result.data;
    }
    if (result is Err<List<ConsentHistoryItemDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown consent history result',
      code: 'unknown_consent_history',
    );
  }

  Future<List<UserBlockDto>> _fetchUserBlocks() async {
    final result = await _remoteDataSource.fetchUserBlocks();
    if (result is Success<List<UserBlockDto>>) {
      return result.data;
    }
    if (result is Err<List<UserBlockDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown user blocks result',
      code: 'unknown_user_blocks',
    );
  }

  Future<List<ProjectRoleRequestDto>> _fetchProjectRoleRequests({
    String? status,
  }) async {
    final result = await _remoteDataSource.fetchProjectRoleRequests(
      status: status,
    );
    if (result is Success<List<ProjectRoleRequestDto>>) {
      return result.data;
    }
    if (result is Err<List<ProjectRoleRequestDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown project role requests result',
      code: 'unknown_project_role_requests',
    );
  }

  Future<List<VerificationAppealDto>> _fetchVerificationAppeals(
    String projectId,
  ) async {
    final result = await _remoteDataSource.fetchVerificationAppeals(
      projectId: projectId,
    );
    if (result is Success<List<VerificationAppealDto>>) {
      return result.data;
    }
    if (result is Err<List<VerificationAppealDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown verification appeals result',
      code: 'unknown_verification_appeals',
    );
  }

  static const String _profileCacheKey = 'user_profile';
  static const String _notificationCacheKey = 'notification_settings';
  static const String _privacySettingsCacheKey = 'privacy_settings';
  static const String _userBlocksCacheKey = 'user_blocks';
  static const String _projectRoleRequestsCacheKeyPrefix =
      'project_role_requests';

  String _userProfileCacheKey(String userId) {
    return 'user_profile:$userId';
  }

  String _verificationAppealsCacheKey(String projectId) {
    return 'verification_appeals:$projectId';
  }

  String _projectRoleRequestsCacheKey(String? status) {
    final normalized = status == null || status.trim().isEmpty
        ? 'ALL'
        : status.trim().toUpperCase();
    return '$_projectRoleRequestsCacheKeyPrefix:$normalized';
  }

  String _privacyRequestsCacheKey(int page, int size) {
    return 'privacy_requests:$page:$size';
  }

  String _consentHistoryCacheKey(int page, int size) {
    return 'consent_history:$page:$size';
  }
}

Map<String, dynamic> _blockedUserToJson(BlockedUserDto dto) {
  return {
    'id': dto.id,
    'displayName': dto.displayName,
    if (dto.avatarUrl != null) 'avatarUrl': dto.avatarUrl,
  };
}

Map<String, dynamic> _userBlockToJson(UserBlockDto dto) {
  return {
    'id': dto.id,
    'blockedUser': _blockedUserToJson(dto.blockedUser),
    if (dto.reason != null) 'reason': dto.reason,
    'createdAt': dto.createdAt.toIso8601String(),
  };
}

Map<String, dynamic> _projectRoleRequestToJson(ProjectRoleRequestDto dto) {
  return {
    'id': dto.id,
    'projectId': dto.projectId,
    if (dto.projectCode != null) 'projectCode': dto.projectCode,
    if (dto.projectName != null) 'projectName': dto.projectName,
    'requestedRole': dto.requestedRole,
    'status': dto.status,
    'justification': dto.justification,
    'createdAt': dto.createdAt.toIso8601String(),
    if (dto.adminMemo != null) 'adminMemo': dto.adminMemo,
    if (dto.reviewedAt != null) 'reviewedAt': dto.reviewedAt!.toIso8601String(),
    if (dto.reviewerId != null) 'reviewerId': dto.reviewerId,
    if (dto.reviewerName != null) 'reviewerName': dto.reviewerName,
  };
}

Map<String, dynamic> _verificationAppealToJson(VerificationAppealDto dto) {
  return {
    'id': dto.id,
    'targetType': dto.targetType,
    'targetId': dto.targetId,
    if (dto.placeId != null) 'placeId': dto.placeId,
    'reason': dto.reason,
    if (dto.description != null) 'description': dto.description,
    'evidenceUrls': dto.evidenceUrls,
    'status': dto.status,
    if (dto.reviewerMemo != null) 'reviewerMemo': dto.reviewerMemo,
    'createdAt': dto.createdAt.toIso8601String(),
    if (dto.resolvedAt != null) 'resolvedAt': dto.resolvedAt!.toIso8601String(),
  };
}
