/// EN: Travel-journal masthead for the clean-sheet community root.
/// KO: 새 커뮤니티 루트를 위한 여행 저널형 마스트헤드.
library;

import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_text.dart';
import '../../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../../core/widgets/navigation/gbt_app_bar_icon_button.dart';

/// EN: Establishes the shared-notes identity without a generic app bar.
/// KO: 일반 앱 바 없이 공유 노트의 정체성을 보여줍니다.
class FieldCommunityMasthead extends StatelessWidget {
  const FieldCommunityMasthead({
    super.key,
    required this.onSearch,
    required this.onSettings,
  });

  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return GBTPageHeader(
      title: context.l10n(ko: '커뮤니티', en: 'Community', ja: 'コミュニティ'),
      showDivider: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GBTAppBarIconButton(
            icon: Icons.search_rounded,
            tooltip: context.l10n(
              ko: '커뮤니티 검색',
              en: 'Search community',
              ja: 'コミュニティを検索',
            ),
            onPressed: onSearch,
          ),
          GBTAppBarIconButton(
            icon: Icons.tune_rounded,
            tooltip: context.l10n(
              ko: '커뮤니티 설정',
              en: 'Community settings',
              ja: 'コミュニティ設定',
            ),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}
