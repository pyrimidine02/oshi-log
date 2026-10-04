/// EN: Place review sheet — polished bottom sheet for review + photo upload.
/// KO: 방문 후기 시트 — 후기 + 사진 업로드를 위한 세련된 바텀 시트.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/design_system/widgets/feedback/gbt_loading.dart';
import 'package:oshi_log/features/shared/uploads/application/uploads_controller.dart';
import 'package:oshi_log/features/shared/uploads/utils/webp_image_converter.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';

class PlaceReviewSheet extends ConsumerStatefulWidget {
  const PlaceReviewSheet({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<PlaceReviewSheet> createState() => _PlaceReviewSheetState();
}

class _PlaceReviewSheetState extends ConsumerState<PlaceReviewSheet> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  double _uploadProgress = 0;

  static const int _maxImages = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSubmit = !_isSubmitting && _controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? GBTColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GBTSpacing.radiusLg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: GBTSpacing.pageHorizontal,
          right: GBTSpacing.pageHorizontal,
          top: GBTSpacing.sm,
          bottom: bottomInset + GBTSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EN: Drag handle
            // KO: 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: GBTSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? GBTColors.darkBorder : GBTColors.border,
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
                ),
              ),
            ),

            // EN: Title row
            // KO: 타이틀 행
            Row(
              children: [
                Icon(
                  Icons.rate_review_rounded,
                  size: 24,
                  color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                ),
                const SizedBox(width: GBTSpacing.sm),
                Text(
                  context.l10n(
                    ko: '방문 후기 작성',
                    en: 'Write visit review',
                    ja: '訪問レビュー作成',
                  ),
                  style: GBTTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GBTSpacing.md),

            // EN: Text input with styled border
            // KO: 스타일된 테두리가 있는 텍스트 입력
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              enabled: !_isSubmitting,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.l10n(
                  ko: '이 장소에 대한 후기를 남겨주세요...',
                  en: 'Share your review for this place...',
                  ja: 'この場所のレビューを残してください...',
                ),
                hintStyle: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                ),
                filled: true,
                fillColor: isDark
                    ? GBTColors.darkSurfaceElevated
                    : GBTColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                  borderSide: BorderSide(
                    color: isDark ? GBTColors.darkPrimary : GBTColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(GBTSpacing.md),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: GBTSpacing.md),

            // EN: Photo section header
            // KO: 사진 섹션 헤더
            Row(
              children: [
                Text(
                  context.l10n(ko: '사진', en: 'Photos', ja: '写真'),
                  style: GBTTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? GBTColors.darkTextSecondary
                        : GBTColors.textSecondary,
                  ),
                ),
                const SizedBox(width: GBTSpacing.xs),
                Text(
                  '${_images.length}/$_maxImages',
                  style: GBTTypography.labelSmall.copyWith(
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
                  ),
                ),
                const Spacer(),
                if (_images.length < _maxImages)
                  TextButton.icon(
                    onPressed: _isSubmitting ? null : _pickImages,
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 20,
                    ),
                    label: Text(context.l10n(ko: '추가', en: 'Add', ja: '追加')),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GBTSpacing.sm,
                      ),
                    ),
                  ),
              ],
            ),

            // EN: Photo grid preview (actual image thumbnails)
            // KO: 사진 그리드 프리뷰 (실제 이미지 썸네일)
            if (_images.isNotEmpty) ...[
              const SizedBox(height: GBTSpacing.sm),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: GBTSpacing.sm),
                  itemBuilder: (context, index) {
                    return _ImageThumbnail(
                      file: _images[index],
                      isDark: isDark,
                      isSubmitting: _isSubmitting,
                      onRemove: () {
                        setState(() => _images.removeAt(index));
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: GBTSpacing.md),

            // EN: Error message
            // KO: 에러 메시지
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(GBTSpacing.sm),
                decoration: BoxDecoration(
                  color: GBTColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: GBTColors.error),
                    const SizedBox(width: GBTSpacing.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GBTTypography.bodySmall.copyWith(
                          color: GBTColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
            ],

            // EN: Submit button with progress
            // KO: 진행률이 있는 제출 버튼
            if (_isSubmitting)
              Column(
                children: [
                  if (_images.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        GBTSpacing.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? GBTColors.darkSurfaceVariant
                            : GBTColors.surfaceVariant,
                        color: isDark
                            ? GBTColors.darkPrimary
                            : GBTColors.primary,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.sm),
                  ],
                  GBTLoading(
                    message: context.l10n(
                      ko: '후기를 등록하는 중...',
                      en: 'Submitting review...',
                      ja: 'レビューを登録中...',
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    context.l10n(ko: '후기 등록', en: 'Post review', ja: 'レビュー投稿'),
                  ),
                ),
              ),

            const SizedBox(height: GBTSpacing.xs),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _uploadProgress = 0;
    });

    try {
      final uploadIds = await _uploadImages();
      final repository = await ref.read(placesRepositoryProvider.future);
      final result = await repository.createPlaceComment(
        placeId: widget.placeId,
        body: body,
        photoUploadIds: uploadIds,
        tags: const [],
        isPublic: true,
      );

      if (result case Err(:final failure)) {
        _handleFailure(failure);
        return;
      }

      await ref
          .read(placeCommentsControllerProvider(widget.placeId).notifier)
          .load(forceRefresh: true);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      _handleFailure(failure);
    } catch (_) {
      setState(() {
        _errorMessage = context.l10n(
          ko: '이미지 업로드에 실패했습니다.',
          en: 'Image upload failed.',
          ja: '画像アップロードに失敗しました。',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_images.isEmpty) return <String>[];
    final uploadController = ref.read(uploadsControllerProvider.notifier);
    final uploadIds = <String>[];

    for (var i = 0; i < _images.length; i++) {
      final image = _images[i];
      final payload = await convertToWebp(
        path: image.path,
        originalFilename: p.basename(image.path),
      );

      final uploadResult = await uploadController.uploadImageBytes(
        bytes: payload.bytes,
        filename: payload.filename,
        contentType: payload.contentType,
      );
      if (uploadResult case Err(:final failure)) {
        throw failure;
      }

      final upload = switch (uploadResult) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };

      uploadIds.add(upload.uploadId);

      // EN: Update progress
      // KO: 진행률 업데이트
      if (mounted) {
        setState(() {
          _uploadProgress = (i + 1) / _images.length;
        });
      }
    }

    return uploadIds;
  }

  void _handleFailure(Failure failure) {
    setState(() {
      if (failure is AuthFailure && failure.code == '403') {
        _errorMessage = context.l10n(
          ko: '아직 준비중입니다.',
          en: 'Coming soon.',
          ja: '準備中です。',
        );
      } else {
        _errorMessage = failure.userMessage;
      }
    });
  }
}

// ---------------------------------------------------------------------------
// EN: Image thumbnail with remove button
// KO: 제거 버튼이 있는 이미지 썸네일
// ---------------------------------------------------------------------------

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.file,
    required this.isDark,
    required this.isSubmitting,
    required this.onRemove,
  });

  final XFile file;
  final bool isDark;
  final bool isSubmitting;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // EN: Image preview
          // KO: 이미지 프리뷰
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
              child: Image.file(
                File(file.path),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? GBTColors.darkSurfaceVariant
                      : GBTColors.surfaceVariant,
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 24,
                    color: isDark
                        ? GBTColors.darkTextTertiary
                        : GBTColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          // EN: Remove button
          // KO: 제거 버튼
          if (!isSubmitting)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
