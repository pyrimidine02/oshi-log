/// EN: Editorial masthead for the Field Guide root.
/// KO: Field Guide 루트의 에디토리얼 마스트헤드.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';

/// EN: Identifies the guide and the active project without a generic app bar.
/// KO: 일반적인 앱 바 대신 가이드와 활성 프로젝트를 식별합니다.
class FieldGuideMasthead extends StatelessWidget {
  const FieldGuideMasthead({
    super.key,
    required this.projectKey,
    required this.onSearch,
  });

  final String? projectKey;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final normalizedProjectKey = projectKey?.trim();
    final projectLabel =
        normalizedProjectKey == null || normalizedProjectKey.isEmpty
        ? null
        : normalizedProjectKey
              .split('-')
              .where((part) => part.isNotEmpty)
              .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
              .join(' ');
    final searchLabel = context.l10n(
      ko: '정보 검색',
      en: 'Search information',
      ja: '情報を検索',
    );
    return GBTPageHeader(
      eyebrow: projectLabel,
      title: context.l10n(ko: '정보', en: 'Info', ja: '情報'),
      showDivider: false,
      trailing: GBTAppBarIconButton(
        icon: Icons.search_rounded,
        tooltip: searchLabel,
        onPressed: onSearch,
      ),
    );
  }
}
