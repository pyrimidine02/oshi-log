/// EN: Reset password page (Step 2 — token + new password).
/// KO: 비밀번호 재설정 페이지 (2단계 — 토큰 + 새 비밀번호).
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

/// EN: Page where the user enters the reset token and new password.
///     The token may be pre-filled from a deep link.
/// KO: 재설정 토큰과 새 비밀번호를 입력하는 페이지.
///     딥링크에서 토큰이 자동으로 채워질 수 있습니다.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.initialToken});

  /// EN: Optional initial token from a deep link.
  /// KO: 딥링크에서 전달된 선택적 초기 토큰.
  final String? initialToken;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          ko: '새 비밀번호 설정',
          en: 'Set New Password',
          ja: '新しいパスワードを設定',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GBTSpacing.paddingPage,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: GBTSpacing.lg),
                FieldAuthHeader(
                  eyebrow: 'ACCOUNT RECOVERY',
                  title: context.l10n(
                    ko: '새 접근 키를 만드세요',
                    en: 'Create a new access key',
                    ja: '新しいアクセスキーを作成',
                  ),
                  subtitle: context.l10n(
                    ko: '이메일로 받은 코드와 새 비밀번호를 입력해주세요.',
                    en: 'Enter the code from your email and your new password.',
                    ja: 'メールで受け取ったコードと新しいパスワードを入力してください。',
                  ),
                  icon: Icons.key_outlined,
                ),
                const SizedBox(height: GBTSpacing.xl),

                // EN: Token field (may be pre-filled from deep link).
                // KO: 토큰 필드 (딥링크에서 자동 입력될 수 있음).
                GBTTextField(
                  controller: _tokenController,
                  label: context.l10n(
                    ko: '인증 코드',
                    en: 'Verification code',
                    ja: '認証コード',
                  ),
                  hint: context.l10n(
                    ko: '이메일로 받은 코드를 입력하세요',
                    en: 'Enter the code from your email',
                    ja: 'メールで受け取ったコードを入力してください',
                  ),
                  prefixIcon: Icons.vpn_key_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return context.l10n(
                        ko: '인증 코드를 입력해주세요',
                        en: 'Please enter the verification code',
                        ja: '認証コードを入力してください',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: GBTSpacing.md),

                // EN: New password field
                // KO: 새 비밀번호 필드
                GBTTextField(
                  controller: _newPasswordController,
                  label: context.l10n(
                    ko: '새 비밀번호',
                    en: 'New password',
                    ja: '新しいパスワード',
                  ),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureNew,
                  suffixIcon: _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () => setState(() => _obscureNew = !_obscureNew),
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                ),

                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '8~128자, 대문자·소문자·숫자·특수문자(@\$!%*?&) 각 1개 이상',
                    en: '8–128 chars with uppercase, lowercase, number, and special char (@\$!%*?&)',
                    ja: '8〜128文字・大文字・小文字・数字・特殊文字(@\$!%*?&)を各1つ以上',
                  ),
                  style: GBTTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: GBTSpacing.md),

                // EN: Confirm new password field
                // KO: 새 비밀번호 확인 필드
                GBTTextField(
                  controller: _confirmPasswordController,
                  label: context.l10n(
                    ko: '새 비밀번호 확인',
                    en: 'Confirm new password',
                    ja: '新しいパスワードを再入力',
                  ),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureConfirm,
                  suffixIcon: _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.l10n(
                        ko: '비밀번호 확인을 입력해주세요',
                        en: 'Please confirm your new password',
                        ja: '新しいパスワードを再入力してください',
                      );
                    }
                    if (v != _newPasswordController.text) {
                      return context.l10n(
                        ko: '비밀번호가 일치하지 않습니다',
                        en: 'Passwords do not match',
                        ja: 'パスワードが一致しません',
                      );
                    }
                    return null;
                  },
                  onSubmitted: (_) => isLoading ? null : _handleSubmit(),
                ),

                const SizedBox(height: GBTSpacing.xl),

                GBTButton(
                  label: context.l10n(
                    ko: '비밀번호 재설정',
                    en: 'Reset password',
                    ja: 'パスワードをリセット',
                  ),
                  isLoading: isLoading,
                  isFullWidth: true,
                  onPressed: isLoading ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) {
      return context.l10n(
        ko: '새 비밀번호를 입력해주세요',
        en: 'Please enter a new password',
        ja: '新しいパスワードを入力してください',
      );
    }
    if (v.length < 8 || v.length > 128) {
      return context.l10n(
        ko: '8~128자로 입력해주세요',
        en: 'Must be 8–128 characters',
        ja: '8〜128文字で入力してください',
      );
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasDigit = RegExp(r'[0-9]').hasMatch(v);
    final hasSpecial = RegExp(r'[@$!%*?&]').hasMatch(v);
    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
      return context.l10n(
        ko: '대문자·소문자·숫자·특수문자(@\$!%*?&)를 각 1개 이상 포함해야 합니다',
        en: 'Must include uppercase, lowercase, number, and special char (@\$!%*?&)',
        ja: '大文字・小文字・数字・特殊文字(@\$!%*?&)を各1つ以上含めてください',
      );
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .confirmPasswordReset(
            token: _tokenController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      if (result is Success<void>) {
        // EN: All sessions revoked — navigate to login with success message.
        // KO: 모든 세션 만료 — 성공 메시지와 함께 로그인 화면으로 이동.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '비밀번호가 재설정되었습니다. 새 비밀번호로 로그인해주세요.',
                en: 'Password has been reset. Please log in with your new password.',
                ja: 'パスワードがリセットされました。新しいパスワードでログインしてください。',
              ),
            ),
          ),
        );
        context.go('/login');
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
  if (error is ServerFailure) {
    return switch (error.code) {
      'EMAIL_VERIFICATION_INVALID' => context.l10n(
        ko: '유효하지 않은 코드입니다. 코드를 확인해주세요.',
        en: 'Invalid code. Please check your code.',
        ja: '無効なコードです。コードを確認してください。',
      ),
      'EMAIL_VERIFICATION_EXPIRED' => context.l10n(
        ko: '코드가 만료되었습니다. 비밀번호 재설정을 다시 요청해주세요.',
        en: 'Code has expired. Please request a new reset link.',
        ja: 'コードが失効しました。パスワードリセットを再リクエストしてください。',
      ),
      'EMAIL_VERIFICATION_ALREADY_USED' => context.l10n(
        ko: '이미 사용된 코드입니다. 새 코드를 요청해주세요.',
        en: 'Code has already been used. Please request a new one.',
        ja: '既に使用されたコードです。新しいコードをリクエストしてください。',
      ),
      'EMAIL_VERIFICATION_MAX_ATTEMPTS' => context.l10n(
        ko: '시도 횟수를 초과했습니다. 새 코드를 요청해주세요.',
        en: 'Too many attempts. Please request a new code.',
        ja: '試行回数を超えました。新しいコードをリクエストしてください。',
      ),
      'EMAIL_VERIFICATION_INVALID_TYPE' => context.l10n(
        ko: '잘못된 코드 유형입니다. 비밀번호 재설정 이메일의 코드를 사용해주세요.',
        en: 'Invalid code type. Please use the code from the password reset email.',
        ja: '無効なコードの種類です。パスワードリセットメールのコードをご使用ください。',
      ),
      'PASSWORD_UNCHANGED' => context.l10n(
        ko: '새 비밀번호가 현재 비밀번호와 동일합니다.',
        en: 'New password must be different from the current password.',
        ja: '新しいパスワードは現在のパスワードと異なる必要があります。',
      ),
      'VALIDATION_FAILED' => context.l10n(
        ko: '비밀번호 규칙을 확인해주세요.',
        en: 'Please check the password requirements.',
        ja: 'パスワードの要件を確認してください。',
      ),
      _ => context.l10n(
        ko: '비밀번호 재설정에 실패했습니다. 다시 시도해주세요.',
        en: 'Failed to reset password. Please try again.',
        ja: 'パスワードのリセットに失敗しました。再試行してください。',
      ),
    };
  }
  if (error is ServerFailure && error.code == '429') {
    return context.l10n(
      ko: '시도 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.',
      en: 'Too many attempts. Please try again later.',
      ja: '試行回数を超えました。しばらくしてから再試行してください。',
    );
  }
  return context.l10n(
    ko: '비밀번호 재설정에 실패했습니다. 다시 시도해주세요.',
    en: 'Failed to reset password. Please try again.',
    ja: 'パスワードのリセットに失敗しました。再試行してください。',
  );
}
