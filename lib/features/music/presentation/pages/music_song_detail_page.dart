/// EN: Song detail page for music information APIs — tab-based layout.
/// KO: 악곡 정보 API용 곡 상세 페이지 — 탭 기반 레이아웃입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/music_controller.dart';
import '../../domain/entities/music_entities.dart';

// ──────────────────────────────────────────────────────────────
// EN: Music page accent — the shared field-teal secondary token.
// KO: 음악 페이지 전용 accent — 공통 field-teal 보조 토큰입니다.
// ──────────────────────────────────────────────────────────────
Color _musicAccent(bool isDark) =>
    isDark ? GBTColors.darkSecondary : GBTColors.secondary;

// ══════════════════════════════════════════════════════════════
// MAIN PAGE
// ══════════════════════════════════════════════════════════════

/// EN: Song detail page with three task-focused sections.
/// KO: 가사·라이브 가이드·곡 기록의 세 가지 작업 중심 섹션입니다.
class MusicSongDetailPage extends ConsumerStatefulWidget {
  const MusicSongDetailPage({
    super.key,
    required this.projectId,
    required this.songId,
    this.eventId,
  });

  final String projectId;
  final String songId;
  final String? eventId;

  @override
  ConsumerState<MusicSongDetailPage> createState() =>
      _MusicSongDetailPageState();
}

class _MusicSongDetailPageState extends ConsumerState<MusicSongDetailPage>
    with TickerProviderStateMixin {
  // EN: Always fetch romanized/translated lyrics once, toggle only affects rendering.
  // KO: 로마자/번역 가사는 한 번에 받아오고, 토글은 렌더링만 전환합니다.
  static const bool _fetchRomanizedLyrics = true;
  static const bool _fetchTranslatedLyrics = true;

  // EN: Pronunciation and translation are visual reading preferences only.
  // KO: 발음과 번역은 가사 읽기 표시 옵션으로만 관리합니다.
  bool _includeRomanized = true;
  bool _includeTranslated = true;
  late String _lang;
  late TabController _tabController;

  String? get _eventId {
    final normalized = widget.eventId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final platformLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    switch (platformLanguage) {
      case 'ja':
      case 'en':
      case 'ko':
        _lang = platformLanguage;
      default:
        _lang = 'ko';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // EN: Build key tuples used for provider lookups and invalidation.
  // KO: 프로바이더 조회 및 무효화에 사용할 키 튜플을 생성합니다.
  MusicSongKey get _songKey =>
      (projectId: widget.projectId, songId: widget.songId);

  MusicLyricsKey get _lyricsKey => (
    projectId: widget.projectId,
    songId: widget.songId,
    lang: _lang,
    version: null,
    includeRomanized: _fetchRomanizedLyrics,
    includeTranslated: _fetchTranslatedLyrics,
  );

  MusicPartsKey get _partsKey => (
    projectId: widget.projectId,
    songId: widget.songId,
    lang: _lang,
    version: null,
  );

  MusicCallGuideKey get _callGuideKey => (
    projectId: widget.projectId,
    songId: widget.songId,
    lang: _lang,
    version: null,
  );

  MusicAvailabilityKey _availabilityKey(BuildContext context) => (
    projectId: widget.projectId,
    songId: widget.songId,
    country: _countryFromLocale(Localizations.localeOf(context)),
  );

  Future<void> _refreshAll(BuildContext context) async {
    ref.invalidate(musicSongDetailProvider(_songKey));
    ref.invalidate(musicSongVersionsProvider(_songKey));
    ref.invalidate(musicSongLyricsProvider(_lyricsKey));
    ref.invalidate(musicSongPartsProvider(_partsKey));
    ref.invalidate(musicSongCallGuideProvider(_callGuideKey));
    ref.invalidate(musicSongCreditsProvider(_songKey));
    ref.invalidate(musicSongDifficultyProvider(_songKey));
    ref.invalidate(musicSongMediaLinksProvider(_songKey));
    ref.invalidate(musicSongAvailabilityProvider(_availabilityKey(context)));
    if (_eventId != null) {
      ref.invalidate(
        musicSongLiveContextProvider((
          projectId: widget.projectId,
          songId: widget.songId,
          eventId: _eventId!,
          lang: _lang,
          version: null,
          includeRomanized: _fetchRomanizedLyrics,
          includeTranslated: _fetchTranslatedLyrics,
        )),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    final songState = ref.watch(musicSongDetailProvider(_songKey));
    final song = songState.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _musicAccent(isDark);
    final bgColor = isDark ? GBTColors.darkBackground : GBTColors.background;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    // EN: Fetch album cover when albumId is available.
    // KO: albumId가 있을 때 앨범 커버를 가져옵니다.
    // JA: albumIdが存在する場合、アルバムカバーを取得します。
    final albumCoverUrl = (song?.albumId?.isNotEmpty == true)
        ? ref
              .watch(
                musicAlbumDetailProvider((
                  projectId: widget.projectId,
                  albumId: song!.albumId!,
                )),
              )
              .valueOrNull
              ?.coverUrl
        : null;

    final tabs = TabBar(
      controller: _tabController,
      isScrollable: textScale >= 1.8,
      tabAlignment: textScale >= 1.8 ? TabAlignment.start : TabAlignment.fill,
      indicatorColor: accent,
      indicatorWeight: 2,
      labelColor: accent,
      unselectedLabelColor: isDark
          ? GBTColors.darkTextSecondary
          : GBTColors.textSecondary,
      labelStyle: GBTTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GBTTypography.labelSmall.copyWith(
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        Tab(
          height: textScale >= 1.8 ? 56 : 48,
          text: context.l10n(ko: '가사', en: 'Lyrics', ja: '歌詞'),
        ),
        Tab(
          height: textScale >= 1.8 ? 56 : 48,
          text: context.l10n(ko: '라이브 가이드', en: 'Live guide', ja: 'ライブガイド'),
        ),
        Tab(
          height: textScale >= 1.8 ? 56 : 48,
          text: context.l10n(ko: '곡 기록', en: 'Song record', ja: '楽曲記録'),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: bgColor,
      appBar: gbtStandardAppBar(
        context,
        title: song?.title ?? context.l10n(ko: '곡 정보', en: 'Song', ja: '楽曲情報'),
        leading: IconButton(
          tooltip: context.l10n(ko: '뒤로', en: 'Back', ja: '戻る'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // EN: Let the song content determine its height; tabs are a separate
          // pinned sliver so the safe area and long titles cannot overlap them.
          // KO: 곡 내용만큼 높이를 확보하고 탭을 별도 고정 슬리버로 배치해
          // 안전 영역과 긴 제목이 탭에 가려지지 않도록 합니다.
          SliverToBoxAdapter(
            child: _SongHeroBg(
              songState: songState,
              albumCoverUrl: albumCoverUrl,
              isDark: isDark,
              accent: accent,
              bgColor: bgColor,
              onRetry: () => _refreshAll(context),
            ),
          ),
          SliverAppBar(
            primary: false,
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(tabs.preferredSize.height + 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: tabs,
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 0: Lyrics
            _LyricsTab(
              projectId: widget.projectId,
              songId: widget.songId,
              eventId: _eventId,
              lang: _lang,
              isDark: isDark,
              accent: accent,
              includeRomanized: _includeRomanized,
              includeTranslated: _includeTranslated,
              onToggleRomanized: () =>
                  setState(() => _includeRomanized = !_includeRomanized),
              onToggleTranslated: () =>
                  setState(() => _includeTranslated = !_includeTranslated),
              onRefresh: () => _refreshAll(context),
            ),
            // Tab 1: Live guide
            _GuideTab(
              projectId: widget.projectId,
              songId: widget.songId,
              eventId: _eventId,
              lang: _lang,
              isDark: isDark,
              accent: accent,
              onRefresh: () => _refreshAll(context),
            ),
            // Tab 2: Song record
            _InfoTab(
              projectId: widget.projectId,
              songId: widget.songId,
              eventId: _eventId,
              lang: _lang,
              isDark: isDark,
              accent: accent,
              onRefresh: () => _refreshAll(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SCROLLING SONG HEADER
// ══════════════════════════════════════════════════════════════

/// EN: Content-sized song header above the pinned tabs.
/// KO: 고정 탭 위에서 내용만큼 높이를 갖는 곡 헤더입니다.
class _SongHeroBg extends StatelessWidget {
  const _SongHeroBg({
    required this.songState,
    required this.isDark,
    required this.accent,
    required this.bgColor,
    required this.onRetry,
    this.albumCoverUrl,
  });

  final AsyncValue<MusicSongDetail> songState;
  final String? albumCoverUrl;
  final bool isDark;
  final Color accent;
  final Color bgColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return songState.when(
      loading: () => _HeroBgShell(
        isDark: isDark,
        accent: accent,
        bgColor: bgColor,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => _HeroBgShell(
        isDark: isDark,
        accent: accent,
        bgColor: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: GBTColors.error,
                size: 28,
              ),
              const SizedBox(height: GBTSpacing.xs),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
                  style: GBTTypography.bodySmall.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (song) => _HeroBgData(
        song: song,
        albumCoverUrl: albumCoverUrl,
        isDark: isDark,
        accent: accent,
        bgColor: bgColor,
      ),
    );
  }
}

/// EN: Paper-toned shell for loading and error states in the hero area.
/// KO: 히어로 영역의 로딩과 오류 상태를 위한 종이 톤 셸.
class _HeroBgShell extends StatelessWidget {
  const _HeroBgShell({
    required this.isDark,
    required this.accent,
    required this.bgColor,
    required this.child,
  });

  final bool isDark;
  final Color accent;
  final Color bgColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(color: accent, width: 3),
          bottom: BorderSide(
            color: isDark ? GBTColors.darkBorder : GBTColors.border,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// EN: Hero background with actual song data.
/// KO: 실제 곡 데이터로 채워진 히어로 배경입니다.
class _HeroBgData extends StatelessWidget {
  const _HeroBgData({
    required this.song,
    required this.isDark,
    required this.accent,
    required this.bgColor,
    this.albumCoverUrl,
  });

  final MusicSongDetail song;
  final String? albumCoverUrl;
  final bool isDark;
  final Color accent;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final isTitleTrack = song.isTitleTrack ?? false;
    final altTitle = (song.titleJa ?? '').trim().isNotEmpty
        ? song.titleJa!
        : (song.titleEn ?? '').trim().isNotEmpty
        ? song.titleEn!
        : null;
    final hasCover = (albumCoverUrl ?? '').trim().isNotEmpty;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    final metadata = <String>[
      if (song.bpm != null) 'BPM ${song.bpm}',
      if (song.durationMs != null) _formatMs(song.durationMs!),
    ];
    final titleTrackLabel = context.l10n(
      ko: '타이틀곡',
      en: 'Title track',
      ja: '表題曲',
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            song.title,
            style: GBTTypography.titleLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
        if ((song.primaryUnitName ?? '').trim().isNotEmpty ||
            altTitle != null) ...[
          const SizedBox(height: GBTSpacing.xs),
          Text(
            (song.primaryUnitName ?? '').trim().isNotEmpty
                ? song.primaryUnitName!
                : altTitle!,
            style: GBTTypography.bodySmall.copyWith(color: textSecondary),
          ),
        ],
        if (metadata.isNotEmpty || isTitleTrack) ...[
          const SizedBox(height: GBTSpacing.xs),
          Text(
            [if (isTitleTrack) titleTrackLabel, ...metadata].join('  ·  '),
            style: GBTTypography.labelSmall.copyWith(color: accent),
          ),
        ],
      ],
    );
    return Padding(
      key: const Key('music-song-dossier'),
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cover = _SongDossierCover(
            imageUrl: hasCover ? albumCoverUrl : null,
            title: song.title,
            accent: accent,
          );
          if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCover) ...[cover, const SizedBox(height: GBTSpacing.md)],
                details,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              const SizedBox(width: GBTSpacing.md),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _SongDossierCover extends StatelessWidget {
  const _SongDossierCover({
    required this.imageUrl,
    required this.title,
    required this.accent,
  });

  final String? imageUrl;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      child: SizedBox.square(
        dimension: 104,
        child: imageUrl != null
            ? GBTImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                semanticLabel: '$title album cover',
              )
            : ColoredBox(
                color: accent.withValues(alpha: 0.1),
                child: Icon(Icons.graphic_eq_rounded, color: accent, size: 32),
              ),
      ),
    );
  }
}
// TAB 0: LYRICS
// ══════════════════════════════════════════════════════════════

/// EN: Lyrics tab — displays integrated lyrics with filter controls.
/// KO: 가사 탭 — 필터 컨트롤이 있는 통합 가사를 표시합니다.
class _LyricsTab extends ConsumerWidget {
  const _LyricsTab({
    required this.projectId,
    required this.songId,
    required this.eventId,
    required this.lang,
    required this.isDark,
    required this.accent,
    required this.includeRomanized,
    required this.includeTranslated,
    required this.onToggleRomanized,
    required this.onToggleTranslated,
    required this.onRefresh,
  });

  final String projectId;
  final String songId;
  final String? eventId;
  final String lang;
  final bool isDark;
  final Color accent;
  final bool includeRomanized;
  final bool includeTranslated;
  final VoidCallback onToggleRomanized;
  final VoidCallback onToggleTranslated;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsKey = (
      projectId: projectId,
      songId: songId,
      lang: lang,
      version: null,
      includeRomanized: true,
      includeTranslated: true,
    );
    final usesLiveContext = eventId != null;
    final AsyncValue<MusicSongLiveContext?>? liveContextState = !usesLiveContext
        ? null
        : ref
              .watch(
                musicSongLiveContextProvider((
                  projectId: projectId,
                  songId: songId,
                  eventId: eventId!,
                  lang: lang,
                  version: null,
                  includeRomanized: true,
                  includeTranslated: true,
                )),
              )
              .whenData<MusicSongLiveContext?>((value) => value);
    final liveContext = liveContextState?.valueOrNull;
    final fallbackAfterLiveError = liveContextState?.hasError ?? false;
    final lyricsState =
        !usesLiveContext ||
            fallbackAfterLiveError ||
            (liveContext != null && liveContext.lyrics == null)
        ? ref.watch(musicSongLyricsProvider(lyricsKey))
        : null;
    return RefreshIndicator(
      color: accent,
      onRefresh: onRefresh,
      child: _IntegratedLyricsPanel(
        controls: Padding(
          padding: const EdgeInsets.only(bottom: GBTSpacing.md),
          child: _LyricsFilterRow(
            includeRomanized: includeRomanized,
            includeTranslated: includeTranslated,
            isDark: isDark,
            accent: accent,
            onToggleRomanized: onToggleRomanized,
            onToggleTranslated: onToggleTranslated,
          ),
        ),
        liveContextState: liveContextState,
        lyricsState: lyricsState,
        partsState: null,
        callGuideState: null,
        includeRomanized: includeRomanized,
        includeTranslated: includeTranslated,
        showMemberParts: false,
        showCallGuide: false,
        isDark: isDark,
        accent: accent,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1: INFO
// ══════════════════════════════════════════════════════════════

/// EN: Song record — streaming, metadata, versions, and reference details.
/// KO: 곡 기록 — 스트리밍·메타데이터·버전·참고 정보를 모아 보여줍니다.
class _InfoTab extends ConsumerWidget {
  const _InfoTab({
    required this.projectId,
    required this.songId,
    required this.eventId,
    required this.lang,
    required this.isDark,
    required this.accent,
    required this.onRefresh,
  });

  final String projectId;
  final String songId;
  final String? eventId;
  final String lang;
  final bool isDark;
  final Color accent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songKey = (projectId: projectId, songId: songId);
    final songState = ref.watch(musicSongDetailProvider(songKey));
    final versionsState = ref.watch(musicSongVersionsProvider(songKey));
    final difficultyState = ref.watch(musicSongDifficultyProvider(songKey));
    final mediaState = ref.watch(musicSongMediaLinksProvider(songKey));
    final creditsState = ref.watch(musicSongCreditsProvider(songKey));
    final availabilityState = ref.watch(
      musicSongAvailabilityProvider((
        projectId: projectId,
        songId: songId,
        country: _countryFromLocale(Localizations.localeOf(context)),
      )),
    );
    final liveContextState = eventId == null
        ? null
        : ref.watch(
            musicSongLiveContextProvider((
              projectId: projectId,
              songId: songId,
              eventId: eventId!,
              lang: lang,
              version: null,
              includeRomanized: true,
              includeTranslated: true,
            )),
          );

    final song = songState.valueOrNull;

    // EN: Fetch album title from album detail so the Info tab shows a
    //     human-readable name instead of a raw UUID.
    // KO: 앨범 상세에서 앨범 제목을 가져와 정보 탭에 UUID 대신 표시합니다.
    // JA: アルバム詳細からタイトルを取得してUUIDではなく表示します。
    final albumKey = (song?.albumId?.isNotEmpty == true)
        ? (projectId: projectId, albumId: song!.albumId!)
        : null;
    final albumTitle = albumKey != null
        ? ref.watch(musicAlbumDetailProvider(albumKey)).valueOrNull?.title
        : null;

    return RefreshIndicator(
      color: accent,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.xxl,
        ),
        children: [
          _TabSectionHeader(
            icon: Icons.headphones_rounded,
            title: context.l10n(ko: '바로 듣기', en: 'Listen now', ja: '今すぐ聴く'),
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: GBTSpacing.sm),
          mediaState.when(
            data: (mediaData) {
              final previewUrl = mediaData.preview.url;
              final supportedLinks = mediaData.streamingLinks
                  .where((link) => _isSupportedStreamingPlatform(link.provider))
                  .toList(growable: false);
              if ((previewUrl == null || previewUrl.isEmpty) &&
                  supportedLinks.isEmpty) {
                return _EmptyHint(
                  text: context.l10n(
                    ko: '연결된 스트리밍 서비스가 없습니다.',
                    en: 'No streaming services linked.',
                    ja: 'ストリーミングサービスがありません。',
                  ),
                );
              }
              return Column(
                children: [
                  if (previewUrl != null && previewUrl.isNotEmpty)
                    _StreamingLinkRow(
                      label: context.l10n(
                        ko: '오디오 미리듣기',
                        en: 'Audio preview',
                        ja: 'オーディオ試聴',
                      ),
                      icon: Icons.play_circle_filled_rounded,
                      platformColor: accent,
                      onTap: () => _launchUrl(previewUrl),
                      isDark: isDark,
                    ),
                  ...supportedLinks.map(
                    (link) => _StreamingLinkRow(
                      label: _streamingDisplayName(link.provider),
                      icon: _streamingIcon(link.provider),
                      platformColor: _streamingColor(link.provider),
                      caption: link.regionAvailability,
                      onTap: () => _launchUrl(link.url),
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
            loading: () => const _InlineLoading(),
            error: (e, _) => _InlineError(message: _errorText(context, e)),
          ),

          if (liveContextState != null) ...[
            const SizedBox(height: GBTSpacing.md),
            liveContextState.when(
              data: (liveContext) {
                final items = liveContext.setlistContext?.items ?? const [];
                if (items.isEmpty) return const SizedBox.shrink();
                return _RecordDisclosure(
                  initiallyExpanded: true,
                  icon: Icons.route_rounded,
                  title: context.l10n(
                    ko: '이 공연의 세트리스트',
                    en: 'Setlist for this event',
                    ja: 'この公演のセットリスト',
                  ),
                  isDark: isDark,
                  accent: accent,
                  child: Column(
                    children: items
                        .map(
                          (item) => _SetlistRow(
                            item: item,
                            isDark: isDark,
                            accent: accent,
                            onTap: !item.hasSongLink
                                ? null
                                : () => context.goToSongDetail(
                                    item.songId!,
                                    projectId: projectId,
                                    eventId: eventId,
                                  ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                );
              },
              loading: () => const _InlineLoading(),
              error: (e, _) => _InlineError(message: _errorText(context, e)),
            ),
          ],

          const SizedBox(height: GBTSpacing.lg),

          // EN: Song metadata section.
          // KO: 곡 메타데이터 섹션.
          _TabSectionHeader(
            icon: Icons.info_outline_rounded,
            title: context.l10n(ko: '기본 정보', en: 'Details', ja: '基本情報'),
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: GBTSpacing.sm),
          if (songState.isLoading && song == null)
            const _InlineLoading()
          else if (songState.hasError && song == null)
            _InlineError(message: _errorText(context, songState.error))
          else if (song != null) ...[
            _MetaRow(
              label: context.l10n(ko: '앨범', en: 'Album', ja: 'アルバム'),
              // EN: Show resolved album title; fall back to albumId if title
              //     not yet loaded, or '-' when albumId is absent.
              // KO: 앨범 제목 표시. 아직 로드 전이면 albumId, 없으면 '-'.
              value:
                  albumTitle ??
                  ((song.albumId ?? '').isNotEmpty ? song.albumId! : '-'),
              isDark: isDark,
            ),
            _MetaRow(
              label: context.l10n(ko: '트랙', en: 'Track', ja: 'トラック'),
              value: song.trackNo != null ? 'Track ${song.trackNo}' : '-',
              isDark: isDark,
            ),
            _MetaRow(
              label: context.l10n(ko: '유닛', en: 'Unit', ja: 'ユニット'),
              value: (song.primaryUnitName ?? '').isNotEmpty
                  ? song.primaryUnitName!
                  : '-',
              isDark: isDark,
            ),
            _MetaRow(
              label: 'BPM',
              value: song.bpm != null ? '${song.bpm}' : '-',
              isDark: isDark,
            ),
            _MetaRow(
              label: context.l10n(ko: '길이', en: 'Duration', ja: '長さ'),
              value: song.durationMs != null
                  ? _formatMs(song.durationMs!)
                  : '-',
              isDark: isDark,
            ),
            if (song.albums.isNotEmpty) ...[
              const SizedBox(height: GBTSpacing.md),
              _TabSectionHeader(
                icon: Icons.album_outlined,
                title: context.l10n(
                  ko: '발매 기록',
                  en: 'Release appearances',
                  ja: '収録作品',
                ),
                isDark: isDark,
                accent: accent,
              ),
              const SizedBox(height: GBTSpacing.xs),
              ...song.albums.map(
                (album) => _SongAlbumAppearanceRow(
                  album: album,
                  isDark: isDark,
                  accent: accent,
                ),
              ),
            ],
          ],

          const SizedBox(height: GBTSpacing.lg),

          // EN: Versions section.
          // KO: 버전 섹션.
          _TabSectionHeader(
            icon: Icons.layers_outlined,
            title: context.l10n(ko: '버전', en: 'Versions', ja: 'バージョン'),
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: GBTSpacing.sm),
          versionsState.when(
            data: (versions) => versions.isEmpty
                ? _EmptyHint(
                    text: context.l10n(
                      ko: '버전 정보가 없습니다.',
                      en: 'No versions.',
                      ja: 'バージョン情報がありません。',
                    ),
                  )
                : _VersionList(versions: versions, isDark: isDark),
            loading: () => const _InlineLoading(),
            error: (e, _) => _InlineError(message: _errorText(context, e)),
          ),

          const SizedBox(height: GBTSpacing.lg),

          // EN: Difficulty section.
          // KO: 난이도 섹션.
          _TabSectionHeader(
            icon: Icons.bar_chart_rounded,
            title: context.l10n(ko: '난이도', en: 'Difficulty', ja: '難易度'),
            isDark: isDark,
            accent: accent,
          ),
          const SizedBox(height: GBTSpacing.sm),
          difficultyState.when(
            data: (d) =>
                _DifficultyRow(difficulty: d, isDark: isDark, accent: accent),
            loading: () => const _InlineLoading(),
            error: (e, _) => _InlineError(message: _errorText(context, e)),
          ),

          // EN: Default version code chip if available.
          // KO: 기본 버전 코드 칩 (있을 경우).
          if (song != null && (song.defaultVersionCode ?? '').isNotEmpty) ...[
            const SizedBox(height: GBTSpacing.xs),
            Wrap(
              children: [
                _InfoChip(
                  icon: Icons.layers_rounded,
                  label: song.defaultVersionCode!,
                  isDark: isDark,
                ),
              ],
            ),
          ],

          const SizedBox(height: GBTSpacing.lg),
          _RecordDisclosure(
            icon: Icons.public_rounded,
            title: context.l10n(
              ko: '지역별 이용 정보',
              en: 'Regional availability',
              ja: '地域別利用情報',
            ),
            isDark: isDark,
            accent: accent,
            child: availabilityState.when(
              data: (availability) =>
                  _AvailabilityRow(availability: availability, isDark: isDark),
              loading: () => const _InlineLoading(),
              error: (e, _) => _InlineError(message: _errorText(context, e)),
            ),
          ),
          _RecordDisclosure(
            icon: Icons.badge_outlined,
            title: context.l10n(ko: '크레딧', en: 'Credits', ja: 'クレジット'),
            isDark: isDark,
            accent: accent,
            child: creditsState.when(
              data: (groups) => groups.isEmpty
                  ? _EmptyHint(
                      text: context.l10n(
                        ko: '크레딧 정보가 없습니다.',
                        en: 'No credits.',
                        ja: 'クレジット情報がありません。',
                      ),
                    )
                  : _CreditsList(
                      groups: groups,
                      isDark: isDark,
                      accent: accent,
                    ),
              loading: () => const _InlineLoading(),
              error: (e, _) => _InlineError(message: _errorText(context, e)),
            ),
          ),

          // EN: Empty bottom spacing for readability.
          // KO: 가독성을 위한 하단 여백.
          const SizedBox(height: GBTSpacing.sm),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2: GUIDE
// ══════════════════════════════════════════════════════════════

/// EN: Guide tab — member part segments and call guide cues.
/// KO: 가이드 탭 — 멤버 파트 구간 및 콜가이드 큐입니다.
class _GuideTab extends ConsumerWidget {
  const _GuideTab({
    required this.projectId,
    required this.songId,
    required this.eventId,
    required this.lang,
    required this.isDark,
    required this.accent,
    required this.onRefresh,
  });

  final String projectId;
  final String songId;
  final String? eventId;
  final String lang;
  final bool isDark;
  final Color accent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsKey = (
      projectId: projectId,
      songId: songId,
      lang: lang,
      version: null,
    );
    final callGuideKey = (
      projectId: projectId,
      songId: songId,
      lang: lang,
      version: null,
    );

    final liveContextState = eventId == null
        ? null
        : ref.watch(
            musicSongLiveContextProvider((
              projectId: projectId,
              songId: songId,
              eventId: eventId!,
              lang: lang,
              version: null,
              includeRomanized: true,
              includeTranslated: true,
            )),
          );
    final liveContext = liveContextState?.valueOrNull;
    final AsyncValue<MusicPartsPayload> partsState;
    final AsyncValue<MusicCallGuidePayload> callGuideState;
    if (liveContextState?.isLoading ?? false) {
      partsState = const AsyncLoading();
      callGuideState = const AsyncLoading();
    } else {
      final liveParts = liveContext?.parts;
      final liveCallGuide = liveContext?.callGuide;
      partsState = liveParts != null
          ? AsyncData(liveParts)
          : ref.watch(musicSongPartsProvider(partsKey));
      callGuideState = liveCallGuide != null
          ? AsyncData(liveCallGuide)
          : ref.watch(musicSongCallGuideProvider(callGuideKey));
    }

    final timeline = <_GuideTimelineEntry>[
      for (final segment in partsState.valueOrNull?.segments ?? const [])
        _GuideTimelineEntry.part(segment),
      for (final cue in callGuideState.valueOrNull?.cues ?? const [])
        _GuideTimelineEntry.call(cue),
    ]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final isLoading = partsState.isLoading || callGuideState.isLoading;
    final error = partsState.error ?? callGuideState.error;

    return RefreshIndicator(
      color: accent,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.pageHorizontal,
              GBTSpacing.md,
              GBTSpacing.pageHorizontal,
              GBTSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: _TabSectionHeader(
                icon: Icons.timeline_rounded,
                title: context.l10n(
                  ko: '파트 · 콜 타임라인',
                  en: 'Parts · call timeline',
                  ja: 'パート・コールタイムライン',
                ),
                isDark: isDark,
                accent: accent,
              ),
            ),
          ),
          if (timeline.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.pageHorizontal,
                ),
                child: isLoading
                    ? const _InlineLoading()
                    : error != null
                    ? _InlineError(message: _errorText(context, error))
                    : _EmptyHint(
                        text: context.l10n(
                          ko: '라이브 가이드 정보가 없습니다.',
                          en: 'No live guide data.',
                          ja: 'ライブガイド情報がありません。',
                        ),
                      ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.pageHorizontal,
                0,
                GBTSpacing.pageHorizontal,
                GBTSpacing.xxl,
              ),
              sliver: SliverList.builder(
                itemCount:
                    timeline.length + (isLoading || error != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == timeline.length) {
                    return isLoading
                        ? const _InlineLoading()
                        : _InlineError(message: _errorText(context, error!));
                  }
                  return _GuideTimelineRow(
                    entry: timeline[index],
                    isDark: isDark,
                    accent: accent,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideTimelineEntry {
  const _GuideTimelineEntry.part(MusicPartSegment this.part) : call = null;
  const _GuideTimelineEntry.call(MusicCallCue this.call) : part = null;

  final MusicPartSegment? part;
  final MusicCallCue? call;

  int get startMs => part?.startMs ?? call!.startMs;
}

class _GuideTimelineRow extends StatelessWidget {
  const _GuideTimelineRow({
    required this.entry,
    required this.isDark,
    required this.accent,
  });

  final _GuideTimelineEntry entry;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final segment = entry.part;
    if (segment != null) {
      final memberId = segment.memberId?.trim();
      final memberColor = memberId == null || memberId.isEmpty
          ? (isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary)
          : _memberColorFromId(memberId, isDark);
      final memberName = (segment.memberName ?? '').trim();
      return _SimpleRow(
        title: (segment.partType ?? '').trim().isNotEmpty
            ? segment.partType!.trim()
            : context.l10n(ko: '파트', en: 'Part', ja: 'パート'),
        subtitle: [
          if (memberName.isNotEmpty) memberName,
          '${_formatMs(segment.startMs)} – ${_formatMs(segment.endMs)}',
        ].join('  ·  '),
        badge: context.l10n(ko: '파트', en: 'Part', ja: 'パート'),
        icon: Icons.person_rounded,
        isDark: isDark,
        accent: memberColor,
      );
    }

    final cue = entry.call!;
    final cueColor = (cue.intensity ?? 0) >= 3 ? accent : GBTColors.accentBlue;
    final intensityLabel = cue.intensity != null
        ? '  ·  lv.${cue.intensity}'
        : '';
    return _SimpleRow(
      title: cue.cueText,
      subtitle:
          '${_formatMs(cue.startMs)} – ${_formatMs(cue.endMs)}$intensityLabel',
      badge: cue.cueType,
      icon: Icons.surround_sound_rounded,
      isDark: isDark,
      accent: cueColor,
    );
  }
}
// ══════════════════════════════════════════════════════════════
// TAB SECTION HEADER
// ══════════════════════════════════════════════════════════════

class _RecordDisclosure extends StatelessWidget {
  const _RecordDisclosure({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.accent,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final Color accent;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? GBTColors.darkBorder : GBTColors.border;
    return Container(
      margin: const EdgeInsets.only(bottom: GBTSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: accent, size: 20),
        title: Text(
          title,
          style: GBTTypography.bodyMedium.copyWith(
            color: isDark ? GBTColors.darkTextPrimary : GBTColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: accent,
        collapsedIconColor: isDark
            ? GBTColors.darkTextSecondary
            : GBTColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(
          GBTSpacing.md,
          0,
          GBTSpacing.md,
          GBTSpacing.md,
        ),
        children: [child],
      ),
    );
  }
}

class _TabSectionHeader extends StatelessWidget {
  const _TabSectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final divider = isDark ? GBTColors.darkBorder : GBTColors.border;
    final titleColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: GBTSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: GBTTypography.titleSmall.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GBTSpacing.xs),
        Container(height: 1, color: divider.withValues(alpha: 0.4)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// META ROW (key-value row for info tab)
// ══════════════════════════════════════════════════════════════

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GBTTypography.bodySmall.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GBTTypography.bodySmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Shows one canonical album appearance for a song without inventing
///     release dates or track positions when the API leaves them unknown.
/// KO: API가 알 수 없는 발매일·트랙 위치를 제공할 때 값을 만들어내지 않고
///     곡의 앨범 수록 기록 하나를 표시합니다.
class _SongAlbumAppearanceRow extends StatelessWidget {
  const _SongAlbumAppearanceRow({
    required this.album,
    required this.isDark,
    required this.accent,
  });

  final MusicAlbumSummary album;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final releaseDate = album.releaseDate?.trim();
    final releaseLabel = releaseDate != null && releaseDate.isNotEmpty
        ? releaseDate
        : album.releaseDateText?.trim();
    final metadata = <String>[
      if (album.type.trim().isNotEmpty) album.type.toUpperCase(),
      if (releaseLabel != null && releaseLabel.isNotEmpty) releaseLabel,
      if (album.discNo != null) 'Disc ${album.discNo}',
      if (album.trackNo != null) 'Track ${album.trackNo}',
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      margin: const EdgeInsets.only(bottom: GBTSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurfaceVariant : GBTColors.surfaceVariant,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        border: Border.all(
          color: isDark ? GBTColors.darkBorder : GBTColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.album_outlined, size: 18, color: accent),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GBTTypography.bodySmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    metadata.join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GBTTypography.caption.copyWith(color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LYRICS FILTER ROW
// ══════════════════════════════════════════════════════════════

class _LyricsFilterRow extends StatelessWidget {
  const _LyricsFilterRow({
    required this.includeRomanized,
    required this.includeTranslated,
    required this.isDark,
    required this.accent,
    required this.onToggleRomanized,
    required this.onToggleTranslated,
  });

  final bool includeRomanized;
  final bool includeTranslated;
  final bool isDark;
  final Color accent;
  final VoidCallback onToggleRomanized;
  final VoidCallback onToggleTranslated;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final textColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        tooltip: context.l10n(
          ko: '가사 표시 옵션',
          en: 'Lyrics display options',
          ja: '歌詞表示オプション',
        ),
        onSelected: (value) {
          if (value == 'romanized') onToggleRomanized();
          if (value == 'translated') onToggleTranslated();
        },
        itemBuilder: (context) => [
          CheckedPopupMenuItem<String>(
            value: 'romanized',
            checked: includeRomanized,
            child: Text(
              context.l10n(ko: '발음 표기', en: 'Pronunciation', ja: '読み方'),
            ),
          ),
          CheckedPopupMenuItem<String>(
            value: 'translated',
            checked: includeTranslated,
            child: Text(context.l10n(ko: '번역', en: 'Translation', ja: '翻訳')),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
            child: textScale >= 2
                ? Icon(Icons.tune_rounded, size: 22, color: accent)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: accent),
                      const SizedBox(width: GBTSpacing.xs),
                      Flexible(
                        child: Text(
                          context.l10n(
                            ko: '표시 옵션',
                            en: 'Display options',
                            ja: '表示オプション',
                          ),
                          style: GBTTypography.labelMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
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
}

// ══════════════════════════════════════════════════════════════
// INTEGRATED LYRICS PANEL
// ══════════════════════════════════════════════════════════════

class _PartMemberOption {
  const _PartMemberOption({
    required this.memberId,
    required this.displayName,
    required this.color,
  });

  final String memberId;
  final String displayName;
  final Color color;
}

class _IntegratedLyricsPanel extends StatefulWidget {
  const _IntegratedLyricsPanel({
    required this.controls,
    required this.lyricsState,
    required this.partsState,
    required this.callGuideState,
    required this.includeRomanized,
    required this.includeTranslated,
    required this.showMemberParts,
    required this.showCallGuide,
    required this.isDark,
    required this.accent,
    this.liveContextState,
  });

  final Widget controls;
  final AsyncValue<MusicSongLiveContext?>? liveContextState;
  final AsyncValue<MusicLyricsPayload>? lyricsState;
  final AsyncValue<MusicPartsPayload>? partsState;
  final AsyncValue<MusicCallGuidePayload>? callGuideState;
  final bool includeRomanized;
  final bool includeTranslated;
  final bool showMemberParts;
  final bool showCallGuide;
  final bool isDark;
  final Color accent;

  @override
  State<_IntegratedLyricsPanel> createState() => _IntegratedLyricsPanelState();
}

class _IntegratedLyricsPanelState extends State<_IntegratedLyricsPanel> {
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final liveCtx = widget.liveContextState?.valueOrNull;
    final lyrics = liveCtx?.lyrics ?? widget.lyricsState?.valueOrNull;
    final parts = liveCtx?.parts ?? widget.partsState?.valueOrNull;
    final callGuide = liveCtx?.callGuide ?? widget.callGuideState?.valueOrNull;

    final lines = [...(lyrics?.lines ?? const <MusicLyricLine>[])]
      ..sort((a, b) => a.order.compareTo(b.order));
    final segments = widget.showMemberParts
        ? (parts?.segments ?? const <MusicPartSegment>[])
        : const <MusicPartSegment>[];
    final cues = widget.showCallGuide
        ? (callGuide?.cues ?? const <MusicCallCue>[])
        : const <MusicCallCue>[];

    final isLoading =
        (widget.liveContextState?.isLoading ?? false) ||
        (widget.lyricsState?.isLoading ?? false) ||
        (widget.showMemberParts && (widget.partsState?.isLoading ?? false)) ||
        (widget.showCallGuide && (widget.callGuideState?.isLoading ?? false));

    if (isLoading && lines.isEmpty && segments.isEmpty && cues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GBTSpacing.paddingMd,
        children: [widget.controls, const _InlineLoading()],
      );
    }

    final hasError =
        (widget.liveContextState?.hasError ?? false) ||
        (widget.lyricsState?.hasError ?? false) ||
        (widget.showMemberParts && (widget.partsState?.hasError ?? false)) ||
        (widget.showCallGuide && (widget.callGuideState?.hasError ?? false));

    final effectiveError =
        widget.liveContextState?.error ?? widget.lyricsState?.error;
    if (hasError && lines.isEmpty && segments.isEmpty && cues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GBTSpacing.paddingMd,
        children: [
          widget.controls,
          _InlineError(message: _errorText(context, effectiveError)),
        ],
      );
    }

    if (lines.isEmpty && segments.isEmpty && cues.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GBTSpacing.paddingMd,
        children: [
          widget.controls,
          _EmptyHint(
            text: context.l10n(
              ko: '가사/파트/콜가이드 정보가 없습니다.',
              en: 'No lyrics, parts, or call guide.',
              ja: '歌詞/パート/コールガイド情報がありません。',
            ),
          ),
        ],
      );
    }

    // Build lookup maps
    final lineById = <String, MusicLyricLine>{
      for (final line in lines) line.lineId: line,
    };
    final partsByLineId = <String, List<MusicPartSegment>>{};
    final unmatchedParts = <MusicPartSegment>[];
    for (final seg in segments) {
      final id = _resolveSegmentLineId(
        segment: seg,
        lineById: lineById,
        orderedLines: lines,
      );
      if (id == null) {
        unmatchedParts.add(seg);
      } else {
        partsByLineId.putIfAbsent(id, () => []).add(seg);
      }
    }
    final cuesByLineId = <String, List<MusicCallCue>>{};
    final unmatchedCues = <MusicCallCue>[];
    for (final cue in cues) {
      String? id;
      for (final line in lines) {
        if (cue.startMs < line.endMs && cue.endMs > line.startMs) {
          id = line.lineId;
          break;
        }
      }
      if (id == null) {
        unmatchedCues.add(cue);
      } else {
        cuesByLineId.putIfAbsent(id, () => []).add(cue);
      }
    }

    // Member options
    final memberOptions = _buildMemberOptions(segments, widget.isDark);
    if (_selectedMemberId != null &&
        !memberOptions.any((o) => o.memberId == _selectedMemberId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedMemberId = null);
      });
    }
    final colorMap = <String, Color>{
      for (final o in memberOptions) o.memberId: o.color,
    };
    final selectedMember = memberOptions
        .where((o) => o.memberId == _selectedMemberId)
        .firstOrNull;

    final itemBuilders = <Widget Function()>[];
    if (widget.showMemberParts && memberOptions.isNotEmpty) {
      itemBuilders.add(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberFilterBar(
              memberOptions: memberOptions,
              selectedMemberId: _selectedMemberId,
              isDark: widget.isDark,
              accent: widget.accent,
              onSelectAll: () => setState(() => _selectedMemberId = null),
              onSelectMember: (id) => setState(() {
                _selectedMemberId = _selectedMemberId == id ? null : id;
              }),
            ),
            if (selectedMember != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selectedMember.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n(
                        ko: '${selectedMember.displayName} 파트',
                        en: '${selectedMember.displayName}\'s part',
                        ja: '${selectedMember.displayName}のパート',
                      ),
                      style: GBTTypography.labelSmall.copyWith(
                        color: selectedMember.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: GBTSpacing.sm),
          ],
        ),
      );
    }

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final startsSection =
          index == 0 || lines[index - 1].section != line.section;
      itemBuilders.add(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (startsSection) ...[
              _LyricsSectionDivider(
                section: line.section,
                isDark: widget.isDark,
                accent: widget.accent,
              ),
              const SizedBox(height: GBTSpacing.xs),
            ],
            _LyricLine(
              line: line,
              includeRomanized: widget.includeRomanized,
              includeTranslated: widget.includeTranslated,
              isDark: widget.isDark,
              lineParts: partsByLineId[line.lineId] ?? const [],
              lineCues: cuesByLineId[line.lineId] ?? const [],
              selectedMemberId: _selectedMemberId,
              memberColorMap: colorMap,
              onPartTap: (segment) {
                final memberId = segment.memberId?.trim();
                if (memberId == null || memberId.isEmpty) return;
                setState(() {
                  _selectedMemberId = _selectedMemberId == memberId
                      ? null
                      : memberId;
                });
              },
            ),
            if (index == lines.length - 1 ||
                lines[index + 1].section != line.section)
              const SizedBox(height: GBTSpacing.sm),
          ],
        ),
      );
    }

    if (lines.isEmpty) {
      itemBuilders.add(
        () => _EmptyHint(
          text: context.l10n(
            ko: '가사 라인이 없습니다.',
            en: 'No lyric lines.',
            ja: '歌詞行がありません。',
          ),
        ),
      );
    }

    for (var index = 0; index < unmatchedParts.length; index++) {
      final segment = unmatchedParts[index];
      itemBuilders.add(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0)
              _UnmappedHeader(
                label: context.l10n(
                  ko: '미매핑 파트',
                  en: 'Unmapped parts',
                  ja: '未マッピングパート',
                ),
                isDark: widget.isDark,
              ),
            _SimpleRow(
              title: _partDisplayLabel(context, segment),
              subtitle:
                  '${_formatMs(segment.startMs)} – ${_formatMs(segment.endMs)}',
              badge: segment.partType,
              icon: Icons.multitrack_audio_rounded,
              isDark: widget.isDark,
              accent: widget.accent,
            ),
          ],
        ),
      );
    }

    for (var index = 0; index < unmatchedCues.length; index++) {
      final cue = unmatchedCues[index];
      itemBuilders.add(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0)
              _UnmappedHeader(
                label: context.l10n(
                  ko: '미매핑 콜가이드',
                  en: 'Unmapped call guide',
                  ja: '未マッピングコールガイド',
                ),
                isDark: widget.isDark,
              ),
            _SimpleRow(
              title: cue.cueText,
              subtitle: '${_formatMs(cue.startMs)} – ${_formatMs(cue.endMs)}',
              badge: cue.cueType,
              icon: Icons.music_note_rounded,
              isDark: widget.isDark,
              accent: widget.accent,
            ),
          ],
        ),
      );
    }

    if (widget.showMemberParts && (widget.partsState?.hasError ?? false)) {
      itemBuilders.add(
        () => _InlineError(
          message: _errorText(context, widget.partsState?.error),
        ),
      );
    }
    if (widget.showCallGuide && (widget.callGuideState?.hasError ?? false)) {
      itemBuilders.add(
        () => _InlineError(
          message: _errorText(context, widget.callGuideState?.error),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        GBTSpacing.md,
        GBTSpacing.md,
        GBTSpacing.md,
        GBTSpacing.xxl,
      ),
      itemCount: itemBuilders.length + 1,
      itemBuilder: (context, index) =>
          index == 0 ? widget.controls : itemBuilders[index - 1](),
    );
  }

  String? _resolveSegmentLineId({
    required MusicPartSegment segment,
    required Map<String, MusicLyricLine> lineById,
    required List<MusicLyricLine> orderedLines,
  }) {
    final id = segment.lyricLineId?.trim();
    if (id != null && id.isNotEmpty && lineById.containsKey(id)) return id;
    int best = 0;
    String? bestId;
    for (final line in orderedLines) {
      final s = segment.startMs > line.startMs ? segment.startMs : line.startMs;
      final e = segment.endMs < line.endMs ? segment.endMs : line.endMs;
      final overlap = e > s ? e - s : 0;
      if (overlap > best) {
        best = overlap;
        bestId = line.lineId;
      }
    }
    return bestId;
  }

  List<_PartMemberOption> _buildMemberOptions(
    List<MusicPartSegment> segments,
    bool isDark,
  ) {
    final options = <_PartMemberOption>[];
    final seen = <String>{};
    for (final seg in segments) {
      final mid = seg.memberId?.trim();
      if (mid == null || mid.isEmpty || !seen.add(mid)) continue;
      final name = seg.memberName?.trim();
      final display = (name != null && name.isNotEmpty)
          ? name
          : mid.substring(0, mid.length >= 6 ? 6 : mid.length);
      options.add(
        _PartMemberOption(
          memberId: mid,
          displayName: display,
          color: _memberColorFromId(mid, isDark),
        ),
      );
    }
    return options;
  }
}

// ══════════════════════════════════════════════════════════════
// LYRIC LINE — minimal, readable, full-width
// ══════════════════════════════════════════════════════════════

class _LyricLine extends StatelessWidget {
  const _LyricLine({
    required this.line,
    required this.includeRomanized,
    required this.includeTranslated,
    required this.isDark,
    required this.lineParts,
    required this.lineCues,
    required this.memberColorMap,
    required this.selectedMemberId,
    this.onPartTap,
  });

  final MusicLyricLine line;
  final bool includeRomanized;
  final bool includeTranslated;
  final bool isDark;
  final List<MusicPartSegment> lineParts;
  final List<MusicCallCue> lineCues;
  final Map<String, Color> memberColorMap;
  final String? selectedMemberId;
  final ValueChanged<MusicPartSegment>? onPartTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    // Resolve member colors for this line
    final lineMemberColors = <Color>[];
    final seenIds = <String>{};
    for (final p in lineParts) {
      final mid = p.memberId?.trim();
      if (mid == null || mid.isEmpty || !seenIds.add(mid)) continue;
      final c = memberColorMap[mid];
      if (c != null) lineMemberColors.add(c);
    }

    final hasMixed = lineParts.any((p) => _isMixedPartType(p.partType));
    final isSelMode = selectedMemberId != null;
    final selSegs = isSelMode
        ? lineParts
              .where((p) => p.memberId?.trim() == selectedMemberId)
              .toList()
        : const <MusicPartSegment>[];
    final isSelLine = selSegs.isNotEmpty;
    final selColor = selectedMemberId == null
        ? null
        : memberColorMap[selectedMemberId!];

    // Determine lyric text color
    Color lyricColor = textPrimary;
    List<Color>? gradientColors;
    if (isSelMode) {
      if (!isSelLine) {
        lyricColor = textTertiary;
      } else if ((hasMixed ||
              selSegs.any((s) => _isMixedPartType(s.partType))) &&
          lineMemberColors.length >= 2) {
        gradientColors = lineMemberColors.take(3).toList();
      } else {
        lyricColor =
            selColor ??
            (lineMemberColors.isNotEmpty
                ? lineMemberColors.first
                : textPrimary);
      }
    } else if (hasMixed && lineMemberColors.length >= 2) {
      gradientColors = lineMemberColors.take(3).toList();
    } else if (lineMemberColors.isNotEmpty) {
      lyricColor = lineMemberColors.first;
    }

    final leftBorderColor = (isSelMode && isSelLine)
        ? (selColor ??
              (lineMemberColors.isNotEmpty ? lineMemberColors.first : null))
        : (!isSelMode && lineMemberColors.isNotEmpty)
        ? lineMemberColors.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (isSelMode && !isSelLine) ? 0.32 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar (member color)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: leftBorderColor != null ? 3 : 0,
              height: leftBorderColor != null ? 44 : 0,
              decoration: BoxDecoration(
                color: leftBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: leftBorderColor != null ? GBTSpacing.sm : 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original lyric
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _GradientText(
                            text: line.textOriginal,
                            style: GBTTypography.bodyLarge.copyWith(
                              color: lyricColor,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                            gradientColors: gradientColors,
                          ),
                        ),
                        // Timestamp
                        Padding(
                          padding: const EdgeInsets.only(
                            left: GBTSpacing.sm,
                            top: 3,
                          ),
                          child: Text(
                            _formatMs(line.startMs),
                            style: GBTTypography.caption.copyWith(
                              color: textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Romanized
                    if (includeRomanized &&
                        (line.textRomanized ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          line.textRomanized!,
                          style: GBTTypography.bodySmall.copyWith(
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    // Translation
                    if (includeTranslated &&
                        (line.textTranslated ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          line.textTranslated!,
                          style: GBTTypography.bodySmall.copyWith(
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    // Part & cue badges
                    if (lineParts.isNotEmpty || lineCues.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: GBTSpacing.xs),
                        child: Wrap(
                          spacing: GBTSpacing.xs,
                          runSpacing: GBTSpacing.xs,
                          children: [
                            ...lineParts.map((seg) {
                              final mc = memberColorMap[seg.memberId?.trim()];
                              final isGradient =
                                  _isMixedPartType(seg.partType) &&
                                  lineMemberColors.length >= 2;
                              return _PartBadge(
                                label: _partDisplayLabel(context, seg),
                                partType: seg.partType,
                                solidColor: isGradient ? null : mc,
                                gradientColors: isGradient
                                    ? lineMemberColors.take(3).toList()
                                    : null,
                                isSelected:
                                    selectedMemberId != null &&
                                    seg.memberId?.trim() == selectedMemberId,
                                isDark: isDark,
                                onTap: onPartTap == null
                                    ? null
                                    : () => onPartTap!(seg),
                              );
                            }),
                            ...lineCues.map(
                              (cue) => _CueBadge(
                                label: cue.cueText,
                                cueType: cue.cueType,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _LyricsSectionDivider extends StatelessWidget {
  const _LyricsSectionDivider({
    required this.section,
    required this.isDark,
    required this.accent,
  });

  final String section;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final upper = section.trim().toUpperCase();
    final Color sectionColor;
    if (upper.contains('CHORUS') ||
        upper.contains('サビ') ||
        upper.contains('후렴')) {
      sectionColor = accent; // pink
    } else if (upper.contains('BRIDGE') ||
        upper.contains('ブリッジ') ||
        upper.contains('브릿지')) {
      sectionColor = GBTColors.accentBlue;
    } else if (upper.contains('INTRO') || upper.contains('OUTRO')) {
      sectionColor = isDark
          ? GBTColors.darkTextTertiary
          : GBTColors.textTertiary;
    } else {
      sectionColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(top: GBTSpacing.sm),
      child: Row(
        children: [
          Text(
            section.toUpperCase(),
            style: GBTTypography.caption.copyWith(
              color: sectionColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: GBTSpacing.xs),
          Expanded(
            child: Container(
              height: 1,
              color: sectionColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberFilterBar extends StatelessWidget {
  const _MemberFilterBar({
    required this.memberOptions,
    required this.selectedMemberId,
    required this.isDark,
    required this.accent,
    required this.onSelectAll,
    required this.onSelectMember,
  });

  final List<_PartMemberOption> memberOptions;
  final String? selectedMemberId;
  final bool isDark;
  final Color accent;
  final VoidCallback onSelectAll;
  final ValueChanged<String> onSelectMember;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MemberChip(
            label: context.l10n(ko: '전체', en: 'All', ja: '全体'),
            color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
            isSelected: selectedMemberId == null,
            isDark: isDark,
            onTap: onSelectAll,
          ),
          ...memberOptions.map(
            (o) => Padding(
              padding: const EdgeInsets.only(left: GBTSpacing.xs),
              child: _MemberChip(
                label: o.displayName,
                color: o.color,
                isSelected: selectedMemberId == o.memberId,
                isDark: isDark,
                onTap: () => onSelectMember(o.memberId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgInactive = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.16) : bgInactive,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.55)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GBTTypography.labelSmall.copyWith(
                color: isSelected
                    ? color
                    : (isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnmappedHeader extends StatelessWidget {
  const _UnmappedHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
      child: Text(
        label,
        style: GBTTypography.caption.copyWith(
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText({
    required this.text,
    required this.style,
    this.gradientColors,
  });

  final String text;
  final TextStyle style;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    if (gradientColors == null || gradientColors!.length < 2) {
      return Text(text, style: style);
    }
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: gradientColors!,
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class _PartBadge extends StatelessWidget {
  const _PartBadge({
    required this.label,
    required this.isDark,
    required this.partType,
    this.solidColor,
    this.gradientColors,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final String? partType;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = isDark ? GBTColors.darkSecondary : GBTColors.secondary;
    final hasGrad = gradientColors != null && gradientColors!.length >= 2;
    final base = solidColor ?? fallback;
    final textColor = hasGrad ? gradientColors!.first : base;
    final alpha = isSelected ? 0.26 : 0.14;

    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasGrad ? null : base.withValues(alpha: alpha),
        gradient: hasGrad
            ? LinearGradient(
                colors: gradientColors!
                    .map((c) => c.withValues(alpha: alpha + 0.08))
                    .toList(),
              )
            : null,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: isSelected
            ? Border.all(color: hasGrad ? gradientColors!.first : base)
            : null,
      ),
      child: Text(
        partType == null || partType!.trim().isEmpty
            ? label
            : '$label · ${partType!.trim()}',
        style: GBTTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

class _CueBadge extends StatelessWidget {
  const _CueBadge({required this.label, required this.cueType});

  final String label;
  final String cueType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: GBTColors.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Text(
        '$cueType · $label',
        style: GBTTypography.labelSmall.copyWith(
          color: GBTColors.accentBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// VERSION LIST
// ══════════════════════════════════════════════════════════════

class _VersionList extends StatelessWidget {
  const _VersionList({required this.versions, required this.isDark});

  final List<MusicSongVersionInfo> versions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final surfaceVar = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final accent = _musicAccent(isDark);

    return Column(
      children: versions
          .map((v) {
            final details = [
              if (v.durationMs != null && v.durationMs! > 0)
                _formatMs(v.durationMs!),
              if (v.bpm != null && v.bpm! > 0) 'BPM ${v.bpm}',
              if ((v.key ?? '').isNotEmpty) v.key!,
              if ((v.timeSignature ?? '').isNotEmpty) v.timeSignature!,
            ];
            return Container(
              margin: const EdgeInsets.only(bottom: GBTSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.sm,
                vertical: GBTSpacing.xs2,
              ),
              decoration: BoxDecoration(
                color: surfaceVar,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  if (v.isDefault) ...[
                    Icon(Icons.check_circle_rounded, size: 14, color: accent),
                    const SizedBox(width: GBTSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      v.versionCode,
                      style: GBTTypography.bodySmall.copyWith(
                        color: v.isDefault ? accent : textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details.join(' · '),
                      style: GBTTypography.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DIFFICULTY ROW
// ══════════════════════════════════════════════════════════════

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({
    required this.difficulty,
    required this.isDark,
    required this.accent,
  });

  final MusicDifficulty difficulty;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: GBTSpacing.xs,
      runSpacing: GBTSpacing.xs,
      children: [
        _InfoChip(
          icon: Icons.signal_cellular_alt_rounded,
          label: context.l10n(
            ko: '난이도 ${difficulty.difficultyLevel}',
            en: 'Lv. ${difficulty.difficultyLevel}',
            ja: '難易度 ${difficulty.difficultyLevel}',
          ),
          isDark: isDark,
        ),
        _InfoChip(
          icon: Icons.surround_sound_rounded,
          label: context.l10n(
            ko: '콜 강도 ${difficulty.callIntensity}',
            en: 'Call ${difficulty.callIntensity}',
            ja: 'コール ${difficulty.callIntensity}',
          ),
          isDark: isDark,
        ),
        _InfoChip(
          icon: Icons.auto_graph_rounded,
          label: '${difficulty.cueDensityPerMin}/min',
          isDark: isDark,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// AVAILABILITY ROW
// ══════════════════════════════════════════════════════════════

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.availability, required this.isDark});

  final MusicAvailability availability;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ok = availability.isAvailableNow;
    final statusColor = ok
        ? (isDark ? GBTColors.darkPrimary : GBTColors.primary)
        : GBTColors.error;

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          ok
              ? context.l10n(ko: '현재 재생 가능', en: 'Available now', ja: '現在利用可能')
              : context.l10n(ko: '현재 재생 제한', en: 'Restricted', ja: '利用制限中'),
          style: GBTTypography.bodySmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: GBTSpacing.xs),
        Text(
          '· ${availability.rightsPolicy}',
          style: GBTTypography.labelSmall.copyWith(
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STREAMING LINK ROW
// ══════════════════════════════════════════════════════════════

class _StreamingLinkRow extends StatelessWidget {
  const _StreamingLinkRow({
    required this.label,
    required this.icon,
    required this.platformColor,
    required this.onTap,
    required this.isDark,
    this.caption,
  });

  final String label;
  final IconData icon;
  final Color platformColor;
  final VoidCallback onTap;
  final bool isDark;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final surfaceVar = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
      // EN: Pill-shaped streaming/preview button — fully rounded to match
      // the "play button" language used across the ticket UI.
      // KO: 스트리밍/미리듣기 버튼 — 티켓 UI 전반의 "재생 버튼" 언어에 맞춰
      // 완전한 필(pill) 형태로 표현합니다.
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.sm,
            vertical: GBTSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: surfaceVar,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            border: Border.all(color: platformColor.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: platformColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: platformColor),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GBTTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((caption ?? '').trim().isNotEmpty)
                      Text(
                        caption!,
                        style: GBTTypography.caption.copyWith(
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CREDITS LIST
// ══════════════════════════════════════════════════════════════

class _CreditsList extends StatelessWidget {
  const _CreditsList({
    required this.groups,
    required this.isDark,
    required this.accent,
  });

  final List<MusicCreditGroup> groups;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups
          .map((group) {
            return Padding(
              padding: const EdgeInsets.only(bottom: GBTSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN: Role label pops in the accent color — a clear step above
                  // the contributor names for scannable credits hierarchy.
                  // KO: 역할 라벨은 accent 색상으로 강조하여 기여자 이름과의
                  // 시각적 위계를 명확히 구분합니다.
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 11,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      Text(
                        group.role,
                        style: GBTTypography.labelSmall.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    group.contributors
                        .map((c) {
                          final type = c.type?.trim();
                          return (type != null && type.isNotEmpty)
                              ? '${c.name} ($type)'
                              : c.name;
                        })
                        .join(', '),
                    style: GBTTypography.bodySmall.copyWith(
                      color: isDark
                          ? GBTColors.darkTextPrimary
                          : GBTColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SETLIST ROW
// ══════════════════════════════════════════════════════════════

class _SetlistRow extends StatelessWidget {
  const _SetlistRow({
    required this.item,
    required this.isDark,
    required this.accent,
    this.onTap,
  });

  final MusicSetlistItem item;
  final bool isDark;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final surfaceVar = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.sm,
              vertical: GBTSpacing.xs2,
            ),
            decoration: BoxDecoration(
              color: surfaceVar,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${item.order.toString().padLeft(2, '0')}',
                    style: GBTTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Expanded(
                  child: Text(
                    item.songTitle ?? '-',
                    style: GBTTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.isEncore)
                  Container(
                    margin: const EdgeInsets.only(left: GBTSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        GBTSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      'Encore',
                      style: GBTTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: textSecondary,
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

// ══════════════════════════════════════════════════════════════
// SIMPLE ROW (unmapped parts / cues)
// ══════════════════════════════════════════════════════════════

class _SimpleRow extends StatelessWidget {
  const _SimpleRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.accent,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final surfaceVar = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: GBTSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.sm,
          vertical: GBTSpacing.xs2,
        ),
        decoration: BoxDecoration(
          color: surfaceVar,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: GBTSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GBTTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GBTTypography.caption.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            if ((badge ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
                child: Text(
                  badge!,
                  style: GBTTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SMALL ATOMS
// ══════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.isDark, this.icon});

  final String label;
  final bool isDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final surfaceVar = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final textColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final iconColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceVar,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: GBTSpacing.md),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        message,
        style: GBTTypography.bodySmall.copyWith(color: GBTColors.error),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GBTTypography.bodySmall.copyWith(
        color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

Future<void> _launchUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _errorText(BuildContext context, Object? error) {
  if (error is Failure) return error.userMessage;
  return context.l10n(
    ko: '데이터를 불러오지 못했습니다.',
    en: 'Failed to load data.',
    ja: 'データの読み込みに失敗しました。',
  );
}

const List<Color> _memberPartColorPalette = <Color>[
  Color(0xFFEF4444), // red
  Color(0xFFF97316), // orange
  Color(0xFFEAB308), // yellow
  Color(0xFF22C55E), // green
  Color(0xFF06B6D4), // cyan
  Color(0xFF3B82F6), // blue
  Color(0xFF8B5CF6), // violet
  Color(0xFFEC4899), // pink
];

Color _memberColorFromId(String memberId, bool isDark) {
  var hash = 0;
  for (final cu in memberId.trim().toLowerCase().codeUnits) {
    hash = ((hash * 31) + cu) & 0x7fffffff;
  }
  final base = _memberPartColorPalette[hash % _memberPartColorPalette.length];
  return isDark ? (Color.lerp(base, Colors.white, 0.12) ?? base) : base;
}

bool _isMixedPartType(String? partType) {
  final n = partType?.trim().toUpperCase();
  return n == 'DUET' || n == 'UNISON' || n == 'HARMONY';
}

String _partDisplayLabel(BuildContext context, MusicPartSegment segment) {
  final name = segment.memberName?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (segment.partType?.trim().toUpperCase() == 'UNISON') return 'UNISON';
  return context.l10n(ko: '미지정 파트', en: 'Unassigned', ja: '未指定パート');
}

String _formatMs(int ms) {
  final s = (ms / 1000).floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String? _countryFromLocale(Locale locale) {
  final c = locale.countryCode?.trim();
  return (c == null || c.isEmpty) ? null : c.toUpperCase();
}

// EN: Only Spotify, Apple Music, YouTube Music are supported
// KO: 스포티파이·애플뮤직·유튜브뮤직만 지원
bool _isSupportedStreamingPlatform(String provider) {
  final l = provider.toLowerCase();
  return l.contains('spotify') ||
      l.contains('apple') ||
      l.contains('itunes') ||
      l.contains('youtube') ||
      l.contains('youtu');
}

// EN: Friendly display name for each platform
// KO: 플랫폼별 표시 이름
String _streamingDisplayName(String provider) {
  final l = provider.toLowerCase();
  if (l.contains('spotify')) return 'Spotify';
  if (l.contains('apple') || l.contains('itunes')) return 'Apple Music';
  return 'YouTube Music';
}

IconData _streamingIcon(String provider) {
  final l = provider.toLowerCase();
  if (l.contains('spotify')) return Icons.headphones_rounded;
  if (l.contains('apple') || l.contains('itunes')) {
    return Icons.music_note_rounded;
  }
  return Icons.play_circle_filled_rounded;
}

Color _streamingColor(String provider) {
  final l = provider.toLowerCase();
  if (l.contains('spotify')) return const Color(0xFF1DB954);
  if (l.contains('apple') || l.contains('itunes')) {
    return const Color(0xFFFC3C44);
  }
  return const Color(0xFFFF0000); // YouTube red
}
