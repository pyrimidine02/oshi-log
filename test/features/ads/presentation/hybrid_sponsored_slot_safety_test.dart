import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/ads/presentation/widgets/hybrid_sponsored_slot.dart';

void main() {
  group('safeHouseTargetPath', () {
    test('accepts an app-relative route with query parameters', () {
      expect(
        safeHouseTargetPath('  /places/abc?from=house  '),
        '/places/abc?from=house',
      );
    });

    test('rejects schemes, authorities, relative paths, and backslashes', () {
      for (final value in <String?>[
        'https://attacker.example',
        '//attacker.example/path',
        'mailto:person@example.com',
        'places/abc',
        r'/places\attacker',
        null,
      ]) {
        expect(safeHouseTargetPath(value), isNull, reason: value);
      }
    });
  });

  group('safeHouseTargetUri', () {
    test('accepts HTTPS and rejects other schemes or credentials', () {
      expect(
        safeHouseTargetUri('https://campaign.example/offer')?.host,
        'campaign.example',
      );
      for (final value in <String?>[
        'http://campaign.example/offer',
        'javascript:alert(1)',
        'https://user:password@campaign.example/offer',
        null,
      ]) {
        expect(safeHouseTargetUri(value), isNull, reason: value);
      }
    });
  });
}
