/// EN: Social calling-card header for the field-notes user profile.
/// KO: 필드 노트 사용자 프로필의 소셜 명함 헤더입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_spacing.dart';
import '../../../../../core/theme/gbt_typography.dart';
import '../../../../../core/widgets/common/gbt_image.dart';
import '../field_user_profile_view_data.dart';

class FieldProfileCallingCard extends StatelessWidget {
  const FieldProfileCallingCard({
    super.key,
    required this.data,
    required this.isMyProfile,
    required this.isAuthenticated,
    required this.isFollowing,
    required this.isBlocked,
    required this.isFollowBusy,
    required this.isMoreBusy,
    required this.onBack,
    required this.onAvatarTap,
    required this.onCoverTap,
    required this.onFollow,
    required this.onMore,
    required this.onFollowers,
    required this.onFollowing,
    required this.onEdit,
    required this.onOpenTitlePicker,
    this.activeTitleBadge,
    this.onMessage,
  });

  final FieldUserProfileViewData data;
  final bool isMyProfile;
  final bool isAuthenticated;
  final bool isFollowing;
  final bool isBlocked;
  final bool isFollowBusy;
  final bool isMoreBusy;
  final VoidCallback onBack;
  final VoidCallback onAvatarTap;
  final VoidCallback onCoverTap;
  final VoidCallback onFollow;
  final VoidCallback onMore;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onEdit;
  final VoidCallback onOpenTitlePicker;
  final Widget? activeTitleBadge;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bio =
        data.bio ??
        context.l10n(
          ko: '아직 소개가 없어요.',
          en: 'No introduction yet.',
          ja: '紹介はまだありません。',
        );
    final title = context.l10n(
      ko: '${data.displayName}의 여행 기록',
      en: '${data.displayName}\'s travel record',
      ja: '${data.displayName}の旅の記録',
    );

    return Semantics(
      container: true,
      label: context.l10n(
        ko: '${data.displayName} 프로필. $bio',
        en: '${data.displayName} profile. $bio',
        ja: '${data.displayName}のプロフィール。$bio',
      ),
      child: ColoredBox(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.pageHorizontal,
            GBTSpacing.sm,
            GBTSpacing.pageHorizontal,
            GBTSpacing.lg,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.primary, width: 4),
                left: BorderSide(color: colors.outlineVariant),
                right: BorderSide(color: colors.outlineVariant),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CoverPlate(
                  coverImageUrl: data.coverImageUrl,
                  onBack: onBack,
                  onTap: onCoverTap,
                ),
                Padding(
                  padding: const EdgeInsets.all(GBTSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: GBTSpacing.sm,
                        runSpacing: GBTSpacing.xs,
                        children: [
                          Text(
                            context.l10n(
                              ko: '여행자 프로필',
                              en: 'Traveler profile',
                              ja: '旅人プロフィール',
                            ),
                            style: GBTTypography.overline.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            context.l10n(
                              ko: '공개 활동 기록',
                              en: 'Public activity record',
                              ja: '公開アクティビティ記録',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GBTTypography.overline.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                      Divider(height: 1, color: colors.outlineVariant),
                      const SizedBox(height: GBTSpacing.md),
                      _IdentityRow(
                        avatarUrl: data.avatarUrl,
                        onAvatarTap: onAvatarTap,
                        marker: data.accessLevelLabel,
                      ),
                      const SizedBox(height: GBTSpacing.md),
                      Text(
                        title,
                        style: GBTTypography.headlineMedium.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (activeTitleBadge != null) ...[
                        const SizedBox(height: GBTSpacing.sm),
                        activeTitleBadge!,
                      ],
                      const SizedBox(height: GBTSpacing.sm),
                      Text(
                        bio,
                        style: GBTTypography.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.md),
                      Divider(height: 1, color: colors.outlineVariant),
                      _RelationshipLine(
                        data: data,
                        onFollowers: onFollowers,
                        onFollowing: onFollowing,
                      ),
                      const SizedBox(height: GBTSpacing.md),
                      _Actions(
                        isMyProfile: isMyProfile,
                        isAuthenticated: isAuthenticated,
                        isFollowing: isFollowing,
                        isBlocked: isBlocked,
                        isFollowBusy: isFollowBusy,
                        isMoreBusy: isMoreBusy,
                        onFollow: onFollow,
                        onMessage: onMessage,
                        onMore: onMore,
                        onEdit: onEdit,
                        onOpenTitlePicker: onOpenTitlePicker,
                      ),
                    ],
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

class _CoverPlate extends StatelessWidget {
  const _CoverPlate({
    required this.coverImageUrl,
    required this.onBack,
    required this.onTap,
  });

  final String? coverImageUrl;
  final VoidCallback onBack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedCover = coverImageUrl;
    return SizedBox(
      height: normalizedCover == null ? 64 : 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (normalizedCover != null)
            GestureDetector(
              onTap: onTap,
              child: GBTImage(
                imageUrl: normalizedCover,
                fit: BoxFit.cover,
                semanticLabel: context.l10n(
                  ko: '프로필 커버 이미지',
                  en: 'Profile cover image',
                  ja: 'プロフィールカバー画像',
                ),
              ),
            )
          else
            ColoredBox(color: colors.surfaceContainerLow),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(GBTSpacing.sm),
                child: Material(
                  color: colors.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onBack,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.avatarUrl,
    required this.onAvatarTap,
    required this.marker,
  });

  final String? avatarUrl;
  final VoidCallback onAvatarTap;
  final String marker;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedAvatar = avatarUrl;
    final normalizedMarker = marker.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.surface,
          shape: const RoundedRectangleBorder(),
          child: InkWell(
            onTap: normalizedAvatar == null ? null : onAvatarTap,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  width: 78,
                  height: 94,
                  child: normalizedAvatar == null
                      ? ColoredBox(
                          color: colors.secondaryContainer,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 38,
                            color: colors.onSecondaryContainer,
                          ),
                        )
                      : GBTImage(
                          imageUrl: normalizedAvatar,
                          width: 78,
                          height: 94,
                          fit: BoxFit.cover,
                          semanticLabel: context.l10n(
                            ko: '프로필 사진',
                            en: 'Profile image',
                            ja: 'プロフィール画像',
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: GBTSpacing.md),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 94),
            padding: const EdgeInsets.all(GBTSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              border: Border(
                left: BorderSide(color: colors.primary, width: 3),
                top: BorderSide(color: colors.outlineVariant),
                right: BorderSide(color: colors.outlineVariant),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(
                    ko: '계정 등급',
                    en: 'Account level',
                    ja: 'アカウントレベル',
                  ),
                  style: GBTTypography.overline.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  normalizedMarker.isEmpty
                      ? context.l10n(ko: '회원', en: 'Member', ja: 'メンバー')
                      : normalizedMarker,
                  style: GBTTypography.titleSmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RelationshipLine extends StatelessWidget {
  const _RelationshipLine({
    required this.data,
    required this.onFollowers,
    required this.onFollowing,
  });

  final FieldUserProfileViewData data;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final joined = MaterialLocalizations.of(
      context,
    ).formatCompactDate(data.joinedAt.toLocal());
    return Wrap(
      spacing: GBTSpacing.md,
      runSpacing: GBTSpacing.sm,
      children: [
        _RelationshipDatum(
          key: const Key('field-profile-followers'),
          value: data.followerCount?.toString() ?? '—',
          label: context.l10n(ko: '팔로워', en: 'followers', ja: 'フォロワー'),
          onTap: onFollowers,
        ),
        _RelationshipDatum(
          key: const Key('field-profile-following'),
          value: data.followingCount?.toString() ?? '—',
          label: context.l10n(ko: '팔로잉', en: 'following', ja: 'フォロー中'),
          onTap: onFollowing,
        ),
        Text(
          context.l10n(
            ko: '$joined 합류',
            en: 'Joined $joined',
            ja: '$joined 参加',
          ),
          style: GBTTypography.labelMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RelationshipDatum extends StatelessWidget {
  const _RelationshipDatum({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GBTTypography.labelLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: GBTTypography.labelMedium.copyWith(
                      color: colors.onSurfaceVariant,
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

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isMyProfile,
    required this.isAuthenticated,
    required this.isFollowing,
    required this.isBlocked,
    required this.isFollowBusy,
    required this.isMoreBusy,
    required this.onFollow,
    required this.onMore,
    required this.onEdit,
    required this.onOpenTitlePicker,
    this.onMessage,
  });

  final bool isMyProfile;
  final bool isAuthenticated;
  final bool isFollowing;
  final bool isBlocked;
  final bool isFollowBusy;
  final bool isMoreBusy;
  final VoidCallback onFollow;
  final VoidCallback? onMessage;
  final VoidCallback onMore;
  final VoidCallback onEdit;
  final VoidCallback onOpenTitlePicker;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (isMyProfile) {
      final editButton = _ActionButtonFrame(
        child: FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            context.l10n(ko: '프로필 수정', en: 'Edit profile', ja: 'プロフィール編集'),
          ),
        ),
      );
      final titleButton = _ActionButtonFrame(
        child: OutlinedButton.icon(
          onPressed: onOpenTitlePicker,
          icon: const Icon(Icons.workspace_premium_outlined),
          label: Text(context.l10n(ko: '칭호', en: 'Title', ja: '称号')),
        ),
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 380 || textScale > 1.3) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                editButton,
                const SizedBox(height: GBTSpacing.sm),
                titleButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: editButton),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(child: titleButton),
            ],
          );
        },
      );
    }
    if (!isAuthenticated) return const SizedBox.shrink();

    final followButton = _ActionButtonFrame(
      key: const Key('traveler-profile-follow'),
      child: FilledButton(
        key: const Key('field-profile-follow'),
        onPressed: isFollowBusy || isBlocked ? null : onFollow,
        child: Text(
          isBlocked
              ? context.l10n(ko: '차단됨', en: 'Blocked', ja: 'ブロック済み')
              : isFollowing
              ? context.l10n(ko: '팔로우 취소', en: 'Unfollow', ja: 'フォロー解除')
              : context.l10n(ko: '팔로우', en: 'Follow', ja: 'フォロー'),
        ),
      ),
    );
    final messageButton = onMessage == null
        ? null
        : _ActionButtonFrame(
            key: const Key('traveler-profile-message'),
            child: OutlinedButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(context.l10n(ko: '메시지', en: 'Message', ja: 'メッセージ')),
            ),
          );
    final moreButton = SizedBox(
      width: GBTSpacing.touchTarget,
      height: GBTSpacing.touchTarget,
      child: Tooltip(
        message: context.l10n(ko: '더 보기', en: 'More', ja: 'さらに表示'),
        child: OutlinedButton(
          onPressed: isMoreBusy ? null : onMore,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(GBTSpacing.touchTarget),
          ),
          child: const Icon(Icons.more_horiz_rounded),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380 || textScale > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              followButton,
              const SizedBox(height: GBTSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (messageButton != null) Expanded(child: messageButton),
                  if (messageButton != null)
                    const SizedBox(width: GBTSpacing.sm),
                  moreButton,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: followButton),
            if (messageButton != null) ...[
              const SizedBox(width: GBTSpacing.sm),
              messageButton,
            ],
            const SizedBox(width: GBTSpacing.sm),
            moreButton,
          ],
        );
      },
    );
  }
}

class _ActionButtonFrame extends StatelessWidget {
  const _ActionButtonFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      child: child,
    );
  }
}
