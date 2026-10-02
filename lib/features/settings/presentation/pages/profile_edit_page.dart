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
      title: context.l10n(
        ko: '저장하지 않고 나갈까요?',
        en: 'Leave without saving?',
        ja: '保存せずに終了しますか？',
      ),
      message: context.l10n(
        ko: '프로필 변경 사항이 사라집니다.',
        en: 'Your profile changes will be lost.',
        ja: 'プロフィールの変更内容が失われます。',
      ),
      confirmLabel: context.l10n(ko: '나가기', en: 'Leave', ja: '終了する'),
      cancelLabel: context.l10n(ko: '계속 수정', en: 'Keep editing', ja: '編集を続ける'),
    );
    return shouldDiscard ?? false;
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _normalizeOptional(_bioController.text);
    if (displayName.isEmpty) {
      _showMessage(
        context.l10n(
          ko: '표시 이름을 입력해주세요',
          en: 'Please enter a display name.',
          ja: '表示名を入力してください。',
        ),
      );
      return;
    }
    if (!_hasPendingChanges) {
      _showMessage(
        context.l10n(
          ko: '변경된 내용이 없어요',
          en: 'No changes to save.',
          ja: '変更内容がありません。',
        ),
      );
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
      _showMessage(
        context.l10n(
          ko: '프로필이 저장되었습니다',
          en: 'Profile saved.',
          ja: 'プロフィールを保存しました。',
        ),
      );
      context.pop();
      return;
    }
    _showMessage(
      context.l10n(
        ko: '프로필 저장에 실패했습니다',
        en: 'Failed to save profile.',
        ja: 'プロフィールの保存に失敗しました。',
      ),
    );
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
                label: _isSaving
                    ? context.l10n(ko: '저장 중', en: 'Saving', ja: '保存中')
                    : context.l10n(
                        ko: '프로필 저장',
                        en: 'Save profile',
                        ja: 'プロフィールを保存する',
                      ),
                enabled: _canSaveProfile,
                child: Padding(
                  padding: const EdgeInsets.only(right: GBTSpacing.xs),
                  child: TextButton(
                    onPressed: _canSaveProfile ? _saveProfile : null,
                    child: Text(
                      _isSaving
                          ? context.l10n(ko: '저장 중', en: 'Saving', ja: '保存中')
                          : context.l10n(ko: '저장', en: 'Save', ja: '保存する'),
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
                ? context.l10n(
                    ko: '프로필 저장 중...',
                    en: 'Saving profile...',
                    ja: 'プロフィールを保存しています...',
                  )
                : _isChangingAvatar
                ? context.l10n(
                    ko: '프로필 사진 선택 중...',
                    en: 'Choosing profile photo...',
                    ja: 'プロフィール写真を選択しています...',
                  )
                : _isChangingCover
                ? context.l10n(
                    ko: '배경 이미지 선택 중...',
                    en: 'Choosing cover image...',
                    ja: '背景画像を選択しています...',
                  )
                : _isUploadingAvatar
                ? context.l10n(
                    ko: '프로필 사진 업로드 중...',
                    en: 'Uploading profile photo...',
                    ja: 'プロフィール写真をアップロードしています...',
                  )
                : _isUploadingCover
                ? context.l10n(
                    ko: '배경 이미지 업로드 중...',
                    en: 'Uploading cover image...',
                    ja: '背景画像をアップロードしています...',
                  )
                : null,
            child: state.when(
              loading: () => GBTLoading(
                message: context.l10n(
                  ko: '프로필을 불러오는 중...',
                  en: 'Loading profile...',
                  ja: 'プロフィールを読み込んでいます...',
                ),
              ),
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
      if (!mounted) return null;
      if (sourceBytes.isEmpty) {
        _showMessage(
          context.l10n(
            ko: '사진을 불러오지 못했습니다.',
            en: 'Failed to load the photo.',
            ja: '写真を読み込めませんでした。',
          ),
        );
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
      if (!mounted) return null;
      if (croppedBytes.isEmpty) {
        _showMessage(
          context.l10n(
            ko: '사진 편집에 실패했습니다.',
            en: 'Failed to edit the photo.',
            ja: '写真の編集に失敗しました。',
          ),
        );
        return null;
      }

      final ext = p.extension(sourcePath).toLowerCase();
      final outputExt = ext == '.png' ? '.png' : '.jpg';
      final dir = await Directory.systemTemp.createTemp('gbt_profile_crop_');
      final file = File(p.join(dir.path, 'cropped$outputExt'));
      await file.writeAsBytes(croppedBytes, flush: true);
      return file.path;
    } catch (_) {
      if (!mounted) return null;
      _showMessage(
        context.l10n(
          ko: '사진 편집에 실패했습니다.',
          en: 'Failed to edit the photo.',
          ja: '写真の編集に失敗しました。',
        ),
      );
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
      if (!mounted) return null;
      _showMessage(
        context.l10n(
          ko: '사진 편집에 실패했습니다.',
          en: 'Failed to edit the photo.',
          ja: '写真の編集に失敗しました。',
        ),
      );
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
      if (!mounted) return;

      final uploadSourcePath = await _cropImageForUpload(
        sourcePath: picked.path,
        title: context.l10n(
          ko: '프로필 사진 자르기',
          en: 'Crop profile photo',
          ja: 'プロフィール写真をトリミング',
        ),
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
        if (!mounted) return;
        if (upload.url.isEmpty) {
          _showMessage(
            context.l10n(
              ko: '업로드 정보를 가져오지 못했습니다.',
              en: 'Failed to get upload information.',
              ja: 'アップロード情報を取得できませんでした。',
            ),
          );
          return;
        }
        setState(() => _pendingAvatarUrl = upload.url);
        _showMessage(
          context.l10n(
            ko: '사진이 업로드되었습니다. 저장을 눌러 반영하세요.',
            en: 'Photo uploaded. Tap save to apply it.',
            ja: '写真をアップロードしました。保存を押して反映してください。',
          ),
        );
      } on Failure catch (failure) {
        _handleUploadFailure(failure);
      } catch (_) {
        if (!mounted) return;
        _showMessage(
          context.l10n(
            ko: '사진 업로드에 실패했습니다.',
            en: 'Failed to upload the photo.',
            ja: '写真のアップロードに失敗しました。',
          ),
        );
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
      if (!mounted) return;

      final uploadSourcePath = await _cropImageForUpload(
        sourcePath: picked.path,
        title: context.l10n(
          ko: '배경 이미지 자르기',
          en: 'Crop cover image',
          ja: '背景画像をトリミング',
        ),
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
        if (!mounted) return;
        if (upload.url.isEmpty) {
          _showMessage(
            context.l10n(
              ko: '업로드 정보를 가져오지 못했습니다.',
              en: 'Failed to get upload information.',
              ja: 'アップロード情報を取得できませんでした。',
            ),
          );
          return;
        }
        setState(() => _pendingCoverUrl = upload.url);
        _showMessage(
          context.l10n(
            ko: '배경 이미지가 업로드되었습니다. 저장을 눌러 반영하세요.',
            en: 'Cover image uploaded. Tap save to apply it.',
            ja: '背景画像をアップロードしました。保存を押して反映してください。',
          ),
        );
      } on Failure catch (failure) {
        _handleUploadFailure(failure);
      } catch (_) {
        if (!mounted) return;
        _showMessage(
          context.l10n(
            ko: '배경 이미지 업로드에 실패했습니다.',
            en: 'Failed to upload the cover image.',
            ja: '背景画像のアップロードに失敗しました。',
          ),
        );
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
        ? context.l10n(
            ko: '아직 준비중입니다.',
            en: 'This feature is not available yet.',
            ja: 'この機能は準備中です。',
          )
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
              semanticLabel: context.l10n(
                ko: '오류 아이콘',
                en: 'Error icon',
                ja: 'エラーアイコン',
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              context.l10n(
                ko: '프로필 정보를 불러오지 못했어요',
                en: 'Failed to load profile information.',
                ja: 'プロフィール情報を読み込めませんでした。',
              ),
              style: GBTTypography.titleSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '잠시 후 다시 시도해주세요',
                en: 'Please try again in a moment.',
                ja: 'しばらくしてからもう一度お試しください。',
              ),
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
            ),
            const SizedBox(height: GBTSpacing.lg),
            Semantics(
              button: true,
              label: context.l10n(
                ko: '프로필 정보 다시 불러오기',
                en: 'Reload profile information',
                ja: 'プロフィール情報を再読み込み',
              ),
              child: FilledButton(
                onPressed: onRetry,
                child: Text(
                  context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行する'),
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
              semanticLabel: context.l10n(
                ko: '잠금 아이콘',
                en: 'Lock icon',
                ja: 'ロックアイコン',
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              context.l10n(
                ko: '로그인이 필요합니다',
                en: 'Sign-in required',
                ja: 'ログインが必要です',
              ),
              style: GBTTypography.titleSmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Text(
              context.l10n(
                ko: '프로필을 수정하려면 로그인해주세요.',
                en: 'Please sign in to edit your profile.',
                ja: 'プロフィールを編集するにはログインしてください。',
              ),
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
              label: context.l10n(
                ko: '로그인 페이지로 이동',
                en: 'Go to sign-in page',
                ja: 'ログインページへ移動',
              ),
              child: FilledButton(
                onPressed: onLogin,
                child: Text(
                  context.l10n(ko: '로그인', en: 'Sign in', ja: 'ログインする'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
