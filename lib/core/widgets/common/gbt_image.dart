/// EN: Optimized network image widget with shimmer and accessibility.
/// KO: 쉬머와 접근성을 포함한 최적화 네트워크 이미지 위젯.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../utils/media_url.dart';
import '../feedback/gbt_loading.dart';

/// EN: Optimized image widget for remote URLs.
/// KO: 원격 URL을 위한 최적화 이미지 위젯.
class GBTImage extends StatelessWidget {
  const GBTImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.borderRadius,
    this.useShimmer = true,
    this.placeholder,
    this.errorWidget,
    this.onError,
  });

  /// EN: Image URL.
  /// KO: 이미지 URL.
  final String imageUrl;

  /// EN: Image width.
  /// KO: 이미지 너비.
  final double? width;

  /// EN: Image height.
  /// KO: 이미지 높이.
  final double? height;

  /// EN: Image fit behavior.
  /// KO: 이미지 맞춤 방식.
  final BoxFit fit;

  /// EN: Semantic label for accessibility.
  /// KO: 접근성 시맨틱 라벨.
  final String? semanticLabel;

  /// EN: Optional border radius for clipping.
  /// KO: 클리핑을 위한 모서리 반경.
  final BorderRadius? borderRadius;

  /// EN: Whether to show shimmer placeholder.
  /// KO: 쉬머 플레이스홀더 표시 여부.
  final bool useShimmer;

  /// EN: Custom placeholder widget.
  /// KO: 커스텀 플레이스홀더 위젯.
  final Widget? placeholder;

  /// EN: Custom error widget.
  /// KO: 커스텀 에러 위젯.
  final Widget? errorWidget;

  /// EN: Optional callback invoked when image loading fails.
  /// KO: 이미지 로딩 실패 시 호출되는 선택 콜백입니다.
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedUrl = resolveMediaUrl(imageUrl);

    // EN: Skip memory cache resizing for GIF URLs to preserve animation frames.
    // KO: GIF URL은 애니메이션 프레임 보존을 위해 메모리 캐시 리사이징을 건너뜁니다.
    final isGif = resolvedUrl.toLowerCase().contains('.gif');
    final cacheWidth = (!isGif && width != null && width!.isFinite)
        ? width!.toInt()
        : null;
    final cacheHeight = (!isGif && height != null && height!.isFinite)
        ? height!.toInt()
        : null;

    final baseImage = CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, _) => _buildPlaceholder(isDark: isDark),
      errorWidget: (context, _, __) {
        onError?.call();
        return _buildError(isDark: isDark);
      },
      // EN: Skip imageBuilder for GIFs so CachedNetworkImage renders animation
      //     frames natively via Flutter's image codec pipeline.
      // KO: GIF는 imageBuilder를 건너뛰어 Flutter 이미지 코덱 파이프라인을 통해
      //     CachedNetworkImage가 애니메이션 프레임을 네이티브로 렌더링하게 합니다.
      imageBuilder: isGif
          ? null
          : (context, imageProvider) {
              return Image(
                image: imageProvider,
                width: width,
                height: height,
                fit: fit,
              );
            },
    );

    // EN: Wrap with semantics: label if provided, exclude if decorative
    // KO: 시맨틱 래핑: 라벨이 있으면 제공, 장식적이면 제외
    final image = semanticLabel != null
        ? Semantics(label: semanticLabel, image: true, child: baseImage)
        : ExcludeSemantics(child: baseImage);

    final resolvedBorderRadius = borderRadius;
    if (resolvedBorderRadius == null) return image;

    return ClipRRect(borderRadius: resolvedBorderRadius, child: image);
  }

  /// EN: Build placeholder with dark mode awareness
  /// KO: 다크 모드 인식 플레이스홀더 빌드
  Widget _buildPlaceholder({required bool isDark}) {
    if (placeholder != null) return placeholder!;

    final container = Container(
      width: width,
      height: height,
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
    );

    if (!useShimmer) return container;

    return GBTShimmer(child: container);
  }

  /// EN: Build error widget with dark mode awareness
  /// KO: 다크 모드 인식 에러 위젯 빌드
  Widget _buildError({required bool isDark}) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
        borderRadius:
            borderRadius ?? BorderRadius.circular(GBTSpacing.radiusSm),
      ),
      child: Icon(
        Icons.broken_image,
        color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        size: GBTSpacing.iconLg,
      ),
    );
  }
}
