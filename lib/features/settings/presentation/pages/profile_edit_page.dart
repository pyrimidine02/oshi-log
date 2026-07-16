/// EN: Profile edit page — iOS-settings style, consistent with SettingsPage.
/// KO: 프로필 편집 페이지 — SettingsPage와 동일한 iOS 설정 스타일.
library;

import 'dart:io';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart' as native_cropper;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/profile_media_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/sensitive_text_utils.dart';
import '../../../../core/widgets/common/gbt_icon_chip.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/legal/legal_policy_links_section.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../uploads/application/uploads_controller.dart';
import '../../../uploads/utils/webp_image_converter.dart';
import '../../application/settings_controller.dart';
import '../../domain/entities/user_profile.dart';

/// EN: Profile edit page widget.
/// KO: 프로필 편집 페이지 위젯.
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  static const int _maxDisplayNameLength = 30;
  static const int _maxBioLength = 200;

  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _didSetInitial = false;
  bool _isHydrating = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  bool _isChangingAvatar = false;
  bool _isChangingCover = false;

  String? _initialDisplayName;
  String? _initialBio;
  String? _initialAvatarUrl;
  String? _initialCoverUrl;

  String? _pendingAvatarUrl;
  String? _pendingCoverUrl;

  bool get _isBusy =>
      _isSaving ||
      _isUploadingAvatar ||
      _isUploadingCover ||
      _isChangingAvatar ||
      _isChangingCover;

  bool get _hasPendingChanges {
    if (!_didSetInitial) return false;
    final currentDisplayName = _displayNameController.text.trim();
    final currentBio = _normalizeOptional(_bioController.text);
    final baselineDisplayName = (_initialDisplayName ?? '').trim();
    final baselineBio = _normalizeOptional(_initialBio ?? '');
    final currentAvatar = _pendingAvatarUrl ?? _initialAvatarUrl;
    final currentCover = _pendingCoverUrl ?? _initialCoverUrl;
    return currentDisplayName != baselineDisplayName ||
        currentBio != baselineBio ||
        currentAvatar != _initialAvatarUrl ||
        currentCover != _initialCoverUrl;
  }

  bool get _canSaveProfile =>
      !_isBusy &&
      _hasPendingChanges &&
      _displayNameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _displayNameController.addListener(_onFormChanged);
    _bioController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_onFormChanged);
    _bioController.removeListener(_onFormChanged);
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted || _isHydrating) return;
    setState(() {});
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _hydrateFromProfile(UserProfile profile) {
    _isHydrating = true;
    _displayNameController.text = profile.displayName;
    _bioController.text = profile.bio ?? '';
    _isHydrating = false;
    _initialDisplayName = profile.displayName;
    _initialBio = profile.bio;
    _initialAvatarUrl = profile.avatarUrl;
    _initialCoverUrl = profile.coverImageUrl;
    _pendingAvatarUrl = null;
    _pendingCoverUrl = null;
    _didSetInitial = true;
  }

  Future<bool> _handleWillPop() async {
    if (_isBusy) return false;
    if (!_hasPendingChanges) return true;
    final shouldDiscard = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '저장하지 않고 나갈까요?',
      message: '프로필 변경 사항이 사라집니다.',
      confirmLabel: '나가기',
      cancelLabel: '계속 수정',
    );
    return shouldDiscard ?? false;
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _normalizeOptional(_bioController.text);
    if (displayName.isEmpty) {
      _showMessage('표시 이름을 입력해주세요');
      return;
    }
    if (!_hasPendingChanges) {
      _showMessage('변경된 내용이 없어요');
      return;
    }
    setState(() => _isSaving = true);
    final profile = ref.read(userProfileControllerProvider).valueOrNull;
    final result = await ref
        .read(userProfileControllerProvider.notifier)
        .updateProfile(
          displayName: displayName,
          avatarUrl: _pendingAvatarUrl ?? profile?.avatarUrl,
          bio: bio,
          coverImageUrl: _pendingCoverUrl ?? profile?.coverImageUrl,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result case Success<UserProfile>(:final data)) {
      _hydrateFromProfile(data);
      _showMessage('프로필이 저장되었습니다');
      context.pop();
      return;
    }
    _showMessage('프로필 저장에 실패했습니다');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(ko: '프로필 수정', en: 'Edit profile', ja: 'プロフィール編集'),
        ),
        body: _LoginRequired(onLogin: () => context.push('/login')),
      );
    }

    final state = ref.watch(userProfileControllerProvider);

    return PopScope<Object?>(
      canPop: !_isBusy && !_hasPendingChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (!mounted || !shouldPop) return;
        Navigator.of(this.context).pop(result);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: gbtStandardAppBar(
            context,
            title: context.l10n(
              ko: '프로필 수정',
              en: 'Edit profile',
              ja: 'プロフィール編集',
            ),
            actions: [
              Semantics(
                button: true,
                label: _isSaving ? '저장 중' : '프로필 저장',
                enabled: _canSaveProfile,
                child: Padding(
                  padding: const EdgeInsets.only(right: GBTSpacing.xs),
                  child: TextButton(
                    onPressed: _canSaveProfile ? _saveProfile : null,
                    child: Text(
                      _isSaving ? '저장 중' : '저장',
                      style: GBTTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _canSaveProfile
                            ? (isDark
                                  ? GBTColors.darkPrimary
                                  : GBTColors.primary)
                            : (isDark
                                  ? GBTColors.darkTextTertiary
                                  : GBTColors.textTertiary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: GBTLoadingOverlay(
            isLoading: _isBusy,
            message: _isSaving
                ? '프로필 저장 중...'
                : _isChangingAvatar
                ? '프로필 사진 선택 중...'
                : _isChangingCover
                ? '배경 이미지 선택 중...'
                : _isUploadingAvatar
                ? '프로필 사진 업로드 중...'
                : _isUploadingCover
                ? '배경 이미지 업로드 중...'
                : null,
            child: state.when(
              loading: () => const GBTLoading(message: '프로필을 불러오는 중...'),
              error: (error, _) => _ProfileLoadError(
                onRetry: () => ref
                    .read(userProfileControllerProvider.notifier)
                    .load(forceRefresh: true),
              ),
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                if (!_didSetInitial) _hydrateFromProfile(profile);

                final avatarUrl = _pendingAvatarUrl ?? profile.avatarUrl;
                final coverUrl = _pendingCoverUrl ?? profile.coverImageUrl;

                return _ProfileForm(
                  profile: profile,
                  avatarUrl: avatarUrl,
                  coverUrl: coverUrl,
                  displayNameController: _displayNameController,
                  bioController: _bioController,
                  maxDisplayNameLength: _maxDisplayNameLength,
                  maxBioLength: _maxBioLength,
                  hasPendingAvatar: _pendingAvatarUrl != null,
                  hasPendingCover: _pendingCoverUrl != null,
                  isUploadingAvatar: _isUploadingAvatar || _isChangingAvatar,
                  isUploadingCover: _isUploadingCover || _isChangingCover,
                  onChangeAvatar: _changeAvatar,
                  onChangeCover: _changeCover,
                  onRefresh: () => ref
                      .read(userProfileControllerProvider.notifier)
                      .load(forceRefresh: true),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _cropImageForUpload({
    required String sourcePath,
    required String title,
    required double ratioX,
    required double ratioY,
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _cropImageInAppOnAndroid(
        sourcePath: sourcePath,
        title: title,
        aspectRatio: ratioX / ratioY,
      );
    }
    return _cropImageWithNativeCropper(
      sourcePath: sourcePath,
      title: title,
      ratioX: ratioX,
      ratioY: ratioY,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  Future<String?> _cropImageInAppOnAndroid({
    required String sourcePath,
    required String title,
    required double aspectRatio,
  }) async {
    try {
      final sourceBytes = await File(sourcePath).readAsBytes();
      if (sourceBytes.isEmpty) {
        _showMessage('사진을 불러오지 못했습니다.');
        return null;
      }
      if (!mounted) return null;

      final croppedBytes = await showDialog<Uint8List?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AndroidInAppCropDialog(
          title: title,
          imageBytes: sourceBytes,
          aspectRatio: aspectRatio,
        ),
      );
      if (croppedBytes == null) return null;
      if (croppedBytes.isEmpty) {
        _showMessage('사진 편집에 실패했습니다.');
        return null;
      }

      final ext = p.extension(sourcePath).toLowerCase();
      final outputExt = ext == '.png' ? '.png' : '.jpg';
      final dir = await Directory.systemTemp.createTemp('gbt_profile_crop_');
      final file = File(p.join(dir.path, 'cropped$outputExt'));
      await file.writeAsBytes(croppedBytes, flush: true);
      return file.path;
    } catch (_) {
      _showMessage('사진 편집에 실패했습니다.');
      return null;
    }
  }

  Future<String?> _cropImageWithNativeCropper({
    required String sourcePath,
    required String title,
    required double ratioX,
    required double ratioY,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final cropped = await native_cropper.ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: native_cropper.CropAspectRatio(
          ratioX: ratioX,
          ratioY: ratioY,
        ),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        uiSettings: [
          native_cropper.AndroidUiSettings(
            toolbarTitle: title,
            lockAspectRatio: true,
          ),
          native_cropper.IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      return cropped?.path;
    } catch (_) {
      _showMessage('사진 편집에 실패했습니다.');
      return null;
    }
  }

  Future<void> _changeAvatar() async {
    if (_isBusy) return;
    setState(() => _isChangingAvatar = true);
    try {
      XFile? picked;
      try {
        picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );
      } catch (_) {
        return;
      }
      if (picked == null) return;

      final uploadSourcePath = await _cropImageForUpload(
        sourcePath: picked.path,
        title: '프로필 사진 자르기',
        ratioX: 1,
        ratioY: 1,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (uploadSourcePath == null) return;
      if (!mounted) return;

      setState(() => _isUploadingAvatar = true);
      try {
        final payload = await convertToWebp(
          path: uploadSourcePath,
          originalFilename: p.basename(uploadSourcePath),
          maxWidth: 1024,
          maxHeight: 1024,
          quality: 85,
        );
        final uploadResult = await ref
            .read(uploadsControllerProvider.notifier)
            .uploadImageBytes(
              bytes: payload.bytes,
              filename: payload.filename,
              contentType: payload.contentType,
            );
        if (uploadResult case Err(:final failure)) {
          _handleUploadFailure(failure);
          return;
        }
        final upload = switch (uploadResult) {
          Success(:final data) => data,
          Err(:final failure) => throw failure,
        };
        if (upload.url.isEmpty) {
          _showMessage('업로드 정보를 가져오지 못했습니다.');
          return;
        }
        if (!mounted) return;
        setState(() => _pendingAvatarUrl = upload.url);
        _showMessage('사진이 업로드되었습니다. 저장을 눌러 반영하세요.');
      } on Failure catch (failure) {
        _handleUploadFailure(failure);
      } catch (_) {
        _showMessage('사진 업로드에 실패했습니다.');
      } finally {
        if (mounted) setState(() => _isUploadingAvatar = false);
      }
    } finally {
      if (mounted) setState(() => _isChangingAvatar = false);
    }
  }

  Future<void> _changeCover() async {
    if (_isBusy) return;
    setState(() => _isChangingCover = true);
    try {
      XFile? picked;
      try {
        picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: profileCoverMaxWidth.toDouble(),
          maxHeight: profileCoverMaxHeight.toDouble(),
          imageQuality: 90,
        );
      } catch (_) {
        return;
      }
      if (picked == null) return;

      final uploadSourcePath = await _cropImageForUpload(
        sourcePath: picked.path,
        title: '배경 이미지 자르기',
        ratioX: profileCoverCropRatioX,
        ratioY: profileCoverCropRatioY,
        maxWidth: profileCoverMaxWidth,
        maxHeight: profileCoverMaxHeight,
      );
      if (uploadSourcePath == null) return;
      if (!mounted) return;

      setState(() => _isUploadingCover = true);
      try {
        final payload = await convertToWebp(
          path: uploadSourcePath,
          originalFilename: p.basename(uploadSourcePath),
          maxWidth: profileCoverMaxWidth,
          maxHeight: profileCoverMaxHeight,
          quality: 80,
        );
        final uploadResult = await ref
            .read(uploadsControllerProvider.notifier)
            .uploadImageBytes(
              bytes: payload.bytes,
              filename: payload.filename,
              contentType: payload.contentType,
            );
        if (uploadResult case Err(:final failure)) {
          _handleUploadFailure(failure);
          return;
        }
        final upload = switch (uploadResult) {
          Success(:final data) => data,
          Err(:final failure) => throw failure,
        };
        if (upload.url.isEmpty) {
          _showMessage('업로드 정보를 가져오지 못했습니다.');
          return;
        }
        if (!mounted) return;
        setState(() => _pendingCoverUrl = upload.url);
        _showMessage('배경 이미지가 업로드되었습니다. 저장을 눌러 반영하세요.');
      } on Failure catch (failure) {
        _handleUploadFailure(failure);
      } catch (_) {
        _showMessage('배경 이미지 업로드에 실패했습니다.');
      } finally {
        if (mounted) setState(() => _isUploadingCover = false);
      }
    } finally {
      if (mounted) setState(() => _isChangingCover = false);
    }
  }

  void _handleUploadFailure(Failure failure) {
    if (!mounted) return;
    final message = failure is AuthFailure && failure.code == '403'
        ? '아직 준비중입니다.'
        : failure.userMessage;
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ========================================
// EN: Main profile form — iOS-settings layout matching SettingsPage
// KO: 메인 프로필 폼 — SettingsPage와 동일한 iOS 설정 레이아웃
// ========================================
class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.profile,
    required this.displayNameController,
    required this.bioController,
    required this.avatarUrl,
    required this.coverUrl,
    required this.maxDisplayNameLength,
    required this.maxBioLength,
    required this.hasPendingAvatar,
    required this.hasPendingCover,
    required this.isUploadingAvatar,
    required this.isUploadingCover,
    required this.onChangeAvatar,
    required this.onChangeCover,
    required this.onRefresh,
  });

  final UserProfile profile;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final String? avatarUrl;
  final String? coverUrl;
  final int maxDisplayNameLength;
  final int maxBioLength;
  final bool hasPendingAvatar;
  final bool hasPendingCover;
  final bool isUploadingAvatar;
  final bool isUploadingCover;
  final VoidCallback onChangeAvatar;
  final VoidCallback onChangeCover;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(
          horizontal: GBTSpacing.md,
          vertical: GBTSpacing.sm,
        ),
        children: [
          // ── 이미지 섹션 ──────────────────────────────────────
          _SectionHeader('이미지', isDark: isDark),
          const SizedBox(height: GBTSpacing.xs),
          _ImageSectionCard(
            coverUrl: coverUrl,
            avatarUrl: avatarUrl,
            isUploadingCover: isUploadingCover,
            isUploadingAvatar: isUploadingAvatar,
            hasPendingCover: hasPendingCover,
            hasPendingAvatar: hasPendingAvatar,
            onChangeCover: onChangeCover,
            onChangeAvatar: onChangeAvatar,
            isDark: isDark,
          ),

          // ── 기본 정보 섹션 ────────────────────────────────────
          const SizedBox(height: GBTSpacing.lg),
          _SectionHeader('기본 정보', isDark: isDark),
          const SizedBox(height: GBTSpacing.xs),
          _BasicInfoCard(
            displayNameController: displayNameController,
            bioController: bioController,
            maxDisplayNameLength: maxDisplayNameLength,
            maxBioLength: maxBioLength,
            isDark: isDark,
          ),

          // ── 계정 정보 섹션 (읽기 전용) ─────────────────────
          const SizedBox(height: GBTSpacing.lg),
          _SectionHeader('계정 정보', isDark: isDark),
          const SizedBox(height: GBTSpacing.xs),
          _AccountInfoCard(profile: profile, isDark: isDark),

          const SizedBox(height: GBTSpacing.lg),
          _SectionHeader('약관 및 정책', isDark: isDark),
          const SizedBox(height: GBTSpacing.xs),
          const LegalPolicyLinksSection(),

          SizedBox(
            height: GBTSpacing.xl + MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Section header — matches SettingsPage _SettingsGroup label style
// KO: 섹션 헤더 — SettingsPage _SettingsGroup 라벨 스타일 동일
// ========================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: GBTSpacing.xs2),
      child: Text(
        title,
        style: GBTTypography.labelSmall.copyWith(
          color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ========================================
// EN: Section card container — matches _SettingsGroup card style exactly
// KO: 섹션 카드 컨테이너 — _SettingsGroup 카드 스타일과 완전히 동일
// ========================================
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? GBTColors.darkSurface : GBTColors.surface,
      child: child,
    );
  }
}

// ========================================
// EN: Image section card — cover preview + avatar row
// KO: 이미지 섹션 카드 — 커버 미리보기 + 아바타 행
// ========================================
class _ImageSectionCard extends StatelessWidget {
  const _ImageSectionCard({
    required this.coverUrl,
    required this.avatarUrl,
    required this.isUploadingCover,
    required this.isUploadingAvatar,
    required this.hasPendingCover,
    required this.hasPendingAvatar,
    required this.onChangeCover,
    required this.onChangeAvatar,
    required this.isDark,
  });

  final String? coverUrl;
  final String? avatarUrl;
  final bool isUploadingCover;
  final bool isUploadingAvatar;
  final bool hasPendingCover;
  final bool hasPendingAvatar;
  final VoidCallback onChangeCover;
  final VoidCallback onChangeAvatar;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? GBTColors.darkBorderSubtle
        : GBTColors.divider;

    return _SectionCard(
      child: Column(
        children: [
          // EN: Cover photo tap area — rounded top corners
          // KO: 커버 사진 탭 영역 — 상단 모서리 둥글게
          Semantics(
            button: true,
            label: '배경 이미지 변경',
            child: _CoverTile(
              coverUrl: coverUrl,
              isUploading: isUploadingCover,
              hasPending: hasPendingCover,
              onTap: isUploadingCover ? null : onChangeCover,
              isDark: isDark,
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // EN: Avatar row — settings-row style
          // KO: 아바타 행 — 설정 행 스타일
          _AvatarTile(
            avatarUrl: avatarUrl,
            isUploading: isUploadingAvatar,
            hasPending: hasPendingAvatar,
            onTap: isUploadingAvatar ? null : onChangeAvatar,
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Cover photo tile — rounded top, camera overlay, pending badge
// KO: 커버 사진 타일 — 상단 둥글기, 카메라 오버레이, 대기 뱃지
// ========================================
class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.coverUrl,
    required this.isUploading,
    required this.hasPending,
    required this.onTap,
    required this.isDark,
  });

  final String? coverUrl;
  final bool isUploading;
  final bool hasPending;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasImage = coverUrl != null && coverUrl!.isNotEmpty;
    const topRadius = BorderRadius.zero;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: topRadius,
        child: AspectRatio(
          aspectRatio: profileCoverAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // EN: Cover image or a quiet paper-toned placeholder.
              // KO: 커버 이미지 또는 차분한 종이톤 플레이스홀더.
              if (hasImage)
                GBTImage(
                  imageUrl: coverUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: '배경 이미지',
                )
              else
                ColoredBox(
                  color: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                ),

              // EN: Overlay with camera chip — always visible, not distracting
              // KO: 카메라 칩 오버레이 — 항상 노출, 시각적으로 방해되지 않게
              if (!isUploading)
                Container(
                  color: GBTColors.overlay.withValues(alpha: 0.18),
                  child: Center(
                    child: _CameraChip(label: hasImage ? '배경 변경' : '배경 추가'),
                  ),
                )
              else
                Container(
                  color: GBTColors.overlay.withValues(alpha: 0.45),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: GBTColors.textInverse,
                      ),
                    ),
                  ),
                ),

              // EN: Pending upload dot — top right
              // KO: 저장 대기 점 — 우상단
              if (hasPending && !isUploading)
                Positioned(
                  top: GBTSpacing.sm,
                  right: GBTSpacing.sm,
                  child: _PendingDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Camera chip — icon + label pill button on cover/avatar
// KO: 카메라 칩 — 커버/아바타 위 아이콘+라벨 필 버튼
// ========================================
class _CameraChip extends StatelessWidget {
  const _CameraChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: GBTColors.overlay.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.camera_alt_rounded,
            size: 13,
            color: GBTColors.textInverse,
          ),
          const SizedBox(width: GBTSpacing.xxs + 1),
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(
              color: GBTColors.textInverse,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Avatar settings-row tile — consistent with _SettingsRow pattern
// KO: 아바타 설정 행 타일 — _SettingsRow 패턴과 동일
// ========================================
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatarUrl,
    required this.isUploading,
    required this.hasPending,
    required this.onTap,
    required this.isDark,
    this.isLast = false,
  });

  final String? avatarUrl;
  final bool isUploading;
  final bool hasPending;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Semantics(
      button: true,
      label: '프로필 사진 변경',
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(GBTSpacing.radiusMd),
                bottomRight: Radius.circular(GBTSpacing.radiusMd),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GBTSpacing.md,
            vertical: GBTSpacing.sm + 4,
          ),
          child: Row(
            children: [
              // EN: Avatar thumbnail with loading/pending overlay
              // KO: 로딩/대기 오버레이가 있는 아바타 썸네일
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? GBTColors.darkSurfaceVariant
                          : GBTColors.surfaceVariant,
                    ),
                    child: hasImage
                        ? ClipOval(
                            child: GBTImage(
                              imageUrl: avatarUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              semanticLabel: '프로필 이미지',
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: textTertiary,
                          ),
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: GBTColors.overlay.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GBTColors.textInverse,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (hasPending && !isUploading)
                    Positioned(right: 0, bottom: 0, child: _PendingDot()),
                ],
              ),
              const SizedBox(width: GBTSpacing.md),
              // EN: Label column
              // KO: 레이블 컬럼
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프로필 사진',
                      style: GBTTypography.bodyMedium.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isUploading ? '업로드 중...' : '갤러리에서 변경',
                      style: GBTTypography.labelSmall.copyWith(
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// EN: Basic info card — name (inline) + bio (stacked), no visible borders
// KO: 기본 정보 카드 — 이름(인라인) + 소개(스택), 테두리 없는 입력
// ========================================
class _BasicInfoCard extends StatelessWidget {
  const _BasicInfoCard({
    required this.displayNameController,
    required this.bioController,
    required this.maxDisplayNameLength,
    required this.maxBioLength,
    required this.isDark,
  });

  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final int maxDisplayNameLength;
  final int maxBioLength;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? GBTColors.darkBorderSubtle
        : GBTColors.divider;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textSecondary = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final focusedColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return _SectionCard(
      child: Column(
        children: [
          // EN: Display name — label left, text field right (iOS-style inline)
          // KO: 표시 이름 — 왼쪽 라벨, 오른쪽 텍스트 필드 (iOS 스타일 인라인)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GBTSpacing.md,
              vertical: GBTSpacing.sm + 4,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    '표시 이름',
                    style: GBTTypography.bodyMedium.copyWith(
                      color: textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: displayNameController,
                    maxLength: maxDisplayNameLength,
                    textAlign: TextAlign.end,
                    textInputAction: TextInputAction.next,
                    style: GBTTypography.bodyMedium.copyWith(
                      color: textSecondary,
                    ),
                    decoration: InputDecoration(
                      hintText: '닉네임 입력',
                      hintStyle: GBTTypography.bodyMedium.copyWith(
                        color: textTertiary,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: focusedColor, width: 1.5),
                      ),
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: GBTSpacing.md, color: dividerColor),
          // EN: Bio — label + counter on top, multiline field below
          // KO: 소개 — 상단 라벨+카운터, 하단 멀티라인 필드
          Padding(
            padding: const EdgeInsets.all(GBTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '소개',
                      style: GBTTypography.bodyMedium.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: bioController,
                      builder: (context, _) => Text(
                        '${bioController.text.length}/$maxBioLength',
                        style: GBTTypography.labelSmall.copyWith(
                          color: textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GBTSpacing.xs2),
                TextField(
                  controller: bioController,
                  maxLength: maxBioLength,
                  maxLines: null,
                  minLines: 3,
                  style: GBTTypography.bodyMedium.copyWith(
                    color: textSecondary,
                  ),
                  decoration: InputDecoration(
                    hintText: '나를 간단히 소개해 보세요',
                    hintStyle: GBTTypography.bodyMedium.copyWith(
                      color: textTertiary,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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

// ========================================
// EN: Account info card — read-only rows matching _SettingsRow style
// KO: 계정 정보 카드 — _SettingsRow 스타일의 읽기 전용 행
// ========================================
class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.profile, required this.isDark});

  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? GBTColors.darkBorderSubtle
        : GBTColors.divider;

    return _SectionCard(
      child: Column(
        children: [
          _AccountInfoRow(
            icon: Icons.mail_outline_rounded,
            iconBgColor: GBTColors.accentBlue,
            label: '이메일',
            value: maskEmail(profile.email),
            isDark: isDark,
          ),
          Divider(
            height: 1,
            indent: GBTSpacing.md + 36 + GBTSpacing.md,
            endIndent: GBTSpacing.md,
            color: dividerColor,
          ),
          _AccountInfoRow(
            icon: Icons.verified_user_outlined,
            iconBgColor: GBTColors.success,
            label: '권한',
            value:
                '${profile.accountRole} · ${profile.effectiveAccessLevelLabel}',
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Account info row — mirrors _SettingsRow but without InkWell (read-only)
// KO: 계정 정보 행 — InkWell 없는 읽기 전용 _SettingsRow 미러
// ========================================
class _AccountInfoRow extends StatelessWidget {
  const _AccountInfoRow({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String value;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;
    final textTertiary = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.sm + 4,
      ),
      child: Row(
        children: [
          // EN: Gradient icon chip — same as _SettingsRow 36x36
          // KO: 그라디언트 아이콘 칩 — _SettingsRow 36x36과 동일
          GBTIconChip(icon: icon, color: iconBgColor, size: 36),
          const SizedBox(width: GBTSpacing.md),
          // EN: Label
          // KO: 라벨
          Text(
            label,
            style: GBTTypography.bodyMedium.copyWith(color: textPrimary),
          ),
          const Spacer(),
          // EN: Value (right-aligned, muted)
          // KO: 값 (우측 정렬, 회색 처리)
          Text(
            value,
            style: GBTTypography.bodySmall.copyWith(color: textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ========================================
// EN: Android in-app crop dialog — avoids native activity crashes while
//     preserving interactive crop UX.
// KO: Android 인앱 크롭 다이얼로그 — 네이티브 Activity 크래시를 피하면서
//     상호작용 크롭 UX를 유지합니다.
// ========================================
class _AndroidInAppCropDialog extends StatefulWidget {
  const _AndroidInAppCropDialog({
    required this.title,
    required this.imageBytes,
    required this.aspectRatio,
  });

  final String title;
  final Uint8List imageBytes;
  final double aspectRatio;

  @override
  State<_AndroidInAppCropDialog> createState() =>
      _AndroidInAppCropDialogState();
}

class _AndroidInAppCropDialogState extends State<_AndroidInAppCropDialog> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  void _startCrop() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GBTColors.darkSurface : GBTColors.surface;
    final border = isDark ? GBTColors.darkBorderSubtle : GBTColors.border;
    final textPrimary = isDark
        ? GBTColors.darkTextPrimary
        : GBTColors.textPrimary;

    return Dialog(
      backgroundColor: surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.76,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GBTSpacing.sm,
                GBTSpacing.sm,
                GBTSpacing.sm,
                GBTSpacing.xs,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isCropping
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GBTTypography.titleSmall.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isCropping ? null : _startCrop,
                    child: _isCropping
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('적용'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(GBTSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  child: Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    aspectRatio: widget.aspectRatio,
                    interactive: true,
                    fixCropRect: true,
                    radius: GBTSpacing.radiusSm,
                    baseColor: GBTColors.overlay,
                    maskColor: GBTColors.overlay.withValues(alpha: 0.55),
                    onStatusChanged: (status) {
                      if (!mounted) return;
                      if (status != CropStatus.cropping && _isCropping) {
                        setState(() => _isCropping = false);
                      }
                    },
                    onCropped: (result) {
                      if (!mounted) return;
                      switch (result) {
                        case CropSuccess(:final croppedImage):
                          Navigator.of(context).pop(croppedImage);
                        case CropFailure():
                          Navigator.of(context).pop(Uint8List(0));
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Pending dot — small orange indicator for unsaved uploads
// KO: 저장 대기 점 — 업로드 대기 중 주황색 인디케이터
// ========================================
class _PendingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GBTColors.warning,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? GBTColors.darkSurfaceElevated
              : GBTColors.surface,
          width: 1.5,
        ),
      ),
    );
  }
}

// ========================================
// EN: Profile load error state
// KO: 프로필 로드 오류 상태
// ========================================
class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: GBTSpacing.paddingPage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: GBTSpacing.xxl,
              color: GBTColors.error,
              semanticLabel: '오류 아이콘',
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              '프로필 정보를 불러오지 못했어요',
              style: GBTTypography.titleSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              '잠시 후 다시 시도해주세요',
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
            ),
            const SizedBox(height: GBTSpacing.lg),
            Semantics(
              button: true,
              label: '프로필 정보 다시 불러오기',
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EN: Login required state
// KO: 로그인 필요 상태
// ========================================
class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: GBTSpacing.paddingPage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: GBTSpacing.touchTarget,
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
              semanticLabel: '잠금 아이콘',
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              '로그인이 필요합니다',
              style: GBTTypography.titleSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              '프로필을 수정하려면 로그인해주세요.',
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GBTSpacing.lg),
            Semantics(
              button: true,
              label: '로그인 페이지로 이동',
              child: FilledButton(onPressed: onLogin, child: const Text('로그인')),
            ),
          ],
        ),
      ),
    );
  }
}
