/// EN: Auto-advancing banner carousel for the home page header area.
/// KO: 홈 페이지 헤더 영역의 자동 전환 배너 캐러셀.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../application/home_banners_controller.dart';
import '../../domain/entities/home_banner.dart';

/// EN: Home page banner carousel — auto-advances every 3 s, swipeable.
/// EN: Hides itself completely when there are no banners or on error.
/// KO: 홈 페이지 배너 캐러셀 — 3초마다 자동 전환, 스와이프 가능.
/// KO: 배너가 없거나 오류 시 자체적으로 완전히 숨겨집니다.
class HomeBannerCarousel extends ConsumerStatefulWidget {
  const HomeBannerCarousel({super.key, this.onBannerTap});

  /// EN: Optional override for tap handling (e.g. analytics).
  /// EN: When provided, the default navigation logic is skipped entirely.
  /// KO: 탭 처리 오버라이드 (예: 분석). 제공하면 기본 네비게이션 로직이
  /// KO: 완전히 생략됩니다.
  final void Function(HomeBanner banner)? onBannerTap;

  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  // EN: Peek fraction so neighboring slides are visible at the edges —
  //     gives the rail a "parallax-lite" carousel feel instead of a flat
  //     full-width swap.
  // KO: 옆 슬라이드가 가장자리에 살짝 보이도록 하는 peek 비율 —
  //    단순 전체 폭 전환 대신 "parallax-lite" 캐러셀 느낌을 줍니다.
  static const double _viewportFraction = 0.92;

  late final PageController _pageController;
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;

  // EN: Tracks whether a user-initiated scroll is in progress so the
  // EN: auto-advance timer does not fight the gesture.
  // KO: 사용자가 스크롤 중인지 추적해 자동 전환 타이머가 제스처와
  // KO: 충돌하지 않도록 합니다.
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // EN: Timer helpers
  // KO: 타이머 헬퍼
  // --------------------------------------------------------

  void _startTimer(List<HomeBanner> banners) {
    _autoAdvanceTimer?.cancel();
    if (banners.length <= 1) return;
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _isUserScrolling) return;
      final nextPage = (_currentPage + 1) % banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index, List<HomeBanner> banners) {
    if (!mounted) return;
    setState(() => _currentPage = index);
    // EN: Restart timer on manual swipe to give extra reading time.
    // KO: 수동 스와이프 시 타이머를 재시작하여 읽을 시간을 추가로 제공합니다.
    _startTimer(banners);
  }

  // --------------------------------------------------------
  // EN: Tap handling
  // KO: 탭 처리
  // --------------------------------------------------------

  Future<void> _handleBannerTap(BuildContext context, HomeBanner banner) async {
    if (widget.onBannerTap != null) {
      widget.onBannerTap!(banner);
      return;
    }
    switch (banner.actionType) {
      case HomeBannerActionType.externalUrl:
        final raw = banner.actionValue;
        if (raw != null && raw.isNotEmpty) {
          final uri = Uri.tryParse(raw);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      case HomeBannerActionType.internalRoute:
        final route = banner.actionValue;
        if (route != null && route.isNotEmpty && context.mounted) {
          context.push(route);
        }
      case HomeBannerActionType.none:
        break;
    }
  }

  // --------------------------------------------------------
  // EN: Build
  // KO: 빌드
  // --------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(homeBannersProvider);

    return bannersAsync.when(
      loading: _buildShimmer,
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // EN: Kick off the auto-advance timer after the first frame so
        // EN: the PageController is attached to the viewport.
        // KO: PageController가 뷰포트에 연결된 후 자동 전환 타이머를
        // KO: 첫 번째 프레임 이후에 시작합니다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startTimer(banners);
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageView(context, banners),
            if (banners.length > 1) ...[
              const SizedBox(height: GBTSpacing.sm),
              _buildDotIndicators(banners.length),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    return GBTShimmer(
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.pageHorizontal,
        ),
        decoration: BoxDecoration(
          color: GBTColors.surfaceVariant,
          borderRadius: BorderRadius.circular(GBTSpacing.lg2),
        ),
      ),
    );
  }

  Widget _buildPageView(BuildContext context, List<HomeBanner> banners) {
    return SizedBox(
      height: 200,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: (_) {
          _isUserScrolling = true;
          return false;
        },
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (_) {
            _isUserScrolling = false;
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (index) => _onPageChanged(index, banners),
            itemBuilder: (context, index) {
              final banner = banners[index];
              // EN: Subtle scale-down for off-center slides — the
              //     "parallax-lite" depth cue paired with the peek
              //     viewport fraction above. The AnimatedBuilder wraps only
              //     the Transform so the slide subtree is built once and
              //     reused across scroll frames.
              // KO: 중앙에서 벗어난 슬라이드를 살짝 축소 — 위 peek
              //     비율과 함께 "parallax-lite" 깊이감을 만듭니다.
              //     AnimatedBuilder가 Transform만 감싸므로 슬라이드 서브트리는
              //     한 번만 빌드되고 스크롤 프레임 간 재사용됩니다.
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  var scale = 1.0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    final page =
                        _pageController.page ?? _currentPage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.08)).clamp(
                      0.92,
                      1.0,
                    );
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _BannerSlide(
                  banner: banner,
                  onTap: () => _handleBannerTap(context, banner),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          // EN: Active dot: 20×8 indigo pill; inactive dot: 8×8 grey circle.
          // KO: 활성 점: 20×8 인디고 알약; 비활성 점: 8×8 회색 원형.
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? GBTColors.darkPrimary : GBTColors.primary)
                : (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary)
                      .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ============================================================
// EN: Private single-slide widget — extracted for rebuild scope.
// KO: 재빌드 범위 최소화를 위해 분리된 단일 슬라이드 위젯.
// ============================================================

/// EN: A single banner slide with image, optional overlay text, and tap handler.
/// KO: 이미지, 선택적 오버레이 텍스트, 탭 핸들러가 있는 단일 배너 슬라이드.
class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, required this.onTap});

  final HomeBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasText =
        (banner.title?.isNotEmpty == true) ||
        (banner.subtitle?.isNotEmpty == true);
    final isTappable = banner.actionType != HomeBannerActionType.none;

    return GestureDetector(
      onTap: isTappable ? onTap : null,
      child: Padding(
        // EN: Tighter inner gap than a full page margin — the PageView's
        //     peek viewport fraction already insets the first/last slide
        //     from the screen edge.
        // KO: 전체 페이지 여백보다 좁은 내부 간격 — PageView의 peek
        //     비율이 이미 첫/마지막 슬라이드를 화면 가장자리에서
        //     띄워주기 때문입니다.
        padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs2),
        child: Semantics(
          label: banner.title ?? '홈 배너',
          button: isTappable,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GBTSpacing.lg2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // EN: Full-bleed banner image with built-in shimmer placeholder.
                // KO: 내장 쉬머 플레이스홀더가 있는 전체 크기 배너 이미지.
                GBTImage(
                  imageUrl: banner.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  semanticLabel: banner.title ?? '홈 배너',
                ),
                // EN: Bottom gradient overlay for text readability.
                // KO: 텍스트 가독성을 위한 하단 그라디언트 오버레이.
                if (hasText)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                if (hasText)
                  Positioned(
                    left: GBTSpacing.md,
                    right: GBTSpacing.md,
                    bottom: GBTSpacing.md,
                    child: _BannerTextOverlay(banner: banner),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Overlay text column drawn on top of the banner image.
/// KO: 배너 이미지 위에 표시되는 오버레이 텍스트 열.
class _BannerTextOverlay extends StatelessWidget {
  const _BannerTextOverlay({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (banner.title != null)
          Text(
            banner.title!,
            style: GBTTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (banner.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            banner.subtitle!,
            style: GBTTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
