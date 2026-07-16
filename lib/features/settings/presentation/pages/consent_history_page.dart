/// EN: Consent history page showing legal consent records.
/// KO: 법률 동의 이력을 표시하는 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/settings_controller.dart';
import '../../domain/entities/consent_history.dart';

class ConsentHistoryPage extends ConsumerWidget {
  const ConsentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consentHistoryProvider);

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '동의 이력', en: 'Consent history', ja: '同意履歴'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(consentHistoryProvider);
          await ref.read(consentHistoryProvider.future);
        },
        child: state.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              GBTLoading(
                message: context.l10n(
                  ko: '동의 이력을 불러오는 중...',
                  en: 'Loading consent history...',
                  ja: '同意履歴を読み込み中...',
                ),
              ),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              GBTErrorState(
                message: context.l10n(
                  ko: '동의 이력을 불러오지 못했습니다.',
                  en: 'Failed to load consent history.',
                  ja: '同意履歴を読み込めませんでした。',
                ),
                onRetry: () => ref.invalidate(consentHistoryProvider),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  GBTEmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    message: context.l10n(
                      ko: '저장된 동의 이력이 없습니다.',
                      en: 'No consent history found.',
                      ja: '保存された同意履歴はありません。',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(GBTSpacing.md),
              itemBuilder: (context, index) =>
                  _ConsentHistoryTile(item: items[index]),
              separatorBuilder: (context, _) => Divider(
                height: GBTSpacing.lg,
                color: Theme.of(context).dividerColor,
              ),
              itemCount: items.length,
            );
          },
        ),
      ),
    );
  }
}

final consentHistoryProvider = FutureProvider<List<ConsentHistoryItem>>((
  ref,
) async {
  final repository = await ref.read(settingsRepositoryProvider.future);
  final result = await repository.getConsentHistory();
  if (result is Err<List<ConsentHistoryItem>>) {
    throw result.failure;
  }
  return result.dataOrNull ?? const <ConsentHistoryItem>[];
});

class _ConsentHistoryTile extends StatelessWidget {
  const _ConsentHistoryTile({required this.item});

  final ConsentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.xs,
        vertical: GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.agreed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: item.agreed
                    ? (isDark ? GBTColors.darkSecondary : GBTColors.success)
                    : colorScheme.error,
              ),
              const SizedBox(width: GBTSpacing.xs),
              Expanded(
                child: Text(
                  _consentLabel(context, item.type, item.label),
                  style: GBTTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '버전: ${item.version}',
              en: 'Version: ${item.version}',
              ja: 'バージョン: ${item.version}',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n(
              ko: '동의 시각: ${_formatConsentDate(item.agreedAt)}',
              en: 'Agreed at: ${_formatConsentDate(item.agreedAt)}',
              ja: '同意時刻: ${_formatConsentDate(item.agreedAt)}',
            ),
            style: GBTTypography.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _consentLabel(BuildContext context, String type, String? fallback) {
    final normalized = type.trim().toUpperCase();
    switch (normalized) {
      case 'TERMS_OF_SERVICE':
        return context.l10n(
          ko: '이용약관 동의',
          en: 'Terms of service',
          ja: '利用規約への同意',
        );
      case 'PRIVACY_POLICY':
        return context.l10n(
          ko: '개인정보 처리방침 동의',
          en: 'Privacy policy',
          ja: 'プライバシーポリシーへの同意',
        );
      case 'AGE_OVER_14':
        return context.l10n(
          ko: '만 14세 이상 확인',
          en: 'Age 14+ confirmation',
          ja: '14歳以上確認',
        );
      default:
        return fallback ??
            context.l10n(ko: '동의 항목', en: 'Consent item', ja: '同意項目');
    }
  }

  String _formatConsentDate(DateTime? value) {
    if (value == null) return '-';
    final parsed = value;
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
