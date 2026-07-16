/// EN: Detail-page primitives for event tickets and attendance stamps.
/// KO: 이벤트 티켓과 방문 스탬프를 위한 상세 페이지 프리미티브입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';

/// EN: A tactile attendance action that clearly exposes locked verification.
/// KO: 검증 잠금 상태를 명확히 표시하는 촉각적 방문 액션입니다.
class FieldAttendanceStamp extends StatelessWidget {
  const FieldAttendanceStamp({
    super.key,
    required this.attended,
    required this.canUndo,
    required this.isBusy,
    required this.onToggle,
  });

  final bool attended;
  final bool canUndo;
  final bool isBusy;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locked = attended && !canUndo;
    final enabled = !locked && !isBusy && onToggle != null;
    final label = attended
        ? context.l10n(
            ko: locked ? '검증된 참석' : '참석 취소',
            en: locked ? 'Verified attendance' : 'Cancel attendance',
            ja: locked ? '検証済みの参加' : '参加取消',
          )
        : context.l10n(ko: '참석 기록', en: 'Mark attended', ja: '参加記録');
    final accent = attended ? colors.secondary : colors.primary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? onToggle : null,
      excludeSemantics: true,
      child: Material(
        color: attended ? colors.secondaryContainer : colors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          side: BorderSide(color: accent),
        ),
        child: InkWell(
          onTap: enabled ? onToggle : null,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GBTSpacing.touchTarget,
              minWidth: GBTSpacing.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.md,
                vertical: GBTSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBusy)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent,
                      ),
                    )
                  else
                    Icon(
                      attended
                          ? Icons.verified_rounded
                          : Icons.confirmation_num_outlined,
                      size: 20,
                      color: accent,
                    ),
                  const SizedBox(width: GBTSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: One labeled field in the perforated event document.
/// KO: 절취선 이벤트 문서 안의 한 개 라벨 필드입니다.
class FieldEventFact extends StatelessWidget {
  const FieldEventFact({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.secondary),
        const SizedBox(width: GBTSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.75,
                ),
              ),
              const SizedBox(height: GBTSpacing.xxs),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
