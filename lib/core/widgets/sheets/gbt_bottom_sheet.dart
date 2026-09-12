/// EN: GBT Bottom Sheet component
/// KO: GBT 바텀 시트 컴포넌트
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: Show a GBT styled modal bottom sheet
/// KO: GBT 스타일의 모달 바텀 시트 표시
Future<T?> showGBTBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  double? maxHeight,
}) {
  final platform = Theme.of(context).platform;
  final useCupertino =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  if (useCupertino) {
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: isDismissible,
      semanticsDismissible: isDismissible,
      builder: (popupContext) {
        final mediaQuery = MediaQuery.of(popupContext);
        final heightLimit = maxHeight ?? mediaQuery.size.height * 0.9;
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GBTBottomSheet(
                title: title,
                maxHeight: heightLimit,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        GBTBottomSheet(title: title, maxHeight: maxHeight, child: child),
  );
}

/// EN: GBT Bottom Sheet widget
/// KO: GBT 바텀 시트 위젯
class GBTBottomSheet extends StatelessWidget {
  const GBTBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.maxHeight,
    this.onClose,
  });

  /// EN: Content of the bottom sheet
  /// KO: 바텀 시트의 콘텐츠
  final Widget child;

  /// EN: Optional title
  /// KO: 선택적 제목
  final String? title;

  /// EN: Maximum height of the sheet
  /// KO: 시트의 최대 높이
  final double? maxHeight;

  /// EN: Callback when close button is tapped
  /// KO: 닫기 버튼이 탭되었을 때 콜백
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // EN: Drag handle with neutral color for light/dark
          // KO: 라이트/다크용 뉴트럴 색상 드래그 핸들
          Semantics(
            label: '드래그하여 시트를 닫을 수 있습니다',
            child: Container(
              margin: const EdgeInsets.only(top: GBTSpacing.sm),
              width: 36,
              height: GBTSpacing.xs,
              decoration: BoxDecoration(
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textDisabled,
                borderRadius: BorderRadius.circular(GBTSpacing.xxs),
              ),
            ),
          ),

          // EN: Header with title and close button
          // KO: 제목과 닫기 버튼이 있는 헤더
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.sm,
                GBTSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: GBTTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? GBTColors.darkTextPrimary
                            : GBTColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // EN: Close button with tooltip for accessibility
                  // KO: 접근성을 위한 툴팁이 있는 닫기 버튼
                  Tooltip(
                    message: '닫기',
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? GBTColors.darkTextSecondary
                            : GBTColors.textSecondary,
                      ),
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      iconSize: GBTSpacing.iconSm,
                      constraints: const BoxConstraints(
                        minWidth: GBTSpacing.touchTarget,
                        minHeight: GBTSpacing.touchTarget,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // EN: Content
          // KO: 콘텐츠
          Flexible(child: child),
        ],
      ),
    );

    // EN: Add bottom padding for keyboard
    // KO: 키보드를 위한 하단 패딩 추가
    if (bottomPadding > 0) {
      content = Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: content,
      );
    }

    return content;
  }
}

/// EN: GBT Action Sheet for showing a list of actions
/// KO: 액션 리스트를 표시하는 GBT 액션 시트
Future<T?> showGBTActionSheet<T>({
  required BuildContext context,
  required List<GBTActionSheetItem<T>> actions,
  String? title,
  String? cancelLabel,
}) {
  final platform = Theme.of(context).platform;
  final useCupertino =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  if (useCupertino) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        actions: actions
            .map(
              (action) => CupertinoActionSheetAction(
                isDestructiveAction: action.isDestructive,
                onPressed: () {
                  action.onTap?.call();
                  Navigator.of(popupContext).pop(action.value);
                },
                child: Text(action.label),
              ),
            )
            .toList(growable: false),
        cancelButton: cancelLabel == null
            ? null
            : CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(popupContext).pop(),
                child: Text(cancelLabel),
              ),
      ),
    );
  }

  return showGBTBottomSheet<T>(
    context: context,
    title: title,
    isScrollControlled: true,
    child: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...actions.map((action) => _ActionItem<T>(action: action)),
            if (cancelLabel != null) ...[
              const Divider(height: 1),
              _CancelItem(label: cancelLabel),
            ],
          ],
        ),
      ),
    ),
  );
}

/// EN: Action sheet item data
/// KO: 액션 시트 아이템 데이터
class GBTActionSheetItem<T> {
  const GBTActionSheetItem({
    required this.label,
    this.icon,
    this.value,
    this.isDestructive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final T? value;
  final bool isDestructive;
  final VoidCallback? onTap;
}

/// EN: Action item widget with dark mode awareness
/// KO: 다크 모드 인식 액션 아이템 위젯
class _ActionItem<T> extends StatelessWidget {
  const _ActionItem({required this.action});

  final GBTActionSheetItem<T> action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = action.isDestructive
        ? GBTColors.error
        : (isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary);

    return Semantics(
      button: true,
      label: action.label,
      hint: action.isDestructive
          ? '탭하면 ${action.label} 작업이 실행됩니다 (삭제 동작)'
          : '탭하면 ${action.label} 작업이 실행됩니다',
      child: ListTile(
        leading: action.icon != null ? Icon(action.icon, color: color) : null,
        title: Text(
          action.label,
          style: GBTTypography.bodyMedium.copyWith(color: color),
        ),
        onTap: () {
          action.onTap?.call();
          Navigator.of(context).pop(action.value);
        },
      ),
    );
  }
}

/// EN: Cancel item widget with dark mode awareness
/// KO: 다크 모드 인식 취소 아이템 위젯
class _CancelItem extends StatelessWidget {
  const _CancelItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      hint: '탭하면 시트를 닫습니다',
      child: ListTile(
        title: Text(
          label,
          style: GBTTypography.bodyMedium.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// EN: GBT Confirmation Sheet for showing confirmation dialog
/// KO: 확인 다이얼로그를 표시하는 GBT 확인 시트
Future<bool?> showGBTConfirmationSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool isDestructive = false,
}) {
  return showGBTBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    child: SafeArea(
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SingleChildScrollView(
            padding: GBTSpacing.paddingPage,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  title,
                  style: GBTTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? GBTColors.darkTextPrimary
                        : GBTColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  message,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GBTSpacing.lg),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: GBTSpacing.md,
                  overflowSpacing: GBTSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(cancelLabel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: isDestructive
                          ? FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            )
                          : null,
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
