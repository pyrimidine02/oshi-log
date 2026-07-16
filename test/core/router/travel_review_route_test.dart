import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/router/app_router.dart';
import 'package:girlsbandtabi_app/core/security/secure_storage.dart';

void main() {
  test(
    'travel review detail named route carries immutable project context',
    () {
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      addTearDown(router.dispose);

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
