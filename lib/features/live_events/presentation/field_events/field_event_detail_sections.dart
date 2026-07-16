/// EN: Content sections for the clean-sheet event detail dossier.
/// KO: 신규 이벤트 상세 도시에용 콘텐츠 섹션입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/theme.dart';
import '../../../music/domain/entities/music_entities.dart';

/// EN: Numbered setlist rail backed by the existing music provider.
/// KO: 기존 음악 프로바이더를 사용하는 번호형 세트리스트 레일입니다.
class FieldEventSetlistSection extends StatelessWidget {
  const FieldEventSetlistSection({
    super.key,
    required this.state,
    required this.onSongTap,
    this.hasProjectContext = true,
  });

  final AsyncValue<MusicLiveSetlist?> state;
  final ValueChanged<MusicSetlistItem> onSongTap;
  final bool hasProjectContext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          eyebrow: context.l10n(
            ko: 'PERFORMANCE LOG',
            en: 'PERFORMANCE LOG',
            ja: 'PERFORMANCE LOG',
          ),
          title: context.l10n(ko: '세트리스트', en: 'Setlist', ja: 'セットリスト'),
        ),
        const SizedBox(height: GBTSpacing.md),
        state.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(
            error is Failure
                ? error.userMessage
                : context.l10n(
                    ko: '세트리스트를 불러오지 못했어요.',
                    en: 'Could not load the setlist.',
                    ja: 'セットリストを読み込めませんでした。',
                  ),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          data: (setlist) {
            if (setlist == null || setlist.items.isEmpty) {
              return Text(
                context.l10n(
                  ko: '세트리스트가 아직 등록되지 않았어요.',
                  en: 'The setlist has not been registered yet.',
                  ja: 'セットリストはまだ登録されていません。',
                ),
                style: TextStyle(color: colors.onSurfaceVariant),
              );
            }
            return Column(
              children: [
                for (final item in setlist.items)
                  _SetlistRow(
                    item: item,
                    hasProjectContext: hasProjectContext,
                    onTap: () => onSongTap(item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SetlistRow extends StatelessWidget {
  const _SetlistRow({
    required this.item,
    required this.hasProjectContext,
    required this.onTap,
  });

  final MusicSetlistItem item;
  final bool hasProjectContext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNavigable = hasProjectContext && item.hasSongLink;
    final metadata = <String>[
      if ((item.unitName ?? '').trim().isNotEmpty) item.unitName!,
      if ((item.versionCode ?? '').trim().isNotEmpty) item.versionCode!,
      item.segmentType,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isNavigable ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  item.order.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.songTitle ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xxs),
                    Text(
                      metadata.join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isEncore)
                Padding(
                  padding: const EdgeInsets.only(left: GBTSpacing.sm),
                  child: Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: colors.tertiary,
                  ),
                ),
              if (isNavigable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Editorial section title shared across detail content.
/// KO: 상세 콘텐츠가 공유하는 에디토리얼 섹션 제목입니다.
class FieldEventSectionHeading extends StatelessWidget {
  const FieldEventSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _SectionHeading(eyebrow: eyebrow, title: title);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
