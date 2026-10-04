import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/place/verification/application/verification_controller.dart';
import 'package:oshi_log/features/place/verification/domain/entities/verification_entities.dart';
import 'package:oshi_log/platform/utils/result.dart';

void main() {
  group('VerificationController', () {
    test('returns auth failure when user is unauthenticated', () async {
      final container = ProviderContainer(
        overrides: [isAuthenticatedProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(verificationControllerProvider.notifier);
      final result = await notifier.verifyPlace('place-1');

      expect(result, isA<Err<VerificationResult>>());
      expect(
        container.read(verificationControllerProvider).error,
        isA<AuthFailure>(),
      );
    });
  });
}
