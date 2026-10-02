/// EN: Auth session state (authenticated/unauthenticated) and refresh tick.
/// KO: 인증 세션 상태(인증됨/인증되지 않음)와 리프레시 tick.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/providers/core_providers.dart'
    show secureStorageProvider;

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
