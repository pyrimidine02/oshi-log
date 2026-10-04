import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/app/router/app_router.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';

void main() {
  test('fan subject named route keeps generic subject identity', () {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    final location = router.namedLocation(
      AppRoutes.fanSubjectDetail,
      pathParameters: const {'subjectId': 'subject-artist'},
    );

    expect(location, '/fan-subjects/subject-artist');
  });
}
