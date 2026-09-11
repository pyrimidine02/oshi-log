/// EN: Agenda primitives for the Urban Travel Field Notes event desk.
/// KO: Urban Travel Field Notes 이벤트 데스크용 아젠다 프리미티브입니다.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/layout/gbt_field_primitives.dart';
import '../../domain/entities/live_event_entities.dart';

/// EN: One event rendered as a dated railway-agenda row, not a card carousel.
/// KO: 카드 캐러셀이 아닌 날짜 기반 철도 아젠다 행으로 표시하는 이벤트입니다.
class FieldEventAgendaRow extends StatelessWidget {
  const FieldEventAgendaRow({
    super.key,
    required this.event,
    required this.attended,
    required this.onTap,
  });

  final LiveEventSummary event;
  final bool attended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = event.showStartTime.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final locationLabel = fieldEventSummaryLocationLabel(event);
    final attendanceLabel = attended
        ? context.l10n(ko: '방문 완료', en: 'Visited', ja: '訪問済み')
        : null;
    return Semantics(
      button: true,
      label: context.l10n(
        ko: [
          event.title,
          DateFormat.yMMMMd(locale).format(local),
          event.status,
          attendanceLabel,
        ].whereType<String>().join(', '),
        en: [
          event.title,
          DateFormat.yMMMMd(locale).format(local),
          event.status,
          attendanceLabel,
        ].whereType<String>().join(', '),
        ja: [
          event.title,
          DateFormat.yMMMMd(locale).format(local),
          event.status,
          attendanceLabel,
        ].whereType<String>().join(', '),
      ),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.MMM(locale).format(local).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        DateFormat.d(locale).format(local),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
                  color: attended ? colors.secondary : colors.outlineVariant,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: GBTSpacing.xs,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: GBTSpacing.xs,
                          runSpacing: GBTSpacing.xs,
                          children: [
                            GBTFieldBadge(
                              label: event.status.toUpperCase(),
                              color: colors.primary,
                            ),
                            if (attended)
                              GBTFieldBadge(
                                label: attendanceLabel!,
                                icon: Icons.verified_rounded,
                                color: colors.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          '${DateFormat.Hm(locale).format(local)}  ·  $locationLabel',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
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

/// EN: Uses server supplied venue identity before falling back to scope data.
/// KO: 서버가 제공한 공연장 정보를 우선 사용하고 없으면 연결 범위를 표시합니다.
String fieldEventSummaryLocationLabel(LiveEventSummary event) {
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
  return event.metaLabel;
}

/// EN: The single poster-led next event at the top of the agenda.
/// KO: 아젠다 상단에서 포스터로 강조하는 단 하나의 다음 이벤트입니다.
class FieldEventPosterFeature extends StatelessWidget {
  const FieldEventPosterFeature({
    super.key,
    required this.event,
    required this.onTap,
  });

  final LiveEventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final local = event.showStartTime.toLocal();
    return Semantics(
      button: true,
      label: context.l10n(
        ko: '다음 이벤트 ${event.title}',
        en: 'Next event ${event.title}',
        ja: '次のイベント ${event.title}',
      ),
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusCard),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useVertical =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(16) > 20;
              final poster = _FieldEventPoster(
                imageUrl: event.bannerUrl,
                title: event.title,
              );
              final document = _FieldEventFeatureDocument(
                event: event,
                dateLabel: DateFormat.yMMMd(locale).format(local),
                timeLabel: DateFormat.Hm(locale).format(local),
              );
              if (useVertical) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 16 / 9, child: poster),
                    document,
                  ],
                );
              }
              return SizedBox(
                height: 224,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 148, child: poster),
                    Expanded(child: document),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FieldEventPoster extends StatelessWidget {
  const _FieldEventPoster({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return GBTImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '$title 포스터',
          en: '$title poster',
          ja: '$title ポスター',
        ),
      );
    }
    return ColoredBox(
      color: colors.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 56,
          color: colors.secondary,
        ),
      ),
    );
  }
}

class _FieldEventFeatureDocument extends StatelessWidget {
  const _FieldEventFeatureDocument({
    required this.event,
    required this.dateLabel,
    required this.timeLabel,
  });

  final LiveEventSummary event;
  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locationLabel = fieldEventSummaryLocationLabel(event);
    return Padding(
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n(
                    ko: 'NEXT LIVE',
                    en: 'NEXT LIVE',
                    ja: 'NEXT LIVE',
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              GBTFieldBadge(
                label: event.status.toUpperCase(),
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.sm),
          Text(
            event.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: GBTSpacing.lg),
          Divider(color: colors.outlineVariant),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            '$dateLabel  ·  $timeLabel',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.place_outlined, size: 16, color: colors.secondary),
              const SizedBox(width: GBTSpacing.xs),
              Expanded(
                child: Text(
                  locationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  event.dDayLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
