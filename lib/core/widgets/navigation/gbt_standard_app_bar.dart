/// EN: Shared compact app bar for routed feature screens.
/// KO: 라우팅된 기능 화면을 위한 공통 컴팩트 앱바입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// EN: Builds the single solid top-bar treatment used throughout the app.
/// Content and chrome share the field-paper background, while a subtle rule
/// provides separation without adding height, blur, or elevation.
/// KO: 앱 전반에서 사용하는 하나의 솔리드 상단바를 구성합니다. 본문과 크롬은
/// 필드 페이퍼 배경을 공유하고, 높이·블러·고도를 추가하지 않는 얇은 구분선으로
/// 영역만 나눕니다.
PreferredSizeWidget gbtStandardAppBar(
  BuildContext context, {
  String? title,
  Widget? titleWidget,
  Widget? leading,
  bool automaticallyImplyLeading = true,
  bool? centerTitle,
  double? titleSpacing,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  assert(
    title != null || titleWidget != null,
    'Either title or titleWidget must be provided.',
  );

  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final resolvedTitle =
      titleWidget ??
      Text(
        title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      );

  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    backgroundColor: theme.scaffoldBackgroundColor,
    foregroundColor: colors.onSurface,
    toolbarHeight: GBTSpacing.appBarHeight,
    shape: Border(bottom: BorderSide(color: colors.outlineVariant, width: 0.8)),
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    centerTitle: centerTitle,
    titleSpacing: titleSpacing,
    title: resolvedTitle,
    actions: actions,
    bottom: bottom,
  );
}
