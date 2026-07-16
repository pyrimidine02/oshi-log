/// EN: Quote cards page — browse and like anime quotes.
/// KO: 명대사 카드 페이지 — 애니메이션 명대사 탐색 및 좋아요.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/quotes_controller.dart';
import '../../domain/entities/quote_card.dart';

/// EN: Displays a scrollable list of anime quote cards for a project.
/// KO: 프로젝트의 애니메이션 명대사 카드를 스크롤 가능한 목록으로 표시합니다.
class QuotesPage extends ConsumerWidget {
  const QuotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectKey = ref.watch(selectedProjectKeyProvider);

    // EN: Treat empty string as null so the API receives no filter.
    // KO: 빈 문자열은 null로 처리하여 API에 필터가 전달되지 않도록 합니다.
    final pid = (projectKey?.isNotEmpty ?? false) ? projectKey : null;
    final quotesAsync = ref.watch(quotesControllerProvider(pid));

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '명대사 카드', en: 'Quote Cards', ja: '名言カード'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(quotesControllerProvider(pid).notifier).refresh(),
        child: quotesAsync.when(
          loading: () => _QuoteListShimmer(),
          error: (_, __) => Center(
            child: GBTEmptyState(
              message: context.l10n(
                ko: '명대사를 불러오지 못했어요',
                en: 'Could not load quotes',
                ja: '名言を読み込めませんでした',
              ),
              actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: 'リトライ'),
              onAction: () =>
                  ref.read(quotesControllerProvider(pid).notifier).refresh(),
            ),
          ),
          data: (quotes) => quotes.isEmpty
              ? Center(
                  child: GBTEmptyState(
                    icon: Icons.format_quote_rounded,
                    message: context.l10n(
                      ko: '아직 명대사 카드가 없어요',
                      en: 'No quote cards yet',
                      ja: '名言カードはまだありません',
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.pageHorizontal,
                    GBTSpacing.lg,
                    GBTSpacing.pageHorizontal,
                    GBTSpacing.xl,
                  ),
                  itemCount: quotes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: GBTSpacing.xl),
                        child: _QuotesDocumentHeader(count: quotes.length),
                      );
                    }
                    final quote = quotes[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: GBTSpacing.md),
                      child: _QuoteCardWidget(
                        quote: quote,
                        onLike: () => ref
                            .read(quotesControllerProvider(pid).notifier)
                            .toggleLike(quote.id),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// EN: Editorial heading for the project's memorable-lines archive.
/// KO: 프로젝트의 기억할 만한 대사 아카이브를 위한 에디토리얼 헤더.
class _QuotesDocumentHeader extends StatelessWidget {
  const _QuotesDocumentHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.only(bottom: GBTSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? GBTColors.darkBorder : GBTColors.border,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOICE ARCHIVE / ${count.toString().padLeft(2, '0')}',
              style: GBTTypography.labelSmall.copyWith(
                color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '여정에 남은 한마디',
                en: 'Lines that stayed with the journey',
                ja: '旅の記憶に残る言葉',
              ),
              style: GBTTypography.headlineSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
            Text(
              context.l10n(
                ko: '좋아하는 대사를 모으고 이미지로 저장해 공유해보세요.',
                en: 'Collect favorite lines, then save and share them as images.',
                ja: '好きなセリフを集め、画像として保存・共有できます。',
              ),
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EN: Shimmer placeholder list shown while quotes are loading.
// KO: 명대사 로딩 중에 표시되는 쉬머 플레이스홀더 목록입니다.
// ============================================================

class _QuoteListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(GBTSpacing.pageHorizontal),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: GBTSpacing.md),
        child: GBTShimmer(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: GBTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EN: Individual quote card widget with like and save-to-gallery actions.
// KO: 좋아요 및 갤러리 저장 액션이 있는 개별 명대사 카드 위젯입니다.
// ============================================================

class _QuoteCardWidget extends StatefulWidget {
  const _QuoteCardWidget({required this.quote, required this.onLike});

  final QuoteCard quote;
  final VoidCallback onLike;

  @override
  State<_QuoteCardWidget> createState() => _QuoteCardWidgetState();
}

class _QuoteCardWidgetState extends State<_QuoteCardWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;

  /// EN: Captures the card as a PNG and saves it to the device gallery.
  /// KO: 카드를 PNG로 캡처하여 기기 갤러리에 저장합니다.
  Future<void> _saveAsImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await Gal.putImageBytes(bytes, name: 'quote_${widget.quote.id}.png');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '이미지가 저장됐어요',
                en: 'Image saved to gallery',
                ja: 'ギャラリーに保存しました',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '저장에 실패했어요',
                en: 'Failed to save image',
                ja: '保存に失敗しました',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// EN: Converts a hex colour string (with or without #) to a [Color].
  /// KO: '#' 포함 여부와 관계없이 16진수 색상 문자열을 [Color]로 변환합니다.
  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return GBTColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = widget.quote;

    // EN: Decide whether the card uses a solid colour, gradient, or theme surface.
    // KO: 카드가 단색, 그라디언트, 테마 표면 중 무엇을 사용할지 결정합니다.
    final hasGradient = quote.backgroundGradientColors.length >= 2;
    final hasSolid = quote.backgroundHexColor != null;
    final bgColor = hasSolid
        ? _hexToColor(quote.backgroundHexColor!)
        : (isDark ? GBTColors.darkSurface : GBTColors.surface);

    // EN: Text uses the inverse token on coloured/gradient backgrounds,
    // theme-aware otherwise.
    // KO: 색상/그라디언트 배경에서는 inverse 토큰, 그 외에는 테마에 맞는
    // 색상을 사용합니다.
    final onCardPrimary = (hasGradient || hasSolid)
        ? GBTColors.textInverse
        : null;

    return Semantics(
      label: '${quote.characterName}: ${quote.quoteText}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN: RepaintBoundary wraps only the visual card for image export.
          // KO: RepaintBoundary는 이미지 내보내기를 위해 시각적 카드만 감쌉니다.
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GBTSpacing.lg),
              decoration: BoxDecoration(
                color: hasGradient ? null : bgColor,
                gradient: hasGradient
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: quote.backgroundGradientColors
                            .map(_hexToColor)
                            .toList(),
                      )
                    : null,
                border: Border(
                  left: BorderSide(
                    color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    width: 3,
                  ),
                  top: BorderSide(
                    color: isDark ? GBTColors.darkBorder : GBTColors.border,
                  ),
                  bottom: BorderSide(
                    color: isDark ? GBTColors.darkBorder : GBTColors.border,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN: Large quotation-mark glyph — the elegant-card
                  // signature. Uses primaryMuted on the plain theme
                  // surface; falls back to a translucent inverse tint on
                  // custom-colored/gradient cards for contrast.
                  // KO: 우아한 카드의 시그니처인 큰 따옴표 글리프 —
                  // 일반 테마 표면에서는 primaryMuted를 사용하고,
                  // 커스텀 색상/그라디언트 카드에서는 대비를 위해
                  // 반투명 inverse 톤으로 대체합니다.
                  Icon(
                    Icons.format_quote_rounded,
                    color:
                        onCardPrimary?.withValues(alpha: 0.35) ??
                        (isDark
                            ? GBTColors.darkPrimary.withValues(alpha: 0.28)
                            : GBTColors.primaryMuted),
                    size: 44,
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    quote.quoteText,
                    style: GBTTypography.titleMedium.copyWith(
                      color:
                          onCardPrimary ??
                          (isDark
                              ? GBTColors.darkTextPrimary
                              : GBTColors.textPrimary),
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: GBTSpacing.md),
                  // EN: Source (character + episode) right-aligned as a
                  // caption — a quiet attribution line under the quote.
                  // KO: 출처(캐릭터 + 에피소드)는 인용구 아래 우측 정렬된
                  // 캡션으로, 조용한 어트리뷰션 라인 역할을 합니다.
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '— ${quote.characterName}',
                          style: GBTTypography.caption.copyWith(
                            color:
                                onCardPrimary?.withValues(alpha: 0.85) ??
                                (isDark
                                    ? GBTColors.darkTextSecondary
                                    : GBTColors.textSecondary),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (quote.episodeContext != null) ...[
                          const SizedBox(height: GBTSpacing.xxs),
                          Text(
                            quote.episodeContext!,
                            style: GBTTypography.caption.copyWith(
                              color:
                                  onCardPrimary?.withValues(alpha: 0.65) ??
                                  (isDark
                                      ? GBTColors.darkTextTertiary
                                      : GBTColors.textTertiary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // EN: Action row: like counter on the left, save button on the right.
          // KO: 액션 행: 왼쪽에 좋아요 카운터, 오른쪽에 저장 버튼입니다.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.xs,
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: quote.isLiked
                      ? context.l10n(ko: '좋아요 취소', en: 'Unlike', ja: 'いいね取り消し')
                      : context.l10n(ko: '좋아요', en: 'Like', ja: 'いいね'),
                  child: InkWell(
                    onTap: widget.onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.sm,
                          vertical: GBTSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              quote.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: quote.isLiked
                                  ? (isDark
                                        ? GBTColors.darkPrimary
                                        : GBTColors.primary)
                                  : (isDark
                                        ? GBTColors.darkTextSecondary
                                        : GBTColors.textSecondary),
                              size: GBTSpacing.iconSm,
                            ),
                            const SizedBox(width: GBTSpacing.xs),
                            Text(
                              '${quote.likeCount}',
                              style: GBTTypography.bodySmall.copyWith(
                                color: isDark
                                    ? GBTColors.darkTextSecondary
                                    : GBTColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: context.l10n(
                    ko: '이미지로 저장',
                    en: 'Save as image',
                    ja: '画像として保存',
                  ),
                  child: InkWell(
                    onTap: _saveAsImage,
                    borderRadius: BorderRadius.circular(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GBTSpacing.sm,
                          vertical: GBTSpacing.xs,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: GBTSpacing.iconSm,
                                height: GBTSpacing.iconSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.download_outlined,
                                size: GBTSpacing.iconSm,
                                color: isDark
                                    ? GBTColors.darkTextSecondary
                                    : GBTColors.textSecondary,
                              ),
                      ),
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
}
