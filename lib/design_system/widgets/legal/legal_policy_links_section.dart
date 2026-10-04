/// EN: Reusable legal policy links section with version metadata.
/// KO: 버전 메타데이터를 포함한 재사용 가능한 정책 링크 섹션입니다.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../platform/constants/legal_policy_constants.dart';
import '../../localization/locale_text.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Pure presentation widget — the caller resolves [policies] (e.g. from
///     `legalPoliciesProvider` in the auth feature) and passes a display
///     value in. This keeps core/widgets free of feature provider imports.
/// KO: 순수 표시 위젯입니다 — 호출자가 [policies]를 해석해(예: auth feature의
///     `legalPoliciesProvider`) 표시값으로 전달합니다. core/widgets가 feature
///     프로바이더를 import하지 않도록 유지합니다.
class LegalPolicyLinksSection extends StatelessWidget {
  const LegalPolicyLinksSection({
    super.key,
    this.title,
    this.showContainer = true,
    List<LegalPolicyInfo>? policies,
  }) : _policies = policies;

  final String? title;
  final bool showContainer;
  final List<LegalPolicyInfo>? _policies;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final header =
        title ??
        context.l10n(ko: '약관 및 정책', en: 'Terms and policies', ja: '規約とポリシー');

    // EN: Fall back to bundled constants when the caller has none yet
    //     (loading/error in the caller's fetch).
    // KO: 호출자가 아직 값을 전달하지 못한 경우(로딩/오류) 내장 상수로 폴백합니다.
    final policies = _policies ?? LegalPolicyConstants.policies;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: GBTTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        ...policies.map(
          (policy) => Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
            child: _PolicyRow(policy: policy),
          ),
        ),
      ],
    );

    if (!showContainer) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(
          color: isDark ? GBTColors.darkBorderSubtle : GBTColors.border,
          width: 0.5,
        ),
      ),
      child: content,
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.policy});

  final LegalPolicyInfo policy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final tertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      onTap: () => _openPolicy(context, policy.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.xs,
          vertical: GBTSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                policy.type.label(context),
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                ),
              ),
            ),
            Text(
              policy.version,
              style: GBTTypography.labelSmall.copyWith(color: tertiary),
            ),
            const SizedBox(width: GBTSpacing.xs),
            Icon(Icons.open_in_new_rounded, size: 16, color: primary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPolicy(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '정책 문서를 열 수 없습니다.',
            en: 'Unable to open policy document.',
            ja: 'ポリシー文書を開けません。',
          ),
        ),
      ),
    );
  }
}
