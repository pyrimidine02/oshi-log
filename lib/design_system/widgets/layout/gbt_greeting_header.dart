/// EN: Time-based greeting header with indigo gradient background
/// KO: 시간대별 인사말 + 인디고 그라디언트 배경 헤더
library;

import 'package:flutter/material.dart';

import '../../localization/locale_text.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';
import '../common/gbt_image.dart';

/// EN: Greeting header that replaces the hero section.
///     Displays a time-based greeting with indigo gradient background.
///     When [userBannerUrl] is provided it takes priority over [backgroundImageUrl].
///     When [onCustomizeTap] is provided, a small palette icon button appears in
///     the bottom-right corner of the header to open the banner picker.
///     Height: SafeArea.top + kToolbarHeight + 130px (~230-270px)
/// KO: 히어로 섹션을 대체하는 인사말 헤더.
///     시간대별 인사말을 인디고 그라디언트 배경에 표시합니다.
///     [userBannerUrl]이 제공되면 [backgroundImageUrl]보다 우선 적용됩니다.
///     [onCustomizeTap]이 제공되면 헤더 오른쪽 하단에 팔레트 아이콘 버튼이 표시되어
///     배너 피커를 열 수 있습니다.
///     높이: SafeArea.top + kToolbarHeight + 130px (~230-270px)
class GBTGreetingHeader extends StatelessWidget {
  const GBTGreetingHeader({
    super.key,
    this.userName,
    this.backgroundImageUrl,
    this.userBannerUrl,
    this.featuredTitle,
    this.featuredDate,
    this.featuredPosterUrl,
    this.onFeaturedTap,
    this.onCustomizeTap,
  });

  final String? userName;
  final String? backgroundImageUrl;

  /// EN: User's custom banner URL — takes priority over [backgroundImageUrl].
  /// KO: 사용자의 커스텀 배너 URL — [backgroundImageUrl]보다 우선 적용됩니다.
  final String? userBannerUrl;

  final String? featuredTitle;
  final String? featuredDate;
  final String? featuredPosterUrl;
  final VoidCallback? onFeaturedTap;

  /// EN: Callback invoked when the user taps the palette customize button.
  ///     When null the button is not shown.
  /// KO: 사용자가 팔레트 커스터마이징 버튼을 탭했을 때 호출되는 콜백.
  ///     null이면 버튼이 표시되지 않습니다.
  final VoidCallback? onCustomizeTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getGreeting(context, userName);
    final topPadding = MediaQuery.of(context).padding.top;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final directionality = Directionality.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textMaxWidth = (screenWidth - (GBTSpacing.pageHorizontal * 2)).clamp(
      120.0,
      720.0,
    );
    final titleStyle = GBTTypography.displayMedium.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      shadows: const [
        Shadow(color: Color(0x73000000), blurRadius: 10, offset: Offset(0, 2)),
      ],
    );
    final subtitleStyle = GBTTypography.bodyLarge.copyWith(
      color: Colors.white.withValues(alpha: 0.92),
      shadows: const [
        Shadow(color: Color(0x70000000), blurRadius: 8, offset: Offset(0, 1)),
      ],
    );
    final titleSingleLineHeight = _measureTextHeight(
      text: greeting.title,
      style: titleStyle,
      maxWidth: textMaxWidth,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: directionality,
      maxLines: 1,
    );
    final titleMultiLineHeight = _measureTextHeight(
      text: greeting.title,
      style: titleStyle,
      maxWidth: textMaxWidth,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: directionality,
      maxLines: 2,
    );
    final subtitleSingleLineHeight = _measureTextHeight(
      text: greeting.subtitle,
      style: subtitleStyle,
      maxWidth: textMaxWidth,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: directionality,
      maxLines: 1,
    );
    final subtitleMultiLineHeight = _measureTextHeight(
      text: greeting.subtitle,
      style: subtitleStyle,
      maxWidth: textMaxWidth,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: directionality,
      maxLines: 2,
    );
    final multilineExtraHeight =
        (titleMultiLineHeight - titleSingleLineHeight) +
        (subtitleMultiLineHeight - subtitleSingleLineHeight);
    // EN: User banner takes priority over the content-derived background image.
    // KO: 사용자 배너가 콘텐츠에서 파생된 배경 이미지보다 우선 적용됩니다.
    final String? effectiveBackgroundUrl;
    final uBannerUrl = userBannerUrl;
    if (uBannerUrl != null && uBannerUrl.trim().isNotEmpty) {
      effectiveBackgroundUrl = uBannerUrl;
    } else {
      effectiveBackgroundUrl = backgroundImageUrl;
    }

    final resolvedBackgroundUrl =
        (effectiveBackgroundUrl?.trim().isNotEmpty == true)
        ? effectiveBackgroundUrl
        : null;
    // EN: Hide the live chip when the user has a custom banner set,
    //     so the banner image shows cleanly without the live poster overlay.
    // KO: 사용자 배너가 설정된 경우 라이브 칩을 숨겨서
    //     라이브 포스터 오버레이 없이 배너 이미지만 깔끔하게 표시합니다.
    final hasUserBanner = uBannerUrl != null && uBannerUrl.trim().isNotEmpty;
    final hasFeaturedLive =
        !hasUserBanner &&
        featuredTitle != null &&
        featuredTitle!.trim().isNotEmpty;
    final featuredExtraHeight = hasFeaturedLive ? 56.0 : 0.0;
    final textScaleExtraHeight = ((textScale - 1.0) * 36.0).clamp(0.0, 40.0);
    final headerHeight =
        topPadding +
        kToolbarHeight +
        130 +
        featuredExtraHeight +
        textScaleExtraHeight +
        multilineExtraHeight.clamp(0.0, 64.0);

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: isDark
            ? GBTColors.darkGreetingGradient
            : GBTColors.greetingGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // EN: Mesh-gradient glows — two soft radial blobs layered over the
          // base greetingGradient for a liquid-glass depth feel. Cheap
          // (RadialGradient falloff, no shader/blur) and naturally hidden
          // once a real background image covers this layer below.
          // KO: 메시 그라디언트 글로우 — 베이스 greetingGradient 위에 얹는
          // 두 개의 부드러운 라디얼 블롭으로 리퀴드 글래스 깊이감을 연출합니다.
          // 저비용(RadialGradient 페이드아웃, 셰이더/블러 없음)이며 실제
          // 배경 이미지가 있으면 아래 레이어라 자연스럽게 가려집니다.
          Positioned(
            top: -50,
            right: -60,
            child: _MeshGlow(
              color: GBTColors.secondaryLight,
              alpha: isDark ? 0.22 : 0.16,
              size: 240,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _MeshGlow(
              color: GBTColors.accentBlue,
              alpha: isDark ? 0.26 : 0.18,
              size: 220,
            ),
          ),
          if (resolvedBackgroundUrl != null)
            GBTImage(
              imageUrl: resolvedBackgroundUrl,
              fit: BoxFit.cover,
              useShimmer: false,
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x66000000), Color(0xC9000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              topPadding + kToolbarHeight + GBTSpacing.md,
              GBTSpacing.pageHorizontal,
              GBTSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  greeting.title,
                  style: titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  greeting.subtitle,
                  style: subtitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasFeaturedLive) ...[
                  const SizedBox(height: GBTSpacing.sm),
                  _FeaturedLiveChip(
                    title: featuredTitle!,
                    dateLabel: featuredDate,
                    posterUrl: featuredPosterUrl,
                    onTap: onFeaturedTap,
                  ),
                ],
              ],
            ),
          ),
          // EN: Palette customize button — bottom-right corner floating badge.
          //     Only shown when [onCustomizeTap] is provided.
          // KO: 팔레트 커스터마이징 버튼 — 오른쪽 하단 모서리 플로팅 뱃지.
          //     [onCustomizeTap]이 제공된 경우에만 표시됩니다.
          if (onCustomizeTap != null)
            Positioned(
              right: GBTSpacing.sm,
              bottom: GBTSpacing.sm,
              child: Semantics(
                label: '배너 꾸미기',
                button: true,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onCustomizeTap,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(GBTSpacing.xs),
                      child: Icon(
                        Icons.palette_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// EN: Single soft radial glow circle — a cheap building block for the
/// header's mesh-gradient depth effect (no blur shader, just gradient falloff).
/// KO: 부드러운 라디얼 글로우 원 하나 — 헤더의 메시 그라디언트 깊이감 효과를
/// 위한 저비용 빌딩 블록 (블러 셰이더 없이 그라디언트 페이드아웃만 사용).
class _MeshGlow extends StatelessWidget {
  const _MeshGlow({
    required this.color,
    required this.alpha,
    required this.size,
  });

  final Color color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedLiveChip extends StatelessWidget {
  const _FeaturedLiveChip({
    required this.title,
    this.dateLabel,
    this.posterUrl,
    this.onTap,
  });

  final String title;
  final String? dateLabel;
  final String? posterUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasPoster = posterUrl != null && posterUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(GBTSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
                    child: hasPoster
                        ? GBTImage(
                            imageUrl: posterUrl!,
                            fit: BoxFit.cover,
                            useShimmer: false,
                          )
                        : ColoredBox(
                            color: GBTColors.darkSurfaceElevated.withValues(
                              alpha: 0.55,
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GBTTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateLabel != null && dateLabel!.trim().isNotEmpty)
                      Text(
                        dateLabel!,
                        style: GBTTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Returns personalized greeting based on current hour and user name
/// KO: 현재 시간 및 사용자명에 따른 맞춤형 인사말 반환
_Greeting _getGreeting(BuildContext context, String? userName) {
  final namePrefixKo = userName != null && userName.isNotEmpty
      ? '$userName님, '
      : '';
  final nameSuffixEn = userName != null && userName.isNotEmpty
      ? ', $userName'
      : '';
  final nameSuffixJa = userName != null && userName.isNotEmpty
      ? '、$userNameさん'
      : '';

  final now = DateTime.now();
  final hour = now.hour;
  final isWeekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

  if (hour >= 6 && hour < 12) {
    return _Greeting(
      title: context.l10n(
        ko: '$namePrefixKo상쾌한 아침이에요',
        en: 'Good morning$nameSuffixEn',
        ja: 'おはようございます$nameSuffixJa',
      ),
      subtitle: context.l10n(
        ko: isWeekend ? '주말을 맞아 새로운 성지로 떠나볼까요?' : '오늘 하루도 힘차게 시작해봐요!',
        en: isWeekend
            ? 'How about a weekend pilgrimage?'
            : 'Let\'s start the day right!',
        ja: isWeekend ? '週末の聖地巡礼はいかがですか？' : '今日も一日頑張りましょう！',
      ),
    );
  } else if (hour >= 12 && hour < 18) {
    return _Greeting(
      title: context.l10n(
        ko: '$namePrefixKo좋은 오후예요',
        en: 'Good afternoon$nameSuffixEn',
        ja: 'こんにちは$nameSuffixJa',
      ),
      subtitle: context.l10n(
        ko: isWeekend
            ? '여유로운 주말, 새로운 장소를 발견해 보세요'
            : '잠시 휴식을 취하며 새로운 음악을 들어볼까요?',
        en: isWeekend
            ? 'Relax and discover new places'
            : 'Take a break with some new music',
        ja: isWeekend ? '休日は新しい場所を見つけてみましょう' : '休憩しながら新しい音楽を聴いてみませんか？',
      ),
    );
  } else if (hour >= 18) {
    return _Greeting(
      title: context.l10n(
        ko: '$namePrefixKo멋진 저녁이에요',
        en: 'Good evening$nameSuffixEn',
        ja: 'こんばんは$nameSuffixJa',
      ),
      subtitle: context.l10n(
        ko: '오늘의 라이브와 함께 하루를 마무리해 보세요',
        en: 'Wrap up your day with today\'s live events',
        ja: '今日のライブと共に一日を締めくくりましょう',
      ),
    );
  } else {
    return _Greeting(
      title: context.l10n(
        ko: '$namePrefixKo아직 깨어 계시네요',
        en: 'Still awake$nameSuffixEn',
        ja: 'まだ起きているんですね$nameSuffixJa',
      ),
      subtitle: context.l10n(
        ko: '밤에도 걸즈밴드의 음악은 계속됩니다',
        en: 'The band\'s music continues through the night',
        ja: '夜もガールズバンドの音楽は続きます',
      ),
    );
  }
}

class _Greeting {
  const _Greeting({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

double _measureTextHeight({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextScaler textScaler,
  required TextDirection textDirection,
  required int maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  return painter.height;
}
