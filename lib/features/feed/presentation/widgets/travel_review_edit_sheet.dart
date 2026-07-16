/// EN: Minimal patch editor for an authored travel review.
/// KO: 본인이 작성한 여행 후기를 수정하는 간결한 패치 편집기입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../application/travel_reviews_controller.dart';
import '../../domain/entities/travel_review.dart';

class TravelReviewEditSheet extends ConsumerStatefulWidget {
  const TravelReviewEditSheet({
    super.key,
    required this.projectCode,
    required this.review,
  });

  final String projectCode;
  final TravelReviewDetail review;

  @override
  ConsumerState<TravelReviewEditSheet> createState() =>
      _TravelReviewEditSheetState();
}

class _TravelReviewEditSheetState extends ConsumerState<TravelReviewEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _routeNoteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.review.post.title);
    _contentController = TextEditingController(
      text: widget.review.post.content ?? '',
    );
    _routeNoteController = TextEditingController(
      text: widget.review.routeNote ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _routeNoteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }
    setState(() => _submitting = true);
    final result = await ref
        .read(travelReviewMutationControllerProvider.notifier)
        .update(
          projectCode: widget.projectCode,
          reviewId: widget.review.id,
          patch: TravelReviewPatch(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            routeNote: _routeNoteController.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTSpacing.md,
        0,
        GBTSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + GBTSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '여행 후기 수정',
              style: GBTTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            TextField(
              controller: _titleController,
              maxLength: 255,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: GBTSpacing.sm),
            TextField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              maxLength: 20000,
              decoration: const InputDecoration(
                labelText: '내용',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            TextField(
              controller: _routeNoteController,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: '동선 메모',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
