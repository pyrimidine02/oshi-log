/// EN: ProviderScope overrides that wire app-owned session composition into
///     feature providers without features importing `lib/app`.
/// KO: feature가 `lib/app`을 import하지 않고도 app이 소유한 세션 조합을
///     연결하는 ProviderScope override 목록입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../session/session_cleanup.dart';

/// EN: Overrides to add to the root `ProviderScope` in `main.dart`/`app.dart`.
/// KO: `main.dart`/`app.dart`의 루트 `ProviderScope`에 추가할 override 목록.
final List<Override> sessionOverrides = [
  sessionCleanupProvider.overrideWithValue(appSessionCleanup),
  apiUnauthorizedCallbackProvider.overrideWith((ref) {
    return () => ref.read(authStateProvider.notifier).setUnauthenticated();
  }),
  apiTokenRefreshedCallbackProvider.overrideWith((ref) {
    return () {
      final notifier = ref.read(authTokenRefreshTickProvider.notifier);
      notifier.state = notifier.state + 1;
    };
  }),
];
