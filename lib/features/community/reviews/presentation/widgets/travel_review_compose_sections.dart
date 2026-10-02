/// EN: Optional trip metadata, event, and fan-subject compose controls.
/// KO: 선택적 여행 메타데이터·이벤트·팬 대상 작성 컨트롤입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';
import 'package:oshi_log/features/live_events/application/live_events_controller.dart';
import 'package:oshi_log/features/live_events/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/fan_subjects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/fan_subject.dart';

class TravelReviewComposeMetadata extends StatelessWidget {
  const TravelReviewComposeMetadata({
    super.key,
    required this.routeNoteController,
    required this.selectedEvents,
    this.verifiedEventIds = const {},
    required this.selectedSubjects,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onPickEvents,
    required this.onPickSubjects,
    required this.onRemoveEvent,
    required this.onRemoveSubject,
    this.tripStartedOn,
    this.tripEndedOn,
  });

  final TextEditingController routeNoteController;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;
  final List<LiveEventSummary> selectedEvents;
  final Set<String> verifiedEventIds;
  final List<FanSubject> selectedSubjects;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickEvents;
  final VoidCallback onPickSubjects;
  final ValueChanged<String> onRemoveEvent;
  final ValueChanged<String> onRemoveSubject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '여행 정보', en: 'Trip Info', ja: '旅の情報'),
          style: GBTTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: GBTSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final startButton = _DateButton(
              label: context.l10n(ko: '시작일', en: 'Start Date', ja: '開始日'),
              value: tripStartedOn,
              onPressed: onPickStartDate,
            );
            final endButton = _DateButton(
              label: context.l10n(ko: '종료일', en: 'End Date', ja: '終了日'),
              value: tripEndedOn,
              onPressed: onPickEndDate,
            );
            if (constraints.maxWidth < 360 || textScale > 1.3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startButton,
                  const SizedBox(height: GBTSpacing.sm),
                  endButton,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: startButton),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(child: endButton),
              ],
            );
          },
        ),
        const SizedBox(height: GBTSpacing.sm),
        TextField(
          controller: routeNoteController,
          minLines: 2,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: context.l10n(ko: '동선 메모', en: 'Route Notes', ja: '移動メモ'),
            hintText: context.l10n(
              ko: '교통, 예약, 이동 팁을 남겨보세요.',
              en: 'Add transport, booking, or travel tips.',
              ja: '交通、予約、移動のコツを書いてみましょう。',
            ),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: GBTSpacing.md),
        _SelectionHeader(
          title: context.l10n(
            ko: '함께한 라이브',
            en: 'Linked Live Events',
            ja: '一緒に参加したライブ',
          ),
          count: selectedEvents.length,
          actionLabel: context.l10n(
            ko: '라이브 선택',
            en: 'Select Live',
            ja: 'ライブを選択',
          ),
          icon: Icons.event_available_outlined,
          onPressed: onPickEvents,
        ),
        if (selectedEvents.isNotEmpty) ...[
          const SizedBox(height: GBTSpacing.xs),
          for (final event in selectedEvents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.music_note_rounded),
              title: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'yyyy.MM.dd HH:mm',
                    ).format(event.showStartTime.toLocal()),
                  ),
                  if (verifiedEventIds.contains(event.id))
                    Text(
                      context.l10n(
                        ko: '인증된 참석 기록 연결',
                        en: 'Linked to verified attendance',
                        ja: '認証済み参加記録にリンク',
                      ),
                      style: GBTTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                onPressed: () => onRemoveEvent(event.id),
                icon: const Icon(Icons.close_rounded),
                tooltip: context.l10n(
                  ko: '${event.title} 제거',
                  en: 'Remove ${event.title}',
                  ja: '${event.title}を削除',
                ),
              ),
            ),
        ],
        const SizedBox(height: GBTSpacing.md),
        _SelectionHeader(
          title: context.l10n(ko: '기록 대상', en: 'Tagged Subjects', ja: '記録対象'),
          count: selectedSubjects.length,
          actionLabel: context.l10n(
            ko: '대상 선택',
            en: 'Select Subjects',
            ja: '対象を選択',
          ),
          icon: Icons.auto_awesome_outlined,
          onPressed: onPickSubjects,
        ),
        if (selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: GBTSpacing.sm),
          Wrap(
            spacing: GBTSpacing.xs,
            runSpacing: GBTSpacing.xs,
            children: selectedSubjects
                .map(
                  (subject) => InputChip(
                    label: Text(subject.name),
                    onDeleted: () => onRemoveSubject(subject.id),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class TravelEventPickerSheet extends ConsumerWidget {
  const TravelEventPickerSheet({
    super.key,
    required this.selectedIds,
    required this.onToggle,
  });

  final Set<String> selectedIds;
  final ValueChanged<LiveEventSummary> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(liveEventsListControllerProvider);
    return _PickerScaffold(
      title: context.l10n(
        ko: '함께한 라이브',
        en: 'Linked Live Events',
        ja: '一緒に参加したライブ',
      ),
      child: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PickerMessage(
          icon: Icons.cloud_off_rounded,
          message: context.l10n(
            ko: '라이브 일정을 불러오지 못했어요.',
            en: 'Could not load live schedules.',
            ja: 'ライブ日程を読み込めませんでした。',
          ),
          onRetry: () => ref
              .read(liveEventsListControllerProvider.notifier)
              .load(forceRefresh: true),
        ),
        data: (items) => items.isEmpty
            ? _PickerMessage(
                icon: Icons.event_busy_outlined,
                message: context.l10n(
                  ko: '선택할 수 있는 라이브가 없어요.',
                  en: 'No live events to select.',
                  ja: '選択できるライブがありません。',
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = selectedIds.contains(item.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) => onToggle(item),
                    title: Text(item.title),
                    subtitle: Text(
                      DateFormat(
                        'yyyy.MM.dd HH:mm',
                      ).format(item.showStartTime.toLocal()),
                    ),
                    secondary: const Icon(Icons.music_note_rounded),
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
      ),
    );
  }
}

class TravelFanSubjectPickerSheet extends ConsumerWidget {
  const TravelFanSubjectPickerSheet({
    super.key,
    required this.projectCode,
    required this.selectedIds,
    required this.onToggle,
  });

  final String projectCode;
  final Set<String> selectedIds;
  final ValueChanged<FanSubject> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(
      fanSubjectsProvider(FanSubjectQuery(projectId: projectCode, size: 100)),
    );
    return _PickerScaffold(
      title: context.l10n(ko: '기록할 팬 대상', en: 'Tagged Subjects', ja: '記録対象'),
      child: subjects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PickerMessage(
          icon: Icons.cloud_off_rounded,
          message: context.l10n(
            ko: '프로젝트·밴드·성우 목록을 불러오지 못했어요.',
            en: 'Could not load the project/band/voice-actor list.',
            ja: 'プロジェクト・バンド・声優の一覧を読み込めませんでした。',
          ),
        ),
        data: (items) => items.isEmpty
            ? _PickerMessage(
                icon: Icons.auto_awesome_outlined,
                message: context.l10n(
                  ko: '선택할 수 있는 팬 대상이 없어요.',
                  en: 'No subjects to select.',
                  ja: '選択できる記録対象がありません。',
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    value: selectedIds.contains(item.id),
                    onChanged: (_) => onToggle(item),
                    title: Text(item.name),
                    subtitle: Text(_subjectTypeLabel(context, item.kind)),
                    secondary: CircleAvatar(
                      child: Icon(_subjectTypeIcon(item.kind), size: 20),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final formattedValue = value == null
        ? null
        : DateFormat('yyyy.MM.dd').format(value!);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        formattedValue == null ? label : '$label $formattedValue',
        maxLines: 2,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.title,
    required this.count,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final int count;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final titleText = Text(
      count == 0 ? title : '$title $count',
      style: GBTTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final actionButton = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(actionLabel),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, GBTSpacing.touchTarget),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360 || textScale > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleText,
              const SizedBox(height: GBTSpacing.xs),
              actionButton,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: titleText),
            const SizedBox(width: GBTSpacing.sm),
            Flexible(flex: 0, child: actionButton),
          ],
        );
      },
    );
  }
}

class _PickerScaffold extends StatelessWidget {
  const _PickerScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                0,
                GBTSpacing.md,
                GBTSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GBTTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, GBTSpacing.touchTarget),
                    ),
                    child: Text(context.l10n(ko: '완료', en: 'Done', ja: '完了する')),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GBTSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: GBTSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: GBTSpacing.sm),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(
                  context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行する'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _subjectTypeLabel(BuildContext context, FanSubjectKind kind) =>
    switch (kind) {
      FanSubjectKind.project => context.l10n(
        ko: '프로젝트',
        en: 'Project',
        ja: 'プロジェクト',
      ),
      FanSubjectKind.unit => context.l10n(
        ko: '밴드·유닛',
        en: 'Band/Unit',
        ja: 'バンド・ユニット',
      ),
      FanSubjectKind.voiceActor => context.l10n(
        ko: '성우',
        en: 'Voice Actor',
        ja: '声優',
      ),
      FanSubjectKind.artist => context.l10n(
        ko: '아티스트',
        en: 'Artist',
        ja: 'アーティスト',
      ),
      FanSubjectKind.anime => context.l10n(ko: '애니메이션', en: 'Anime', ja: 'アニメ'),
      FanSubjectKind.unknown => context.l10n(ko: '기타', en: 'Other', ja: 'その他'),
    };

IconData _subjectTypeIcon(FanSubjectKind kind) => switch (kind) {
  FanSubjectKind.project => Icons.folder_outlined,
  FanSubjectKind.unit => Icons.groups_outlined,
  FanSubjectKind.voiceActor => Icons.person_outline_rounded,
  FanSubjectKind.artist => Icons.mic_external_on_outlined,
  FanSubjectKind.anime => Icons.movie_filter_outlined,
  FanSubjectKind.unknown => Icons.auto_awesome_outlined,
};
