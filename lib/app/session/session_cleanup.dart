/// EN: App-owned logout/session cleanup — resets every user-scoped provider
///     across features. auth injects this via `sessionCleanupProvider`
///     (see `lib/features/auth/application/auth_controller.dart`) so that
///     auth never imports app or sibling features directly.
/// KO: app이 소유하는 로그아웃/세션 정리 — feature 전반의 사용자 범위
///     프로바이더를 초기화합니다. auth는 `sessionCleanupProvider`를 통해
///     이를 주입받으므로 app이나 다른 feature를 직접 import하지 않습니다
///     (`lib/features/auth/application/auth_controller.dart` 참고).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/favorites/application/favorites_controller.dart';
import '../../features/feed/application/local_post_bookmarks_controller.dart';
import '../../features/feed/application/reaction_controller.dart';
import '../../features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../core/router/navigation_state.dart';

/// EN: Reset project/tab selection and invalidate user-scoped feature
///     providers on logout/session reset.
/// KO: 로그아웃/세션 초기화 시 프로젝트/탭 선택을 초기화하고 사용자 범위
///     feature 프로바이더를 무효화합니다.
void appSessionCleanup(Ref ref) {
  // EN: Reset project/unit selection state.
  // KO: 프로젝트/유닛 선택 상태 초기화.
  ref.read(selectedProjectKeyProvider.notifier).state = null;
  ref.read(selectedProjectIdProvider.notifier).state = null;
  ref.read(selectedUnitIdsProvider.notifier).state = [];
  ref.read(currentNavIndexProvider.notifier).state = 0;

  // EN: Invalidate user profile providers.
  // KO: 사용자 프로필 프로바이더 초기화.
  ref.invalidate(userProfileControllerProvider);
  ref.invalidate(notificationSettingsControllerProvider);

  // EN: Dispose user mutation queues and local bookmarks so callbacks
  //     from the previous session cannot observe the next one.
  // KO: 이전 세션의 콜백이 다음 세션을 관찰하지 못하도록 사용자 변경
  //     대기열과 로컬 북마크 프로바이더를 해제합니다.
  ref.invalidate(favoritesControllerProvider);
  ref.invalidate(postReactionOutboxControllerProvider);
  ref.invalidate(liveAttendanceOutboxControllerProvider);
  ref.invalidate(localPostBookmarksControllerProvider);
}
