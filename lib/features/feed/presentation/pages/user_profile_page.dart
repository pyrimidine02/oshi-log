/// EN: Community user profile page showing posts and comments.
/// KO: 게시글/댓글을 보여주는 커뮤니티 사용자 프로필 페이지.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/common/gbt_linkified_text.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_segmented_tab_bar.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../application/community_moderation_controller.dart';
import '../../application/user_follow_controller.dart';
import '../../application/user_follow_list_controller.dart';
import '../../application/user_activity_controller.dart';
import '../../domain/entities/community_moderation.dart';
import '../../domain/entities/feed_entities.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../titles/application/titles_controller.dart';
import '../../../titles/presentation/widgets/active_title_badge.dart';
import '../../../visits/application/visits_controller.dart';

/// EN: User profile page for community activity.
/// KO: 커뮤니티 활동 사용자 프로필 페이지.
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfileState = ref.watch(userProfileControllerProvider);
    final myProfile = myProfileState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final publicProfileState = userId == myProfile?.id
        ? const AsyncValue<UserProfile?>.data(null)
        : ref.watch(userProfileByIdProvider(userId));
    final activityState = ref.watch(userActivityControllerProvider(userId));

    final publicProfile = publicProfileState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final isMyProfile = myProfile?.id == userId;
    final profile = isMyProfile ? myProfile : publicProfile;
    final displayName =
        profile?.displayName ?? context.l10n(ko: '사용자', en: 'User', ja: 'ユーザー');
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final avatarUrl = profile?.avatarUrl;
    final hasAvatarImage = avatarUrl != null && avatarUrl.isNotEmpty;
    final coverUrl = profile?.coverImageUrl;
    final hasCoverImage = coverUrl != null && coverUrl.isNotEmpty;
    final bio = profile?.bio?.trim();
    final bioLabel = (bio != null && bio.isNotEmpty)
        ? bio
        : context.l10n(
            ko: '소개가 아직 없습니다.',
            en: 'No bio yet.',
            ja: '紹介はまだありません。',
          );
    final blockState = !isMyProfile && isAuthenticated
        ? ref.watch(blockStatusControllerProvider(userId))
        : const AsyncValue<BlockStatus>.loading();
    final blockStatus = blockState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final followState = !isMyProfile && isAuthenticated
        ? ref.watch(userFollowControllerProvider(userId))
        : const AsyncValue<UserFollowStatus>.loading();
    final followStatus = followState.maybeWhen(
      data: (status) => status,
      orElse: () => null,
    );
    final isFollowed = followState.maybeWhen(
      data: (status) => status.following,
      orElse: () => false,
    );
    final followersState = isAuthenticated
        ? ref.watch(userFollowersProvider(userId))
        : const AsyncValue<List<UserFollowSummary>>.data([]);
    final followingState = isAuthenticated
        ? ref.watch(userFollowingProvider(userId))
        : const AsyncValue<List<UserFollowSummary>>.data([]);
    final followerCountFromList = followersState.maybeWhen(
      data: (value) => value.length,
      orElse: () => null,
    );
    final followingCountFromList = followingState.maybeWhen(
      data: (value) => value.length,
      orElse: () => null,
    );
    final followerCount =
        followStatus?.targetFollowerCount ?? followerCountFromList;
    final followingCount =
        followStatus?.targetFollowingCount ?? followingCountFromList;
    final isBlockedProfile =
        blockStatus?.blockedByMe == true ||
        blockStatus?.blockedMe == true ||
        blockStatus?.blockedByAdmin == true;
    final isBlockActionBusy = blockStatus == null;
    final isFollowActionBusy = followState.isLoading;
    final canFollow = !isBlockedProfile && !isFollowActionBusy;
    final fanLevelProfile = isMyProfile
        ? ref.watch(fanLevelControllerProvider).valueOrNull
        : null;
    final userRanking = isMyProfile
        ? ref.watch(userRankingProvider).valueOrNull
        : null;
    final liveAttendanceHistory = isMyProfile
        ? ref.watch(liveAttendanceHistoryControllerProvider)
        : const LiveAttendanceHistoryViewState();

    final totalXp = profile?.totalXp ?? fanLevelProfile?.totalXp;
    final levelLabel = _buildLevelLabel(
      level: profile?.fanLevel,
      gradeLabel: profile?.fanGrade ?? fanLevelProfile?.grade.koLabel,
    );
    final uniquePlacesVisited =
        profile?.uniquePlacesVisited ?? userRanking?.uniquePlaces;
    final liveAttendanceCount =
        profile?.liveAttendanceCount ??
        (isMyProfile ? liveAttendanceHistory.items.length : null);
    final followLabel = isFollowed
        ? context.l10n(ko: '팔로우 취소', en: 'Unfollow', ja: 'フォロー解除')
        : context.l10n(ko: '팔로우', en: 'Follow', ja: 'フォロー');
    final blockLabel = blockStatus?.blockedByMe == true
        ? context.l10n(ko: '차단 해제', en: 'Unblock', ja: 'ブロック解除')
        : context.l10n(ko: '차단', en: 'Block', ja: 'ブロック');
    final actionVisualDensity = isAndroid
        ? VisualDensity.standard
        : VisualDensity.compact;
    final actionTapTargetSize = isAndroid
        ? MaterialTapTargetSize.padded
        : MaterialTapTargetSize.shrinkWrap;
    final editActionMinHeight = isAndroid ? 42.0 : 36.0;
    final relationshipActionMinHeight = isAndroid ? 40.0 : 32.0;
    Widget? headerAction;
    if (isMyProfile) {
      // EN: Inline watch — activeTitleProvider is needed for the title-picker
      //     query param only on own profile.
      // KO: 내 프로필에서만 필요한 칭호 선택 query param을 위해 인라인 watch.
      final activeTitleId = ref.watch(activeTitleProvider).valueOrNull?.titleId;
      // EN: Use mainAxisSize.min so the Row fits inside Positioned (no Expanded).
      // KO: Positioned 안에 들어가도록 mainAxisSize.min으로 Row를 사용합니다.
      headerAction = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => context.pushNamed(AppRoutes.profileEdit),
            style: OutlinedButton.styleFrom(
              visualDensity: actionVisualDensity,
              tapTargetSize: actionTapTargetSize,
              shape: const StadiumBorder(),
              minimumSize: Size(0, editActionMinHeight),
              padding: EdgeInsets.symmetric(
                horizontal: isAndroid ? GBTSpacing.md2 : GBTSpacing.md,
              ),
            ),
            child: Text(
              context.l10n(ko: '프로필 수정', en: 'Edit profile', ja: 'プロフィール編集'),
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.xs),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(
              AppRoutes.titlePicker,
              queryParameters: activeTitleId != null && activeTitleId.isNotEmpty
                  ? {'titleId': activeTitleId}
                  : {},
            ),
            style: OutlinedButton.styleFrom(
              visualDensity: actionVisualDensity,
              tapTargetSize: actionTapTargetSize,
              shape: const StadiumBorder(),
              minimumSize: Size(0, editActionMinHeight),
              padding: EdgeInsets.symmetric(
                horizontal: isAndroid ? GBTSpacing.md : GBTSpacing.sm,
              ),
            ),
            icon: const Icon(Icons.workspace_premium_rounded, size: 15),
            label: Text(
              context.l10n(ko: '칭호', en: 'Title', ja: '称号'),
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    } else if (isAuthenticated) {
      headerAction = Wrap(
        spacing: GBTSpacing.xs,
        runSpacing: GBTSpacing.xs,
        children: [
          FilledButton.tonal(
            onPressed: canFollow
                ? () async {
                    final result = await ref
                        .read(userFollowControllerProvider(userId).notifier)
                        .toggleFollow();
                    if (!context.mounted) return;
                    if (result is Success<bool>) {
                      _showSnackBar(
                        context,
                        result.data
                            ? context.l10n(
                                ko: '사용자를 팔로우했어요',
                                en: 'You followed this user',
                                ja: 'このユーザーをフォローしました',
                              )
                            : context.l10n(
                                ko: '팔로우를 취소했어요',
                                en: 'Unfollowed',
                                ja: 'フォローを解除しました',
                              ),
                      );
                    } else {
                      _showSnackBar(
                        context,
                        context.l10n(
                          ko: '팔로우 상태를 변경하지 못했어요',
                          en: 'Failed to update follow status',
                          ja: 'フォロー状態を変更できませんでした',
                        ),
                      );
                    }
                  }
                : null,
            style: FilledButton.styleFrom(
              visualDensity: actionVisualDensity,
              tapTargetSize: actionTapTargetSize,
              shape: const StadiumBorder(),
              minimumSize: Size(0, relationshipActionMinHeight),
              padding: EdgeInsets.symmetric(horizontal: isAndroid ? 14 : 12),
            ),
            child: Text(
              isBlockedProfile
                  ? context.l10n(ko: '차단됨', en: 'Blocked', ja: 'ブロック済み')
                  : followLabel,
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: isBlockActionBusy
                ? null
                : () async {
                    final result = await ref
                        .read(blockStatusControllerProvider(userId).notifier)
                        .toggleBlock();
                    if (result is Err<void> && context.mounted) {
                      _showSnackBar(
                        context,
                        context.l10n(
                          ko: '차단 상태를 변경하지 못했어요',
                          en: 'Failed to update block status',
                          ja: 'ブロック状態を変更できませんでした',
                        ),
                      );
                      return;
                    }
                    final updated = ref
                        .read(blockStatusControllerProvider(userId))
                        .maybeWhen(
                          data: (value) => value.blockedByMe,
                          orElse: () => false,
                        );
                    if (context.mounted) {
                      _showSnackBar(
                        context,
                        updated
                            ? context.l10n(
                                ko: '사용자를 차단했어요',
                                en: 'User blocked',
                                ja: 'ユーザーをブロックしました',
                              )
                            : context.l10n(
                                ko: '차단을 해제했어요',
                                en: 'User unblocked',
                                ja: 'ブロックを解除しました',
                              ),
                      );
                    }
                  },
            style: OutlinedButton.styleFrom(
              visualDensity: actionVisualDensity,
              tapTargetSize: actionTapTargetSize,
              shape: const StadiumBorder(),
              minimumSize: Size(0, relationshipActionMinHeight),
              padding: EdgeInsets.symmetric(horizontal: isAndroid ? 14 : 12),
            ),
            child: Text(
              blockLabel,
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    // EN: Fetch active title — own title from notifier, others' via FutureProvider.
    // KO: 활성 칭호 조회 — 내 칭호는 notifier에서, 타인 칭호는 FutureProvider로.
    final activeTitleItem = isMyProfile
        ? ref.watch(activeTitleProvider).valueOrNull
        : ref.watch(userActiveTitleProvider(userId)).valueOrNull;
    final activeTitleBadge = activeTitleItem?.hasTitle == true
        ? ActiveTitleBadge.fromActiveItem(activeTitleItem!)
        : null;

    // EN: Account info section — shown only on own profile.
    // KO: 계정정보 섹션 — 내 프로필에서만 표시합니다.
    Widget? accountInfoSection;
    if (isMyProfile && myProfile != null) {
      accountInfoSection = _AccountInfoSection(profile: myProfile);
    }

    // EN: Activity stats list — profile counts used directly (activity counts
    //     are reflected in the visible post/comment items in tabs).
    // KO: 활동 통계 — 탭에서 실제 아이템이 표시되므로 프로필 카운트를 직접 사용합니다.
    final activityStats = [
      _HeaderActivityStat(
        icon: Icons.auto_graph_rounded,
        label: context.l10n(ko: 'XP', en: 'XP', ja: 'XP'),
        value: _formatCountValue(totalXp),
      ),
      _HeaderActivityStat(
        icon: Icons.bolt_rounded,
        label: context.l10n(ko: '레벨', en: 'Level', ja: 'レベル'),
        value: levelLabel,
      ),
      _HeaderActivityStat(
        icon: Icons.place_outlined,
        label: context.l10n(ko: '성지 방문', en: 'Place visits', ja: '聖地訪問'),
        value: _formatCountValue(uniquePlacesVisited),
      ),
      _HeaderActivityStat(
        icon: Icons.festival_outlined,
        label: context.l10n(ko: '라이브 방문', en: 'Live visits', ja: 'ライブ参加'),
        value: _formatCountValue(liveAttendanceCount),
      ),
      _HeaderActivityStat(
        icon: Icons.article_outlined,
        label: context.l10n(ko: '작성 글', en: 'Posts', ja: '投稿'),
        value: _formatCountValue(profile?.postCount),
      ),
      _HeaderActivityStat(
        icon: Icons.mode_comment_outlined,
        label: context.l10n(ko: '작성 댓글', en: 'Comments', ja: 'コメント'),
        value: _formatCountValue(profile?.commentCount),
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (innerContext, innerBoxIsScrolled) {
            final isDark = Theme.of(innerContext).brightness == Brightness.dark;
            final isAndroidHeader =
                Theme.of(innerContext).platform == TargetPlatform.android;
            return [
              // EN: Immersive SliverAppBar with parallax cover image.
              // KO: 패럴랙스 커버 이미지를 가진 몰입형 SliverAppBar.
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(
                    left: GBTSpacing.sm,
                    top: GBTSpacing.xs,
                    bottom: GBTSpacing.xs,
                  ),
                  child: isAndroidHeader
                      ? Material(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.52)
                              : Colors.white.withValues(alpha: 0.8),
                          shape: const CircleBorder(),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.22),
                          child: IconButton(
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.padded,
                              minimumSize: const Size.square(44),
                            ),
                            onPressed: () =>
                                Navigator.of(innerContext).maybePop(),
                            tooltip: MaterialLocalizations.of(
                              innerContext,
                            ).backButtonTooltip,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: isDark
                                ? Colors.white
                                : GBTColors.textPrimary,
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.44 : 0.3,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                Navigator.of(innerContext).maybePop(),
                            tooltip: MaterialLocalizations.of(
                              innerContext,
                            ).backButtonTooltip,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: Colors.white,
                          ),
                        ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      hasCoverImage
                          ? Semantics(
                              label: context.l10n(
                                ko: '프로필 배경 이미지',
                                en: 'Profile cover image',
                                ja: 'プロフィール背景画像',
                              ),
                              hint: context.l10n(
                                ko: '탭하면 확대해서 봅니다',
                                en: 'Tap to zoom',
                                ja: 'タップして拡大表示',
                              ),
                              button: true,
                              child: GestureDetector(
                                onTap: () => _showProfileImageViewer(
                                  context,
                                  imageUrl: coverUrl,
                                  semanticLabel: context.l10n(
                                    ko: '프로필 배경 이미지',
                                    en: 'Profile cover image',
                                    ja: 'プロフィール背景画像',
                                  ),
                                ),
                                child: GBTImage(
                                  imageUrl: coverUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                  semanticLabel: context.l10n(
                                    ko: '프로필 배경 이미지',
                                    en: 'Profile cover image',
                                    ja: 'プロフィール背景画像',
                                  ),
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: isDark
                                  ? GBTColors.darkSurfaceVariant
                                  : GBTColors.surfaceVariant,
                            ),
                      // EN: Bottom gradient for readability on cover.
                      // KO: 커버 위 가독성을 위한 하단 그라디언트.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      // EN: Surface transition band makes avatar appear
                      //     half on cover and half on content.
                      // KO: 표면 전환 밴드로 아바타가 커버/본문에 반씩 걸쳐
                      //     보이도록 처리합니다.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          height:
                              (_NewProfileInfoSection._kAvatarTotal / 2) +
                              GBTSpacing.sm,
                          child: ColoredBox(
                            color: isDark
                                ? GBTColors.darkSurface
                                : GBTColors.surface,
                          ),
                        ),
                      ),
                      Positioned(
                        left: GBTSpacing.pageHorizontal,
                        bottom:
                            ((_NewProfileInfoSection._kAvatarTotal / 2) +
                                GBTSpacing.sm) -
                            (_NewProfileInfoSection._kAvatarTotal / 2),
                        child: _ProfileAvatar(
                          url: avatarUrl,
                          radius:
                              _NewProfileInfoSection._kAvatarRadius +
                              _NewProfileInfoSection._kAvatarBorder,
                          onTap: hasAvatarImage
                              ? () => _showProfileImageViewer(
                                  context,
                                  imageUrl: avatarUrl,
                                  semanticLabel: context.l10n(
                                    ko: '프로필 사진',
                                    en: 'Profile image',
                                    ja: 'プロフィール画像',
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (headerAction != null)
                        Positioned(
                          left:
                              GBTSpacing.pageHorizontal +
                              _NewProfileInfoSection._kAvatarTotal +
                              GBTSpacing.sm,
                          right: GBTSpacing.pageHorizontal,
                          bottom: 0,
                          child: SizedBox(
                            height:
                                (_NewProfileInfoSection._kAvatarTotal / 2) +
                                GBTSpacing.sm,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: headerAction,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // EN: Profile info section rendered below the cover header.
              // KO: 커버 헤더 아래에 렌더링되는 프로필 정보 섹션입니다.
              SliverToBoxAdapter(
                child: _NewProfileInfoSection(
                  displayName: displayName,
                  bioLabel: bioLabel,
                  activityStats: activityStats,
                  onOpenFollowers: () => context.goToUserFollowers(userId),
                  onOpenFollowing: () => context.goToUserFollowing(userId),
                  summaryLabel: profile?.summaryLabel,
                  followerCount: followerCount,
                  followingCount: followingCount,
                  onOpenFanLevel: isMyProfile
                      ? () => context.push('/fan-level')
                      : null,
                  onOpenVisitHistory: isMyProfile
                      ? () => context.goToVisitHistory()
                      : null,
                  onOpenLiveAttendanceHistory: isMyProfile
                      ? () => context.goToVisitHistory(showLiveTab: true)
                      : null,
                  activeTitleBadge: activeTitleBadge,
                  accountInfoSection: accountInfoSection,
                ),
              ),
              // EN: Sticky tab bar pinned below profile info.
              // KO: 프로필 정보 아래 고정되는 스티키 탭바.
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  tabBar: GBTSegmentedTabBar(
                    height: 44,
                    margin: const EdgeInsets.symmetric(
                      horizontal: GBTSpacing.md2,
                    ),
                    tabs: [
                      Tab(
                        text: context.l10n(ko: '작성한 글', en: 'Posts', ja: '投稿'),
                      ),
                      Tab(
                        text: context.l10n(
                          ko: '작성한 댓글',
                          en: 'Comments',
                          ja: 'コメント',
                        ),
                      ),
                    ],
                  ),
                  isDark: isDark,
                  isAndroid: isAndroidHeader,
                ),
              ),
            ];
          },
          body: isBlockedProfile && !isMyProfile
              ? TabBarView(
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _BlockedProfileState(
                          blockedByMe: blockStatus?.blockedByMe == true,
                          blockedMe: blockStatus?.blockedMe == true,
                          blockedByAdmin: blockStatus?.blockedByAdmin == true,
                        ),
                      ],
                    ),
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _BlockedProfileState(
                          blockedByMe: blockStatus?.blockedByMe == true,
                          blockedMe: blockStatus?.blockedMe == true,
                          blockedByAdmin: blockStatus?.blockedByAdmin == true,
                        ),
                      ],
                    ),
                  ],
                )
              : activityState.when(
                  loading: () => TabBarView(
                    children: [
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: GBTSpacing.paddingPage,
                            child: GBTLoading(
                              message: context.l10n(
                                ko: '활동을 불러오는 중...',
                                en: 'Loading activity...',
                                ja: 'アクティビティを読み込み中...',
                              ),
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: GBTSpacing.paddingPage,
                            child: GBTLoading(
                              message: context.l10n(
                                ko: '활동을 불러오는 중...',
                                en: 'Loading activity...',
                                ja: 'アクティビティを読み込み中...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, _) {
                    final message = error is Failure
                        ? error.userMessage
                        : context.l10n(
                            ko: '활동을 불러오지 못했어요',
                            en: 'Failed to load activity',
                            ja: 'アクティビティを読み込めませんでした',
                          );
                    return TabBarView(
                      children: [
                        ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: GBTSpacing.paddingPage,
                              child: GBTErrorState(
                                message: message,
                                onRetry: () => ref
                                    .read(
                                      userActivityControllerProvider(
                                        userId,
                                      ).notifier,
                                    )
                                    .load(forceRefresh: true),
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: GBTSpacing.paddingPage,
                              child: GBTErrorState(
                                message: message,
                                onRetry: () => ref
                                    .read(
                                      userActivityControllerProvider(
                                        userId,
                                      ).notifier,
                                    )
                                    .load(forceRefresh: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  data: (activity) => TabBarView(
                    children: [
                      _PostsTab(
                        posts: activity.posts,
                        onRefresh: () => ref
                            .read(
                              userActivityControllerProvider(userId).notifier,
                            )
                            .load(forceRefresh: true),
                      ),
                      _CommentsTab(
                        comments: activity.comments,
                        onRefresh: () => ref
                            .read(
                              userActivityControllerProvider(userId).notifier,
                            )
                            .load(forceRefresh: true),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _BlockedProfileState extends StatelessWidget {
  const _BlockedProfileState({
    required this.blockedByMe,
    required this.blockedMe,
    required this.blockedByAdmin,
  });

  final bool blockedByMe;
  final bool blockedMe;
  final bool blockedByAdmin;

  @override
  Widget build(BuildContext context) {
    final message = blockedByAdmin
        ? context.l10n(
            ko: '관리자 정책으로 이 사용자의 활동을 볼 수 없습니다.',
            en: 'You cannot view this user due to admin policy.',
            ja: '管理者ポリシーによりこのユーザーの活動を表示できません。',
          )
        : blockedByMe
        ? context.l10n(
            ko: '차단한 사용자의 활동은 숨겨집니다.',
            en: 'Blocked user activity is hidden.',
            ja: 'ブロックしたユーザーの活動は非表示です。',
          )
        : blockedMe
        ? context.l10n(
            ko: '이 사용자가 나를 차단해 활동을 볼 수 없습니다.',
            en: 'This user blocked you, activity is unavailable.',
            ja: 'このユーザーにブロックされているため活動を表示できません。',
          )
        : context.l10n(
            ko: '활동을 표시할 수 없습니다.',
            en: 'Cannot display activity.',
            ja: '活動を表示できません。',
          );

    return Center(
      child: Padding(
        padding: GBTSpacing.paddingPage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 40),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              message,
              style: GBTTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// EN: Profile avatar widget with dark-mode-aware placeholder.
/// KO: 다크 모드 인식 플레이스홀더를 가진 프로필 아바타 위젯.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, this.radius = 28, this.onTap});

  final String? url;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // EN: Use theme-aware placeholder colors.
    // KO: 테마 인식 플레이스홀더 색상을 사용합니다.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: isDark
            ? GBTColors.darkSurfaceVariant
            : GBTColors.surfaceVariant,
        child: Icon(
          Icons.person,
          color: isDark ? GBTColors.darkTextTertiary : GBTColors.textTertiary,
          size: radius,
        ),
      );
    }

    final avatar = ClipOval(
      child: GBTImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        semanticLabel: context.l10n(
          ko: '프로필 사진',
          en: 'Profile image',
          ja: 'プロフィール画像',
        ),
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return Semantics(
      hint: context.l10n(
        ko: '탭하면 확대해서 봅니다',
        en: 'Tap to zoom',
        ja: 'タップして拡大表示',
      ),
      button: true,
      child: GestureDetector(onTap: onTap, child: avatar),
    );
  }
}

// ===========================================================================
// EN: Sticky tab bar delegate for NestedScrollView.
// KO: NestedScrollView용 스티키 탭바 델리게이트.
// ===========================================================================

/// EN: SliverPersistentHeader delegate that pins the tab bar.
/// KO: 탭바를 고정하는 SliverPersistentHeader 델리게이트.
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate({
    required this.tabBar,
    required this.isDark,
    required this.isAndroid,
  });

  final Widget tabBar;
  final bool isDark;
  final bool isAndroid;

  static const double _kHeight = 44.0 + 1.0; // tab bar + divider

  @override
  double get minExtent => _kHeight;

  @override
  double get maxExtent => _kHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (!isAndroid) {
      return ColoredBox(
        color: isDark ? GBTColors.darkSurface : GBTColors.surface,
        child: Column(children: [tabBar, const Divider(height: 1)]),
      );
    }

    return Material(
      color: isDark ? GBTColors.darkSurface : GBTColors.surface,
      surfaceTintColor: isDark
          ? GBTColors.darkPrimary.withValues(alpha: 0.08)
          : GBTColors.primary.withValues(alpha: 0.08),
      elevation: overlapsContent ? 2 : 0,
      child: Column(children: [tabBar, const Divider(height: 1)]),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.isAndroid != isAndroid ||
      oldDelegate.tabBar != tabBar;
}

// ===========================================================================
// EN: Profile info section shown in SliverToBoxAdapter.
// KO: SliverToBoxAdapter에 표시되는 프로필 정보 섹션.
// ===========================================================================

/// EN: Profile info card with overlapping avatar, bio, stats, and CTA.
/// KO: 오버랩 아바타, 소개, 통계, CTA를 포함하는 프로필 정보 카드.
class _NewProfileInfoSection extends StatelessWidget {
  const _NewProfileInfoSection({
    required this.displayName,
    required this.bioLabel,
    required this.activityStats,
    required this.onOpenFollowers,
    required this.onOpenFollowing,
    this.summaryLabel,
    this.followerCount,
    this.followingCount,
    this.onOpenFanLevel,
    this.onOpenVisitHistory,
    this.onOpenLiveAttendanceHistory,
    this.activeTitleBadge,
    this.accountInfoSection,
  });

  final String displayName;
  final String bioLabel;
  final String? summaryLabel;
  final int? followerCount;
  final int? followingCount;
  final VoidCallback onOpenFollowers;
  final VoidCallback onOpenFollowing;
  final List<_HeaderActivityStat> activityStats;
  final VoidCallback? onOpenFanLevel;
  final VoidCallback? onOpenVisitHistory;
  final VoidCallback? onOpenLiveAttendanceHistory;

  /// EN: Active title badge shown below the display name.
  /// KO: 표시 이름 아래에 표시되는 활성 칭호 배지.
  final Widget? activeTitleBadge;

  /// EN: Account info section shown only on own profile.
  /// KO: 내 프로필에서만 표시되는 계정정보 섹션.
  final Widget? accountInfoSection;

  // EN: Layout constants for avatar overlap design.
  // KO: 아바타 오버랩 디자인을 위한 레이아웃 상수.
  static const double _kAvatarRadius = 48.0;
  static const double _kAvatarBorder = 4.0;

  // EN: Total avatar widget diameter including border.
  // KO: 테두리를 포함한 전체 아바타 위젯 지름.
  static const double _kAvatarTotal = (_kAvatarRadius + _kAvatarBorder) * 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final surfaceColor = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Semantics(
      label:
          '${context.l10n(ko: "프로필", en: "Profile", ja: "プロフィール")}: $displayName. $bioLabel',
      child: ColoredBox(
        color: surfaceColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // EN: Keep top spacing compact so profile info starts right below avatar.
              // KO: 프로필 정보가 아바타 바로 아래에서 시작되도록 상단 간격을 최소화합니다.
              SizedBox(height: isAndroid ? GBTSpacing.sm : GBTSpacing.xs),
              // EN: Display name row with inline active title badge.
              // KO: 표시 이름 행에 활성 칭호 배지를 인라인으로 함께 배치합니다.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: GBTTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeTitleBadge != null) ...[
                    const SizedBox(width: GBTSpacing.xs),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: activeTitleBadge!,
                      ),
                    ),
                  ],
                ],
              ),
              if (summaryLabel != null && summaryLabel!.trim().isNotEmpty) ...[
                SizedBox(height: isAndroid ? GBTSpacing.sm : GBTSpacing.xs),
                Text(
                  summaryLabel!,
                  style:
                      (isAndroid
                              ? GBTTypography.labelMedium
                              : GBTTypography.labelSmall)
                          .copyWith(color: tertiaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: isAndroid ? GBTSpacing.md : GBTSpacing.sm),
              // EN: Bio text — secondary color, up to 4 lines.
              // KO: 소개 텍스트 — 보조 색상, 최대 4줄.
              GBTLinkifiedText(
                bioLabel,
                style:
                    (isAndroid
                            ? GBTTypography.bodyMedium
                            : GBTTypography.bodySmall)
                        .copyWith(color: secondaryColor, height: 1.55),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isAndroid ? GBTSpacing.md2 : GBTSpacing.md),
              // EN: Follower / following inline row (Twitter-style).
              // KO: 팔로워 / 팔로잉 인라인 행 (Twitter 스타일).
              _ProfileFollowerRow(
                followerCount: followerCount,
                followingCount: followingCount,
                onTapFollowers: onOpenFollowers,
                onTapFollowing: onOpenFollowing,
              ),
              SizedBox(height: isAndroid ? GBTSpacing.md2 : GBTSpacing.md),
              // EN: Activity section label.
              // KO: 활동 섹션 레이블.
              Text(
                context.l10n(ko: '활동 통계', en: 'Activity', ja: '活動統計'),
                style:
                    (isAndroid
                            ? GBTTypography.labelMedium
                            : GBTTypography.labelSmall)
                        .copyWith(
                          color: tertiaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
              ),
              SizedBox(height: isAndroid ? GBTSpacing.sm : GBTSpacing.xs),
              // EN: Re-designed activity stats panel.
              // KO: 재디자인된 활동 통계 패널.
              _ActivityStatsGrid(stats: activityStats),
              if (onOpenFanLevel != null ||
                  onOpenVisitHistory != null ||
                  onOpenLiveAttendanceHistory != null) ...[
                SizedBox(height: isAndroid ? GBTSpacing.md : GBTSpacing.sm),
                _ProfileShortcutGrid(
                  items: [
                    if (onOpenFanLevel != null)
                      _ProfileShortcutItem(
                        icon: Icons.bolt_outlined,
                        label: context.l10n(
                          ko: '덕력',
                          en: 'Fan level',
                          ja: 'ファンレベル',
                        ),
                        onTap: onOpenFanLevel!,
                        paletteIndex: 0,
                      ),
                    if (onOpenVisitHistory != null)
                      _ProfileShortcutItem(
                        icon: Icons.map_outlined,
                        label: context.l10n(
                          ko: '성지 기록',
                          en: 'Place history',
                          ja: '聖地履歴',
                        ),
                        onTap: onOpenVisitHistory!,
                        paletteIndex: 2,
                      ),
                    if (onOpenLiveAttendanceHistory != null)
                      _ProfileShortcutItem(
                        icon: Icons.festival_outlined,
                        label: context.l10n(
                          ko: '라이브 기록',
                          en: 'Live history',
                          ja: 'ライブ履歴',
                        ),
                        onTap: onOpenLiveAttendanceHistory!,
                        paletteIndex: 3,
                      ),
                  ],
                ),
              ],
              if (accountInfoSection != null) ...[
                SizedBox(height: isAndroid ? GBTSpacing.md2 : GBTSpacing.md),
                accountInfoSection!,
              ],
              SizedBox(height: isAndroid ? GBTSpacing.md2 : GBTSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// EN: Profile header helper data class.
// KO: 프로필 헤더 헬퍼 데이터 클래스.
// ===========================================================================

/// EN: Activity stat data model for the profile stats grid.
/// KO: 프로필 통계 그리드용 활동 통계 데이터 모델.
class _HeaderActivityStat {
  const _HeaderActivityStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

// ===========================================================================
// EN: Followers / following inline row.
// KO: 팔로워 / 팔로잉 인라인 행.
// ===========================================================================

/// EN: Twitter-style inline follower and following count row.
/// KO: Twitter 스타일의 팔로워·팔로잉 수 인라인 행.
class _ProfileFollowerRow extends StatelessWidget {
  const _ProfileFollowerRow({
    required this.followerCount,
    required this.followingCount,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  final int? followerCount;
  final int? followingCount;
  final VoidCallback onTapFollowers;
  final VoidCallback onTapFollowing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final primaryColor = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;

    Widget item(String count, String label, VoidCallback onTap) {
      final text = Text.rich(
        TextSpan(
          children: [
            TextSpan(
              // EN: statNumber applies tabular figures so follower/following
              // counts don't visually jitter as digits change.
              // KO: statNumber는 고정폭 숫자를 적용해 팔로워/팔로잉 수의
              // 자릿수가 바뀌어도 시각적으로 흔들리지 않도록 합니다.
              text: count,
              style: GBTTypography.statNumber.copyWith(
                fontSize: 14,
                height: 1.0,
                color: primaryColor,
              ),
            ),
            TextSpan(
              text: ' $label',
              style: GBTTypography.bodySmall.copyWith(color: secondaryColor),
            ),
          ],
        ),
      );

      if (!isAndroid) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
            child: text,
          ),
        );
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.xs,
              vertical: GBTSpacing.xs,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Align(alignment: Alignment.centerLeft, child: text),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(
          followerCount == null ? '-' : '$followerCount',
          context.l10n(ko: '팔로워', en: 'followers', ja: 'フォロワー'),
          onTapFollowers,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.sm),
          child: Text(
            '·',
            style: GBTTypography.bodySmall.copyWith(color: secondaryColor),
          ),
        ),
        item(
          followingCount == null ? '-' : '$followingCount',
          context.l10n(ko: '팔로잉', en: 'following', ja: 'フォロー中'),
          onTapFollowing,
        ),
      ],
    );
  }
}

// ===========================================================================
// EN: Activity stats redesigned panel.
// KO: 활동 통계 리디자인 패널.
// ===========================================================================

/// EN: Displays activity stats in a responsive 2-column card panel.
/// KO: 활동 통계를 반응형 2열 카드 패널로 표시합니다.
class _ActivityStatsGrid extends StatelessWidget {
  const _ActivityStatsGrid({required this.stats});

  final List<_HeaderActivityStat> stats;

  static const int _columns = 2;
  static const double _gap = GBTSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = _gap * (_columns - 1);
        final cellWidth = (constraints.maxWidth - totalGap) / _columns;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < stats.length; i++)
              SizedBox(
                width: cellWidth,
                child: _StatGridCell(stat: stats[i], isDark: isDark, index: i),
              ),
          ],
        );
      },
    );
  }
}

/// EN: Single cell in the activity stats grid.
/// KO: 활동 통계 그리드의 단일 셀.
class _StatGridCell extends StatelessWidget {
  const _StatGridCell({
    required this.stat,
    required this.isDark,
    required this.index,
  });

  final _HeaderActivityStat stat;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = _StatCardPalette.fromIndex(index: index, isDark: isDark);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final cardRadius = BorderRadius.circular(GBTSpacing.radiusLg);
    final cardDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.backgroundStart, palette.backgroundEnd],
      ),
      borderRadius: cardRadius,
      border: Border.all(color: palette.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final cardBody = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm2,
        vertical: GBTSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withValues(alpha: isDark ? 0.24 : 0.14),
              border: Border.all(
                color: palette.accent.withValues(alpha: isDark ? 0.4 : 0.26),
              ),
            ),
            child: Icon(stat.icon, size: 18, color: palette.accent),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.label,
                  style: GBTTypography.labelSmall.copyWith(
                    color: palette.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.value,
                  // EN: statNumber gives tabular figures so digits align
                  // across the stat grid cells.
                  // KO: statNumber는 고정폭 숫자를 적용해 통계 그리드 셀
                  // 전반에서 자릿수가 정렬되도록 합니다.
                  style: GBTTypography.statNumber.copyWith(
                    fontSize: 18,
                    color: palette.value,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isAndroid) {
      return Container(decoration: cardDecoration, child: cardBody);
    }

    return Material(
      color: Colors.transparent,
      child: Ink(decoration: cardDecoration, child: cardBody),
    );
  }
}

/// EN: Color palette set for the redesigned activity stat cards.
/// KO: 리디자인된 활동 통계 카드용 컬러 팔레트 세트입니다.
class _StatCardPalette {
  const _StatCardPalette({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.border,
    required this.accent,
    required this.label,
    required this.value,
  });

  final Color backgroundStart;
  final Color backgroundEnd;
  final Color border;
  final Color accent;
  final Color label;
  final Color value;

  static _StatCardPalette fromIndex({
    required int index,
    required bool isDark,
  }) {
    final normalized = index % 6;
    if (isDark) {
      switch (normalized) {
        case 0:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF1A2433),
            backgroundEnd: Color(0xFF14202E),
            border: Color(0xFF2C4A6A),
            accent: Color(0xFF6CB7FF),
            label: Color(0xFF9AB2CC),
            value: Color(0xFFEAF3FF),
          );
        case 1:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF1B2731),
            backgroundEnd: Color(0xFF14212A),
            border: Color(0xFF2C5A63),
            accent: Color(0xFF64D7C6),
            label: Color(0xFF9EC1BE),
            value: Color(0xFFE9FFF9),
          );
        case 2:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF2D241A),
            backgroundEnd: Color(0xFF231C14),
            border: Color(0xFF6B4F2A),
            accent: Color(0xFFFFC46B),
            label: Color(0xFFD0B389),
            value: Color(0xFFFFF2DE),
          );
        case 3:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF1F2B1C),
            backgroundEnd: Color(0xFF182218),
            border: Color(0xFF40653A),
            accent: Color(0xFF91D676),
            label: Color(0xFFB4CFA9),
            value: Color(0xFFF1FFE9),
          );
        case 4:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF2D2027),
            backgroundEnd: Color(0xFF231920),
            border: Color(0xFF6D3A55),
            accent: Color(0xFFFF7FAE),
            label: Color(0xFFD8AEC0),
            value: Color(0xFFFFE9F2),
          );
        default:
          return const _StatCardPalette(
            backgroundStart: Color(0xFF23243A),
            backgroundEnd: Color(0xFF1A1B2C),
            border: Color(0xFF4A4F7A),
            accent: Color(0xFF9EA6FF),
            label: Color(0xFFB8BCDA),
            value: Color(0xFFF1F3FF),
          );
      }
    }

    switch (normalized) {
      case 0:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFF2F8FF),
          backgroundEnd: Color(0xFFE4F0FF),
          border: Color(0xFFBAD8FF),
          accent: Color(0xFF2B79D4),
          label: Color(0xFF4A6D96),
          value: Color(0xFF173B61),
        );
      case 1:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFF0FBF8),
          backgroundEnd: Color(0xFFE1F5EE),
          border: Color(0xFFB9E6D8),
          accent: Color(0xFF1D9A86),
          label: Color(0xFF4A8278),
          value: Color(0xFF125248),
        );
      case 2:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFFFF8EE),
          backgroundEnd: Color(0xFFFFF0D9),
          border: Color(0xFFF3D5A2),
          accent: Color(0xFFBE7A11),
          label: Color(0xFF8A6A3C),
          value: Color(0xFF5E4319),
        );
      case 3:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFF3FAEF),
          backgroundEnd: Color(0xFFE5F5DC),
          border: Color(0xFFC7E6B3),
          accent: Color(0xFF4A9D33),
          label: Color(0xFF5D8560),
          value: Color(0xFF244B22),
        );
      case 4:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFFFF2F7),
          backgroundEnd: Color(0xFFFFE3EE),
          border: Color(0xFFF2BFD2),
          accent: Color(0xFFBE3D73),
          label: Color(0xFF8F5673),
          value: Color(0xFF612340),
        );
      default:
        return const _StatCardPalette(
          backgroundStart: Color(0xFFF2F4FF),
          backgroundEnd: Color(0xFFE4E8FF),
          border: Color(0xFFBDC7F4),
          accent: Color(0xFF4D58C7),
          label: Color(0xFF616AA6),
          value: Color(0xFF2B326C),
        );
    }
  }
}

/// EN: Data model for profile shortcut actions.
/// KO: 프로필 숏컷 액션 데이터 모델입니다.
class _ProfileShortcutItem {
  const _ProfileShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.paletteIndex,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int paletteIndex;
}

/// EN: Responsive shortcut cards aligned with stats/list card design.
/// KO: 활동 통계/목록 카드 디자인과 통일된 반응형 숏컷 카드 그리드입니다.
class _ProfileShortcutGrid extends StatelessWidget {
  const _ProfileShortcutGrid({required this.items});

  final List<_ProfileShortcutItem> items;

  static const double _gap = GBTSpacing.xs;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = items.length >= 3 ? 3 : items.length;
        final totalGap = _gap * (columns - 1);
        final cellWidth = (constraints.maxWidth - totalGap) / columns;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cellWidth,
                child: _ProfileShortcutChip(
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  paletteIndex: item.paletteIndex,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileShortcutChip extends StatelessWidget {
  const _ProfileShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.paletteIndex,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int paletteIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final palette = _StatCardPalette.fromIndex(
      index: paletteIndex,
      isDark: isDark,
    );
    final borderRadius = BorderRadius.circular(GBTSpacing.radiusMd);
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.backgroundStart, palette.backgroundEnd],
      ),
      borderRadius: borderRadius,
      border: Border.all(color: palette.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.sm,
              vertical: GBTSpacing.xs,
            ),
            decoration: decoration,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.accent.withValues(
                      alpha: isDark ? 0.24 : 0.14,
                    ),
                    border: Border.all(
                      color: palette.accent.withValues(
                        alpha: isDark ? 0.4 : 0.26,
                      ),
                    ),
                  ),
                  child: Icon(icon, size: 14, color: palette.accent),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style:
                        (isAndroid
                                ? GBTTypography.labelMedium
                                : GBTTypography.labelSmall)
                            .copyWith(
                              color: palette.value,
                              fontWeight: FontWeight.w700,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// EN: Posts tab showing user's authored posts.
/// KO: 사용자가 작성한 게시글을 보여주는 탭.
class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts, required this.onRefresh});

  final List<PostSummary> posts;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final cardGap = isAndroid ? GBTSpacing.md : GBTSpacing.sm;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (posts.isEmpty) ...[
            const SizedBox(height: 80),
            GBTEmptyState(
              icon: Icons.article_outlined,
              title: context.l10n(
                ko: '작성한 글이 없습니다',
                en: 'No posts yet',
                ja: '投稿がありません',
              ),
            ),
          ] else
            Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < posts.length; i++) ...[
                    if (i > 0) SizedBox(height: cardGap),
                    Builder(
                      builder: (context) {
                        final post = posts[i];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final isAndroidCard =
                            Theme.of(context).platform ==
                            TargetPlatform.android;
                        final palette = _StatCardPalette.fromIndex(
                          index: i,
                          isDark: isDark,
                        );
                        final body = post.content?.trim();
                        final cardRadius = BorderRadius.circular(
                          GBTSpacing.radiusLg,
                        );
                        final cardDecoration = BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.backgroundStart,
                              palette.backgroundEnd,
                            ],
                          ),
                          borderRadius: cardRadius,
                          border: Border.all(color: palette.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.24 : 0.07,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        );

                        return InkWell(
                          borderRadius: cardRadius,
                          onTap: () {
                            context.goToPostDetail(
                              post.id,
                              projectCode: post.projectId,
                            );
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(GBTSpacing.sm2),
                            decoration: cardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: palette.accent.withValues(
                                          alpha: isDark ? 0.24 : 0.14,
                                        ),
                                        border: Border.all(
                                          color: palette.accent.withValues(
                                            alpha: isDark ? 0.42 : 0.28,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.article_outlined,
                                        size: 16,
                                        color: palette.accent,
                                      ),
                                    ),
                                    const SizedBox(width: GBTSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        context.l10n(
                                          ko: '작성 글',
                                          en: 'Post',
                                          ja: '投稿',
                                        ),
                                        style: GBTTypography.labelSmall
                                            .copyWith(
                                              color: palette.label,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isAndroidCard
                                                  ? 12
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: palette.accent.withValues(
                                        alpha: isDark ? 0.82 : 0.72,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: GBTSpacing.sm),
                                Text(
                                  post.title,
                                  style: GBTTypography.titleSmall.copyWith(
                                    color: palette.value,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (body != null && body.isNotEmpty) ...[
                                  const SizedBox(height: GBTSpacing.xs),
                                  GBTLinkifiedText(
                                    body,
                                    style: GBTTypography.bodySmall.copyWith(
                                      color: palette.label,
                                      height: 1.45,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: GBTSpacing.sm),
                                Text(
                                  post.timeAgoLabel,
                                  style:
                                      (isAndroidCard
                                              ? GBTTypography.labelMedium
                                              : GBTTypography.labelSmall)
                                          .copyWith(
                                            color: palette.label,
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

/// EN: Comments tab showing user's authored comments.
/// KO: 사용자가 작성한 댓글을 보여주는 탭.
class _CommentsTab extends StatelessWidget {
  const _CommentsTab({required this.comments, required this.onRefresh});

  final List<PostComment> comments;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final cardGap = isAndroid ? GBTSpacing.md : GBTSpacing.sm;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (comments.isEmpty) ...[
            const SizedBox(height: 80),
            GBTEmptyState(
              icon: Icons.mode_comment_outlined,
              title: context.l10n(
                ko: '작성한 댓글이 없습니다',
                en: 'No comments yet',
                ja: 'コメントがありません',
              ),
            ),
          ] else
            Padding(
              padding: GBTSpacing.paddingPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < comments.length; i++) ...[
                    if (i > 0) SizedBox(height: cardGap),
                    Builder(
                      builder: (context) {
                        final comment = comments[i];
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final isAndroidCard =
                            Theme.of(context).platform ==
                            TargetPlatform.android;
                        final palette = _StatCardPalette.fromIndex(
                          index: i + 3,
                          isDark: isDark,
                        );
                        final cardRadius = BorderRadius.circular(
                          GBTSpacing.radiusLg,
                        );
                        final cardDecoration = BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.backgroundStart,
                              palette.backgroundEnd,
                            ],
                          ),
                          borderRadius: cardRadius,
                          border: Border.all(color: palette.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.24 : 0.07,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        );

                        return InkWell(
                          borderRadius: cardRadius,
                          onTap: () {
                            context.goToPostDetail(
                              comment.postId,
                              projectCode: comment.projectId,
                            );
                          },
                          child: Ink(
                            padding: const EdgeInsets.all(GBTSpacing.sm2),
                            decoration: cardDecoration,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: palette.accent.withValues(
                                          alpha: isDark ? 0.24 : 0.14,
                                        ),
                                        border: Border.all(
                                          color: palette.accent.withValues(
                                            alpha: isDark ? 0.42 : 0.28,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 15,
                                        color: palette.accent,
                                      ),
                                    ),
                                    const SizedBox(width: GBTSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        context.l10n(
                                          ko: '작성 댓글',
                                          en: 'Comment',
                                          ja: 'コメント',
                                        ),
                                        style: GBTTypography.labelSmall
                                            .copyWith(
                                              color: palette.label,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isAndroidCard
                                                  ? 12
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: palette.accent.withValues(
                                        alpha: isDark ? 0.82 : 0.72,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: GBTSpacing.sm),
                                GBTLinkifiedText(
                                  comment.content,
                                  style: GBTTypography.bodyMedium.copyWith(
                                    color: palette.value,
                                    height: 1.45,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: GBTSpacing.sm),
                                Text(
                                  comment.timeAgoLabel,
                                  style:
                                      (isAndroidCard
                                              ? GBTTypography.labelMedium
                                              : GBTTypography.labelSmall)
                                          .copyWith(
                                            color: palette.label,
                                            fontWeight: FontWeight.w600,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

String _formatCountValue(int? value) => value == null ? '-' : '$value';

String _buildLevelLabel({int? level, String? gradeLabel}) {
  final normalizedGrade = gradeLabel?.trim();
  if (level != null && normalizedGrade != null && normalizedGrade.isNotEmpty) {
    return 'Lv.$level · $normalizedGrade';
  }
  if (level != null) {
    return 'Lv.$level';
  }
  if (normalizedGrade != null && normalizedGrade.isNotEmpty) {
    return normalizedGrade;
  }
  return '-';
}

/// EN: Opens a full-screen zoomable profile image viewer.
/// KO: 프로필 이미지를 전체 화면 확대 뷰어로 엽니다.
void _showProfileImageViewer(
  BuildContext context, {
  required String imageUrl,
  required String semanticLabel,
}) {
  final normalized = imageUrl.trim();
  if (normalized.isEmpty) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ProfileImageViewerPage(
          imageUrl: normalized,
          semanticLabel: semanticLabel,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// EN: Full-screen viewer for a single profile image.
/// KO: 단일 프로필 이미지를 보여주는 전체 화면 뷰어입니다.
class _ProfileImageViewerPage extends StatelessWidget {
  const _ProfileImageViewerPage({
    required this.imageUrl,
    required this.semanticLabel,
  });

  final String imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.6,
            maxScale: 4.0,
            child: GBTImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// EN: Account info section displayed only on own profile.
/// KO: 내 프로필에서만 표시되는 계정정보 섹션.
class _AccountInfoSection extends StatelessWidget {
  const _AccountInfoSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? GBTColors.darkBorder : GBTColors.border;
    final surfaceVariant = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final labelColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final valueColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final joinDate = '${profile.createdAt.toLocal()}'.split(' ').first;

    final rows = [
      (
        label: context.l10n(ko: '이메일', en: 'Email', ja: 'メールアドレス'),
        value: profile.email,
      ),
      (
        label: context.l10n(ko: '가입일', en: 'Joined', ja: '登録日'),
        value: joinDate,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GBTSpacing.md,
              GBTSpacing.sm,
              GBTSpacing.md,
              GBTSpacing.xs,
            ),
            child: Text(
              context.l10n(ko: '계정 정보', en: 'Account Info', ja: 'アカウント情報'),
              style: GBTTypography.labelSmall.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GBTSpacing.md,
                vertical: GBTSpacing.xs,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      rows[i].label,
                      style: GBTTypography.labelSmall.copyWith(
                        color: labelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: GBTSpacing.sm),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: GBTTypography.bodySmall.copyWith(
                        color: valueColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: GBTSpacing.xs),
        ],
      ),
    );
  }
}
