/// EN: Staggered list item widget with fade and slide animations
/// KO: 페이드 및 슬라이드 애니메이션이 적용된 stagger 리스트 아이템 위젯
library;

import 'package:flutter/material.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_animations.dart';

/// EN: A widget that applies staggered fade and slide animations to list items.
/// Useful for creating sequential reveal effects in lists and grids.
///
/// The widget animates the child with:
/// - Fade: opacity 0.0 → 1.0
/// - Slide: from 5% below to original position
///
/// When reduce motion is enabled, animations are skipped and the child
/// is displayed immediately.
///
/// Example:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     return StaggeredListItem(
///       delay: GBTStaggerAnimations.delayFor(index),
///       child: MyListTile(item: items[index]),
///     );
///   },
/// )
/// ```
///
/// KO: 리스트 아이템에 stagger 페이드 및 슬라이드 애니메이션을 적용하는 위젯입니다.
/// 리스트와 그리드에서 순차적인 표시 효과를 만드는 데 유용합니다.
///
/// 위젯은 다음과 같이 자식을 애니메이션합니다:
/// - 페이드: 불투명도 0.0 → 1.0
/// - 슬라이드: 5% 아래에서 원래 위치로
///
/// 모션 감소가 활성화된 경우, 애니메이션을 건너뛰고 자식을
/// 즉시 표시합니다.
///
/// 예시:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     return StaggeredListItem(
///       delay: GBTStaggerAnimations.delayFor(index),
///       child: MyListTile(item: items[index]),
///     );
///   },
/// )
/// ```
class StaggeredListItem extends StatefulWidget {
  /// EN: Creates a staggered list item with fade and slide animations.
  /// KO: 페이드 및 슬라이드 애니메이션이 적용된 stagger 리스트 아이템을 생성합니다.
  const StaggeredListItem({
    required this.delay,
    required this.child,
    super.key,
  });

  /// EN: Delay before starting the animation.
  /// Use [GBTStaggerAnimations.delayFor] to calculate appropriate delays
  /// based on item index.
  ///
  /// KO: 애니메이션을 시작하기 전 지연 시간입니다.
  /// 아이템 인덱스를 기반으로 적절한 지연 시간을 계산하려면
  /// [GBTStaggerAnimations.delayFor]를 사용하세요.
  final Duration delay;

  /// EN: The child widget to animate.
  /// KO: 애니메이션을 적용할 자식 위젯입니다.
  final Widget child;

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  /// EN: Animation controller for managing the animation lifecycle
  /// KO: 애니메이션 생명주기를 관리하는 애니메이션 컨트롤러
  late AnimationController _controller;

  /// EN: Fade animation (opacity 0.0 → 1.0)
  /// KO: 페이드 애니메이션 (불투명도 0.0 → 1.0)
  late Animation<double> _fadeAnimation;

  /// EN: Slide animation (5% below → original position)
  /// KO: 슬라이드 애니메이션 (5% 아래 → 원래 위치)
  late Animation<Offset> _slideAnimation;

  bool _disableAnimations = false;
  bool _hasScheduled = false;

  @override
  void initState() {
    super.initState();

    // EN: Initialize animation controller with appropriate duration
    // KO: 적절한 지속 시간으로 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: GBTAnimations.normal,
      vsync: this,
    );

    // EN: Create fade animation with easeOutCubic curve
    // KO: easeOutCubic 커브로 페이드 애니메이션 생성
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: GBTAnimations.defaultCurve),
    );

    // EN: Create slide animation (5% below to original position)
    // KO: 슬라이드 애니메이션 생성 (5% 아래에서 원래 위치로)
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: GBTAnimations.defaultCurve,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // EN: Check if animations should be disabled (safe in dependencies phase).
    // KO: 애니메이션 비활성화 여부 확인 (의존성 단계에서 안전).
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_disableAnimations == disableAnimations && _hasScheduled) return;
    _disableAnimations = disableAnimations;
    _controller.duration = disableAnimations
        ? Duration.zero
        : GBTAnimations.normal;

    if (disableAnimations) {
      _controller.value = 1.0;
      _hasScheduled = true;
      return;
    }

    if (!_hasScheduled) {
      _hasScheduled = true;
      _startAnimation();
    }
  }

  /// EN: Starts the animation after the specified delay.
  /// KO: 지정된 지연 후 애니메이션을 시작합니다.
  ///
  /// KO: 지정된 지연 후 애니메이션을 시작합니다.
  void _startAnimation() {
    Future.delayed(widget.delay, () {
      // EN: Check if widget is still mounted before starting animation
      // KO: 애니메이션을 시작하기 전에 위젯이 여전히 마운트되어 있는지 확인
      if (mounted && !_disableAnimations) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    // EN: Clean up animation controller
    // KO: 애니메이션 컨트롤러 정리
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // EN: Apply slide and fade transitions to the child widget
    // KO: 자식 위젯에 슬라이드 및 페이드 전환 적용
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}
