/// EN: Full-page banner picker for profile background customization.
/// KO: 프로필 배경 커스터마이징을 위한 전체 페이지 배너 피커.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/banner_controller.dart';
import '../../domain/entities/banner_entities.dart';
import '../banner_picker_layout.dart';

// =============================================================================
// EN: Rarity visual constants
// KO: 희귀도 시각화 상수
// =============================================================================

Color _rarityBorderColor(BannerRarity rarity) {
  return switch (rarity) {
    BannerRarity.common => GBTColors.textTertiary,
    BannerRarity.rare => GBTColors.accentBlue,
    BannerRarity.epic => GBTColors.secondary,
    BannerRarity.legendary => GBTColors.accent,
  };
}

String _rarityLabel(BannerRarity rarity) {
  return switch (rarity) {
    BannerRarity.common => '일반',
    BannerRarity.rare => '레어',
    BannerRarity.epic => '에픽',
    BannerRarity.legendary => '레전더리',
  };
}

// =============================================================================
// EN: BannerPickerPage — ConsumerStatefulWidget
// KO: BannerPickerPage — ConsumerStatefulWidget
// =============================================================================

/// EN: Full-page route that lets the user select and apply a profile banner.
///     Shows a 3-column thumbnail grid with rarity border, lock overlay,
///     and a bottom apply button.
/// KO: 사용자가 프로필 배너를 선택하고 적용할 수 있는 전체 페이지 라우트.
///     희귀도 테두리, 잠금 오버레이, 하단 적용 버튼을 포함한 3열 썸네일 그리드를 표시합니다.
class BannerPickerPage extends ConsumerStatefulWidget {
  const BannerPickerPage({super.key});

  @override
  ConsumerState<BannerPickerPage> createState() => _BannerPickerPageState();
}

class _BannerPickerPageState extends ConsumerState<BannerPickerPage> {
  // EN: Locally selected banner id (not yet applied).
  // KO: 아직 적용되지 않은 로컬 선택 배너 ID.
  String? _selectedId;

  // EN: True while the apply mutation is in-flight.
  // KO: 적용 변이가 진행 중인 경우 true.
  bool _isApplying = false;

  // EN: True while the remove mutation is in-flight.
  // KO: 해제 변이가 진행 중인 경우 true.
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    // EN: Seed the selection with the currently active banner on first render.
    // KO: 첫 렌더 시 현재 활성 배너로 선택값을 초기화합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeBanner = ref.read(activeBannerProvider).valueOrNull;
      if (_selectedId == null && activeBanner?.bannerId != null) {
        setState(() => _selectedId = activeBanner!.bannerId);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // EN: Interaction handlers
  // KO: 상호작용 핸들러
  // ---------------------------------------------------------------------------

  void _onBannerTap(BannerItem item) {
    if (!item.isUnlocked) {
      final description = item.unlockDescription?.isNotEmpty == true
          ? item.unlockDescription!
          : '이 배너를 해금하려면 조건을 달성하세요';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(description),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _selectedId = item.id);
  }

  Future<void> _onRemove() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);
    try {
      await ref.read(bannerCatalogProvider.notifier).removeBanner();
      if (!mounted) return;
      setState(() => _selectedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배너가 해제되었어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배너 해제에 실패했어요: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _onApply() async {
    final selectedId = _selectedId;
    if (selectedId == null || _isApplying) return;

    setState(() => _isApplying = true);
    try {
      await ref.read(bannerCatalogProvider.notifier).applyBanner(selectedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배너가 적용되었어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배너 적용에 실패했어요: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  // ---------------------------------------------------------------------------
  // EN: Build
  // KO: 빌드
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalogState = ref.watch(bannerCatalogProvider);
    final activeBannerAsync = ref.watch(activeBannerProvider);

    // EN: Derive the currently active banner id from the notifier.
    // KO: 노티파이어에서 현재 활성 배너 ID를 도출합니다.
    final activeId = activeBannerAsync.valueOrNull?.bannerId;

    // EN: The apply button is disabled when:
    //   1. No item is selected.
    //   2. The selected item is already the active banner.
    //   3. An apply mutation is in-flight.
    // KO: 적용 버튼 비활성화 조건:
    //   1. 선택된 항목이 없는 경우.
    //   2. 선택된 항목이 이미 활성 배너인 경우.
    //   3. 적용 변이가 진행 중인 경우.
    final isApplyDisabled =
        _selectedId == null || _selectedId == activeId || _isApplying;

    final scaffoldBg = isDark ? GBTColors.darkBackground : GBTColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: gbtStandardAppBar(
        context,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: '배너 꾸미기',
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GBTPageHeader(
            eyebrow: 'PROFILE BANNER',
            title: '여행 여권의 표지를 고르세요',
            description: '칭호와 티어를 달성하면 새로운 배너가 열려요.',
          ),

          // EN: Catalog grid (expands to fill available space)
          // KO: 카탈로그 그리드 (가용 공간 채움)
          Expanded(
            child: catalogState.when(
              loading: () => _BannerGridShimmer(isDark: isDark),
              error: (error, _) => _BannerErrorState(
                onRetry: () =>
                    ref.read(bannerCatalogProvider.notifier).refresh(),
              ),
              data: (items) => _BannerGrid(
                items: items,
                selectedId: _selectedId,
                onTap: _onBannerTap,
              ),
            ),
          ),

          // EN: Bottom bar — apply selected banner or remove active banner.
          // KO: 하단 바 — 선택한 배너 적용 또는 활성 배너 해제.
          _ApplyBar(
            isDark: isDark,
            isDisabled: isApplyDisabled,
            isApplying: _isApplying,
            onApply: _onApply,
            hasActiveBanner: activeId != null,
            isRemoving: _isRemoving,
            onRemove: _onRemove,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Banner grid — renders the catalog items.
// KO: 배너 그리드 — 카탈로그 아이템을 렌더링합니다.
// =============================================================================

class _BannerGrid extends StatelessWidget {
  const _BannerGrid({
    required this.items,
    required this.selectedId,
    required this.onTap,
  });

  final List<BannerItem> items;
  final String? selectedId;
  final void Function(BannerItem) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const GBTEmptyState(
        icon: Icons.panorama_outlined,
        title: '아직 표시할 배너가 없어요',
        subtitle: '칭호와 티어를 확장하면 이곳에 추가됩니다.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = resolveBannerPickerLayout(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            GBTSpacing.md,
            GBTSpacing.pageHorizontal,
            GBTSpacing.xl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            crossAxisSpacing: GBTSpacing.sm,
            mainAxisSpacing: GBTSpacing.sm,
            childAspectRatio: layout.childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _BannerCell(
              item: item,
              isSelected: item.id == selectedId,
              onTap: () => onTap(item),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// EN: Single banner cell in the grid.
// KO: 그리드의 단일 배너 셀.
// =============================================================================

class _BannerCell extends StatelessWidget {
  const _BannerCell({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final BannerItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSelected
        ? (isDark ? GBTColors.darkPrimary : GBTColors.primary)
        : _rarityBorderColor(item.rarity);
    final borderWidth = isSelected ? 2.5 : 1.5;

    return Semantics(
      label:
          '${item.name}, ${_rarityLabel(item.rarity)},'
          ' ${item.isUnlocked ? "해금됨" : "잠김"}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              GBTSpacing.radiusMd - borderWidth,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // EN: Thumbnail image
                // KO: 썸네일 이미지
                GBTImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  useShimmer: true,
                  semanticLabel: item.name,
                ),

                // EN: Lock overlay for locked banners
                // KO: 잠긴 배너의 잠금 오버레이
                if (!item.isUnlocked)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: GBTColors.overlay.withValues(alpha: 0.55),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          color: GBTColors.textInverse,
                          size: 22,
                        ),
                        if (item.unlockDescription?.isNotEmpty == true) ...[
                          const SizedBox(height: GBTSpacing.xxs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GBTSpacing.xs,
                            ),
                            child: Text(
                              item.unlockDescription!,
                              style: GBTTypography.caption.copyWith(
                                color: GBTColors.textInverse.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // EN: Checkmark badge for the active item
                // KO: 활성 항목의 체크마크 뱃지
                if (item.isActive)
                  Positioned(
                    top: GBTSpacing.xs,
                    right: GBTSpacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.check_rounded,
                          color: GBTColors.textInverse,
                          size: 12,
                        ),
                      ),
                    ),
                  ),

                // EN: Selected highlight ring (not yet applied)
                // KO: 선택됨 하이라이트 링 (아직 적용 전)
                if (isSelected && !item.isActive)
                  Positioned(
                    top: GBTSpacing.xs,
                    right: GBTSpacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GBTColors.textInverse.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.check_rounded,
                          color: isDark
                              ? GBTColors.darkPrimary
                              : GBTColors.primary,
                          size: 12,
                        ),
                      ),
                    ),
                  ),

                // EN: Rarity badge at the bottom-left corner
                // KO: 왼쪽 하단 모서리의 희귀도 뱃지
                Positioned(
                  bottom: GBTSpacing.xs,
                  left: GBTSpacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _rarityBorderColor(
                        item.rarity,
                      ).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.xxs + 2,
                        vertical: 2,
                      ),
                      child: Text(
                        _rarityLabel(item.rarity),
                        style: GBTTypography.caption.copyWith(
                          color: GBTColorValidator.getContrastingTextColor(
                            _rarityBorderColor(item.rarity),
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

// =============================================================================
// EN: Shimmer loading placeholder for the grid.
// KO: 그리드용 쉬머 로딩 플레이스홀더.
// =============================================================================

class _BannerGridShimmer extends StatelessWidget {
  const _BannerGridShimmer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmerColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = resolveBannerPickerLayout(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            GBTSpacing.md,
            GBTSpacing.pageHorizontal,
            GBTSpacing.xl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            crossAxisSpacing: GBTSpacing.sm,
            mainAxisSpacing: GBTSpacing.sm,
            childAspectRatio: layout.childAspectRatio,
          ),
          // EN: Show nine placeholders while preserving the final grid width.
          // KO: 최종 그리드 너비를 유지하며 9개 플레이스홀더를 표시합니다.
          itemCount: 9,
          itemBuilder: (_, __) => GBTShimmer(
            child: Container(
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// EN: Error state with retry button.
// KO: 재시도 버튼이 있는 오류 상태.
// =============================================================================

class _BannerErrorState extends StatelessWidget {
  const _BannerErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark
                ? GBTColors.darkTextSecondary
                : GBTColors.textSecondary,
          ),
          const SizedBox(height: GBTSpacing.md),
          Text(
            '배너 목록을 불러오지 못했어요',
            style: GBTTypography.bodyMedium.copyWith(
              color: isDark
                  ? GBTColors.darkTextSecondary
                  : GBTColors.textSecondary,
            ),
          ),
          const SizedBox(height: GBTSpacing.lg),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

// =============================================================================
// EN: Bottom apply bar — sticky CTA.
// KO: 하단 적용 바 — 고정 CTA.
// =============================================================================

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.isDark,
    required this.isDisabled,
    required this.isApplying,
    required this.onApply,
    this.hasActiveBanner = false,
    this.isRemoving = false,
    this.onRemove,
  });

  final bool isDark;
  final bool isDisabled;
  final bool isApplying;
  final VoidCallback onApply;
  // EN: Whether the user currently has an active banner (enables the remove button).
  // KO: 사용자에게 활성 배너가 있는지 여부 (해제 버튼 활성화).
  final bool hasActiveBanner;
  final bool isRemoving;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurface : GBTColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? GBTColors.darkSurfaceVariant
                : GBTColors.surfaceVariant,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.md + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EN: Apply button — primary CTA.
            // KO: 적용 버튼 — 기본 CTA.
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isDisabled ? null : onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? GBTColors.darkPrimary
                      : GBTColors.primary,
                  foregroundColor: GBTColors.textInverse,
                  disabledBackgroundColor: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                  disabledForegroundColor: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: isApplying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GBTColors.textInverse,
                        ),
                      )
                    : const Text('이 배너 적용'),
              ),
            ),

            // EN: Remove button — secondary, only shown when banner is active.
            // KO: 해제 버튼 — 보조, 활성 배너가 있을 때만 표시됩니다.
            if (hasActiveBanner) ...[
              const SizedBox(height: GBTSpacing.xs),
              SizedBox(
                height: GBTSpacing.touchTarget,
                child: TextButton(
                  onPressed: isRemoving ? null : onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                    ),
                  ),
                  child: isRemoving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? GBTColors.darkTextSecondary
                                : GBTColors.textSecondary,
                          ),
                        )
                      : const Text('배너 해제'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
