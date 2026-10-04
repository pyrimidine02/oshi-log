/// EN: GBT animation system for consistent motion, transitions, and timing
/// KO: 일관된 모션, 전환, 타이밍을 위한 GBT 애니메이션 시스템
library;

import 'package:flutter/material.dart';

/// EN: Animation constants for consistent motion
/// KO: 일관된 모션을 위한 애니메이션 상수
class GBTAnimations {
  GBTAnimations._();

  // ========================================
  // EN: Standard Durations (organic timing)
  // KO: 표준 지속 시간 (유기적 타이밍)
  // ========================================

  /// EN: Fast transitions for micro-interactions (130ms)
  /// KO: 마이크로 인터랙션을 위한 빠른 전환 (130ms)
  static const Duration fast = Duration(milliseconds: 130);

  /// EN: Normal transitions for most UI elements (280ms)
  /// KO: 대부분의 UI 요소를 위한 보통 전환 (280ms)
  static const Duration normal = Duration(milliseconds: 280);

  /// EN: Slow transitions for major state changes (420ms)
  /// KO: 주요 상태 변경을 위한 느린 전환 (420ms)
  static const Duration slow = Duration(milliseconds: 420);

  /// EN: Emphasized transitions for important moments (500ms)
  /// KO: 중요한 순간을 위한 강조 전환 (500ms)
  static const Duration emphasis = Duration(milliseconds: 500);

  // ========================================
  // EN: Standard Curves
  // KO: 표준 커브
  // ========================================

  /// EN: Default easing curve for most animations
  /// KO: 대부분의 애니메이션을 위한 기본 이징 커브
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// EN: Bounce curve for playful interactions
  /// KO: 경쾌한 인터랙션을 위한 바운스 커브
  static const Curve bounceCurve = Curves.easeOutBack;

  /// EN: Emphasized curve for Material 3 transitions
  /// KO: Material 3 전환을 위한 강조 커브
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  // ========================================
  // EN: Interaction Scale Factors
  // KO: 인터랙션 스케일 팩터
  // ========================================

  /// EN: Scale factor for pressed state (0.97)
  /// KO: 눌린 상태를 위한 스케일 팩터 (0.97)
  static const double pressedScale = 0.97;

  /// EN: Scale factor for hover state (1.02)
  /// KO: 호버 상태를 위한 스케일 팩터 (1.02)
  static const double hoverScale = 1.02;
}

/// EN: Stagger animation timing utilities for list/grid items
/// KO: 리스트/그리드 아이템을 위한 stagger 애니메이션 타이밍 유틸리티
class GBTStaggerAnimations {
  GBTStaggerAnimations._();

  // ========================================
  // EN: Stagger Configuration
  // KO: Stagger 설정
  // ========================================

  /// EN: Delay between each item in milliseconds (80ms)
  /// KO: 각 아이템 간 지연 시간 (밀리초, 80ms)
  static const int itemDelay = 80;

  /// EN: Maximum number of items to stagger (12)
  /// KO: Stagger할 최대 아이템 수 (12)
  static const int maxItems = 12;

  // ========================================
  // EN: Delay Calculation
  // KO: 지연 시간 계산
  // ========================================

  /// EN: Calculate stagger delay for a given item index.
  /// Returns Duration clamped to maxItems to prevent excessive delays.
  ///
  /// Example:
  /// ```dart
  /// AnimatedBuilder(
  ///   animation: animation,
  ///   builder: (context, child) {
  ///     final delay = GBTStaggerAnimations.delayFor(index);
  ///     final adjustedValue = Curves.easeOut.transform(
  ///       ((animation.value * 1000) - delay.inMilliseconds)
  ///         .clamp(0, itemDelay) / itemDelay,
  ///     );
  ///     return Opacity(opacity: adjustedValue, child: child);
  ///   },
  /// )
  /// ```
  ///
  /// KO: 주어진 아이템 인덱스에 대한 stagger 지연 시간을 계산합니다.
  /// 과도한 지연을 방지하기 위해 maxItems로 제한된 Duration을 반환합니다.
  ///
  /// 예시:
  /// ```dart
  /// AnimatedBuilder(
  ///   animation: animation,
  ///   builder: (context, child) {
  ///     final delay = GBTStaggerAnimations.delayFor(index);
  ///     final adjustedValue = Curves.easeOut.transform(
  ///       ((animation.value * 1000) - delay.inMilliseconds)
  ///         .clamp(0, itemDelay) / itemDelay,
  ///     );
  ///     return Opacity(opacity: adjustedValue, child: child);
  ///   },
  /// )
  /// ```
  static Duration delayFor(int index) {
    // EN: Clamp index to maxItems to prevent excessively long delays
    // KO: 지나치게 긴 지연을 방지하기 위해 인덱스를 maxItems로 제한
    final clampedIndex = index.clamp(0, maxItems);
    return Duration(milliseconds: clampedIndex * itemDelay);
  }
}

/// EN: Hero animation tag generators for consistent navigation transitions
/// KO: 일관된 네비게이션 전환을 위한 Hero 애니메이션 태그 생성기
class GBTHeroTags {
  GBTHeroTags._();

  // ========================================
  // EN: Place Hero Tags
  // KO: 장소 Hero 태그
  // ========================================

  /// EN: Generate Hero tag for place image
  /// KO: 장소 이미지를 위한 Hero 태그 생성
  ///
  /// Example: 'place_image_abc123'
  static String placeImage(String placeId) => 'place_image_$placeId';

  // ========================================
  // EN: News Hero Tags
  // KO: 뉴스 Hero 태그
  // ========================================

  /// EN: Generate Hero tag for news image
  /// KO: 뉴스 이미지를 위한 Hero 태그 생성
  ///
  /// Example: 'news_image_xyz789'
  static String newsImage(String newsId) => 'news_image_$newsId';

  // ========================================
  // EN: Event Hero Tags
  // KO: 이벤트 Hero 태그
  // ========================================

  /// EN: Generate Hero tag for event poster
  /// KO: 이벤트 포스터를 위한 Hero 태그 생성
  ///
  /// Example: 'event_poster_evt456'
  static String eventPoster(String eventId) => 'event_poster_$eventId';

  // ========================================
  // EN: User Hero Tags
  // KO: 사용자 Hero 태그
  // ========================================

  /// EN: Generate Hero tag for user avatar
  /// KO: 사용자 아바타를 위한 Hero 태그 생성
  ///
  /// Example: 'user_avatar_user123'
  static String userAvatar(String userId) => 'user_avatar_$userId';
}

/// EN: Page transition builders for GoRouter with Material 3 motion
/// KO: Material 3 모션을 적용한 GoRouter용 페이지 전환 빌더
class GBTPageTransitions {
  GBTPageTransitions._();

  // ========================================
  // EN: Fade Through Transition (Material 3)
  // KO: Fade Through 전환 (Material 3)
  // ========================================

  /// EN: Material 3 fade through transition - outgoing page fades out,
  /// then incoming page fades in. Suitable for peer-to-peer navigation.
  ///
  /// Usage with GoRouter:
  /// ```dart
  /// GoRoute(
  ///   path: '/details',
  ///   pageBuilder: (context, state) => CustomTransitionPage(
  ///     child: DetailsPage(),
  ///     transitionsBuilder: GBTPageTransitions.fadeThrough(),
  ///   ),
  /// )
  /// ```
  ///
  /// KO: Material 3 fade through 전환 - 나가는 페이지가 페이드 아웃된 후,
  /// 들어오는 페이지가 페이드 인됩니다. 동등한 레벨의 네비게이션에 적합합니다.
  ///
  /// GoRouter 사용 예시:
  /// ```dart
  /// GoRoute(
  ///   path: '/details',
  ///   pageBuilder: (context, state) => CustomTransitionPage(
  ///     child: DetailsPage(),
  ///     transitionsBuilder: GBTPageTransitions.fadeThrough(),
  ///   ),
  /// )
  /// ```
  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  )
  fadeThrough() {
    return (context, animation, secondaryAnimation, child) {
      // EN: Respect system-level reduce-motion accessibility setting.
      // KO: 시스템 수준의 모션 감소 접근성 설정을 존중합니다.
      if (MediaQuery.of(context).disableAnimations) return child;
      // EN: Fade out the outgoing page
      // KO: 나가는 페이지를 페이드 아웃
      const fadeOutStart = 0.0;
      const fadeOutEnd = 0.3;

      // EN: Fade in the incoming page
      // KO: 들어오는 페이지를 페이드 인
      const fadeInStart = 0.3;
      const fadeInEnd = 1.0;

      // EN: Outgoing page fade out
      // KO: 나가는 페이지 페이드 아웃
      final outgoingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(fadeOutStart, fadeOutEnd, curve: Curves.easeIn),
        ),
      );

      // EN: Incoming page fade in with slight scale
      // KO: 들어오는 페이지 페이드 인 및 약간의 스케일
      final incomingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(
            fadeInStart,
            fadeInEnd,
            curve: GBTAnimations.emphasizedCurve,
          ),
        ),
      );

      final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(
            fadeInStart,
            fadeInEnd,
            curve: GBTAnimations.emphasizedCurve,
          ),
        ),
      );

      // EN: Apply outgoing animation only if this is the outgoing page
      // KO: 나가는 페이지인 경우에만 나가는 애니메이션 적용
      if (secondaryAnimation.status != AnimationStatus.dismissed) {
        return FadeTransition(opacity: outgoingOpacity, child: child);
      }

      // EN: Apply incoming animation
      // KO: 들어오는 애니메이션 적용
      return FadeTransition(
        opacity: incomingOpacity,
        child: ScaleTransition(scale: scale, child: child),
      );
    };
  }

  // ========================================
  // EN: Shared Axis Y Transition (Modal Style)
  // KO: Shared Axis Y 전환 (모달 스타일)
  // ========================================

  /// EN: Shared axis Y transition - incoming page slides up with fade.
  /// Suitable for hierarchical navigation (parent -> child, e.g., modal sheets).
  ///
  /// Usage with GoRouter:
  /// ```dart
  /// GoRoute(
  ///   path: '/modal',
  ///   pageBuilder: (context, state) => CustomTransitionPage(
  ///     child: ModalPage(),
  ///     transitionsBuilder: GBTPageTransitions.sharedAxisY(),
  ///   ),
  /// )
  /// ```
  ///
  /// KO: Shared axis Y 전환 - 들어오는 페이지가 페이드와 함께 위로 슬라이드됩니다.
  /// 계층적 네비게이션에 적합합니다 (부모 -> 자식, 예: 모달 시트).
  ///
  /// GoRouter 사용 예시:
  /// ```dart
  /// GoRoute(
  ///   path: '/modal',
  ///   pageBuilder: (context, state) => CustomTransitionPage(
  ///     child: ModalPage(),
  ///     transitionsBuilder: GBTPageTransitions.sharedAxisY(),
  ///   ),
  /// )
  /// ```
  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  )
  sharedAxisY() {
    return (context, animation, secondaryAnimation, child) {
      // EN: Respect system-level reduce-motion accessibility setting.
      // KO: 시스템 수준의 모션 감소 접근성 설정을 존중합니다.
      if (MediaQuery.of(context).disableAnimations) return child;
      // EN: Outgoing page fades out and slides down slightly
      // KO: 나가는 페이지가 페이드 아웃되고 약간 아래로 슬라이드
      final outgoingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
        ),
      );

      final outgoingSlide =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.0, 0.05),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
            ),
          );

      // EN: Incoming page slides up and fades in
      // KO: 들어오는 페이지가 위로 슬라이드되고 페이드 인
      final incomingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: GBTAnimations.emphasizedCurve),
        ),
      );

      final incomingSlide =
          Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(
                0.3,
                1.0,
                curve: GBTAnimations.emphasizedCurve,
              ),
            ),
          );

      // EN: Apply outgoing animation only if this is the outgoing page
      // KO: 나가는 페이지인 경우에만 나가는 애니메이션 적용
      if (secondaryAnimation.status != AnimationStatus.dismissed) {
        return SlideTransition(
          position: outgoingSlide,
          child: FadeTransition(opacity: outgoingOpacity, child: child),
        );
      }

      // EN: Apply incoming animation
      // KO: 들어오는 애니메이션 적용
      return SlideTransition(
        position: incomingSlide,
        child: FadeTransition(opacity: incomingOpacity, child: child),
      );
    };
  }
}
