/// EN: Admin operations center page.
/// KO: 운영/관리자 센터 페이지.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../../features/settings/application/settings_controller.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../application/admin_ops_controller.dart';
import '../../domain/entities/admin_ops_entities.dart';

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
        appBar: gbtStandardAppBar(context, title: '관리자 도구'),
        body: profileState.when(
          loading: () => const Center(child: GBTLoading(message: '권한 확인 중...')),
          error: (error, _) => Center(
            child: Padding(
              padding: GBTSpacing.paddingPage,
              child: GBTErrorState(
                message: '권한 정보를 확인하지 못했어요',
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
      label: '운영 업무 영역',
      child: const SizedBox(
        height: 56,
        child: GBTSegmentedTabBar(
          height: 56,
          isScrollable: true,
          margin: EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.xs,
            GBTSpacing.md,
            GBTSpacing.xs,
          ),
          labelPadding: EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          tabs: [
            Tab(text: '개요'),
            Tab(text: '신고 관리'),
            Tab(text: '권한 요청'),
            Tab(text: '미디어 삭제'),
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
    return const GBTEmptyState(
      icon: Icons.lock_outline,
      title: '접근 권한이 없습니다',
      subtitle: '운영 권한이 확인된 계정만 접근할 수 있습니다.',
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
        children: const [
          SizedBox(height: 120),
          GBTLoading(message: '운영 지표를 불러오는 중...'),
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
              message: '운영 지표를 불러오지 못했어요',
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
        const GBTPageHeader(
          eyebrow: 'OPERATIONS LOG',
          title: '운영 대기 원장',
          description: '신고, 권한, 검증, 미디어 요청을 처리 순서대로 확인하세요.',
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
                      '현재 대기',
                      style: GBTTypography.labelMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      '${summary.totalPendingItems}건',
                      style: GBTTypography.displaySmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      hasUrgent
                          ? '신규 신고 ${summary.openReports}건을 먼저 확인해야 합니다.'
                          : '신규로 접수된 신고는 없습니다.',
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
        label: '신규 신고',
        value: summary.openReports,
        color: GBTColors.error,
        icon: Icons.flag,
      ),
      _StatCardData(
        label: '검토 중 신고',
        value: summary.inReviewReports,
        color: GBTColors.primary,
        icon: Icons.rule,
      ),
      _StatCardData(
        label: '권한 변경 요청',
        value: summary.pendingAccessGrantRequests,
        color: GBTColors.primary,
        icon: Icons.manage_accounts,
      ),
      _StatCardData(
        label: '인증 이의제기',
        value: summary.pendingVerificationAppeals,
        color: GBTColors.secondary,
        icon: Icons.gavel,
      ),
      _StatCardData(
        label: '삭제 요청',
        value: summary.pendingMediaDeletionRequests,
        color: GBTColors.error,
        icon: Icons.photo_library_outlined,
      ),
      _StatCardData(
        label: '활성 제재',
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
          '보조 지표',
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
            const _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: '신고 처리 원장',
              description: '접수 순서와 담당 상태를 기준으로 처리합니다.',
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            const GBTLoading(message: '신고 목록을 불러오는 중...'),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: '신고 처리 원장',
              description: '접수 순서와 담당 상태를 기준으로 처리합니다.',
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: '신고 목록을 불러오지 못했어요',
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
            const _AdminOpsTabHeader(
              eyebrow: 'COMMUNITY MODERATION',
              title: '신고 처리 원장',
              description: '접수 순서와 담당 상태를 기준으로 처리합니다.',
            ),
            _ReportFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.sm),
            if (reports.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 96),
                child: GBTEmptyState(message: '현재 처리할 신고가 없습니다'),
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
            const _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: '권한 요청 원장',
              description: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            const GBTLoading(message: '권한 요청 목록을 불러오는 중...'),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: '권한 요청 원장',
              description: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: '권한 요청 목록을 불러오지 못했어요',
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
            const _AdminOpsTabHeader(
              eyebrow: 'ACCESS DESK',
              title: '권한 요청 원장',
              description: '프로젝트 역할과 사유를 확인한 후 승인하세요.',
            ),
            _RoleRequestFilterRow(selected: state.filter),
            const SizedBox(height: GBTSpacing.sm),
            if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 96),
                child: GBTEmptyState(message: '현재 처리할 권한 요청이 없습니다'),
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
          children: const [
            _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: '미디어 삭제 원장',
              description: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
            ),
            SizedBox(height: GBTSpacing.xl),
            GBTLoading(message: '미디어 삭제 요청 목록을 불러오는 중...'),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GBTSpacing.paddingPage,
          children: [
            const _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: '미디어 삭제 원장',
              description: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
            ),
            const SizedBox(height: GBTSpacing.xl),
            GBTErrorState(
              message: '미디어 삭제 요청 목록을 불러오지 못했어요',
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
            const _AdminOpsTabHeader(
              eyebrow: 'MEDIA CONTROL',
              title: '미디어 삭제 원장',
              description: '연결된 콘텐츠 범위를 확인한 뒤 삭제를 진행하세요.',
            ),
            if (requests.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 96),
                child: GBTEmptyState(message: '현재 처리할 미디어 삭제 요청이 없습니다'),
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
                          child: const Text('거절'),
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
                          child: const Text('승인'),
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
        ? '요청을 ${decision.label}했습니다'
        : (result is Err<void> ? result.failure.userMessage : '처리에 실패했습니다');
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
          title: Text('요청 ${decision.label}'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '운영 메모를 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              style: decision == AdminRoleRequestDecision.reject
                  ? FilledButton.styleFrom(backgroundColor: GBTColors.error)
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(decision.label),
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
                '요청자 · ${request.requestedBy}',
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
                  child: const Text('미디어만 삭제'),
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
                  child: const Text('연관 콘텐츠도 삭제'),
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
                  child: const Text('반려'),
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
          title: const Text('삭제 요청 승인'),
          content: Text(
            deleteLinkedContents
                ? '해당 미디어와 연관 게시글/장소후기를 함께 삭제합니다. 진행할까요?'
                : '해당 미디어만 삭제합니다. 진행할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GBTColors.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('승인'),
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
        ? '삭제 요청을 승인했습니다'
        : (result is Err<void> ? result.failure.userMessage : '처리에 실패했습니다');
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
        ? '삭제 요청을 반려했습니다'
        : (result is Err<void> ? result.failure.userMessage : '처리에 실패했습니다');
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
                        '접수 · ${DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt)}',
                        style: GBTTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '담당 · ${report.assigneeName ?? '미할당'}',
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
          _showSnackBar(context, '담당자 할당을 위해 사용자 정보가 필요해요');
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
      _showSnackBar(context, '요청이 반영되었습니다');
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
                    '신고 처리',
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
              title: '나에게 할당',
              subtitle: report.assigneeName ?? '현재 미할당',
              onTap: () => Navigator.of(context).pop(_ReportAction.assignToMe),
            ),
            _ActionSheetItem(
              icon: Icons.rule_outlined,
              iconColor: colors.primary,
              title: '검토 중으로 변경',
              onTap: () =>
                  Navigator.of(context).pop(_ReportAction.markInReview),
            ),
            _ActionSheetItem(
              icon: Icons.check_circle_outline,
              iconColor: colors.secondary,
              title: '조치 완료로 변경',
              onTap: () =>
                  Navigator.of(context).pop(_ReportAction.markResolved),
            ),
            _ActionSheetItem(
              icon: Icons.block_outlined,
              iconColor: colors.error,
              title: '반려 처리',
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
