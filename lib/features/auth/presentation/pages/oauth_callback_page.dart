/// EN: OAuth callback handler page.
/// KO: OAuth 콜백 처리 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/auth_controller.dart';
import '../../domain/entities/oauth_provider.dart';

/// EN: OAuth callback page that exchanges code for tokens.
/// KO: 인가 코드를 토큰으로 교환하는 OAuth 콜백 페이지.
class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({
    super.key,
    required this.providerId,
    required this.code,
    this.stateParam,
  });

  final String providerId;
  final String code;
  final String? stateParam;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _exchangeCode();
  }

  Future<void> _exchangeCode() async {
    final provider = OAuthProvider.fromId(widget.providerId);
    if (provider == null) {
      setState(() {
        _failure = const ValidationFailure(
          'Unknown OAuth provider',
          code: 'unknown_provider',
        );
      });
      return;
    }

    if (widget.code.isEmpty) {
      setState(() {
        _failure = const ValidationFailure(
          'OAuth code missing',
          code: 'missing_code',
        );
      });
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);

    // EN: Twitter uses PKCE (POST endpoint with codeVerifier) — different from
    //     other providers that use the generic GET callback exchange.
    // KO: Twitter는 PKCE 방식 (codeVerifier와 함께 POST) —
    //     다른 제공자의 일반 GET 콜백 교환 방식과 다릅니다.
    final Result<void> result;
    if (provider == OAuthProvider.twitter) {
      result = await controller.completeTwitterLogin(
        code: widget.code,
        stateParam: widget.stateParam,
      );
    } else {
      final oauthService = ref.read(authOAuthServiceProvider);
      final stateValidation = await oauthService.validateAndConsumeState(
        provider: provider,
        callbackState: widget.stateParam,
      );
      if (!mounted) return;
      if (stateValidation is Err<void>) {
        setState(() => _failure = stateValidation.failure);
        return;
      }
      result = await controller.completeOAuthLogin(
        provider: provider,
        code: widget.code,
        stateParam: widget.stateParam,
      );
    }

    if (!mounted) return;

    if (result is Err<void>) {
      final failure = result.failure;
      setState(() {
        _failure = failure;
      });
      return;
    }

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_failure != null) {
      return Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '로그인 실패', en: 'Login failed', ja: 'ログイン失敗'),
        ),
        body: Center(
          child: Padding(
            padding: GBTSpacing.paddingPage,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EN: Error icon for visual clarity
                // KO: 시각적 명확성을 위한 오류 아이콘
                Icon(
                  Icons.error_outline,
                  size: GBTSpacing.xxxl,
                  color: colorScheme.error,
                  semanticLabel: context.l10n(
                    ko: '로그인 오류',
                    en: 'Login error',
                    ja: 'ログインエラー',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  context.l10n(
                    ko: '로그인에 실패했습니다',
                    en: 'Login failed',
                    ja: 'ログインに失敗しました',
                  ),
                  style: GBTTypography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  _failure!.userMessage,
                  textAlign: TextAlign.center,
                  style: GBTTypography.bodyMedium.copyWith(
                    // EN: Use theme-aware text color for dark mode
                    // KO: 다크 모드를 위해 테마 인식 텍스트 색상 사용
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: GBTSpacing.lg),
                Semantics(
                  button: true,
                  label: context.l10n(
                    ko: '로그인 페이지로 돌아가기',
                    en: 'Back to login page',
                    ja: 'ログインページに戻る',
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      context.l10n(
                        ko: '로그인으로 돌아가기',
                        en: 'Back to login',
                        ja: 'ログインに戻る',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        GBTSpacing.touchTarget,
                        GBTSpacing.touchTarget,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: GBTLoading(
          message: context.l10n(
            ko: '로그인 처리 중...',
            en: 'Processing login...',
            ja: 'ログイン処理中...',
          ),
        ),
      ),
    );
  }
}
