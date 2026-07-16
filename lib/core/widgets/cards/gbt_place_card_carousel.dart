/// EN: Carousel-style place card — square image with name/location below
/// KO: 캐러셀 스타일 장소 카드 — 정사각형 이미지 + 하단 이름/위치
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_animations.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_decorations.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';
import '../common/gbt_image.dart';

/// EN: Compact place card for horizontal carousel display.
///     Square image (1:1) with name and location below. No border, subtle shadow in light mode.
/// KO: 수평 캐러셀 표시용 컴팩트 장소 카드.
///     정사각형 이미지(1:1) + 아래에 이름과 위치. 테두리 없음, 라이트 모드에서 부드러운 그림자.
class GBTPlaceCardCarousel extends StatelessWidget {
  const GBTPlaceCardCarousel({
    super.key,
    required this.placeId,
    required this.name,
    required this.location,
    this.imageUrl,
    this.width = 160,
    this.onTap,
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

  /// EN: Card width (height is derived from content)
  /// KO: 카드 너비 (높이는 콘텐츠에서 파생)
  final double width;

  /// EN: Callback when card is tapped
  /// KO: 카드가 탭되었을 때 콜백
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: '$name, $location',
      hint: onTap != null ? '탭하면 상세 정보를 확인합니다' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // EN: Square image, 2026 large-radius (radiusCard), border-subtle
              // depth (no shadow), plus a glass-feel top edge hairline.
              // KO: 정사각형 이미지, 2026 라지 라운드(radiusCard),
              // border-subtle 깊이감 (그림자 없음), 글래스 느낌의 상단
              // 엣지 헤어라인 추가.
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
                  border: Border.all(
                    color: isDark
                        ? GBTColors.darkBorderSubtle
                        : GBTColors.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Stack(
                  children: [
                    Hero(
                      tag: GBTHeroTags.placeImage(placeId),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            GBTSpacing.radiusCard,
                          ),
                          child: _buildImage(isDark),
                        ),
                      ),
                    ),
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
                  ],
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              // EN: Place name — bold
              // KO: 장소 이름 — 볼드
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
              // EN: Location — teal accent icon + secondary text
              // KO: 위치 — 틸 액센트 아이콘 + 보조 텍스트
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: isDark
                        ? GBTColors.darkPrimary
                        : GBTColors.accentTeal,
                  ),
                  const SizedBox(width: GBTSpacing.xxs),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (imageUrl != null) {
      return GBTImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        semanticLabel: '$name 이미지',
      );
    }
    return Container(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.primary,
        ),
      ),
    );
  }
}
