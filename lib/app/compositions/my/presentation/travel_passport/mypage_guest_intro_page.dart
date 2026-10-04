/// EN: Guest-facing My root (PR9 IA): intro copy, a login entry, and a
/// EN: language/theme settings entry — no protected data calls (S1 gate).
/// KO: 비회원용 마이 루트(PR9 IA): 소개 문구, 로그인 진입, 언어/테마 설정
/// KO: 진입만 제공합니다 — 보호 데이터 호출 없음(S1 대기).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';

class MypageGuestIntroPage extends StatelessWidget {
  const MypageGuestIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 64,
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  context.l10n(
                    ko: '로그인하고 나의 여정을 기록해보세요',
                    en: 'Log in to track your own journey',
                    ja: 'ログインしてあなたの記録を始めましょう',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: GBTSpacing.lg),
                FilledButton(
                  key: const Key('mypage-guest-login'),
                  onPressed: () => context.go('/login?redirect=%2Fmypage'),
                  child: Text(
                    context.l10n(ko: '로그인', en: 'Log in', ja: 'ログイン'),
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                TextButton(
                  key: const Key('mypage-guest-settings'),
                  onPressed: () => context.pushNamed(AppRoutes.preferences),
                  child: Text(
                    context.l10n(
                      ko: '언어·테마 설정',
                      en: 'Language & theme',
                      ja: '言語・テーマ設定',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
