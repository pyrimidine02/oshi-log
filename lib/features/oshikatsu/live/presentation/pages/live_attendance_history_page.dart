/// EN: Live attendance history body widgets with timeline-style cards.
/// KO: 타임라인 스타일 카드 기반의 라이브 방문 기록 바디 위젯.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/core/router/app_router.dart';
import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';
import 'package:oshi_log/core/widgets/common/gbt_image.dart';
import 'package:oshi_log/core/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';

class LiveAttendanceHistoryBody extends ConsumerStatefulWidget {
  const LiveAttendanceHistoryBody({super.key});

  @override
  ConsumerState<LiveAttendanceHistoryBody> createState() =>
      _LiveAttendanceHistoryBodyState();
}

class _LiveAttendanceHistoryBodyState
    extends ConsumerState<LiveAttendanceHistoryBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// EN: Builds the project-grouped list of attendance records.
  ///     Groups items by [LiveAttendanceHistoryRecord.projectKey] in insertion
  ///     order (most recently attended project first).
  /// KO: 출석 기록을 프로젝트별로 그룹화한 리스트를 구성합니다.
  ///     [LiveAttendanceHistoryRecord.projectKey]로 삽입 순서(최근 참여 프로젝트
  ///     우선) 대로 그룹화합니다.
  Widget _buildGroupedList(BuildContext context) {
    final historyState = ref.watch(liveAttendanceHistoryControllerProvider);

    // EN: Build projectKey → name lookup from the projects provider.
    // KO: 프로젝트 프로바이더에서 projectKey → 이름 조회 맵을 구성합니다.
    final projectNameOf = <String, String>{};
    ref.watch(projectsControllerProvider).whenData((projects) {
      for (final p in projects) {
        if (p.code.isNotEmpty) projectNameOf[p.code] = p.name;
        projectNameOf[p.id] = p.name;
      }
    });

    // EN: Group records by projectKey, preserving insertion order.
    // KO: 삽입 순서를 유지하며 projectKey별로 기록을 그룹화합니다.
    final groups = <String, List<LiveAttendanceHistoryRecord>>{};
    for (final record in historyState.items) {
      (groups[record.projectKey] ??= []).add(record);
    }

    // EN: Build a flat children list: project header → cards per project.
    // KO: 평탄한 children 리스트 구성: 프로젝트 헤더 → 프로젝트별 카드.
    final children = <Widget>[];
    for (final projectKey in groups.keys) {
      final projectName = projectNameOf[projectKey] ?? projectKey;
      children.add(_LiveProjectHeader(label: projectName));
      for (final record in groups[projectKey]!) {
        children.add(_HistoryCard(record: record));
        children.add(const SizedBox(height: GBTSpacing.sm));
      }
    }
    if (historyState.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.md,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
      ),
      children: children,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 220) {
      return;
    }
    ref.read(liveAttendanceHistoryControllerProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(liveAttendanceHistoryControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(liveAttendanceHistoryControllerProvider.notifier)
          .load(forceRefresh: true),
      child: historyState.isInitialLoading
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 160),
                Center(
                  child: GBTLoading(
                    message: context.l10n(
                      ko: '라이브 방문 기록을 불러오는 중...',
                      en: 'Loading live attendance history...',
                      ja: 'ライブ参加履歴を読み込み中...',
                    ),
                  ),
                ),
              ],
            )
          : historyState.failure != null
          ? Builder(
              builder: (context) {
                final failure = historyState.failure;
                final message = failure is Failure
                    ? failure.userMessage
                    : context.l10n(
                        ko: '라이브 방문 기록을 불러오지 못했어요.',
                        en: 'Could not load live attendance history.',
                        ja: 'ライブ参加履歴を読み込めませんでした。',
                      );
                return _EmptyState(
                  message: message,
                  actionLabel: context.l10n(
                    ko: '다시 시도',
                    en: 'Retry',
                    ja: '再試行',
                  ),
                  onTap: () => ref
                      .read(liveAttendanceHistoryControllerProvider.notifier)
                      .load(forceRefresh: true),
                );
              },
            )
          : historyState.items.isEmpty
          ? _EmptyState(
              message: context.l10n(
                ko: '아직 라이브 방문 기록이 없습니다.\n라이브 상세에서 방문 토글을 켜보세요.',
                en: 'No live attendance records yet.\nTurn on attendance from a live detail page.',
                ja: 'まだライブ参加記録がありません。\nライブ詳細で参加トグルをオンにしてください。',
              ),
            )
          : _buildGroupedList(context),
    );
  }
}

// ---------------------------------------------------------------------------
// EN: Project section header for live attendance history.
// KO: 라이브 방문 기록 프로젝트 섹션 헤더.
// ---------------------------------------------------------------------------

class _LiveProjectHeader extends StatelessWidget {
  const _LiveProjectHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, GBTSpacing.lg, 0, GBTSpacing.xs),
      child: Text(
        label,
        style: GBTTypography.headlineSmall.copyWith(
          color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final LiveAttendanceHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorderSubtle : GBTColors.border;
    final surfaceColor = isDark
        ? GBTColors.darkSurfaceElevated
        : GBTColors.surface;
    final secondaryText = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryText = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final statusColor = _statusColor(isDark, record.status);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        onTap: () => context.goToEventDetail(record.eventId),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (record.bannerUrl?.isNotEmpty == true)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(GBTSpacing.radiusMd),
                  ),
                  child: SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: GBTImage(
                      imageUrl: record.bannerUrl!,
                      fit: BoxFit.cover,
                      semanticLabel: context.l10n(
                        ko: '${record.titleFallback} 포스터',
                        en: '${record.titleFallback} poster',
                        ja: '${record.titleFallback} ポスター',
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: GBTSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.titleFallback,
                            style: GBTTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: GBTSpacing.xs),
                        _StatusBadge(
                          label: _statusLabel(context, record.status),
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      record.showStartTime != null
                          ? context.l10n(
                              ko: '공연 일정: ${_formatDate(record.showStartTime)}',
                              en: 'Event: ${_formatDate(record.showStartTime)}',
                              ja: '公演日程: ${_formatDate(record.showStartTime)}',
                            )
                          : context.l10n(
                              ko: '공연 일정 정보 없음',
                              en: 'No event schedule info',
                              ja: '公演日程情報なし',
                            ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      context.l10n(
                        ko: '프로젝트 ${record.projectKey} · 기록 ${_formatDate(record.attendedAt)}',
                        en: 'Project ${record.projectKey} · Recorded ${_formatDate(record.attendedAt)}',
                        ja: 'プロジェクト ${record.projectKey} ・ 記録 ${_formatDate(record.attendedAt)}',
                      ),
                      style: GBTTypography.labelSmall.copyWith(
                        color: tertiaryText,
                      ),
                    ),
                    if (record.verificationMethod?.isNotEmpty == true) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Text(
                        context.l10n(
                          ko: '인증 방식: ${record.verificationMethod}',
                          en: 'Verification: ${record.verificationMethod}',
                          ja: '認証方式: ${record.verificationMethod}',
                        ),
                        style: GBTTypography.labelSmall.copyWith(
                          color: tertiaryText,
                        ),
                      ),
                    ],
                    if (record.isVerified && !record.canUndo) ...[
                      const SizedBox(height: GBTSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: tertiaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              context.l10n(
                                ko: '검증 완료 상태라 취소할 수 없어요.',
                                en: 'This verified record cannot be undone.',
                                ja: '検証済みのため取り消せません。',
                              ),
                              style: GBTTypography.labelSmall.copyWith(
                                color: tertiaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Text(
        label,
        style: GBTTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.actionLabel, this.onTap});

  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 56,
                    color: GBTColors.textTertiary,
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: GBTColors.textSecondary,
                    ),
                  ),
                  if (actionLabel != null && onTap != null) ...[
                    const SizedBox(height: GBTSpacing.md),
                    FilledButton(onPressed: onTap, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _statusLabel(BuildContext context, String status) {
  final normalized = LiveAttendanceStatus.normalize(status);
  return switch (normalized) {
    LiveAttendanceStatus.verified => context.l10n(
      ko: '검증 완료',
      en: 'Verified',
      ja: '検証完了',
    ),
    LiveAttendanceStatus.declared => context.l10n(
      ko: '검증 전',
      en: 'Declared',
      ja: '検証前',
    ),
    _ => context.l10n(ko: '미기록', en: 'None', ja: '未記録'),
  };
}

Color _statusColor(bool isDark, String status) {
  final normalized = LiveAttendanceStatus.normalize(status);
  return switch (normalized) {
    LiveAttendanceStatus.verified =>
      isDark ? GBTColors.darkPrimary : GBTColors.primary,
    LiveAttendanceStatus.declared =>
      isDark ? GBTColors.darkSecondary : GBTColors.secondary,
    _ => isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
  };
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return DateFormat('yyyy.MM.dd HH:mm').format(value.toLocal());
}
