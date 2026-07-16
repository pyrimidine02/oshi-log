import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/router/app_router.dart';
import 'package:girlsbandtabi_app/core/security/secure_storage.dart';

void main() {
  test('fan subject named route keeps generic subject identity', () {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    final location = router.namedLocation(
      AppRoutes.fanSubjectDetail,
      pathParameters: const {'subjectId': 'subject-artist'},
    );

    expect(location, '/fan-subjects/subject-artist');
  });
}
