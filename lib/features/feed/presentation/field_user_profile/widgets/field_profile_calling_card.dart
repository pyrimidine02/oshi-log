/// EN: Social calling-card header for the field-notes user profile.
/// KO: 필드 노트 사용자 프로필의 소셜 명함 헤더입니다.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/theme/gbt_colors.dart';
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
      ko: '${data.displayName}의 FIELD LOG',
      en: '${data.displayName}\'s FIELD LOG',
      ja: '${data.displayName}の FIELD LOG',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoverPlate(
              coverImageUrl: data.coverImageUrl,
              onBack: onBack,
              onTap: onCoverTap,
            ),
            Transform.translate(
              offset: const Offset(0, -38),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.pageHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IdentityRow(
                      avatarUrl: data.avatarUrl,
                      onAvatarTap: onAvatarTap,
                      marker: data.accountRole,
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                    Text(
                      title,
                      style: GBTTypography.displaySmall.copyWith(
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
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.md),
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
                      onMore: onMore,
                      onEdit: onEdit,
                      onOpenTitlePicker: onOpenTitlePicker,
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
      height: 184,
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
            CustomPaint(
              painter: _RouteGridPainter(
                line: colors.secondary.withValues(alpha: 0.35),
                paper: colors.surfaceContainerHighest,
                route: colors.primary,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
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
          Positioned(
            right: GBTSpacing.md,
            bottom: GBTSpacing.md,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GBTColors.fieldInk.withValues(alpha: 0.82),
                border: Border.all(color: Colors.white54),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.sm,
                  vertical: GBTSpacing.xs,
                ),
                child: Text(
                  'TRAVELER / COMMUNITY',
                  style: GBTTypography.overline.copyWith(color: Colors.white),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Material(
          color: colors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: normalizedAvatar == null ? null : onAvatarTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 86,
                  child: normalizedAvatar == null
                      ? ColoredBox(
                          color: colors.secondaryContainer,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 42,
                            color: colors.onSecondaryContainer,
                          ),
                        )
                      : GBTImage(
                          imageUrl: normalizedAvatar,
                          width: 86,
                          height: 86,
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: GBTSpacing.sm,
              bottom: GBTSpacing.sm,
            ),
            child: Text(
              marker.trim().isEmpty ? 'MEMBER' : marker.toUpperCase(),
              style: GBTTypography.overline.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
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
  });

  final bool isMyProfile;
  final bool isAuthenticated;
  final bool isFollowing;
  final bool isBlocked;
  final bool isFollowBusy;
  final bool isMoreBusy;
  final VoidCallback onFollow;
  final VoidCallback onMore;
  final VoidCallback onEdit;
  final VoidCallback onOpenTitlePicker;

  @override
  Widget build(BuildContext context) {
    if (isMyProfile) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                context.l10n(ko: '프로필 수정', en: 'Edit profile', ja: 'プロフィール編集'),
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onOpenTitlePicker,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(context.l10n(ko: '칭호', en: 'Title', ja: '称号')),
            ),
          ),
        ],
      );
    }
    if (!isAuthenticated) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: GBTSpacing.touchTarget,
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
          ),
        ),
        const SizedBox(width: GBTSpacing.sm),
        SizedBox(
          width: GBTSpacing.touchTarget,
          height: GBTSpacing.touchTarget,
          child: OutlinedButton(
            onPressed: isMoreBusy ? null : onMore,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(GBTSpacing.touchTarget),
            ),
            child: const Icon(Icons.more_horiz_rounded),
          ),
        ),
      ],
    );
  }
}

class _RouteGridPainter extends CustomPainter {
  const _RouteGridPainter({
    required this.line,
    required this.paper,
    required this.route,
  });

  final Color line;
  final Color paper;
  final Color route;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final gridPaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 20.0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 18.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final routePath = Path()
      ..moveTo(-10, size.height * 0.78)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.62,
        size.height * 1.1,
        size.width + 12,
        size.height * 0.2,
      );
    canvas.drawPath(
      routePath,
      Paint()
        ..color = route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteGridPainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.paper != paper ||
        oldDelegate.route != route;
  }
}
