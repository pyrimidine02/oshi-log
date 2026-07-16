/// EN: Email verification pending page shown after registration.
/// KO: 회원가입 후 이메일 인증 대기 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import 'email_verification_args.dart';

/// EN: Email verification pending page.
///     Shows a message prompting the user to check their inbox.
///     Also provides a manual code entry section for cases where the
///     deep-link cannot be opened (e.g. desktop email clients).
/// KO: 이메일 인증 대기 페이지.
///     사용자에게 받은 편지함을 확인하도록 안내하는 메시지를 표시합니다.
///     딥링크를 열 수 없는 경우(예: 데스크톱 이메일 클라이언트)를 위한
///     수동 코드 입력 섹션도 제공합니다.
class EmailVerificationPendingPage extends ConsumerStatefulWidget {
  const EmailVerificationPendingPage({super.key, required this.args});

  /// EN: Navigation arguments containing the email and optional expiry time.
  /// KO: 이메일과 선택적 만료 시간을 포함하는 네비게이션 인자.
  final EmailVerificationArgs args;

  @override
  ConsumerState<EmailVerificationPendingPage> createState() =>
      _EmailVerificationPendingPageState();
}

class _EmailVerificationPendingPageState
    extends ConsumerState<EmailVerificationPendingPage> {
  // EN: Seconds remaining before resend is allowed.
  // KO: 재발송 가능까지 남은 초.
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  bool _isSending = false;

  // EN: Manual code entry state.
  // KO: 수동 코드 입력 상태.
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isVerifying = false;
  String? _codeError;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _startCooldownUntil(DateTime? resendAvailableAt) {
    _cooldownTimer?.cancel();
    final now = DateTime.now();
    if (resendAvailableAt == null || !resendAvailableAt.isAfter(now)) {
      setState(() => _cooldownRemaining = 0);
      return;
    }
    final secondsLeft = resendAvailableAt
        .difference(now)
        .inSeconds
        .clamp(0, 3600);
    setState(() => _cooldownRemaining = secondsLeft);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownRemaining > 0 || _isSending) return;
    setState(() => _isSending = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendEmailVerification(email: widget.args.email);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (result is Success<DateTime?>) {
      _startCooldownUntil(result.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '인증 메일을 재발송했습니다. 새 코드를 붙여넣어 주세요.',
              en: 'Verification email resent. Please paste the new code.',
              ja: '認証メールを再送しました。新しいコードを貼り付けてください。',
            ),
          ),
        ),
      );
    } else if (result is Err<DateTime?>) {
      final failure = result.failure;
      final message = failure.code == '429'
          ? context.l10n(
              ko: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
              en: 'Too many requests. Please try again later.',
              ja: 'リクエストが多すぎます。しばらく経ってから再試行してください。',
            )
          : context.l10n(
              ko: '재발송에 실패했습니다. 잠시 후 다시 시도해주세요.',
              en: 'Resend failed. Please try again later.',
              ja: '再送に失敗しました。しばらく経ってから再試行してください。',
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// EN: Paste clipboard content into the code input field.
  /// KO: 클립보드 내용을 코드 입력 필드에 붙여넣습니다.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text ?? '';
    if (text.isNotEmpty) {
      _codeController.text = text.trim();
      _codeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _codeController.text.length),
      );
      setState(() => _codeError = null);
    }
  }

  /// EN: Submit the manually entered verification code.
  ///     Trims whitespace before calling the API.
  /// KO: 수동으로 입력된 인증 코드를 제출합니다.
  ///     API 호출 전에 공백을 trim합니다.
  Future<void> _handleVerify() async {
    final token = _codeController.text.trim();

    if (token.isEmpty) {
      setState(() {
        _codeError = context.l10n(
          ko: '코드를 입력해주세요.',
          en: 'Please enter the code.',
          ja: 'コードを入力してください。',
        );
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _codeError = null;
    });

    final result = await ref
        .read(authControllerProvider.notifier)
        .confirmEmailVerification(token: token);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result is Success<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '이메일 인증이 완료되었습니다!',
              en: 'Email verified successfully!',
              ja: 'メール認証が完了しました！',
            ),
          ),
          backgroundColor: GBTColors.success,
        ),
      );
      // EN: Navigate to login after successful verification.
      // KO: 인증 완료 후 로그인 화면으로 이동합니다.
      context.go('/login');
      return;
    }

    if (result is Err<void>) {
      final failure = result.failure;
      final errorCode = failure.code ?? '';
      final errorMessage = _resolveErrorMessage(errorCode, failure.message);

      // EN: For ALREADY_USED, navigate to login after showing message.
      // KO: ALREADY_USED의 경우 메시지 표시 후 로그인으로 이동합니다.
      if (errorCode == 'EMAIL_VERIFICATION_ALREADY_USED') {
        _showAlreadyUsedDialog();
        return;
      }

      setState(() => _codeError = errorMessage);
    }
  }

  /// EN: Resolve human-readable error message from server error code.
  /// KO: 서버 에러 코드에서 사람이 읽을 수 있는 에러 메시지를 반환합니다.
  String _resolveErrorMessage(String code, String fallbackMessage) {
    return switch (code) {
      'EMAIL_VERIFICATION_INVALID' => context.l10n(
        ko: '유효하지 않은 인증 코드입니다. 코드를 다시 확인해주세요.',
        en: 'Invalid verification code. Please check the code again.',
        ja: '無効な認証コードです。コードを再確認してください。',
      ),
      'EMAIL_VERIFICATION_EXPIRED' => context.l10n(
        ko: '인증 코드가 만료되었습니다. 인증 메일을 다시 받아주세요.',
        en: 'The verification code has expired. Please request a new email.',
        ja: '認証コードが期限切れです。認証メールを再送してください。',
      ),
      'EMAIL_VERIFICATION_INVALID_TYPE' => context.l10n(
        ko: '올바르지 않은 인증 코드입니다.',
        en: 'Invalid verification code type.',
        ja: '正しくない認証コードです。',
      ),
      'EMAIL_VERIFICATION_ALREADY_USED' => context.l10n(
        ko: '이미 사용된 인증 코드입니다. 이미 인증이 완료되었을 수 있습니다.',
        en: 'This code has already been used. Verification may already be complete.',
        ja: 'すでに使用済みの認証コードです。すでに認証が完了している可能性があります。',
      ),
      'EMAIL_VERIFICATION_MAX_ATTEMPTS' => context.l10n(
        ko: '인증 시도 횟수를 초과했습니다. 인증 메일을 다시 받아주세요.',
        en: 'Too many attempts. Please request a new verification email.',
        ja: '試行回数を超えました。認証メールを再送してください。',
      ),
      'EMAIL_VERIFICATION_COOLDOWN' => context.l10n(
        ko: '잠시 후 다시 시도해주세요.',
        en: 'Please try again after a moment.',
        ja: 'しばらくたってから再試行してください。',
      ),
      _ when code.startsWith('5') => context.l10n(
        ko: '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        en: 'A server error occurred. Please try again later.',
        ja: 'サーバーエラーが発生しました。しばらくたってから再試行してください。',
      ),
      _ => context.l10n(
        ko: '인증에 실패했습니다. 잠시 후 다시 시도해주세요.',
        en: 'Verification failed. Please try again later.',
        ja: '認証に失敗しました。しばらくたってから再試行してください。',
      ),
    };
  }

  /// EN: Show a dialog for the ALREADY_USED case, then navigate to login.
  /// KO: ALREADY_USED 케이스에 대한 다이얼로그를 표시한 뒤 로그인으로 이동합니다.
  void _showAlreadyUsedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n(ko: '이미 인증 완료', en: 'Already Verified', ja: '認証済み'),
        ),
        content: Text(
          context.l10n(
            ko: '이미 사용된 인증 코드입니다. 인증이 이미 완료되었을 수 있습니다.\n로그인 화면으로 이동하시겠습니까?',
            en: 'This code has already been used. Verification may already be complete.\nGo to the login screen?',
            ja: 'すでに使用済みの認証コードです。認証が完了している可能性があります。\nログイン画面に移動しますか？',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: Text(
              context.l10n(ko: '로그인으로', en: 'Go to Login', ja: 'ログインへ'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isResendEnabled = _cooldownRemaining <= 0 && !_isSending;
    final expiresAt = widget.args.verificationExpiresAt;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '이메일 인증',
          en: 'Email Verification',
          ja: 'メール認証',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
          tooltip: context.l10n(ko: '로그인으로 이동', en: 'Go to login', ja: 'ログインへ'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GBTSpacing.paddingPage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: GBTSpacing.xl),

              // EN: Mail icon
              // KO: 메일 아이콘
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? GBTColors.darkSurfaceVariant
                          : GBTColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 36,
                      color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.lg),

              // EN: Headline
              // KO: 헤드라인
              Text(
                context.l10n(
                  ko: '인증 메일이 발송되었습니다',
                  en: 'Verification email sent',
                  ja: '認証メールを送信しました',
                ),
                style: GBTTypography.headlineSmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextPrimary
                      : GBTColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GBTSpacing.sm),

              // EN: Description with email address
              // KO: 이메일 주소 포함 설명
              Text(
                context.l10n(
                  ko: '${widget.args.email} 으로 발송된 메일의 링크를 클릭하여 인증을 완료해주세요.\n인증 완료 후 로그인할 수 있습니다.',
                  en: 'Click the link sent to ${widget.args.email} to complete verification.\nYou can log in after verification.',
                  ja: '${widget.args.email} に送信されたメール内のリンクをクリックして認証を完了してください。\n認証後にログインできます。',
                ),
                style: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              // EN: Verification expiry notice (shown when backend provides it)
              // KO: 인증 만료 안내 (백엔드가 제공할 때 표시)
              if (expiresAt != null) ...[
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '인증 링크 유효기간: ${DateFormat('MM/dd HH:mm').format(expiresAt)}까지',
                    en: 'Link expires: ${DateFormat('MM/dd HH:mm').format(expiresAt)}',
                    ja: 'リンク有効期限: ${DateFormat('MM/dd HH:mm').format(expiresAt)}まで',
                  ),
                  style: GBTTypography.labelMedium.copyWith(
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: GBTSpacing.xl2),

              // EN: Action buttons row: open email + resend
              // KO: 액션 버튼 행: 이메일 열기 + 재전송
              Row(
                children: [
                  Expanded(
                    child: GBTButton(
                      label: context.l10n(
                        ko: '이메일 열기',
                        en: 'Open Email',
                        ja: 'メールを開く',
                      ),
                      icon: Icons.open_in_new,
                      iconPosition: IconPosition.leading,
                      onPressed: () {
                        // EN: Platform-level mail app launch is handled
                        //     by url_launcher if available; no-op here.
                        // KO: 플랫폼 기본 메일 앱 실행은 url_launcher로
                        //     처리합니다. 현재는 no-op입니다.
                      },
                      variant: GBTButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: GBTButton(
                      label: _cooldownRemaining > 0
                          ? context.l10n(
                              ko: '재전송 ($_cooldownRemaining초)',
                              en: 'Resend ($_cooldownRemaining s)',
                              ja: '再送 ($_cooldownRemaining秒)',
                            )
                          : context.l10n(
                              ko: '인증 메일 재전송',
                              en: 'Resend email',
                              ja: '認証メール再送',
                            ),
                      isLoading: _isSending,
                      onPressed: isResendEnabled ? _handleResend : null,
                      variant: GBTButtonVariant.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: GBTSpacing.xl2),

              // EN: Divider with label
              // KO: 라벨이 있는 구분선
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.md,
                    ),
                    child: Text(
                      context.l10n(
                        ko: '링크가 열리지 않나요?',
                        en: "Can't open the link?",
                        ja: 'リンクが開けない場合',
                      ),
                      style: GBTTypography.labelMedium.copyWith(
                        color: isDark
                            ? GBTColors.darkTextSecondary
                            : GBTColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: GBTSpacing.md),

              // EN: Helper text for manual code input
              // KO: 수동 코드 입력 안내 텍스트
              Text(
                context.l10n(
                  ko: '이메일에 있는 인증 코드를 아래에 붙여넣으세요',
                  en: 'Paste the verification code from your email below',
                  ja: 'メールに記載の認証コードを下に貼り付けてください',
                ),
                style: GBTTypography.bodySmall.copyWith(
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GBTSpacing.md),

              // EN: Code input field with error display
              // KO: 에러 표시가 있는 코드 입력 필드
              TextField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                autofocus: false,
                maxLength: 100,
                maxLines: 1,
                onChanged: (_) {
                  if (_codeError != null) {
                    setState(() => _codeError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: context.l10n(
                    ko: '코드를 여기에 붙여넣어 주세요',
                    en: 'Paste code here',
                    ja: 'ここにコードを貼り付けてください',
                  ),
                  errorText: _codeError,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.md,
                    vertical: GBTSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.md),

              // EN: Paste from clipboard + Verify buttons
              // KO: 클립보드에서 붙여넣기 + 인증하기 버튼
              Row(
                children: [
                  Expanded(
                    child: GBTButton(
                      label: context.l10n(
                        ko: '클립보드에서 붙여넣기',
                        en: 'Paste from Clipboard',
                        ja: 'クリップボードから貼り付け',
                      ),
                      icon: Icons.content_paste_rounded,
                      iconPosition: IconPosition.leading,
                      onPressed: _pasteFromClipboard,
                      variant: GBTButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: GBTButton(
                      label: context.l10n(ko: '인증하기', en: 'Verify', ja: '認証する'),
                      icon: Icons.arrow_forward_rounded,
                      iconPosition: IconPosition.trailing,
                      isLoading: _isVerifying,
                      onPressed: _isVerifying ? null : _handleVerify,
                      variant: GBTButtonVariant.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: GBTSpacing.xl),

              // EN: Back to login link
              // KO: 로그인으로 돌아가기 링크
              Semantics(
                button: true,
                label: context.l10n(
                  ko: '로그인 페이지로 이동',
                  en: 'Go to login page',
                  ja: 'ログインページへ',
                ),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      GBTSpacing.touchTarget,
                      GBTSpacing.touchTarget,
                    ),
                  ),
                  child: Text(
                    context.l10n(
                      ko: '로그인으로 돌아가기',
                      en: 'Back to login',
                      ja: 'ログインに戻る',
                    ),
                    style: GBTTypography.labelLarge.copyWith(
                      color: isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
