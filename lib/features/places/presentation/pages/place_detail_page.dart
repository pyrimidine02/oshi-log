/// EN: Place detail page with photos, info, and verification
/// KO: 사진, 정보, 인증을 포함한 장소 상세 페이지
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_animations.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../favorites/application/favorites_controller.dart';
import '../../../favorites/domain/entities/favorite_entities.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../verification/application/verification_controller.dart';
import '../../../verification/presentation/widgets/verification_sheet.dart';
import '../../application/places_controller.dart';
import '../../domain/entities/place_comment_entities.dart';
import '../../domain/entities/place_entities.dart';
import '../../domain/entities/place_guide_entities.dart';
import '../../domain/utils/place_type_search.dart';
import '../utils/place_directions_launcher.dart';
import '../../../../core/widgets/common/registrant_credit_widget.dart';
import '../widgets/place_review_sheet.dart';

/// EN: Place detail page widget
/// KO: 장소 상세 페이지 위젯
class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placeDetailControllerProvider(placeId));
    Future<void> handleRefresh() async {
      await _refreshAll(ref);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '장소 기록', en: 'Place record', ja: '場所記録'),
      ),
      // EN: Sticky verify CTA — enabled once data is loaded.
      // KO: 고정 인증 CTA — 데이터 로드 완료 후 활성화.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.sm,
              GBTSpacing.md,
              GBTSpacing.sm,
            ),
            child: FilledButton.icon(
              onPressed: state.hasValue
                  ? () => _showVerificationSheet(
                      context,
                      ref,
                      placeId,
                      placeName: state.valueOrNull?.name,
                    )
                  : null,
              icon: const Icon(Icons.location_on_rounded),
              label: Text(
                context.l10n(
                  ko: '이곳에 다녀왔어요',
                  en: 'I visited here',
                  ja: 'ここに行ってきました',
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: state.when(
            loading: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return [
                SliverToBoxAdapter(
                  child: GBTShimmer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // EN: Compact media placeholder for the field record.
                        // KO: 필드 기록용 컴팩트 미디어 플레이스홀더입니다.
                        Container(
                          height: 184,
                          color: isDark
                              ? GBTColors.darkSurfaceVariant
                              : GBTColors.surfaceVariant,
                        ),
                        // EN: Title and metadata skeleton rows
                        // KO: 제목 및 메타데이터 스켈레톤 행
                        Padding(
                          padding: const EdgeInsets.all(GBTSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GBTShimmerContainer(height: 24, width: 200),
                              const SizedBox(height: GBTSpacing.sm),
                              GBTShimmerContainer(height: 16, width: 160),
                              const SizedBox(height: GBTSpacing.xs),
                              GBTShimmerContainer(height: 16, width: 120),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            error: (error, _) {
              final message = error is Failure
                  ? error.userMessage
                  : context.l10n(
                      ko: '장소 정보를 불러오지 못했어요',
                      en: 'Could not load place details',
                      ja: '場所情報を読み込めませんでした',
                    );
              return [
                SliverFillRemaining(
                  child: Center(
                    child: GBTErrorState(
                      message: message,
                      onRetry: () => ref
                          .read(placeDetailControllerProvider(placeId).notifier)
                          .load(forceRefresh: true),
                    ),
                  ),
                ),
              ];
            },
            data: (place) => _buildContent(context, ref, place),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll(WidgetRef ref) async {
    await Future.wait([
      ref
          .read(placeDetailControllerProvider(placeId).notifier)
          .load(forceRefresh: true),
      ref
          .read(placeGuidesControllerProvider(placeId).notifier)
          .load(forceRefresh: true),
      ref
          .read(placeCommentsControllerProvider(placeId).notifier)
          .load(forceRefresh: true),
      ref.read(favoritesControllerProvider.notifier).load(forceRefresh: true),
    ]);
  }

  List<Widget> _buildContent(
    BuildContext context,
    WidgetRef ref,
    PlaceDetail place,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final selection = ref.watch(projectSelectionControllerProvider);
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isFavorite = favoritesState.maybeWhen(
      data: (items) => items.any(
        (item) => item.entityId == place.id && item.type == FavoriteType.place,
      ),
      orElse: () => place.isFavorite,
    );
    final projectKey = selection.projectKey;
    final unitsState = projectKey != null && projectKey.isNotEmpty
        ? ref.watch(projectUnitsControllerProvider(projectKey))
        : null;
    final guidesState = ref.watch(placeGuidesControllerProvider(place.id));
    final commentsState = ref.watch(placeCommentsControllerProvider(place.id));

    // EN: Build gallery image list — use imageUrls if available, fallback to hero.
    // KO: 갤러리 이미지 목록 — imageUrls 우선, 없으면 hero 이미지로 대체.
    final galleryImages = place.imageUrls.isNotEmpty
        ? place.imageUrls
        : (place.heroImageUrl != null ? [place.heroImageUrl!] : <String>[]);

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaceDetailDocumentHeader(
              name: place.name,
              address: place.address,
              visitLabel: context.l10n(
                ko: '${place.visitCount ?? 0}명 방문',
                en: '${place.visitCount ?? 0} visits',
                ja: '${place.visitCount ?? 0}人が訪問',
              ),
              favoriteLabel: context.l10n(
                ko: '${place.favoriteCount ?? 0}명 관심',
                en: '${place.favoriteCount ?? 0} interested',
                ja: '${place.favoriteCount ?? 0}人がお気に入り',
              ),
              favoriteTooltip: isFavorite
                  ? context.l10n(
                      ko: '즐겨찾기 해제',
                      en: 'Remove favorite',
                      ja: 'お気に入り解除',
                    )
                  : context.l10n(
                      ko: '즐겨찾기 추가',
                      en: 'Add favorite',
                      ja: 'お気に入り追加',
                    ),
              isFavorite: isFavorite,
              onFavorite: () => ref
                  .read(favoritesControllerProvider.notifier)
                  .toggleFavorite(
                    entityId: place.id,
                    type: FavoriteType.place,
                    isCurrentlyFavorite: isFavorite,
                  ),
              directionsLabel: context.l10n(
                ko: '길안내',
                en: 'Directions',
                ja: '経路案内',
              ),
              onDirections: place.directions?.hasProviders ?? false
                  ? () => showPlaceDirectionsSheet(
                      context,
                      placeName: place.name,
                      directions: place.directions!,
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.md,
                0,
                GBTSpacing.md,
                GBTSpacing.lg,
              ),
              child: SizedBox(
                height: 184,
                width: double.infinity,
                child: galleryImages.isNotEmpty
                    ? _PhotoGallery(
                        imageUrls: galleryImages,
                        placeId: place.id,
                        placeName: place.name,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecordSectionHeader(
                    indexLabel: '01',
                    title: context.l10n(ko: '소개', en: 'About', ja: '紹介'),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Text(
                    place.description ??
                        context.l10n(
                          ko: '소개 정보가 없습니다.',
                          en: 'No description available.',
                          ja: '紹介情報がありません。',
                        ),
                    style: GBTTypography.bodyMedium.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xl),
                  _RecordSectionHeader(
                    indexLabel: '02',
                    title: context.l10n(
                      ko: '장소 분류',
                      en: 'Place categories',
                      ja: '場所カテゴリー',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                ],
              ),
            ),
            if (place.tags.isNotEmpty || place.types.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
                child: Wrap(
                  spacing: GBTSpacing.sm,
                  runSpacing: GBTSpacing.xs,
                  children:
                      (place.tags.isNotEmpty
                              ? place.tags
                              : place.types.map(_formatPlaceType))
                          .map((label) => _FieldTag(label: label))
                          .toList(growable: false),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
                child: Text(
                  context.l10n(
                    ko: '장소 분류 정보가 없습니다.',
                    en: 'No category information.',
                    ja: 'カテゴリー情報がありません。',
                  ),
                  style: GBTTypography.bodySmall.copyWith(
                    color: secondaryColor,
                  ),
                ),
              ),
            Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: GBTSpacing.xl),
                  _RecordSectionHeader(
                    indexLabel: '03',
                    title: context.l10n(
                      ko: '관련 밴드',
                      en: 'Related bands',
                      ja: '関連バンド',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  if (unitsState == null)
                    Text(
                      context.l10n(
                        ko: '관련 밴드 정보가 없습니다.',
                        en: 'No related band information.',
                        ja: '関連バンド情報がありません。',
                      ),
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                      ),
                    )
                  else
                    unitsState.when(
                      loading: () => const SizedBox(
                        height: 32,
                        child: GBTShimmer(
                          child: SizedBox(width: 120, height: 28),
                        ),
                      ),
                      error: (error, _) {
                        final message = error is Failure
                            ? error.userMessage
                            : context.l10n(
                                ko: '관련 밴드를 불러오지 못했어요',
                                en: 'Could not load related bands',
                                ja: '関連バンドを読み込めませんでした',
                              );
                        return Text(
                          message,
                          style: GBTTypography.bodySmall.copyWith(
                            color: secondaryColor,
                          ),
                        );
                      },
                      data: (units) {
                        if (units.isEmpty) {
                          return Text(
                            context.l10n(
                              ko: '관련 밴드 정보가 없습니다.',
                              en: 'No related band information.',
                              ja: '関連バンド情報がありません。',
                            ),
                            style: GBTTypography.bodySmall.copyWith(
                              color: secondaryColor,
                            ),
                          );
                        }
                        return Wrap(
                          spacing: GBTSpacing.xs,
                          runSpacing: GBTSpacing.xs,
                          children: units
                              .map(
                                (unit) => _FieldTag(
                                  label: unit.displayName.isNotEmpty
                                      ? unit.displayName
                                      : unit.code,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  const SizedBox(height: GBTSpacing.xl),
                  _RecordSectionHeader(
                    indexLabel: '04',
                    title: context.l10n(
                      ko: '장소 가이드',
                      en: 'Place guides',
                      ja: '場所ガイド',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  _GuideSection(
                    state: guidesState,
                    isDark: isDark,
                    onRetry: () => ref
                        .read(placeGuidesControllerProvider(place.id).notifier)
                        .load(forceRefresh: true),
                  ),
                  const SizedBox(height: GBTSpacing.xl),
                  _RecordSectionHeader(
                    indexLabel: '05',
                    title: context.l10n(
                      ko: '방문 후기',
                      en: 'Visit reviews',
                      ja: '訪問レビュー',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  _CommentSection(
                    placeId: place.id,
                    state: commentsState,
                    onRetry: () => ref
                        .read(
                          placeCommentsControllerProvider(place.id).notifier,
                        )
                        .load(forceRefresh: true),
                  ),
                  const SizedBox(height: GBTSpacing.xl),
                  _RecordSectionHeader(
                    indexLabel: '06',
                    title: context.l10n(
                      ko: '기록 기여자',
                      en: 'Record contributors',
                      ja: '記録協力者',
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  // EN: Contributors credit — who registered and edited this place.
                  // KO: 기여자 크레딧 — 이 장소를 등록하고 수정한 사람을 표시합니다.
                  ContributorsCreditWidget(
                    entityType: 'places',
                    entityId: place.id,
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
}

/// EN: Compact editorial identity block for a place field record.
/// KO: 장소 필드 기록을 위한 컴팩트한 에디토리얼 식별 블록입니다.
class PlaceDetailDocumentHeader extends StatelessWidget {
  const PlaceDetailDocumentHeader({
    super.key,
    required this.name,
    required this.address,
    required this.visitLabel,
    required this.favoriteLabel,
    required this.favoriteTooltip,
    required this.isFavorite,
    required this.onFavorite,
    required this.directionsLabel,
    this.onDirections,
  });

  final String name;
  final String address;
  final String visitLabel;
  final String favoriteLabel;
  final String favoriteTooltip;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final String directionsLabel;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      key: const ValueKey('place-detail-document-header'),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.md,
        GBTSpacing.md,
        GBTSpacing.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: colors.primary),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLACE RECORD',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.xxs),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: GBTSpacing.xs),
                    Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: GBTSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldStat(
                        icon: Icons.directions_walk_rounded,
                        label: visitLabel,
                      ),
                      const SizedBox(height: GBTSpacing.xs),
                      _FieldStat(
                        icon: Icons.bookmark_border_rounded,
                        label: favoriteLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: GBTSpacing.sm),
                  Wrap(
                    spacing: GBTSpacing.sm,
                    runSpacing: GBTSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (onDirections != null)
                        FilledButton.icon(
                          onPressed: onDirections,
                          icon: const Icon(Icons.near_me_outlined, size: 18),
                          label: Text(directionsLabel),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      IconButton.outlined(
                        onPressed: onFavorite,
                        tooltip: favoriteTooltip,
                        icon: Icon(
                          isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStat extends StatelessWidget {
  const _FieldStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: GBTSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordSectionHeader extends StatelessWidget {
  const _RecordSectionHeader({required this.indexLabel, required this.title});

  final String indexLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              indexLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTag extends StatelessWidget {
  const _FieldTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xxs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ========================================
// EN: Photo gallery with PageView + dot indicator
// KO: PageView + 점 표시기를 갖춘 사진 갤러리
// ========================================

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({
    required this.imageUrls,
    required this.placeId,
    required this.placeName,
  });

  final List<String> imageUrls;
  final String placeId;
  final String placeName;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    if (images.length == 1) {
      return Hero(
        tag: GBTHeroTags.placeImage(widget.placeId),
        transitionOnUserGestures: true,
        child: GBTImage(
          imageUrl: images.first,
          fit: BoxFit.cover,
          semanticLabel: context.l10n(
            ko: '${widget.placeName} 사진',
            en: '${widget.placeName} photo',
            ja: '${widget.placeName} 写真',
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // EN: PageView with Hero on first image only.
        // KO: 첫 번째 이미지에만 Hero 적용한 PageView.
        PageView.builder(
          controller: _controller,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final child = GBTImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              semanticLabel: context.l10n(
                ko: '${widget.placeName} 사진 ${index + 1}',
                en: '${widget.placeName} photo ${index + 1}',
                ja: '${widget.placeName} 写真 ${index + 1}',
              ),
            );
            if (index == 0) {
              return Hero(
                tag: GBTHeroTags.placeImage(widget.placeId),
                transitionOnUserGestures: true,
                child: child,
              );
            }
            return child;
          },
        ),
        // EN: Page count uses the page surface, not a photo overlay gradient.
        // KO: 사진 오버레이 그라데이션 대신 페이지 표면으로 장수를 표시합니다.
        Positioned(
          top: GBTSpacing.md,
          right: GBTSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.sm,
              vertical: GBTSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              '${_currentPage + 1}/${images.length}',
              style: GBTTypography.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // EN: Animated dot indicator — bottom-center.
        // KO: 애니메이션 점 표시기 — 하단 중앙.
        Positioned(
          bottom: GBTSpacing.md,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length.clamp(0, 10),
              (index) => AnimatedContainer(
                duration: GBTAnimations.fast,
                curve: GBTAnimations.defaultCurve,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ========================================
// EN: Guide section — card style items
// KO: 가이드 섹션 — 카드 스타일 아이템
// ========================================

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.state,
    required this.isDark,
    required this.onRetry,
  });

  final AsyncValue<List<PlaceGuideSummary>> state;
  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => GBTShimmer(
        child: Column(
          children: [
            GBTShimmerContainer(height: 72, width: double.infinity),
            const SizedBox(height: GBTSpacing.sm),
            GBTShimmerContainer(height: 72, width: double.infinity),
          ],
        ),
      ),
      error: (error, _) {
        if (_isForbidden(error)) {
          return _SectionMessage(
            message: context.l10n(
              ko: '아직 준비중입니다.',
              en: 'Coming soon.',
              ja: '準備中です。',
            ),
          );
        }
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '가이드를 불러오지 못했어요',
                en: 'Could not load guides',
                ja: 'ガイドを読み込めませんでした',
              );
        return _SectionMessage(message: message, onRetry: onRetry);
      },
      data: (guides) {
        if (guides.isEmpty) {
          return _SectionMessage(
            message: context.l10n(
              ko: '등록된 가이드가 없습니다.',
              en: 'No guides available.',
              ja: '登録されたガイドがありません。',
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: guides.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final guide = guides[index];
            return _GuideCard(guide: guide, isDark: isDark, index: index);
          },
        );
      },
    );
  }
}

/// EN: Guide card — numbered index + title + preview + metadata.
/// KO: 가이드 카드 — 번호 인덱스 + 제목 + 미리보기 + 메타데이터.
class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.isDark,
    required this.index,
  });

  final PlaceGuideSummary guide;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Semantics(
      label: context.l10n(
        ko: '가이드: ${guide.title.isNotEmpty ? guide.title : '가이드'}',
        en: 'Guide: ${guide.title.isNotEmpty ? guide.title : 'Guide'}',
        ja: 'ガイド: ${guide.title.isNotEmpty ? guide.title : 'ガイド'}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: GBTTypography.labelSmall.copyWith(
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: GBTSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.title.isNotEmpty
                        ? guide.title
                        : context.l10n(ko: '가이드', en: 'Guide', ja: 'ガイド'),
                    style: GBTTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (guide.preview.isNotEmpty) ...[
                    const SizedBox(height: GBTSpacing.xxs),
                    Text(
                      guide.preview,
                      style: GBTTypography.bodySmall.copyWith(
                        color: secondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: GBTSpacing.xs),
                  Row(
                    children: [
                      if (guide.updatedAtLabel.isNotEmpty)
                        Text(
                          guide.updatedAtLabel,
                          style: GBTTypography.labelSmall.copyWith(
                            color: tertiaryColor,
                          ),
                        ),
                      if (guide.hasImages && guide.updatedAtLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: GBTSpacing.sm),
                          child: Row(
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: 12,
                                color: tertiaryColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${guide.imageCount}',
                                style: GBTTypography.labelSmall.copyWith(
                                  color: tertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: GBTSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: tertiaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Comment section — review cards
// KO: 댓글 섹션 — 리뷰 카드
// ========================================

class _CommentSection extends ConsumerStatefulWidget {
  const _CommentSection({
    required this.placeId,
    required this.state,
    required this.onRetry,
  });

  final String placeId;
  final AsyncValue<List<PlaceComment>> state;
  final VoidCallback onRetry;

  @override
  ConsumerState<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<_CommentSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profile = isAuthenticated
        ? ref.watch(userProfileControllerProvider).valueOrNull
        : null;
    final currentUserId = profile?.id ?? '';
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final selection = ref.watch(projectSelectionControllerProvider);
    final canModerate =
        profile != null &&
        (profile.canModerateCommunity ||
            profile.canModerateProjectCommunity(
              projectId: selectedProjectId,
              projectCode: selection.projectKey,
            ));

    return widget.state.when(
      loading: () => GBTShimmer(
        child: Column(
          children: [
            GBTShimmerContainer(height: 88, width: double.infinity),
            const SizedBox(height: GBTSpacing.sm),
            GBTShimmerContainer(height: 88, width: double.infinity),
          ],
        ),
      ),
      error: (error, _) {
        if (_isForbidden(error)) {
          return _SectionMessage(
            message: context.l10n(
              ko: '아직 준비중입니다.',
              en: 'Coming soon.',
              ja: '準備中です。',
            ),
          );
        }
        final message = error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '후기를 불러오지 못했어요',
                en: 'Could not load reviews',
                ja: 'レビューを読み込めませんでした',
              );
        return _SectionMessage(message: message, onRetry: widget.onRetry);
      },
      data: (comments) {
        if (comments.isEmpty) {
          return _SectionMessage(
            message: context.l10n(
              ko: '등록된 후기가 없습니다.',
              en: 'No reviews available.',
              ja: '登録されたレビューがありません。',
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: comments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final comment = comments[index];
            final canDelete =
                profile != null &&
                (canModerate ||
                    (currentUserId.isNotEmpty &&
                        comment.authorId == currentUserId));

            return _ReviewCard(
              comment: comment,
              isDark: isDark,
              onPhotoTap: _showPhotoPreview,
              canDelete: canDelete,
              onDelete: () => _deleteComment(comment.id),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteComment(String commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.l10n(ko: '후기 삭제', en: 'Delete review', ja: 'レビュー削除'),
          ),
          content: Text(
            context.l10n(
              ko: '이 후기를 삭제할까요?',
              en: 'Delete this review?',
              ja: 'このレビューを削除しますか？',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n(ko: '삭제', en: 'Delete', ja: '削除')),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }

    final result = await ref
        .read(placeCommentsControllerProvider(widget.placeId).notifier)
        .deleteComment(commentId);
    if (!mounted) {
      return;
    }

    final message = result is Success<void>
        ? context.l10n(ko: '후기를 삭제했어요', en: 'Review deleted', ja: 'レビューを削除しました')
        : result is Err<void>
        ? result.failure.userMessage
        : context.l10n(
            ko: '후기 삭제에 실패했어요',
            en: 'Failed to delete review',
            ja: 'レビューの削除に失敗しました',
          );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPhotoPreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return Semantics(
          label: context.l10n(
            ko: '사진 확대 보기. 탭하여 닫기',
            en: 'Photo preview. Tap to close.',
            ja: '写真プレビュー。タップで閉じる',
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Dialog(
              insetPadding: const EdgeInsets.all(GBTSpacing.md),
              backgroundColor: Colors.transparent,
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  child: GBTImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    semanticLabel: context.l10n(
                      ko: '방문 후기 사진 확대',
                      en: 'Review photo zoomed',
                      ja: 'レビュー写真拡大',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// EN: Review card — avatar initials + body + photo strip.
/// KO: 리뷰 카드 — 이니셜 아바타 + 본문 + 사진 스트립.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.comment,
    required this.isDark,
    required this.onPhotoTap,
    required this.canDelete,
    required this.onDelete,
  });

  final PlaceComment comment;
  final bool isDark;
  final ValueChanged<String> onPhotoTap;
  final bool canDelete;
  final VoidCallback onDelete;

  String get _authorInitial {
    if (comment.authorId.isNotEmpty) {
      return comment.authorId[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final authorLabel = comment.authorId.isNotEmpty
        ? context.l10n(ko: '방문자', en: 'Visitor', ja: '訪問者')
        : context.l10n(ko: '익명 방문자', en: 'Anonymous visitor', ja: '匿名の訪問者');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN: Author row — avatar circle + name + date.
          // KO: 작성자 행 — 아바타 원 + 이름 + 날짜.
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isDark ? GBTColors.darkPrimary : GBTColors.primary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _authorInitial,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorLabel,
                      style: GBTTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.createdAtLabel.isNotEmpty)
                      Text(
                        comment.createdAtLabel,
                        style: GBTTypography.labelSmall.copyWith(
                          color: tertiaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (comment.replyCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? GBTColors.darkPrimary : GBTColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                  ),
                  child: Text(
                    context.l10n(
                      ko: '답글 ${comment.replyCount}',
                      en: 'Replies ${comment.replyCount}',
                      ja: '返信 ${comment.replyCount}',
                    ),
                    style: GBTTypography.labelSmall.copyWith(
                      color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    ),
                  ),
                ),
              if (canDelete)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: tertiaryColor,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        context.l10n(ko: '삭제', en: 'Delete', ja: '削除'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // EN: Body text.
          // KO: 본문 텍스트.
          if (comment.body.isNotEmpty) ...[
            const SizedBox(height: GBTSpacing.sm),
            GBTLinkifiedText(
              comment.body,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // EN: Horizontal photo strip — 80px square thumbnails.
          // KO: 가로 사진 스트립 — 80px 정사각형 썸네일.
          if (comment.photoUrls.isNotEmpty) ...[
            const SizedBox(height: GBTSpacing.sm),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: comment.photoUrls.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: GBTSpacing.xs),
                itemBuilder: (context, index) {
                  final url = comment.photoUrls[index];
                  return Semantics(
                    label: context.l10n(
                      ko: '방문 후기 사진 ${index + 1}. 탭하여 확대',
                      en: 'Review photo ${index + 1}. Tap to zoom.',
                      ja: 'レビュー写真 ${index + 1}。タップで拡大',
                    ),
                    button: true,
                    child: GestureDetector(
                      onTap: () => onPhotoTap(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          GBTSpacing.radiusSm,
                        ),
                        child: GBTImage(
                          imageUrl: url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          semanticLabel: context.l10n(
                            ko: '방문 후기 사진',
                            en: 'Review photo',
                            ja: 'レビュー写真',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: GBTTypography.bodySmall.copyWith(color: secondaryColor),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: GBTSpacing.xs),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
          ),
        ],
      ],
    );
  }
}

bool _isForbidden(Object error) {
  return error is AuthFailure && error.code == '403';
}

String _formatPlaceType(String type) {
  return placeTypeLabel(type);
}

void _showVerificationSheet(
  BuildContext context,
  WidgetRef ref,
  String placeId, {
  String? placeName,
}) {
  ref.read(verificationControllerProvider.notifier).reset();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => VerificationSheet(
      title: context.l10n(ko: '방문 인증', en: 'Visit verification', ja: '訪問認証'),
      description: context.l10n(
        ko: '현재 위치를 확인해 방문 인증을 진행합니다.',
        en: 'Verify your current location to complete visit verification.',
        ja: '現在地を確認して訪問認証を進めます。',
      ),
      onVerify: () => ref
          .read(verificationControllerProvider.notifier)
          .verifyPlace(placeId, targetName: placeName),
      onWriteReview: () => _showReviewSheet(context, placeId),
    ),
  );
}

void _showReviewSheet(BuildContext context, String placeId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => PlaceReviewSheet(placeId: placeId),
  );
}
