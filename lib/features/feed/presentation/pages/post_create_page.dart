/// EN: Community post creation page.
/// KO: 커뮤니티 게시글 작성 페이지.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../fan_level/application/fan_level_controller.dart';
import '../../application/feed_controller.dart';
import '../../domain/entities/feed_entities.dart';
import '../../../projects/presentation/widgets/project_selector.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../uploads/application/uploads_controller.dart';
import '../../../uploads/domain/entities/upload_entity.dart';
import '../../../uploads/utils/webp_image_converter.dart';
import '../widgets/post_compose_components.dart';

/// EN: Community post creation page widget.
/// KO: 커뮤니티 게시글 작성 페이지 위젯.
class PostCreatePage extends ConsumerStatefulWidget {
  const PostCreatePage({super.key});

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  static const int _maxTitleLength = 60;
  static const int _maxContentLength = 3000;
  static const int _maxImageCount = 6;
  static const String _draftStorageKey = 'feed_post_create_draft_v1';

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final List<String> _selectedTags = [];
  final List<String> _topicOptions = <String>[];
  final List<String> _tagSuggestions = <String>[];
  late final PostComposeAutosaveConfig _autosaveConfig;
  late final PostComposeAutosaveController _autosaveController;
  bool _isSubmitting = false;
  bool _skipDraftSaveOnDispose = false;
  bool _isTaxonomyLoading = false;
  bool _taxonomyLoadFailed = false;
  Failure? _taxonomyFailure;
  String? _errorMessage;
  String? _selectedTopic;
  bool _lastCanSubmit = false;
  bool _lastHasDraft = false;

  bool get _hasDraft {
    return _titleController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        (_selectedTopic != null && _selectedTopic!.trim().isNotEmpty) ||
        _selectedTags.isNotEmpty;
  }

  bool get _canSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        !_isSubmitting;
  }

  int get _remainingImageSlots => _maxImageCount - _images.length;

  PostComposeAutosaveState get _autosaveState {
    return ref.read(postComposeAutosaveControllerProvider(_autosaveConfig));
  }

  @override
  void initState() {
    super.initState();
    _autosaveConfig = const PostComposeAutosaveConfig(
      storageKey: _draftStorageKey,
    );
    _autosaveController = ref.read(
      postComposeAutosaveControllerProvider(_autosaveConfig).notifier,
    );
    _titleController.addListener(_onFormChanged);
    _contentController.addListener(_onFormChanged);
    _lastCanSubmit = _canSubmit;
    _lastHasDraft = _hasDraft;

    unawaited(_autosaveController.loadRecoverableDraft());
    unawaited(_loadPostComposeOptions(forceRefresh: true));
  }

  @override
  void dispose() {
    if (!_isSubmitting && !_skipDraftSaveOnDispose) {
      unawaited(_saveDraftOnDisposeSafely());
    }
    _titleController.removeListener(_onFormChanged);
    _contentController.removeListener(_onFormChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDraftOnDisposeSafely() async {
    try {
      await _autosaveController.saveSnapshot(
        title: _titleController.text,
        content: _contentController.text,
        imagePaths: _images.map((image) => image.path).toList(growable: false),
        topic: _selectedTopic,
        tags: _selectedTags,
        hasData: _hasDraft,
        silent: true,
      );
    } on StateError {
      // EN: Ignore dispose-order races (e.g. tests disposing ProviderContainer first).
      // KO: dispose 순서 경합(예: 테스트에서 ProviderContainer 선해제)은 무시합니다.
    }
  }

  void _onFormChanged() {
    if (!mounted) {
      return;
    }
    _scheduleDraftSave();
    final nextCanSubmit = _canSubmit;
    final nextHasDraft = _hasDraft;
    if (nextCanSubmit == _lastCanSubmit && nextHasDraft == _lastHasDraft) {
      return;
    }
    setState(() {
      _lastCanSubmit = nextCanSubmit;
      _lastHasDraft = nextHasDraft;
    });
  }

  void _scheduleDraftSave() {
    if (_isSubmitting) {
      return;
    }
    _autosaveController.scheduleSave(
      title: _titleController.text,
      content: _contentController.text,
      imagePaths: _images.map((image) => image.path).toList(growable: false),
      topic: _selectedTopic,
      tags: _selectedTags,
      hasData: _hasDraft,
    );
  }

  void _restoreDraft() {
    final draft = _autosaveState.recoverableDraft;
    if (draft == null) {
      return;
    }

    final existingImagePaths = draft.imagePaths
        .where((path) => File(path).existsSync())
        .take(_maxImageCount)
        .toList(growable: false);

    setState(() {
      _titleController.text = draft.title;
      _contentController.text = draft.content;
      _images
        ..clear()
        ..addAll(existingImagePaths.map((path) => XFile(path)));
      _selectedTopic = draft.topic;
      _selectedTags
        ..clear()
        ..addAll(sanitizePostTags(draft.tags));
    });
    _autosaveController.consumeRecoverableDraft(message: '임시 저장 글을 복구했어요');

    _scheduleDraftSave();
    _showMessage('임시 저장 글을 복구했어요.');
  }

  Future<void> _discardRecoverableDraft() async {
    await _autosaveController.clearSavedDraft(silent: true);
    _showMessage('임시 저장 글을 삭제했어요.');
  }

  Future<bool> _handleWillPop() async {
    if (_isSubmitting) {
      return false;
    }
    if (!_hasDraft) {
      return true;
    }

    final shouldDiscard = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: '작성 중인 내용을 나갈까요?',
      message: '현재 입력 내용은 임시 저장되어 다음에 복구할 수 있어요.',
      confirmLabel: '나가기',
      cancelLabel: '계속 작성',
    );

    return shouldDiscard ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _orderedOptionNames(List<PostTaxonomyOption> options) {
    return options
        .map((option) => option.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadPostComposeOptions({bool forceRefresh = false}) async {
    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }

    setState(() {
      _isTaxonomyLoading = true;
    });

    Result<PostComposeOptions> result;
    try {
      final repository = await ref.read(feedRepositoryProvider.future);
      result = await repository.getPostComposeOptions(
        forceRefresh: forceRefresh,
      );
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTaxonomyLoading = false;
        _taxonomyLoadFailed = true;
        _taxonomyFailure = ErrorHandler.mapException(error, stackTrace);
      });
      return;
    }
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<PostComposeOptions>(:final data):
        final topics = _orderedOptionNames(data.topics);
        final tags = _orderedOptionNames(data.tags);
        setState(() {
          _topicOptions
            ..clear()
            ..addAll(topics);
          _tagSuggestions
            ..clear()
            ..addAll(tags);
          _isTaxonomyLoading = false;
          _taxonomyLoadFailed = false;
          _taxonomyFailure = null;
        });
      case Err<PostComposeOptions>(:final failure):
        setState(() {
          _isTaxonomyLoading = false;
          _taxonomyLoadFailed = true;
          _taxonomyFailure = failure;
        });
    }
  }

  bool get _shouldShowTaxonomyLoginAction {
    final failure = _taxonomyFailure;
    if (failure is! AuthFailure) {
      return false;
    }
    return failure.code == '401' || failure.code == 'auth_required';
  }

  bool get _canOpenTopicPicker {
    if (_isSubmitting || _isTaxonomyLoading) {
      return false;
    }
    return _topicOptions.isNotEmpty;
  }

  bool get _canOpenTagPicker {
    if (_isSubmitting || _isTaxonomyLoading) {
      return false;
    }
    return _tagSuggestions.isNotEmpty;
  }

  String? get _taxonomyStatusMessage {
    if (_isTaxonomyLoading) {
      return '토픽/태그 목록을 불러오는 중입니다.';
    }

    if (_taxonomyLoadFailed) {
      final failure = _taxonomyFailure;
      if (failure is AuthFailure) {
        switch (failure.code) {
          case '401':
          case 'auth_required':
            return '로그인이 만료되었습니다. 다시 로그인해주세요.';
          case '403':
            return '토픽/태그 목록 조회 권한이 없습니다.';
        }
      }
      return '토픽/태그 목록을 불러오지 못했습니다.';
    }

    if (_topicOptions.isEmpty && _tagSuggestions.isEmpty) {
      return '현재 선택 가능한 토픽/태그가 없습니다.';
    }

    if (_topicOptions.isEmpty) {
      return '현재 선택 가능한 토픽이 없습니다.';
    }

    if (_tagSuggestions.isEmpty) {
      return '현재 선택 가능한 태그가 없습니다.';
    }

    return null;
  }

  Future<void> _handleCancelPressed() async {
    if (_isSubmitting) return;
    final shouldPop = await _handleWillPop();
    if (!mounted || !shouldPop) return;
    Navigator.of(context).pop();
  }

  Future<void> _openDraftShelf(PostComposeAutosaveState autosaveState) async {
    final recoverableDraft = autosaveState.recoverableDraft;
    if (recoverableDraft == null) {
      _showMessage('복구 가능한 임시 저장 글이 없습니다.');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('임시 저장 글 복구'),
                subtitle: Text(
                  '${recoverableDraft.savedAt.toLocal()}',
                  style: GBTTypography.labelSmall,
                ),
                onTap: () => Navigator.of(sheetContext).pop('restore'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('임시 저장 글 삭제'),
                onTap: () => Navigator.of(sheetContext).pop('discard'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'restore') {
      _restoreDraft();
      return;
    }
    if (action == 'discard') {
      await _discardRecoverableDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final autosaveState = ref.watch(
      postComposeAutosaveControllerProvider(_autosaveConfig),
    );

    return PopScope<Object?>(
      canPop: !_isSubmitting && !_hasDraft,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _handleWillPop();
        if (!mounted || !shouldPop) {
          return;
        }
        Navigator.of(this.context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: gbtStandardAppBar(
          context,
          title: '작성',
          leading: IconButton(
            onPressed: _isSubmitting ? null : _handleCancelPressed,
            icon: const Icon(Icons.close_rounded),
            tooltip: '작성 취소',
          ),
          actions: [
            IconButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _openDraftShelf(autosaveState),
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: '임시 보관함',
            ),
            Padding(
              padding: const EdgeInsets.only(right: GBTSpacing.xs),
              child: FilledButton(
                key: const ValueKey('post-compose-submit'),
                onPressed: _canSubmit ? () => _submit(context) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(56, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                  ),
                ),
                child: Text(
                  _isSubmitting ? '게시 중' : '게시',
                  style: GBTTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: isAuthenticated
            ? _buildForm(context, autosaveState: autosaveState)
            : const PostComposeLoginRequiredMessage(),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required PostComposeAutosaveState autosaveState,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final profile = ref.watch(userProfileControllerProvider).valueOrNull;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    GBTSpacing.md,
                    GBTSpacing.md,
                    GBTSpacing.md,
                  ),
                  children: [
                    const GBTPageHeader(
                      eyebrow: 'COMMUNITY NOTE',
                      title: '새 여행 기록',
                      description: '성지와 공연에서 발견한 순간을 나만의 필드 노트로 남겨보세요.',
                      padding: EdgeInsets.only(bottom: GBTSpacing.md),
                    ),
                    const SizedBox(height: GBTSpacing.md),
                    if (autosaveState.recoverableDraft != null) ...[
                      PostComposeDraftRecoveryBanner(
                        savedAt: autosaveState.recoverableDraft!.savedAt,
                        projectCode:
                            autosaveState.recoverableDraft!.projectCode,
                        onRestore: _restoreDraft,
                        onDiscard: _discardRecoverableDraft,
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                    ],
                    if (autosaveState.autosaveMessage != null) ...[
                      Text(
                        autosaveState.autosaveMessage!,
                        style: GBTTypography.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: GBTSpacing.sm),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ComposerAvatar(url: profile?.avatarUrl),
                        const SizedBox(width: GBTSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: GBTSpacing.touchTarget,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ProjectAudienceSelectorCompact(),
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.xs),
                              PostTopicTagSelector(
                                selectedTopic: _selectedTopic,
                                selectedTags: _selectedTags,
                                onTapTopic: _canOpenTopicPicker
                                    ? _handleTopicTap
                                    : null,
                                onTapAddTag: _canOpenTagPicker
                                    ? _handleTagAddTap
                                    : null,
                                onRemoveTag: _isSubmitting ? null : _removeTag,
                              ),
                              if (_taxonomyStatusMessage != null) ...[
                                const SizedBox(height: GBTSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _taxonomyStatusMessage!,
                                        style: GBTTypography.labelSmall
                                            .copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    if (_taxonomyLoadFailed)
                                      TextButton(
                                        onPressed: _isTaxonomyLoading
                                            ? null
                                            : () => unawaited(
                                                _loadPostComposeOptions(
                                                  forceRefresh: true,
                                                ),
                                              ),
                                        child: const Text('다시 시도'),
                                      ),
                                    if (_taxonomyLoadFailed &&
                                        _shouldShowTaxonomyLoginAction)
                                      TextButton(
                                        onPressed: () => context.go('/login'),
                                        child: const Text('로그인'),
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: GBTSpacing.xs),
                              TextField(
                                controller: _titleController,
                                focusNode: _titleFocusNode,
                                autofocus: true,
                                maxLength: _maxTitleLength,
                                maxLines: 1,
                                textInputAction: TextInputAction.next,
                                style: GBTTypography.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: '제목을 입력해주세요',
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: GBTTypography.headlineMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              const SizedBox(height: GBTSpacing.md),
                              TextField(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                maxLength: _maxContentLength,
                                maxLines: null,
                                minLines: 8,
                                textInputAction: TextInputAction.newline,
                                style: GBTTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 1.6,
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      '커뮤니티 이용규칙을 지켜주세요.\n'
                                      '광고, 비방, 도배성 글은 제재될 수 있어요.',
                                  hintStyle: GBTTypography.bodyLarge.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _images.isNotEmpty
                          ? Column(
                              children: [
                                const SizedBox(height: GBTSpacing.sm),
                                SizedBox(
                                  height: 92,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: GBTSpacing.sm),
                                    itemBuilder: (context, index) {
                                      final image = _images[index];
                                      return _ComposerLocalImageTile(
                                        imagePath: image.path,
                                        onPreview: () => _previewImage(image),
                                        onRemove: _isSubmitting
                                            ? null
                                            : () {
                                                setState(() {
                                                  _images.removeAt(index);
                                                });
                                                _scheduleDraftSave();
                                              },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: GBTSpacing.sm),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(GBTSpacing.sm),
                          decoration: BoxDecoration(
                            color: GBTColors.errorLight,
                            borderRadius: BorderRadius.circular(
                              GBTSpacing.radiusSm,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GBTTypography.bodySmall.copyWith(
                              color: GBTColors.errorDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: GBTSpacing.lg),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? GBTColors.darkBorderSubtle
                            : GBTColors.border,
                        width: 0.8,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    GBTSpacing.xs,
                    GBTSpacing.md,
                    GBTSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      _ComposerToolbarIconButton(
                        icon: Icons.image_outlined,
                        onTap: _isSubmitting ? null : _pickFromGallery,
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      _ComposerToolbarIconButton(
                        icon: Icons.camera_alt_outlined,
                        onTap: _isSubmitting ? null : _pickFromCamera,
                      ),
                      const SizedBox(width: GBTSpacing.xs),
                      _ComposerToolbarIconButton(
                        icon: Icons.gif_box_outlined,
                        onTap: _isSubmitting ? null : _pickGif,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black.withValues(alpha: 0.22),
            child: const Center(child: GBTLoading(message: '게시글을 등록하는 중...')),
          ),
      ],
    );
  }

  void _previewImage(XFile image) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(GBTSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          '이미지를 표시할 수 없습니다',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: GBTSpacing.xs,
                  top: GBTSpacing.xs,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTopicTap() async {
    if (_isTaxonomyLoading) {
      _showMessage('토픽/태그 목록을 불러오는 중입니다.');
      return;
    }
    if (_topicOptions.isEmpty) {
      _showMessage('선택 가능한 토픽이 없습니다.');
      return;
    }

    final selected = await showPostTopicPickerSheet(
      context,
      selectedTopic: _selectedTopic,
      options: _topicOptions,
    );
    if (!mounted || selected == null) {
      return;
    }
    final normalized = selected.trim().isEmpty ? null : selected.trim();
    if (normalized == _selectedTopic) {
      return;
    }
    setState(() {
      _selectedTopic = normalized;
    });
    _scheduleDraftSave();
  }

  Future<void> _handleTagAddTap() async {
    if (_selectedTags.length >= kPostMaxTagCount) {
      _showMessage('태그는 최대 $kPostMaxTagCount개까지 추가할 수 있어요.');
      return;
    }
    if (_isTaxonomyLoading) {
      _showMessage('토픽/태그 목록을 불러오는 중입니다.');
      return;
    }
    if (_tagSuggestions.isEmpty) {
      _showMessage('선택 가능한 태그가 없습니다.');
      return;
    }
    final selected = await showPostTagPickerSheet(
      context,
      selectedTags: _selectedTags,
      suggestions: _tagSuggestions,
    );
    if (!mounted || selected == null) {
      return;
    }
    final normalized = normalizePostTag(selected);
    if (normalized.isEmpty) {
      return;
    }
    final exists = _selectedTags.any(
      (tag) => tag.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) {
      _showMessage('이미 선택된 태그예요.');
      return;
    }
    setState(() {
      _selectedTags.add(normalized);
    });
    _scheduleDraftSave();
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    _scheduleDraftSave();
  }

  Future<void> _submit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요')));
      return;
    }

    final projectCode = ref.read(selectedProjectKeyProvider);
    if (projectCode == null || projectCode.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('프로젝트를 먼저 선택해주세요')));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var imageUploadIds = const <String>[];
    var imageUrls = const <String>[];
    if (_images.isNotEmpty) {
      try {
        final uploads = await _uploadImages();
        // EN: Collect both IDs (for the server) and URLs (for markdown embed).
        // KO: 서버용 ID와 마크다운 삽입용 URL을 모두 수집합니다.
        imageUploadIds = uploads
            .map((upload) => upload.uploadId)
            .where((uploadId) => uploadId.isNotEmpty)
            .toList();
        imageUrls = uploads
            .map((upload) => upload.url)
            .where((url) => url.isNotEmpty)
            .toList();
      } on Failure catch (failure) {
        setState(() {
          _errorMessage = failure.userMessage;
          _isSubmitting = false;
        });
        return;
      } catch (_) {
        setState(() {
          _errorMessage = '이미지 업로드에 실패했습니다.';
          _isSubmitting = false;
        });
        return;
      }
    }
    final contentWithImages = appendImageMarkdownContent(content, imageUrls);

    final repository = await ref.read(feedRepositoryProvider.future);
    final normalizedTags = sanitizePostTags(_selectedTags);
    final result = await repository.createPost(
      projectCode: projectCode,
      title: title,
      content: contentWithImages,
      imageUploadIds: imageUploadIds,
      topic: _selectedTopic,
      tags: normalizedTags,
    );

    if (!mounted) {
      return;
    }

    if (result case Success<PostDetail>(:final data)) {
      final category =
          (_selectedTopic != null && _selectedTopic!.trim().isNotEmpty)
          ? _selectedTopic!.trim()
          : 'general';
      unawaited(ref.read(analyticsServiceProvider).logPostCreate(category));
      // EN: Earn XP for post creation and refresh fan level profile.
      // KO: 게시글 작성 XP를 획득하고 팬 레벨 프로필을 갱신합니다.
      unawaited(
        ref
            .read(fanLevelRepositoryProvider)
            .earnXp('POST_CREATED', data.id, projectId: projectCode)
            .then((_) => ref.invalidate(fanLevelControllerProvider)),
      );
      await Future.wait([
        ref
            .read(communityFeedControllerProvider.notifier)
            .reload(forceRefresh: true),
        ref.read(postListControllerProvider.notifier).load(forceRefresh: true),
      ]);
      await _autosaveController.clearSavedDraft(silent: true);
      _skipDraftSaveOnDispose = true;
      if (!mounted) {
        return;
      }
      router.pushReplacementNamed(
        AppRoutes.postDetail,
        pathParameters: {'postId': data.id},
      );
      return;
    } else if (result case Err<PostDetail>(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _pickFromGallery() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('이미지는 최대 $_maxImageCount장까지 첨부할 수 있어요.');
      return;
    }

    try {
      final picked = await _picker.pickMultiImage(
        maxHeight: 2160,
        maxWidth: 2160,
        imageQuality: 92,
      );

      if (picked.isEmpty || !mounted) {
        return;
      }

      _appendPickedImages(picked);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('갤러리를 열지 못했어요.');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('이미지는 최대 $_maxImageCount장까지 첨부할 수 있어요.');
      return;
    }

    if (!_picker.supportsImageSource(ImageSource.camera)) {
      _showMessage('이 기기에서는 카메라를 사용할 수 없어요.');
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 2160,
        maxWidth: 2160,
        imageQuality: 92,
      );

      if (picked == null || !mounted) {
        return;
      }

      _appendPickedImages([picked]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('카메라를 열지 못했어요.');
    }
  }

  /// EN: Pick GIF files from the file system and append to the image list.
  /// KO: 파일 시스템에서 GIF 파일을 선택하여 이미지 목록에 추가합니다.
  Future<void> _pickGif() async {
    if (_remainingImageSlots <= 0) {
      _showMessage('이미지는 최대 $_maxImageCount장까지 첨부할 수 있어요.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      // EN: Preserve original filename (f.name) so .gif extension is
      // reliably detected even if the temp path has no extension.
      // KO: 임시 경로에 확장자가 없는 경우에도 .gif 감지를 위해
      // 원본 파일명(f.name)을 유지합니다.
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => XFile(f.path!, name: f.name))
          .toList();
      _appendPickedImages(files);
    } catch (_) {
      if (!mounted) return;
      _showMessage('GIF 파일을 열지 못했어요.');
    }
  }

  void _appendPickedImages(List<XFile> picked) {
    final existingPaths = _images.map((image) => image.path).toSet();
    final uniquePicked = <XFile>[];
    for (final image in picked) {
      if (existingPaths.add(image.path)) {
        uniquePicked.add(image);
      }
    }

    if (uniquePicked.isEmpty) {
      _showMessage('이미 추가된 사진입니다.');
      return;
    }

    final addable = uniquePicked.take(_remainingImageSlots).toList();
    final droppedCount = uniquePicked.length - addable.length;

    setState(() {
      _images.addAll(addable);
    });
    _scheduleDraftSave();

    if (droppedCount > 0) {
      _showMessage('$_maxImageCount장까지만 첨부할 수 있어요.');
    }
  }

  Future<List<UploadInfo>> _uploadImages() async {
    if (_images.isEmpty) return const [];

    final uploadController = ref.read(uploadsControllerProvider.notifier);
    final uploads = <UploadInfo>[];

    for (final image in _images) {
      // EN: Use image.name so the original filename (including .gif extension
      // from file_picker) is preserved for MIME-type detection.
      // KO: file_picker 원본 파일명(.gif 확장자 포함)을 MIME 타입 감지에 사용합니다.
      final originalFilename = image.name.isNotEmpty
          ? image.name
          : p.basename(image.path);
      final payload = await convertToWebp(
        path: image.path,
        originalFilename: originalFilename,
        // EN: Force JPEG on Android to keep feed thumbnail generation stable.
        // KO: 안드로이드에서는 피드 썸네일 생성 안정화를 위해 JPEG로 강제합니다.
        forceJpeg: Platform.isAndroid,
      );

      final uploadResult = await uploadController.uploadImageBytes(
        bytes: payload.bytes,
        filename: payload.filename,
        contentType: payload.contentType,
      );

      final upload = switch (uploadResult) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };

      // EN: Keep uploadId even when URL is temporarily empty so the backend
      // can still derive summary thumbnail/image from imageUploadIds.
      // KO: URL이 일시적으로 비어 있어도 imageUploadIds 기반 썸네일/이미지
      // 파생을 위해 uploadId는 유지합니다.
      if (upload.uploadId.isNotEmpty) {
        uploads.add(upload);
      }
    }

    return _hydrateUploadUrlsFromMyUploads(uploads, uploadController);
  }

  Future<List<UploadInfo>> _hydrateUploadUrlsFromMyUploads(
    List<UploadInfo> uploads,
    UploadsController uploadController,
  ) async {
    if (uploads.isEmpty) {
      return const [];
    }

    var resolved = List<UploadInfo>.from(uploads);
    if (resolved.every((upload) => upload.url.isNotEmpty)) {
      return resolved;
    }

    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt += 1) {
      if (resolved.every((upload) => upload.url.isNotEmpty)) {
        break;
      }
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }

      await uploadController.load(forceRefresh: true);
      final latestUploads = ref.read(uploadsControllerProvider).valueOrNull;
      if (latestUploads == null || latestUploads.isEmpty) {
        continue;
      }

      final latestById = <String, UploadInfo>{
        for (final item in latestUploads)
          if (item.uploadId.isNotEmpty) item.uploadId: item,
      };
      resolved = resolved
          .map((upload) {
            if (upload.url.isNotEmpty || upload.uploadId.isEmpty) {
              return upload;
            }
            final latest = latestById[upload.uploadId];
            if (latest == null || latest.url.isEmpty) {
              return upload;
            }
            return UploadInfo(
              uploadId: upload.uploadId,
              url: latest.url,
              filename: latest.filename.isNotEmpty
                  ? latest.filename
                  : upload.filename,
              isApproved: latest.isApproved,
            );
          })
          .toList(growable: false);
    }

    final unresolved = resolved.where((upload) => upload.url.isEmpty).length;
    if (unresolved > 0) {
      AppLogger.warning(
        'Some uploaded image URLs are unresolved after retries',
        tag: 'PostCreatePage',
        data: {'total': resolved.length, 'unresolved': unresolved},
      );
    }
    return resolved;
  }
}

/// EN: Composer avatar shown at the beginning of create/edit text area.
/// KO: 작성/수정 입력 영역 시작점에 표시되는 작성자 아바타입니다.
class _ComposerAvatar extends StatelessWidget {
  const _ComposerAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedUrl = (url == null || url!.isEmpty)
        ? null
        : resolveMediaUrl(url!);
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: resolvedUrl == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                ),
                child: Icon(
                  Icons.person,
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                ),
              )
            : GBTImage(imageUrl: resolvedUrl, fit: BoxFit.cover),
      ),
    );
  }
}

/// EN: Compact icon button used in the composer toolbar.
/// KO: 작성 툴바에서 사용하는 컴팩트 아이콘 버튼입니다.
class _ComposerToolbarIconButton extends StatelessWidget {
  const _ComposerToolbarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;

    return SizedBox(
      width: GBTSpacing.touchTarget,
      height: GBTSpacing.touchTarget,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 22,
          color: iconColor.withValues(alpha: onTap == null ? 0.42 : 1),
        ),
      ),
    );
  }
}

/// EN: Horizontal local-image preview tile for compose timeline style.
/// KO: 타임라인 스타일 작성 화면의 가로형 로컬 이미지 미리보기 타일입니다.
class _ComposerLocalImageTile extends StatelessWidget {
  const _ComposerLocalImageTile({
    required this.imagePath,
    required this.onPreview,
    this.onRemove,
  });

  final String imagePath;
  final VoidCallback onPreview;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? GBTColors.darkSurfaceVariant
                            : GBTColors.surfaceVariant,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark
                              ? GBTColors.darkTextTertiary
                              : GBTColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: GBTSpacing.touchTarget,
                height: GBTSpacing.touchTarget,
                child: IconButton.filled(
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.56),
                  ),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white,
                  tooltip: '삭제',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
