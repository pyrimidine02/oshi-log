/// EN: Compact search chrome shared by full-page search experiences.
/// KO: 전체 화면 검색 경험에서 공유하는 컴팩트 검색 크롬입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'gbt_standard_app_bar.dart';

/// EN: Keeps search inside the standard 56dp route bar instead of stacking a
/// second floating or glass header above the results.
/// KO: 검색창을 결과 위의 별도 플로팅·글래스 헤더로 쌓지 않고 표준 56dp
/// 라우트 바 안에 배치합니다.
class GBTSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GBTSearchAppBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.focusNode,
    this.onBack,
    this.backTooltip,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onBack;
  final String? backTooltip;
  final bool autofocus;

  @override
  Size get preferredSize => const Size.fromHeight(GBTSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return gbtStandardAppBar(
      context,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        tooltip:
            backTooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
        icon: const BackButtonIcon(),
      ),
      titleWidget: SizedBox(
        height: GBTSpacing.minTouchTarget,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surface,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.onSurfaceVariant,
              size: GBTSpacing.iconSm,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: GBTSpacing.touchTarget,
              minHeight: GBTSpacing.minTouchTarget,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              borderSide: BorderSide(color: colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ),
      actions: const [SizedBox(width: GBTSpacing.sm)],
    );
  }
}
