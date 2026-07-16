/// EN: GBT Place Card component for displaying place information
/// KO: 장소 정보를 표시하기 위한 GBT 장소 카드 컴포넌트
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/gbt_animations.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_decorations.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';
import '../common/gbt_image.dart';
import '../common/gbt_pressable.dart';

/// EN: Place card widget for list/grid display with press animation
/// KO: 프레스 애니메이션을 포함한 리스트/그리드 표시용 장소 카드 위젯
class GBTPlaceCard extends StatelessWidget {
  const GBTPlaceCard({
    super.key,
    required this.placeId,
    required this.name,
    required this.location,
    this.imageUrl,
    this.distance,
    this.isVerified = false,
    this.isFavorite = false,
    this.rating,
    this.onTap,
    this.onFavoriteToggle,
  });

  /// EN: Place ID for Hero tag
  /// KO: Hero 태그용 장소 ID
  final String placeId;

  /// EN: Place name
  /// KO: 장소 이름
  final String name;

  /// EN: Place location description
  /// KO: 장소 위치 설명
  final String location;

  /// EN: Place image URL
  /// KO: 장소 이미지 URL
  final String? imageUrl;

  /// EN: Distance from user
  /// KO: 사용자로부터의 거리
  final String? distance;

  /// EN: Whether place has been verified/visited
  /// KO: 장소가 인증/방문되었는지 여부
  final bool isVerified;

  /// EN: Whether place is favorited
  /// KO: 장소가 즐겨찾기인지 여부
  final bool isFavorite;

  /// EN: Place rating
  /// KO: 장소 평점
  final double? rating;

  /// EN: Callback when card is tapped
  /// KO: 카드가 탭되었을 때 콜백
  final VoidCallback? onTap;

  /// EN: Callback when favorite is toggled
  /// KO: 즐겨찾기가 토글되었을 때 콜백
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: [
        name,
        location,
        if (distance != null) '거리 $distance',
        if (isVerified) '방문 완료',
        if (rating != null) '평점 ${rating!.toStringAsFixed(1)}점',
        if (isFavorite) '즐겨찾기',
      ].join(', '),
      hint: onTap != null ? '탭하면 상세 정보를 확인합니다' : null,
      button: onTap != null,
      child: GBTPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: GBTAnimations.normal,
          curve: GBTAnimations.defaultCurve,
          // EN: Image-first card shell — 16px radius, border-subtle depth
          // instead of a heavy shadow.
          // KO: 이미지 우선 카드 셸 — 16px 반지름, 무거운 그림자 대신
          // border-subtle로 깊이감 표현.
          decoration: GBTDecorations.imageCard(isDark: isDark),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EN: Image section with overlay gradient (4:3 aspect ratio)
              // KO: 오버레이 그라디언트가 있는 이미지 섹션 (4:3 비율)
              Stack(
                children: [
                  // EN: Hero animation for smooth image transition, including iOS swipe-back.
                  // KO: iOS 스와이프 백 포함 부드러운 이미지 전환을 위한 Hero 애니메이션.
                  Hero(
                    tag: GBTHeroTags.placeImage(placeId),
                    transitionOnUserGestures: true,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _buildImage(isDark),
                    ),
                  ),
                  // EN: Top scrim so the verified/favorite badges stay legible
                  // over any photo.
                  // KO: 인증·즐겨찾기 배지가 어떤 사진 위에서도 가독성을
                  // 유지하도록 하는 상단 스크림.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: GBTDecorations.imageTopScrim,
                      ),
                    ),
                  ),
                  // EN: Glass-feel top edge hairline highlight.
                  // KO: 글래스 느낌의 상단 엣지 헤어라인 하이라이트.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: GBTDecorations.glassTopHairline,
                        ),
                      ),
                    ),
                  ),
                  // EN: Verified badge
                  // KO: 인증 배지
                  if (isVerified)
                    Positioned(
                      top: GBTSpacing.sm,
                      left: GBTSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: GBTDecorations.verifiedBadge(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '방문완료',
                              style: GBTTypography.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // EN: Favorite button
                  // KO: 즐겨찾기 버튼
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: GBTSpacing.sm,
                      right: GBTSpacing.sm,
                      child: _FavoriteButton(
                        isFavorite: isFavorite,
                        onToggle: onFavoriteToggle!,
                      ),
                    ),
                ],
              ),

              // EN: Content section
              // KO: 콘텐츠 섹션
              Padding(
                padding: GBTSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // EN: Place name — bodyMedium bold for neutral emphasis
                    // KO: 장소 이름 — 뉴트럴 강조를 위한 bodyMedium 볼드
                    Text(
                      name,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: isDark
                            ? GBTColors.darkTextPrimary
                            : GBTColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: GBTSpacing.xxs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: GBTTypography.bodySmall.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextSecondary
                                  : GBTColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Row(
                      children: [
                        // EN: Distance badge with teal semantic color
                        // KO: 틸 시맨틱 색상을 사용한 거리 배지
                        if (distance != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GBTSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? GBTSemanticColors.darkMetadataDistance
                                        .withValues(alpha: 0.15)
                                  : GBTSemanticColors.metadataDistance
                                        .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusXs,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me,
                                  size: 12,
                                  color: isDark
                                      ? GBTSemanticColors.darkMetadataDistance
                                      : GBTSemanticColors.metadataDistance,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distance!,
                                  style: GBTTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? GBTSemanticColors.darkMetadataDistance
                                        : GBTSemanticColors.metadataDistance,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (rating != null)
                            const SizedBox(width: GBTSpacing.sm),
                        ],
                        if (rating != null) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: GBTColors.rating,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: GBTTypography.labelSmall.copyWith(
                              color: isDark
                                  ? GBTColors.darkTextSecondary
                                  : GBTColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// EN: Build image widget with dark mode placeholder
  /// KO: 다크 모드 플레이스홀더가 있는 이미지 위젯 빌드
  Widget _buildImage(bool isDark) {
    if (imageUrl != null) {
      return GBTImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        semanticLabel: '$name 이미지',
      );
    }
    return Container(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        ),
      ),
    );
  }
}

/// EN: Animated favorite button with heart scale effect and 48dp touch target.
/// KO: 하트 스케일 효과와 48dp 터치 타겟을 가진 애니메이션 즐겨찾기 버튼.
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.isFavorite, required this.onToggle});

  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: GBTAnimations.normal,
      vsync: this,
    );
    _heartScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(_FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _heartController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
      button: true,
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onToggle();
          },
          customBorder: const CircleBorder(),
          // EN: Ensure 48dp minimum touch target (20 icon + 14*2 padding = 48)
          // KO: 48dp 최소 터치 타겟 보장 (20 아이콘 + 14*2 패딩 = 48)
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ScaleTransition(
              scale: _heartScale,
              child: AnimatedSwitcher(
                duration: GBTAnimations.fast,
                child: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(widget.isFavorite),
                  color: widget.isFavorite ? GBTColors.favorite : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Horizontal place card for list display with press animation
/// KO: 프레스 애니메이션을 포함한 리스트 표시용 가로 장소 카드
class GBTPlaceCardHorizontal extends StatelessWidget {
  const GBTPlaceCardHorizontal({
    super.key,
    required this.name,
    required this.location,
    this.imageUrl,
    this.distance,
    this.typeLabels = const [],
    this.tagLabels = const [],
    this.isVerified = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onDirectionsTap,
  });

  final String name;
  final String location;
  final String? imageUrl;
  final String? distance;
  final List<String> typeLabels;
  final List<String> tagLabels;
  final bool isVerified;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: [
        name,
        location,
        if (typeLabels.isNotEmpty) '유형 ${typeLabels.join(', ')}',
        if (tagLabels.isNotEmpty) '태그 ${tagLabels.join(', ')}',
        if (distance != null) '거리 $distance',
        if (isVerified) '방문 완료',
        if (isFavorite) '즐겨찾기',
      ].join(', '),
      hint: onTap != null ? '탭하면 상세 정보를 확인합니다' : null,
      button: onTap != null,
      child: GBTPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: GBTAnimations.normal,
          curve: GBTAnimations.defaultCurve,
          // EN: Borderless neutral surface — no shadow, no border
          // KO: 테두리 없는 뉴트럴 표면 — 그림자·테두리 제거
          decoration: BoxDecoration(
            color: isDark ? GBTColors.darkSurface : GBTColors.surface,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          ),
          child: Padding(
            padding: GBTSpacing.paddingMd,
            child: Row(
              children: [
                // EN: Portrait image with rounded corners (80×88 — 10:11 portrait crop for better venue display)
                // KO: 세로형 이미지 (80×88 — 장소 분위기 전달에 유리한 10:11 세로 비율)
                Container(
                  width: 80,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isDark
                        ? GBTColors.darkSurfaceElevated
                        : GBTColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? GBTImage(
                          imageUrl: imageUrl!,
                          width: 80,
                          height: 88,
                          fit: BoxFit.cover,
                          semanticLabel: '$name 이미지',
                        )
                      : Icon(
                          Icons.place_outlined,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                ),

                const SizedBox(width: GBTSpacing.md),

                // EN: Content
                // KO: 콘텐츠
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            // EN: Place name — bodyMedium bold for neutral emphasis
                            // KO: 장소 이름 — 뉴트럴 강조를 위한 bodyMedium 볼드
                            child: Text(
                              name,
                              style: GBTTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? GBTColors.darkTextPrimary
                                    : GBTColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: GBTColors.verified,
                            ),
                        ],
                      ),
                      const SizedBox(height: GBTSpacing.xxs),
                      Text(
                        location,
                        style: GBTTypography.bodySmall.copyWith(
                          color: isDark
                              ? GBTColors.darkTextSecondary
                              : GBTColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (typeLabels.isNotEmpty || tagLabels.isNotEmpty) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Wrap(
                          spacing: GBTSpacing.xs,
                          runSpacing: GBTSpacing.xxs,
                          children: [
                            ...typeLabels.map(
                              (type) => _PlaceMetaChip(
                                label: type,
                                icon: Icons.category_outlined,
                                isDark: isDark,
                                foreground: isDark
                                    ? GBTColors.infoLight
                                    : GBTColors.infoDark,
                                background: isDark
                                    ? GBTColors.infoDark.withValues(alpha: 0.2)
                                    : GBTColors.infoLight,
                              ),
                            ),
                            ...tagLabels.map(
                              (tag) => _PlaceMetaChip(
                                label: tag,
                                icon: Icons.sell_outlined,
                                isDark: isDark,
                                foreground: isDark
                                    ? GBTColors.secondaryLight
                                    : GBTColors.secondaryPressed,
                                background: isDark
                                    ? GBTColors.secondaryPressed.withValues(
                                        alpha: 0.2,
                                      )
                                    : GBTColors.secondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // EN: Distance badge with teal semantic color
                      // KO: 틸 시맨틱 색상을 사용한 거리 배지
                      if (distance != null) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GBTSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? GBTSemanticColors.darkMetadataDistance
                                      .withValues(alpha: 0.15)
                                : GBTSemanticColors.metadataDistance.withValues(
                                    alpha: 0.15,
                                  ),
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusXs,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 12,
                                color: isDark
                                    ? GBTSemanticColors.darkMetadataDistance
                                    : GBTSemanticColors.metadataDistance,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance!,
                                style: GBTTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? GBTSemanticColors.darkMetadataDistance
                                      : GBTSemanticColors.metadataDistance,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // EN: Favorite button with 48dp touch target
                // KO: 48dp 터치 타겟의 즐겨찾기 버튼
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDirectionsTap != null)
                      Tooltip(
                        message: '길안내',
                        child: SizedBox(
                          width: GBTSpacing.touchTarget,
                          height: GBTSpacing.touchTarget,
                          child: IconButton(
                            icon: Icon(
                              Icons.near_me_rounded,
                              color: isDark
                                  ? GBTColors.darkTextTertiary
                                  : GBTColors.textTertiary,
                            ),
                            onPressed: onDirectionsTap,
                            padding: const EdgeInsets.all(0),
                            constraints: const BoxConstraints(
                              minWidth: GBTSpacing.touchTarget,
                              minHeight: GBTSpacing.touchTarget,
                            ),
                          ),
                        ),
                      ),
                    if (onDirectionsTap != null && onFavoriteToggle != null)
                      const SizedBox(height: GBTSpacing.xxs),
                    if (onFavoriteToggle != null)
                      Tooltip(
                        message: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                        child: SizedBox(
                          width: GBTSpacing.touchTarget,
                          height: GBTSpacing.touchTarget,
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: GBTAnimations.fast,
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(isFavorite),
                                color: isFavorite
                                    ? GBTColors.favorite
                                    : (isDark
                                          ? GBTColors.darkTextTertiary
                                          : GBTColors.textTertiary),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onFavoriteToggle!();
                            },
                            padding: const EdgeInsets.all(0),
                            constraints: const BoxConstraints(
                              minWidth: GBTSpacing.touchTarget,
                              minHeight: GBTSpacing.touchTarget,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceMetaChip extends StatelessWidget {
  const _PlaceMetaChip({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
