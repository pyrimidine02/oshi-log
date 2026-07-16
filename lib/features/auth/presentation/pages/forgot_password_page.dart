/// EN: Forgot-password page (Step 1 — email input).
/// KO: 비밀번호 분실 페이지 (1단계 — 이메일 입력).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/inputs/gbt_text_field.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import '../widgets/field_auth_components.dart';

/// EN: Page where the user enters their email to request a password-reset link.
/// KO: 비밀번호 재설정 링크를 요청하기 위해 이메일을 입력하는 페이지.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (!mounted) return;
      next.whenOrNull(
        error: (error, _) {
          final msg = _buildErrorMessage(context, error);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    final isLoading =
        ref.watch(authControllerProvider).isLoading || _isSubmitting;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '비밀번호 찾기',
          en: 'Forgot Password',
          ja: 'パスワードを忘れた場合',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GBTSpacing.paddingPage,
          child: _emailSent
              ? _buildSuccessView(context, colorScheme)
              : _buildEmailForm(context, colorScheme, isLoading),
        ),
      ),
    );
  }

  Widget _buildEmailForm(
    BuildContext context,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GBTSpacing.lg),
          FieldAuthHeader(
            eyebrow: 'ACCOUNT RECOVERY',
            title: context.l10n(
              ko: '다시 여정에 접속하세요',
              en: 'Find your way back',
              ja: '旅に戻りましょう',
            ),
            subtitle: context.l10n(
              ko: '가입한 이메일로 비밀번호 재설정 링크를 보내드립니다.',
              en: 'We will send a password reset link to your registered email.',
              ja: '登録メールにパスワード再設定リンクをお送りします。',
            ),
            icon: Icons.mark_email_unread_outlined,
          ),
          const SizedBox(height: GBTSpacing.xl),

          // EN: Email input field
          // KO: 이메일 입력 필드
          GBTTextField(
            controller: _emailController,
            label: context.l10n(ko: '이메일', en: 'Email', ja: 'メールアドレス'),
            hint: context.l10n(
              ko: '이메일을 입력하세요',
              en: 'Enter your email',
              ja: 'メールアドレスを入力してください',
            ),
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return context.l10n(
                  ko: '이메일을 입력해주세요',
                  en: 'Please enter your email',
                  ja: 'メールアドレスを入力してください',
                );
              }
              final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegExp.hasMatch(v.trim())) {
                return context.l10n(
                  ko: '올바른 이메일 형식을 입력해주세요',
                  en: 'Please enter a valid email address',
                  ja: '正しいメールアドレスを入力してください',
                );
              }
              return null;
            },
            onSubmitted: (_) => isLoading ? null : _handleSubmit(),
          ),

          const SizedBox(height: GBTSpacing.xl),

          GBTButton(
            label: context.l10n(
              ko: '재설정 이메일 보내기',
              en: 'Send reset email',
              ja: 'リセットメールを送信',
            ),
            isLoading: isLoading,
            isFullWidth: true,
            onPressed: isLoading ? null : _handleSubmit,
          ),

          const SizedBox(height: GBTSpacing.lg),

          // EN: Link to enter the reset code manually
          // KO: 이미 코드를 받은 경우 입력 화면으로 이동
          Center(
            child: TextButton(
              onPressed: () => context.push('/reset-password'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  GBTSpacing.touchTarget,
                  GBTSpacing.touchTarget,
                ),
              ),
              child: Text(
                context.l10n(
                  ko: '이미 코드를 받으셨나요? 코드 입력',
                  en: 'Already have a code? Enter it here',
                  ja: '既にコードをお持ちですか？コードを入力',
                ),
                style: GBTTypography.labelMedium.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GBTSpacing.xxxl),
        Center(
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: GBTSpacing.xl),
        Text(
          context.l10n(
            ko: '이메일을 확인해주세요',
            en: 'Check your email',
            ja: 'メールを確認してください',
          ),
          style: GBTTypography.headlineMedium.copyWith(
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          context.l10n(
            ko: '${_emailController.text.trim()}으로\n비밀번호 재설정 링크를 보냈습니다.\n(링크는 60분 후 만료됩니다)',
            en: 'A password reset link has been sent to\n${_emailController.text.trim()}.\n(The link expires in 60 minutes)',
            ja: '${_emailController.text.trim()}に\nパスワードリセットリンクを送信しました。\n(リンクは60分後に失効します)',
          ),
          style: GBTTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: GBTSpacing.xxxl),
        GBTButton(
          label: context.l10n(ko: '코드 입력하기', en: 'Enter code', ja: 'コードを入力する'),
          isFullWidth: true,
          onPressed: () => context.push('/reset-password'),
        ),
        const SizedBox(height: GBTSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _emailSent = false;
              _emailController.clear();
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(
                GBTSpacing.touchTarget,
                GBTSpacing.touchTarget,
              ),
            ),
            child: Text(
              context.l10n(
                ko: '다른 이메일로 재시도',
                en: 'Try a different email',
                ja: '別のメールアドレスで再試行',
              ),
              style: GBTTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(email: _emailController.text.trim());
      if (!mounted) return;
      if (result is Success<void>) {
        // EN: Always show success (server returns 200 even for unknown emails).
        // KO: 항상 성공 화면 표시 (서버는 미등록 이메일도 200 반환).
        setState(() => _emailSent = true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

String _buildErrorMessage(BuildContext context, Object error) {
  if (error is NetworkFailure) {
    return context.l10n(
      ko: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
      en: 'Check your network connection and try again.',
      ja: 'ネットワーク接続を確認して再試行してください。',
    );
  }
  if (error is ServerFailure && error.code == '429') {
    return context.l10n(
      ko: '재전송 쿨다운 중입니다. 잠시 후 다시 시도해주세요.',
      en: 'Please wait before requesting another email.',
      ja: '再送信のクールダウン中です。しばらくしてから再試行してください。',
    );
  }
  return context.l10n(
    ko: '요청에 실패했습니다. 다시 시도해주세요.',
    en: 'Request failed. Please try again.',
    ja: 'リクエストに失敗しました。再試行してください。',
  );
}
