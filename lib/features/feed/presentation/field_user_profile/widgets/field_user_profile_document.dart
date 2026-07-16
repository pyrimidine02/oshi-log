/// EN: Route-agnostic traveler profile document.
/// KO: 라우트에 의존하지 않는 여행자 프로필 문서입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/gbt_colors.dart';
import '../../../domain/entities/feed_entities.dart';
import '../field_user_profile_view_data.dart';
import 'field_profile_activity.dart';
import 'field_profile_calling_card.dart';
import 'field_profile_ledger.dart';

/// EN: Composes identity, factual metrics, and activity as one field record.
/// KO: 신원, 사실 지표, 활동을 하나의 현장 기록으로 구성합니다.
class FieldUserProfileDocument extends StatelessWidget {
  const FieldUserProfileDocument({
    super.key,
    required this.data,
    required this.posts,
    required this.comments,
    required this.isAuthenticated,
    required this.isFollowing,
    required this.isBlocked,
    required this.isFollowBusy,
    required this.isMoreBusy,
    required this.onBack,
    required this.onAvatarTap,
    required this.onFollow,
    required this.onMore,
    required this.onFollowers,
    required this.onFollowing,
    required this.onRefresh,
    required this.onOpenPost,
    this.onRefreshVisits,
    this.isMyProfile = false,
    this.onCoverTap,
    this.onMessage,
    this.onEdit,
    this.onOpenTitlePicker,
    this.activeTitleBadge,
    this.isActivityLoading = false,
    this.activityErrorMessage,
    this.blockedMessage,
    this.onRetryActivity,
    this.onOpenFanLevel,
    this.onOpenPlaceHistory,
    this.onOpenLiveHistory,
    this.accountLedger,
  });

  final FieldUserProfileViewData data;
  final List<PostSummary> posts;
  final List<PostComment> comments;
  final bool isMyProfile;
  final bool isAuthenticated;
  final bool isFollowing;
  final bool isBlocked;
  final bool isFollowBusy;
  final bool isMoreBusy;
  final VoidCallback onBack;
  final VoidCallback onAvatarTap;
  final VoidCallback? onCoverTap;
  final VoidCallback onFollow;
  final VoidCallback? onMessage;
  final VoidCallback onMore;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenTitlePicker;
  final Widget? activeTitleBadge;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onRefreshVisits;
  final FieldOpenPost onOpenPost;
  final bool isActivityLoading;
  final String? activityErrorMessage;
  final String? blockedMessage;
  final VoidCallback? onRetryActivity;
  final VoidCallback? onOpenFanLevel;
  final VoidCallback? onOpenPlaceHistory;
  final VoidCallback? onOpenLiveHistory;
  final Widget? accountLedger;

  @override
  Widget build(BuildContext context) {
    final visitCount = data.metrics
        .where((metric) => metric.kind == FieldProfileMetricKind.placeVisits)
        .map((metric) => metric.value)
        .firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabHeight = MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? 64.0
        : 48.0;
    return DefaultTabController(
      length: 3,
      child: ColoredBox(
        color: isDark ? GBTColors.darkBackground : GBTColors.fieldPaper,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: const ValueKey<String>('traveler-field-card'),
                child: FieldProfileCallingCard(
                  data: data,
                  activeTitleBadge: activeTitleBadge,
                  isMyProfile: isMyProfile,
                  isAuthenticated: isAuthenticated,
                  isFollowing: isFollowing,
                  isBlocked: isBlocked,
                  isFollowBusy: isFollowBusy,
                  isMoreBusy: isMoreBusy,
                  onBack: onBack,
                  onAvatarTap: onAvatarTap,
                  onCoverTap: onCoverTap ?? () {},
                  onFollow: onFollow,
                  onMessage: onMessage,
                  onMore: onMore,
                  onFollowers: onFollowers,
                  onFollowing: onFollowing,
                  onEdit: onEdit ?? () {},
                  onOpenTitlePicker: onOpenTitlePicker ?? () {},
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: const ValueKey<String>('traveler-field-ledger'),
                child: FieldProfileLedger(
                  metrics: data.metrics,
                  onOpenFanLevel: onOpenFanLevel,
                  onOpenPlaceHistory: onOpenPlaceHistory,
                  onOpenLiveHistory: onOpenLiveHistory,
                ),
              ),
            ),
            if (accountLedger != null) SliverToBoxAdapter(child: accountLedger),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ActivityHeaderDelegate(
                height: tabHeight,
                child: KeyedSubtree(
                  key: const ValueKey<String>('traveler-activity-tabs'),
                  child: const FieldProfileActivityTabBar(
                    includeVisitLedger: true,
                  ),
                ),
              ),
            ),
          ],
          body: FieldProfileActivity(
            posts: posts,
            comments: comments,
            isLoading: isActivityLoading,
            errorMessage: activityErrorMessage,
            blockedMessage: blockedMessage,
            onRetry: onRetryActivity,
            onRefresh: onRefresh,
            onOpenPost: onOpenPost,
            includeVisitLedger: true,
            visitCountLabel: visitCount,
            onOpenVisitHistory: onOpenPlaceHistory,
            onRefreshVisits: onRefreshVisits,
            showTabBar: false,
          ),
        ),
      ),
    );
  }
}

class _ActivityHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ActivityHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ActivityHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
