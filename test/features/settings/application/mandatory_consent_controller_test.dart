import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/settings/application/mandatory_consent_controller.dart';

void main() {
  group('parseMandatoryConsentStatusPayload', () {
    test('parses canUseService and required consent list', () {
      final payload = parseMandatoryConsentStatusPayload({
        'canUseService': false,
        'requiredConsents': [
          {
            'type': 'TERMS_OF_SERVICE',
            'requiredVersion': 'v2026.03.10',
            'policyUrl': 'https://example.com/policies/terms/v2026.03.10',
            'agreed': false,
            'agreedVersion': null,
            'agreedAt': null,
            'needsReconsent': true,
          },
          {
            'type': 'PRIVACY_POLICY',
            'requiredVersion': 'v2026.03.10',
            'policyUrl': 'https://example.com/policies/privacy/v2026.03.10',
            'agreed': true,
            'agreedVersion': 'v2026.03.01',
            'agreedAt': '2026-03-01T03:10:00Z',
            'needsReconsent': true,
          },
          {
            'type': 'LOCATION_TERMS',
            'requiredVersion': 'v2026.03.10',
            'policyUrl': 'https://example.com/policies/location/v2026.03.10',
            'agreed': false,
            'agreedVersion': null,
            'agreedAt': null,
            'needsReconsent': true,
          },
        ],
      });

      expect(payload.canUseService, isFalse);
      expect(payload.requiredConsents, hasLength(3));
      expect(payload.requiredConsents.first.type, 'TERMS_OF_SERVICE');
      expect(payload.requiredConsents.first.requiredVersion, 'v2026.03.10');
    });

    test('falls back to blocking payload on invalid response shape', () {
      final payload = parseMandatoryConsentStatusPayload('invalid');

      expect(payload.canUseService, isFalse);
      expect(payload.requiredConsents, isEmpty);
    });
  });

  group('resolveBlockingRequiredConsents', () {
    test('returns needsReconsent entries', () {
      final blocking = resolveBlockingRequiredConsents(
        consents: const [
          RequiredConsentStatusItem(
            type: 'TERMS_OF_SERVICE',
            requiredVersion: 'v2026.03.10',
            policyUrl: 'https://example.com/terms',
            agreed: true,
            agreedVersion: 'v2026.03.10',
            agreedAt: '2026-03-10T10:30:00Z',
            needsReconsent: false,
          ),
          RequiredConsentStatusItem(
            type: 'PRIVACY_POLICY',
            requiredVersion: 'v2026.03.10',
            policyUrl: 'https://example.com/privacy',
            agreed: true,
            agreedVersion: 'v2026.03.01',
            agreedAt: '2026-03-01T03:10:00Z',
            needsReconsent: true,
          ),
        ],
      );

      expect(blocking, hasLength(1));
      expect(blocking.first.type, 'PRIVACY_POLICY');
    });

    test(
      'treats not-agreed entries as blocking even if needsReconsent=false',
      () {
        final blocking = resolveBlockingRequiredConsents(
          consents: const [
            RequiredConsentStatusItem(
              type: 'TERMS_OF_SERVICE',
              requiredVersion: 'v2026.03.10',
              policyUrl: 'https://example.com/terms',
              agreed: false,
              agreedVersion: null,
              agreedAt: null,
              needsReconsent: false,
            ),
          ],
        );

        expect(blocking, hasLength(1));
        expect(blocking.first.type, 'TERMS_OF_SERVICE');
      },
    );
  });

  group('mandatory consent type set', () {
    test('extracts and validates required 3 consent types only', () {
      const source = [
        RequiredConsentStatusItem(
          type: 'TERMS_OF_SERVICE',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/terms',
          agreed: true,
          agreedVersion: 'v2026.03.12',
          agreedAt: '2026-03-12T10:00:00Z',
          needsReconsent: false,
        ),
        RequiredConsentStatusItem(
          type: 'PRIVACY_POLICY',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/privacy',
          agreed: true,
          agreedVersion: 'v2026.03.12',
          agreedAt: '2026-03-12T10:00:00Z',
          needsReconsent: false,
        ),
        RequiredConsentStatusItem(
          type: 'LOCATION_TERMS',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/location',
          agreed: false,
          agreedVersion: null,
          agreedAt: null,
          needsReconsent: true,
        ),
        RequiredConsentStatusItem(
          type: 'AGE_OVER_14',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/age',
          agreed: true,
          agreedVersion: 'v2026.03.12',
          agreedAt: '2026-03-12T10:00:00Z',
          needsReconsent: false,
        ),
      ];

      final mandatory = extractMandatoryConsentItems(consents: source);
      expect(mandatory, hasLength(3));
      expect(
        mandatory.map((item) => item.type).toSet(),
        equals({'TERMS_OF_SERVICE', 'PRIVACY_POLICY', 'LOCATION_TERMS'}),
      );
      expect(containsAllMandatoryConsentTypes(consents: mandatory), isTrue);
    });

    test('returns false when one of required 3 consent types is missing', () {
      const source = [
        RequiredConsentStatusItem(
          type: 'TERMS_OF_SERVICE',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/terms',
          agreed: true,
          agreedVersion: 'v2026.03.12',
          agreedAt: '2026-03-12T10:00:00Z',
          needsReconsent: false,
        ),
        RequiredConsentStatusItem(
          type: 'PRIVACY_POLICY',
          requiredVersion: 'v2026.03.12',
          policyUrl: 'https://example.com/privacy',
          agreed: true,
          agreedVersion: 'v2026.03.12',
          agreedAt: '2026-03-12T10:00:00Z',
          needsReconsent: false,
        ),
      ];

      expect(containsAllMandatoryConsentTypes(consents: source), isFalse);
    });
  });
}
