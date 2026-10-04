/// EN: Clean-sheet event dossier preserving real event and attendance actions.
/// KO: 실제 이벤트와 방문 액션을 유지하는 신규 이벤트 도시에 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../domain/event_time_policy.dart';
import 'event_preparation.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_image.dart';
import 'package:oshi_log/design_system/widgets/common/registrant_credit_widget.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/design_system/widgets/navigation/gbt_standard_app_bar.dart';
import 'package:oshi_log/features/shared/favorites/application/favorites_controller.dart';
import 'package:oshi_log/features/shared/favorites/domain/entities/favorite_entities.dart';
import 'package:oshi_log/features/oshikatsu/music/application/music_controller.dart';
import 'package:oshi_log/features/oshikatsu/music/domain/entities/music_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/application/live_events_controller.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'field_event_detail_sections.dart';
import 'field_event_detail_widgets.dart';
import 'live_schedule_status_badge.dart';

/// EN: Event detail entry used by shell and overlay event routes.
/// KO: 쉘 및 오버레이 이벤트 라우트에서 사용하는 이벤트 상세 진입점입니다.
class FieldLiveEventDetailPage extends ConsumerWidget {
  const FieldLiveEventDetailPage({
    super.key,
    required this.eventId,
    this.preparationBuilder,
  });

  final String eventId;
  final Widget Function(BuildContext, LiveEventDetail)? preparationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveEventDetailControllerProvider(eventId));
    final favorites = ref.watch(favoritesControllerProvider);
    final event = state.valueOrNull;
    final isFavorite =
        event != null &&
        favorites.maybeWhen(
          data: (items) => items.any(
            (item) =>
                item.entityId == event.id &&
                item.type == FavoriteType.liveEvent,
          ),
          orElse: () => false,
        );

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        titleWidget: Text(
          context.l10n(
            ko: 'EVENT DOSSIER',
            en: 'EVENT DOSSIER',
            ja: 'EVENT DOSSIER',
          ),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: event == null
                ? null
                : () => _toggleFavorite(context, ref, event, isFavorite),
            tooltip: isFavorite
                ? context.l10n(
                    ko: '즐겨찾기 해제',
                    en: 'Remove favorite',
                    ja: 'お気に入りを解除',
                  )
                : context.l10n(
                    ko: '즐겨찾기 추가',
                    en: 'Add favorite',
                    ja: 'お気に入りに追加',
                  ),
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const _EventDetailSkeleton(),
        error: (error, _) => _EventDetailError(
          message: error is Failure
              ? error.userMessage
              : context.l10n(
                  ko: '이벤트 정보를 불러오지 못했어요.',
                  en: 'Could not load this event.',
                  ja: 'イベント情報を読み込めませんでした。',
                ),
          onRetry: () => ref
              .read(liveEventDetailControllerProvider(eventId).notifier)
              .load(forceRefresh: true),
        ),
        data: (event) => _FieldEventDetailContent(
          event: event,
          preparationBuilder: preparationBuilder,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    LiveEventDetail event,
    bool isFavorite,
  ) async {
    if (!ref.read(isAuthenticatedProvider) &&
        !await ref.read(authenticationGateProvider)(context)) {
      return;
    }
    if (!context.mounted) return;
    final currentFavorite =
        ref
            .read(favoritesControllerProvider)
            .valueOrNull
            ?.any(
              (item) =>
                  item.entityId == event.id &&
                  item.type == FavoriteType.liveEvent,
            ) ??
        isFavorite;
    final result = await ref
        .read(favoritesControllerProvider.notifier)
        .toggleFavorite(
          entityId: event.id,
          type: FavoriteType.liveEvent,
          isCurrentlyFavorite: currentFavorite,
        );
    if (!context.mounted || result.failureOrNull == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.userMessage)));
  }
}

class _FieldEventDetailContent extends ConsumerWidget {
  const _FieldEventDetailContent({
    required this.event,
    this.preparationBuilder,
  });

  final LiveEventDetail event;
  final Widget Function(BuildContext, LiveEventDetail)? preparationBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId =
        resolveLiveEventProjectContext(
          eventProjectIds: event.projectIds,
          selectedProjectKey: ref.watch(selectedProjectKeyProvider),
          selectedProjectId: ref.watch(selectedProjectIdProvider),
        ) ??
        '';
    final attendanceContext = projectId.isEmpty
        ? null
        : (projectId: projectId, eventId: event.id);
    final attendance = attendanceContext == null
        ? LiveAttendanceViewState(
            attendance: LiveAttendanceState.none(event.id),
          )
        : ref.watch(
            liveAttendanceByProjectControllerProvider(attendanceContext),
          );
    final AsyncValue<MusicLiveSetlist?> setlist = projectId.isEmpty
        ? const AsyncData(null)
        : ref
              .watch(
                liveEventSetlistProvider((
                  projectId: projectId,
                  liveEventId: event.id,
                )),
              )
              .whenData<MusicLiveSetlist?>((value) => value);
    final ticketUrl = event.ticketUrl?.trim();
    final placeId = event.placeId?.trim();
    final rescheduledEventId = event.rescheduledEventId;
    final phase = EventTimePolicy.phase(
      start: event.showStartTime,
      end: event.endTime,
      now: DateTime.now(),
    );
    final address = event.address?.trim() ?? '';
    final canTicket =
        !event.isCancelled &&
        ticketUrl != null &&
        Uri.tryParse(ticketUrl)?.scheme == 'https';
    void openDirections({bool returning = false}) {
      _openTicket(
        context,
        Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          returning ? 'origin' : 'destination': address,
          'travelmode': 'transit',
        }).toString(),
      );
    }

    void openGuides() => context.pushNamed(
      AppRoutes.cheerGuides,
      queryParameters: {if (projectId.isNotEmpty) 'project': projectId},
    );
    void toggleAttendance() {
      if (attendanceContext != null) {
        _toggleAttendance(
          context,
          ref,
          attendanceContext,
          attendance.attendance.attended,
        );
      }
    }

    final recordEnabled =
        attendanceContext != null &&
        !attendance.isLoading &&
        !attendance.isSubmitting &&
        (attendance.failure == null || !ref.watch(isAuthenticatedProvider)) &&
        (event.isAttendable || attendance.attendance.attended);
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(liveEventDetailControllerProvider(event.id).notifier)
                  .load(forceRefresh: true);
              if (attendanceContext != null) {
                ref
                    .read(
                      liveAttendanceByProjectControllerProvider(
                        attendanceContext,
                      ).notifier,
                    )
                    .load(forceRefresh: true);
              }
              if (projectId.isNotEmpty) {
                ref.invalidate(
                  liveEventSetlistProvider((
                    projectId: projectId,
                    liveEventId: event.id,
                  )),
                );
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(GBTSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                FieldEventTicketDocument(
                  event: event,
                  attendance: attendance,
                  onAttendanceToggle: null,
                  onTicketTap: null,
                  showActions: false,
                  onRescheduledTap: rescheduledEventId == null
                      ? null
                      : () => context.goToEventDetail(rescheduledEventId),
                ),
                const SizedBox(height: GBTSpacing.xl),
                EventAccessSection(
                  event: event,
                  collapsed: phase == EventPhase.after,
                  onDirections: address.isEmpty ? null : openDirections,
                  onVenue: placeId == null || placeId.isEmpty
                      ? null
                      : () => context.goToPlaceDetail(placeId),
                ),
                if (phase == EventPhase.today && canTicket)
                  ExpansionTile(
                    title: Text(
                      context.l10n(ko: '티켓', en: 'Tickets', ja: 'チケット'),
                    ),
                    children: [
                      TextButton.icon(
                        onPressed: () => _openTicket(context, ticketUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(
                          context.l10n(
                            ko: '공식 티켓',
                            en: 'Official tickets',
                            ja: '公式チケット',
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: GBTSpacing.xl),
                Text(
                  context.l10n(
                    ko: '내 참전 기록',
                    en: 'My attendance record',
                    ja: '私の参戦記録',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: GBTSpacing.sm),
                if (attendance.failure != null) ...[
                  Text(attendance.failure!.userMessage),
                  TextButton(
                    onPressed: attendanceContext == null
                        ? null
                        : () => ref
                              .read(
                                liveAttendanceByProjectControllerProvider(
                                  attendanceContext,
                                ).notifier,
                              )
                              .load(forceRefresh: true),
                    child: Text(
                      context.l10n(
                        ko: '기록 다시 불러오기',
                        en: 'Retry attendance',
                        ja: '記録を再読み込み',
                      ),
                    ),
                  ),
                ],
                FieldAttendanceStamp(
                  attended: attendance.attendance.attended,
                  canUndo: attendance.attendance.canUndo,
                  isBusy: attendance.isLoading || attendance.isSubmitting,
                  onToggle: recordEnabled ? toggleAttendance : null,
                ),
                Text(
                  attendance.attendance.isVerified
                      ? context.l10n(
                          ko: '위치 인증 완료 · 시스템 확인',
                          en: 'Location verified by the system',
                          ja: '位置認証済み・システム確認',
                        )
                      : context.l10n(
                          ko: '직접 남기는 참전 기록입니다. 참가 예정과는 별개예요.',
                          en: 'Self-reported attendance; separate from future plans.',
                          ja: '自己申告の参戦記録です。参加予定とは別です。',
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: GBTSpacing.xl),
                EventPreparationSection(
                  collapsed: phase == EventPhase.after,
                  onCheerGuide: openGuides,
                  onReturnRoute: address.isEmpty
                      ? null
                      : () => openDirections(returning: true),
                  supplement: preparationBuilder?.call(context, event),
                ),
                const SizedBox(height: GBTSpacing.xl),
                FieldEventSetlistSection(
                  eventId: event.id,
                  state: setlist,
                  hasProjectContext: projectId.isNotEmpty,
                  onRetry: projectId.isEmpty
                      ? null
                      : () => ref.invalidate(
                          liveEventSetlistProvider((
                            projectId: projectId,
                            liveEventId: event.id,
                          )),
                        ),
                  onSongTap: (item) {
                    if (item.hasSongLink && projectId.isNotEmpty) {
                      context.goToSongDetail(
                        item.songId!,
                        projectId: projectId,
                        eventId: event.id,
                      );
                    }
                  },
                ),
                const SizedBox(height: GBTSpacing.xl),
                if ((event.description ?? '').trim().isNotEmpty)
                  ExpansionTile(
                    title: Text(
                      context.l10n(ko: '공연 정보', en: 'Event notes', ja: '公演情報'),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(GBTSpacing.md),
                        child: Text(event.description!),
                      ),
                    ],
                  ),
                ExpansionTile(
                  title: Text(
                    context.l10n(ko: '포스터', en: 'Poster', ja: 'ポスター'),
                  ),
                  children: [_EventPoster(event: event)],
                ),
                const SizedBox(height: GBTSpacing.md),
                ContributorsCreditWidget(
                  entityType: 'lives',
                  entityId: event.id,
                ),
                const SizedBox(height: GBTSpacing.xl),
              ],
            ),
          ),
        ),
        EventActionBar(
          phase: phase,
          onTicket: canTicket ? () => _openTicket(context, ticketUrl) : null,
          onDirections: address.isEmpty ? null : openDirections,
          onCheerGuide: openGuides,
          onRecord: recordEnabled && !attendance.attendance.attended
              ? toggleAttendance
              : null,
          onReport: () => context.goToPostCreate(),
        ),
      ],
    );
  }

  Future<void> _toggleAttendance(
    BuildContext context,
    WidgetRef ref,
    ({String projectId, String eventId}) attendanceContext,
    bool isAttended,
  ) async {
    if (!ref.read(isAuthenticatedProvider) &&
        !await ref.read(authenticationGateProvider)(context)) {
      return;
    }
    if (!context.mounted) return;
    final currentAttended = ref
        .read(liveAttendanceByProjectControllerProvider(attendanceContext))
        .attendance
        .attended;
    final result = await ref
        .read(
          liveAttendanceByProjectControllerProvider(attendanceContext).notifier,
        )
        .toggle(!currentAttended);
    if (!context.mounted || result.failureOrNull == null) return;
    final failure = result.failureOrNull!;
    final message = isLiveNotAttendableFailure(failure)
        ? liveCancelledMessage(context)
        : failure is ValidationFailure &&
              failure.code == 'ATTENDANCE_UPDATE_FAILED'
        ? context.l10n(
            ko: '검증 완료된 방문 기록은 취소할 수 없어요.',
            en: 'Verified attendance cannot be undone.',
            ja: '検証済みの参加記録は取り消せません。',
          )
        : failure.userMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTicket(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    final allowed = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    var opened = false;
    try {
      opened =
          allowed && await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '외부 링크를 열 수 없어요.',
            en: 'Could not open the external link.',
            ja: '外部リンクを開けませんでした。',
          ),
        ),
      ),
    );
  }
}

class _EventPoster extends StatelessWidget {
  const _EventPoster({required this.event});

  final LiveEventDetail event;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxHeight: 460),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: event.bannerUrl == null || event.bannerUrl!.trim().isEmpty
            ? Center(
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 72,
                  color: colors.secondary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(GBTSpacing.sm),
                child: GBTImage(
                  imageUrl: event.bannerUrl!,
                  fit: BoxFit.contain,
                  semanticLabel: context.l10n(
                    ko: '${event.title} 포스터',
                    en: '${event.title} poster',
                    ja: '${event.title} ポスター',
                  ),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                ),
              ),
      ),
    );
  }
}

/// EN: The responsive event document shown beneath the poster.
/// KO: 포스터 아래에 표시하는 반응형 이벤트 문서입니다.
class FieldEventTicketDocument extends StatelessWidget {
  const FieldEventTicketDocument({
    super.key,
    required this.event,
    required this.attendance,
    required this.onAttendanceToggle,
    required this.onTicketTap,
    this.onVenueTap,
    this.onRescheduledTap,
    this.showActions = true,
    this.now,
  });
  final LiveEventDetail event;
  final LiveAttendanceViewState attendance;
  final VoidCallback? onAttendanceToggle;
  final VoidCallback? onTicketTap;
  final VoidCallback? onVenueTap;
  final VoidCallback? onRescheduledTap;
  final bool showActions;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = EventTimePolicy.inJst(event.showStartTime);
    final phase = EventTimePolicy.phase(
      start: event.showStartTime,
      end: event.endTime,
      now: now ?? DateTime.now(),
    );
    final canToggle = event.isAttendable || attendance.attendance.attended;
    final times = <String>[
      if (event.doorsOpenTime != null)
        '${context.l10n(ko: '개장', en: 'Doors', ja: '開場')} ${DateFormat.Hm(locale).format(EventTimePolicy.inJst(event.doorsOpenTime!))}',
      '${context.l10n(ko: '개연', en: 'Show', ja: '開演')} ${DateFormat.Hm(locale).format(start)}',
      if (event.endTime != null && event.endTime!.isAfter(event.showStartTime))
        '${context.l10n(ko: '종료', en: 'End', ja: '終演')} ${DateFormat.Hm(locale).format(EventTimePolicy.inJst(event.endTime!))}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventStatusBadges(
          start: event.showStartTime,
          end: event.endTime,
          scheduleStatus: event.scheduleStatus,
          attended: attendance.attendance.attended,
          now: now,
        ),
        const SizedBox(height: GBTSpacing.md),
        Text(
          event.title,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: GBTSpacing.md),
        FieldEventFact(
          label: context.l10n(ko: '날짜 · JST', en: 'Date · JST', ja: '日付・JST'),
          value: DateFormat.yMMMMEEEEd(locale).format(start),
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: GBTSpacing.md),
        FieldEventFact(
          label: context.l10n(
            ko: '공연 시각 · JST',
            en: 'Show times · JST',
            ja: '公演時刻・JST',
          ),
          value: times.join('\n'),
          icon: Icons.schedule,
        ),
        if (event.showStartTime.toLocal().timeZoneOffset !=
            EventTimePolicy.jstOffset) ...[
          const SizedBox(height: GBTSpacing.sm),
          Text(
            '${context.l10n(ko: '단말 현지 시각', en: 'Device local time', ja: '端末の現地時刻')}: ${DateFormat.yMd(locale).add_Hm().format(event.showStartTime.toLocal())} (${event.showStartTime.toLocal().timeZoneName})',
          ),
        ],
        if (event.isCancelled)
          Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.md),
            child: Text(liveCancelledMessage(context)),
          ),
        if (event.isPostponed)
          Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.md),
            child: Text(
              context.l10n(
                ko: event.rescheduledEventId == null
                    ? '연기 — 새 일정 미정'
                    : '연기 — 새 일정 확인',
                en: event.rescheduledEventId == null
                    ? 'Postponed — new date TBA'
                    : 'Postponed — check the new date',
                ja: event.rescheduledEventId == null
                    ? '延期・新しい日程は未定'
                    : '延期・新しい日程をご確認ください',
              ),
            ),
          ),
        if (event.isPostponed &&
            event.rescheduledEventId != null &&
            onRescheduledTap != null)
          TextButton.icon(
            onPressed: onRescheduledTap,
            icon: const Icon(Icons.event_repeat),
            label: Text(
              context.l10n(ko: '새 일정 보기', en: 'View new date', ja: '新しい日程を見る'),
            ),
          ),
        if (showActions) ...[
          const SizedBox(height: GBTSpacing.md),
          FieldEventFact(
            label: context.l10n(ko: '장소', en: 'Venue', ja: '会場'),
            value: _eventVenueLabel(context, event),
            icon: Icons.place_outlined,
          ),
          if (onVenueTap != null)
            TextButton(
              onPressed: onVenueTap,
              child: Text(
                context.l10n(
                  ko: '회장 상세',
                  en: 'View venue place',
                  ja: '会場の場所を見る',
                ),
              ),
            ),
          FieldAttendanceStamp(
            attended: attendance.attendance.attended,
            canUndo: attendance.attendance.canUndo,
            isBusy: attendance.isLoading || attendance.isSubmitting,
            onToggle: canToggle ? onAttendanceToggle : null,
          ),
          if (!event.isCancelled &&
              phase != EventPhase.after &&
              onTicketTap != null)
            OutlinedButton.icon(
              onPressed: onTicketTap,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                context.l10n(ko: '공식 티켓', en: 'Official tickets', ja: '公式チケット'),
              ),
            ),
        ],
      ],
    );
  }
}

String _eventVenueLabel(BuildContext context, LiveEventDetail event) {
  final venue = event.venue?.trim();
  final address = event.address?.trim();
  if (venue != null &&
      venue.isNotEmpty &&
      address != null &&
      address.isNotEmpty) {
    return '$venue · $address';
  }
  if (venue != null && venue.isNotEmpty) return venue;
  if (address != null && address.isNotEmpty) return address;
  return context.l10n(
    ko: '이벤트 데이터에 미제공',
    en: 'Not provided in event data',
    ja: 'イベントデータに未登録',
  );
}

class _EventDetailSkeleton extends StatelessWidget {
  const _EventDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(GBTSpacing.md),
      children: const [
        GBTShimmerContainer(height: 280, width: double.infinity),
        SizedBox(height: GBTSpacing.lg),
        GBTShimmerContainer(height: 360, width: double.infinity),
      ],
    );
  }
}

class _EventDetailError extends StatelessWidget {
  const _EventDetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(GBTSpacing.lg),
      children: [
        const SizedBox(height: GBTSpacing.xxxl),
        GBTErrorState(message: message, onRetry: onRetry),
      ],
    );
  }
}
