/// EN: Verification bottom sheet widget.
/// KO: 인증 바텀시트 위젯.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/design_system/accessibility/a11y_wrapper.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/constants/legal_policy_constants.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/location/location_notice_consent.dart';
import 'package:oshi_log/features/identity/auth/application/legal_policies_provider.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_stamp_badge.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/features/place/verification/application/verification_controller.dart';
import 'package:oshi_log/features/place/verification/domain/entities/verification_entities.dart';

class VerificationSheet extends ConsumerStatefulWidget {
  const VerificationSheet({
    super.key,
    required this.title,
    required this.description,
    required this.onVerify,
    this.onWriteReview,
  });

  final String title;
  final String description;
  final Future<Result<VerificationResult>> Function() onVerify;
  final VoidCallback? onWriteReview;

  @override
  ConsumerState<VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends ConsumerState<VerificationSheet> {
  bool _agreedLocationNotice = false;

  // EN: True once the user has agreed to the location notice before. The
  //     notice then stays visible as information without asking again.
  // KO: 사용자가 이전에 위치 고지에 동의한 경우 true입니다. 이후에는 고지를
  //     안내용으로만 표시하고 다시 동의를 요구하지 않습니다.
  bool _acknowledgedBefore = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNoticeAcknowledgement());
  }

  Future<void> _loadNoticeAcknowledgement() async {
    final consent = await ref.read(locationNoticeConsentProvider.future);
    if (!mounted || !consent.isAgreed) return;
    setState(() {
      _acknowledgedBefore = true;
      _agreedLocationNotice = true;
    });
  }

  Future<void> _persistNoticeAcknowledgement() async {
    try {
      final store = await ref.read(locationNoticeConsentStoreProvider.future);
      await store.agree(DateTime.now());
      ref.invalidate(locationNoticeConsentProvider);
      if (!mounted) return;
      setState(() => _acknowledgedBefore = true);
    } on Exception catch (_) {
      // EN: A failed write only means the notice is shown again next time.
      // KO: 저장 실패는 다음 번에 고지를 다시 표시하는 것 외에 영향이 없습니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationControllerProvider);
    // EN: Location terms version comes from the server policy list.
    // KO: 위치정보 이용약관 버전은 서버 정책 목록에서 가져옵니다.
    final locationTerms = resolveLegalPolicy(
      ref.watch(legalPoliciesProvider).valueOrNull,
      LegalPolicyType.locationTerms,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: GBTSpacing.md,
        right: GBTSpacing.md,
        top: GBTSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + GBTSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? GBTColors.darkBorder
                  : GBTColors.border,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          Text(widget.title, style: GBTTypography.titleMedium),
          const SizedBox(height: GBTSpacing.sm),
          Text(
            widget.description,
            style: GBTTypography.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GBTSpacing.md),
          // EN: Shown only until the notice is agreed once; afterwards
          //     verification starts directly with no consent step.
          // KO: 고지에 1회 동의할 때까지만 표시하며, 이후에는 동의 단계 없이
          //     바로 인증을 시작합니다.
          if (!_acknowledgedBefore)
            _LocationNoticeCard(
              agreed: _agreedLocationNotice,
              versionLabel: locationTerms.version,
              onChanged: (value) {
                setState(() => _agreedLocationNotice = value);
              },
            ),
          const SizedBox(height: GBTSpacing.lg),
          state.when(
            loading: () => GBTLoading(
              message: context.l10n(
                ko: '인증 처리 중...',
                en: 'Verifying...',
                ja: '認証処理中...',
              ),
            ),
            error: (error, _) {
              final message = error is Failure
                  ? _buildVerificationErrorMessage(context, error)
                  : context.l10n(
                      ko: '인증에 실패했습니다',
                      en: 'Verification failed',
                      ja: '認証に失敗しました',
                    );

              // EN: Announce error to screen reader
              // KO: 스크린 리더에 에러 공지
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  A11yAnnouncer.announceError(context, message);
                }
              });

              return Column(
                children: [
                  Text(
                    message,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: GBTColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GBTSpacing.md),
                  _PrimaryButton(
                    label: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                    onPressed: _handleStartVerification,
                  ),
                ],
              );
            },
            data: (result) {
              if (result != null) {
                // EN: Announce success to screen reader
                // KO: 스크린 리더에 성공 공지
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    A11yAnnouncer.announceSuccess(
                      context,
                      context.l10n(
                        ko: '장소 인증이 완료되었습니다',
                        en: 'Place verification complete',
                        ja: 'スポット認証が完了しました',
                      ),
                    );
                  }
                });

                final isDark = Theme.of(context).brightness == Brightness.dark;
                // EN: Verified/visited semantic mint — matches the stamp
                // color used across zukan and visit records.
                // KO: 인증/방문 시맨틱 민트 — 도감·방문 기록에서 쓰는
                // 스탬프 색상과 동일합니다.
                final mint = GBTSemanticColors.getDistanceColor(
                  Theme.of(context).brightness,
                );

                return Column(
                  children: [
                    // EN: Celebratory stamp-press pop — reuses the same
                    // unlock animation as the zukan collection badges.
                    // KO: 축하 스탬프 찍기 팝 — 도감 배지와 동일한 해금
                    // 애니메이션을 재사용합니다.
                    GBTStampBadge(
                      size: 96,
                      unlocked: true,
                      color: mint,
                      child: Icon(Icons.check_rounded, size: 44, color: mint),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    Text(
                      context.l10n(ko: '인증 완료!', en: 'Verified!', ja: '認証完了！'),
                      style: GBTTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: mint,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      result.result,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: isDark
                            ? GBTColors.darkTextSecondary
                            : GBTColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    if (widget.onWriteReview != null) ...[
                      _PrimaryButton(
                        label: context.l10n(
                          ko: '후기 작성',
                          en: 'Write a Review',
                          ja: 'レビューを書く',
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onWriteReview?.call();
                        },
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            context.l10n(ko: '건너뛰기', en: 'Skip', ja: 'スキップ'),
                          ),
                        ),
                      ),
                    ] else
                      _PrimaryButton(
                        label: context.l10n(ko: '확인', en: 'OK', ja: '確認'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                );
              }

              return _PrimaryButton(
                label: _agreedLocationNotice
                    ? context.l10n(
                        ko: '동의하고 인증 시작',
                        en: 'Agree & Start Verification',
                        ja: '同意して認証を開始する',
                      )
                    : context.l10n(
                        ko: '사전 고지 동의 필요',
                        en: 'Agreement required',
                        ja: '事前告知への同意が必要です',
                      ),
                onPressed: _agreedLocationNotice
                    ? _handleStartVerification
                    : _showConsentRequired,
              );
            },
          ),
          const SizedBox(height: GBTSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _handleStartVerification() async {
    if (!_agreedLocationNotice) {
      _showConsentRequired();
      return;
    }
    // EN: Remember the first agreement so later verifications never re-ask.
    // KO: 첫 동의를 저장해 이후 인증에서는 다시 동의를 요구하지 않습니다.
    if (!_acknowledgedBefore) {
      await _persistNoticeAcknowledgement();
    }
    ref.read(verificationControllerProvider.notifier).reset();
    await widget.onVerify();
  }

  void _showConsentRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '위치 수집 사전 고지에 동의해야 인증을 시작할 수 있어요',
            en: 'Agree to the location notice to start verification',
            ja: '位置情報の収集に関する事前告知に同意すると認証を開始できます',
          ),
        ),
      ),
    );
  }
}

class _LocationNoticeCard extends StatelessWidget {
  const _LocationNoticeCard({
    required this.agreed,
    required this.versionLabel,
    required this.onChanged,
  });

  final bool agreed;
  final String versionLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GBTSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(
          color: isDark ? GBTColors.darkBorderSubtle : GBTColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n(
              ko: '위치 수집 사전 고지',
              en: 'Location Collection Notice',
              ja: '位置情報収集に関する事前告知',
            ),
            style: GBTTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            context.l10n(
              ko: '목적: 방문 인증\n보유기간: 관련 법령 및 운영정책 범위 내\n철회: 설정 > 약관/정책에서 확인 후 철회 요청',
              en: 'Purpose: Visit verification\nRetention: Within applicable laws and policy\nWithdrawal: Settings > Terms/Policy for withdrawal requests',
              ja: '目的: 訪問認証\n保有期間: 関連法令および運営ポリシーの範囲内\n撤回: 設定＞規約・ポリシーで確認後、撤回を申請できます',
            ),
            style: GBTTypography.labelSmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            context.l10n(
              ko: '위치정보 이용약관 $versionLabel',
              en: 'Location Terms $versionLabel',
              ja: '位置情報利用規約 $versionLabel',
            ),
            style: GBTTypography.labelSmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          InkWell(
            onTap: () => onChanged(!agreed),
            borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (value) => onChanged(value ?? false),
                ),
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '위치 수집/이용 고지 내용을 확인했고 동의합니다 (필수)',
                      en: 'I have read and agree to the location notice (required)',
                      ja: '位置情報の収集・利用に関する告知内容を確認し、同意します（必須）',
                    ),
                    style: GBTTypography.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// EN: Maps server error codes to user-facing localized messages.
// KO: 서버 에러 코드를 사용자 표시용 다국어 메시지로 매핑합니다.
const _verificationErrorMessages = <String, (String ko, String en, String ja)>{
  'out_of_verification_radius': (
    '인증 반경 밖입니다. 장소/공연장 근처에서 다시 시도해주세요.',
    'You are outside the verification radius. Try again near the venue.',
    '認証範囲外です。スポット・会場の近くで再度お試しください。',
  ),
  'location_token_invalid': (
    '위치 인증 토큰이 유효하지 않습니다. 앱을 재시작한 뒤 다시 시도해주세요.',
    'The location verification token is invalid. Restart the app and try again.',
    '位置認証トークンが無効です。アプリを再起動してから再度お試しください。',
  ),
  'location_token_expired': (
    '위치 인증 토큰이 만료되었습니다. 다시 시도해주세요.',
    'The location verification token has expired. Try again.',
    '位置認証トークンの有効期限が切れました。再度お試しください。',
  ),
  'visit_cooldown_active': (
    '짧은 시간 내 중복 인증은 제한됩니다. 잠시 후 다시 시도해주세요.',
    'Repeated verification in a short time is limited. Try again later.',
    '短時間での重複認証は制限されています。しばらくしてから再度お試しください。',
  ),
  'daily_visit_limit_reached': (
    '오늘 이 장소의 인증 가능 횟수를 초과했습니다.',
    'You have reached today\'s verification limit for this place.',
    '本日この場所の認証可能回数を超えました。',
  ),
  'duplicate_verification_request': (
    '중복 인증 요청입니다.',
    'This is a duplicate verification request.',
    '重複した認証リクエストです。',
  ),
  'simulated_location_not_allowed': (
    '모의 위치는 허용되지 않습니다.',
    'Mock locations are not allowed.',
    '模擬位置情報は許可されていません。',
  ),
  'suspicious_movement_detected': (
    '비정상 이동 패턴이 감지되어 인증이 거부되었습니다.',
    'Verification was denied due to an unusual movement pattern.',
    '異常な移動パターンが検出されたため、認証が拒否されました。',
  ),
  'rapid_traversal_detected': (
    '짧은 시간 내 과도한 장소 인증 패턴이 감지되었습니다.',
    'An excessive place-verification pattern was detected in a short time.',
    '短時間で過度な場所認証パターンが検出されました。',
  ),
  'gps_accuracy_invalid': (
    'GPS 정확도가 비정상으로 감지되었습니다.',
    'GPS accuracy was detected as abnormal.',
    'GPSの精度が異常として検出されました。',
  ),
  'gps_accuracy_too_low': (
    'GPS 정확도가 낮아 인증할 수 없습니다.',
    'Verification is not possible due to low GPS accuracy.',
    'GPSの精度が低いため認証できません。',
  ),
};

String _buildVerificationErrorMessage(BuildContext context, Failure error) {
  final codeLower = error.code?.toLowerCase();
  if (codeLower != null) {
    final mapped = _verificationErrorMessages[codeLower];
    if (mapped != null) {
      return context.l10n(ko: mapped.$1, en: mapped.$2, ja: mapped.$3);
    }
  }
  return context.l10n(
    ko: '인증에 실패했습니다. 위치와 GPS 상태를 확인하고 다시 시도해주세요.',
    en: 'Verification failed. Check your location and GPS status and try again.',
    ja: '認証に失敗しました。位置情報とGPSの状態を確認して再度お試しください。',
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
