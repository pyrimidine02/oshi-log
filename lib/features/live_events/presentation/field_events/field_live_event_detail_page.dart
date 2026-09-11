/// EN: Clean-sheet event dossier preserving real event and attendance actions.
/// KO: 실제 이벤트와 방문 액션을 유지하는 신규 이벤트 도시에 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/registrant_credit_widget.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../favorites/application/favorites_controller.dart';
import '../../../favorites/domain/entities/favorite_entities.dart';
import '../../../music/application/music_controller.dart';
import '../../../music/domain/entities/music_entities.dart';
import '../../application/live_events_controller.dart';
import '../../domain/entities/live_event_entities.dart';
import 'field_event_detail_sections.dart';
import 'field_event_detail_widgets.dart';

/// EN: Event detail entry used by shell and overlay event routes.
/// KO: 쉘 및 오버레이 이벤트 라우트에서 사용하는 이벤트 상세 진입점입니다.
class FieldLiveEventDetailPage extends ConsumerWidget {
  const FieldLiveEventDetailPage({super.key, required this.eventId});

  final String eventId;

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
        data: (event) => _FieldEventDetailContent(event: event),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    LiveEventDetail event,
    bool isFavorite,
  ) async {
    final result = await ref
        .read(favoritesControllerProvider.notifier)
        .toggleFavorite(
          entityId: event.id,
          type: FavoriteType.liveEvent,
          isCurrentlyFavorite: isFavorite,
        );
    if (!context.mounted || result.failureOrNull == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.failureOrNull!.userMessage)));
  }
}

class _FieldEventDetailContent extends ConsumerWidget {
  const _FieldEventDetailContent({required this.event});

  final LiveEventDetail event;

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
    return RefreshIndicator(
      onRefresh: () async {
        final attendanceRefresh = attendanceContext == null
            ? Future<void>.value()
            : ref
                  .read(
                    liveAttendanceByProjectControllerProvider(
                      attendanceContext,
                    ).notifier,
                  )
                  .load(forceRefresh: true)
                  .then<void>((_) {});
        await Future.wait<void>([
          ref
              .read(liveEventDetailControllerProvider(event.id).notifier)
              .load(forceRefresh: true),
          attendanceRefresh,
        ]);
        if (projectId.isNotEmpty) {
          ref.invalidate(
            liveEventSetlistProvider((
              projectId: projectId,
              liveEventId: event.id,
            )),
          );
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.md,
              GBTSpacing.md,
              0,
            ),
            sliver: SliverList.list(
              children: [
                _EventPoster(event: event),
                const SizedBox(height: GBTSpacing.lg),
                FieldEventTicketDocument(
                  event: event,
                  attendance: attendance,
                  onAttendanceToggle: attendanceContext == null
                      ? null
                      : () => _toggleAttendance(
                          context,
                          ref,
                          attendanceContext,
                          attendance.attendance.attended,
                        ),
                  onTicketTap: ticketUrl == null || ticketUrl.isEmpty
                      ? null
                      : () => _openTicket(context, ticketUrl),
                  onVenueTap: placeId == null || placeId.isEmpty
                      ? null
                      : () => context.goToPlaceDetail(placeId),
                ),
                const SizedBox(height: GBTSpacing.xl),
                FieldEventSectionHeading(
                  eyebrow: context.l10n(
                    ko: 'FIELD NOTES',
                    en: 'FIELD NOTES',
                    ja: 'FIELD NOTES',
                  ),
                  title: context.l10n(
                    ko: '공연 정보',
                    en: 'Event notes',
                    ja: '公演情報',
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  (event.description ?? '').trim().isEmpty
                      ? context.l10n(
                          ko: '등록된 공연 설명이 없어요.',
                          en: 'No event description has been registered.',
                          ja: '公演説明は登録されていません。',
                        )
                      : event.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.65),
                ),
                const SizedBox(height: GBTSpacing.xl),
                FieldEventSetlistSection(
                  state: setlist,
                  hasProjectContext: projectId.isNotEmpty,
                  onSongTap: (item) {
                    if (!item.hasSongLink || projectId.isEmpty) return;
                    context.goToSongDetail(
                      item.songId!,
                      projectId: projectId,
                      eventId: event.id,
                    );
                  },
                ),
                const SizedBox(height: GBTSpacing.xl),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: GBTSpacing.md),
                ContributorsCreditWidget(
                  entityType: 'lives',
                  entityId: event.id,
                ),
                const SizedBox(height: GBTSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAttendance(
    BuildContext context,
    WidgetRef ref,
    ({String projectId, String eventId}) attendanceContext,
    bool isAttended,
  ) async {
    final result = await ref
        .read(
          liveAttendanceByProjectControllerProvider(attendanceContext).notifier,
        )
        .toggle(!isAttended);
    if (!context.mounted || result.failureOrNull == null) return;
    final failure = result.failureOrNull!;
    final message =
        failure is ValidationFailure &&
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
            ko: '티켓 링크를 열 수 없어요.',
            en: 'Could not open the ticket link.',
            ja: 'チケットリンクを開けませんでした。',
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
  });

  final LiveEventDetail event;
  final LiveAttendanceViewState attendance;
  final VoidCallback? onAttendanceToggle;
  final VoidCallback? onTicketTap;
  final VoidCallback? onVenueTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startsAt = event.showStartTime.toLocal();
    final endTime = event.endTime?.toLocal();
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: colors.primary),
          Padding(
            padding: const EdgeInsets.all(GBTSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      event.dDayLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: GBTSpacing.lg),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: GBTSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 480;
                    final factWidth = wide
                        ? (constraints.maxWidth - GBTSpacing.md) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: GBTSpacing.md,
                      runSpacing: GBTSpacing.md,
                      children: [
                        SizedBox(
                          width: factWidth,
                          child: FieldEventFact(
                            label: context.l10n(ko: '날짜', en: 'Date', ja: '日付'),
                            value: DateFormat.yMMMMEEEEd(
                              locale,
                            ).format(startsAt),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                        SizedBox(
                          width: factWidth,
                          child: FieldEventFact(
                            label: context.l10n(ko: '시간', en: 'Time', ja: '時間'),
                            value: _timeLine(locale, startsAt, endTime),
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        SizedBox(
                          width: factWidth,
                          child: FieldEventFact(
                            label: context.l10n(
                              ko: '입장',
                              en: 'Doors',
                              ja: '開場',
                            ),
                            value: event.doorsOpenTime == null
                                ? context.l10n(ko: '미정', en: 'TBD', ja: '未定')
                                : DateFormat.Hm(
                                    locale,
                                  ).format(event.doorsOpenTime!.toLocal()),
                            icon: Icons.meeting_room_outlined,
                          ),
                        ),
                        SizedBox(
                          width: factWidth,
                          child: FieldEventFact(
                            label: context.l10n(
                              ko: '장소',
                              en: 'Venue',
                              ja: '会場',
                            ),
                            value: _eventVenueLabel(context, event),
                            icon: Icons.place_outlined,
                          ),
                        ),
                        SizedBox(
                          width: factWidth,
                          child: FieldEventFact(
                            label: context.l10n(
                              ko: '연결',
                              en: 'Scope',
                              ja: '連携',
                            ),
                            value: event.metaLabel,
                            icon: Icons.groups_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (onVenueTap != null) ...[
                  const SizedBox(height: GBTSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onVenueTap,
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        context.l10n(
                          ko: '장소 상세 보기',
                          en: 'View venue place',
                          ja: '会場の場所を見る',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _Perforation(color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _attendanceStatusLabel(context, attendance),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                FieldAttendanceStamp(
                  attended: attendance.attendance.attended,
                  canUndo: attendance.attendance.canUndo,
                  isBusy: attendance.isLoading || attendance.isSubmitting,
                  onToggle: onAttendanceToggle,
                ),
                const SizedBox(height: GBTSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onTicketTap,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    onTicketTap == null
                        ? context.l10n(
                            ko: '티켓 정보 없음',
                            en: 'No ticket information',
                            ja: 'チケット情報なし',
                          )
                        : context.l10n(
                            ko: '티켓 페이지 열기',
                            en: 'Open ticket page',
                            ja: 'チケットページを開く',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLine(String locale, DateTime startsAt, DateTime? endTime) {
    final start = DateFormat.Hm(locale).format(startsAt);
    if (endTime == null) return start;
    return '$start – ${DateFormat.Hm(locale).format(endTime)}';
  }

  String _attendanceStatusLabel(
    BuildContext context,
    LiveAttendanceViewState state,
  ) {
    if (state.isLoading) {
      return context.l10n(
        ko: '방문 상태를 확인하는 중입니다.',
        en: 'Checking attendance status.',
        ja: '参加状態を確認中です。',
      );
    }
    return switch (LiveAttendanceStatus.normalize(state.attendance.status)) {
      LiveAttendanceStatus.verified => context.l10n(
        ko: '방문이 검증되었어요.',
        en: 'Attendance is verified.',
        ja: '参加が検証されました。',
      ),
      LiveAttendanceStatus.declared => context.l10n(
        ko: '방문을 기록했어요. 검증 전입니다.',
        en: 'Attendance is recorded and awaiting verification.',
        ja: '参加を記録しました。検証待ちです。',
      ),
      _ => context.l10n(
        ko: '이 공연을 여행 기록에 남겨보세요.',
        en: 'Add this show to your travel record.',
        ja: 'この公演を旅の記録に残しましょう。',
      ),
    };
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

class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ),
        Expanded(child: Divider(color: color)),
        Container(
          width: 12,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
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
