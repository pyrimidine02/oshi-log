/// EN: Shared field-note identity components for authentication journeys.
/// KO: 인증 여정에서 공유하는 필드 노트 아이덴티티 구성 요소입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';

/// EN: A responsive account header using the original GBT blue.
/// KO: 기존 GBT 블루를 사용하는 반응형 계정 헤더입니다.
class FieldAuthHeader extends StatelessWidget {
  const FieldAuthHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.icon = Icons.route_outlined,
    this.centered = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    final content = Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          eyebrow,
          style: GBTTypography.labelSmall.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          title,
          style: GBTTypography.headlineSmall.copyWith(
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          subtitle,
          style: GBTTypography.bodyMedium.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
          textAlign: textAlign,
        ),
      ],
    );

    if (centered) {
      return Semantics(
        header: true,
        child: Column(
          children: [
            _FieldAuthMark(icon: icon, primary: primary),
            const SizedBox(height: GBTSpacing.md),
            content,
          ],
        ),
      );
    }

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldAuthMark(icon: icon, primary: primary),
          const SizedBox(width: GBTSpacing.md),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _FieldAuthMark extends StatelessWidget {
  const _FieldAuthMark({required this.icon, required this.primary});

  final IconData icon;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('field-auth-mark'),
      width: 48,
      height: 48,
      color: primary,
      alignment: Alignment.center,
      child: Icon(icon, size: 26, color: GBTColors.textInverse),
    );
  }
}
