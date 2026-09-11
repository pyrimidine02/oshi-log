/// EN: Core Riverpod providers for dependency injection
/// KO: 의존성 주입을 위한 핵심 Riverpod 프로바이더
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logging/app_logger.dart';
import '../connectivity/connectivity_service.dart';
import '../cache/cache_manager.dart';
import '../constants/legal_policy_constants.dart';
import '../config/app_config.dart';
import '../error/failure.dart';
import '../network/api_client.dart';
import '../analytics/analytics_service.dart';
import '../location/location_service.dart';
import '../notifications/local_notifications_service.dart';
import '../notifications/remote_push_service.dart';
import '../telemetry/telemetry_service.dart';
import '../utils/result.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/notifications/domain/entities/notification_entities.dart';
import '../realtime/sse_client.dart';
import '../security/secure_storage.dart';
import '../storage/local_storage.dart';

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

/// EN: API client provider
/// KO: API 클라이언트 프로바이더
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(
    secureStorage: secureStorage,
    onUnauthorized: () {
      ref.read(authStateProvider.notifier).setUnauthenticated();
    },
    onTokenRefreshed: () {
      final notifier = ref.read(authTokenRefreshTickProvider.notifier);
      notifier.state = notifier.state + 1;
    },
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

/// EN: Remote push service provider.
/// KO: 원격 푸시 서비스 프로바이더입니다.
final remotePushServiceProvider = Provider<RemotePushService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final localStorageFuture = ref.watch(localStorageProvider.future);
  final localNotificationsService = ref.watch(
    localNotificationsServiceProvider,
  );
  final service = RemotePushService(
    apiClient: apiClient,
    secureStorage: secureStorage,
    localStorageFuture: localStorageFuture,
    localNotificationsService: localNotificationsService,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// EN: Stream provider for foreground FCM messages — feeds the in-app banner queue.
/// KO: 인앱 배너 큐에 공급하기 위한 포그라운드 FCM 메시지 스트림 프로바이더입니다.
final remotePushForegroundMessagesProvider = StreamProvider<NotificationItem>((
  ref,
) {
  return ref.watch(remotePushServiceProvider).foregroundMessages;
});

/// EN: Stream provider for remote-push open tap events.
/// KO: 원격 푸시 오픈 탭 이벤트 스트림 프로바이더입니다.
final remotePushTapEventsProvider = StreamProvider<LocalNotificationTapEvent>((
  ref,
) {
  final service = ref.watch(remotePushServiceProvider);
  return service.tapEvents;
});

/// EN: Global bootstrap provider for remote push setup + auth-bound sync.
/// KO: 원격 푸시 초기화 + 인증 상태 동기화를 위한 전역 부트스트랩 프로바이더입니다.
final remotePushBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(remotePushServiceProvider);
  unawaited(service.initialize());

  ref.listen<AuthState>(authStateProvider, (_, next) {
    switch (next) {
      case AuthState.authenticated:
        unawaited(service.setAuthenticated(true));
      case AuthState.unauthenticated:
        unawaited(service.setAuthenticated(false));
      case AuthState.initial:
        break;
    }
  });

  if (ref.read(isAuthenticatedProvider)) {
    unawaited(service.setAuthenticated(true));
  }
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

// ========================================
// EN: App State Providers
// KO: 앱 상태 프로바이더
// ========================================

/// EN: Theme mode provider (light/dark/system)
/// KO: 테마 모드 프로바이더 (라이트/다크/시스템)
final themeModeProvider = StateProvider<String>((ref) {
  return 'system';
});

/// EN: Locale state notifier.
/// KO: 로케일 상태 노티파이어.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    unawaited(_loadPersistedLocale());
  }

  final Ref _ref;

  Future<void> _loadPersistedLocale() async {
    final storage = await _ref.read(localStorageProvider.future);
    final stored = storage.getLocale();
    final locale = _parseStoredLocale(stored);
    state = locale;
    Intl.defaultLocale = _intlLocaleTag(locale);
  }

  /// EN: Set locale and persist user preference.
  /// KO: 로케일을 설정하고 사용자 선호도를 저장합니다.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    Intl.defaultLocale = _intlLocaleTag(locale);
    final storage = await _ref.read(localStorageProvider.future);
    final value = locale == null ? 'system' : locale.languageCode;
    await storage.setLocale(value);
  }

  /// EN: Set locale by language code (`ko`, `en`, `ja`), or `system`.
  /// KO: 언어 코드(`ko`, `en`, `ja`) 또는 `system`으로 로케일을 설정합니다.
  Future<void> setLocaleByCode(String code) async {
    final normalized = code.trim().toLowerCase();
    final locale = _parseStoredLocale(normalized);
    await setLocale(locale);
  }

  Locale? _parseStoredLocale(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      case 'ja':
        return const Locale('ja', 'JP');
      default:
        return null;
    }
  }

  String _intlLocaleTag(Locale? locale) {
    if (locale == null) {
      return Intl.systemLocale;
    }
    final effective = locale;
    final country = effective.countryCode;
    if (country == null || country.isEmpty) {
      return effective.languageCode;
    }
    return '${effective.languageCode}_$country';
  }
}

/// EN: App locale provider (null means follow system locale).
/// KO: 앱 로케일 프로바이더 (null이면 시스템 로케일을 따릅니다).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});

/// EN: Selected project key provider (slug/code)
/// KO: 선택된 프로젝트 키 프로바이더 (slug/code)
final selectedProjectKeyProvider = StateProvider<String?>((ref) {
  return null;
});

/// EN: Selected project ID provider (UUID when available).
/// KO: 선택된 프로젝트 ID 프로바이더 (가능하면 UUID).
final selectedProjectIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// EN: Selected unit IDs provider
/// KO: 선택된 유닛 ID 목록 프로바이더
final selectedUnitIdsProvider = StateProvider<List<String>>((ref) {
  return [];
});

/// EN: Current bottom navigation index.
/// KO: 현재 하단 네비게이션 인덱스.
final currentNavIndexProvider = StateProvider<int>((ref) {
  return 0;
});

// ========================================
// EN: Auth State Providers
// KO: 인증 상태 프로바이더
// ========================================

/// EN: Auth state enumeration
/// KO: 인증 상태 열거형
enum AuthState { initial, authenticated, unauthenticated }

/// EN: Auth state notifier for managing authentication
/// KO: 인증 관리를 위한 인증 상태 노티파이어
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._secureStorage) : super(AuthState.initial);

  final SecureStorage _secureStorage;

  /// EN: Check authentication status on app start.
  /// EN: Presence of both tokens is sufficient — the API interceptor handles
  /// EN: access-token refresh on 401/403 transparently. Gating on the stored
  /// EN: access-token expiry timestamp would incorrectly log the user out
  /// EN: whenever the short-lived access token expires while the refresh token
  /// EN: is still valid (which is the normal idle state between app launches).
  /// KO: 앱 시작 시 인증 상태 확인.
  /// KO: 두 토큰이 모두 존재하면 인증됨으로 처리합니다. API 인터셉터가
  /// KO: 401/403 응답 시 액세스 토큰을 투명하게 갱신합니다.
  /// KO: 저장된 액세스 토큰 만료 시간을 기준으로 판단하면 리프레시 토큰이
  /// KO: 유효한 상태에서도 세션이 조기 종료되는 문제가 발생합니다.
  Future<void> checkAuthStatus() async {
    final hasTokens = await _secureStorage.hasValidTokens();
    state = hasTokens ? AuthState.authenticated : AuthState.unauthenticated;
  }

  /// EN: Set authenticated state
  /// KO: 인증됨 상태 설정
  void setAuthenticated() {
    state = AuthState.authenticated;
  }

  /// EN: Set unauthenticated state
  /// KO: 인증되지 않음 상태 설정
  void setUnauthenticated() {
    state = AuthState.unauthenticated;
  }

  /// EN: Logout - clear tokens and set unauthenticated
  /// KO: 로그아웃 - 토큰 삭제 및 인증되지 않음 설정
  Future<void> logout() async {
    await _secureStorage.clearTokens();
    state = AuthState.unauthenticated;
  }
}

// ========================================
// EN: Legal Policy Providers
// KO: 법률 정책 프로바이더
// ========================================

/// EN: Fetches the latest legal policy list from the public server endpoint.
///     Fails instead of falling back to bundled constants: a consent recorded
///     against a stale local version makes the server demand re-consent right
///     after signup. Display surfaces may still fall back through
///     [resolveLegalPolicy]; consent submission must await this provider.
/// KO: 공개 서버 엔드포인트에서 최신 법률 정책 목록을 가져옵니다.
///     내장 상수로 폴백하지 않고 실패합니다 — 오래된 로컬 버전으로 동의를
///     기록하면 가입 직후 서버가 재동의를 요구하기 때문입니다. 화면 표시는
///     [resolveLegalPolicy]로 폴백할 수 있지만, 동의 제출은 이 프로바이더를
///     반드시 await 해야 합니다.
final legalPoliciesProvider = FutureProvider<List<LegalPolicyInfo>>((
  ref,
) async {
  final apiClient = ref.read(apiClientProvider);
  final result = await AuthRemoteDataSource(apiClient).fetchLegalPolicies();
  if (result is Success<List<Map<String, dynamic>>>) {
    final parsed = result.data
        .map(LegalPolicyInfo.fromJson)
        .whereType<LegalPolicyInfo>()
        .toList(growable: false);
    final hasAll = {
      LegalPolicyType.termsOfService,
      LegalPolicyType.privacyPolicy,
      LegalPolicyType.locationTerms,
    }.every((t) => parsed.any((p) => p.type == t));
    if (hasAll) return parsed;
  }
  throw const ServerFailure(
    'Legal policies unavailable',
    code: 'LEGAL_POLICIES_UNAVAILABLE',
  );
});

/// EN: Auth state notifier provider
/// KO: 인증 상태 노티파이어 프로바이더
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthStateNotifier(secureStorage);
});

/// EN: Check if user is authenticated
/// KO: 사용자 인증 여부 확인
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) == AuthState.authenticated;
});

/// EN: Monotonic tick incremented when access token is refreshed.
/// KO: 액세스 토큰 갱신 성공 시 증가하는 단조 증가 tick 값입니다.
final authTokenRefreshTickProvider = StateProvider<int>((ref) {
  return 0;
});
