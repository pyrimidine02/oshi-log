/// EN: Clean-sheet public user profile in the Urban Travel Field Notes system.
/// KO: Urban Travel Field Notes 시스템으로 새로 설계한 공개 사용자 프로필입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../../live_events/application/live_events_controller.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../settings/domain/entities/user_profile.dart';
import '../../../titles/application/titles_controller.dart';
import '../../../titles/presentation/widgets/active_title_badge.dart';
import '../../../visits/application/visits_controller.dart';
import '../../application/community_moderation_controller.dart';
import '../../application/report_rate_limiter.dart';
import '../../application/user_activity_controller.dart';
import '../../application/user_follow_controller.dart';
import '../../application/user_follow_list_controller.dart';
import '../../domain/entities/community_moderation.dart';
import '../widgets/community_report_sheet.dart';
import 'field_user_profile_view_data.dart';
import 'widgets/field_user_profile_document.dart';

/// EN: Public profile entry point preserving all existing domain actions.
/// KO: 기존 도메인 액션을 모두 유지하는 공개 프로필 진입점입니다.
class FieldUserProfilePage extends ConsumerWidget {
  const FieldUserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfileState = ref.watch(userProfileControllerProvider);
    final myProfile = myProfileState.valueOrNull;
    final isMyProfile = myProfile?.id == userId;
    final publicState = isMyProfile
        ? AsyncValue<UserProfile?>.data(myProfile)
        : ref.watch(userProfileByIdProvider(userId));
    final profile = isMyProfile ? myProfile : publicState.valueOrNull;

    if (profile == null) {
      return _ProfileLoadState(
        isLoading: publicState.isLoading || myProfileState.isLoading,
        error: publicState.hasError ? publicState.error : null,
        onRetry: () => ref
            .read(userProfileByIdProvider(userId).notifier)
            .load(forceRefresh: true),
      );
    }

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final followState = !isMyProfile && isAuthenticated
        ? ref.watch(userFollowControllerProvider(userId))
        : const AsyncValue<UserFollowStatus>.loading();
    final blockState = !isMyProfile && isAuthenticated
        ? ref.watch(blockStatusControllerProvider(userId))
        : const AsyncValue<BlockStatus>.loading();
    final followersState = isAuthenticated
        ? ref.watch(userFollowersProvider(userId))
        : const AsyncValue<List<UserFollowSummary>>.data([]);
    final followingState = isAuthenticated
        ? ref.watch(userFollowingProvider(userId))
        : const AsyncValue<List<UserFollowSummary>>.data([]);
    final followStatus = followState.valueOrNull;
    final blockStatus = blockState.valueOrNull;
    final followerCount =
        followStatus?.targetFollowerCount ?? followersState.valueOrNull?.length;
    final followingCount =
        followStatus?.targetFollowingCount ??
        followingState.valueOrNull?.length;
    final isBlocked =
        blockStatus?.blockedByMe == true ||
        blockStatus?.blockedMe == true ||
        blockStatus?.blockedByAdmin == true;
    final activityState = ref.watch(userActivityControllerProvider(userId));

    final fanLevel = isMyProfile
        ? ref.watch(fanLevelControllerProvider).valueOrNull
        : null;
    final ranking = isMyProfile
        ? ref.watch(userRankingProvider).valueOrNull
        : null;
    final liveHistory = isMyProfile
        ? ref.watch(liveAttendanceHistoryControllerProvider)
        : const LiveAttendanceHistoryViewState();
    final viewData = FieldUserProfileViewData.fromProfile(
      profile: profile,
      followerCount: followerCount,
      followingCount: followingCount,
      fallbackTotalXp: fanLevel?.totalXp,
      fallbackFanGrade: fanLevel?.grade.koLabel,
      fallbackUniquePlacesVisited: ranking?.uniquePlaces,
      fallbackLiveAttendanceCount: liveHistory.items.length,
    );

    final activeTitle = isMyProfile
        ? ref.watch(activeTitleProvider).valueOrNull
        : ref.watch(userActiveTitleProvider(userId)).valueOrNull;
    final activeTitleBadge = activeTitle != null && activeTitle.hasTitle
        ? ActiveTitleBadge.fromActiveItem(activeTitle)
        : null;
    final activeTitleId = isMyProfile
        ? ref.watch(activeTitleProvider).valueOrNull?.titleId
        : null;

    final activity = activityState.valueOrNull;
    final error = activityState.error;
    Future<void> refreshActivity() {
      return ref
          .read(userActivityControllerProvider(userId).notifier)
          .load(forceRefresh: true);
    }

    Future<void> refreshVisits() async {
      if (isMyProfile) {
        ref.invalidate(userRankingProvider);
        await Future.wait([
          ref
              .read(userProfileControllerProvider.notifier)
              .load(forceRefresh: true),
          ref.read(userRankingProvider.future),
        ]);
        return;
      }
      await ref
          .read(userProfileByIdProvider(userId).notifier)
          .load(forceRefresh: true);
    }

    return Scaffold(
      body: FieldUserProfileDocument(
        data: viewData,
        posts: activity?.posts ?? const [],
        comments: activity?.comments ?? const [],
        isMyProfile: isMyProfile,
        isAuthenticated: isAuthenticated,
        isFollowing: followStatus?.following == true,
        isBlocked: isBlocked,
        isFollowBusy: !isMyProfile && followState.isLoading,
        isMoreBusy: !isMyProfile && blockStatus == null,
        activeTitleBadge: activeTitleBadge,
        onBack: () => Navigator.of(context).maybePop(),
        onAvatarTap: () => _openImage(
          context,
          imageUrl: viewData.avatarUrl,
          label: context.l10n(
            ko: '프로필 사진',
            en: 'Profile image',
            ja: 'プロフィール画像',
          ),
        ),
        onCoverTap: () => _openImage(
          context,
          imageUrl: viewData.coverImageUrl,
          label: context.l10n(
            ko: '프로필 커버 이미지',
            en: 'Profile cover image',
            ja: 'プロフィールカバー画像',
          ),
        ),
        onFollow: () => _toggleFollow(context, ref),
        onMore: () => _openMoreActions(
          context,
          ref,
          blockedByMe: blockStatus?.blockedByMe == true,
        ),
        onFollowers: () => context.goToUserFollowers(userId),
        onFollowing: () => context.goToUserFollowing(userId),
        onEdit: () => context.pushNamed(AppRoutes.profileEdit),
        onOpenTitlePicker: () => context.pushNamed(
          AppRoutes.titlePicker,
          queryParameters: activeTitleId != null && activeTitleId.isNotEmpty
              ? {'titleId': activeTitleId}
              : {},
        ),
        onRefresh: refreshActivity,
        onRefreshVisits: refreshVisits,
        onOpenPost: (postId, projectCode) =>
            context.goToPostDetail(postId, projectCode: projectCode),
        isActivityLoading: activityState.isLoading,
        activityErrorMessage: error == null
            ? null
            : error is Failure
            ? error.userMessage
            : context.l10n(
                ko: '활동을 불러오지 못했어요',
                en: 'Failed to load activity',
                ja: 'アクティビティを読み込めませんでした',
              ),
        blockedMessage: isBlocked && !isMyProfile
            ? _blockedMessage(context, blockStatus)
            : null,
        onRetryActivity: refreshActivity,
        onOpenFanLevel: isMyProfile ? () => context.push('/fan-level') : null,
        onOpenPlaceHistory: isMyProfile
            ? () => context.goToVisitHistory()
            : null,
        onOpenLiveHistory: isMyProfile
            ? () => context.goToVisitHistory(showLiveTab: true)
            : null,
        accountLedger: isMyProfile ? _AccountLedger(profile: profile) : null,
      ),
    );
  }

  Future<void> _toggleFollow(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(userFollowControllerProvider(userId).notifier)
        .toggleFollow();
    if (!context.mounted) return;
    final message = switch (result) {
      Success<bool>(:final data) =>
        data
            ? context.l10n(
                ko: '팔로우했어요',
                en: 'Following this traveler',
                ja: 'フォローしました',
              )
            : context.l10n(
                ko: '팔로우를 취소했어요',
                en: 'Unfollowed',
                ja: 'フォローを解除しました',
              ),
      _ => context.l10n(
        ko: '팔로우 상태를 바꾸지 못했어요',
        en: 'Failed to update follow status',
        ja: 'フォロー状態を更新できませんでした',
      ),
    };
    _snack(context, message);
  }

  Future<void> _openMoreActions(
    BuildContext context,
    WidgetRef ref, {
    required bool blockedByMe,
  }) async {
    final action = await showModalBottomSheet<_ProfileAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minTileHeight: GBTSpacing.touchTarget,
              leading: Icon(
                blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded,
              ),
              title: Text(
                blockedByMe
                    ? sheetContext.l10n(
                        ko: '차단 해제',
                        en: 'Unblock',
                        ja: 'ブロック解除',
                      )
                    : sheetContext.l10n(
                        ko: '사용자 차단',
                        en: 'Block user',
                        ja: 'ユーザーをブロック',
                      ),
              ),
              onTap: () => Navigator.pop(sheetContext, _ProfileAction.block),
            ),
            ListTile(
              minTileHeight: GBTSpacing.touchTarget,
              leading: const Icon(Icons.flag_outlined),
              title: Text(
                sheetContext.l10n(
                  ko: '사용자 신고',
                  en: 'Report user',
                  ja: 'ユーザーを通報',
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, _ProfileAction.report),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _ProfileAction.block:
        await _toggleBlock(context, ref);
      case _ProfileAction.report:
        await _reportUser(context, ref);
    }
  }

  Future<void> _toggleBlock(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(blockStatusControllerProvider(userId).notifier)
        .toggleBlock();
    if (!context.mounted) return;
    if (result is Err<void>) {
      _snack(
        context,
        context.l10n(
          ko: '차단 상태를 바꾸지 못했어요',
          en: 'Failed to update block status',
          ja: 'ブロック状態を更新できませんでした',
        ),
      );
      return;
    }
    final blocked = ref
        .read(blockStatusControllerProvider(userId))
        .valueOrNull
        ?.blockedByMe;
    _snack(
      context,
      blocked == true
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

  Future<void> _reportUser(BuildContext context, WidgetRef ref) async {
    final limiter = ref.read(reportRateLimiterProvider);
    final targetKey = 'user:$userId';
    if (!limiter.canReport(targetKey)) {
      final minutes = limiter.remainingCooldown(targetKey).inMinutes + 1;
      _snack(
        context,
        context.l10n(
          ko: '$minutes분 후 다시 신고할 수 있어요',
          en: 'You can report again in $minutes minutes',
          ja: '$minutes分後に再度通報できます',
        ),
      );
      return;
    }
    final payload = await showModalBottomSheet<CommunityReportPayload>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CommunityReportSheet(),
    );
    if (payload == null || !context.mounted) return;
    final confirmed = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(ko: '신고 접수', en: 'Submit report', ja: '通報受付'),
      message: context.l10n(
        ko: '이 사용자를 "${payload.reason.label}" 사유로 신고할까요?',
        en: 'Report this user for "${payload.reason.label}"?',
        ja: 'このユーザーを「${payload.reason.label}」の理由で通報しますか？',
      ),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      confirmLabel: context.l10n(ko: '신고 접수', en: 'Submit', ja: '受付'),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = await ref.read(communityRepositoryProvider.future);
    final result = await repository.createReport(
      targetType: CommunityReportTargetType.user,
      targetId: userId,
      reason: payload.reason,
      description: payload.description,
    );
    if (!context.mounted) return;
    if (result is Success<void>) {
      limiter.recordReport(targetKey);
      _snack(
        context,
        context.l10n(ko: '신고가 접수됐어요', en: 'Report submitted', ja: '通報を受け付けました'),
      );
    } else {
      _snack(
        context,
        context.l10n(
          ko: '신고를 접수하지 못했어요',
          en: 'Failed to submit report',
          ja: '通報を受け付けられませんでした',
        ),
      );
    }
  }
}

enum _ProfileAction { block, report }

class _ProfileLoadState extends StatelessWidget {
  const _ProfileLoadState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '프로필 기록', en: 'Profile record', ja: 'プロフィール記録'),
      ),
      body: Center(
        child: Padding(
          padding: GBTSpacing.paddingPage,
          child: isLoading
              ? GBTLoading(
                  message: context.l10n(
                    ko: '프로필을 불러오는 중...',
                    en: 'Loading profile...',
                    ja: 'プロフィールを読み込み中...',
                  ),
                )
              : GBTErrorState(
                  message: switch (error) {
                    Failure(:final userMessage) => userMessage,
                    _ => context.l10n(
                      ko: '프로필을 불러오지 못했어요',
                      en: 'Failed to load profile',
                      ja: 'プロフィールを読み込めませんでした',
                    ),
                  },
                  onRetry: onRetry,
                ),
        ),
      ),
    );
  }
}

class _AccountLedger extends StatelessWidget {
  const _AccountLedger({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final joined = MaterialLocalizations.of(
      context,
    ).formatCompactDate(profile.createdAt.toLocal());
    final rows = <({String label, String value})>[
      (
        label: context.l10n(ko: '이메일', en: 'Email', ja: 'メール'),
        value: profile.email,
      ),
      (label: context.l10n(ko: '가입일', en: 'Joined', ja: '登録日'), value: joined),
      (
        label: context.l10n(ko: '접근 등급', en: 'Access', ja: 'アクセス'),
        value: profile.effectiveAccessLevelLabel,
      ),
    ];
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          0,
          GBTSpacing.pageHorizontal,
          GBTSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n(ko: '계정 정보', en: 'Account details', ja: 'アカウント情報'),
              style: GBTTypography.overline.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: GBTSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 82,
                            child: Text(
                              rows[index].label,
                              style: GBTTypography.labelMedium.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rows[index].value,
                              style: GBTTypography.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < rows.length - 1)
                      Divider(height: 1, color: colors.outlineVariant),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImageViewer extends StatelessWidget {
  const _ProfileImageViewer({required this.imageUrl, required this.label});

  final String imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: GBTImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

String _blockedMessage(BuildContext context, BlockStatus? status) {
  if (status?.blockedByAdmin == true) {
    return context.l10n(
      ko: '관리자 정책으로 이 사용자의 활동을 볼 수 없어요.',
      en: 'This activity is unavailable due to admin policy.',
      ja: '管理者ポリシーにより活動を表示できません。',
    );
  }
  if (status?.blockedMe == true) {
    return context.l10n(
      ko: '이 사용자의 활동을 볼 수 없어요.',
      en: 'This user\'s activity is unavailable.',
      ja: 'このユーザーの活動を表示できません。',
    );
  }
  return context.l10n(
    ko: '차단한 사용자의 활동은 숨겨져요.',
    en: 'Activity from a blocked user is hidden.',
    ja: 'ブロックしたユーザーの活動は非表示です。',
  );
}

void _openImage(
  BuildContext context, {
  required String? imageUrl,
  required String label,
}) {
  final normalized = imageUrl?.trim();
  if (normalized == null || normalized.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ProfileImageViewer(imageUrl: normalized, label: label),
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
