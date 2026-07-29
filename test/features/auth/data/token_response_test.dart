import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/auth/data/dto/token_response.dart';

void main() {
  test('TokenResponse parses expiry fields', () {
    final json = {
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'expiresIn': 3600,
      'tokenType': 'Bearer',
    };

    final response = TokenResponse.fromJson(json);
    expect(response.accessToken, 'access');
    expect(response.refreshToken, 'refresh');
    expect(response.expiresIn, 3600);
    expect(response.tokenType, 'Bearer');

    final now = DateTime(2026, 1, 28, 12, 0);
    final resolved = response.resolvedExpiry(now);
    expect(resolved, now.add(const Duration(seconds: 3600)));
  });

  test('TokenResponse uses expiresAt when provided', () {
    final json = {
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'expiresAt': '2026-01-28T12:30:00Z',
    };

    final response = TokenResponse.fromJson(json);
    expect(response.expiresAt, DateTime.parse('2026-01-28T12:30:00Z'));
  });
}
