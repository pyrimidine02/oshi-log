/// EN: Shared compose components for post create/edit pages.
/// KO: 게시글 작성/수정 페이지 공용 컴포넌트 모음입니다.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/gbt_colors.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';
import 'package:oshi_log/design_system/theme/gbt_typography.dart';
import 'package:oshi_log/design_system/widgets/common/gbt_image.dart';

/// EN: Appends markdown image blocks to post content.
/// KO: 게시글 본문 뒤에 이미지 마크다운 블록을 추가합니다.
String appendImageMarkdownContent(String content, List<String> urls) {
  if (urls.isEmpty) {
    return content;
  }

  final buffer = StringBuffer(content);
  buffer.writeln('\n');
  for (final url in urls) {
    buffer.writeln('![]($url)');
  }
  return buffer.toString().trim();
}

/// EN: Maximum allowed tag count in compose metadata.
/// KO: 작성 메타데이터에서 허용하는 최대 태그 개수입니다.
const int kPostMaxTagCount = 5;

// EN: PostComposeDocumentEditor moved to
// lib/design_system/widgets/compose/post_compose_document_editor.dart (feature-
// agnostic, reused by reviews' compose flows too).
// KO: PostComposeDocumentEditor는 feature에 종속되지 않도록
// lib/design_system/widgets/compose/post_compose_document_editor.dart로 이동했습니다
// (reviews 작성 플로우에서도 재사용).
/// EN: Normalizes user-entered tag text into API-friendly token.
/// KO: 사용자 입력 태그를 API 전송 가능한 토큰으로 정규화합니다.
String normalizePostTag(String rawTag) {
  final withoutHash = rawTag.trim().replaceFirst(RegExp(r'^#+'), '');
  final compact = withoutHash.replaceAll(RegExp(r'\s+'), '');
  return compact.trim();
}

/// EN: Sanitizes tags with normalization, dedupe and max length/count rules.
/// KO: 태그를 정규화/중복제거/길이·개수 제한 규칙으로 정제합니다.
List<String> sanitizePostTags(
  Iterable<String> rawTags, {
  int maxCount = kPostMaxTagCount,
  int maxLength = 16,
}) {
  final seen = <String>{};
  final sanitized = <String>[];
  for (final rawTag in rawTags) {
    final normalized = normalizePostTag(rawTag);
    if (normalized.isEmpty || normalized.length > maxLength) {
      continue;
    }
    final key = normalized.toLowerCase();
    if (seen.add(key)) {
      sanitized.add(normalized);
    }
    if (sanitized.length >= maxCount) {
      break;
    }
  }
  return sanitized;
}

/// EN: Compact selector row for topic/tag metadata in compose forms.
/// KO: 작성 폼에서 토픽/태그 메타데이터를 선택하는 컴팩트 행입니다.
class PostTopicTagSelector extends StatelessWidget {
  const PostTopicTagSelector({
    super.key,
    required this.selectedTopic,
    required this.selectedTags,
    required this.onTapTopic,
    required this.onTapAddTag,
    required this.onRemoveTag,
  });

  final String? selectedTopic;
  final List<String> selectedTags;
  final VoidCallback? onTapTopic;
  final VoidCallback? onTapAddTag;
  final ValueChanged<String>? onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: GBTSpacing.xs,
        runSpacing: GBTSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ActionChip(
            onPressed: onTapTopic,
            avatar: const Icon(Icons.topic_outlined, size: 16),
            label: Text(
              selectedTopic ??
                  context.l10n(ko: '토픽 선택', en: 'Select topic', ja: 'トピック選択'),
            ),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            labelStyle: GBTTypography.labelMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          ...selectedTags.map(
            (tag) => InputChip(
              label: Text('#$tag'),
              onDeleted: onRemoveTag == null ? null : () => onRemoveTag!(tag),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.75),
              ),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.32,
              ),
              labelStyle: GBTTypography.labelSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              deleteIconColor: colorScheme.onSurfaceVariant,
            ),
          ),
          ActionChip(
            onPressed: onTapAddTag,
            avatar: const Icon(Icons.add, size: 16),
            label: Text(context.l10n(ko: '태그', en: 'Tags', ja: 'タグ')),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            labelStyle: GBTTypography.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Shows a modal topic picker; returns `''` when user clears selection.
/// KO: 모달 토픽 선택기를 표시하며, 선택 해제 시 `''`를 반환합니다.
Future<String?> showPostTopicPickerSheet(
  BuildContext context, {
  required String? selectedTopic,
  required List<String> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final currentValue = selectedTopic?.trim() ?? '';
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxSheetHeight = _availableBottomSheetHeight(sheetContext) * 0.72;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    0,
                    GBTSpacing.md,
                    GBTSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n(
                            ko: '토픽 선택',
                            en: 'Select topic',
                            ja: 'トピック選択',
                          ),
                          style: GBTTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, GBTSpacing.touchTarget),
                        ),
                        child: Text(
                          context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _PostTopicOptionTile(
                        label: context.l10n(
                          ko: '선택 안 함',
                          en: 'None selected',
                          ja: '選択しない',
                        ),
                        isSelected: currentValue.isEmpty,
                        onTap: () => Navigator.of(sheetContext).pop(''),
                      ),
                      ...options.map(
                        (topic) => _PostTopicOptionTile(
                          label: topic,
                          isSelected: currentValue == topic,
                          onTap: () => Navigator.of(sheetContext).pop(topic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// EN: Shows a modal tag picker and returns a selected tag token.
/// KO: 모달 태그 선택기를 표시하고 선택된 태그 토큰을 반환합니다.
Future<String?> showPostTagPickerSheet(
  BuildContext context, {
  required List<String> selectedTags,
  List<String> suggestions = const <String>[],
}) async {
  final orderedSuggestions = suggestions
      .map(normalizePostTag)
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);

  bool isAlreadySelected(String normalizedTag) {
    return selectedTags.any(
      (tag) => tag.toLowerCase() == normalizedTag.toLowerCase(),
    );
  }

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxSheetHeight = _availableBottomSheetHeight(sheetContext) * 0.72;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GBTSpacing.md,
                    0,
                    GBTSpacing.md,
                    GBTSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n(
                            ko: '태그 선택',
                            en: 'Select tags',
                            ja: 'タグ選択',
                          ),
                          style: GBTTypography.titleLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, GBTSpacing.touchTarget),
                        ),
                        child: Text(
                          context.l10n(ko: '닫기', en: 'Close', ja: '閉じる'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(GBTSpacing.md),
                    child: orderedSuggestions.isEmpty
                        ? Text(
                            context.l10n(
                              ko: '선택 가능한 태그가 없습니다.',
                              en: 'No tags available.',
                              ja: '選択できるタグがありません。',
                            ),
                            style: GBTTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Wrap(
                            spacing: GBTSpacing.xs,
                            runSpacing: GBTSpacing.xs,
                            children: orderedSuggestions
                                .map((tag) {
                                  final disabled = isAlreadySelected(tag);
                                  return ActionChip(
                                    onPressed: disabled
                                        ? null
                                        : () => Navigator.of(
                                            sheetContext,
                                          ).pop(tag),
                                    label: Text('#$tag'),
                                  );
                                })
                                .toList(growable: false),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return result;
}

double _availableBottomSheetHeight(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final blockedHeight =
      mediaQuery.viewInsets.bottom +
      mediaQuery.padding.top +
      mediaQuery.padding.bottom;
  return (mediaQuery.size.height - blockedHeight).clamp(
    GBTSpacing.touchTarget,
    mediaQuery.size.height,
  );
}

class _PostTopicOptionTile extends StatelessWidget {
  const _PostTopicOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(label),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

/// EN: Intro card for compose pages.
/// KO: 작성/수정 페이지 상단 소개 카드입니다.
class PostComposeIntroCard extends StatelessWidget {
  const PostComposeIntroCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.edit_note_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GBTTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xxs),
                Text(
                  description,
                  style: GBTTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

/// EN: Inline banner for recovering an unsent local draft.
/// KO: 미전송 임시저장 글 복구를 위한 인라인 배너입니다.
class PostComposeDraftRecoveryBanner extends StatelessWidget {
  const PostComposeDraftRecoveryBanner({
    super.key,
    required this.savedAt,
    required this.projectCode,
    required this.onRestore,
    required this.onDiscard,
  });

  final DateTime savedAt;
  final String? projectCode;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = savedAt.hour.toString().padLeft(2, '0');
    final minute = savedAt.minute.toString().padLeft(2, '0');
    final projectLabel = projectCode?.isNotEmpty == true
        ? ' · $projectCode'
        : '';

    final cardColor = isDark
        ? colorScheme.secondaryContainer.withValues(alpha: 0.15)
        : colorScheme.secondaryContainer.withValues(alpha: 0.38);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: GBTSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: isDark ? 0.1 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restore, color: colorScheme.secondary, size: 20),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(
                    ko: '임시 저장된 글이 있어요',
                    en: 'You have a saved draft',
                    ja: '保存された下書きがあります',
                  ),
                  style: GBTTypography.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n(
                    ko: '저장 시각 $hour:$minute$projectLabel',
                    en: 'Saved at $hour:$minute$projectLabel',
                    ja: '保存時刻 $hour:$minute$projectLabel',
                  ),
                  style: GBTTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, GBTSpacing.touchTarget),
            ),
            child: Text(context.l10n(ko: '삭제', en: 'Delete', ja: '削除する')),
          ),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: onRestore,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, GBTSpacing.touchTarget),
            ),
            child: Text(context.l10n(ko: '복구', en: 'Recover', ja: '復元する')),
          ),
        ],
      ),
    );
  }
}

/// EN: Compose progress card (title/content/image completion).
/// KO: 작성 진행률 카드(제목/내용/이미지 완료 상태)입니다.
class PostComposeStatusCard extends StatelessWidget {
  const PostComposeStatusCard({
    super.key,
    required this.completionRatio,
    required this.hasTitle,
    required this.hasContent,
    required this.hasImage,
  });

  final double completionRatio;
  final bool hasTitle;
  final bool hasContent;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(GBTSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 18),
              const SizedBox(width: GBTSpacing.xs),
              Text(
                context.l10n(ko: '작성 가이드', en: 'Writing guide', ja: '作成ガイド'),
                style: GBTTypography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(completionRatio * 100).round()}%',
                style: GBTTypography.labelMedium.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GBTSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: completionRatio,
              minHeight: 6,
              backgroundColor: colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          Wrap(
            spacing: GBTSpacing.sm,
            runSpacing: GBTSpacing.sm,
            children: [
              _PostComposeGuideChip(
                label: context.l10n(ko: '제목', en: 'Title', ja: 'タイトル'),
                isDone: hasTitle,
              ),
              _PostComposeGuideChip(
                label: context.l10n(
                  ko: '내용 30자+',
                  en: 'Content 30+ chars',
                  ja: '内容30文字以上',
                ),
                isDone: hasContent,
              ),
              _PostComposeGuideChip(
                label: context.l10n(
                  ko: '이미지(선택)',
                  en: 'Image (optional)',
                  ja: '画像（任意）',
                ),
                isDone: hasImage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostComposeGuideChip extends StatelessWidget {
  const _PostComposeGuideChip({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.sm,
        vertical: GBTSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDone
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        border: Border.all(
          color: isDone
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isDone ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: GBTSpacing.xs),
          Text(
            label,
            style: GBTTypography.labelSmall.copyWith(
              color: isDone ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Badge showing the currently selected project.
/// KO: 현재 선택 프로젝트를 보여주는 배지입니다.
class PostComposeProjectBadge extends StatelessWidget {
  const PostComposeProjectBadge({super.key, required this.projectCode});

  final String? projectCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.md,
        vertical: GBTSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: GBTSpacing.xs),
          Expanded(
            child: Text(
              projectCode == null || projectCode!.isEmpty
                  ? context.l10n(
                      ko: '프로젝트를 선택해주세요',
                      en: 'Please select a project',
                      ja: 'プロジェクトを選択してください',
                    )
                  : context.l10n(
                      ko: '현재 프로젝트: $projectCode',
                      en: 'Current project: $projectCode',
                      ja: '現在のプロジェクト：$projectCode',
                    ),
              style: GBTTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Image picker section used by compose forms.
/// KO: 작성 폼에서 사용하는 이미지 섹션입니다.
class PostComposeImageSection extends StatelessWidget {
  const PostComposeImageSection({
    super.key,
    required this.imageCount,
    required this.maxImageCount,
    required this.isSubmitting,
    required this.onPickImages,
    required this.onClearAll,
    required this.imageGrid,
    this.useCardChrome = true,
  });

  final int imageCount;
  final int maxImageCount;
  final bool isSubmitting;
  final VoidCallback onPickImages;
  final VoidCallback? onClearAll;
  final Widget? imageGrid;
  final bool useCardChrome;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.all(GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n(ko: '사진', en: 'Photos', ja: '写真'),
                style: GBTTypography.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: GBTSpacing.xs),
              Text(
                '$imageCount/$maxImageCount',
                style: GBTTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isSubmitting || imageCount >= maxImageCount
                    ? null
                    : onPickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(context.l10n(ko: '추가', en: 'Add', ja: '追加する')),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: isSubmitting ? null : onClearAll,
                  child: Text(
                    context.l10n(ko: '전체 삭제', en: 'Delete all', ja: '全削除する'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            context.l10n(
              ko: '장소 사진을 추가하면 게시글 전달력이 좋아져요.',
              en: 'Adding a photo of the place makes your post more vivid.',
              ja: '場所の写真を追加すると投稿が伝わりやすくなります。',
            ),
            style: GBTTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (imageGrid != null) ...[
            const SizedBox(height: GBTSpacing.md),
            imageGrid!,
          ] else ...[
            const SizedBox(height: GBTSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_size_select_actual_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: GBTSpacing.xs),
                  Text(
                    context.l10n(
                      ko: '최대 $maxImageCount장 첨부 가능',
                      en: 'Up to $maxImageCount images allowed',
                      ja: '最大$maxImageCount枚まで添付可能',
                    ),
                    style: GBTTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (!useCardChrome) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: content,
    );
  }
}

/// EN: Preview tile for selected image files.
/// KO: 선택한 이미지 파일 미리보기 타일입니다.
class PostComposePickedImageTile extends StatelessWidget {
  const PostComposePickedImageTile({
    super.key,
    required this.imagePath,
    required this.filename,
    required this.onPreview,
    this.onRemove,
  });

  final String imagePath;
  final String filename;
  final VoidCallback onPreview;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: context.l10n(
        ko: '$filename 미리보기',
        en: '$filename preview',
        ja: '$filenameのプレビュー',
      ),
      child: Material(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPreview,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.xs,
                    vertical: GBTSpacing.xxs,
                  ),
                  decoration: const BoxDecoration(
                    gradient: GBTColors.carouselCardOverlayGradient,
                  ),
                  child: Text(
                    filename,
                    style: GBTTypography.caption.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: GBTSpacing.xs,
                right: GBTSpacing.xs,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton.filled(
                    padding: EdgeInsets.zero,
                    onPressed: onRemove,
                    iconSize: 14,
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n(
                      ko: '사진 제거',
                      en: 'Remove photo',
                      ja: '写真を削除する',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Preview tile for existing remote image URLs.
/// KO: 기존 원격 이미지 URL 미리보기 타일입니다.
class PostComposeRemoteImageTile extends StatelessWidget {
  const PostComposeRemoteImageTile({
    super.key,
    required this.imageUrl,
    required this.filename,
    required this.onPreview,
    this.onRemove,
  });

  final String imageUrl;
  final String filename;
  final VoidCallback onPreview;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: context.l10n(
        ko: '$filename 미리보기',
        en: '$filename preview',
        ja: '$filenameのプレビュー',
      ),
      child: Material(
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPreview,
          child: Stack(
            children: [
              Positioned.fill(
                child: GBTImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GBTSpacing.xs,
                    vertical: GBTSpacing.xxs,
                  ),
                  decoration: const BoxDecoration(
                    gradient: GBTColors.carouselCardOverlayGradient,
                  ),
                  child: Text(
                    filename,
                    style: GBTTypography.caption.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  top: GBTSpacing.xs,
                  right: GBTSpacing.xs,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton.filled(
                      padding: EdgeInsets.zero,
                      onPressed: onRemove,
                      iconSize: 14,
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n(
                        ko: '사진 제거',
                        en: 'Remove photo',
                        ja: '写真を削除する',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// EN: Login required message widget with icon and descriptive text.
/// KO: 아이콘과 설명 텍스트를 포함한 로그인 필요 메시지 위젯.
class PostComposeLoginRequiredMessage extends StatelessWidget {
  const PostComposeLoginRequiredMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: isDark
                  ? GBTColors.darkTextTertiary
                  : GBTColors.textTertiary,
            ),
            const SizedBox(height: GBTSpacing.md),
            Text(
              context.l10n(
                ko: '로그인 후 게시글을 작성할 수 있어요.',
                en: 'Log in to write a post.',
                ja: 'ログイン後に投稿を作成できます。',
              ),
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextSecondary
                    : GBTColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
