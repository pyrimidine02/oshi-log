/// EN: Admin operations center page.
/// KO: 운영/관리자 센터 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/design_system/widgets/layout/gbt_page_header.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_segmented_tab_bar.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';
import 'package:oshi_log/features/identity/account/domain/entities/user_profile.dart';
import 'package:oshi_log/features/community/moderation/application/admin_ops_controller.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/admin_ops_entities.dart';

/// EN: Admin operations page with overview/report moderation tabs.
/// KO: 개요/신고 관리 탭을 제공하는 관리자 페이지.
class AdminOpsPage extends ConsumerStatefulWidget {
  const AdminOpsPage({super.key});

  @override
  ConsumerState<AdminOpsPage> createState() => _AdminOpsPageState();
}

class _AdminOpsPageState extends ConsumerState<AdminOpsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(userProfileControllerProvider.notifier).load(forceRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileControllerProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '관리자 도구', en: 'Admin tools', ja: '管理者ツール'),
        ),
        body: profileState.when(
          loading: () => Center(
            child: GBTLoading(
              message: context.l10n(
                ko: '권한 확인 중...',
                en: 'Checking permissions...',
                ja: '権限を確認しています...',
              ),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: GBTSpacing.paddingPage,
              child: GBTErrorState(
                message: context.l10n(
                  ko: '권한 정보를 확인하지 못했어요',
                  en: 'Failed to check permissions.',
                  ja: '権限情報を確認できませんでした。',
                ),
                onRetry: () => ref
                    .read(userProfileControllerProvider.notifier)
                    .load(forceRefresh: true),
              ),
            ),
          ),
          data: (profile) {
            if (!_canAccess(profile)) {
              return const _AccessDeniedView();
            }

            return const Column(
              children: [
                AdminOpsSectionNavigation(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(),
                      _ReportsTab(),
                      _RoleRequestsTab(),
                      _MediaDeletionsTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _canAccess(UserProfile? profile) {
    return hasAdminOpsAccess(
      effectiveAccessLevel: profile?.effectiveAccessLevel,
      accountRole: profile?.accountRole,
    );
  }
}

/// EN: Keeps the four local operations modes in the page body so the global
/// app bar remains compact and predictable.
/// KO: 전역 앱바를 작고 예측 가능하게 유지하도록 네 가지 운영 모드를 본문에
/// 배치합니다.
class AdminOpsSectionNavigation extends StatelessWidget {
  const AdminOpsSectionNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n(ko: '운영 업무 영역', en: 'Operations area', ja: '運営業務エリア'),
      child: SizedBox(
        height: 56,
        child: GBTSegmentedTabBar(
          height: 56,
          isScrollable: true,
          margin: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.xs,
            GBTSpacing.md,
            GBTSpacing.xs,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          tabs: [
            Tab(
              text: context.l10n(ko: '개요', en: 'Overview', ja: '概要'),
            ),
            Tab(
              text: context.l10n(ko: '신고 관리', en: 'Reports', ja: '通報管理'),
            ),
            Tab(
              text: context.l10n(
                ko: '권한 요청',
                en: 'Permission requests',
                ja: '権限リクエスト',
              ),
            ),
            Tab(
              text: context.l10n(
                ko: '미디어 삭제',
                en: 'Media deletions',
                ja: 'メディア削除',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return GBTEmptyState(
      icon: Icons.lock_outline,
      title: context.l10n(
        ko: '접근 권한이 없습니다',
        en: 'Access denied',
        ja: 'アクセス権限がありません',
      ),
      subtitle: context.l10n(
        ko: '운영 권한이 확인된 계정만 접근할 수 있습니다.',
        en: 'Only accounts with verified operations permission can access this.',
        ja: '運営権限が確認されたアカウントのみアクセスできます。',
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);

    return state.when(
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          GBTLoading(
            message: context.l10n(
              ko: '운영 지표를 불러오는 중...',
              en: 'Loading operations metrics...',
              ja: '運営指標を読み込んでいます...',
            ),
          ),
        ],
      ),
      error: (error, _) => RefreshIndicator(
        onRefresh: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .load(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const SizedBox(height: 80),
            GBTErrorState(
              message: context.l10n(
                ko: '운영 지표를 불러오지 못했어요',
                en: 'Failed to load operations metrics.',
                ja: '運営指標を読み込めませんでした。',
              ),
              onRetry: () => ref
                  .read(adminDashboardControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
          ],
        ),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () => ref
            .read(adminDashboardControllerProvider.notifier)
            .load(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            AdminOpsSummaryLedger(summary: summary),
            const SizedBox(height: GBTSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// EN: Presents pending operations as a linear field ledger rather than a
/// dashboard of unrelated cards.
/// KO: 대기 중인 운영 업무를 서로 다른 카드 대시보드가 아닌 선형 현장
/// 원장으로 표시합니다.
class AdminOpsSummaryLedger extends StatelessWidget {
  const AdminOpsSummaryLedger({super.key, required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasUrgent = summary.openReports > 0;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GBTPageHeader(
          eyebrow: 'OPERATIONS LOG',
          title: context.l10n(
            ko: '운영 대기 원장',
            en: 'Operations ledger',
            ja: '運営待ち原簿',
          ),
          description: context.l10n(
            ko: '신고, 권한, 검증, 미디어 요청을 처리 순서대로 확인하세요.',
            en: 'Review reports, permissions, verification, and media requests in order.',
            ja: '通報・権限・認証・メディアのリクエストを順番に確認してください。',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.lg,
            GBTSpacing.md,
            GBTSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n(
                        ko: '현재 대기',
                        en: 'Currently pending',
                        ja: '現在の待ち件数',
                      ),
                      style: GBTTypography.labelMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      context.l10n(
                        ko: '${summary.totalPendingItems}건',
                        en: '${summary.totalPendingItems} items',
                        ja: '${summary.totalPendingItems}件',
                      ),
                      style: GBTTypography.displaySmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      hasUrgent
                          ? context.l10n(
                              ko: '신규 신고 ${summary.openReports}건을 먼저 확인해야 합니다.',
                              en: 'Please review ${summary.openReports} new reports first.',
                              ja: '新規通報${summary.openReports}件を先に確認してください。',
                            )
                          : context.l10n(
                              ko: '신규로 접수된 신고는 없습니다.',
                              en: 'No new reports.',
                              ja: '新規の通報はありません。',
                            ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: hasUrgent
                            ? colors.error
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.md),
              Icon(
                Icons.admin_panel_settings_outlined,
                color: colors.primary,
                size: GBTSpacing.iconLg,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          child: _StatGrid(summary: summary),
        ),
        if (summary.extraMetrics.isNotEmpty) ...[
          const SizedBox(height: GBTSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
            child: _ExtraMetricsSection(extraMetrics: summary.extraMetrics),
          ),
        ],
      ],
    );
  }
}

// EN: Linear operations ledger ordered by triage priority.
// KO: 처리 우선순위로 정렬한 선형 운영 원장.

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <_StatCardData>[
      _StatCardData(
        label: context.l10n(ko: '신규 신고', en: 'New reports', ja: '新規通報'),
        value: summary.openReports,
        color: GBTColors.error,
        icon: Icons.flag,
      ),
      _StatCardData(
        label: context.l10n(
          ko: '검토 중 신고',
          en: 'In-review reports',
          ja: '確認中の通報',
        ),
        value: summary.inReviewReports,
        color: GBTColors.primary,
        icon: Icons.rule,
      ),
      _StatCardData(
        label: context.l10n(
          ko: '권한 변경 요청',
          en: 'Permission change requests',
          ja: '権限変更リクエスト',
        ),
        value: summary.pendingAccessGrantRequests,
        color: GBTColors.primary,
        icon: Icons.manage_accounts,
      ),
      _StatCardData(
        label: context.l10n(
          ko: '인증 이의제기',
          en: 'Verification appeals',
          ja: '認証異議申し立て',
        ),
        value: summary.pendingVerificationAppeals,
        color: GBTColors.secondary,
        icon: Icons.gavel,
      ),
      _StatCardData(
        label: context.l10n(
          ko: '삭제 요청',
          en: 'Deletion requests',
          ja: '削除リクエスト',
        ),
        value: summary.pendingMediaDeletionRequests,
        color: GBTColors.error,
        icon: Icons.photo_library_outlined,
      ),
      _StatCardData(
        label: context.l10n(ko: '활성 제재', en: 'Active sanctions', ja: '有効な制裁'),
        value: summary.activeSanctions,
        color: GBTColors.secondary,
        icon: Icons.policy,
      ),
    ];

    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          _StatCard(index: index + 1, data: cards[index]),
          if (index < cards.length - 1) Divider(height: 1, color: dividerColor),
        ],
      ],
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.index, required this.data});

  final int index;
  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasValue = data.value > 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GBTTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Icon(
              data.icon,
              size: GBTSpacing.iconSm,
              color: hasValue ? data.color : colors.onSurfaceVariant,
            ),
            const SizedBox(width: GBTSpacing.sm2),
            Expanded(
              child: Text(
                data.label,
                style: GBTTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Text(
              '${data.value}',
              style: GBTTypography.titleMedium.copyWith(
                color: hasValue ? data.color : colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Extra metrics section — custom Row layout with Divider
// KO: 추가 지표 섹션 — 구분선이 있는 커스텀 Row 레이아웃
// ========================================

class _ExtraMetricsSection extends StatelessWidget {
  const _ExtraMetricsSection({required this.extraMetrics});

  final Map<String, int> extraMetrics;

  @override
  Widget build(BuildContext context) {
    final entries = extraMetrics.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '보조 지표', en: 'Secondary metrics', ja: '補助指標'),
          style: GBTTypography.labelMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Divider(height: 1, color: colors.outlineVariant),
        for (int i = 0; i < entries.length; i++) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[i].key,
                      style: GBTTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Text(
                    '${entries[i].value}',
                    style: GBTTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.secondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < entries.length - 1)
            Divider(height: 1, color: colors.outlineVariant),
        ],
      ],
    );
  }
}

class _AdminOpsTabHeader extends StatelessWidget {
  const _AdminOpsTabHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GBTPageHeader(
      eyebrow: eyebrow,
      title: title,
      description: description,
      padding: const EdgeInsets.fromLTRB(0, GBTSpacing.sm, 0, GBTSpacing.md),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportsControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(adminReportsControllerProvider.notifier)
          .load(forceRefresh: true),
      child: state.reports.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: context.l10n(
                ko: '신고 처리 원장',
                en: 'Report ledger',
                ja: '通報処理原簿',
              ),
              description: context.l10n(
                ko: '접수 순서와 담당 상태를 기준으로 처리합니다.',
                en: 'Process reports in order of receipt and assignment status.',
                ja: '受付順と担当状況に基づいて処理します。',
              ),
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTLoading(
              message: context.l10n(
                ko: '신고 목록을 불러오는 중...',
                en: 'Loading reports...',
                ja: '通報リストを読み込んでいます...',
              ),
            ),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: context.l10n(
                ko: '신고 처리 원장',
                en: 'Report ledger',
                ja: '通報処理原簿',
              ),
              description: context.l10n(
                ko: '접수 순서와 담당 상태를 기준으로 처리합니다.',
                en: 'Process reports in order of receipt and assignment status.',
                ja: '受付順と担当状況に基づいて処理します。',
              ),
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: context.l10n(
                ko: '신고 목록을 불러오지 못했어요',
                en: 'Failed to load reports.',
                ja: '通報リストを読み込めませんでした。',
              ),
              onRetry: () => ref
                  .read(adminReportsControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
          ],
        ),
        data: (reports) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: context.l10n(
                ko: '신고 처리 원장',
                en: 'Report ledger',
                ja: '通報処理原簿',
              ),
              description: context.l10n(
                ko: '접수 순서와 담당 상태를 기준으로 처리합니다.',
                en: 'Process reports in order of receipt and assignment status.',
                ja: '受付順と担当状況に基づいて処理します。',
              ),
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.sm),
            if (reports.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 96),
                child: GBTEmptyState(
                  message: context.l10n(
                    ko: '현재 처리할 신고가 없습니다',
                    en: 'No reports to process right now.',
                    ja: '現在処理対象の通報はありません。',
                  ),
                ),
              )
            else
              ...reports.map(
                (report) =>
                    _ReportCard(report: report, isMutating: state.isMutating),
              ),
            const SizedBox(height: GBTSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _RoleRequestsTab extends ConsumerWidget {
  const _RoleRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminRoleRequestsControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(adminRoleRequestsControllerProvider.notifier)
          .load(forceRefresh: true),
      child: state.requests.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: context.l10n(
                ko: '권한 요청 원장',
                en: 'Permission request ledger',
                ja: '権限リクエスト原簿',
              ),
              description: context.l10n(
                ko: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
                en: 'Check the project role and reason, then approve.',
                ja: 'プロジェクトの役割と理由を確認してから承認してください。',
              ),
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTLoading(
              message: context.l10n(
                ko: '권한 요청 목록을 불러오는 중...',
                en: 'Loading permission requests...',
                ja: '権限リクエストリストを読み込んでいます...',
              ),
            ),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: context.l10n(
                ko: '권한 요청 원장',
                en: 'Permission request ledger',
                ja: '権限リクエスト原簿',
              ),
              description: context.l10n(
                ko: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
                en: 'Check the project role and reason, then approve.',
                ja: 'プロジェクトの役割と理由を確認してから承認してください。',
              ),
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: context.l10n(
                ko: '권한 요청 목록을 불러오지 못했어요',
                en: 'Failed to load permission requests.',
                ja: '権限リクエストリストを読み込めませんでした。',
              ),
              onRetry: () => ref
                  .read(adminRoleRequestsControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
          ],
        ),
        data: (requests) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: context.l10n(
                ko: '권한 요청 원장',
                en: 'Permission request ledger',
                ja: '権限リクエスト原簿',
              ),
              description: context.l10n(
                ko: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
                en: 'Check the project role and reason, then approve.',
                ja: 'プロジェクトの役割と理由を確認してから承認してください。',
              ),
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.sm),
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 96),
                child: GBTEmptyState(
                  message: context.l10n(
                    ko: '현재 처리할 권한 요청이 없습니다',
                    en: 'No permission requests to process right now.',
                    ja: '現在処理対象の権限リクエストはありません。',
                  ),
                ),
              )
            else
              ...requests.map(
                (item) => _RoleRequestCard(
                  request: item,
                  isMutating: state.isMutating,
                ),
              ),
            const SizedBox(height: GBTSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _MediaDeletionsTab extends ConsumerWidget {
  const _MediaDeletionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminMediaDeletionsControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(adminMediaDeletionsControllerProvider.notifier)
          .load(forceRefresh: true),
      child: state.requests.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: context.l10n(
                ko: '미디어 삭제 원장',
                en: 'Media deletion ledger',
                ja: 'メディア削除原簿',
              ),
              description: context.l10n(
                ko: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
                en: 'Check the scope of linked content before deleting.',
                ja: '関連コンテンツの範囲を確認してから削除してください。',
              ),
            ),
            const SizedBox(height: GBTSpacing.xl),
            GBTLoading(
              message: context.l10n(
                ko: '미디어 삭제 요청 목록을 불러오는 중...',
                en: 'Loading media deletion requests...',
                ja: 'メディア削除リクエストリストを読み込んでいます...',
              ),
            ),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: context.l10n(
                ko: '미디어 삭제 원장',
                en: 'Media deletion ledger',
                ja: 'メディア削除原簿',
              ),
              description: context.l10n(
                ko: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
                en: 'Check the scope of linked content before deleting.',
                ja: '関連コンテンツの範囲を確認してから削除してください。',
              ),
            ),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: context.l10n(
                ko: '미디어 삭제 요청 목록을 불러오지 못했어요',
                en: 'Failed to load media deletion requests.',
                ja: 'メディア削除リクエストリストを読み込めませんでした。',
              ),
              onRetry: () => ref
                  .read(adminMediaDeletionsControllerProvider.notifier)
                  .load(forceRefresh: true),
            ),
          ],
        ),
        data: (requests) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: context.l10n(
                ko: '미디어 삭제 원장',
                en: 'Media deletion ledger',
                ja: 'メディア削除原簿',
              ),
              description: context.l10n(
                ko: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
                en: 'Check the scope of linked content before deleting.',
                ja: '関連コンテンツの範囲を確認してから削除してください。',
              ),
            ),
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 96),
                child: GBTEmptyState(
                  message: context.l10n(
                    ko: '현재 처리할 미디어 삭제 요청이 없습니다',
                    en: 'No media deletion requests to process right now.',
                    ja: '現在処理対象のメディア削除リクエストはありません。',
                  ),
                ),
              )
            else
              ...requests.map(
                (item) => _MediaDeletionRequestCard(
                  request: item,
                  isMutating: state.isMutating,
                ),
              ),
            const SizedBox(height: GBTSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// EN: A scrollable document-index filter with accessible touch targets.
/// KO: 접근성 터치 영역을 갖춘 가로 스크롤 문서 색인 필터입니다.
class AdminOpsFilterRail extends StatelessWidget {
  const AdminOpsFilterRail({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == labels.length - 1 ? 0 : GBTSpacing.xs,
              ),
              child: Semantics(
                button: true,
                selected: index == selectedIndex,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: GBTSpacing.touchTarget,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index == selectedIndex
                                ? colors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.sm2,
                          vertical: GBTSpacing.sm,
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: GBTTypography.labelMedium.copyWith(
                              color: index == selectedIndex
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: index == selectedIndex
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleRequestFilterRow extends ConsumerWidget {
  const _RoleRequestFilterRow({required this.selected});

  final AdminProjectRoleRequestFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = AdminProjectRoleRequestFilter.values;
    return AdminOpsFilterRail(
      labels: filters.map((filter) => filter.label).toList(growable: false),
      selectedIndex: filters.indexOf(selected),
      onSelected: (index) => ref
          .read(adminRoleRequestsControllerProvider.notifier)
          .load(filter: filters[index], forceRefresh: true),
    );
  }
}

class _RoleRequestCard extends ConsumerWidget {
  const _RoleRequestCard({required this.request, required this.isMutating});

  final AdminProjectRoleRequest request;
  final bool isMutating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(request.status);

    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: GBTSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCESS REQUEST',
                          style: GBTTypography.labelSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          request.projectName ??
                              request.projectCode ??
                              request.projectId,
                          style: GBTTypography.titleSmall.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Text(
                    request.statusLabel,
                    style: GBTTypography.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                '${request.requestedRoleLabel} · ${request.requesterName ?? request.requesterId ?? '-'}',
                style: GBTTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                request.justification,
                style: GBTTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                  height: 1.45,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                style: GBTTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (request.isPending) ...[
                const SizedBox(height: GBTSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: GBTSpacing.touchTarget,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                          onPressed: isMutating
                              ? null
                              : () => _reviewRequest(
                                  context,
                                  ref,
                                  decision: AdminRoleRequestDecision.reject,
                                ),
                          child: Text(
                            context.l10n(ko: '거절', en: 'Reject', ja: '却下する'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: GBTSpacing.touchTarget,
                        child: FilledButton(
                          onPressed: isMutating
                              ? null
                              : () => _reviewRequest(
                                  context,
                                  ref,
                                  decision: AdminRoleRequestDecision.approve,
                                ),
                          child: Text(
                            context.l10n(ko: '승인', en: 'Approve', ja: '承認する'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewRequest(
    BuildContext context,
    WidgetRef ref, {
    required AdminRoleRequestDecision decision,
  }) async {
    final memo = await _showMemoDialog(context, decision: decision);
    if (!context.mounted || memo == null) {
      return;
    }

    final result = await ref
        .read(adminRoleRequestsControllerProvider.notifier)
        .review(
          requestId: request.id,
          decision: decision,
          adminMemo: memo.trim().isEmpty ? null : memo.trim(),
        );

    if (!context.mounted) {
      return;
    }
    final message = result is Success<void>
        ? context.l10n(
            ko: '요청을 ${decision.label}했습니다',
            en: 'Request ${_decisionLabel(context, decision)}.',
            ja: 'リクエストを${_decisionLabel(context, decision)}しました。',
          )
        : (result is Err<void>
              ? result.failure.userMessage
              : context.l10n(
                  ko: '처리에 실패했습니다',
                  en: 'Failed to process the request.',
                  ja: '処理に失敗しました。',
                ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _showMemoDialog(
    BuildContext context, {
    required AdminRoleRequestDecision decision,
  }) async {
    final controller = TextEditingController();
    final memo = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.l10n(
              ko: '요청 ${decision.label}',
              en: '${_decisionLabel(context, decision)} request',
              ja: 'リクエストを${_decisionLabel(context, decision)}',
            ),
          ),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n(
                ko: '메모 (선택)',
                en: 'Memo (optional)',
                ja: 'メモ（任意）',
              ),
              hintText: context.l10n(
                ko: '운영 메모를 입력하세요',
                en: 'Enter an operations memo',
                ja: '運営メモを入力してください',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              style: decision == AdminRoleRequestDecision.reject
                  ? FilledButton.styleFrom(backgroundColor: GBTColors.error)
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(_decisionLabel(dialogContext, decision)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return memo;
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'GRANTED':
        return GBTColors.secondary;
      case 'REJECTED':
      case 'DENIED':
        return GBTColors.error;
      case 'CANCELED':
      case 'CANCELLED':
        return GBTColors.textTertiary;
      case 'PENDING':
      case 'OPEN':
      case 'REQUESTED':
      default:
        return GBTColors.primary;
    }
  }
}

class _MediaDeletionRequestCard extends ConsumerWidget {
  const _MediaDeletionRequestCard({
    required this.request,
    required this.isMutating,
  });

  final AdminMediaDeletionRequest request;
  final bool isMutating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: GBTSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELETION REQUEST',
                          style: GBTTypography.labelSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          request.entityTypeLabel,
                          style: GBTTypography.titleSmall.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Text(
                    request.status.label,
                    style: GBTTypography.labelSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '요청자 · ${request.requestedBy}',
                  en: 'Requested by · ${request.requestedBy}',
                  ja: 'リクエスト者 · ${request.requestedBy}',
                ),
                style: GBTTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                style: GBTTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                'UPLOAD · ${request.uploadId}',
                style: GBTTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: GBTSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    minimumSize: const Size(0, GBTSpacing.touchTarget),
                  ),
                  onPressed: isMutating
                      ? null
                      : () =>
                            _approve(context, ref, deleteLinkedContents: false),
                  child: Text(
                    context.l10n(
                      ko: '미디어만 삭제',
                      en: 'Delete media only',
                      ja: 'メディアのみ削除する',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    minimumSize: const Size(0, GBTSpacing.touchTarget),
                  ),
                  onPressed: isMutating
                      ? null
                      : () =>
                            _approve(context, ref, deleteLinkedContents: true),
                  child: Text(
                    context.l10n(
                      ko: '연관 콘텐츠도 삭제',
                      en: 'Delete linked content too',
                      ja: '関連コンテンツも削除する',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, GBTSpacing.touchTarget),
                  ),
                  onPressed: isMutating ? null : () => _reject(context, ref),
                  child: Text(context.l10n(ko: '반려', en: 'Reject', ja: '却下する')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref, {
    required bool deleteLinkedContents,
  }) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.l10n(
              ko: '삭제 요청 승인',
              en: 'Approve deletion request',
              ja: '削除リクエストを承認',
            ),
          ),
          content: Text(
            deleteLinkedContents
                ? context.l10n(
                    ko: '해당 미디어와 연관 게시글/장소후기를 함께 삭제합니다. 진행할까요?',
                    en: 'This will delete the media and its linked posts/place reviews. Continue?',
                    ja: 'このメディアと関連する投稿・場所レビューも削除します。続けますか？',
                  )
                : context.l10n(
                    ko: '해당 미디어만 삭제합니다. 진행할까요?',
                    en: 'This will delete only the media. Continue?',
                    ja: 'このメディアのみ削除します。続けますか？',
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GBTColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n(ko: '승인', en: 'Approve', ja: '承認する')),
            ),
          ],
        );
      },
    );
    if (shouldProceed != true || !context.mounted) {
      return;
    }

    final result = await ref
        .read(adminMediaDeletionsControllerProvider.notifier)
        .approve(
          requestId: request.id,
          deleteLinkedContents: deleteLinkedContents,
        );
    if (!context.mounted) {
      return;
    }
    final message = result is Success<void>
        ? context.l10n(
            ko: '삭제 요청을 승인했습니다',
            en: 'Deletion request approved.',
            ja: '削除リクエストを承認しました。',
          )
        : (result is Err<void>
              ? result.failure.userMessage
              : context.l10n(
                  ko: '처리에 실패했습니다',
                  en: 'Failed to process the request.',
                  ja: '処理に失敗しました。',
                ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(adminMediaDeletionsControllerProvider.notifier)
        .reject(requestId: request.id);
    if (!context.mounted) {
      return;
    }
    final message = result is Success<void>
        ? context.l10n(
            ko: '삭제 요청을 반려했습니다',
            en: 'Deletion request rejected.',
            ja: '削除リクエストを却下しました。',
          )
        : (result is Err<void>
              ? result.failure.userMessage
              : context.l10n(
                  ko: '처리에 실패했습니다',
                  en: 'Failed to process the request.',
                  ja: '処理に失敗しました。',
                ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ========================================
// EN: Report filter row — custom InkWell chip style (no ChoiceChip)
// KO: 신고 필터 행 — ChoiceChip 없이 커스텀 InkWell 칩 스타일
// ========================================

class _ReportFilterRow extends ConsumerWidget {
  const _ReportFilterRow({required this.selected});

  final AdminReportFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = AdminReportFilter.values;
    return AdminOpsFilterRail(
      labels: filters.map((filter) => filter.label).toList(growable: false),
      selectedIndex: filters.indexOf(selected),
      onSelected: (index) => ref
          .read(adminReportsControllerProvider.notifier)
          .load(filter: filters[index], forceRefresh: true),
    );
  }
}

// EN: Borderless moderation record that opens the existing action sheet.
// KO: 기존 처리 액션 시트를 여는 테두리 없는 모더레이션 기록.

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report, required this.isMutating});

  final AdminCommunityReport report;
  final bool isMutating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final palette = _paletteFor(report.status);

    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
            ),
          ),
          child: Semantics(
            button: true,
            label:
                '${report.status.label} ${report.targetLabel} ${report.reason}',
            child: InkWell(
              onTap: isMutating
                  ? null
                  : () => _showReportActionsSheet(context, ref, report),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 88),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            report.status.label,
                            style: GBTTypography.labelSmall.copyWith(
                              color: palette.foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: GBTSpacing.sm),
                          Expanded(
                            child: Text(
                              report.targetLabel,
                              style: GBTTypography.labelSmall.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: GBTSpacing.iconSm,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      Text(
                        report.reason,
                        style: GBTTypography.titleSmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (report.previewText != null &&
                          report.previewText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: GBTSpacing.xs),
                          child: Text(
                            report.previewText!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GBTTypography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: GBTSpacing.sm),
                      Text(
                        context.l10n(
                          ko: '접수 · ${DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt)}',
                          en: 'Received · ${DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt)}',
                          ja: '受付 · ${DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt)}',
                        ),
                        style: GBTTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        context.l10n(
                          ko: '담당 · ${report.assigneeName ?? '미할당'}',
                          en: 'Assignee · ${report.assigneeName ?? 'Unassigned'}',
                          ja: '担当 · ${report.assigneeName ?? '未割当'}',
                        ),
                        style: GBTTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportActionsSheet(
    BuildContext context,
    WidgetRef ref,
    AdminCommunityReport report,
  ) async {
    final action = await showModalBottomSheet<_ReportAction>(
      context: context,
      builder: (_) => _ReportActionSheet(report: report),
    );
    if (!context.mounted || action == null) {
      return;
    }

    final notifier = ref.read(adminReportsControllerProvider.notifier);
    final profile = ref.read(userProfileControllerProvider).valueOrNull;

    Result<void> result;
    switch (action) {
      case _ReportAction.assignToMe:
        final userId = profile?.id;
        if (userId == null || userId.isEmpty) {
          _showSnackBar(
            context,
            context.l10n(
              ko: '담당자 할당을 위해 사용자 정보가 필요해요',
              en: 'User information is required to assign an assignee.',
              ja: '担当者を割り当てるにはユーザー情報が必要です。',
            ),
          );
          return;
        }
        result = await notifier.assignToUser(
          reportId: report.id,
          assigneeUserId: userId,
        );
      case _ReportAction.markInReview:
        result = await notifier.updateStatus(
          reportId: report.id,
          status: AdminReportStatus.inReview,
        );
      case _ReportAction.markResolved:
        result = await notifier.updateStatus(
          reportId: report.id,
          status: AdminReportStatus.resolved,
        );
      case _ReportAction.reject:
        result = await notifier.updateStatus(
          reportId: report.id,
          status: AdminReportStatus.rejected,
        );
    }

    if (!context.mounted) {
      return;
    }

    if (result is Success<void>) {
      _showSnackBar(
        context,
        context.l10n(
          ko: '요청이 반영되었습니다',
          en: 'Request applied.',
          ja: 'リクエストを反映しました。',
        ),
      );
      return;
    }

    if (result is Err<void>) {
      _showSnackBar(context, result.failure.userMessage);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ReportAction { assignToMe, markInReview, markResolved, reject }

// EN: Report action sheet as a compact moderation document.
// KO: 신고 처리 액션 시트를 컴팩트한 모더레이션 문서로 표시합니다.

class _ReportActionSheet extends StatelessWidget {
  const _ReportActionSheet({required this.report});

  final AdminCommunityReport report;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: GBTSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
                GBTSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODERATION ACTION',
                    style: GBTTypography.labelSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    context.l10n(ko: '신고 처리', en: 'Handle report', ja: '通報処理'),
                    style: GBTTypography.titleLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    report.reason,
                    style: GBTTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            _ActionSheetItem(
              icon: Icons.person_add_alt_1,
              iconColor: colors.primary,
              title: context.l10n(
                ko: '나에게 할당',
                en: 'Assign to me',
                ja: '自分に割り当てる',
              ),
              subtitle:
                  report.assigneeName ??
                  context.l10n(
                    ko: '현재 미할당',
                    en: 'Currently unassigned',
                    ja: '現在未割当',
                  ),
              onTap: () => Navigator.of(context).pop(_ReportAction.assignToMe),
            ),
            _ActionSheetItem(
              icon: Icons.rule_outlined,
              iconColor: colors.primary,
              title: context.l10n(
                ko: '검토 중으로 변경',
                en: 'Mark as in review',
                ja: '確認中に変更',
              ),
              onTap: () =>
                  Navigator.of(context).pop(_ReportAction.markInReview),
            ),
            _ActionSheetItem(
              icon: Icons.check_circle_outline,
              iconColor: colors.secondary,
              title: context.l10n(
                ko: '조치 완료로 변경',
                en: 'Mark as resolved',
                ja: '対応完了に変更',
              ),
              onTap: () =>
                  Navigator.of(context).pop(_ReportAction.markResolved),
            ),
            _ActionSheetItem(
              icon: Icons.block_outlined,
              iconColor: colors.error,
              title: context.l10n(ko: '반려 처리', en: 'Reject', ja: '却下処理'),
              onTap: () => Navigator.of(context).pop(_ReportAction.reject),
            ),
            const SizedBox(height: GBTSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// EN: Borderless action row with a minimum 56px interaction target.
/// KO: 최소 56px 상호작용 영역을 갖춘 테두리 없는 액션 행입니다.
class _ActionSheetItem extends StatelessWidget {
  const _ActionSheetItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: GBTSpacing.iconSm, color: iconColor),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: iconColor == colors.error
                              ? colors.error
                              : colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          subtitle!,
                          style: GBTTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: GBTSpacing.iconSm,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: UI palette for report states.
/// KO: 신고 상태별 UI 색상 팔레트.
class AdminReportStatusPalette {
  const AdminReportStatusPalette({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

String _decisionLabel(BuildContext context, AdminRoleRequestDecision decision) {
  switch (decision) {
    case AdminRoleRequestDecision.approve:
      return context.l10n(ko: '승인', en: 'approved', ja: '承認');
    case AdminRoleRequestDecision.reject:
      return context.l10n(ko: '거절', en: 'rejected', ja: '却下');
  }
}

AdminReportStatusPalette _paletteFor(AdminReportStatus status) {
  switch (status) {
    case AdminReportStatus.open:
      return const AdminReportStatusPalette(
        foreground: GBTColors.errorDark,
        background: GBTColors.errorLight,
      );
    case AdminReportStatus.inReview:
      return const AdminReportStatusPalette(
        foreground: GBTColors.primary,
        background: GBTColors.primaryLight,
      );
    case AdminReportStatus.resolved:
      return const AdminReportStatusPalette(
        foreground: GBTColors.secondary,
        background: GBTColors.secondaryLight,
      );
    case AdminReportStatus.rejected:
    case AdminReportStatus.duplicate:
    case AdminReportStatus.dismissed:
      return const AdminReportStatusPalette(
        foreground: GBTColors.textSecondary,
        background: GBTColors.surfaceVariant,
      );
    case AdminReportStatus.unknown:
      return const AdminReportStatusPalette(
        foreground: GBTColors.primary,
        background: GBTColors.primaryLight,
      );
  }
}
