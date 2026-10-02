/// EN: Minimal patch editor for an authored travel review.
/// KO: 본인이 작성한 여행 후기를 수정하는 간결한 패치 편집기입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/reviews/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review.dart';
import 'package:oshi_log/features/community/posts/presentation/widgets/post_compose_components.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '제목과 내용을 입력해주세요.',
              en: 'Please enter a title and content.',
              ja: 'タイトルと内容を入力してください。',
            ),
          ),
        ),
      );
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
              context.l10n(
                ko: '여행 후기 수정',
                en: 'Edit Travel Review',
                ja: '旅の記録を編集',
              ),
              style: GBTTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            PostComposeDocumentEditor(
              titleController: _titleController,
              contentController: _contentController,
              autofocusTitle: false,
              titleHintText: context.l10n(
                ko: '이번 여행은 어떠셨나요?',
                en: 'How was this trip?',
                ja: '今回の旅はいかがでしたか？',
              ),
              contentHintText: context.l10n(
                ko: '자세한 후기를 남겨주세요.',
                en: 'Share the details of your trip.',
                ja: '詳しいレビューを書いてください。',
              ),
              maxTitleLines: 2,
              minContentLines: 4,
              maxTitleLength: 255,
              maxContentLength: 20000,
            ),
            const SizedBox(height: GBTSpacing.sm),
            TextField(
              controller: _routeNoteController,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: context.l10n(
                  ko: '동선 메모',
                  en: 'Route Notes',
                  ja: '移動メモ',
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: GBTSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(72, GBTSpacing.touchTarget),
                  ),
                  child: Text(
                    context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
                  ),
                ),
                const SizedBox(width: GBTSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        GBTSpacing.touchTarget,
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            context.l10n(
                              ko: '수정 완료',
                              en: 'Save Changes',
                              ja: '編集を完了する',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
