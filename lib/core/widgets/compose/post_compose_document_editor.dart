/// EN: Shared field-note document editor (title + content fields) used by
/// multiple features' compose flows. Kept feature-agnostic.
/// KO: 여러 기능의 작성 플로우가 공통으로 쓰는 필드 노트 에디터(제목+본문)
/// 입니다. 특정 feature에 종속되지 않도록 유지합니다.
library;

import 'package:flutter/material.dart';

import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';

/// EN: Shared field-note writing surface used by create and edit flows.
/// KO: 작성과 수정 흐름이 공통으로 사용하는 필드 노트 작성 영역입니다.
class PostComposeDocumentEditor extends StatelessWidget {
  const PostComposeDocumentEditor({
    super.key,
    required this.titleController,
    required this.contentController,
    this.titleFocusNode,
    this.contentFocusNode,
    this.header,
    this.enabled = true,
    this.autofocusTitle = true,
    this.titleHintText,
    this.contentHintText,
    this.maxTitleLines = 1,
    this.minContentLines = 8,
    this.maxTitleLength = 60,
    this.maxContentLength = 3000,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode? titleFocusNode;
  final FocusNode? contentFocusNode;
  final Widget? header;
  final bool enabled;
  final bool autofocusTitle;
  final String? titleHintText;
  final String? contentHintText;
  final int maxTitleLines;
  final int minContentLines;
  final int maxTitleLength;
  final int maxContentLength;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ruleColor = colors.outlineVariant.withValues(alpha: 0.8);
    const fieldBorder = InputBorder.none;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ruleColor),
          bottom: BorderSide(color: ruleColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: GBTSpacing.sm),
              Divider(height: 1, color: ruleColor),
              const SizedBox(height: GBTSpacing.sm),
            ],
            TextField(
              key: const ValueKey<String>('post-compose-title'),
              controller: titleController,
              focusNode: titleFocusNode,
              enabled: enabled,
              autofocus: autofocusTitle,
              maxLength: maxTitleLength,
              maxLines: maxTitleLines,
              textInputAction: maxTitleLines == 1
                  ? TextInputAction.next
                  : TextInputAction.newline,
              style: GBTTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText:
                    titleHintText ??
                    context.l10n(
                      ko: '제목을 입력해주세요',
                      en: 'Enter a title',
                      ja: 'タイトルを入力してください',
                    ),
                counterText: '',
                filled: false,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder,
                disabledBorder: fieldBorder,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: GBTTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: GBTSpacing.sm),
            Divider(height: 1, color: ruleColor),
            const SizedBox(height: GBTSpacing.md),
            TextField(
              key: const ValueKey<String>('post-compose-content'),
              controller: contentController,
              focusNode: contentFocusNode,
              enabled: enabled,
              maxLength: maxContentLength,
              maxLines: null,
              minLines: minContentLines,
              textInputAction: TextInputAction.newline,
              style: GBTTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.7,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText:
                    contentHintText ??
                    context.l10n(
                      ko: '어디서 무엇을 보았는지, 왜 기억하고 싶은지 남겨보세요.',
                      en: 'Share where and what you saw, and why you want to remember it.',
                      ja: 'どこで何を見たか、なぜ覚えておきたいかを書いてみましょう。',
                    ),
                counterText: '',
                filled: false,
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder,
                disabledBorder: fieldBorder,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: GBTTypography.bodyLarge.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
