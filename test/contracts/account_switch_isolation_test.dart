// EN: PR 0 contract — freezes today's account-switch isolation behavior.
//     LocalStorage is namespaced per API origin, NOT per account, so
//     account A and account B on the same backend share the same on-disk
//     keys. Isolation today relies entirely on auth_controller calling
//     clearUserScopedLocalStorage()/clearUserScopedMutations() (the exact
//     functions the real logout path uses) before a new session starts.
//     This test drives those real functions directly, it does not
//     reimplement the clearing logic.
// KO: PR 0 계약 — 현재의 계정 전환 격리 동작을 고정합니다. LocalStorage는
//     계정이 아닌 API 오리진 단위로 네임스페이스가 나뉘므로, 같은 백엔드의
//     계정 A와 B는 동일한 디스크 키를 공유합니다. 오늘날의 격리는 새 세션
//     시작 전 auth_controller가 clearUserScopedLocalStorage()/
//     clearUserScopedMutations()(실제 로그아웃 경로가 쓰는 바로 그 함수)를
//     호출하는 것에 전적으로 의존합니다. 이 테스트는 로직을 재구현하지 않고
//     그 실제 함수를 직접 구동합니다.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/storage/local_storage.dart';
import 'package:oshi_log/features/auth/application/auth_controller.dart'
    show clearUserScopedLocalStorage, clearUserScopedMutations;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocalStorage> buildStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs, namespace: 'api_prod');
  }

  Future<void> seedAccountAData(LocalStorage storage) async {
    await storage.setPendingFavoriteMutations([
      {'marker': 'account-a-favorite'},
    ]);
    await storage.setPendingPostReactionMutations([
      {'marker': 'account-a-reaction'},
    ]);
    await storage.setPendingLiveAttendanceMutations([
      {'marker': 'account-a-attendance'},
    ]);
    await storage.setLocalPostBookmarks([
      {'marker': 'account-a-bookmark'},
    ]);
    await storage.setString(LocalStorageKeys.selectedProjectId, 'account-a-project');
  }

  test(
    'logout cleanup (clearUserScopedLocalStorage) removes account A queues/selection '
    'before account B can start a session on the same origin',
    () async {
      final storage = await buildStorage();
      await seedAccountAData(storage);

      // EN: This is the exact call auth_controller._clearUserLocalStorage makes.
      // KO: auth_controller._clearUserLocalStorage가 호출하는 것과 동일한 함수입니다.
      final cleared = await clearUserScopedLocalStorage(storage);

      expect(cleared, isTrue);
      expect(storage.getPendingFavoriteMutations(), isEmpty);
      expect(storage.getPendingPostReactionMutations(), isEmpty);
      expect(storage.getPendingLiveAttendanceMutations(), isEmpty);
      expect(storage.getLocalPostBookmarks(), isEmpty);
      expect(storage.getString(LocalStorageKeys.selectedProjectId), isNull);

      // EN: Account B now starts on a clean slate — no leaked A data.
      // KO: 계정 B는 이제 A 데이터가 누출되지 않은 상태에서 시작합니다.
      expect(storage.getPendingFavoriteMutations(), isNot(contains({'marker': 'account-a-favorite'})));
    },
  );

  test(
    'pre-login cleanup (clearUserScopedMutations) also clears queues '
    'left over from an account that never ran a clean logout',
    () async {
      final storage = await buildStorage();
      await seedAccountAData(storage);

      final cleared = await clearUserScopedMutations(storage);

      expect(cleared, isTrue);
      expect(storage.getPendingFavoriteMutations(), isEmpty);
      expect(storage.getPendingPostReactionMutations(), isEmpty);
      expect(storage.getPendingLiveAttendanceMutations(), isEmpty);
      expect(storage.getLocalPostBookmarks(), isEmpty);

      // EN: KNOWN LEAK — clearUserScopedMutations does not touch
      // selectedProjectId; only the full clearUserScopedLocalStorage
      // (logout path) does. If a caller relies on clearUserScopedMutations
      // alone (e.g. pre-login guard) account A's project selection can
      // survive into account B's session. Not fixed here per PR 0 scope.
      expect(
        storage.getString(LocalStorageKeys.selectedProjectId),
        'account-a-project',
        reason: 'KNOWN LEAK: clearUserScopedMutations leaves selectedProjectId behind; '
            'only clearUserScopedLocalStorage (full logout) clears it.',
      );
    },
  );
}
