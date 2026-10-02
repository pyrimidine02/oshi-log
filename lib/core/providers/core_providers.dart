/// EN: Core Riverpod providers for dependency injection
/// KO: 의존성 주입을 위한 핵심 Riverpod 프로바이더
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logging/app_logger.dart';
import '../connectivity/connectivity_service.dart';
import '../cache/cache_manager.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../analytics/analytics_service.dart';
import '../location/location_service.dart';
import '../../platform/notifications/local_notifications_service.dart';
import '../../platform/notifications/remote_push_service.dart';
import '../realtime/sse_client.dart';
import '../security/secure_storage.dart';
import '../storage/local_storage.dart';
import '../telemetry/telemetry_service.dart';

// ========================================
// EN: Storage Providers
// KO: 저장소 프로바이더
// ========================================

/// EN: Secure storage provider for sensitive data
/// KO: 민감한 데이터를 위한 보안 저장소 프로바이더
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(namespace: AppConfig.instance.storageNamespace);
});

/// EN: Local storage provider (async initialization required)
/// KO: 로컬 저장소 프로바이더 (비동기 초기화 필요)
final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  return LocalStorage.create(namespace: AppConfig.instance.storageNamespace);
});

/// EN: Cache manager provider (async initialization required).
/// KO: 캐시 매니저 프로바이더 (비동기 초기화 필요).
final cacheManagerProvider = FutureProvider<CacheManager>((ref) async {
  final localStorage = await ref.read(localStorageProvider.future);
  final connectivityService = ref.watch(connectivityServiceProvider);
  return CacheManager(
    localStorage,
    isOnline: () => connectivityService.isOnline,
  );
});

// ========================================
// EN: Network Providers
// KO: 네트워크 프로바이더
// ========================================

/// EN: Called when the API client receives an unauthorized (401) response
///     that could not be refreshed. Default is a no-op; app bootstrap wires
///     this to the auth feature so that core/platform never imports auth.
/// KO: API 클라이언트가 갱신할 수 없는 unauthorized(401) 응답을 받았을 때
///     호출됩니다. 기본값은 아무 작업도 하지 않으며, core/platform이 auth를
///     import하지 않도록 app bootstrap에서 auth feature에 연결합니다.
typedef ApiUnauthorizedCallback = void Function();

/// EN: Called when the API client successfully refreshes the access token.
/// KO: API 클라이언트가 액세스 토큰 갱신에 성공했을 때 호출됩니다.
typedef ApiTokenRefreshedCallback = void Function();

/// EN: Default no-op; overridden in `lib/app/bootstrap/session_overrides.dart`.
/// KO: 기본값은 아무 작업도 하지 않으며
///     `lib/app/bootstrap/session_overrides.dart`에서 override 됩니다.
final apiUnauthorizedCallbackProvider = Provider<ApiUnauthorizedCallback>((
  ref,
) {
  return () {};
});

/// EN: Default no-op; overridden in `lib/app/bootstrap/session_overrides.dart`.
/// KO: 기본값은 아무 작업도 하지 않으며
///     `lib/app/bootstrap/session_overrides.dart`에서 override 됩니다.
final apiTokenRefreshedCallbackProvider = Provider<ApiTokenRefreshedCallback>((
  ref,
) {
  return () {};
});

/// EN: API client provider
/// KO: API 클라이언트 프로바이더
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(
    secureStorage: secureStorage,
    onUnauthorized: () => ref.read(apiUnauthorizedCallbackProvider)(),
    onTokenRefreshed: () => ref.read(apiTokenRefreshedCallbackProvider)(),
  );
});

/// EN: SSE client provider for realtime stream connections.
/// KO: 실시간 스트림 연결을 위한 SSE 클라이언트 프로바이더입니다.
final sseClientProvider = Provider<SseClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SseClient(
    secureStorage: secureStorage,
    ensureFreshToken: () {
      final apiClient = ref.read(apiClientProvider);
      return apiClient.proactiveRefreshIfExpired();
    },
  );
});

/// EN: Local notifications service provider.
/// KO: 로컬 알림 서비스 프로바이더입니다.
final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  final service = LocalNotificationsService();
  ref.onDispose(service.dispose);
  return service;
});

/// EN: One-time app-scope bootstrap for local notifications initialization.
/// KO: 로컬 알림 초기화를 위한 앱 전역 1회 부트스트랩 프로바이더입니다.
final localNotificationsBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(localNotificationsServiceProvider);
  unawaited(service.initialize());
});

/// EN: Stream provider for local-notification tap events.
/// KO: 로컬 알림 탭 이벤트 스트림 프로바이더입니다.
final localNotificationTapEventsProvider =
    StreamProvider<LocalNotificationTapEvent>((ref) {
      final service = ref.watch(localNotificationsServiceProvider);
      return service.tapEvents;
    });

/// EN: Called to register/refresh this device's push token with the backend.
///     Default is a no-op; app bootstrap wires this to the notifications
///     feature's device registration so that core/platform never imports it.
/// KO: 이 디바이스의 푸시 토큰을 백엔드에 등록/갱신할 때 호출됩니다.
///     기본값은 아무 작업도 하지 않으며, core/platform이 import하지 않도록
///     app bootstrap에서 notifications feature의 디바이스 등록에 연결합니다.
typedef NotificationUpsertDeviceRegistration =
    Future<void> Function(
      String pushToken, {
      required String provider,
      required bool forceRegister,
    });

/// EN: Called to deactivate this device's backend push registration.
/// KO: 이 디바이스의 백엔드 푸시 등록을 비활성화할 때 호출됩니다.
typedef NotificationDeactivateCurrentDevice = Future<void> Function();

/// EN: Called to record a notification-open event.
/// KO: 알림 오픈 이벤트를 기록할 때 호출됩니다.
typedef NotificationTrackNotificationOpen =
    Future<void> Function(String notificationId, {String? deviceId});

/// EN: Default no-op; overridden in `lib/app/bootstrap/session_overrides.dart`.
/// KO: 기본값은 아무 작업도 하지 않으며
///     `lib/app/bootstrap/session_overrides.dart`에서 override 됩니다.
final notificationUpsertDeviceRegistrationProvider =
    Provider<NotificationUpsertDeviceRegistration>((ref) {
      return (pushToken, {required provider, required forceRegister}) async {};
    });

/// EN: Default no-op; overridden in `lib/app/bootstrap/session_overrides.dart`.
/// KO: 기본값은 아무 작업도 하지 않으며
///     `lib/app/bootstrap/session_overrides.dart`에서 override 됩니다.
final notificationDeactivateCurrentDeviceProvider =
    Provider<NotificationDeactivateCurrentDevice>((ref) {
      return () async {};
    });

/// EN: Default no-op; overridden in `lib/app/bootstrap/session_overrides.dart`.
/// KO: 기본값은 아무 작업도 하지 않으며
///     `lib/app/bootstrap/session_overrides.dart`에서 override 됩니다.
final notificationTrackNotificationOpenProvider =
    Provider<NotificationTrackNotificationOpen>((ref) {
      return (notificationId, {deviceId}) async {};
    });

/// EN: Remote push service provider. Device-registration persistence is
///     injected via the callback providers above, overridden by app
///     bootstrap with the notifications feature's implementation.
/// KO: 원격 푸시 서비스 프로바이더입니다. 디바이스 등록 영속화는 위 콜백
///     프로바이더를 통해 주입되며, app bootstrap이 notifications feature
///     구현으로 override합니다.
final remotePushServiceProvider = Provider<RemotePushService>((ref) {
  final localStorageFuture = ref.watch(localStorageProvider.future);
  final service = RemotePushService(
    localStorageFuture: localStorageFuture,
    upsertDeviceRegistration:
        (pushToken, {required provider, required forceRegister}) {
          return ref.read(notificationUpsertDeviceRegistrationProvider)(
            pushToken,
            provider: provider,
            forceRegister: forceRegister,
          );
        },
    deactivateCurrentDevice: () =>
        ref.read(notificationDeactivateCurrentDeviceProvider)(),
    trackNotificationOpen: (notificationId, {deviceId}) {
      return ref.read(notificationTrackNotificationOpenProvider)(
        notificationId,
        deviceId: deviceId,
      );
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// EN: Analytics service provider.
/// KO: 분석 서비스 프로바이더.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

/// EN: Telemetry service provider — bootstraps banned-state from storage on first access.
/// KO: 텔레메트리 서비스 프로바이더 — 첫 접근 시 저장소에서 차단 상태를 불러옵니다.
final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService.instance;
});

/// EN: One-time bootstrap provider that restores the device-banned flag from storage.
/// KO: 저장소에서 기기 차단 플래그를 복원하는 1회 부트스트랩 프로바이더.
final telemetryBootstrapProvider = Provider<void>((ref) {
  unawaited(TelemetryService.instance.initialize());
});

/// EN: Connectivity service provider
/// KO: 연결 서비스 프로바이더
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// EN: Location service provider.
/// KO: 위치 서비스 프로바이더.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// EN: Connectivity status stream provider
/// KO: 연결 상태 스트림 프로바이더
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// EN: Current connectivity status provider
/// KO: 현재 연결 상태 프로바이더
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline;
});

/// EN: App semantic version provider (build number excluded).
/// KO: 앱 시맨틱 버전 프로바이더 (빌드 번호 제외).
const String _fallbackAppVersion = String.fromEnvironment(
  'APP_VERSION_FALLBACK',
  defaultValue: '0.0.4',
);

final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version.trim();
    if (version.isNotEmpty) {
      return version;
    }
  } catch (error, stackTrace) {
    AppLogger.error(
      'Failed to load app version from platform; fallback will be used.',
      error: error,
      stackTrace: stackTrace,
      tag: 'AppVersionProvider',
    );
  }
  return _fallbackAppVersion;
});

// EN: Theme/locale preferences moved to
//     `lib/features/settings/application/app_preferences.dart`.
// KO: 테마/로케일 설정은
//     `lib/features/settings/application/app_preferences.dart`로 이동했습니다.

// EN: Project/unit selection state moved to
//     `lib/features/projects/application/project_context.dart`.
// KO: 프로젝트/유닛 선택 상태는
//     `lib/features/projects/application/project_context.dart`로 이동했습니다.

// EN: Tab state moved to `lib/core/router/navigation_state.dart`.
// KO: 탭 상태는 `lib/core/router/navigation_state.dart`로 이동했습니다.

// EN: Auth state/refresh tick moved to
//     `lib/features/auth/application/session_state.dart`.
// KO: 인증 상태/refresh tick은
//     `lib/features/auth/application/session_state.dart`로 이동했습니다.

// EN: Legal policy provider moved to
//     `lib/features/auth/application/legal_policies_provider.dart`.
// KO: 법률 정책 프로바이더는
//     `lib/features/auth/application/legal_policies_provider.dart`로 이동했습니다.
