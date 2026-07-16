/// EN: Shared recovery view for invalid or missing routes.
/// KO: 잘못되었거나 찾을 수 없는 경로를 위한 공통 복구 화면입니다.
library;

import 'package:flutter/material.dart';

import 'gbt_empty_state.dart';

/// EN: Presents route failures with the same empty-state language used by the
/// rest of the application and remains scrollable under large text settings.
/// KO: 앱의 다른 빈 상태와 동일한 표현으로 경로 오류를 안내하며 큰 글자
/// 설정에서도 스크롤할 수 있도록 구성합니다.
class GBTNavigationErrorView extends StatelessWidget {
  const GBTNavigationErrorView({
    super.key,
    required this.message,
    this.details,
    this.recoveryLabel = '홈으로 돌아가기',
    this.onRecover,
  });

  final String message;
  final String? details;
  final String recoveryLabel;
  final VoidCallback? onRecover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: GBTEmptyState(
              icon: Icons.explore_off_outlined,
              title: message,
              subtitle: details,
              actionLabel: onRecover == null ? null : recoveryLabel,
              onAction: onRecover,
            ),
          ),
        );
      },
    );
  }
}
