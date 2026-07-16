/// EN: Daily check-in card — full-width button below XP section.
/// KO: 일일 출석 체크 카드 — XP 섹션 아래 전체 너비 버튼.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_decorations.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../fan_level/application/fan_level_controller.dart';

/// EN: Full-width daily check-in button with loading state.
/// KO: 로딩 상태를 포함한 전체 너비 일일 출석 체크 버튼.
class CheckInCard extends ConsumerStatefulWidget {
  const CheckInCard({super.key, required this.isDark});

  final bool isDark;

  @override
  ConsumerState<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<CheckInCard> {
  bool _isLoading = false;

  Future<void> _doCheckIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(fanLevelControllerProvider.notifier)
          .checkIn();
      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '출석 체크! +${result.xpEarned} XP 획득',
                en: 'Checked in! +${result.xpEarned} XP earned',
                ja: '出席チェック! +${result.xpEarned} XP獲得',
              ),
            ),
            backgroundColor: GBTColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(fanLevelControllerProvider).valueOrNull;
    final hasCheckedIn = profile?.hasCheckedInToday ?? false;
    final isDark = widget.isDark;

    final doneColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final doneLabelColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final label = hasCheckedIn
        ? context.l10n(ko: '오늘 출석 완료', en: 'Already checked in', ja: '今日の出席完了')
        : context.l10n(
            ko: '오늘 출석 체크 (+10 XP)',
            en: 'Check in today (+10 XP)',
            ja: '今日の出席チェック (+10 XP)',
          );

    // EN: Hero CTA treatment — primary gradient + soft glow when actionable,
    // flat muted surface once already checked in.
    // KO: 히어로 CTA 처리 — 액션 가능할 때는 프라이머리 그라디언트 + 은은한
    // 글로우, 출석 완료 후에는 플랫한 뮤트 표면.
    final decoration = hasCheckedIn
        ? BoxDecoration(
            color: doneColor,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          )
        : BoxDecoration(
            gradient: GBTColors.primaryGradient,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            boxShadow: GBTShadows.primaryGlow(opacity: isDark ? 0.4 : 0.3),
          );
    final contentColor = hasCheckedIn ? doneLabelColor : GBTColors.textInverse;

    return Semantics(
      button: true,
      enabled: !(hasCheckedIn || _isLoading),
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            onTap: hasCheckedIn || _isLoading ? null : _doCheckIn,
            child: Ink(
              decoration: decoration,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: contentColor,
                            ),
                          )
                        : Icon(
                            hasCheckedIn
                                ? Icons.check_circle_outline_rounded
                                : Icons.calendar_today_outlined,
                            size: 18,
                            color: contentColor,
                          ),
                    const SizedBox(width: GBTSpacing.sm),
                    Text(
                      label,
                      style: GBTTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: contentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
