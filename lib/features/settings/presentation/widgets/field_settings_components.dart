/// EN: Shared document-style building blocks for settings pages.
/// KO: 설정 페이지에서 공유하는 문서형 구성 요소입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';

/// EN: A borderless settings section separated by editorial hairlines.
/// KO: 문서형 구분선으로 항목을 나누는 테두리 없는 설정 섹션입니다.
class FieldSettingsSection extends StatelessWidget {
  const FieldSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? GBTColors.darkBorderSubtle
        : GBTColors.divider;
    final sectionChildren = <Widget>[];

    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        sectionChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: GBTSpacing.xl + GBTSpacing.lg,
            color: dividerColor,
          ),
        );
      }
      sectionChildren.add(children[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
          child: Text(
            title,
            style: GBTTypography.labelSmall.copyWith(
              color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: GBTSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
            child: Text(
              description!,
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: GBTSpacing.sm),
        Material(
          color: Colors.transparent,
          child: Column(children: sectionChildren),
        ),
      ],
    );
  }
}

/// EN: A minimum-48dp settings row with a quiet blue navigation cue.
/// KO: 절제된 파란 탐색 단서와 최소 48dp 터치 영역을 가진 설정 행입니다.
class FieldSettingsRow extends StatelessWidget {
  const FieldSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = destructive
        ? (isDark ? GBTColors.errorLight : GBTColors.error)
        : (isDark ? GBTColors.darkPrimary : GBTColors.primary);
    final titleColor = destructive
        ? actionColor
        : (isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary);
    final resolvedTrailing =
        trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textTertiary,
              ));

    return Semantics(
      button: onTap != null,
      label: subtitle == null ? title : '$title, $subtitle',
      child: InkWell(
        key: ValueKey('field-settings-row-$title'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: GBTSpacing.xl,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(icon, size: 22, color: actionColor),
                  ),
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GBTTypography.bodySmall.copyWith(
                            color: isDark
                                ? GBTColors.darkTextSecondary
                                : GBTColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (resolvedTrailing != null) ...[
                  const SizedBox(width: GBTSpacing.sm),
                  resolvedTrailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: A quiet field-note introduction for settings subpages.
/// KO: 설정 하위 페이지를 위한 절제된 필드 노트 안내 영역입니다.
class FieldSettingsIntro extends StatelessWidget {
  const FieldSettingsIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return Semantics(
      header: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: primary),
            const SizedBox(width: GBTSpacing.md),
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 24, color: primary),
              ),
              const SizedBox(width: GBTSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: GBTTypography.labelSmall.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    title,
                    style: GBTTypography.titleLarge.copyWith(
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    description,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
