/// EN: Clean-sheet community root for field reports and travel knowledge.
/// KO: 필드 리포트와 여행 지식을 위한 새 커뮤니티 루트.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../application/board_controller.dart';
import '../widgets/community_fab_layout.dart';
import 'field_community_providers.dart';
import 'sections/field_community_timeline_section.dart';
import 'sections/field_community_travel_section.dart';
import 'widgets/field_community_masthead.dart';
import 'widgets/field_community_mode_bar.dart';

enum _FieldCommunitySection { feed, discover, travel }

/// EN: Uses the existing bottom-nav routes while replacing their page design.
/// KO: 기존 하단바 라우트를 유지하면서 페이지 디자인을 새로 구성합니다.
class FieldCommunityPage extends ConsumerStatefulWidget {
  const FieldCommunityPage({super.key, this.initialSectionIndex = 0});

  /// EN: 0 feed, 1 discover, 2 travel notes; controlled by existing routes.
  /// KO: 0 피드, 1 발견, 2 여행 노트이며 기존 라우트가 제어합니다.
  final int initialSectionIndex;

  @override
  ConsumerState<FieldCommunityPage> createState() => _FieldCommunityPageState();
}

class _FieldCommunityPageState extends ConsumerState<FieldCommunityPage>
    with WidgetsBindingObserver {
  static const Duration _foregroundRefreshInterval = Duration(seconds: 25);

  Timer? _foregroundRefreshTimer;
  FieldCommunityActions? _activeLifecycleActions;
  bool _isAppResumed = true;
  bool _isRealtimeLifecycleActive = false;
  bool _isDisposed = false;

  _FieldCommunitySection get _section {
    if (widget.initialSectionIndex <= 0) return _FieldCommunitySection.feed;
    if (widget.initialSectionIndex == 1) {
      return _FieldCommunitySection.discover;
    }
    return _FieldCommunitySection.travel;
  }

  List<CommunityFeedMode> get _modes => switch (_section) {
    _FieldCommunitySection.feed => const [
      CommunityFeedMode.recommended,
      CommunityFeedMode.following,
    ],
    _FieldCommunitySection.discover => const [
      CommunityFeedMode.trending,
      CommunityFeedMode.latest,
    ],
    _FieldCommunitySection.travel => const [],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startFeedLifecycle();
    WidgetsBinding.instance.addPostFrameCallback((_) => _alignFeedMode());
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopFeedLifecycle();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FieldCommunityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSectionIndex == widget.initialSectionIndex) return;
    final hadLiveFeed = oldWidget.initialSectionIndex <= 1;
    final hasLiveFeed = widget.initialSectionIndex <= 1;
    if (hadLiveFeed && !hasLiveFeed) {
      _stopFeedLifecycle();
    } else if (!hadLiveFeed && hasLiveFeed) {
      _startFeedLifecycle();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _alignFeedMode());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) _refreshFeedIfVisible();
  }

  void _startFeedLifecycle() {
    if (_isDisposed ||
        _isRealtimeLifecycleActive ||
        _section == _FieldCommunitySection.travel) {
      return;
    }
    final actions = ref.read(fieldCommunityActionsProvider);
    _activeLifecycleActions = actions;
    _isRealtimeLifecycleActive = true;
    unawaited(actions.startRealtimeSync());
    _foregroundRefreshTimer ??= Timer.periodic(
      _foregroundRefreshInterval,
      (_) => _refreshFeedIfVisible(),
    );
  }

  void _stopFeedLifecycle() {
    _foregroundRefreshTimer?.cancel();
    _foregroundRefreshTimer = null;
    if (!_isRealtimeLifecycleActive) return;
    _isRealtimeLifecycleActive = false;
    final actions = _activeLifecycleActions;
    _activeLifecycleActions = null;
    if (actions != null) unawaited(actions.stopRealtimeSync());
  }

  void _refreshFeedIfVisible() {
    if (_isDisposed ||
        !mounted ||
        !_isAppResumed ||
        !_isRealtimeLifecycleActive) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final actions = _activeLifecycleActions;
    if (actions == null) return;
    unawaited(
      actions.refreshInBackground(minInterval: _foregroundRefreshInterval),
    );
  }

  void _alignFeedMode() {
    if (!mounted || _section == _FieldCommunitySection.travel) return;
    final state = ref.read(fieldCommunityFeedStateProvider);
    if (_modes.contains(state.mode)) return;
    unawaited(ref.read(fieldCommunityActionsProvider).selectMode(_modes.first));
  }

  void _selectMode(CommunityFeedMode mode) {
    HapticFeedback.selectionClick();
    unawaited(ref.read(fieldCommunityActionsProvider).selectMode(mode));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = _section == _FieldCommunitySection.travel
        ? null
        : ref.watch(fieldCommunityFeedStateProvider);
    final selectedMode = feedState != null && _modes.contains(feedState.mode)
        ? feedState.mode
        : (_modes.isEmpty ? null : _modes.first);

    return Scaffold(
      backgroundColor: isDark ? GBTColors.darkBackground : GBTColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FieldCommunityMasthead(
              onSearch: context.goToSearch,
              onSettings: context.goToCommunitySettings,
            ),
            if (selectedMode != null)
              FieldCommunityModeBar(
                modes: _modes,
                selected: selectedMode,
                onSelected: _selectMode,
              ),
            Expanded(child: _buildSection(feedState)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _section == _FieldCommunitySection.travel
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: resolveCommunityFabBottomPadding(
                  screenHeight: MediaQuery.sizeOf(context).height,
                ),
              ),
              child: Semantics(
                button: true,
                label: _composeLabel(context),
                child: FloatingActionButton.extended(
                  key: const Key('field-community-compose'),
                  onPressed: context.goToPostCreate,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(_composeLabel(context)),
                ),
              ),
            ),
    );
  }

  Widget _buildSection(CommunityFeedViewState? feedState) {
    if (_section == _FieldCommunitySection.travel) {
      return FieldCommunityTravelSection(
        onWriteGeneralReport: context.goToPostCreate,
      );
    }
    final state = feedState ?? const CommunityFeedViewState();
    final actions = ref.read(fieldCommunityActionsProvider);
    return FieldCommunityTimelineSection(
      state: state,
      onRefresh: actions.refresh,
      onLoadMore: actions.loadMore,
      onApplyPending: actions.applyPendingPosts,
      onCompose: context.goToPostCreate,
      onPostTap: (postId, projectId) {
        context.goToPostDetail(postId, projectCode: projectId);
      },
    );
  }

  String _composeLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'en') return 'Write report';
    if (languageCode == 'ja') return 'レポートを書く';
    return '리포트 쓰기';
  }
}
