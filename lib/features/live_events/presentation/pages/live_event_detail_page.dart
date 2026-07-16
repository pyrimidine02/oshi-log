/// EN: Live event detail page with info and attendance toggle.
/// KO: 정보 및 방문 토글을 포함한 라이브 이벤트 상세 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/cards/gbt_ticket_card.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../favorites/application/favorites_controller.dart';
import '../../../favorites/domain/entities/favorite_entities.dart';
import '../../../music/application/music_controller.dart';
import '../../../music/domain/entities/music_entities.dart';
import '../../../../core/widgets/common/registrant_credit_widget.dart';
import '../../application/live_events_controller.dart';
import '../../domain/entities/live_event_entities.dart';

/// EN: Live event detail page widget
/// KO: 라이브 이벤트 상세 페이지 위젯
class LiveEventDetailPage extends ConsumerWidget {
  const LiveEventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveEventDetailControllerProvider(eventId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Scaffold(
      body: CustomScrollView(
        slivers: state.when(
          loading: () {
            // EN: Skeleton loading — matches poster + info card layout.
            // KO: 스켈레톤 로딩 — 포스터 + 정보 카드 레이아웃에 맞춤.
            final posterH = (MediaQuery.sizeOf(context).width * 1.45).clamp(
              300.0,
              620.0,
            );
            return [
              SliverAppBar(
                expandedHeight: posterH,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: GBTSpacing.xs),
                  child: _OverlayIconButton(
                    tooltip: '뒤로 가기',
                    icon: _platformBackIcon(context),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: GBTShimmer(
                    child: Container(color: surfaceVariantColor),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: GBTShimmer(
                  child: Padding(
                    padding: GBTSpacing.paddingPage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GBTShimmerContainer(height: 28, width: 220),
                        const SizedBox(height: GBTSpacing.xs),
                        GBTShimmerContainer(height: 20, width: 80),
                        const SizedBox(height: GBTSpacing.lg),
                        // EN: Info card row skeleton
                        // KO: 정보 카드 행 스켈레톤
                        SizedBox(
                          height: 88,
                          child: Row(
                            children: [
                              Expanded(
                                child: GBTShimmerContainer(
                                  height: 88,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(width: GBTSpacing.sm),
                              Expanded(
                                child: GBTShimmerContainer(
                                  height: 88,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(width: GBTSpacing.sm),
                              Expanded(
                                child: GBTShimmerContainer(
                                  height: 88,
                                  width: double.infinity,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.lg),
                        GBTShimmerContainer(height: 52, width: double.infinity),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          error: (error, _) {
            final message = error is Failure
                ? error.userMessage
                : '라이브 정보를 불러오지 못했어요';
            return [
              SliverFillRemaining(
                child: Center(
                  child: GBTErrorState(
                    message: message,
                    onRetry: () => ref
                        .read(
                          liveEventDetailControllerProvider(eventId).notifier,
                        )
                        .load(forceRefresh: true),
                  ),
                ),
              ),
            ];
          },
          data: (event) => _buildContent(context, ref, event),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    LiveEventDetail event,
  ) {
    final posterExpandedHeight = (MediaQuery.sizeOf(context).width * 1.45)
        .clamp(300.0, 620.0);
    final topInset = MediaQuery.paddingOf(context).top;
    final posterTopOffset = topInset + GBTSpacing.lg2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final surfaceVariantColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final posterBackgroundTop = isDark
        ? const Color(0xFF1A1D22)
        : const Color(0xFFF2F4F7);
    final posterBackgroundBottom = isDark
        ? const Color(0xFF121418)
        : const Color(0xFFE8ECF3);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final attendanceState = ref.watch(
      liveAttendanceControllerProvider(event.id),
    );
    final setlistProjectId = event.projectIds.isNotEmpty
        ? event.projectIds.first
        : '';
    final AsyncValue<MusicLiveSetlist?> setlistState = setlistProjectId.isEmpty
        ? const AsyncData<MusicLiveSetlist?>(null)
        : ref
              .watch(
                liveEventSetlistProvider((
                  projectId: setlistProjectId,
                  liveEventId: event.id,
                )),
              )
              .whenData<MusicLiveSetlist?>((value) => value);
    final isFavorite = favoritesState.maybeWhen(
      data: (items) => items.any(
        (item) =>
            item.entityId == event.id && item.type == FavoriteType.liveEvent,
      ),
      orElse: () => false,
    );

    final isLive = event.status.toLowerCase() == 'live';
    final isUpcoming = event.showStartTime.isAfter(DateTime.now());
    final isDDay = event.dDayLabel == 'D-day';

    return [
      SliverAppBar(
        expandedHeight: posterExpandedHeight,
        pinned: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: GBTSpacing.xs),
          child: _OverlayIconButton(
            tooltip: '뒤로 가기',
            icon: _platformBackIcon(context),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: event.bannerUrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // EN: Neutral gradient background for letterbox area.
                    // KO: 레터박스 영역은 중립 그라데이션 배경으로 처리.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [posterBackgroundTop, posterBackgroundBottom],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        GBTSpacing.md,
                        posterTopOffset,
                        GBTSpacing.md,
                        GBTSpacing.lg,
                      ),
                      child: Hero(
                        tag: GBTHeroTags.eventPoster(event.id),
                        transitionOnUserGestures: true,
                        child: GBTImage(
                          imageUrl: event.bannerUrl!,
                          fit: BoxFit.contain,
                          semanticLabel: '${event.title} 포스터',
                        ),
                      ),
                    ),
                    // EN: Top gradient for button readability.
                    // KO: 버튼 가독성을 위한 상단 그라데이션.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Color(0x66000000),
                            Color(0x22000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                    // EN: LIVE badge — bottom-left corner, red glow.
                    // KO: LIVE 배지 — 좌하단 모서리, 빨간 글로우.
                    if (isLive)
                      Positioned(
                        bottom: GBTSpacing.md,
                        left: GBTSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GBTSpacing.sm,
                            vertical: GBTSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: GBTColors.live,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusXs,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: GBTColors.live.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PulsingDot(),
                              const SizedBox(width: GBTSpacing.xs),
                              Text(
                                'LIVE',
                                style: GBTTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // EN: D-day badge — bottom-right, secondary accent.
                    // KO: D-day 배지 — 우하단, 보조 색상 강조.
                    if (isUpcoming && !isLive)
                      Positioned(
                        bottom: GBTSpacing.md,
                        right: GBTSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GBTSpacing.sm,
                            vertical: GBTSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isDDay
                                ? GBTColors.secondary
                                : Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusXs,
                            ),
                            boxShadow: isDDay
                                ? [
                                    BoxShadow(
                                      color: GBTColors.secondary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            isDDay ? 'D-DAY' : event.dDayLabel,
                            style: GBTTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Container(
                  color: surfaceVariantColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                        const SizedBox(height: GBTSpacing.md),
                        Text(
                          '이벤트 포스터',
                          style: GBTTypography.bodyMedium.copyWith(
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        actions: [
          _OverlayIconButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
            onPressed: () => ref
                .read(favoritesControllerProvider.notifier)
                .toggleFavorite(
                  entityId: event.id,
                  type: FavoriteType.liveEvent,
                  isCurrentlyFavorite: isFavorite,
                ),
          ),
          _OverlayIconButton(
            icon: Icons.share_outlined,
            tooltip: '이벤트 공유',
            onPressed: () {
              // EN: TODO: Share event
              // KO: TODO: 이벤트 공유
            },
          ),
          // EN: Trailing gap — aligns last button away from screen edge.
          // KO: 우측 끝 여백 — 마지막 버튼을 화면 가장자리에서 띄움.
          const SizedBox(width: GBTSpacing.xs),
        ],
      ),
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: GBTSpacing.paddingPage,
              // EN: The "concert ticket" moment — title/status in the body,
              // date·time·attendance stamp in the tear-off stub.
              // KO: "콘서트 티켓" 모먼트 — 본문에 제목/상태, 절취선 아래
              // 스텁에 날짜·시간·참석 스탬프를 배치합니다.
              child: GBTTicketCard(
                stubHeight: 64,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GBTTypography.headlineSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    Row(
                      children: [
                        // EN: Status chip — color-coded per status.
                        // KO: 상태 칩 — 상태별 색상 코딩.
                        _StatusChip(status: event.status, isDark: isDark),
                        const SizedBox(width: GBTSpacing.sm),
                        Icon(
                          Icons.people_outline_rounded,
                          size: GBTSpacing.iconXs,
                          color: tertiaryColor,
                        ),
                        const SizedBox(width: GBTSpacing.xxs),
                        Expanded(
                          child: Text(
                            event.metaLabel,
                            style: GBTTypography.labelSmall.copyWith(
                              color: tertiaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                stub: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.dateLabel,
                            style: GBTTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDDay
                                  ? (isDark
                                        ? GBTColors.darkSecondary
                                        : GBTColors.secondary)
                                  : (isDark
                                        ? GBTColors.darkTextPrimary
                                        : GBTColors.textPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '개장 ${event.doorTimeLabel} · 시작 ${event.timeLabel}',
                            style: GBTTypography.labelSmall.copyWith(
                              color: tertiaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // EN: Attendance stamp CTA — the ticket stub's tear-off action.
                    // KO: 참석 스탬프 CTA — 티켓 스텁의 절취 액션.
                    _AttendanceStubButton(
                      state: attendanceState,
                      onToggle: (attended) =>
                          _toggleAttendance(context, ref, event, attended),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: GBTSpacing.lg),
                  _LiveAttendanceSection(state: attendanceState),
                  const SizedBox(height: GBTSpacing.lg),
                  _LiveSetlistSection(
                    state: setlistState,
                    projectId: setlistProjectId,
                    liveEventId: event.id,
                  ),
                  const SizedBox(height: GBTSpacing.lg),
                  const Divider(),
                  const SizedBox(height: GBTSpacing.lg),
                  Text(
                    '공연 정보',
                    style: GBTTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  // EN: Expandable description — collapses to 3 lines with "더 보기" toggle.
                  // KO: 접힘 가능한 설명 — 3줄로 축약하고 "더 보기" 토글 제공.
                  _ExpandableDescription(
                    text: event.description ?? '공연 정보가 없습니다.',
                  ),
                  const SizedBox(height: GBTSpacing.lg),
                  Text(
                    '티켓',
                    style: GBTTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  // EN: Ticket section — button if URL exists, message if not.
                  // KO: 티켓 섹션 — URL이 있으면 버튼, 없으면 안내 메시지.
                  if (event.ticketUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchUrl(event.ticketUrl!),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('티켓 구매하기'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      event.ticketUrl!,
                      style: GBTTypography.bodySmall.copyWith(
                        color: tertiaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: GBTSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: surfaceVariantColor,
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        '티켓 정보가 없습니다',
                        style: GBTTypography.bodyMedium.copyWith(
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: GBTSpacing.lg),
                  // EN: Contributors credit — who registered and edited this live event.
                  // KO: 기여자 크레딧 — 이 라이브 이벤트를 등록하고 수정한 사람을 표시합니다.
                  ContributorsCreditWidget(
                    entityType: 'lives',
                    entityId: event.id,
                  ),
                  const SizedBox(height: GBTSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _toggleAttendance(
    BuildContext context,
    WidgetRef ref,
    LiveEventDetail event,
    bool attended,
  ) async {
    final result = await ref
        .read(liveAttendanceControllerProvider(event.id).notifier)
        .toggle(attended);
    if (!context.mounted) {
      return;
    }
    final failure = result.failureOrNull;
    if (failure != null) {
      final message = _attendanceErrorMessage(context, failure);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _LiveAttendanceSection extends StatelessWidget {
  const _LiveAttendanceSection({required this.state});

  final LiveAttendanceViewState state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attendance = state.attendance;
    final cardColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final bodyColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final statusColor = _attendanceStatusColor(isDark, attendance.status);
    final isOffLocked = attendance.attended && !attendance.canUndo;

    return Container(
      width: double.infinity,
      padding: GBTSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN: Status readout — the primary toggle now lives on the ticket
          // stub above; this panel reflects state and sync feedback only.
          // KO: 상태 표시 — 메인 토글은 위쪽 티켓 스텁으로 이동했으며,
          // 이 영역은 상태와 동기화 피드백만 보여줍니다.
          Text(
            context.l10n(ko: '라이브 방문', en: 'Live attendance', ja: 'ライブ参加'),
            style: GBTTypography.titleSmall.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: GBTSpacing.xxs),
          Text(
            _attendanceStatusLabel(context, attendance.status),
            style: GBTTypography.bodySmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.isLoading) ...[
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '서버 상태를 동기화하는 중이에요.',
                en: 'Syncing attendance status from server.',
                ja: 'サーバー状態を同期しています。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: bodyColor),
            ),
          ] else if (state.isSubmitting) ...[
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '방문 상태를 업데이트하는 중이에요.',
                en: 'Updating attendance status.',
                ja: '参加状態を更新しています。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: bodyColor),
            ),
          ] else if (isOffLocked) ...[
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '검증 완료된 방문 기록은 취소할 수 없어요.',
                en: 'Verified attendance cannot be undone.',
                ja: '検証済みの参加記録は取り消せません。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: bodyColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveSetlistSection extends StatelessWidget {
  const _LiveSetlistSection({
    required this.state,
    required this.projectId,
    required this.liveEventId,
  });

  final AsyncValue<MusicLiveSetlist?> state;
  final String projectId;
  final String liveEventId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    return Container(
      width: double.infinity,
      padding: GBTSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n(ko: '세트리스트', en: 'Setlist', ja: 'セットリスト'),
                style: GBTTypography.titleSmall.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.sm),
          state.when(
            data: (setlist) {
              if (setlist == null || setlist.items.isEmpty) {
                return Text(
                  context.l10n(
                    ko: '세트리스트 정보 준비중',
                    en: 'Setlist will be available soon.',
                    ja: 'セットリスト情報は準備中です。',
                  ),
                  style: GBTTypography.bodySmall.copyWith(
                    color: secondaryColor,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.sm,
                      vertical: GBTSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark ? GBTColors.darkPrimary : GBTColors.primary)
                              .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        GBTSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      'Status: ${setlist.eventStatus}',
                      style: GBTTypography.labelSmall.copyWith(
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  ...setlist.items.map((item) {
                    final hasSongLink =
                        item.hasSongLink && projectId.isNotEmpty;
                    final subtitleParts = <String>[
                      if ((item.unitName ?? '').trim().isNotEmpty)
                        item.unitName!,
                      if ((item.versionCode ?? '').trim().isNotEmpty)
                        item.versionCode!,
                      item.segmentType,
                    ];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 18,
                        child: Text(
                          '${item.order}',
                          style: GBTTypography.bodyMedium.copyWith(
                            color: tertiaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        item.songTitle ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: item.isEncore
                          ? const Icon(Icons.star_rounded, size: 16)
                          : null,
                      onTap: !hasSongLink
                          ? null
                          : () => context.goToSongDetail(
                              item.songId!,
                              projectId: projectId,
                              eventId: liveEventId,
                            ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Text(
              error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '세트리스트를 불러오지 못했어요.',
                      en: 'Failed to load setlist.',
                      ja: 'セットリストの読み込みに失敗しました。',
                    ),
              style: GBTTypography.bodySmall.copyWith(color: secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

String _attendanceStatusLabel(BuildContext context, String status) {
  final normalized = LiveAttendanceStatus.normalize(status);
  return switch (normalized) {
    LiveAttendanceStatus.declared => context.l10n(
      ko: '방문 기록됨(검증 전)',
      en: 'Recorded (before verification)',
      ja: '訪問記録済み（検証前）',
    ),
    LiveAttendanceStatus.verified => context.l10n(
      ko: '방문 검증 완료',
      en: 'Attendance verified',
      ja: '参加検証完了',
    ),
    _ => context.l10n(ko: '방문 기록 없음', en: 'No attendance record', ja: '参加記録なし'),
  };
}

String _attendanceErrorMessage(BuildContext context, Failure failure) {
  if (failure is ValidationFailure &&
      failure.code == 'ATTENDANCE_UPDATE_FAILED') {
    return context.l10n(
      ko: '검증 완료된 방문 기록은 취소할 수 없어요.',
      en: 'Verified attendance cannot be undone.',
      ja: '検証済みの参加記録は取り消せません。',
    );
  }
  return switch (failure) {
    AuthFailure() => context.l10n(
      ko: '로그인이 필요합니다.',
      en: 'Login required.',
      ja: 'ログインが必要です。',
    ),
    NetworkFailure() => context.l10n(
      ko: '네트워크 연결을 확인해주세요.',
      en: 'Check your network connection.',
      ja: 'ネットワーク接続を確認してください。',
    ),
    _ => failure.userMessage,
  };
}

Color _attendanceStatusColor(bool isDark, String status) {
  final normalized = LiveAttendanceStatus.normalize(status);
  return switch (normalized) {
    LiveAttendanceStatus.declared =>
      isDark ? GBTColors.darkSecondary : GBTColors.secondary,
    LiveAttendanceStatus.verified =>
      isDark ? GBTColors.darkPrimary : GBTColors.primary,
    _ => isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
  };
}

/// EN: Status chip — color-coded by event status.
/// KO: 이벤트 상태별 색상 코딩 상태 칩.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isDark});

  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final Color chipColor;
    if (lower == 'live') {
      chipColor = GBTColors.live;
    } else if (lower.contains('예정') || lower.contains('upcoming')) {
      chipColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    } else {
      chipColor = isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status,
        style: GBTTypography.labelSmall.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// EN: Compact attendance stamp CTA rendered inside the ticket stub —
/// tapping stamps (or un-stamps) this show as attended.
/// KO: 티켓 스텁 안에 렌더링되는 컴팩트 참석 스탬프 CTA — 탭하면 이
/// 공연을 참석(스탬프) 처리하거나 취소합니다.
class _AttendanceStubButton extends StatelessWidget {
  const _AttendanceStubButton({required this.state, required this.onToggle});

  final LiveAttendanceViewState state;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attendance = state.attendance;
    final isOffLocked = attendance.attended && !attendance.canUndo;
    final isEnabled = !state.isSubmitting && !state.isLoading && !isOffLocked;
    final accent = isDark ? GBTColors.darkAccent : GBTColors.accent;
    final idleColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Semantics(
      button: true,
      label: attendance.attended
          ? context.l10n(ko: '참석 취소', en: 'Cancel attendance', ja: '参加取消')
          : context.l10n(ko: '참석 기록', en: 'Mark attended', ja: '参加記録'),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: isEnabled ? () => onToggle(!attendance.attended) : null,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: attendance.attended
                ? accent.withValues(alpha: isDark ? 0.24 : 0.16)
                : Colors.transparent,
            border: Border.all(
              color: attendance.attended ? accent : idleColor,
              width: 1.4,
            ),
          ),
          child: state.isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : Icon(
                  attendance.attended
                      ? Icons.check_rounded
                      : Icons.confirmation_num_outlined,
                  size: 20,
                  color: attendance.attended ? accent : idleColor,
                ),
        ),
      ),
    );
  }
}

IconData _platformBackIcon(BuildContext context) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return Icons.arrow_back_ios_new_rounded;
  }
  return Icons.arrow_back_rounded;
}

/// EN: Circular overlay icon button — 40px circle, 48px tap target.
/// Semi-transparent dark backdrop ensures readability on any poster.
/// KO: 원형 오버레이 아이콘 버튼 — 40px 원, 48px 터치 타겟.
/// 반투명 어두운 배경으로 어떤 포스터에서도 가독성 보장.
class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      // EN: iconSm (20px) matches design system icon scale.
      // KO: iconSm(20px)은 디자인 시스템 아이콘 크기 기준과 일치.
      icon: Icon(icon, size: GBTSpacing.iconSm),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        // EN: 45% black — readable on bright and dark posters.
        // KO: 45% 검정 — 밝은/어두운 포스터 모두에서 가독성 확보.
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        // EN: 40px visual circle; Material pads tap target to 48px.
        // KO: 40px 시각 원형; Material이 터치 타겟을 48px로 자동 패딩.
        fixedSize: const Size(40, 40),
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

/// EN: Pulsing dot for LIVE badge animation.
/// KO: LIVE 배지 애니메이션용 펄싱 도트.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// EN: Expandable description — collapses to 3 lines; shows "더 보기 / 접기" toggle
/// for long text. Uses AnimatedCrossFade for smooth height transition.
/// KO: 접힘 가능한 설명 — 3줄로 축약; 긴 텍스트에서 "더 보기 / 접기" 토글 표시.
/// 부드러운 높이 전환을 위해 AnimatedCrossFade 사용.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    // EN: Show toggle only when text is long enough to overflow 3 lines.
    //     ~100 chars is a reliable heuristic for most body text sizes.
    // KO: 텍스트가 3줄을 넘길 만큼 긴 경우에만 토글 표시.
    //     ~100자는 대부분의 본문 텍스트 크기에서 신뢰할 수 있는 기준값.
    final isLong = widget.text.length > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: GBTAnimations.normal,
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            style: GBTTypography.bodyMedium.copyWith(
              color: secondaryColor,
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.text,
            style: GBTTypography.bodyMedium.copyWith(
              color: secondaryColor,
              height: 1.6,
            ),
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: GBTSpacing.xs),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? '접기' : '더 보기',
              style: GBTTypography.labelMedium.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
