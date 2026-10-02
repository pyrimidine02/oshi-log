/// EN: Reusable on-demand translation panel for community content.
/// KO: 커뮤니티 콘텐츠용 재사용 요청형 번역 패널입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/features/auth/application/session_state.dart';
import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/core/theme/gbt_spacing.dart';
import 'package:oshi_log/core/theme/gbt_typography.dart';
import 'package:oshi_log/features/community/posts/application/community_translation_controller.dart';

class CommunityTranslationPanel extends ConsumerWidget {
  const CommunityTranslationPanel({
    super.key,
    required this.contentId,
    required this.text,
    this.textStyle,
    this.compact = false,
  });

  final String contentId;
  final String text;
  final TextStyle? textStyle;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context);
    final targetLanguage = normalizeTranslationLanguageCode(
      locale.languageCode,
    );
    final sourceLanguage = detectLikelyTranslationLanguage(normalizedText);
    final shouldShowTranslateAction =
        sourceLanguage == null || sourceLanguage != targetLanguage;
    if (!shouldShowTranslateAction) {
      return const SizedBox.shrink();
    }
    final key = CommunityTranslationCacheKey(
      contentId: contentId,
      targetLanguage: targetLanguage,
    );
    final entry = ref.watch(communityTranslationEntryProvider(key));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? GBTColors.darkTextSecondary
        : GBTColors.textSecondary;
    final tertiaryColor = isDark
        ? GBTColors.darkTextTertiary
        : GBTColors.textTertiary;
    final baseTextStyle =
        textStyle ??
        GBTTypography.bodySmall.copyWith(
          color: secondaryColor,
          height: compact ? 1.45 : 1.5,
        );
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    Future<void> onTranslateTap() async {
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '번역은 로그인 후 이용할 수 있어요',
                en: 'Please log in to use translation.',
                ja: '翻訳はログイン後にご利用いただけます',
              ),
            ),
          ),
        );
        return;
      }
      await ref
          .read(communityTranslationControllerProvider.notifier)
          .translate(
            contentId: contentId,
            text: normalizedText,
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
          );
    }

    Widget buildTranslateAction() {
      switch (entry.status) {
        case CommunityTranslationLoadStatus.loading:
          return Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n(
                    ko: '번역 중...',
                    en: 'Translating...',
                    ja: '翻訳中...',
                  ),
                  style: GBTTypography.labelSmall.copyWith(
                    color: tertiaryColor,
                  ),
                ),
              ],
            ),
          );
        case CommunityTranslationLoadStatus.error:
          return TextButton.icon(
            onPressed: onTranslateTap,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(
              context.l10n(
                ko: '번역 다시 시도',
                en: 'Retry Translation',
                ja: '翻訳を再試行する',
              ),
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: buttonStyle,
          );
        case CommunityTranslationLoadStatus.idle:
        case CommunityTranslationLoadStatus.noResult:
        case CommunityTranslationLoadStatus.translated:
          return TextButton.icon(
            onPressed: entry.status == CommunityTranslationLoadStatus.translated
                ? null
                : onTranslateTap,
            icon: const Icon(Icons.translate_rounded, size: 14),
            label: Text(
              entry.status == CommunityTranslationLoadStatus.translated
                  ? context.l10n(ko: '번역됨', en: 'Translated', ja: '翻訳済み')
                  : context.l10n(ko: '번역', en: 'Translate', ja: '翻訳する'),
              style: GBTTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: buttonStyle,
          );
      }
    }

    Widget? buildTranslationBody() {
      switch (entry.status) {
        case CommunityTranslationLoadStatus.translated:
          final translated = entry.translatedText?.trim();
          if (translated == null || translated.isEmpty) {
            return null;
          }
          return Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.xxs),
            child: Text(translated, style: baseTextStyle),
          );
        case CommunityTranslationLoadStatus.noResult:
          return Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.xxs),
            child: Text(
              context.l10n(
                ko: '번역 결과 없음',
                en: 'No translation result',
                ja: '翻訳結果なし',
              ),
              style: GBTTypography.labelSmall.copyWith(color: tertiaryColor),
            ),
          );
        case CommunityTranslationLoadStatus.error:
          final message = entry.failure?.userMessage;
          if (message == null || message.trim().isEmpty) {
            return null;
          }
          return Padding(
            padding: const EdgeInsets.only(top: GBTSpacing.xxs),
            child: Text(
              message,
              style: GBTTypography.labelSmall.copyWith(color: tertiaryColor),
            ),
          );
        case CommunityTranslationLoadStatus.idle:
        case CommunityTranslationLoadStatus.loading:
          return null;
      }
    }

    final translationBody = buildTranslationBody();

    return Padding(
      padding: EdgeInsets.only(top: compact ? GBTSpacing.xxs : GBTSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTranslateAction(),
          if (translationBody != null) translationBody,
        ],
      ),
    );
  }
}
