/// EN: Profile edit page using the passport-inspired field identity document.
/// KO: 여권 모티프의 필드 신원 정보 문서를 사용하는 프로필 편집 페이지입니다.
library;

import 'dart:io';

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
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../uploads/application/uploads_controller.dart';
import '../../../uploads/utils/webp_image_converter.dart';
import '../../application/settings_controller.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_edit_identity_document.dart';
import '../widgets/profile_image_crop_dialog.dart';

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
        builder: (_) => ProfileImageCropDialog(
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
// EN: Profile form adapter for the passport-inspired identity document.
// KO: 여권 모티프 신원 정보 문서를 연결하는 프로필 폼 어댑터입니다.
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
    final joinedDate = profile.createdAt
        .toLocal()
        .toIso8601String()
        .split('T')
        .first;
    return ProfileEditIdentityDocument(
      onRefresh: onRefresh,
      displayNameController: displayNameController,
      bioController: bioController,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      maxDisplayNameLength: maxDisplayNameLength,
      maxBioLength: maxBioLength,
      maskedEmail: maskEmail(profile.email),
      accessLabel:
          '${profile.accountRole} / ${profile.effectiveAccessLevelLabel}',
      memberSinceLabel: joinedDate,
      hasPendingAvatar: hasPendingAvatar,
      hasPendingCover: hasPendingCover,
      isUploadingAvatar: isUploadingAvatar,
      isUploadingCover: isUploadingCover,
      onChangeAvatar: onChangeAvatar,
      onChangeCover: onChangeCover,
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
