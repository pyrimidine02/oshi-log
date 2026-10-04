/// EN: Reusable press animation wrapper with reduced motion support.
/// KO: 모션 감소 지원을 포함한 재사용 가능한 프레스 애니메이션 래퍼.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/gbt_animations.dart';
import '../../theme/gbt_spacing.dart';

/// EN: Wraps a child widget with a consistent press-scale animation.
/// Respects the user's reduced motion accessibility setting.
/// KO: 자식 위젯을 일관된 프레스 스케일 애니메이션으로 래핑합니다.
/// 사용자의 모션 감소 접근성 설정을 존중합니다.
class GBTPressable extends StatefulWidget {
  const GBTPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scaleEnd = GBTAnimations.pressedScale,
    this.useHaptic = true,
    this.hapticType = GBTHapticType.light,
  });

  /// EN: Child widget to wrap.
  /// KO: 래핑할 자식 위젯.
  final Widget child;

  /// EN: Tap callback. When null, press animation is disabled.
  /// KO: 탭 콜백. null이면 프레스 애니메이션이 비활성화됩니다.
  final VoidCallback? onTap;

  /// EN: Whether the pressable is enabled.
  /// KO: 프레서블 활성화 여부.
  final bool enabled;

  /// EN: Target scale when pressed (default: GBTAnimations.pressedScale).
  /// KO: 눌렸을 때 목표 스케일 (기본값: GBTAnimations.pressedScale).
  final double scaleEnd;

  /// EN: Whether to trigger haptic feedback on tap.
  /// KO: 탭 시 햅틱 피드백 트리거 여부.
  final bool useHaptic;

  /// EN: Haptic feedback type.
  /// KO: 햅틱 피드백 유형.
  final GBTHapticType hapticType;

  @override
  State<GBTPressable> createState() => _GBTPressableState();
}

/// EN: Haptic feedback type for press interactions.
/// KO: 프레스 인터랙션을 위한 햅틱 피드백 유형.
enum GBTHapticType { light, selection }

class _GBTPressableState extends State<GBTPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool get _isActive => widget.onTap != null && widget.enabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GBTAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_isActive) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _onTap() {
    _controller.reverse();
    if (widget.useHaptic) {
      switch (widget.hapticType) {
        case GBTHapticType.light:
          HapticFeedback.lightImpact();
        case GBTHapticType.selection:
          HapticFeedback.selectionClick();
      }
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    // EN: Skip animation when reduced motion is enabled.
    // KO: 모션 감소가 활성화되면 애니메이션을 건너뜁니다.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (!_isActive || reduceMotion) {
      return _buildPressTarget(
        GestureDetector(
          onTap: _isActive ? _onTap : null,
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        ),
      );
    }

    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    Widget animatedChild = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    if (isApple) {
      final opacityAnimation = Tween<double>(
        begin: 1.0,
        end: 0.88,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      animatedChild = FadeTransition(
        opacity: opacityAnimation,
        child: animatedChild,
      );
    }

    return _buildPressTarget(
      GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: animatedChild,
      ),
    );
  }

  Widget _buildPressTarget(Widget child) {
    final target = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: GBTSpacing.minTouchTarget,
        minHeight: GBTSpacing.minTouchTarget,
      ),
      child: child,
    );
    if (!_isActive) return target;
    return Semantics(button: true, enabled: true, child: target);
  }
}
