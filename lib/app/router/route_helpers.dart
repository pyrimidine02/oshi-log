/// EN: Shared, feature-free helpers used by the domain route files.
/// KO: 도메인 라우트 파일들이 공유하는, 피처 의존 없는 헬퍼입니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/gbt_animations.dart';
import '../../core/widgets/feedback/gbt_navigation_error_view.dart';
import '../../core/widgets/navigation/gbt_standard_app_bar.dart';

Page<void> buildAdaptiveDetailPage({
  required LocalKey key,
  required Widget child,
}) {
  // EN: Delegate to MaterialPage to universally respect the theme's PageTransitionsTheme.
  // KO: 테마의 PageTransitionsTheme을 전역적으로 존중하기 위해 MaterialPage에 위임합니다.
  return MaterialPage<void>(key: key, child: child);
}

Page<void> buildAdaptiveOverlayPage({
  required LocalKey key,
  required Widget child,
}) {
  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return MaterialPage<void>(key: key, child: child);
  }
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: GBTPageTransitions.sharedAxisY(),
    transitionDuration: GBTAnimations.normal,
  );
}

class InvalidNavigationPage extends StatelessWidget {
  const InvalidNavigationPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gbtStandardAppBar(context, title: '여정을 열 수 없어요'),
      body: GBTNavigationErrorView(
        message: '요청한 페이지를 열 수 없어요',
        details: message,
      ),
    );
  }
}
