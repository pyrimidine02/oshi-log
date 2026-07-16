/// EN: Shared compose components for post create/edit pages.
/// KO: 게시글 작성/수정 페이지 공용 컴포넌트 모음입니다.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/widgets/common/gbt_image.dart';

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
              maxLines: 1,
              textInputAction: TextInputAction.next,
              style: GBTTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요',
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
              minLines: 8,
              textInputAction: TextInputAction.newline,
              style: GBTTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.7,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '어디서 무엇을 보았는지, 왜 기억하고 싶은지 남겨보세요.',
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
            label: Text(selectedTopic ?? '토픽 선택'),
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
            label: const Text('태그'),
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
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final currentValue = selectedTopic?.trim() ?? '';
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '토픽 선택',
                style: GBTTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '게시글 주제를 하나 선택하세요',
                style: GBTTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _PostTopicOptionTile(
                    label: '선택 안 함',
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
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GBTSpacing.md,
            GBTSpacing.xs,
            GBTSpacing.md,
            GBTSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '태그 선택',
                style: GBTTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GBTSpacing.xs),
              Text(
                '태그는 목록에서만 선택할 수 있어요',
                style: GBTTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              if (orderedSuggestions.isEmpty)
                Text(
                  '선택 가능한 태그가 없습니다.',
                  style: GBTTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: GBTSpacing.xs,
                  runSpacing: GBTSpacing.xs,
                  children: orderedSuggestions
                      .map((tag) {
                        final disabled = isAlreadySelected(tag);
                        return ActionChip(
                          onPressed: disabled
                              ? null
                              : () => Navigator.of(sheetContext).pop(tag),
                          label: Text('#$tag'),
                        );
                      })
                      .toList(growable: false),
                ),
              const SizedBox(height: GBTSpacing.md),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result;
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
                  '임시 저장된 글이 있어요',
                  style: GBTTypography.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '저장 시각 $hour:$minute$projectLabel',
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
            child: const Text('삭제'),
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
            child: const Text('복구'),
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
                '작성 가이드',
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
              _PostComposeGuideChip(label: '제목', isDone: hasTitle),
              _PostComposeGuideChip(label: '내용 30자+', isDone: hasContent),
              _PostComposeGuideChip(label: '이미지(선택)', isDone: hasImage),
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
                  ? '프로젝트를 선택해주세요'
                  : '현재 프로젝트: $projectCode',
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
                '사진',
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
                label: const Text('추가'),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: isSubmitting ? null : onClearAll,
                  child: const Text('전체 삭제'),
                ),
            ],
          ),
          const SizedBox(height: GBTSpacing.xs),
          Text(
            '장소 사진을 추가하면 게시글 전달력이 좋아져요.',
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
                    '최대 $maxImageCount장 첨부 가능',
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
      label: '$filename 미리보기',
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
                    tooltip: '사진 제거',
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
      label: '$filename 미리보기',
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
                      tooltip: '사진 제거',
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
              '로그인 후 게시글을 작성할 수 있어요.',
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
