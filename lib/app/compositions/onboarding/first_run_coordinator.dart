/// EN: Offers optional preferences once, after the home navigator is ready.
/// KO: 홈 내비게이터가 준비된 뒤 선택형 초기 설정을 한 번 표시합니다.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_host.dart';

class FirstRunCoordinator extends ConsumerStatefulWidget {
  const FirstRunCoordinator({
    super.key,
    required this.router,
    required this.child,
  });
  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<FirstRunCoordinator> createState() =>
      _FirstRunCoordinatorState();
}

class _FirstRunCoordinatorState extends ConsumerState<FirstRunCoordinator> {
  bool _offered = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_schedule);
  }

  @override
  void didUpdateWidget(FirstRunCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_schedule);
      widget.router.routerDelegate.addListener(_schedule);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_offered || _scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          _offered ||
          widget.router.state.uri.path != '/home' ||
          ref.read(firstRunCompletedProvider).valueOrNull != false) {
        return;
      }
      final navigator = widget.router.routerDelegate.navigatorKey.currentState;
      if (navigator == null || navigator.canPop()) return;
      _offered = true;
      unawaited(showFirstRunPreferencesSheet(navigator.context));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(firstRunCompletedProvider).valueOrNull == false) {
      _schedule();
    }
    return widget.child;
  }
}
