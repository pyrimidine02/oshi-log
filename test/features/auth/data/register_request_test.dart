import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/auth/data/dto/register_request.dart';
import 'package:oshi_log/features/auth/domain/entities/register_consent.dart';

void main() {
  test('RegisterRequest serializes legacy payload when consents are empty', () {
    const request = RegisterRequest(
      username: 'user@example.com',
      password: 'Password1!',
      nickname: 'tester',
    );

    final json = request.toJson();

    expect(json['username'], 'user@example.com');
    expect(json['password'], 'Password1!');
    expect(json['nickname'], 'tester');
    expect(json.containsKey('consents'), isFalse);
  });

  test('RegisterRequest serializes consent payload when provided', () {
    final request = RegisterRequest(
      username: 'user@example.com',
      password: 'Password1!',
      nickname: 'tester',
      consents: [
        RegisterConsent(
          type: 'TERMS_OF_SERVICE',
          version: 'v2026.03.06',
          agreed: true,
          agreedAt: DateTime.parse('2026-03-06T12:30:00+09:00'),
        ),
      ],
    );

    final json = request.toJson();
    final consents = json['consents'] as List<dynamic>;
    final first = consents.first as Map<String, dynamic>;

    expect(consents.length, 1);
    expect(first['type'], 'TERMS_OF_SERVICE');
    expect(first['version'], 'v2026.03.06');
    expect(first['agreed'], isTrue);
    expect(first['agreedAt'], '2026-03-06T03:30:00.000Z');
  });
}
