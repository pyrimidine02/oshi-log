/// EN: Carousel-style event card — vertical poster with gradient overlay
/// KO: 캐러셀 스타일 이벤트 카드 — 세로 포스터 + 그라디언트 오버레이
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_decorations.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';
import '../common/gbt_image.dart';

/// EN: Vertical poster event card for horizontal carousel display.
///     2:3 aspect ratio with gradient overlay, title at bottom,
///     date badge top-left, LIVE badge top-right.
/// KO: 수평 캐러셀 표시용 세로 포스터 이벤트 카드.
///     2:3 비율 + 그라디언트 오버레이, 하단 제목,
///     좌상단 날짜 배지, 우상단 LIVE 배지.
class GBTEventCardCarousel extends StatelessWidget {
  const GBTEventCardCarousel({
    super.key,
    required this.title,
    this.date,
    this.posterUrl,
    this.isLive = false,
    this.width = 140,
    this.onTap,
  });

  /// EN: Event title
  /// KO: 이벤트 제목
  final String title;

  /// EN: Event date display string
  /// KO: 이벤트 날짜 표시 문자열
  final String? date;

  /// EN: Event poster image URL
  /// KO: 이벤트 포스터 이미지 URL
  final String? posterUrl;

  /// EN: Whether event is currently live
  /// KO: 이벤트가 현재 진행 중인지 여부
  final bool isLive;

  /// EN: Card width
  /// KO: 카드 너비
  final double width;

  /// EN: Callback when card is tapped
  /// KO: 카드가 탭되었을 때 콜백
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: [
        title,
        if (date != null) date!,
        if (isLive) '라이브 진행 중',
      ].join(', '),
      hint: onTap != null ? '탭하면 이벤트 상세로 이동합니다' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // EN: Background image
                  // KO: 배경 이미지
                  _buildPoster(isDark),

                  // EN: Bottom gradient overlay for text readability
                  // KO: 텍스트 가독성을 위한 하단 그라디언트 오버레이
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: GBTColors.carouselCardOverlayGradient,
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

                  // EN: Date badge — top left, semi-transparent
                  // KO: 날짜 배지 — 좌상단, 반투명
                  if (date != null)
                    Positioned(
                      top: GBTSpacing.sm,
                      left: GBTSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.xs,
                          vertical: GBTSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: GBTColors.primary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(
                            GBTSpacing.radiusXs,
                          ),
                        ),
                        child: Text(
                          date!,
                          style: GBTTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // EN: LIVE badge — top right, red
                  // KO: LIVE 배지 — 우상단, 빨강
                  if (isLive)
                    Positioned(
                      top: GBTSpacing.sm,
                      right: GBTSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.xs,
                          vertical: GBTSpacing.xxs,
                        ),
                        decoration: GBTDecorations.liveBadge(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: GBTSpacing.xxs),
                            Text(
                              'LIVE',
                              style: GBTTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // EN: Title at bottom with text shadow
                  // KO: 하단 제목 + 텍스트 쉐도우
                  Positioned(
                    left: GBTSpacing.sm,
                    right: GBTSpacing.sm,
                    bottom: GBTSpacing.sm,
                    child: Text(
                      title,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Color(0x80000000)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(bool isDark) {
    if (posterUrl != null && posterUrl!.trim().isNotEmpty) {
      return GBTImage(
        imageUrl: posterUrl!,
        fit: BoxFit.cover,
        semanticLabel: '$title 포스터',
      );
    }
    return Container(
      color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 32,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.primary,
        ),
      ),
    );
  }
}
