import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/app/router/app_router.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';

void main() {
  test(
    'travel review detail named route carries immutable project context',
    () {
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      final location = router.namedLocation(
        AppRoutes.travelReviewDetail,
        pathParameters: const {
          'projectCode': 'bang-dream',
          'reviewId': 'review-1',
        },
      );

      expect(location, '/community/bang-dream/travel-reviews/review-1');
    },
  );
}
