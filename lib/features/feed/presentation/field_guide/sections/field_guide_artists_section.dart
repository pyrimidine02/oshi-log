/// EN: Artist directory for the Field Guide.
/// KO: Field Guide를 위한 아티스트 디렉터리.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/widgets/common/gbt_image.dart';
import '../../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../projects/domain/entities/project_entities.dart';
import '../field_guide_providers.dart';

class FieldGuideArtistsSection extends ConsumerWidget {
  const FieldGuideArtistsSection({
    super.key,
    required this.onRefresh,
    required this.onArtistTap,
  });

  final Future<void> Function() onRefresh;
  final ValueChanged<Unit> onArtistTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectKey = ref.watch(fieldGuideProjectKeyProvider);
    final state = ref.watch(fieldGuideArtistsProvider);

    if (projectKey == null || projectKey.trim().isEmpty) {
      return _ArtistsEmpty(
        title: context.l10n(
          ko: '프로젝트를 먼저 선택해주세요',
          en: 'Choose a project first',
          ja: '先にプロジェクトを選択してください',
        ),
        subtitle: context.l10n(
          ko: '프로젝트를 선택하면 아티스트 안내서가 열립니다.',
          en: 'The artist guide opens after you select a project.',
          ja: 'プロジェクトを選ぶとアーティストガイドが開きます。',
        ),
        onRefresh: onRefresh,
      );
    }

    return state.when(
      loading: () => const _ArtistsSkeleton(),
      error: (error, _) => _ArtistsFailure(
        message: error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '아티스트를 불러오지 못했어요',
                en: 'Could not load artists',
                ja: 'アーティストを読み込めませんでした',
              ),
        onRetry: onRefresh,
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return _ArtistsEmpty(
            title: context.l10n(
              ko: '등록된 아티스트가 없어요',
              en: 'No artists are registered',
              ja: '登録されたアーティストはありません',
            ),
            subtitle: context.l10n(
              ko: '새 아티스트가 추가되면 이 디렉터리에 나타납니다.',
              en: 'New artists will appear in this directory.',
              ja: '新しいアーティストがこの一覧に追加されます。',
            ),
            onRefresh: onRefresh,
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.lg,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ArtistsIntro(count: artists.length),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  GBTSpacing.pageHorizontal,
                  0,
                  GBTSpacing.pageHorizontal,
                  GBTSpacing.bottomNavClearanceOf(context),
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artist = artists[index];
                    return _ArtistCard(
                      artist: artist,
                      onTap: () => onArtistTap(artist),
                    );
                  }, childCount: artists.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: GBTSpacing.sm,
                    mainAxisSpacing: GBTSpacing.sm,
                    childAspectRatio: 0.66,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArtistsIntro extends StatelessWidget {
  const _ArtistsIntro({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n(ko: '아티스트 색인', en: 'Artist index', ja: 'アーティスト索引'),
                style: GBTTypography.titleLarge.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$count',
              style: GBTTypography.titleLarge.copyWith(
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs),
        Text(
          context.l10n(
            ko: '유닛의 인물, 음악, 관련 장소로 이어지는 시작점입니다.',
            en: 'Start with a unit, then follow its people, music, and places.',
            ja: 'ユニットから人物・音楽・関連スポットへたどれます。',
          ),
          style: GBTTypography.bodySmall.copyWith(color: muted, height: 1.45),
        ),
      ],
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist, required this.onTap});

  final Unit artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    final ink = isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary;
    final muted = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final artistColor = _artistColor(artist.colorHex, isDark: isDark);
    final imageUrl = artist.logoUrl?.trim();
    final memberLabel = context.l10n(
      ko: '${artist.memberSummaries.length}명',
      en: '${artist.memberSummaries.length} members',
      ja: '${artist.memberSummaries.length}人',
    );

    return Semantics(
      button: true,
      label: '${artist.displayName}, $memberLabel',
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? GBTImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        semanticLabel: artist.displayName,
                      )
                    : _ArtistMonogram(
                        name: artist.displayName,
                        color: artistColor,
                      ),
              ),
              Container(height: 4, color: artistColor),
              Padding(
                padding: const EdgeInsets.all(GBTSpacing.sm2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GBTTypography.bodyMedium.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            memberLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GBTTypography.labelSmall.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: muted,
                        ),
                      ],
                    ),
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

class _ArtistMonogram extends StatelessWidget {
  const _ArtistMonogram({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return ColoredBox(
      color: color.withValues(alpha: 0.16),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -28,
            child: Icon(
              Icons.album_rounded,
              size: 112,
              color: color.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: Text(
              initial,
              style: GBTTypography.displayLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistsEmpty extends StatelessWidget {
  const _ArtistsEmpty({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.xl,
          GBTSpacing.pageHorizontal,
          GBTSpacing.bottomNavClearanceOf(context),
        ),
        children: [
          GBTEmptyState(
            icon: Icons.groups_2_outlined,
            title: title,
            subtitle: subtitle,
          ),
        ],
      ),
    );
  }
}

class _ArtistsFailure extends StatelessWidget {
  const _ArtistsFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.xl,
        GBTSpacing.pageHorizontal,
        GBTSpacing.bottomNavClearanceOf(context),
      ),
      children: [GBTErrorState(message: message, onRetry: onRetry)],
    );
  }
}

class _ArtistsSkeleton extends StatelessWidget {
  const _ArtistsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.bottomNavClearanceOf(context),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: GBTSpacing.sm,
        mainAxisSpacing: GBTSpacing.sm,
        childAspectRatio: 0.66,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => GBTShimmer(
        child: Container(
          decoration: BoxDecoration(
            color: GBTColors.surfaceVariant,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

Color _artistColor(String? value, {required bool isDark}) {
  final normalized = value?.trim().replaceFirst('#', '');
  if (normalized != null &&
      (normalized.length == 6 || normalized.length == 8)) {
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(normalized.length == 6 ? 0xFF000000 | parsed : parsed);
    }
  }
  return isDark ? GBTColors.darkSecondary : GBTColors.secondary;
}
