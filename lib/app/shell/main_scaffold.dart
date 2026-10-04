/// EN: Main scaffold with 5-tab navigation (PR9 IA: home/map/live/community/
/// EN: mypage). Every branch — including community — shows the same main
/// EN: `GBTBottomNav`; community's internal section switch moved to its own
/// EN: top navigation (`FieldCommunityPage`).
/// KO: 5탭 네비게이션을 포함한 메인 스캐폴드 (PR9 IA: 홈/지도/라이브/
/// KO: 커뮤니티/마이). 커뮤니티를 포함한 모든 분기가 동일한 메인
/// KO: `GBTBottomNav`를 표시합니다; 커뮤니티 내부 섹션 전환은 자체 상단
/// KO: 내비게이션으로 옮겨졌습니다(`FieldCommunityPage`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/localization/locale_text.dart';
import '../../platform/router/app_router.dart' show NavIndex;
import '../../platform/router/navigation_state.dart';
import '../../design_system/widgets/navigation/gbt_bottom_nav.dart';

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

  void _scheduleSync(int index) {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      if (_lastSyncedIndex == index &&
          ref.read(currentNavIndexProvider) == index) {
        return;
      }
      _lastSyncedIndex = index;
      ref.read(currentNavIndexProvider.notifier).state = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final storedIndex = ref.watch(currentNavIndexProvider);
    final canNavigateBack = GoRouter.of(context).canPop();
    final currentPath = GoRouterState.of(context).uri.path;
    final shouldShowBottomNav = _shouldShowBottomNav(
      currentIndex: currentIndex,
      currentPath: currentPath,
    );
    if (_lastSyncedIndex != currentIndex || storedIndex != currentIndex) {
      _scheduleSync(currentIndex);
    }

    return PopScope(
      canPop: canNavigateBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || canNavigateBack) return;
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
            : GBTBottomNav(
                items: [
                  GBTBottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: context.l10n(ko: '홈', en: 'Home', ja: 'ホーム'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: context.l10n(ko: '지도', en: 'Map', ja: 'マップ'),
                  ),
                  GBTBottomNavItem(
                    icon: Icons.music_note_outlined,
                    activeIcon: Icons.music_note,
                    label: context.l10n(ko: '라이브', en: 'Live', ja: 'ライブ'),
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
                  GBTBottomNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: context.l10n(ko: '마이', en: 'My', ja: 'マイ'),
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
    if (currentIndex == NavIndex.home) {
      return currentPath == '/home';
    }
    if (currentIndex == NavIndex.map) {
      return currentPath == '/map';
    }
    if (currentIndex == NavIndex.live) {
      return currentPath == '/live' || currentPath == '/live/music';
    }
    if (currentIndex == NavIndex.community) {
      return _isCommunityRootRoute(currentPath);
    }
    if (currentIndex == NavIndex.mypage) {
      return currentPath == '/mypage';
    }
    return false;
  }

  bool _isCommunityRootRoute(String path) {
    return path == '/community' ||
        path == '/community/discover' ||
        path == '/community/travel-reviews-tab';
  }

  /// EN: Handle bottom navigation tap
  /// KO: 하단 네비게이션 탭 처리
  void _onTap(BuildContext context, int index) {
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
