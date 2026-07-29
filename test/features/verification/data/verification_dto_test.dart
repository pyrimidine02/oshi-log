import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/verification/data/dto/verification_dto.dart';

void main() {
  test('VerificationChallengeDto parses nonce', () {
    final json = {
      'nonce': 'token-123',
      'expiresAt': '2026-01-28T00:00:00Z',
    };

    final dto = VerificationChallengeDto.fromJson(json);
    expect(dto.nonce, 'token-123');
    expect(dto.expiresAt, isNotNull);
  });

  test('VerificationResultDto parses visit success', () {
    final json = {'placeId': 'place-1', 'result': 'SUCCESS'};

    final dto = VerificationResultDto.fromJson(json);
    expect(dto.placeId, 'place-1');
    expect(dto.result, 'SUCCESS');
  });
}
