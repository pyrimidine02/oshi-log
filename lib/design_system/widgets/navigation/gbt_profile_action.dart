/// EN: Reusable AppBar profile action widget for navigating to settings.
/// KO: 설정으로 이동하는 재사용 가능한 AppBar 프로필 액션 위젯.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../common/gbt_image.dart';
import '../../../platform/router/app_router.dart';

/// EN: AppBar action that shows the user's profile avatar or a fallback icon.
/// KO: 사용자 프로필 아바타 또는 대체 아이콘을 표시하는 AppBar 액션.
class GBTProfileAction extends StatelessWidget {
  const GBTProfileAction({
    super.key,
    this.avatarUrl,
    this.onTap,
    this.placeholderBackgroundColor,
    this.placeholderIconColor,
  });

  final String? avatarUrl;
  final VoidCallback? onTap;
  final Color? placeholderBackgroundColor;
  final Color? placeholderIconColor;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl?.isNotEmpty ?? false;

    // EN: Use theme-aware placeholder colors.
    // KO: 테마 인식 플레이스홀더 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        placeholderBackgroundColor ??
        (isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant);
    final iconColor =
        placeholderIconColor ??
        (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary);

    return Semantics(
      button: true,
      label: '설정',
      child: IconButton(
        tooltip: '설정',
        onPressed: onTap ?? () => context.goToSettings(),
        icon: hasAvatar
            ? ClipOval(
                child: GBTImage(
                  imageUrl: avatarUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  semanticLabel: '프로필 사진',
                ),
              )
            : CircleAvatar(
                radius: 12,
                backgroundColor: bgColor,
                child: Icon(Icons.person, size: 16, color: iconColor),
              ),
        constraints: const BoxConstraints(
          minWidth: GBTSpacing.touchTarget,
          minHeight: GBTSpacing.touchTarget,
        ),
      ),
    );
  }
}
