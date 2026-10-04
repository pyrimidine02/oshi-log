/// EN: A widget that provides a staggered slide-up and fade-in reveal animation.
/// KO: 부드러운 순차 슬라이드 및 페이드인 애니메이션을 제공하는 위젯입니다.
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_animations.dart';

/// EN: Applies a staggered slide-up and fade-in animation to its children.
/// KO: 자식 위젯들에 순차적인 슬라이드 업 및 페이드 인 애니메이션을 적용합니다.
class GBTPageReveal extends StatefulWidget {
  const GBTPageReveal({
    super.key,
    required this.children,
    this.delay = Duration.zero,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// EN: The children to reveal.
  /// KO: 드러낼 자식 위젯들.
  final List<Widget> children;

  /// EN: Initial delay before the animation starts.
  /// KO: 애니메이션 시작 전 초기 지연 시간.
  final Duration delay;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<GBTPageReveal> createState() => _GBTPageRevealState();
}

class _GBTPageRevealState extends State<GBTPageReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // EN: Skip animation when reduced motion is enabled.
    // KO: 모션 감소가 활성화되면 애니메이션을 건너뜁니다.
    if (MediaQuery.of(context).disableAnimations) {
      return Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        children: widget.children,
      );
    }

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: List.generate(widget.children.length, (index) {
        // EN: Stagger the start times by 10% for each child.
        // KO: 각 자식마다 시작 시간을 10%씩 지연시킵니다.
        final double start = (index * 0.1).clamp(0.0, 1.0);
        final double end = (start + 0.4).clamp(0.0, 1.0);

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: GBTAnimations.defaultCurve),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}
