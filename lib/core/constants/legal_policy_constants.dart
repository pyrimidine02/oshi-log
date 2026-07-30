/// EN: Legal policy metadata and public document links.
/// KO: 법률 정책 메타데이터와 공개 문서 링크입니다.
library;

import 'package:flutter/material.dart';

import '../localization/locale_text.dart';

enum LegalPolicyType { termsOfService, privacyPolicy, locationTerms }

class LegalPolicyInfo {
  const LegalPolicyInfo({
    required this.type,
    required this.version,
    required this.effectiveDate,
    required this.url,
  });

  final LegalPolicyType type;
  final String version;
  final String effectiveDate;
  final String url;

  /// EN: Parse a single policy item from the server response.
  ///     Returns null when [json] contains an unrecognised type field.
  /// KO: 서버 응답에서 단일 정책 항목을 파싱합니다.
  ///     type 필드가 알 수 없는 값이면 null을 반환합니다.
  static LegalPolicyInfo? fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String? ?? '').trim().toUpperCase();
    final type = switch (typeStr) {
      'TERMS_OF_SERVICE' => LegalPolicyType.termsOfService,
      'PRIVACY_POLICY' => LegalPolicyType.privacyPolicy,
      'LOCATION_TERMS' => LegalPolicyType.locationTerms,
      _ => null,
    };
    if (type == null) return null;
    return LegalPolicyInfo(
      type: type,
      version:
          ((json['version'] as String?) ??
                  (json['requiredVersion'] as String?) ??
                  '-')
              .trim(),
      effectiveDate: ((json['effectiveDate'] as String?) ?? '-').trim(),
      url: ((json['policyUrl'] as String?) ?? (json['url'] as String?) ?? '')
          .trim(),
    );
  }
}

class LegalPolicyConstants {
  LegalPolicyConstants._();

  // EN: Replace URLs with production policy pages when legal team publishes them.
  // KO: 법무팀 정책 문서 공개 후 운영 URL로 교체해야 합니다.
  static const List<LegalPolicyInfo> policies = [
    LegalPolicyInfo(
      type: LegalPolicyType.termsOfService,
      version: 'v2026.03.12',
      effectiveDate: '2026-03-12',
      url: 'https://girlsbandtabi.app/policies/terms',
    ),
    LegalPolicyInfo(
      type: LegalPolicyType.privacyPolicy,
      version: 'v2026.03.12',
      effectiveDate: '2026-03-12',
      url: 'https://girlsbandtabi.app/policies/privacy',
    ),
    LegalPolicyInfo(
      type: LegalPolicyType.locationTerms,
      version: 'v2026.03.12',
      effectiveDate: '2026-03-12',
      url: 'https://girlsbandtabi.app/policies/location',
    ),
  ];

  static LegalPolicyInfo byType(LegalPolicyType type) {
    return policies.firstWhere((policy) => policy.type == type);
  }
}

/// EN: Resolves the server-fetched policy of [type], falling back to the
///     bundled constants when the server list is unavailable.
///     Display only — never record a consent with the fallback version,
///     because a stale version makes the server demand re-consent.
/// KO: 서버에서 받은 [type] 정책을 찾고, 서버 목록이 없으면 내장 상수로
///     폴백합니다. 표시 전용입니다 — 폴백 버전으로 동의를 기록하면
///     서버가 재동의를 요구하므로 동의 기록에는 사용하지 않습니다.
LegalPolicyInfo resolveLegalPolicy(
  List<LegalPolicyInfo>? policies,
  LegalPolicyType type,
) {
  if (policies != null) {
    for (final policy in policies) {
      if (policy.type == type) return policy;
    }
  }
  return LegalPolicyConstants.byType(type);
}

extension LegalPolicyTypeLabel on LegalPolicyType {
  String label(BuildContext context) {
    return switch (this) {
      LegalPolicyType.termsOfService => context.l10n(
        ko: '이용약관',
        en: 'Terms of service',
        ja: '利用規約',
      ),
      LegalPolicyType.privacyPolicy => context.l10n(
        ko: '개인정보 처리방침',
        en: 'Privacy policy',
        ja: 'プライバシーポリシー',
      ),
      LegalPolicyType.locationTerms => context.l10n(
        ko: '위치정보 이용약관',
        en: 'Location terms',
        ja: '位置情報利用規約',
      ),
    };
  }
}
