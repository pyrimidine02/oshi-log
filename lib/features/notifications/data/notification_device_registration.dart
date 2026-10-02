/// EN: Notification device registration — register/unregister/open-tracking
///     against the backend. Lives in feature data so the platform messaging
///     layer never talks to the API directly.
/// KO: 알림 디바이스 등록/해제/열람 추적을 백엔드와 처리합니다. 플랫폼 메시징
///     레이어가 API를 직접 호출하지 않도록 feature data에 둡니다.
library;

import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/result.dart';

const String _kDeviceHashSalt = 'gbt-salt-v1';
final RegExp _kNotificationDeviceHashPattern = RegExp(r'^[0-9a-f]{64}$');
final RegExp _kIanaTimezonePattern = RegExp(
  r'^[A-Za-z_]+(?:/[A-Za-z0-9._+\-]+)+$',
);

/// EN: Compute salted SHA-256 hash for notification device fingerprinting.
/// KO: 알림 디바이스 지문용 salt 적용 SHA-256 해시를 계산합니다.
String computeNotificationDeviceHash(String rawDeviceId) {
  final normalizedRawDeviceId = rawDeviceId.trim();
  final digest = sha256.convert(
    utf8.encode('$normalizedRawDeviceId:$_kDeviceHashSalt'),
  );
  return digest.toString();
}

/// EN: Normalize and validate a notification device hash (64-char lowercase hex).
/// KO: 알림 디바이스 해시를 정규화/검증합니다 (64자 소문자 16진수).
String? normalizeNotificationDeviceHash(String? deviceHash) {
  if (deviceHash == null) {
    return null;
  }
  final normalized = deviceHash.trim().toLowerCase();
  if (normalized.isEmpty ||
      !_kNotificationDeviceHashPattern.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// EN: Normalize and validate IANA timezone names (for Quiet Hours).
/// KO: IANA 타임존 문자열을 정규화/검증합니다 (Quiet Hours 용).
String? normalizeNotificationTimezone(String? timezone) {
  if (timezone == null) {
    return null;
  }
  final normalized = timezone.trim();
  if (normalized.isEmpty || !_kIanaTimezonePattern.hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// EN: Build notification device registration payload with optional metadata.
/// KO: 선택 메타데이터를 포함한 알림 디바이스 등록 payload를 구성합니다.
Map<String, dynamic> buildNotificationDeviceRegistrationPayload({
  required String platform,
  required String provider,
  required String deviceId,
  required String pushToken,
  String? locale,
  String? timezone,
  String? deviceHash,
}) {
  final normalizedLocale = locale?.trim();
  final normalizedTimezone = normalizeNotificationTimezone(timezone);
  final normalizedDeviceHash = normalizeNotificationDeviceHash(deviceHash);

  return <String, dynamic>{
    'platform': platform,
    'provider': provider,
    'deviceId': deviceId,
    'pushToken': pushToken,
    if (normalizedLocale != null && normalizedLocale.isNotEmpty)
      'locale': normalizedLocale,
    if (normalizedTimezone != null) 'timezone': normalizedTimezone,
    if (normalizedDeviceHash != null) 'deviceHash': normalizedDeviceHash,
  };
}

/// EN: Owns notification device registration/unregistration/open-tracking.
/// KO: 알림 디바이스 등록/해제/열람 추적을 담당합니다.
class NotificationDeviceRegistration {
  NotificationDeviceRegistration({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
    required Future<LocalStorage> localStorageFuture,
    Future<String?> Function()? deviceHashResolver,
    Future<String?> Function()? timezoneResolver,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       _localStorageFuture = localStorageFuture,
       _deviceHashResolver = deviceHashResolver,
       _timezoneResolver = timezoneResolver;

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;
  final Future<LocalStorage> _localStorageFuture;
  final Future<String?> Function()? _deviceHashResolver;
  final Future<String?> Function()? _timezoneResolver;
  String? _cachedDeviceHash;
  String? _cachedTimezone;

  /// EN: Register or refresh the push token for this device.
  /// KO: 이 디바이스의 푸시 토큰을 등록하거나 갱신합니다.
  Future<void> upsertDeviceRegistration(
    String pushToken, {
    required String provider,
    required bool forceRegister,
  }) async {
    final storage = await _localStorageFuture;
    final existingDeviceId = await _resolveStoredDeviceId(storage);
    final deviceId = existingDeviceId ?? await _createAndStoreDeviceId(storage);
    if (deviceId.isEmpty) {
      return;
    }

    final shouldRegister = forceRegister || existingDeviceId == null;
    if (shouldRegister) {
      await _registerDevice(
        storage: storage,
        deviceId: deviceId,
        provider: provider,
        pushToken: pushToken,
      );
      return;
    }

    final patchResult = await _apiClient.patch<dynamic>(
      ApiEndpoints.notificationDeviceToken(deviceId),
      data: {'pushToken': pushToken, 'provider': provider},
    );
    if (patchResult is Success<dynamic>) {
      await _storeNotificationRegistration(
        storage: storage,
        deviceId: deviceId,
        pushToken: pushToken,
      );
      return;
    }

    if (patchResult is Err<dynamic>) {
      final failure = patchResult.failure;
      if (failure is NotFoundFailure && failure.code == '404') {
        await _registerDevice(
          storage: storage,
          deviceId: deviceId,
          provider: provider,
          pushToken: pushToken,
        );
        return;
      }
      AppLogger.warning(
        'Failed to update push token',
        data: failure,
        tag: 'NotificationDeviceRegistration',
      );
    }
  }

  /// EN: Deactivate current backend device registration and clear local keys.
  /// KO: 현재 백엔드 디바이스 등록을 비활성화하고 로컬 키를 정리합니다.
  Future<void> deactivateCurrentDevice() async {
    final storage = await _localStorageFuture;
    final deviceId = await _resolveStoredDeviceId(
      storage,
      migrateLegacyKeys: false,
    );
    if (deviceId == null || deviceId.isEmpty) {
      return;
    }

    final result = await _apiClient.delete<dynamic>(
      ApiEndpoints.notificationDevice(deviceId),
    );

    if (result is Success<dynamic>) {
      await _clearNotificationRegistration(storage);
      return;
    }

    if (result is Err<dynamic>) {
      final failure = result.failure;
      if (failure is NotFoundFailure && failure.code == '404') {
        await _clearNotificationRegistration(storage);
        return;
      }
      AppLogger.warning(
        'Failed to deactivate notification device registration',
        data: failure,
        tag: 'NotificationDeviceRegistration',
      );
    }
  }

  /// EN: Record notification-open event (best-effort, no UX impact on failure).
  /// KO: 알림 오픈 이벤트를 기록합니다 (실패 시 UX 영향 없이 best-effort).
  Future<void> trackNotificationOpen(
    String notificationId, {
    String? deviceId,
  }) async {
    final normalizedNotificationId = notificationId.trim();
    if (normalizedNotificationId.isEmpty) {
      return;
    }

    final storage = await _localStorageFuture;
    final resolvedDeviceId = _firstNonEmpty(
      deviceId,
      await _resolveStoredDeviceId(storage),
    );

    final result = await _apiClient.post<dynamic>(
      ApiEndpoints.notificationOpen(normalizedNotificationId),
      queryParameters: resolvedDeviceId == null
          ? null
          : <String, dynamic>{'deviceId': resolvedDeviceId},
    );

    if (result is Err<dynamic>) {
      // EN: Do not surface open-tracking failures to users.
      // KO: 오픈 추적 실패는 사용자에게 노출하지 않습니다.
      AppLogger.debug(
        'Failed to record notification open',
        data: result.failure,
        tag: 'NotificationDeviceRegistration',
      );
    }
  }

  Future<void> _registerDevice({
    required LocalStorage storage,
    required String deviceId,
    required String provider,
    required String pushToken,
  }) async {
    final payload = buildNotificationDeviceRegistrationPayload(
      platform: _platformValue(),
      provider: provider,
      deviceId: deviceId,
      pushToken: pushToken,
      locale: _resolveDeviceLocale(storage),
      timezone: await _resolveDeviceTimezone(),
      deviceHash: await _resolveDeviceHash(),
    );

    final registerResult = await _apiClient.post<dynamic>(
      ApiEndpoints.notificationDevices,
      data: payload,
    );
    if (registerResult is Success<dynamic>) {
      final responseData = registerResult.data;
      var persistedDeviceId = deviceId;
      if (responseData is Map<String, dynamic>) {
        final candidate = _firstNonEmpty(
          responseData['deviceId']?.toString(),
          responseData['id']?.toString(),
        );
        if (candidate != null && candidate.isNotEmpty) {
          persistedDeviceId = candidate;
        }
      }
      await _storeNotificationRegistration(
        storage: storage,
        deviceId: persistedDeviceId,
        pushToken: pushToken,
      );
      return;
    }

    if (registerResult is Err<dynamic>) {
      AppLogger.warning(
        'Failed to register notification device',
        data: registerResult.failure,
        tag: 'NotificationDeviceRegistration',
      );
    }
  }

  Future<String?> _resolveStoredDeviceId(
    LocalStorage storage, {
    bool migrateLegacyKeys = true,
  }) async {
    final secureDeviceId = (await _secureStorage.getNotificationDeviceId())
        ?.trim();
    if (secureDeviceId != null && secureDeviceId.isNotEmpty) {
      if (migrateLegacyKeys) {
        await _clearLegacyRegistrationKeys(storage);
      }
      return secureDeviceId;
    }

    final primary = storage.getString(LocalStorageKeys.notificationDeviceId);
    if (primary != null && primary.trim().isNotEmpty) {
      final normalized = primary.trim();
      if (migrateLegacyKeys) {
        await _storeNotificationRegistration(
          storage: storage,
          deviceId: normalized,
          pushToken: storage.getString(LocalStorageKeys.notificationPushToken),
        );
      }
      return normalized;
    }

    final legacy = storage.getString(
      LocalStorageKeys.notificationDeviceIdLegacy,
    );
    if (legacy != null && legacy.trim().isNotEmpty) {
      final normalized = legacy.trim();
      if (migrateLegacyKeys) {
        await _storeNotificationRegistration(
          storage: storage,
          deviceId: normalized,
          pushToken: storage.getString(LocalStorageKeys.notificationPushToken),
        );
      }
      return normalized;
    }
    return null;
  }

  Future<String> _createAndStoreDeviceId(LocalStorage storage) async {
    final generated = '${_platformValue().toLowerCase()}-${const Uuid().v4()}';
    await _storeNotificationRegistration(storage: storage, deviceId: generated);
    return generated;
  }

  Future<void> _storeNotificationRegistration({
    required LocalStorage storage,
    required String deviceId,
    String? pushToken,
  }) async {
    final trimmedDeviceId = deviceId.trim();
    final trimmedPushToken = pushToken?.trim();
    await Future.wait([
      _secureStorage.saveNotificationDeviceId(trimmedDeviceId),
      if (trimmedPushToken != null && trimmedPushToken.isNotEmpty)
        _secureStorage.saveNotificationPushToken(trimmedPushToken),
      _clearLegacyRegistrationKeys(storage),
    ]);
  }

  Future<void> _clearLegacyRegistrationKeys(LocalStorage storage) async {
    await Future.wait([
      storage.remove(LocalStorageKeys.notificationDeviceId),
      storage.remove(LocalStorageKeys.notificationDeviceIdLegacy),
      storage.remove(LocalStorageKeys.notificationPushToken),
    ]);
  }

  Future<void> _clearNotificationRegistration(LocalStorage storage) async {
    await Future.wait([
      _secureStorage.clearNotificationRegistration(),
      _clearLegacyRegistrationKeys(storage),
    ]);
  }

  String _platformValue() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      _ => 'UNKNOWN',
    };
  }

  String? _resolveDeviceLocale(LocalStorage storage) {
    final storedLocale = storage.getLocale()?.trim();
    if (storedLocale != null &&
        storedLocale.isNotEmpty &&
        storedLocale.toLowerCase() != 'system') {
      return storedLocale;
    }
    final currentLocale = Intl.getCurrentLocale().trim();
    return currentLocale.isEmpty ? null : currentLocale;
  }

  Future<String?> _resolveDeviceHash() async {
    if (_cachedDeviceHash != null) {
      return _cachedDeviceHash;
    }

    final hashResolver = _deviceHashResolver;
    if (hashResolver != null) {
      final customHash = normalizeNotificationDeviceHash(await hashResolver());
      if (customHash != null) {
        _cachedDeviceHash = customHash;
      }
      return customHash;
    }

    final rawDeviceIdentifier = await _resolveRawDeviceIdentifier();
    if (rawDeviceIdentifier == null || rawDeviceIdentifier.isEmpty) {
      return null;
    }

    final computedHash = computeNotificationDeviceHash(rawDeviceIdentifier);
    _cachedDeviceHash = computedHash;
    return computedHash;
  }

  Future<String?> _resolveRawDeviceIdentifier() async {
    if (kIsWeb) {
      return null;
    }

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _firstNonEmpty(await AndroidId().getId());
        case TargetPlatform.iOS:
          final iosInfo = await DeviceInfoPlugin().iosInfo;
          return _firstNonEmpty(iosInfo.identifierForVendor);
        default:
          return null;
      }
    } catch (error) {
      AppLogger.debug(
        'Failed to resolve raw device identifier for push registration',
        data: error,
        tag: 'NotificationDeviceRegistration',
      );
      return null;
    }
  }

  Future<String?> _resolveDeviceTimezone() async {
    if (_cachedTimezone != null) {
      return _cachedTimezone;
    }

    final timezoneResolver = _timezoneResolver;
    if (timezoneResolver != null) {
      final customTimezone = normalizeNotificationTimezone(
        await timezoneResolver(),
      );
      if (customTimezone != null) {
        _cachedTimezone = customTimezone;
      }
      return customTimezone;
    }

    try {
      final localTimezone = normalizeNotificationTimezone(
        await FlutterTimezone.getLocalTimezone(),
      );
      if (localTimezone != null) {
        _cachedTimezone = localTimezone;
        return localTimezone;
      }
    } catch (error) {
      AppLogger.debug(
        'Failed to resolve IANA timezone for push registration',
        data: error,
        tag: 'NotificationDeviceRegistration',
      );
    }

    final fallbackTimezone = normalizeNotificationTimezone(
      DateTime.now().timeZoneName,
    );
    if (fallbackTimezone != null) {
      _cachedTimezone = fallbackTimezone;
      return fallbackTimezone;
    }
    return null;
  }
}

String? _firstNonEmpty(String? first, [String? second]) {
  if (first != null && first.trim().isNotEmpty) {
    return first.trim();
  }
  if (second != null && second.trim().isNotEmpty) {
    return second.trim();
  }
  return null;
}
