/// EN: ProviderScope overrides that wire app-owned session composition into
///     feature providers without features importing `lib/app`.
/// KO: feature가 `lib/app`을 import하지 않고도 app이 소유한 세션 조합을
///     연결하는 ProviderScope override 목록입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/notifications/application/notification_delivery.dart';
import '../../features/verification/application/verification_controller.dart';
import '../compositions/places/verification_completion.dart';
import '../session/session_cleanup.dart';

/// EN: Overrides to add to the root `ProviderScope` in `main.dart`/`app.dart`.
/// KO: `main.dart`/`app.dart`의 루트 `ProviderScope`에 추가할 override 목록.
final List<Override> sessionOverrides = [
  sessionCleanupProvider.overrideWithValue(appSessionCleanup),
  apiUnauthorizedCallbackProvider.overrideWith((ref) {
    return () => ref.read(authStateProvider.notifier).setUnauthenticated();
  }),
  // EN: Let the API client capture the active auth session generation at
  //     request/refresh start and verify it is still current before
  //     clearing tokens / flipping auth state, so a stale refresh failure
  //     arriving after re-login cannot log out the new session.
  // KO: API 클라이언트가 요청/갱신 시작 시 활성 인증 세션 세대를 캡처하고,
  //     토큰 삭제/인증 상태 전환 전에 여전히 현재 세대인지 확인하도록
  //     연결합니다. 재로그인 이후 도착한 오래된 갱신 실패가 새 세션을
  //     로그아웃시키지 못하도록 합니다.
  apiSessionGenerationProvider.overrideWith((ref) {
    return () =>
        ref.read(authControllerProvider.notifier).currentSessionGeneration;
  }),
  apiSessionGenerationGuardProvider.overrideWith((ref) {
    return (generation) => ref
        .read(authControllerProvider.notifier)
        .isCurrentSessionGeneration(generation);
  }),
  apiTokenRefreshedCallbackProvider.overrideWith((ref) {
    return () {
      final notifier = ref.read(authTokenRefreshTickProvider.notifier);
      notifier.state = notifier.state + 1;
    };
  }),
  // EN: Wire the notification device-registration seams to the
  //     notifications feature's data implementation.
  // KO: 알림 디바이스 등록 seam을 notifications feature의 data 구현에
  //     연결합니다.
  notificationUpsertDeviceRegistrationProvider.overrideWith((ref) {
    return ref
        .watch(notificationDeviceRegistrationProvider)
        .upsertDeviceRegistration;
  }),
  notificationDeactivateCurrentDeviceProvider.overrideWith((ref) {
    return ref
        .watch(notificationDeviceRegistrationProvider)
        .deactivateCurrentDevice;
  }),
  notificationTrackNotificationOpenProvider.overrideWith((ref) {
    return ref
        .watch(notificationDeviceRegistrationProvider)
        .trackNotificationOpen;
  }),
  // EN: Wire the post-verification visit/ranking/title refresh into the
  //     verification feature's success hook.
  // KO: 인증 후 방문/랭킹/칭호 새로고침을 verification feature의 성공 훅에
  //     연결합니다.
  verificationCompletionHookProvider.overrideWithValue(
    refreshVisitDataAfterVerification,
  ),
];
