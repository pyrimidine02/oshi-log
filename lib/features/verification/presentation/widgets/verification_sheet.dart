/// EN: Verification bottom sheet widget.
/// KO: 인증 바텀시트 위젯.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/a11y_wrapper.dart';
import '../../../../core/constants/legal_policy_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/location/location_notice_consent.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_stamp_badge.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../application/verification_controller.dart';
import '../../domain/entities/verification_entities.dart';

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
            loading: () => const GBTLoading(message: '인증 처리 중...'),
            error: (error, _) {
              final message = error is Failure
                  ? _buildVerificationErrorMessage(error)
                  : '인증에 실패했습니다';

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
                    label: '다시 시도',
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
                    A11yAnnouncer.announceSuccess(context, '장소 인증이 완료되었습니다');
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
                      '인증 완료!',
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
                        label: '후기 작성',
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
                          child: const Text('건너뛰기'),
                        ),
                      ),
                    ] else
                      _PrimaryButton(
                        label: '확인',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                );
              }

              return _PrimaryButton(
                label: _agreedLocationNotice ? '동의하고 인증 시작' : '사전 고지 동의 필요',
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
      const SnackBar(content: Text('위치 수집 사전 고지에 동의해야 인증을 시작할 수 있어요')),
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
            '위치 수집 사전 고지',
            style: GBTTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            '목적: 방문 인증\n보유기간: 관련 법령 및 운영정책 범위 내\n철회: 설정 > 약관/정책에서 확인 후 철회 요청',
            style: GBTTypography.labelSmall.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            '위치정보 이용약관 $versionLabel',
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
                    '위치 수집/이용 고지 내용을 확인했고 동의합니다 (필수)',
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

// EN: Maps server error codes to user-facing Korean messages.
// KO: 서버 에러 코드를 사용자 표시용 한국어 메시지로 매핑합니다.
const _verificationErrorMessages = <String, String>{
  'out_of_verification_radius': '인증 반경 밖입니다. 장소/공연장 근처에서 다시 시도해주세요.',
  'location_token_invalid': '위치 인증 토큰이 유효하지 않습니다. 앱을 재시작한 뒤 다시 시도해주세요.',
  'location_token_expired': '위치 인증 토큰이 만료되었습니다. 다시 시도해주세요.',
  'visit_cooldown_active': '짧은 시간 내 중복 인증은 제한됩니다. 잠시 후 다시 시도해주세요.',
  'daily_visit_limit_reached': '오늘 이 장소의 인증 가능 횟수를 초과했습니다.',
  'duplicate_verification_request': '중복 인증 요청입니다.',
  'simulated_location_not_allowed': '모의 위치는 허용되지 않습니다.',
  'suspicious_movement_detected': '비정상 이동 패턴이 감지되어 인증이 거부되었습니다.',
  'rapid_traversal_detected': '짧은 시간 내 과도한 장소 인증 패턴이 감지되었습니다.',
  'gps_accuracy_invalid': 'GPS 정확도가 비정상으로 감지되었습니다.',
  'gps_accuracy_too_low': 'GPS 정확도가 낮아 인증할 수 없습니다.',
};

const _verificationFallbackMessage = '인증에 실패했습니다. 위치와 GPS 상태를 확인하고 다시 시도해주세요.';

String _buildVerificationErrorMessage(Failure error) {
  final codeLower = error.code?.toLowerCase();
  if (codeLower != null) {
    final mapped = _verificationErrorMessages[codeLower];
    if (mapped != null) return mapped;
  }
  return _verificationFallbackMessage;
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
