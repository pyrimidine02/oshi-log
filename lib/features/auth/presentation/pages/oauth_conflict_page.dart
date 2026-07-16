/// EN: Page shown when an OAuth login results in EMAIL_ACCOUNT_CONFLICT (409).
///     The user enters their existing account password to link the OAuth provider.
/// KO: OAuth 로그인 시 EMAIL_ACCOUNT_CONFLICT(409)가 발생한 경우 표시하는 페이지.
///     사용자가 기존 계정 비밀번호를 입력하여 OAuth 제공자를 연동합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/inputs/gbt_text_field.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import '../widgets/field_auth_components.dart';

/// EN: Displays conflict resolution UI for OAuth email-account conflicts.
/// KO: OAuth 이메일 계정 충돌 해결 UI를 표시합니다.
class OAuthConflictPage extends ConsumerStatefulWidget {
  const OAuthConflictPage({super.key, required this.conflictEmail});

  /// EN: Email of the conflicting account, pre-filled from error details.
  /// KO: 충돌 계정의 이메일, 에러 details에서 미리 채워집니다.
  final String conflictEmail;

  @override
  ConsumerState<OAuthConflictPage> createState() => _OAuthConflictPageState();
}

class _OAuthConflictPageState extends ConsumerState<OAuthConflictPage> {
  final _formKey = GlobalKey<FormState>();
  // EN: Read-only email controller pre-filled with the conflicting account email.
  // KO: 충돌 계정 이메일로 미리 채워진 읽기 전용 이메일 컨트롤러.
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.conflictEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .linkExistingOAuth(password: _passwordController.text.trim());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<void>) {
      context.go('/home');
      return;
    }

    if (result is Err<void>) {
      final failure = result.failure;
      final message = _buildErrorMessage(context, failure);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _buildErrorMessage(BuildContext context, Failure failure) {
    return switch (failure.code) {
      '401' => context.l10n(
        ko: '비밀번호가 올바르지 않습니다',
        en: 'Incorrect password',
        ja: 'パスワードが正しくありません',
      ),
      'OAUTH_ALREADY_LINKED' => context.l10n(
        ko: '이 소셜 계정은 이미 다른 계정에 연결되어 있습니다',
        en: 'This social account is already linked to another account',
        ja: 'このソーシャルアカウントは既に別のアカウントに連携されています',
      ),
      'ACCOUNT_ALREADY_HAS_OAUTH' => context.l10n(
        ko: '해당 계정에는 이미 다른 소셜 계정이 연결되어 있습니다',
        en: 'The account already has another social account linked',
        ja: 'そのアカウントには既に別のソーシャルアカウントが連携されています',
      ),
      'EMAIL_VERIFICATION_REQUIRED' => context.l10n(
        ko: '이메일 인증이 완료되지 않은 계정입니다',
        en: 'Email verification is required for this account',
        ja: 'このアカウントはメール認証が完了していません',
      ),
      '429' => context.l10n(
        ko: '비밀번호를 너무 많이 틀렸습니다. 잠시 후 다시 시도해주세요',
        en: 'Too many attempts. Please try again later',
        ja: '試行回数が多すぎます。しばらくしてからお試しください',
      ),
      _ => failure.userMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _isSubmitting;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '계정 연동', en: 'Link Account', ja: 'アカウント連携'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GBTSpacing.paddingPage,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: GBTSpacing.xl),
                FieldAuthHeader(
                  eyebrow: 'ACCOUNT CONNECTION',
                  title: context.l10n(
                    ko: '이미 가입된 계정이 있어요',
                    en: 'An account already exists',
                    ja: '既にアカウントが存在します',
                  ),
                  subtitle: context.l10n(
                    ko: '${widget.conflictEmail} 계정을 확인하면 소셜 계정과 연동됩니다.',
                    en: 'Verify ${widget.conflictEmail} to link the social account.',
                    ja: '${widget.conflictEmail}を確認してソーシャルアカウントと連携します。',
                  ),
                  icon: Icons.link_rounded,
                  centered: true,
                ),
                const SizedBox(height: GBTSpacing.xxxl),
                // EN: Read-only email field pre-filled with the conflicting account email.
                // KO: 충돌 계정 이메일이 미리 채워진 읽기 전용 이메일 필드.
                GBTTextField(
                  controller: _emailController,
                  label: context.l10n(ko: '이메일', en: 'Email', ja: 'メールアドレス'),
                  enabled: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: GBTSpacing.md),
                // EN: Password field with visibility toggle via suffixIcon + onSuffixTap.
                // KO: suffixIcon + onSuffixTap으로 가시성 토글이 있는 비밀번호 필드.
                GBTTextField(
                  controller: _passwordController,
                  label: context.l10n(ko: '비밀번호', en: 'Password', ja: 'パスワード'),
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmitted: (_) => isLoading ? null : _handleSubmit(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n(
                        ko: '비밀번호를 입력해주세요',
                        en: 'Please enter your password',
                        ja: 'パスワードを入力してください',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: GBTSpacing.xl),
                GBTButton(
                  label: context.l10n(
                    ko: '계정 연동하기',
                    en: 'Link Account',
                    ja: 'アカウントを連携する',
                  ),
                  isFullWidth: true,
                  onPressed: isLoading ? null : _handleSubmit,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
