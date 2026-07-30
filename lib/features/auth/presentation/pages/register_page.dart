/// EN: Register page for creating an account.
/// KO: 계정 생성을 위한 회원가입 페이지.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/legal_policy_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/buttons/gbt_button.dart';
import '../../../../core/widgets/inputs/gbt_text_field.dart';
import '../../../../core/widgets/legal/legal_policy_links_section.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import '../../domain/entities/register_consent.dart';
import '../../domain/entities/register_result.dart';
import '../widgets/field_auth_components.dart';
import 'email_verification_args.dart';

/// EN: Register page widget.
/// KO: 회원가입 페이지 위젯.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // EN: Live password validation state.
  // KO: 실시간 비밀번호 검증 상태.
  bool _hasMinLength = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeLocationTerms = false;
  bool _confirmOver14 = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final value = _passwordController.text;
    setState(() {
      _passwordTouched = true;
      _hasMinLength = value.length >= 8 && value.length <= 128;
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasDigit = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[@$!%*?&]'));
      _passwordsMatch =
          value.isNotEmpty && value == _confirmPasswordController.text;
    });
  }

  void _onConfirmChanged() {
    setState(() {
      _confirmTouched = true;
      _passwordsMatch =
          _passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  bool get _allPasswordConditionsMet =>
      _hasMinLength &&
      _hasLowercase &&
      _hasUppercase &&
      _hasDigit &&
      _hasSpecialChar;

  bool get _hasRequiredConsents =>
      _agreeTerms && _agreePrivacy && _agreeLocationTerms && _confirmOver14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      next.whenOrNull(
        error: (error, _) {
          final message = _toSafeRegisterErrorMessage(error);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '회원가입', en: 'Sign up', ja: '会員登録'),
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
                  eyebrow: 'NEW TRAVEL ACCOUNT',
                  title: context.l10n(
                    ko: '나만의 탐방 여정을 시작하세요',
                    en: 'Start your own travel log',
                    ja: 'あなたの探訪記録を始めましょう',
                  ),
                  subtitle: context.l10n(
                    ko: '계정 정보와 필수 동의를 확인하면 바로 시작할 수 있어요.',
                    en: 'Add your account details and required consents to begin.',
                    ja: 'アカウント情報と必須の同意を確認して始めましょう。',
                  ),
                  icon: Icons.person_add_alt_1_outlined,
                ),
                const SizedBox(height: GBTSpacing.lg),

                // EN: Step 1 — basic info group.
                // KO: 1단계 — 기본 정보 그룹.
                _StepLabel(
                  label: context.l10n(
                    ko: '기본 정보',
                    en: 'Basic info',
                    ja: '基本情報',
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: GBTSpacing.xs),

                // EN: Email field.
                // KO: 이메일 필드.
                GBTTextField(
                  controller: _emailController,
                  label: context.l10n(ko: '이메일', en: 'Email', ja: 'メール'),
                  hint: context.l10n(
                    ko: '이메일을 입력하세요',
                    en: 'Enter your email',
                    ja: 'メールアドレスを入力してください',
                  ),
                  prefixIcon: Icons.email_outlined,
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
                    if (!_isValidEmail(value)) {
                      return context.l10n(
                        ko: '올바른 이메일 형식을 입력해주세요',
                        en: 'Please enter a valid email address',
                        ja: '正しいメール形式で入力してください',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: GBTSpacing.md),

                // EN: Nickname field.
                // KO: 닉네임 필드.
                GBTTextField(
                  controller: _nicknameController,
                  label: context.l10n(ko: '닉네임', en: 'Nickname', ja: 'ニックネーム'),
                  hint: context.l10n(
                    ko: '표시할 이름',
                    en: 'Display name',
                    ja: '表示名',
                  ),
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n(
                        ko: '사용자명은 필수입니다.',
                        en: 'Nickname is required.',
                        ja: 'ニックネームは必須です。',
                      );
                    }
                    final trimmed = value.trim();
                    if (trimmed.length < 2 || trimmed.length > 50) {
                      return context.l10n(
                        ko: '사용자명은 2자 이상 50자 이하여야 합니다.',
                        en: 'Nickname must be 2–50 characters.',
                        ja: 'ニックネームは2文字以上50文字以下にしてください。',
                      );
                    }
                    if (!RegExp(
                      r'^[\p{L}\p{M}\p{N}_\-・\p{Zs}]+$',
                      unicode: true,
                    ).hasMatch(trimmed)) {
                      return context.l10n(
                        ko: '사용자명은 문자, 숫자, 공백, 밑줄(_), 하이픈(-), 가운데점(・)만 사용할 수 있습니다.',
                        en: 'Only letters, numbers, spaces, _, -, and ・ are allowed.',
                        ja: '文字、数字、スペース、_、-、・のみ使用できます。',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: GBTSpacing.lg),

                // EN: Step 2 — password group.
                // KO: 2단계 — 비밀번호 그룹.
                _StepLabel(
                  label: context.l10n(
                    ko: '비밀번호 설정',
                    en: 'Set password',
                    ja: 'パスワード設定',
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: GBTSpacing.xs),

                // EN: Password field.
                // KO: 비밀번호 필드.
                GBTTextField(
                  controller: _passwordController,
                  label: context.l10n(ko: '비밀번호', en: 'Password', ja: 'パスワード'),
                  hint: context.l10n(
                    ko: '비밀번호를 입력하세요',
                    en: 'Enter your password',
                    ja: 'パスワードを入力してください',
                  ),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validatePassword(context, value),
                ),

                // EN: Password requirement checklist.
                // KO: 비밀번호 요구사항 체크리스트.
                const SizedBox(height: GBTSpacing.sm),
                _PasswordConditions(
                  touched: _passwordTouched,
                  hasMinLength: _hasMinLength,
                  hasLowercase: _hasLowercase,
                  hasUppercase: _hasUppercase,
                  hasDigit: _hasDigit,
                  hasSpecialChar: _hasSpecialChar,
                ),
                const SizedBox(height: GBTSpacing.md),

                // EN: Password confirmation field.
                // KO: 비밀번호 확인 필드.
                GBTTextField(
                  controller: _confirmPasswordController,
                  label: context.l10n(
                    ko: '비밀번호 확인',
                    en: 'Confirm password',
                    ja: 'パスワード確認',
                  ),
                  hint: context.l10n(
                    ko: '비밀번호를 다시 입력하세요',
                    en: 'Re-enter your password',
                    ja: 'パスワードを再入力してください',
                  ),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureConfirm,
                  suffixIcon: _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n(
                        ko: '비밀번호를 다시 입력해주세요',
                        en: 'Please re-enter your password',
                        ja: 'パスワードを再入力してください',
                      );
                    }
                    if (value != _passwordController.text) {
                      return context.l10n(
                        ko: '비밀번호가 일치하지 않습니다',
                        en: 'Passwords do not match',
                        ja: 'パスワードが一致しません',
                      );
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handleRegister(),
                ),

                // EN: Password match indicator.
                // KO: 비밀번호 일치 표시.
                if (_confirmTouched) ...[
                  const SizedBox(height: GBTSpacing.xs),
                  _ConditionRow(
                    met: _passwordsMatch,
                    touched: true,
                    label: context.l10n(
                      ko: '비밀번호 일치',
                      en: 'Passwords match',
                      ja: 'パスワード一致',
                    ),
                  ),
                ],

                const SizedBox(height: GBTSpacing.lg),
                _ConsentSection(
                  agreeTerms: _agreeTerms,
                  agreePrivacy: _agreePrivacy,
                  agreeLocationTerms: _agreeLocationTerms,
                  confirmOver14: _confirmOver14,
                  onAgreeTermsChanged: (value) {
                    setState(() => _agreeTerms = value);
                  },
                  onAgreePrivacyChanged: (value) {
                    setState(() => _agreePrivacy = value);
                  },
                  onAgreeLocationTermsChanged: (value) {
                    setState(() => _agreeLocationTerms = value);
                  },
                  onConfirmOver14Changed: (value) {
                    setState(() => _confirmOver14 = value);
                  },
                ),
                const SizedBox(height: GBTSpacing.md),
                const LegalPolicyLinksSection(showContainer: false),
                const SizedBox(height: GBTSpacing.lg),
                GBTButton(
                  label: context.l10n(ko: '회원가입', en: 'Sign up', ja: '会員登録'),
                  isLoading: isLoading,
                  isFullWidth: true,
                  onPressed: isLoading
                      ? null
                      : (_hasRequiredConsents ? _handleRegister : null),
                  semanticLabel: isLoading
                      ? context.l10n(
                          ko: '회원가입 진행 중',
                          en: 'Signing up',
                          ja: '登録中',
                        )
                      : context.l10n(ko: '회원가입', en: 'Sign up', ja: '会員登録'),
                ),
                const SizedBox(height: GBTSpacing.md),
                Semantics(
                  button: true,
                  label: context.l10n(
                    ko: '로그인 페이지로 돌아가기',
                    en: 'Back to login page',
                    ja: 'ログインページに戻る',
                  ),
                  child: TextButton(
                    onPressed: () => context.pop(),
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
                        color: colorScheme.onSurfaceVariant,
                      ),
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasRequiredConsents) {
      _showConsentRequiredMessage();
      return;
    }

    // EN: Consent must be recorded against the versions the server currently
    //     requires. Submitting a bundled fallback version makes the server ask
    //     for the same consents again right after signup.
    // KO: 동의는 서버가 현재 요구하는 버전으로 기록해야 합니다. 내장 폴백
    //     버전으로 제출하면 가입 직후 서버가 같은 동의를 다시 요구합니다.
    final policies = await _loadLatestPolicies();
    if (!mounted) return;
    if (policies == null) {
      _showPolicyUnavailableMessage();
      return;
    }

    final consentConfirmed = await _showConsentConfirmDialog(policies);
    if (!consentConfirmed || !mounted) return;

    final consents = _buildRegisterConsents(policies);
    final controller = ref.read(authControllerProvider.notifier);
    final result = await controller.register(
      username: _emailController.text.trim(),
      password: _passwordController.text,
      nickname: _nicknameController.text.trim(),
      consents: consents,
    );

    if (result is Success<RegisterResult> && mounted) {
      await _persistConsentHistory(consents);
      if (!mounted) return;
      if (result.data.verificationRequired) {
        final pendingEmail =
            result.data.pendingEmail ?? _emailController.text.trim();
        context.pushNamed(
          AppRoutes.emailVerificationPending,
          extra: EmailVerificationArgs(
            email: pendingEmail,
            verificationExpiresAt: result.data.verificationExpiresAt,
          ),
        );
      } else {
        context.go('/home');
      }
    }
  }

  /// EN: Loads the policy set the server currently requires.
  ///     Returns null when it cannot be fetched — signup must not proceed
  ///     with an unknown consent version.
  /// KO: 서버가 현재 요구하는 정책 세트를 불러옵니다.
  ///     조회 실패 시 null을 반환합니다 — 알 수 없는 동의 버전으로는
  ///     가입을 진행하지 않아야 합니다.
  Future<List<LegalPolicyInfo>?> _loadLatestPolicies() async {
    try {
      return await ref.read(legalPoliciesProvider.future);
    } on Object {
      return null;
    }
  }

  void _showPolicyUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '최신 약관 정보를 불러올 수 없습니다. 네트워크를 확인한 뒤 다시 시도해주세요.',
            en: 'Could not load the latest terms. Check your network and retry.',
            ja: '最新の規約情報を取得できません。ネットワークを確認して再試行してください。',
          ),
        ),
      ),
    );
  }

  Future<void> _persistConsentHistory(List<RegisterConsent> consents) async {
    try {
      final storage = await ref.read(localStorageProvider.future);
      final consentRecords = consents
          .map(
            (consent) => {
              'type': consent.type,
              'version': consent.version,
              'agreed': consent.agreed,
              'agreedAt': consent.agreedAt.toIso8601String(),
            },
          )
          .toList(growable: false);
      await storage.setJsonList(LocalStorageKeys.userConsents, consentRecords);
    } catch (_) {
      // EN: Consent history persistence failure must not block successful signup.
      // KO: 동의 이력 저장 실패는 가입 성공 흐름을 막지 않아야 합니다.
    }
  }

  List<RegisterConsent> _buildRegisterConsents(List<LegalPolicyInfo> policies) {
    final now = DateTime.now();

    String versionFor(LegalPolicyType type) {
      return resolveLegalPolicy(policies, type).version;
    }

    final termsVersion = versionFor(LegalPolicyType.termsOfService);
    return [
      RegisterConsent(
        type: 'TERMS_OF_SERVICE',
        version: termsVersion,
        agreed: _agreeTerms,
        agreedAt: now,
      ),
      RegisterConsent(
        type: 'PRIVACY_POLICY',
        version: versionFor(LegalPolicyType.privacyPolicy),
        agreed: _agreePrivacy,
        agreedAt: now,
      ),
      RegisterConsent(
        type: 'LOCATION_TERMS',
        version: versionFor(LegalPolicyType.locationTerms),
        agreed: _agreeLocationTerms,
        agreedAt: now,
      ),
      RegisterConsent(
        type: 'AGE_OVER_14',
        version: termsVersion,
        agreed: _confirmOver14,
        agreedAt: now,
      ),
    ];
  }

  String? _validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n(
        ko: '비밀번호는 필수입니다.',
        en: 'Password is required.',
        ja: 'パスワードは必須です。',
      );
    }
    if (value.length < 8 || value.length > 128) {
      return context.l10n(
        ko: '비밀번호는 8자 이상 128자 이하여야 합니다.',
        en: 'Password must be 8–128 characters.',
        ja: 'パスワードは8文字以上128文字以下にしてください。',
      );
    }
    if (!_allPasswordConditionsMet) {
      return context.l10n(
        ko: '비밀번호는 대문자, 소문자, 숫자, 특수문자(@\$!%*?&)를 각각 1개 이상 포함해야 합니다.',
        en: 'Password must include uppercase, lowercase, number, and special character (@\$!%*?&).',
        ja: 'パスワードは大文字・小文字・数字・特殊文字(@\$!%*?&)を各1文字以上含む必要があります。',
      );
    }
    return null;
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  void _showConsentRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '필수 동의 항목을 모두 체크해주세요.',
            en: 'Please check all required consent items.',
            ja: '必須同意項目をすべてチェックしてください。',
          ),
        ),
      ),
    );
  }

  Future<bool> _showConsentConfirmDialog(List<LegalPolicyInfo> policies) {
    final now = DateTime.now().toLocal();
    final terms = resolveLegalPolicy(policies, LegalPolicyType.termsOfService);
    final privacy = resolveLegalPolicy(policies, LegalPolicyType.privacyPolicy);
    final location = resolveLegalPolicy(
      policies,
      LegalPolicyType.locationTerms,
    );
    Widget buildConfirmBody(BuildContext buildContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n(
              ko: '아래 동의 항목으로 가입을 진행할까요?',
              en: 'Proceed with the following consents?',
              ja: '以下の同意内容で登録を進めますか？',
            ),
            style: GBTTypography.bodySmall,
          ),
          const SizedBox(height: GBTSpacing.sm),
          _ConfirmLine(text: '${terms.type.label(context)} ${terms.version}'),
          _ConfirmLine(
            text: '${privacy.type.label(context)} ${privacy.version}',
          ),
          _ConfirmLine(
            text: '${location.type.label(context)} ${location.version}',
          ),
          _ConfirmLine(
            text: context.l10n(
              ko: '만 14세 이상 확인',
              en: 'Confirmed age 14 or older',
              ja: '14歳以上確認',
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '동의 시각: ${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")} ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
              en: 'Consent time: ${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")} ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
              ja: '同意時刻: ${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")} ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
            ),
            style: GBTTypography.labelSmall.copyWith(
              color: Theme.of(buildContext).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final platform = Theme.of(context).platform;
    final useCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    if (!mounted) return Future.value(false);

    final dialogFuture = useCupertino
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (dialogContext) => CupertinoAlertDialog(
              title: Text(
                context.l10n(
                  ko: '가입 전 최종 확인',
                  en: 'Final confirmation',
                  ja: '登録前の最終確認',
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: Colors.transparent,
                  child: buildConfirmBody(dialogContext),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    context.l10n(
                      ko: '동의 후 가입',
                      en: 'Agree and sign up',
                      ja: '同意して登録',
                    ),
                  ),
                ),
              ],
            ),
          )
        : showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(
                  context.l10n(
                    ko: '가입 전 최종 확인',
                    en: 'Final confirmation',
                    ja: '登録前の最終確認',
                  ),
                ),
                content: buildConfirmBody(dialogContext),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.l10n(
                        ko: '동의 후 가입',
                        en: 'Agree and sign up',
                        ja: '同意して登録',
                      ),
                    ),
                  ),
                ],
              );
            },
          );
    return dialogFuture.then((confirmed) => confirmed ?? false);
  }

  String _toSafeRegisterErrorMessage(Object error) {
    if (error is NetworkFailure) {
      return context.l10n(
        ko: '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
        en: 'Check your network and try again.',
        ja: 'ネットワーク状態を確認して再試行してください。',
      );
    }
    if (error is Failure && error.code == '409') {
      return context.l10n(
        ko: '이미 가입된 이메일입니다.',
        en: 'This email is already registered.',
        ja: 'このメールアドレスはすでに登録されています。',
      );
    }
    if (error is Failure && error.code == '429') {
      return context.l10n(
        ko: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        en: 'Too many requests. Please try again later.',
        ja: 'リクエストが多すぎます。しばらく経ってから再試行してください。',
      );
    }
    if (error is ValidationFailure) {
      final firstFieldError =
          error.fieldErrors?.values.firstOrNull?.firstOrNull;
      if (firstFieldError != null) return firstFieldError;
    }
    return context.l10n(
      ko: '회원가입 처리 중 문제가 발생했습니다. 입력값을 확인하고 다시 시도해주세요.',
      en: 'Sign-up failed. Please verify your input and try again.',
      ja: '会員登録に失敗しました。入力内容を確認して再試行してください。',
    );
  }
}

/// EN: Small uppercase-feel section label marking a registration step
/// (basic info / password / consents), matching the settings group label
/// style for cross-screen consistency.
/// KO: 회원가입 단계(기본 정보/비밀번호/동의)를 표시하는 대문자 느낌의 작은
/// 섹션 라벨. 화면 간 일관성을 위해 설정 그룹 라벨 스타일과 통일.
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GBTTypography.labelSmall.copyWith(
        color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ConfirmLine extends StatelessWidget {
  const _ConfirmLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 14),
          ),
          const SizedBox(width: GBTSpacing.xs),
          Expanded(child: Text(text, style: GBTTypography.bodySmall)),
        ],
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.agreeTerms,
    required this.agreePrivacy,
    required this.agreeLocationTerms,
    required this.confirmOver14,
    required this.onAgreeTermsChanged,
    required this.onAgreePrivacyChanged,
    required this.onAgreeLocationTermsChanged,
    required this.onConfirmOver14Changed,
  });

  final bool agreeTerms;
  final bool agreePrivacy;
  final bool agreeLocationTerms;
  final bool confirmOver14;
  final ValueChanged<bool> onAgreeTermsChanged;
  final ValueChanged<bool> onAgreePrivacyChanged;
  final ValueChanged<bool> onAgreeLocationTermsChanged;
  final ValueChanged<bool> onConfirmOver14Changed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '필수 동의', en: 'Required consents', ja: '必須同意'),
          style: GBTTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: GBTSpacing.xs),
        _ConsentCheckTile(
          value: agreeTerms,
          label: context.l10n(
            ko: '이용약관 동의 (필수)',
            en: 'Agree to Terms (Required)',
            ja: '利用規約に同意 (必須)',
          ),
          onChanged: onAgreeTermsChanged,
        ),
        _ConsentCheckTile(
          value: agreePrivacy,
          label: context.l10n(
            ko: '개인정보 처리방침 동의 (필수)',
            en: 'Agree to Privacy Policy (Required)',
            ja: 'プライバシーポリシーに同意 (必須)',
          ),
          onChanged: onAgreePrivacyChanged,
        ),
        _ConsentCheckTile(
          value: agreeLocationTerms,
          label: context.l10n(
            ko: '위치정보 이용약관 동의 (필수)',
            en: 'Agree to Location Terms (Required)',
            ja: '位置情報利用規約に同意 (必須)',
          ),
          onChanged: onAgreeLocationTermsChanged,
        ),
        _ConsentCheckTile(
          value: confirmOver14,
          label: context.l10n(
            ko: '만 14세 이상입니다 (필수)',
            en: 'I am 14 years old or older (Required)',
            ja: '14歳以上です (必須)',
          ),
          onChanged: onConfirmOver14Changed,
        ),
      ],
    );
  }
}

class _ConsentCheckTile extends StatelessWidget {
  const _ConsentCheckTile({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            Expanded(child: Text(label, style: GBTTypography.bodySmall)),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Password condition checklist widget
// KO: 비밀번호 조건 체크리스트 위젯
// ========================================

class _PasswordConditions extends StatelessWidget {
  const _PasswordConditions({
    required this.touched,
    required this.hasMinLength,
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  final bool touched;
  final bool hasMinLength;
  final bool hasLowercase;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConditionRow(
          met: hasMinLength,
          touched: touched,
          label: context.l10n(
            ko: '8자 이상 128자 이하',
            en: '8–128 characters',
            ja: '8文字以上128文字以下',
          ),
        ),
        const SizedBox(height: 2),
        _ConditionRow(
          met: hasLowercase,
          touched: touched,
          label: context.l10n(
            ko: '소문자 포함 (a-z)',
            en: 'Contains lowercase (a-z)',
            ja: '小文字を含む (a-z)',
          ),
        ),
        const SizedBox(height: 2),
        _ConditionRow(
          met: hasUppercase,
          touched: touched,
          label: context.l10n(
            ko: '대문자 포함 (A-Z)',
            en: 'Contains uppercase (A-Z)',
            ja: '大文字を含む (A-Z)',
          ),
        ),
        const SizedBox(height: 2),
        _ConditionRow(
          met: hasDigit,
          touched: touched,
          label: context.l10n(
            ko: '숫자 포함 (0-9)',
            en: 'Contains number (0-9)',
            ja: '数字を含む (0-9)',
          ),
        ),
        const SizedBox(height: 2),
        _ConditionRow(
          met: hasSpecialChar,
          touched: touched,
          label: context.l10n(
            ko: '특수문자 포함 (@\$!%*?& 중 1개 이상)',
            en: 'Contains special character (@\$!%*?&)',
            ja: '特殊文字を含む (@\$!%*?& のいずれか)',
          ),
        ),
      ],
    );
  }
}

// ========================================
// EN: Single condition row with icon + label
// KO: 아이콘 + 라벨이 있는 단일 조건 행
// ========================================

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.met,
    required this.touched,
    required this.label,
  });

  final bool met;
  final bool touched;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // EN: Not touched yet → neutral grey. Touched → green (met) / red (not met).
    // KO: 미입력 → 중립 회색. 입력 후 → 초록 (충족) / 빨강 (미충족).
    final Color iconColor;
    final Color textColor;
    final IconData icon;

    if (!touched) {
      iconColor = isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary;
      textColor = isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary;
      icon = Icons.circle_outlined;
    } else if (met) {
      iconColor = GBTColors.success;
      textColor = GBTColors.success;
      icon = Icons.check_circle;
    } else {
      iconColor = isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary;
      textColor = isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary;
      icon = Icons.circle_outlined;
    }

    return Semantics(
      label:
          '$label, ${met ? context.l10n(ko: "충족", en: "met", ja: "満たす") : context.l10n(ko: "미충족", en: "not met", ja: "未達成")}',
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: GBTSpacing.xs),
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
