/// EN: On-site notices, access, presentation, and server-filtered fan tips.
/// KO: 현장 주의·접근·제시 화면과 서버에서 분류한 팬 팁입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_comment_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_guide_entities.dart';
import 'package:oshi_log/features/place/places/presentation/utils/place_directions_launcher.dart';
import 'place_description_body.dart';

/// EN: Always-visible manners; missing rules never grant permission.
/// KO: 상시 매너 안내이며 규정 정보가 없다고 허가로 해석하지 않습니다.
class PlaceVisitNotice extends StatelessWidget {
  const PlaceVisitNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('place-visit-notice'),
    width: double.infinity,
    padding: const EdgeInsets.all(GBTSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(ko: '방문 전 주의', en: 'Before your visit', ja: '訪問の注意'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          context.l10n(
            ko: '영업·출입·촬영 규정은 현장 안내와 시설의 공식 공지를 확인하세요. 정보 없음은 출입·촬영 허가가 아닙니다.',
            en: 'Check posted rules and the facility’s official notices for hours, entry and photography. Missing information is not permission.',
            ja: '営業時間・立入・撮影のルールは現地の掲示や施設の公式案内で確認してください。情報がないことは許可を意味しません。',
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Text(
          context.l10n(
            ko: '사유지·주거지에 들어가지 말고 통행과 영업을 방해하지 마세요. 사람을 촬영할 때는 동의를 구하세요.',
            en: 'Respect private property and homes. Keep paths and businesses clear, and ask before photographing people.',
            ja: '私有地・住宅には立ち入らず、通行や営業を妨げないでください。人を撮影する際は同意を得てください。',
          ),
        ),
      ],
    ),
  );
}

/// EN: Full address and on-site presentation use the received language as-is.
/// KO: 전체 주소와 현장 제시는 수신한 언어를 그대로 사용합니다.
class PlaceAccessSection extends StatelessWidget {
  const PlaceAccessSection({super.key, required this.place, this.onAddToToday});
  final PlaceDetail place;
  final VoidCallback? onAddToToday;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('place-access-section'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(
        place.address.trim().isNotEmpty
            ? place.address
            : context.l10n(
                ko: '주소 정보가 없습니다.',
                en: 'No address available.',
                ja: '住所情報がありません。',
              ),
      ),
      const SizedBox(height: GBTSpacing.sm),
      Text(
        _originalUnconfirmed(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: GBTSpacing.md),
      Wrap(
        spacing: GBTSpacing.sm,
        runSpacing: GBTSpacing.sm,
        children: [
          if (onAddToToday != null)
            OutlinedButton.icon(
              key: const ValueKey('place-add-to-today'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onAddToToday,
              icon: const Icon(Icons.playlist_add),
              label: Text(
                context.l10n(
                  ko: '오늘 목록에 추가',
                  en: 'Add to today',
                  ja: '今日のリストに追加',
                ),
              ),
            ),
          FilledButton.icon(
            key: const ValueKey('place-show-onsite'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PlacePresentationSheet(place: place),
            ),
            icon: const Icon(Icons.text_fields),
            label: Text(
              context.l10n(ko: '현지에서 보여주기', en: 'Show on site', ja: '現地で見せる'),
            ),
          ),
          if (place.address.trim().isNotEmpty)
            OutlinedButton.icon(
              key: const ValueKey('place-copy-address'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => _copy(context, place.address),
              icon: const Icon(Icons.copy_outlined),
              label: Text(
                context.l10n(ko: '주소 복사', en: 'Copy address', ja: '住所をコピー'),
              ),
            ),
          if (place.directions?.hasProviders ?? false)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => showPlaceDirectionsSheet(
                context,
                placeName: place.name,
                directions: place.directions!,
              ),
              icon: const Icon(Icons.near_me_outlined),
              label: Text(
                context.l10n(ko: '경로 찾기', en: 'Find a route', ja: '経路を調べる'),
              ),
            ),
        ],
      ),
      const SizedBox(height: GBTSpacing.md),
      PlaceSavedStamp(place: place),
    ],
  );
}

/// EN: A local snapshot timestamp is distinct from editorial or visit dates.
/// KO: 로컬 저장 시각을 편집일·방문일과 구분합니다.
class PlaceSavedStamp extends StatelessWidget {
  const PlaceSavedStamp({super.key, required this.place});
  final PlaceDetail place;

  @override
  Widget build(BuildContext context) {
    final savedAt = place.savedAt;
    if (savedAt == null) {
      return Text(
        context.l10n(
          ko: '마지막 저장 시각을 확인할 수 없습니다.',
          en: 'Last saved time unavailable.',
          ja: '最終保存時刻は不明です。',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final stamp = DateFormat('yyyy.MM.dd HH:mm').format(savedAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(
            ko: '마지막 저장 $stamp · 기기 시간',
            en: 'Last saved $stamp · device time',
            ja: '最終保存 $stamp · 端末時刻',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (place.isFromCache || place.isCacheStale)
          Text(
            context.l10n(
              ko: '기기에 저장된 정보를 표시합니다. 현재 현장 상황과 다를 수 있습니다.',
              en: 'Showing a saved copy. Current conditions may differ.',
              ja: '端末に保存された情報です。現在の現地状況とは異なる場合があります。',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// EN: Scrollable large type keeps full names and addresses available offline.
/// KO: 스크롤 가능한 큰 글자로 이름·주소 전체를 오프라인에서도 제시합니다.
class PlacePresentationSheet extends StatelessWidget {
  const PlacePresentationSheet({super.key, required this.place});
  final PlaceDetail place;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        leading: CloseButton(),
        title: Text(
          context.l10n(ko: '현지에서 보여주기', en: 'Show on site', ja: '現地で見せる'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GBTSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_originalUnconfirmed(context)),
              const SizedBox(height: GBTSpacing.xl),
              SelectableText(
                place.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: GBTSpacing.lg),
              SelectableText(
                place.address.trim().isNotEmpty
                    ? place.address
                    : context.l10n(
                        ko: '주소 정보가 없습니다.',
                        en: 'No address available.',
                        ja: '住所情報がありません。',
                      ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: GBTSpacing.xl),
              PlaceSavedStamp(place: place),
              const SizedBox(height: GBTSpacing.lg),
              FilledButton.icon(
                key: const ValueKey('place-copy-name-address'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _copy(
                  context,
                  [
                    place.name,
                    if (place.address.trim().isNotEmpty) place.address,
                  ].join('\n'),
                ),
                icon: const Icon(Icons.copy_outlined),
                label: Text(
                  context.l10n(
                    ko: '이름·주소 복사',
                    en: 'Copy name and address',
                    ja: '名前・住所をコピー',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _originalUnconfirmed(BuildContext context) => context.l10n(
  ko: '원문 미확인 · 현재 제공된 이름과 주소입니다.',
  en: 'Original wording unconfirmed · name and address as provided.',
  ja: '原文未確認 · 現在提供されている名前と住所です。',
);

Future<void> _copy(BuildContext context, String value) async {
  var copied = false;
  try {
    await Clipboard.setData(ClipboardData(text: value));
    copied = true;
  } on PlatformException {
    // EN: Keep platform clipboard failures in the normal feedback flow.
    // KO: 클립보드 오류는 일반 안내 흐름에서 처리합니다.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        copied
            ? context.l10n(ko: '복사했습니다.', en: 'Copied.', ja: 'コピーしました。')
            : context.l10n(
                ko: '복사하지 못했습니다.',
                en: 'Could not copy.',
                ja: 'コピーできませんでした。',
              ),
      ),
    ),
  );
}

/// EN: Pinned notices and the chosen server category fail independently.
/// KO: 고정 안내와 선택한 서버 분류를 독립적으로 조회·재시도합니다.
class PlaceTipsSection extends ConsumerStatefulWidget {
  const PlaceTipsSection({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceTipsSection> createState() => _PlaceTipsSectionState();
}

class _PlaceTipsSectionState extends ConsumerState<PlaceTipsSection> {
  PlaceTipCategory category = PlaceTipCategory.access;

  @override
  Widget build(BuildContext context) {
    final pinnedKey = (
      placeId: widget.placeId,
      category: PlaceTipCategory.pinned,
    );
    final selectedKey = (placeId: widget.placeId, category: category);
    final pinned = ref.watch(placeTipsProvider(pinnedKey));
    final tips = ref.watch(placeTipsProvider(selectedKey));
    final pinnedIds =
        pinned.valueOrNull?.map((item) => item.id).toSet() ?? <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n(
            ko: '팬의 경험담입니다. 시설의 공식 안내와 현장 규정을 우선 확인하세요.',
            en: 'Fan experiences. Check official guidance and posted rules first.',
            ja: 'ファンの体験談です。施設の公式案内と現地のルールを優先してください。',
          ),
        ),
        const SizedBox(height: GBTSpacing.sm),
        Wrap(
          spacing: GBTSpacing.sm,
          runSpacing: GBTSpacing.xs,
          children: [
            for (final choice in [
              PlaceTipCategory.access,
              PlaceTipCategory.routes,
              PlaceTipCategory.advice,
            ])
              ChoiceChip(
                key: ValueKey('place-tips-${choice.name}'),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(switch (choice) {
                  PlaceTipCategory.access => context.l10n(
                    ko: '접근',
                    en: 'Access',
                    ja: 'アクセス',
                  ),
                  PlaceTipCategory.routes => context.l10n(
                    ko: '경로',
                    en: 'Route',
                    ja: 'ルート',
                  ),
                  _ => context.l10n(ko: '조언', en: 'Advice', ja: 'アドバイス'),
                }),
                selected: category == choice,
                onSelected: (_) => setState(() => category = choice),
              ),
          ],
        ),
        const SizedBox(height: GBTSpacing.sm),
        _TipList(
          state: pinned,
          pinned: true,
          onRetry: () => ref.invalidate(placeTipsProvider(pinnedKey)),
        ),
        _TipList(
          state: tips.whenData(
            (items) => items
                .where((item) => !pinnedIds.contains(item.id))
                .take(3)
                .toList(),
          ),
          onRetry: () => ref.invalidate(placeTipsProvider(selectedKey)),
        ),
      ],
    );
  }
}

class _TipList extends StatelessWidget {
  const _TipList({
    required this.state,
    required this.onRetry,
    this.pinned = false,
  });
  final AsyncValue<List<PlaceComment>> state;
  final VoidCallback onRetry;
  final bool pinned;

  @override
  Widget build(BuildContext context) => state.when(
    loading: () => const Padding(
      padding: EdgeInsets.all(GBTSpacing.md),
      child: CircularProgressIndicator(),
    ),
    error: (_, __) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pinned
              ? context.l10n(
                  ko: '고정 안내를 불러오지 못했습니다.',
                  en: 'Could not load pinned notes.',
                  ja: '固定案内を読み込めませんでした。',
                )
              : context.l10n(
                  ko: '팁을 불러오지 못했습니다.',
                  en: 'Could not load tips.',
                  ja: 'Tipsを読み込めませんでした。',
                ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
        ),
      ],
    ),
    data: (items) {
      if (items.isEmpty) {
        return pinned
            ? const SizedBox.shrink()
            : Text(
                context.l10n(
                  ko: '이 분류에 등록된 팁이 없습니다.',
                  en: 'No tips in this category.',
                  ja: 'この分類のTipsはまだありません。',
                ),
              );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pinned)
                    Text(
                      context.l10n(ko: '고정 안내', en: 'Pinned note', ja: '固定案内'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (item.createdAtLabel.isNotEmpty)
                    Text(
                      context.l10n(
                        ko: '게시일 ${item.createdAtLabel}',
                        en: 'Posted ${item.createdAtLabel}',
                        ja: '投稿日 ${item.createdAtLabel}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (item.isPreview)
                    Text(
                      context.l10n(
                        ko: '댓글 요약',
                        en: 'Comment preview',
                        ja: 'コメントの要約',
                      ),
                    ),
                  if (item.body.trim().isNotEmpty)
                    PlaceDescriptionBody(description: item.body),
                  if (item.bestRoute?.trim().isNotEmpty ?? false)
                    PlaceDescriptionBody(description: item.bestRoute),
                  if (item.advice?.trim().isNotEmpty ?? false)
                    PlaceDescriptionBody(description: item.advice),
                  const Divider(),
                ],
              ),
            ),
        ],
      );
    },
  );
}

/// EN: Full guides use the existing safe Markdown renderer, loaded on demand.
/// KO: 전체 가이드는 필요할 때 조회하며 기존 안전 Markdown 렌더러를 사용합니다.
class PlaceGuideReader extends ConsumerWidget {
  const PlaceGuideReader({
    super.key,
    required this.placeId,
    required this.guide,
  });
  final String placeId;
  final PlaceGuideSummary guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (placeId: placeId, guideId: guide.id);
    final state = ref.watch(placeGuideDetailProvider(key));
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          title: Text(
            context.l10n(ko: '현지 가이드', en: 'On-site guide', ja: '現地ガイド'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => GBTErrorState(
                message: context.l10n(
                  ko: '가이드 본문을 불러오지 못했습니다.',
                  en: 'Could not load the full guide.',
                  ja: 'ガイド本文を読み込めませんでした。',
                ),
                onRetry: () => ref.invalidate(placeGuideDetailProvider(key)),
              ),
              data: (detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Text(placeGuideUpdatedLabel(context, detail.updatedAt)),
                  const SizedBox(height: GBTSpacing.lg),
                  if (detail.contentMarkdown.trim().isEmpty)
                    Text(
                      context.l10n(
                        ko: '등록된 가이드 본문이 없습니다.',
                        en: 'No guide content available.',
                        ja: 'ガイド本文がありません。',
                      ),
                    )
                  else
                    PlaceDescriptionBody(description: detail.contentMarkdown),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Do not imply that editorial timestamps confirm current conditions.
/// KO: 편집 시각을 현장 상황의 확인일로 표현하지 않습니다.
String placeGuideUpdatedLabel(BuildContext context, DateTime? updatedAt) {
  final stamp = updatedAt == null
      ? '—'
      : DateFormat('yyyy.MM.dd').format(updatedAt.toLocal());
  return context.l10n(
    ko: '가이드 수정일 $stamp · 현장 확인일 아님',
    en: 'Guide updated $stamp · not an on-site check',
    ja: 'ガイド更新日 $stamp · 現地確認日ではありません',
  );
}
