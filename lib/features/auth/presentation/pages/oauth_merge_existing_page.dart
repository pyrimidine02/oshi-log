/// EN: Page shown after a successful OAuth login (200 — new account created),
///     asking the user if they have an existing account to merge with.
///     Supports merging via email+password or via native Google/Apple SDK.
/// KO: OAuth 로그인 성공(200 — 신규 계정 생성) 후 표시하는 페이지.
///     기존 계정과 합칠지 사용자에게 묻습니다.
///     이메일+비밀번호 또는 네이티브 Google/Apple SDK로 합치기를 지원합니다.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/inputs/gbt_text_field.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import '../widgets/field_auth_components.dart';

/// EN: Prompts the user to merge a new OAuth account with an existing account.
///     Supports email+password accounts and social login accounts (Google, Apple).
/// KO: 신규 OAuth 계정을 기존 계정과 합치도록 사용자에게 안내합니다.
///     이메일+비밀번호 계정과 소셜 로그인 계정(Google, Apple)을 지원합니다.
class OAuthMergeExistingPage extends ConsumerStatefulWidget {
  const OAuthMergeExistingPage({super.key});

  @override
  ConsumerState<OAuthMergeExistingPage> createState() =>
      _OAuthMergeExistingPageState();
}

// EN: Which sub-screen is currently shown.
// KO: 현재 표시 중인 하위 화면.
enum _MergeView {
  // EN: Initial choice — "Yes / No"
  // KO: 초기 선택 화면 — "있다 / 없다"
  choice,
  // EN: Choose merge method — email+password or social login
  // KO: 합치기 방법 선택 — 이메일+비밀번호 또는 소셜 로그인
  methodChoice,
  // EN: Email + password form
  // KO: 이메일+비밀번호 폼
  emailForm,
}

class _OAuthMergeExistingPageState
    extends ConsumerState<OAuthMergeExistingPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  _MergeView _view = _MergeView.choice;

  // EN: Per-button loading flags for social merge buttons.
  // KO: 소셜 합치기 버튼별 로딩 플래그.
  bool _googleLoading = false;
  bool _appleLoading = false;

  bool get _anySocialLoading => _googleLoading || _appleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // EN: Email + password merge
  // KO: 이메일+비밀번호 합치기
  // ──────────────────────────────────────────────

  Future<void> _handleEmailMerge() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .connectExisting(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result is Success<void>) {
      context.go('/home');
      return;
    }

    if (result is Err<void>) {
      _showError(context, result.failure);
    }
  }

  // ──────────────────────────────────────────────
  // EN: Social merge helpers
  // KO: 소셜 합치기 헬퍼
  // ──────────────────────────────────────────────

  Future<void> _handleGoogleMerge() async {
    if (_anySocialLoading || _isSubmitting) return;
    setState(() => _googleLoading = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .connectExistingWithGoogle();
      if (!mounted) return;
      _handleSocialMergeResult(result);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleAppleMerge() async {
    if (_anySocialLoading || _isSubmitting) return;
    setState(() => _appleLoading = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .connectExistingWithApple();
      if (!mounted) return;
      _handleSocialMergeResult(result);
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _handleSocialMergeResult(Result<void> result) {
    if (result is Success<void>) {
      context.go('/home');
      return;
    }
    if (result is Err<void>) {
      final failure = result.failure;
      // EN: Silently ignore user-initiated cancellation.
      // KO: 사용자가 직접 취소한 경우 조용히 무시합니다.
      if (failure is AuthFailure && failure.code == 'sign_in_cancelled') return;
      _showError(context, failure);
    }
  }

  void _showError(BuildContext context, Failure failure) {
    final message = _buildErrorMessage(context, failure);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildErrorMessage(BuildContext context, Failure failure) {
    return switch (failure.code) {
      '401' => context.l10n(
        ko: '이메일 또는 비밀번호가 올바르지 않습니다',
        en: 'Incorrect email or password',
        ja: 'メールアドレスまたはパスワードが正しくありません',
      ),
      'ACCOUNT_NOT_FOUND' => context.l10n(
        ko: '해당 소셜 계정으로 가입된 계정을 찾을 수 없습니다',
        en: 'No account found for this social login',
        ja: 'このソーシャルログインに対応するアカウントが見つかりません',
      ),
      'ACCOUNT_ALREADY_HAS_OAUTH' => context.l10n(
        ko: '해당 계정에는 이미 다른 소셜 계정이 연결되어 있습니다',
        en: 'The account already has another social account linked',
        ja: 'そのアカウントには既に別のソーシャルアカウントが連携されています',
      ),
      '429' => context.l10n(
        ko: '너무 많이 시도했습니다. 잠시 후 다시 시도해주세요',
        en: 'Too many attempts. Please try again later',
        ja: '試行回数が多すぎます。しばらくしてからお試しください',
      ),
      _ => failure.userMessage,
    };
  }

  // ──────────────────────────────────────────────
  // EN: Build
  // KO: 빌드
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final isControllerLoading = authState.isLoading;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        automaticallyImplyLeading: false,
        // EN: Show back arrow only when deeper than the initial choice screen.
        // KO: 초기 선택 화면보다 깊은 단계일 때만 뒤로가기 화살표 표시.
        leading: _view != _MergeView.choice
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: context.l10n(ko: '뒤로', en: 'Back', ja: '戻る'),
                onPressed: () => setState(
                  () => _view = _view == _MergeView.emailForm
                      ? _MergeView.methodChoice
                      : _MergeView.choice,
                ),
              )
            : null,
        title: context.l10n(ko: '로그인 완료', en: 'Login Complete', ja: 'ログイン完了'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GBTSpacing.paddingPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: GBTSpacing.xl),
              // EN: Title and subtitle change per view.
              // KO: 제목과 부제목은 뷰에 따라 달라집니다.
              _buildHeader(context),
              const SizedBox(height: GBTSpacing.xxxl),
              // EN: Body content depends on the current sub-screen.
              // KO: 본문 내용은 현재 하위 화면에 따라 달라집니다.
              _buildBody(context, colorScheme, isControllerLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final (title, subtitle) = switch (_view) {
      _MergeView.choice => (
        context.l10n(
          ko: '혹시 이전에 가입하신\n계정이 있으신가요?',
          en: 'Do you have\nan existing account?',
          ja: '以前に登録した\nアカウントはありますか？',
        ),
        context.l10n(
          ko: '기존 계정과 합치면 이전 활동 내역을 유지할 수 있어요.',
          en: 'Merging with your existing account preserves your previous activity.',
          ja: '既存のアカウントと統合すると、以前の活動履歴を保持できます。',
        ),
      ),
      _MergeView.methodChoice => (
        context.l10n(
          ko: '어떤 방법으로 확인할까요?',
          en: 'How would you like to verify?',
          ja: 'どの方法で確認しますか？',
        ),
        context.l10n(
          ko: '기존 계정으로 로그인해서 소유권을 확인합니다.',
          en: 'Sign in to your existing account to prove ownership.',
          ja: '既存のアカウントにログインして所有権を確認します。',
        ),
      ),
      _MergeView.emailForm => (
        context.l10n(
          ko: '기존 계정 정보를 입력해주세요',
          en: 'Enter your existing account details',
          ja: '既存アカウントの情報を入力してください',
        ),
        context.l10n(
          ko: '입력하신 계정과 현재 계정이 하나로 합쳐집니다.',
          en: 'Your existing account and current account will be merged.',
          ja: '入力したアカウントと現在のアカウントが1つに統合されます。',
        ),
      ),
    };

    return FieldAuthHeader(
      eyebrow: 'ACCOUNT CONTINUITY',
      title: title,
      subtitle: subtitle,
      icon: switch (_view) {
        _MergeView.choice => Icons.route_outlined,
        _MergeView.methodChoice => Icons.verified_user_outlined,
        _MergeView.emailForm => Icons.merge_type_rounded,
      },
      centered: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    bool isControllerLoading,
  ) {
    return switch (_view) {
      _MergeView.choice => _buildChoiceView(context),
      _MergeView.methodChoice => _buildMethodChoiceView(
        context,
        colorScheme,
        isControllerLoading,
      ),
      _MergeView.emailForm => _buildEmailFormView(context, isControllerLoading),
    };
  }

  // EN: "Do you have an existing account?" — Yes / No.
  // KO: "기존 계정이 있나요?" — 예 / 아니오.
  Widget _buildChoiceView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GBTButton(
          label: context.l10n(
            ko: '네, 기존 계정이 있어요',
            en: 'Yes, I have an existing account',
            ja: 'はい、既存のアカウントがあります',
          ),
          isFullWidth: true,
          onPressed: () => setState(() => _view = _MergeView.methodChoice),
        ),
        const SizedBox(height: GBTSpacing.md),
        GBTButton(
          label: context.l10n(
            ko: '아니요, 새 계정으로 시작할게요',
            en: 'No, start with new account',
            ja: 'いいえ、新しいアカウントで始めます',
          ),
          variant: GBTButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }

  // EN: Choose merge method: social buttons OR email+password.
  // KO: 합치기 방법 선택: 소셜 버튼 또는 이메일+비밀번호.
  Widget _buildMethodChoiceView(
    BuildContext context,
    ColorScheme colorScheme,
    bool isControllerLoading,
  ) {
    final isIos = Platform.isIOS;
    final disabled = _anySocialLoading || isControllerLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // EN: Social login options for proving ownership of an existing social account.
        // KO: 기존 소셜 계정 소유권 인증을 위한 소셜 로그인 옵션.
        _SocialMergeButton(
          label: context.l10n(
            ko: 'Google 계정으로 확인',
            en: 'Verify with Google',
            ja: 'Googleアカウントで確認',
          ),
          icon: _GoogleMiniLogo(color: colorScheme.onSurface),
          isLoading: _googleLoading,
          onPressed: disabled ? null : _handleGoogleMerge,
          colorScheme: colorScheme,
        ),
        if (isIos) ...[
          const SizedBox(height: GBTSpacing.sm),
          _SocialMergeButton(
            label: context.l10n(
              ko: 'Apple 계정으로 확인',
              en: 'Verify with Apple',
              ja: 'Appleアカウントで確認',
            ),
            icon: Icon(Icons.apple, size: 20, color: colorScheme.onSurface),
            isLoading: _appleLoading,
            onPressed: disabled ? null : _handleAppleMerge,
            colorScheme: colorScheme,
          ),
        ],
        const SizedBox(height: GBTSpacing.lg),
        // EN: Divider between social and email options.
        // KO: 소셜과 이메일 옵션 사이의 구분선.
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
              child: Text(
                context.l10n(ko: '또는', en: 'or', ja: 'または'),
                style: GBTTypography.labelMedium.copyWith(
                  color: GBTColors.textTertiary,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: GBTSpacing.lg),
        GBTButton(
          label: context.l10n(
            ko: '이메일로 확인',
            en: 'Verify with email',
            ja: 'メールで確認',
          ),
          variant: GBTButtonVariant.secondary,
          isFullWidth: true,
          onPressed: disabled
              ? null
              : () => setState(() => _view = _MergeView.emailForm),
        ),
      ],
    );
  }

  // EN: Email + password form.
  // KO: 이메일+비밀번호 폼.
  Widget _buildEmailFormView(BuildContext context, bool isControllerLoading) {
    final isLoading = isControllerLoading || _isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GBTTextField(
            controller: _emailController,
            label: context.l10n(
              ko: '기존 계정 이메일',
              en: 'Existing Account Email',
              ja: '既存アカウントのメールアドレス',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n(
                  ko: '이메일을 입력해주세요',
                  en: 'Please enter your email',
                  ja: 'メールアドレスを入力してください',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: GBTSpacing.md),
          // EN: Password field with visibility toggle.
          // KO: 가시성 토글이 있는 비밀번호 필드.
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
            onSubmitted: (_) => isLoading ? null : _handleEmailMerge(),
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
              ko: '계정 합치기',
              en: 'Merge Accounts',
              ja: 'アカウントを統合する',
            ),
            isFullWidth: true,
            onPressed: isLoading ? null : _handleEmailMerge,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// EN: Reusable social merge verification button.
// KO: 재사용 가능한 소셜 합치기 인증 버튼.
// ──────────────────────────────────────────────────────────

/// EN: A bordered button used on the merge page to verify ownership via a social login.
/// KO: 머지 페이지에서 소셜 로그인으로 소유권을 인증하는 테두리 버튼.
class _SocialMergeButton extends StatelessWidget {
  const _SocialMergeButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    required this.colorScheme,
  });

  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final borderColor = colorScheme.outlineVariant;
    final textColor = colorScheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
          child: Container(
            height: GBTSpacing.xxl,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: GBTTypography.labelLarge.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
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

// ──────────────────────────────────────────────────────────
// EN: Minimal Google "G" icon for use in the merge button.
// KO: 머지 버튼용 최소 Google "G" 아이콘.
// ──────────────────────────────────────────────────────────

class _GoogleMiniLogo extends StatelessWidget {
  const _GoogleMiniLogo({required this.color});

  // EN: Tint color (unused — Google G is always multicolor per brand guidelines).
  // KO: 틴트 색상 (미사용 — Google G는 브랜드 가이드라인상 항상 멀티컬러).
  // ignore: unused_field
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: const _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.18;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(center: center, radius: radius * 0.72);
    // EN: Four-color arcs of the Google "G".
    // KO: Google "G"의 4색 아크.
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, _rad(-45), _rad(90), false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, _rad(45), _rad(90), false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, _rad(135), _rad(90), false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, _rad(225), _rad(90), false, paint);
    // EN: Horizontal bar of the "G".
    // KO: "G"의 가로 바.
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        radius * 0.72,
        strokeWidth,
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  double _rad(double deg) => deg * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}
