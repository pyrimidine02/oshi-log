/// EN: Push-notification auth sync — app-owned so that core/platform never
///     watches auth state directly.
/// KO: 푸시 알림 인증 동기화 — core/platform이 인증 상태를 직접 watch하지
///     않도록 app이 소유합니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

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
