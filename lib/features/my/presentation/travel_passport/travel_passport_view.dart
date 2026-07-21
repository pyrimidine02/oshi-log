/// EN: Pure, route-agnostic view for the travel-passport root.
/// KO: 라우트에 의존하지 않는 여행 여권 루트 순수 뷰입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import 'passport_document.dart';
import 'passport_sections.dart';
import 'travel_passport_view_data.dart';

/// EN: Clean-sheet My-root composed as one editorial travel document.
/// KO: 하나의 에디토리얼 여행 문서로 구성한 새로운 마이 루트 화면입니다.
class TravelPassportView extends StatelessWidget {
  const TravelPassportView({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.onOpenSettings,
    required this.onOpenFanLevel,
    required this.onOpenCalendar,
    required this.onOpenStop,
    required this.onOpenVisits,
    required this.onOpenCollection,
    required this.onOpenBookmarks,
    required this.onOpenFavorites,
  });

  final TravelPassportViewData data;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFanLevel;
  final VoidCallback onOpenCalendar;
  final ValueChanged<UpcomingStopData> onOpenStop;
  final VoidCallback onOpenVisits;
  final VoidCallback onOpenCollection;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.fieldPaper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: isDark ? GBTColors.darkPrimary : GBTColors.fieldBlue,
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        GBTSpacing.pageHorizontal,
                        GBTSpacing.sm,
                        GBTSpacing.pageHorizontal,
                        GBTSpacing.bottomNavClearanceOf(context) +
                            GBTSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PassportPageHeader(onOpenSettings: onOpenSettings),
                          const SizedBox(height: GBTSpacing.md),
                          PassportDocument(
                            data: data,
                            onOpenFanLevel: onOpenFanLevel,
                          ),
                          if (data.profileStatus ==
                                  PassportProfileStatus.unavailable ||
                              data.scheduleStatus ==
                                  PassportScheduleStatus.unavailable) ...[
                            const SizedBox(height: GBTSpacing.md),
                            _PassportLoadNotice(onRetry: onRefresh),
                          ],
                          const SizedBox(height: GBTSpacing.lg),
                          JourneyLedger(
                            data: data.ledger,
                            profileStatus: data.profileStatus,
                          ),
                          const SizedBox(height: GBTSpacing.lg),
                          NextStopsSection(
                            stops: data.upcomingStops,
                            scheduleStatus: data.scheduleStatus,
                            onOpenCalendar: onOpenCalendar,
                            onOpenStop: onOpenStop,
                          ),
                          const SizedBox(height: GBTSpacing.lg),
                          TravelArchiveSection(
                            ledger: data.ledger,
                            profileStatus: data.profileStatus,
                            onOpenVisits: onOpenVisits,
                            onOpenCollection: onOpenCollection,
                            onOpenBookmarks: onOpenBookmarks,
                            onOpenFavorites: onOpenFavorites,
                          ),
                        ],
                      ),
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
}

class _PassportLoadNotice extends StatelessWidget {
  const _PassportLoadNotice({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.fieldInk;
    final rule = isDark ? GBTColors.darkBorder : GBTColors.border;
    final accent = isDark ? GBTColors.darkPrimary : GBTColors.fieldBlue;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: rule),
          bottom: BorderSide(color: rule),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_rounded, color: accent),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Text(
              context.l10n(
                ko: '일부 여행 기록을 불러오지 못했어요.',
                en: 'Some travel records could not be loaded.',
                ja: '一部の旅行記録を読み込めませんでした。',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ink),
            ),
          ),
          SizedBox(
            height: GBTSpacing.touchTarget,
            child: TextButton(
              key: const Key('travel-passport-retry'),
              onPressed: () => onRetry(),
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportPageHeader extends StatelessWidget {
  const _PassportPageHeader({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.fieldInk;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n(ko: '나의 여행 여권', en: 'Travel passport', ja: '私の旅パスポート'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n(ko: '설정', en: 'Settings', ja: '設定'),
          child: IconButton(
            key: const Key('travel-passport-settings'),
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_rounded),
            color: ink,
            constraints: const BoxConstraints.tightFor(
              width: GBTSpacing.touchTarget,
              height: GBTSpacing.touchTarget,
            ),
            tooltip: context.l10n(ko: '설정', en: 'Settings', ja: '設定'),
          ),
        ),
      ],
    );
  }
}
