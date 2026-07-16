/// EN: Email verified success page shown when the user taps the verification deeplink.
/// KO: 사용자가 인증 딥링크를 탭했을 때 표시되는 이메일 인증 완료 페이지.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../widgets/field_auth_components.dart';

/// EN: Success screen displayed after email verification is completed via deeplink.
/// KO: 딥링크를 통해 이메일 인증이 완료된 후 표시되는 성공 화면.
class EmailVerifiedPage extends StatelessWidget {
  const EmailVerifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: GBTSpacing.paddingPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FieldAuthHeader(
                eyebrow: 'ACCOUNT VERIFIED',
                title: context.l10n(
                  ko: '이메일 인증이 완료되었습니다',
                  en: 'Email verified!',
                  ja: 'メール認証が完了しました',
                ),
                subtitle: context.l10n(
                  ko: '이제 로그인하여 여정을 시작할 수 있어요.',
                  en: 'You can now sign in and begin your journey.',
                  ja: 'ログインして旅を始められます。',
                ),
                icon: Icons.mark_email_read_outlined,
                centered: true,
              ),
              const SizedBox(height: GBTSpacing.xl2),

              // EN: Go to login button
              // KO: 로그인 버튼
              GBTButton(
                label: context.l10n(
                  ko: '로그인하러 가기',
                  en: 'Go to login',
                  ja: 'ログインへ',
                ),
                isFullWidth: true,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
