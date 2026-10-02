import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';

/// EN: Renders a readable introduction inside the place page's existing scroll.
/// KO: 장소 페이지의 기존 스크롤 안에 소개를 읽기 좋게 표시합니다.
class PlaceDescriptionBody extends StatelessWidget {
  const PlaceDescriptionBody({super.key, required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final content = description?.trim() ?? '';
    final colors = Theme.of(context).colorScheme;
    final body = GBTTypography.bodyMedium.copyWith(
      color: colors.onSurface,
      height: 1.75,
    );
    final heading = GBTTypography.titleSmall.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w700,
      height: 1.45,
    );
    if (content.isEmpty) {
      return Text(
        context.l10n(
          ko: '소개 정보가 없습니다.',
          en: 'No description available.',
          ja: '紹介情報がありません。',
        ),
        style: body.copyWith(color: colors.onSurfaceVariant),
      );
    }
    return SelectionArea(
      child: MarkdownBody(
        data: content,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: body,
          h1: heading,
          h2: heading,
          h3: heading,
          h4: heading,
          h5: heading,
          h6: heading,
          h1Padding: const EdgeInsets.only(top: GBTSpacing.md),
          h2Padding: const EdgeInsets.only(top: GBTSpacing.md),
          h3Padding: const EdgeInsets.only(top: GBTSpacing.sm),
          blockSpacing: GBTSpacing.md,
          a: body.copyWith(
            color: colors.primary,
            decoration: TextDecoration.underline,
            decorationColor: colors.primary,
          ),
        ),
        // EN: Description images stay as alt text; the page owns its gallery.
        // KO: 소개의 이미지는 대체 텍스트로 표시하고 사진은 기존 갤러리에서 봅니다.
        imageBuilder: (uri, title, alt) => Text(alt ?? '', style: body),
        onTapLink: (text, href, title) => unawaited(_openLink(context, href)),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String? href) async {
    final uri = Uri.tryParse(href ?? '');
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // EN: Keep platform failures in the page's normal feedback flow.
        // KO: 플랫폼 오류는 페이지의 기본 안내 방식으로 처리합니다.
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '링크를 열 수 없습니다.',
            en: 'Could not open the link.',
            ja: 'リンクを開けませんでした。',
          ),
        ),
      ),
    );
  }
}
