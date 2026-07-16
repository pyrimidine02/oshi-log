/// EN: Change password page for authenticated users.
/// KO: 로그인 상태 사용자의 비밀번호 변경 페이지.
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

/// EN: Page for changing the current user's password (requires authentication).
/// KO: 현재 사용자의 비밀번호를 변경하는 페이지 (인증 필요).
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
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
          final msg = _buildChangePasswordErrorMessage(context, error);
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
          ko: '비밀번호 변경',
          en: 'Change Password',
          ja: 'パスワード変更',
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
                  eyebrow: 'ACCOUNT SECURITY',
                  title: context.l10n(
                    ko: '여행 기록을 안전하게 보호하세요',
                    en: 'Keep your travel record secure',
                    ja: '旅の記録を安全に守りましょう',
                  ),
                  subtitle: context.l10n(
                    ko: '새 비밀번호는 8자 이상의 복합 문자로 설정해주세요.',
                    en: 'Use at least 8 characters with a secure mix.',
                    ja: '8文字以上の複雑なパスワードを設定してください。',
                  ),
                  icon: Icons.lock_outline,
                ),

                const SizedBox(height: GBTSpacing.xl),

                // EN: Info banner
                // KO: 안내 배너
                Container(
                  padding: const EdgeInsets.all(GBTSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(GBTSpacing.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      Expanded(
                        child: Text(
                          context.l10n(
                            ko: '비밀번호 변경 후 모든 기기에서 자동으로 로그아웃됩니다.',
                            en: 'After changing your password, you will be logged out on all devices.',
                            ja: 'パスワード変更後、全デバイスから自動的にログアウトされます。',
                          ),
                          style: GBTTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: GBTSpacing.xl),

                // EN: Current password field
                // KO: 현재 비밀번호 필드
                GBTTextField(
                  controller: _currentPasswordController,
                  label: context.l10n(
                    ko: '현재 비밀번호',
                    en: 'Current password',
                    ja: '現在のパスワード',
                  ),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureCurrent,
                  suffixIcon: _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.l10n(
                        ko: '현재 비밀번호를 입력해주세요',
                        en: 'Please enter your current password',
                        ja: '現在のパスワードを入力してください',
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

                // EN: Submit button
                // KO: 제출 버튼
                GBTButton(
                  label: context.l10n(
                    ko: '비밀번호 변경',
                    en: 'Change password',
                    ja: 'パスワードを変更する',
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
    // EN: Validate: uppercase, lowercase, digit, special char.
    // KO: 대문자, 소문자, 숫자, 특수문자 포함 여부 검증.
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
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      if (result is Success<void>) {
        // EN: Tokens cleared — go to login.
        // KO: 토큰 삭제 완료 — 로그인 화면으로 이동.
        context.go('/login');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

String _buildChangePasswordErrorMessage(BuildContext context, Object error) {
  if (error is NetworkFailure) {
    return context.l10n(
      ko: '네트워크 연결을 확인한 뒤 다시 시도해주세요.',
      en: 'Check your network connection and try again.',
      ja: 'ネットワーク接続を確認して再試行してください。',
    );
  }
  if (error is AuthFailure && error.code == '401') {
    return context.l10n(
      ko: '현재 비밀번호가 올바르지 않습니다.',
      en: 'Your current password is incorrect.',
      ja: '現在のパスワードが正しくありません。',
    );
  }
  if (error is ServerFailure) {
    return switch (error.code) {
      'PASSWORD_UNCHANGED' => context.l10n(
        ko: '새 비밀번호가 현재 비밀번호와 동일합니다.',
        en: 'New password must be different from your current password.',
        ja: '新しいパスワードは現在のパスワードと異なる必要があります。',
      ),
      'PASSWORD_NOT_SET' => context.l10n(
        ko: '소셜 로그인 계정은 비밀번호 변경을 사용할 수 없습니다.',
        en: 'Password change is not available for social login accounts.',
        ja: 'ソーシャルログインアカウントはパスワード変更を使用できません。',
      ),
      'VALIDATION_FAILED' => context.l10n(
        ko: '비밀번호 규칙을 확인해주세요.',
        en: 'Please check the password requirements.',
        ja: 'パスワードの要件を確認してください。',
      ),
      _ => context.l10n(
        ko: '비밀번호 변경에 실패했습니다. 다시 시도해주세요.',
        en: 'Failed to change password. Please try again.',
        ja: 'パスワードの変更に失敗しました。再試行してください。',
      ),
    };
  }
  return context.l10n(
    ko: '비밀번호 변경에 실패했습니다. 다시 시도해주세요.',
    en: 'Failed to change password. Please try again.',
    ja: 'パスワードの変更に失敗しました。再試行してください。',
  );
}
