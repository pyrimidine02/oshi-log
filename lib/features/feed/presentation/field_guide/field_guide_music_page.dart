/// EN: Full-screen music archive launched from the Field Guide.
/// KO: Field Guide에서 여는 전체 화면 음악 아카이브.
library;

import 'package:flutter/material.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../music/presentation/widgets/music_catalog_tab.dart';

class FieldGuideMusicPage extends StatelessWidget {
  const FieldGuideMusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(ko: '음악', en: 'Music', ja: '音楽'),
      ),
      body: const MusicCatalogTab(showPageHeader: true),
    );
  }
}
