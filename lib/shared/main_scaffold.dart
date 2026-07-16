/// EN: Main scaffold with 5-tab navigation and board-specific sub bottom bar.
/// KO: 5탭 네비게이션과 게시판 전용 서브 하단바를 포함한 메인 스캐폴드.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/locale_text.dart';
import '../core/providers/core_providers.dart';
import '../core/theme/gbt_colors.dart';
import '../core/theme/gbt_spacing.dart';
import '../core/widgets/navigation/gbt_bottom_nav.dart';

/// EN: Main scaffold widget with stateful navigation shell
/// KO: 상태 유지 네비게이션 쉘을 포함한 메인 스캐폴드 위젯
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const Duration _androidExitBackWindow = Duration(seconds: 3);

  int? _lastSyncedIndex;
  bool _syncScheduled = false;
  DateTime? _lastBackPressed;
  String _lastNonCommunityLocation = '/home';

  void _scheduleSync(int index) {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || _lastSyncedIndex == index) return;
      _lastSyncedIndex = index;
      ref.read(currentNavIndexProvider.notifier).state = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final canNavigateBack = GoRouter.of(context).canPop();
    final currentUri = GoRouterState.of(context).uri;
    final currentPath = currentUri.path;
    final currentLocation = currentUri.toString();
    final isCommunityBranch = currentIndex == 4;
    final isCommunityRoot =
        isCommunityBranch && _isCommunityRootRoute(currentPath);
    final shouldShowBottomNav = _shouldShowBottomNav(
      currentIndex: currentIndex,
      currentPath: currentPath,
    );
    if (!isCommunityBranch) {
      _lastNonCommunityLocation = currentLocation;
    }
    if (_lastSyncedIndex != currentIndex) {
      _scheduleSync(currentIndex);
    }

    return PopScope(
      canPop: canNavigateBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || canNavigateBack) return;
        if (defaultTargetPlatform == TargetPlatform.android &&
            isCommunityRoot) {
          final target = _lastNonCommunityLocation;
          context.go(
            target.startsWith('/community') || target.isEmpty
                ? '/home'
                : target,
          );
          return;
        }
        if (defaultTargetPlatform != TargetPlatform.android) {
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < _androidExitBackWindow) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressed = now;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '뒤로 버튼을 한 번 더 누르면 앱이 종료됩니다',
                en: 'Press back again within 3 seconds to exit',
                ja: '3秒以内にもう一度戻るを押すと終了します',
              ),
            ),
            duration: _androidExitBackWindow,
          ),
        );
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: !shouldShowBottomNav
            ? null
            : isCommunityBranch
            ? CommunitySubBottomNav(
                section: _resolveCommunitySection(currentPath),
                onBackTap: () {
                  final target = _lastNonCommunityLocation;
                  context.go(
                    target.startsWith('/community') || target.isEmpty
                        ? '/home'
                        : target,
                  );
                },
                onSectionChanged: (section) {
                  ref.read(currentNavIndexProvider.notifier).state = 4;
                  switch (section) {
                    case CommunitySubSection.feed:
                      widget.navigationShell.goBranch(4, initialLocation: true);
                    case CommunitySubSection.discover:
                      context.go('/community/discover');
                    case CommunitySubSection.travelReview:
                      context.go('/community/travel-reviews-tab');
                  }
                },
              )
            : GBTBottomNav(
                items: [
                  GBTBottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: context.l10n(ko: '홈', en: 'Home', ja: 'ホーム'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: context.l10n(ko: '탐방', en: 'Explore', ja: '探索'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.auto_stories_outlined,
                    activeIcon: Icons.auto_stories,
                    label: context.l10n(ko: '정보', en: 'Info', ja: '情報'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: context.l10n(ko: '유저', en: 'My', ja: 'マイ'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.forum_outlined,
                    activeIcon: Icons.forum,
                    label: context.l10n(
                      ko: '커뮤니티',
                      en: 'Community',
                      ja: 'コミュニティ',
                    ),
                  ),
                ],
                currentIndex: currentIndex,
                onTap: (index) => _onTap(context, index),
              ),
      ),
    );
  }

  bool _shouldShowBottomNav({
    required int currentIndex,
    required String currentPath,
  }) {
    if (currentIndex == 4) {
      return _isCommunityRootRoute(currentPath);
    }
    if (currentIndex == 0) {
      return currentPath == '/home';
    }
    if (currentIndex == 1) {
      return currentPath == '/explore';
    }
    if (currentIndex == 2) {
      return currentPath == '/information';
    }
    if (currentIndex == 3) {
      return currentPath == '/mypage';
    }
    return false;
  }

  bool _isCommunityRootRoute(String path) {
    return path == '/community' ||
        path == '/community/discover' ||
        path == '/community/travel-reviews-tab';
  }

  CommunitySubSection _resolveCommunitySection(String path) {
    if (path.startsWith('/community/travel-reviews-tab')) {
      return CommunitySubSection.travelReview;
    }
    if (path.startsWith('/community/discover')) {
      return CommunitySubSection.discover;
    }
    return CommunitySubSection.feed;
  }

  /// EN: Handle bottom navigation tap
  /// KO: 하단 네비게이션 탭 처리
  void _onTap(BuildContext context, int index) {
    if (index == 4 && widget.navigationShell.currentIndex != 4) {
      _lastNonCommunityLocation = GoRouterState.of(context).uri.toString();
    }
    widget.navigationShell.goBranch(
      index,
      // EN: Navigate to initial location if tapping current tab
      // KO: 현재 탭을 탭하면 초기 위치로 이동
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _lastSyncedIndex = index;
    ref.read(currentNavIndexProvider.notifier).state = index;
  }
}

/// EN: Destinations shown in the community-specific persistent navigation.
/// KO: 커뮤니티 전용 고정 내비게이션에 표시되는 목적지입니다.
enum CommunitySubSection { feed, discover, travelReview }

extension on CommunitySubSection {
  String label(BuildContext context) => switch (this) {
    CommunitySubSection.feed => context.l10n(ko: '피드', en: 'Feed', ja: 'フィード'),
    CommunitySubSection.discover => context.l10n(
      ko: '발견',
      en: 'Discover',
      ja: '発見',
    ),
    CommunitySubSection.travelReview => context.l10n(
      ko: '여행후기',
      en: 'Travel Reviews',
      ja: '旅行レビュー',
    ),
  };

  IconData get icon => switch (this) {
    CommunitySubSection.feed => Icons.dynamic_feed_outlined,
    CommunitySubSection.discover => Icons.explore_outlined,
    CommunitySubSection.travelReview => Icons.rate_review_outlined,
  };
}

/// EN: Preserves the community-specific lower bar across platform layouts.
/// KO: 플랫폼별 레이아웃에서 커뮤니티 전용 하단바를 보존합니다.
class CommunitySubBottomNav extends StatelessWidget {
  const CommunitySubBottomNav({
    super.key,
    required this.section,
    required this.onBackTap,
    required this.onSectionChanged,
  });

  final CommunitySubSection section;
  final VoidCallback onBackTap;
  final ValueChanged<CommunitySubSection> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return _buildAndroidBoardSubBottomNav(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final navCornerRadius = isIos ? 38.0 : 34.0;
    final navShape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(navCornerRadius),
    );
    final selectedColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    final unselectedColor = isDark
        ? GBTColors.darkTextSecondary.withValues(alpha: 0.82)
        : GBTColors.textSecondary.withValues(alpha: 0.82);
    final gradientColors = isDark
        ? [
            GBTColors.darkSurface.withValues(alpha: 0.95),
            GBTColors.darkSurfaceVariant.withValues(alpha: 0.95),
          ]
        : [
            GBTColors.surface.withValues(alpha: 0.95),
            GBTColors.appBackground.withValues(alpha: 0.95),
          ];
    final borderColor = isDark
        ? GBTColors.darkBorder.withValues(alpha: 0.72)
        : GBTColors.border.withValues(alpha: 0.82);
    final backButtonColor = isDark
        ? GBTColors.darkSurfaceElevated.withValues(alpha: 0.78)
        : GBTColors.surfaceVariant.withValues(alpha: 0.90);
    final backIconColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final navHeight = GBTSpacing.scaledBottomNavHeight(
      context,
      baseHeight: GBTSpacing.bottomNavHeight + 8,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: navHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(navCornerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.16),
              blurRadius: isDark ? 30 : 24,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipPath(
          // EN: iOS-like continuous corner profile for the board sub-nav pill.
          // KO: 게시판 서브 내비게이션 pill에 iOS 스타일의 연속 곡률을 적용합니다.
          clipper: ShapeBorderClipper(shape: navShape),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                border: Border.all(color: borderColor, width: 0.8),
                borderRadius: BorderRadius.circular(navCornerRadius),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Semantics(
                      button: true,
                      label: context.l10n(
                        ko: '이전 화면으로 돌아가기',
                        en: 'Go back to previous screen',
                        ja: '前の画面に戻る',
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkResponse(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onBackTap();
                          },
                          radius: 28,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: backButtonColor,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 30,
                              color: backIconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: CommunitySubSection.values.map((value) {
                        final isSelected = value == section;
                        final itemColor = isSelected
                            ? selectedColor
                            : unselectedColor;
                        return Expanded(
                          child: Semantics(
                            button: true,
                            selected: isSelected,
                            label:
                                '${value.label(context)} ${context.l10n(ko: '탭', en: 'tab', ja: 'タブ')}',
                            hint: isSelected
                                ? context.l10n(
                                    ko: '현재 선택됨',
                                    en: 'Currently selected',
                                    ja: '現在選択中',
                                  )
                                : context.l10n(
                                    ko: '탭하면 이동합니다',
                                    en: 'Tap to switch',
                                    ja: 'タップして切り替え',
                                  ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSectionChanged(value);
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Icon(
                                          value.icon,
                                          key: ValueKey(
                                            '${value.name}-$isSelected',
                                          ),
                                          color: itemColor,
                                          size: isSelected ? 24 : 22,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        value.label(context),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: itemColor,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 10.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidBoardSubBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(28);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.34 : 0.16);
    final surfaceTint = colorScheme.primary.withValues(alpha: 0.08);
    final backButtonFill = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.82)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.84);
    final navHeight = GBTSpacing.scaledBottomNavHeight(
      context,
      baseHeight: GBTSpacing.bottomNavHeight,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isDark ? 26 : 20,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Material(
          color: colorScheme.surface,
          surfaceTintColor: surfaceTint,
          shadowColor: shadowColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              height: navHeight,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: context.l10n(
                      ko: '이전 화면으로 돌아가기',
                      en: 'Go back to previous screen',
                      ja: '前の画面に戻る',
                    ),
                    child: Material(
                      color: backButtonFill,
                      shape: const CircleBorder(),
                      child: InkResponse(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onBackTap();
                        },
                        radius: 28,
                        containedInkWell: true,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.arrow_back_rounded, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: CommunitySubSection.values
                          .map((value) {
                            final isSelected = value == section;
                            final itemColor = isSelected
                                ? selectedColor
                                : unselectedColor;
                            final itemBackground = isSelected
                                ? selectedColor.withValues(alpha: 0.12)
                                : Colors.transparent;
                            final itemBorder = isSelected
                                ? selectedColor.withValues(alpha: 0.16)
                                : Colors.transparent;

                            return Expanded(
                              child: Semantics(
                                button: true,
                                selected: isSelected,
                                label:
                                    '${value.label(context)} ${context.l10n(ko: '탭', en: 'tab', ja: 'タブ')}',
                                hint: isSelected
                                    ? context.l10n(
                                        ko: '현재 선택됨',
                                        en: 'Currently selected',
                                        ja: '現在選択中',
                                      )
                                    : context.l10n(
                                        ko: '탭하면 이동합니다',
                                        en: 'Tap to switch',
                                        ja: 'タップして切り替え',
                                      ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      onSectionChanged(value);
                                    },
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: itemBackground,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: itemBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: Icon(
                                              value.icon,
                                              key: ValueKey(
                                                '${value.name}-$isSelected',
                                              ),
                                              color: itemColor,
                                              size: isSelected ? 24 : 22,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            value.label(context),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: itemColor,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  fontSize: 10.5,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
