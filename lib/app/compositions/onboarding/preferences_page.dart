/// EN: Public preference entry, including direct links without a back stack.
/// KO: 뒤로 갈 화면이 없는 직접 링크도 지원하는 공개 환경설정 진입점입니다.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_host.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LocaleThemeSheet(
        onClose: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/mypage');
          }
        },
      ),
    ),
  );
}
