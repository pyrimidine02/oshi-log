/// EN: Music catalog tab — redesigned albums/songs browser for the Info page.
/// KO: 악곡 카탈로그 탭 — 정보 페이지 앨범·곡 탐색 뷰 완전 리디자인.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../application/music_controller.dart';
import '../../domain/entities/music_entities.dart';
import '../../../projects/application/projects_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EN: Harbor teal marks audio metadata within the shared field-notes system.
// KO: 하버 틸은 공통 필드 노트 시스템에서 오디오 메타데이터를 표시합니다.
// ─────────────────────────────────────────────────────────────────────────────
Color _accent(bool isDark) =>
    isDark ? GBTColors.darkSecondary : GBTColors.secondary;

String _errorMsg(BuildContext context, Object? e) {
  if (e is Failure) return e.userMessage;
  return context.l10n(
    ko: '데이터를 불러오지 못했습니다.',
    en: 'Failed to load data.',
    ja: 'データの読み込みに失敗しました。',
  );
}

String _formatMs(int ms) {
  final s = (ms / 1000).floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}

String? _albumReleaseLabel({String? releaseDate, String? releaseDateText}) {
  final date = releaseDate?.trim();
  if (date != null && date.isNotEmpty) return date.split('-').first;
  final text = releaseDateText?.trim();
  return text == null || text.isEmpty ? null : text;
}

String? _albumTrackCountLabel(BuildContext context, int? trackCount) {
  if (trackCount == null || trackCount <= 0) return null;
  return context.l10n(
    ko: '$trackCount곡',
    en: '$trackCount tracks',
    ja: '$trackCount曲',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// EN: Music catalog tab — album grid + track list with segmented switcher.
/// KO: 악곡 카탈로그 탭 — 세그먼트 스위처로 앨범 그리드·트랙 목록을 탐색합니다.
class MusicCatalogTab extends ConsumerStatefulWidget {
  const MusicCatalogTab({super.key, this.showPageHeader = false});

  final bool showPageHeader;

  @override
  ConsumerState<MusicCatalogTab> createState() => _MusicCatalogTabState();
}

class _MusicCatalogTabState extends ConsumerState<MusicCatalogTab> {
  // EN: 0 = Albums, 1 = Songs
  // KO: 0 = 앨범, 1 = 곡
  int _viewIndex = 0;
  String? _selectedUnitKey;
  late final ScrollController _albumScroll;
  late final ScrollController _songScroll;

  @override
  void initState() {
    super.initState();
    _albumScroll = ScrollController()..addListener(_onAlbumScroll);
    _songScroll = ScrollController();
  }

  @override
  void dispose() {
    _albumScroll
      ..removeListener(_onAlbumScroll)
      ..dispose();
    _songScroll.dispose();
    super.dispose();
  }

  void _onAlbumScroll() {
    if (!_albumScroll.hasClients) return;
    if (_albumScroll.position.extentAfter > 240) return;
    final pk = ref.read(projectSelectionControllerProvider).projectKey;
    if (pk == null || pk.isEmpty) return;
    final s = ref.read(musicAlbumsControllerProvider(pk));
    if (s.isLoading || s.isLoadingMore || !s.hasNext) return;
    ref.read(musicAlbumsControllerProvider(pk).notifier).loadMore();
  }

  String? _unitKey(MusicSongSummary s) {
    final id = s.primaryUnitId?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final name = s.primaryUnitName?.trim();
    if (name != null && name.isNotEmpty) return 'name:$name';
    return null;
  }

  List<_UnitOption> _buildUnitOptions(List<MusicSongSummary> songs) {
    final order = <String>[];
    final labels = <String, String>{};
    final counts = <String, int>{};
    for (final song in songs) {
      final k = _unitKey(song);
      if (k == null) continue;
      if (!labels.containsKey(k)) {
        labels[k] = (song.primaryUnitName ?? '').trim().isNotEmpty
            ? song.primaryUnitName!.trim()
            : song.primaryUnitId ?? '';
        order.add(k);
      }
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return order
        .map((k) => _UnitOption(key: k, label: labels[k]!, count: counts[k]!))
        .toList(growable: false);
  }

  Future<void> _openAlbumSheet(
    BuildContext ctx,
    String projectId,
    MusicAlbumSummary album,
  ) async {
    final key = (projectId: projectId, albumId: album.id);
    // EN: Returns the tapped songId so we can navigate AFTER the sheet closes,
    //     avoiding GoRouter state conflicts while a modal overlay is active.
    // KO: 탭한 songId를 반환해 시트가 닫힌 후에 이동합니다.
    //     모달 오버레이가 열려있는 동안 GoRouter 상태 충돌을 방지합니다.
    final selectedSongId = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(ctx).brightness == Brightness.dark
          ? GBTColors.darkSurface
          : GBTColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusXl),
        ),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.52,
        maxChildSize: 0.94,
        builder: (context, scrollController) => Consumer(
          builder: (context, ref, _) {
            final detailState = ref.watch(musicAlbumDetailProvider(key));
            final songsState = ref.watch(
              musicSongsControllerProvider(projectId),
            );
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final ac = _accent(isDark);
            return SafeArea(
              top: false,
              child: detailState.when(
                loading: () => CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: ac),
                      ),
                    ),
                  ],
                ),
                error: (e, _) => CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(GBTSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _errorMsg(context, e),
                                textAlign: TextAlign.center,
                                style: GBTTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? GBTColors.darkTextSecondary
                                      : GBTColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: () => ref.invalidate(
                                  musicAlbumDetailProvider(key),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  context.l10n(
                                    ko: '다시 시도',
                                    en: 'Try again',
                                    ja: '再試行',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                data: (detail) => _AlbumSheet(
                  detail: detail,
                  songsById: {for (final s in songsState.items) s.id: s},
                  isDark: isDark,
                  accent: ac,
                  projectId: projectId,
                  scrollController: scrollController,
                  onSongTap: (songId) => Navigator.of(sheetCtx).pop(songId),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (selectedSongId != null && ctx.mounted) {
      ctx.goToSongDetail(selectedSongId, projectId: projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(projectSelectionControllerProvider);
    final projectKey = selection.projectKey ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ac = _accent(isDark);

    if (projectKey.isEmpty) {
      return Column(
        children: [
          if (widget.showPageHeader)
            GBTPageHeader(
              eyebrow: 'TRAVEL AUDIO INDEX',
              title: context.l10n(
                ko: '여행의 사운드트랙',
                en: 'Soundtrack of the journey',
                ja: '旅のサウンドトラック',
              ),
            ),
          Expanded(
            child: _EmptyProjectHero(isDark: isDark, accent: ac),
          ),
        ],
      );
    }

    final albumsState = ref.watch(musicAlbumsControllerProvider(projectKey));
    final songsState = ref.watch(musicSongsControllerProvider(projectKey));
    final unitOptions = _buildUnitOptions(songsState.items);

    // EN: Reset filter key if no longer valid
    // KO: 유효하지 않은 필터 키는 초기화
    final validKey = unitOptions.any((o) => o.key == _selectedUnitKey)
        ? _selectedUnitKey
        : null;
    if (validKey != _selectedUnitKey && _selectedUnitKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedUnitKey = null);
      });
    }

    final filteredSongs = validKey == null
        ? songsState.items
        : songsState.items.where((s) => _unitKey(s) == validKey).toList();
    final filteredAlbumIds = <String>{
      for (final s in filteredSongs)
        if ((s.albumId ?? '').trim().isNotEmpty) s.albumId!.trim(),
    };
    final filteredAlbums = validKey == null
        ? albumsState.items
        : albumsState.items
              .where((a) => filteredAlbumIds.contains(a.id))
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showPageHeader)
          GBTPageHeader(
            eyebrow: 'TRAVEL AUDIO INDEX',
            title: context.l10n(
              ko: '여행의 사운드트랙',
              en: 'Soundtrack of the journey',
              ja: '旅のサウンドトラック',
            ),
            description:
                '${filteredAlbums.length.toString().padLeft(2, '0')}'
                '${albumsState.hasNext ? '+' : ''} ALBUMS · '
                '${filteredSongs.length.toString().padLeft(2, '0')}'
                '${songsState.isLoading && filteredSongs.isNotEmpty ? '+' : ''} TRACKS',
          )
        else
          _MusicDocumentHeader(
            albumCount: filteredAlbums.length,
            songCount: filteredSongs.length,
            hasMoreAlbums: albumsState.hasNext,
            isLoadingSongs: songsState.isLoading && filteredSongs.isNotEmpty,
          ),
        // ── Segmented view switcher ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            GBTSpacing.md,
            GBTSpacing.pageHorizontal,
            GBTSpacing.xs,
          ),
          child: _ViewSwitcher(
            currentIndex: _viewIndex,
            isDark: isDark,
            accent: ac,
            onChanged: (i) => setState(() => _viewIndex = i),
          ),
        ),

        // ── Unit filter chips ─────────────────────────────────────
        if (unitOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: GBTSpacing.pageHorizontal,
              right: GBTSpacing.pageHorizontal,
              top: GBTSpacing.xs2,
              bottom: GBTSpacing.xs,
            ),
            child: _UnitFilterBar(
              options: unitOptions,
              selectedKey: validKey,
              isDark: isDark,
              accent: ac,
              onSelected: (k) => setState(() => _selectedUnitKey = k),
            ),
          ),

        // ── Content area ─────────────────────────────────────────
        Expanded(
          child: _viewIndex == 0
              ? _AlbumsGrid(
                  albums: filteredAlbums,
                  isLoading: albumsState.isLoading && albumsState.items.isEmpty,
                  isLoadingMore: albumsState.isLoadingMore,
                  failure: albumsState.failure,
                  scrollController: _albumScroll,
                  isDark: isDark,
                  accent: ac,
                  onRetry: () => ref
                      .read(musicAlbumsControllerProvider(projectKey).notifier)
                      .load(forceRefresh: true),
                  onTap: (a) => _openAlbumSheet(context, projectKey, a),
                )
              : _SongsList(
                  songs: filteredSongs,
                  isLoading: songsState.isLoading && songsState.items.isEmpty,
                  isLoadingMore: songsState.isLoadingMore,
                  failure: songsState.failure,
                  scrollController: _songScroll,
                  isDark: isDark,
                  accent: ac,
                  onRetry: () => ref
                      .read(musicSongsControllerProvider(projectKey).notifier)
                      .load(forceRefresh: true),
                  onTap: (s) =>
                      context.goToSongDetail(s.id, projectId: projectKey),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW SWITCHER
// ─────────────────────────────────────────────────────────────────────────────

/// EN: Editorial index heading for albums and songs in the active project.
/// KO: 현재 프로젝트의 앨범과 곡을 위한 에디토리얼 인덱스 헤더.
class _MusicDocumentHeader extends StatelessWidget {
  const _MusicDocumentHeader({
    required this.albumCount,
    required this.songCount,
    required this.hasMoreAlbums,
    required this.isLoadingSongs,
  });

  final int albumCount;
  final int songCount;
  final bool hasMoreAlbums;
  final bool isLoadingSongs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.lg,
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRAVEL AUDIO INDEX / '
              '${albumCount.toString().padLeft(2, '0')}${hasMoreAlbums ? '+' : ''} ALBUMS · '
              '${songCount.toString().padLeft(2, '0')}${isLoadingSongs ? '+' : ''} TRACKS',
              style: GBTTypography.labelSmall.copyWith(
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '여행의 사운드트랙',
                en: 'Soundtrack of the journey',
                ja: '旅のサウンドトラック',
              ),
              style: GBTTypography.titleLarge.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    required this.currentIndex,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  final int currentIndex;
  final bool isDark;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
          bottom: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          _SwitcherItem(
            label: context.l10n(ko: '앨범', en: 'Albums', ja: 'アルバム'),
            selected: currentIndex == 0,
            isDark: isDark,
            accent: accent,
            onTap: () => onChanged(0),
          ),
          _SwitcherItem(
            label: context.l10n(ko: '곡', en: 'Songs', ja: '楽曲'),
            selected: currentIndex == 1,
            isDark: isDark,
            accent: accent,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SwitcherItem extends StatelessWidget {
  const _SwitcherItem({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? accent
        : (isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: isDark ? 0.12 : 0.07)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GBTTypography.labelMedium.copyWith(
                color: textColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIT FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────

class _UnitOption {
  const _UnitOption({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

class _UnitFilterBar extends StatelessWidget {
  const _UnitFilterBar({
    required this.options,
    required this.selectedKey,
    required this.isDark,
    required this.accent,
    required this.onSelected,
  });

  final List<_UnitOption> options;
  final String? selectedKey;
  final bool isDark;
  final Color accent;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    _UnitOption? selected;
    for (final option in options) {
      if (option.key == selectedKey) selected = option;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: context.l10n(ko: '유닛 필터', en: 'Unit filter', ja: 'ユニットフィルター'),
        onSelected: (value) => onSelected(value == '__all__' ? null : value),
        itemBuilder: (context) => [
          CheckedPopupMenuItem<String>(
            value: '__all__',
            checked: selectedKey == null,
            child: Text(context.l10n(ko: '전체', en: 'All', ja: '全体')),
          ),
          ...options.map(
            (option) => CheckedPopupMenuItem<String>(
              value: option.key,
              checked: option.key == selectedKey,
              child: Text('${option.label} · ${option.count}'),
            ),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 18, color: accent),
                const SizedBox(width: GBTSpacing.xs),
                Text(
                  context.l10n(ko: '유닛', en: 'Unit', ja: 'ユニット'),
                  style: GBTTypography.labelSmall.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  selected?.label ??
                      context.l10n(ko: '전체', en: 'All', ja: '全体'),
                  style: GBTTypography.labelMedium.copyWith(
                    color: selected == null ? textSecondary : accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.expand_more_rounded, size: 18, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EN: Accessible unit filter used by the music catalog index.
/// KO: 음악 카탈로그 색인에서 사용하는 접근 가능한 유닛 필터입니다.
class MusicCatalogFilterChip extends StatelessWidget {
  const MusicCatalogFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.accent,
    required this.chipBg,
    required this.textSecondary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color accent;
  final Color chipBg;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : chipBg,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: GBTTypography.labelSmall.copyWith(
              color: selected ? accent : textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALBUMS GRID
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({
    required this.albums,
    required this.isLoading,
    required this.isLoadingMore,
    required this.failure,
    required this.scrollController,
    required this.isDark,
    required this.accent,
    required this.onRetry,
    required this.onTap,
  });

  final List<MusicAlbumSummary> albums;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final ScrollController scrollController;
  final bool isDark;
  final Color accent;
  final VoidCallback onRetry;
  final ValueChanged<MusicAlbumSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (failure != null && albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                failure!.userMessage,
                style: GBTTypography.bodySmall.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GBTSpacing.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.l10n(ko: '다시 시도', en: 'Try again', ja: '再試行'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.album_outlined,
              size: 48,
              color: accent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '앨범 정보가 없습니다.',
                en: 'No albums available.',
                ja: 'アルバム情報がありません。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: textSecondary),
            ),
          ],
        ),
      );
    }

    final media = MediaQuery.of(context);
    final useSingleColumn =
        media.size.width < 360 || media.textScaler.scale(1) >= 1.5;

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xxl,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: useSingleColumn ? 1 : 2,
        crossAxisSpacing: GBTSpacing.sm,
        mainAxisSpacing: GBTSpacing.md,
        childAspectRatio: useSingleColumn ? 1.25 : 0.72,
      ),
      itemCount: albums.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, i) {
        if (i >= albums.length) {
          // EN: Loading placeholder tiles
          // KO: 추가 로딩 플레이스홀더 타일
          return _AlbumCardSkeleton(isDark: isDark);
        }
        return _AlbumCard(
          album: albums[i],
          isDark: isDark,
          accent: accent,
          onTap: () => onTap(albums[i]),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  final MusicAlbumSummary album;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final metaColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final hasCover = (album.coverUrl ?? '').trim().isNotEmpty;
    final releaseLabel = _albumReleaseLabel(
      releaseDate: album.releaseDate,
      releaseDateText: album.releaseDateText,
    );
    final trackCountLabel = _albumTrackCountLabel(context, album.trackCount);
    final usesLargeTextLayout = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final details = Padding(
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.sm,
        GBTSpacing.xs,
        GBTSpacing.sm,
        GBTSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            album.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GBTTypography.labelMedium.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            [
              if (album.type.trim().isNotEmpty) album.type.toUpperCase(),
              if (releaseLabel != null) releaseLabel,
              if (trackCountLabel != null) trackCountLabel,
            ].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GBTTypography.caption.copyWith(color: metaColor),
          ),
        ],
      ),
    );
    final cover = ClipRRect(
      borderRadius: usesLargeTextLayout
          ? const BorderRadius.horizontal(
              left: Radius.circular(GBTSpacing.radiusLg),
            )
          : const BorderRadius.vertical(
              top: Radius.circular(GBTSpacing.radiusLg),
            ),
      child: hasCover
          ? GBTImage(
              imageUrl: album.coverUrl!,
              fit: BoxFit.cover,
              semanticLabel: '${album.title} cover',
            )
          : ColoredBox(
              color: accent.withValues(alpha: 0.1),
              child: Center(
                child: Icon(
                  Icons.album_outlined,
                  size: 48,
                  color: accent.withValues(alpha: 0.55),
                ),
              ),
            ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
          ),
          child: usesLargeTextLayout
              ? Row(
                  children: [
                    SizedBox(width: 104, child: cover),
                    Expanded(child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cover),
                    details,
                  ],
                ),
        ),
      ),
    );
  }
}

class _AlbumCardSkeleton extends StatelessWidget {
  const _AlbumCardSkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONGS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _SongsList extends StatelessWidget {
  const _SongsList({
    required this.songs,
    required this.isLoading,
    required this.isLoadingMore,
    required this.failure,
    required this.scrollController,
    required this.isDark,
    required this.accent,
    required this.onRetry,
    required this.onTap,
  });

  final List<MusicSongSummary> songs;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final ScrollController scrollController;
  final bool isDark;
  final Color accent;
  final VoidCallback onRetry;
  final ValueChanged<MusicSongSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }

    if (failure != null && songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure!.userMessage,
              style: GBTTypography.bodySmall.copyWith(color: textSecondary),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行')),
            ),
          ],
        ),
      );
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 48,
              color: accent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '곡 정보가 없습니다.',
                en: 'No songs available.',
                ja: '楽曲情報がありません。',
              ),
              style: GBTTypography.bodySmall.copyWith(color: textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.pageHorizontal,
        GBTSpacing.sm,
        GBTSpacing.pageHorizontal,
        GBTSpacing.xxl,
      ),
      itemCount:
          songs.length + (failure != null ? 1 : 0) + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (failure != null && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n(
                      ko: '일부 곡만 불러왔습니다.',
                      en: 'Only part of the catalog loaded.',
                      ja: '一部の楽曲のみ読み込みました。',
                    ),
                    style: GBTTypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                  ),
                ),
              ],
            ),
          );
        }
        final songIndex = i - (failure != null ? 1 : 0);
        if (songIndex >= songs.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
            child: Center(child: CircularProgressIndicator(color: accent)),
          );
        }
        return _SongRow(
          song: songs[songIndex],
          rank: songIndex + 1,
          isDark: isDark,
          accent: accent,
          onTap: () => onTap(songs[songIndex]),
        );
      },
    );
  }
}

class _SongRow extends StatelessWidget {
  const _SongRow({
    required this.song,
    required this.rank,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  final MusicSongSummary song;
  final int rank;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final metaColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final isTitleTrack = song.isTitleTrack ?? false;

    // EN: Artist/unit + BPM form the subtitle line; duration is broken out
    // as its own tabular-figure trailing label for scannable run times.
    // KO: 아티스트/유닛 + BPM은 서브타이틀 줄로, 재생 시간은 스캔하기 쉽도록
    // 고정폭 숫자(tabular figures)를 적용한 별도 트레일링 라벨로 분리합니다.
    final metaParts = <String>[];
    if ((song.primaryUnitName ?? '').trim().isNotEmpty) {
      metaParts.add(song.primaryUnitName!.trim());
    }
    if (song.bpm != null && song.bpm! > 0) {
      metaParts.add('BPM ${song.bpm}');
    }
    final durationLabel = (song.durationMs != null && song.durationMs! > 0)
        ? _formatMs(song.durationMs!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.sm,
            vertical: GBTSpacing.sm2,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? GBTColors.darkBorderSubtle : GBTColors.divider,
              ),
            ),
          ),
          child: Row(
            children: [
              // EN: A slim index rail avoids repetitive placeholder artwork.
              // KO: 반복 플레이스홀더 아트 대신 얇은 인덱스 레일을 사용합니다.
              Container(
                width: 30,
                height: 44,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: accent, width: 2)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${song.trackNo ?? rank}'.padLeft(2, '0'),
                  style: GBTTypography.labelSmall.copyWith(
                    color: metaColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),

              // ── Title + metadata ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GBTTypography.bodyMedium.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isTitleTrack) ...[
                          const SizedBox(width: GBTSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                GBTSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'TITLE',
                              style: GBTTypography.caption.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaParts.join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.caption.copyWith(color: metaColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),

              // EN: Duration as its own tabular-figure label so digits
              // align vertically down the list.
              // KO: 숫자가 리스트 전체에서 세로로 정렬되도록 재생 시간을
              // 별도의 고정폭 숫자 라벨로 표시합니다.
              if (durationLabel != null) ...[
                Text(
                  durationLabel,
                  style: GBTTypography.labelSmall.copyWith(
                    color: metaColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
              ],

              // ── Chevron ──────────────────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALBUM BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AlbumSheet extends StatelessWidget {
  const _AlbumSheet({
    required this.detail,
    required this.songsById,
    required this.isDark,
    required this.accent,
    required this.projectId,
    required this.scrollController,
    required this.onSongTap,
  });

  final MusicAlbumDetail detail;
  final Map<String, MusicSongSummary> songsById;
  final bool isDark;
  final Color accent;
  final String projectId;
  final ScrollController scrollController;
  final ValueChanged<String> onSongTap;

  String? _resolveSongId(MusicAlbumTrack track) {
    final direct = track.songId.trim();
    if (direct.isNotEmpty) return direct;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final metaColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final divider = isDark ? GBTColors.darkBorder : GBTColors.border;
    final hasCover = (detail.coverUrl ?? '').trim().isNotEmpty;
    final releaseLabel = _albumReleaseLabel(
      releaseDate: detail.releaseDate,
      releaseDateText: detail.releaseDateText,
    );
    final trackCountLabel = _albumTrackCountLabel(context, detail.trackCount);
    final usesLargeTextLayout = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!usesLargeTextLayout)
          ExcludeSemantics(
            child: Text(
              'ALBUM DOSSIER',
              style: GBTTypography.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        if (!usesLargeTextLayout) const SizedBox(height: 4),
        Text(
          detail.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GBTTypography.titleSmall.copyWith(
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (detail.type.trim().isNotEmpty) detail.type.toUpperCase(),
            if (releaseLabel != null) releaseLabel,
            if (trackCountLabel != null) trackCountLabel,
          ].join('  ·  '),
          maxLines: usesLargeTextLayout ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: GBTTypography.bodySmall.copyWith(color: metaColor),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // EN: Compact dossier header keeps the track list immediately visible.
        // KO: 트랙 목록이 바로 보이도록 간결한 기록 문서형 헤더를 사용합니다.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.xs,
            GBTSpacing.md,
            GBTSpacing.sm,
          ),
          child: usesLargeTextLayout
              ? headerText
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                      child: SizedBox.square(
                        dimension: 104,
                        child: hasCover
                            ? GBTImage(
                                imageUrl: detail.coverUrl!,
                                fit: BoxFit.cover,
                                semanticLabel: '${detail.title} cover',
                              )
                            : ColoredBox(
                                color: accent.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.album_outlined,
                                  color: accent,
                                  size: 36,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: GBTSpacing.md),
                    Expanded(child: headerText),
                  ],
                ),
        ),

        Divider(height: 1, color: divider),

        // ── Track list ───────────────────────────────────────
        Expanded(
          child: detail.tracks.isEmpty
              ? CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          context.l10n(
                            ko: '트랙 정보가 없습니다.',
                            en: 'No tracks available.',
                            ja: 'トラック情報がありません。',
                          ),
                          style: GBTTypography.bodySmall.copyWith(
                            color: metaColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.md,
                    vertical: GBTSpacing.sm,
                  ),
                  itemCount: detail.tracks.length,
                  itemBuilder: (context, i) {
                    final track = detail.tracks[i];
                    final songId = _resolveSongId(track);
                    // EN: Look up matched song to check isTitleTrack.
                    // KO: 매칭된 곡을 조회해 isTitleTrack 여부를 확인합니다.
                    final matchedSong = songsById[track.songId];
                    final isTitleTrack = matchedSong?.isTitleTrack ?? false;
                    return MusicAlbumSheetTrackRow(
                      track: track,
                      isTitleTrack: isTitleTrack,
                      isDark: isDark,
                      accent: accent,
                      onTap: songId == null ? null : () => onSongTap(songId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// EN: Single track row inside the album bottom sheet.
///     Highlights title tracks with accent color and bold weight.
/// KO: 앨범 바텀 시트 내 단일 트랙 행.
///     타이틀 트랙은 accent 색상과 굵은 폰트로 강조합니다.
class MusicAlbumSheetTrackRow extends StatelessWidget {
  const MusicAlbumSheetTrackRow({
    super.key,
    required this.track,
    required this.isDark,
    required this.accent,
    required this.isTitleTrack,
    this.onTap,
  });

  final MusicAlbumTrack track;
  final bool isTitleTrack;
  final bool isDark;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final metaColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    // EN: Title tracks get accent-colored track number, regular tracks get
    //     tertiary grey.
    // KO: 타이틀 트랙 번호는 accent, 일반 트랙은 tertiary 회색.
    final trackNoColor = isTitleTrack
        ? accent
        : (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.xs2,
            ),
            child: Row(
              children: [
                // EN: Track number — accent + w700 for title tracks.
                // KO: 트랙 번호 — 타이틀 트랙은 accent + w700.
                SizedBox(
                  width: usesLargeText ? 48 : 28,
                  child: track.trackNo == null
                      ? Semantics(
                          label: context.l10n(
                            ko: '트랙 번호 미상',
                            en: 'Track number unavailable',
                            ja: 'トラック番号不明',
                          ),
                          child: Icon(
                            Icons.music_note_outlined,
                            size: usesLargeText ? 22 : 18,
                            color: trackNoColor,
                          ),
                        )
                      : Text(
                          '${track.trackNo}'.padLeft(2, '0'),
                          textAlign: TextAlign.center,
                          style: GBTTypography.bodySmall.copyWith(
                            color: trackNoColor,
                            fontWeight: isTitleTrack
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: usesLargeText ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: onTap != null ? titleColor : metaColor,
                          fontWeight: isTitleTrack
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (usesLargeText &&
                          ((track.versionCode ?? '').trim().isNotEmpty ||
                              (track.durationMs ?? 0) > 0)) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if ((track.versionCode ?? '').trim().isNotEmpty)
                              track.versionCode!.trim(),
                            if ((track.durationMs ?? 0) > 0)
                              _formatMs(track.durationMs!),
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GBTTypography.caption.copyWith(
                            color: metaColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!usesLargeText &&
                    (track.versionCode ?? '').trim().isNotEmpty) ...[
                  const SizedBox(width: GBTSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        GBTSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      track.versionCode!,
                      style: GBTTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (!usesLargeText &&
                    track.durationMs != null &&
                    track.durationMs! > 0) ...[
                  const SizedBox(width: GBTSpacing.xs),
                  Text(
                    _formatMs(track.durationMs!),
                    style: GBTTypography.caption.copyWith(
                      color: metaColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (onTap != null) ...[
                  const SizedBox(width: GBTSpacing.xs2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: metaColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY PROJECT HERO
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyProjectHero extends StatelessWidget {
  const _EmptyProjectHero({required this.isDark, required this.accent});

  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(GBTSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    border: Border(left: BorderSide(color: accent, width: 3)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.library_music_outlined,
                      size: 38,
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: GBTSpacing.md),
                Text(
                  context.l10n(ko: '뮤직 허브', en: 'Music Hub', ja: 'ミュージックハブ'),
                  style: GBTTypography.titleSmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextPrimary
                        : GBTColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  context.l10n(
                    ko: '프로젝트를 선택하면\n앨범·가사·콜가이드를 탐색할 수 있어요.',
                    en: 'Select a project to explore\nalbums, lyrics, and call guides.',
                    ja: 'プロジェクトを選択すると\nアルバム・歌詞・コール表を確認できます。',
                  ),
                  textAlign: TextAlign.center,
                  style: GBTTypography.bodySmall.copyWith(
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
