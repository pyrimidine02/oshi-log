/// EN: Event preparation blocks using confirmed facts and existing actions.
/// KO: 확인된 정보와 기존 동작을 사용하는 공연 준비 블록입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/theme.dart';
import '../../domain/entities/live_event_entities.dart';
import '../../domain/event_time_policy.dart';

class EventAccessSection extends StatelessWidget {
  const EventAccessSection({
    super.key,
    required this.event,
    this.onDirections,
    this.onVenue,
    this.collapsed = false,
  });
  final LiveEventDetail event;
  final VoidCallback? onDirections;
  final VoidCallback? onVenue;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final address = event.address?.trim() ?? '';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          event.venue?.trim().isNotEmpty == true
              ? event.venue!
              : context.l10n(ko: '회장 미정', en: 'Venue unannounced', ja: '会場未定'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (address.isNotEmpty) ...[
          const SizedBox(height: GBTSpacing.sm),
          SelectableText(address),
          Wrap(
            spacing: GBTSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: address));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n(
                          ko: '주소를 복사했어요',
                          en: 'Address copied',
                          ja: '住所をコピーしました',
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(
                  context.l10n(ko: '주소 복사', en: 'Copy address', ja: '住所をコピー'),
                ),
              ),
              if (onDirections != null)
                TextButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(
                    context.l10n(ko: '길찾기', en: 'Directions', ja: '経路'),
                  ),
                ),
            ],
          ),
        ],
        if (onVenue != null)
          TextButton.icon(
            onPressed: onVenue,
            icon: const Icon(Icons.place_outlined),
            label: Text(
              context.l10n(
                ko: '회장 상세 · 접근 정보',
                en: 'Venue details · access',
                ja: '会場詳細・アクセス',
              ),
            ),
          ),
      ],
    );
    final title = context.l10n(
      ko: '회장·접근',
      en: 'Venue & access',
      ja: '会場・アクセス',
    );
    if (collapsed) {
      return ExpansionTile(
        title: Text(title),
        children: [
          Padding(padding: const EdgeInsets.all(GBTSpacing.md), child: content),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GBTSpacing.md),
        content,
      ],
    );
  }
}

class EventPreparationSection extends StatelessWidget {
  const EventPreparationSection({
    super.key,
    required this.onCheerGuide,
    this.onReturnRoute,
    this.supplement,
    this.collapsed = false,
  });
  final VoidCallback onCheerGuide;
  final VoidCallback? onReturnRoute;
  final Widget? supplement;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onCheerGuide,
          icon: const Icon(Icons.campaign_outlined),
          label: Text(
            context.l10n(ko: '응원 가이드', en: 'Cheer guides', ja: '応援ガイド'),
          ),
        ),
        if (supplement != null) ...[
          const SizedBox(height: GBTSpacing.md),
          supplement!,
        ],
        if (onReturnRoute != null) ...[
          const SizedBox(height: GBTSpacing.md),
          OutlinedButton.icon(
            onPressed: onReturnRoute,
            icon: const Icon(Icons.train_outlined),
            label: Text(
              context.l10n(
                ko: '귀가 경로·막차 확인',
                en: 'Check return route and last train',
                ja: '帰りの経路・終電を確認',
              ),
            ),
          ),
          Text(
            context.l10n(
              ko: '외부 경로 서비스에서 목적지와 출발 시각을 확인하세요.',
              en: 'Check destination and departure time in the route service.',
              ja: '経路サービスで目的地と出発時刻を確認してください。',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
    final title = context.l10n(ko: '공연 준비', en: 'Preparation', ja: '準備');
    if (collapsed) {
      return ExpansionTile(
        title: Text(title),
        children: [
          Padding(padding: const EdgeInsets.all(GBTSpacing.md), child: content),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: GBTSpacing.md),
        content,
      ],
    );
  }
}

class EventActionBar extends StatelessWidget {
  const EventActionBar({
    super.key,
    required this.phase,
    this.onTicket,
    this.onDirections,
    this.onCheerGuide,
    this.onRecord,
    this.onReport,
  });
  final EventPhase phase;
  final VoidCallback? onTicket;
  final VoidCallback? onDirections;
  final VoidCallback? onCheerGuide;
  final VoidCallback? onRecord;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final actions = switch (phase) {
      EventPhase.before => <Widget>[
        if (onTicket != null)
          FilledButton.icon(
            onPressed: onTicket,
            icon: const Icon(Icons.open_in_new),
            label: Text(
              context.l10n(ko: '공식 티켓', en: 'Official tickets', ja: '公式チケット'),
            ),
          ),
      ],
      EventPhase.today => <Widget>[
        if (onDirections != null)
          FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions),
            label: Text(context.l10n(ko: '길찾기', en: 'Directions', ja: '経路')),
          ),
        if (onCheerGuide != null)
          OutlinedButton(
            onPressed: onCheerGuide,
            child: Text(
              context.l10n(ko: '응원 가이드', en: 'Cheer guides', ja: '応援ガイド'),
            ),
          ),
      ],
      EventPhase.after => <Widget>[
        if (onRecord != null)
          FilledButton(
            onPressed: onRecord,
            child: Text(
              context.l10n(ko: '참전 기록', en: 'Record attendance', ja: '記録する'),
            ),
          ),
        if (onReport != null)
          OutlinedButton(
            onPressed: onReport,
            child: Text(
              context.l10n(ko: '레포 쓰기', en: 'Write a report', ja: 'レポを書く'),
            ),
          ),
      ],
    };
    if (actions.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.sm),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: GBTSpacing.sm,
            runSpacing: GBTSpacing.sm,
            children: actions,
          ),
        ),
      ),
    );
  }
}
