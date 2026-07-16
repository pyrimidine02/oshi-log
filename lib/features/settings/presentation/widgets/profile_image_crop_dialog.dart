/// EN: In-app Android image crop dialog used by profile media editing.
/// KO: 프로필 미디어 편집에서 사용하는 Android 인앱 이미지 자르기 다이얼로그입니다.
library;

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';

class ProfileImageCropDialog extends StatefulWidget {
  const ProfileImageCropDialog({
    super.key,
    required this.title,
    required this.imageBytes,
    required this.aspectRatio,
  });

  final String title;
  final Uint8List imageBytes;
  final double aspectRatio;

  @override
  State<ProfileImageCropDialog> createState() => _ProfileImageCropDialogState();
}

class _ProfileImageCropDialogState extends State<ProfileImageCropDialog> {
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
