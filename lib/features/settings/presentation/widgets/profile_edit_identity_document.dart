/// EN: Passport-inspired identity amendment document for profile editing.
/// KO: 프로필 편집을 위한 여권 모티프의 신원 정보 정정 문서입니다.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/legal/legal_policy_links_section.dart';

/// EN: Keeps profile media, editable identity, and account provenance in one folio.
/// KO: 프로필 미디어, 편집 가능한 신원 정보, 계정 출처를 하나의 문서로 묶습니다.
class ProfileEditIdentityDocument extends StatelessWidget {
  const ProfileEditIdentityDocument({
    super.key,
    required this.displayNameController,
    required this.bioController,
    required this.maxDisplayNameLength,
    required this.maxBioLength,
    required this.maskedEmail,
    required this.accessLabel,
    required this.memberSinceLabel,
    required this.hasPendingAvatar,
    required this.hasPendingCover,
    required this.isUploadingAvatar,
    required this.isUploadingCover,
    required this.onChangeAvatar,
    required this.onChangeCover,
    required this.onRefresh,
    this.avatarUrl,
    this.coverUrl,
  });

  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final int maxDisplayNameLength;
  final int maxBioLength;
  final String maskedEmail;
  final String accessLabel;
  final String memberSinceLabel;
  final String? avatarUrl;
  final String? coverUrl;
  final bool hasPendingAvatar;
  final bool hasPendingCover;
  final bool isUploadingAvatar;
  final bool isUploadingCover;
  final VoidCallback onChangeAvatar;
  final VoidCallback onChangeCover;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('profile-edit-identity-document'),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          GBTSpacing.pageHorizontal,
          GBTSpacing.md,
          GBTSpacing.pageHorizontal,
          GBTSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const _DocumentIntro(),
          const SizedBox(height: GBTSpacing.lg),
          _SectionLabel(
            index: '01',
            title: context.l10n(
              ko: '여권 이미지',
              en: 'Passport media',
              ja: 'パスポート画像',
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          _MediaSheet(
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
            displayNameController: displayNameController,
            hasPendingAvatar: hasPendingAvatar,
            hasPendingCover: hasPendingCover,
            isUploadingAvatar: isUploadingAvatar,
            isUploadingCover: isUploadingCover,
            onChangeAvatar: onChangeAvatar,
            onChangeCover: onChangeCover,
          ),
          const SizedBox(height: GBTSpacing.lg),
          _SectionLabel(
            index: '02',
            title: context.l10n(
              ko: '소유자 정보',
              en: 'Holder details',
              ja: '所有者情報',
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          _BasicFields(
            displayNameController: displayNameController,
            bioController: bioController,
            maxDisplayNameLength: maxDisplayNameLength,
            maxBioLength: maxBioLength,
          ),
          const SizedBox(height: GBTSpacing.lg),
          _SectionLabel(
            index: '03',
            title: context.l10n(ko: '발급 기록', en: 'Issue record', ja: '発行記録'),
          ),
          const SizedBox(height: GBTSpacing.sm),
          _AccountLedger(
            maskedEmail: maskedEmail,
            accessLabel: accessLabel,
            memberSinceLabel: memberSinceLabel,
          ),
          const SizedBox(height: GBTSpacing.lg),
          _SectionLabel(
            index: '04',
            title: context.l10n(
              ko: '약관 및 정책',
              en: 'Terms and policies',
              ja: '規約とポリシー',
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          const _RuledSheet(
            child: LegalPolicyLinksSection(showContainer: false, title: ''),
          ),
        ],
      ),
    );
  }
}

class _DocumentIntro extends StatelessWidget {
  const _DocumentIntro();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.primary, width: 4),
          left: BorderSide(color: colors.outlineVariant),
          right: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IDENTITY AMENDMENT',
            style: GBTTypography.overline.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '나의 여행자 정보를 정리합니다',
              en: 'Update your traveler identity',
              ja: '旅行者情報を更新します',
            ),
            style: GBTTypography.headlineMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '변경한 내용은 저장 전까지 여권 원본에 반영되지 않습니다.',
              en: 'Changes remain a draft until you save them.',
              ja: '変更内容は保存するまで反映されません。',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.index, required this.title});

  final String index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index,
          style: GBTTypography.overline.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: GBTSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: GBTTypography.titleSmall.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaSheet extends StatelessWidget {
  const _MediaSheet({
    required this.avatarUrl,
    required this.coverUrl,
    required this.displayNameController,
    required this.hasPendingAvatar,
    required this.hasPendingCover,
    required this.isUploadingAvatar,
    required this.isUploadingCover,
    required this.onChangeAvatar,
    required this.onChangeCover,
  });

  final String? avatarUrl;
  final String? coverUrl;
  final TextEditingController displayNameController;
  final bool hasPendingAvatar;
  final bool hasPendingCover;
  final bool isUploadingAvatar;
  final bool isUploadingCover;
  final VoidCallback onChangeAvatar;
  final VoidCallback onChangeCover;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasCover = coverUrl != null && coverUrl!.isNotEmpty;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      key: const ValueKey('profile-edit-media-sheet'),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        color: colors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasCover)
                  GBTImage(
                    imageUrl: coverUrl!,
                    fit: BoxFit.cover,
                    semanticLabel: context.l10n(
                      ko: '현재 배경 이미지',
                      en: 'Current cover image',
                      ja: '現在の背景画像',
                    ),
                  )
                else
                  ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.route_outlined,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
                if (isUploadingCover) const _LoadingVeil(),
                if (hasPendingCover && !isUploadingCover)
                  const Positioned(
                    top: GBTSpacing.sm,
                    right: GBTSpacing.sm,
                    child: _DraftMark(),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 92,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        border: Border.all(color: colors.outline),
                      ),
                      child: hasAvatar
                          ? GBTImage(
                              imageUrl: avatarUrl!,
                              fit: BoxFit.cover,
                              semanticLabel: context.l10n(
                                ko: '현재 프로필 사진',
                                en: 'Current profile photo',
                                ja: '現在のプロフィール写真',
                              ),
                            )
                          : Icon(
                              Icons.person_outline_rounded,
                              color: colors.onSurfaceVariant,
                              size: 34,
                            ),
                    ),
                    if (isUploadingAvatar)
                      const Positioned.fill(child: _LoadingVeil()),
                    if (hasPendingAvatar && !isUploadingAvatar)
                      const Positioned(
                        top: GBTSpacing.xs,
                        right: GBTSpacing.xs,
                        child: _DraftMark(),
                      ),
                  ],
                ),
                const SizedBox(width: GBTSpacing.md),
                Expanded(
                  child: ListenableBuilder(
                    listenable: displayNameController,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASSPORT HOLDER',
                          style: GBTTypography.overline.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: GBTSpacing.xs),
                        Text(
                          displayNameController.text.trim().isEmpty
                              ? context.l10n(
                                  ko: '이름 미입력',
                                  en: 'Name pending',
                                  ja: '名前未入力',
                                )
                              : displayNameController.text.trim(),
                          style: GBTTypography.titleLarge.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(GBTSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('profile-edit-change-cover'),
                  onPressed: isUploadingCover ? null : onChangeCover,
                  icon: const Icon(Icons.landscape_outlined),
                  label: Text(
                    isUploadingCover
                        ? context.l10n(
                            ko: '배경 업로드 중',
                            en: 'Uploading cover',
                            ja: '背景をアップロード中',
                          )
                        : context.l10n(
                            ko: '배경 이미지 교체',
                            en: 'Replace cover image',
                            ja: '背景画像を変更',
                          ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: GBTSpacing.sm),
                FilledButton.tonalIcon(
                  key: const ValueKey('profile-edit-change-avatar'),
                  onPressed: isUploadingAvatar ? null : onChangeAvatar,
                  icon: const Icon(Icons.portrait_outlined),
                  label: Text(
                    isUploadingAvatar
                        ? context.l10n(
                            ko: '사진 업로드 중',
                            en: 'Uploading photo',
                            ja: '写真をアップロード中',
                          )
                        : context.l10n(
                            ko: '증명 사진 교체',
                            en: 'Replace identity photo',
                            ja: '証明写真を変更',
                          ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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

class _BasicFields extends StatelessWidget {
  const _BasicFields({
    required this.displayNameController,
    required this.bioController,
    required this.maxDisplayNameLength,
    required this.maxBioLength,
  });

  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final int maxDisplayNameLength;
  final int maxBioLength;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _RuledSheet(
      key: const ValueKey('profile-edit-basic-fields'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldCaption(
            label: context.l10n(ko: '표시 이름', en: 'Display name', ja: '表示名'),
            listenable: displayNameController,
            count: () => displayNameController.text.length,
            maxLength: maxDisplayNameLength,
          ),
          TextField(
            key: const ValueKey('profile-edit-display-name'),
            controller: displayNameController,
            maxLength: maxDisplayNameLength,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              context,
              hint: context.l10n(
                ko: '여권에 표시할 이름',
                en: 'Name shown in your passport',
                ja: 'パスポートに表示する名前',
              ),
            ),
          ),
          Divider(height: GBTSpacing.lg, color: colors.outlineVariant),
          _FieldCaption(
            label: context.l10n(ko: '여행자 소개', en: 'Traveler note', ja: '旅行者紹介'),
            listenable: bioController,
            count: () => bioController.text.length,
            maxLength: maxBioLength,
          ),
          TextField(
            key: const ValueKey('profile-edit-bio'),
            controller: bioController,
            maxLength: maxBioLength,
            minLines: 4,
            maxLines: null,
            decoration: _fieldDecoration(
              context,
              hint: context.l10n(
                ko: '어떤 공연과 장소를 기록하는지 적어보세요',
                en: 'Describe the shows and places you document',
                ja: '記録している公演や場所を書いてください',
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      counterText: '',
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
    );
  }
}

class _FieldCaption extends StatelessWidget {
  const _FieldCaption({
    required this.label,
    required this.listenable,
    required this.count,
    required this.maxLength,
  });

  final String label;
  final Listenable listenable;
  final int Function() count;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GBTTypography.labelMedium.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${count()}/$maxLength',
            style: GBTTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountLedger extends StatelessWidget {
  const _AccountLedger({
    required this.maskedEmail,
    required this.accessLabel,
    required this.memberSinceLabel,
  });

  final String maskedEmail;
  final String accessLabel;
  final String memberSinceLabel;

  @override
  Widget build(BuildContext context) {
    return _RuledSheet(
      child: Column(
        children: [
          _LedgerRow(label: 'EMAIL', value: maskedEmail),
          _LedgerRow(label: 'ACCESS', value: accessLabel),
          _LedgerRow(label: 'ISSUED', value: memberSinceLabel, isLast: true),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
      child: Wrap(
        spacing: GBTSpacing.md,
        runSpacing: GBTSpacing.xs,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: GBTTypography.overline.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: GBTTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuledSheet extends StatelessWidget {
  const _RuledSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: child,
    );
  }
}

class _DraftMark extends StatelessWidget {
  const _DraftMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n(ko: '저장 대기 중', en: 'Pending save', ja: '保存待ち'),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surface, width: 2),
        ),
      ),
    );
  }
}

class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.38),
      child: const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
