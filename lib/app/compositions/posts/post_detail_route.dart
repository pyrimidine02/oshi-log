/// EN: Composition root wiring [PostDetailPage] to its cross-feature slots.
/// KO: [PostDetailPage]를 feature 간 슬롯에 연결하는 composition root.
library;

import 'package:flutter/material.dart';

import 'package:oshi_log/core/localization/locale_text.dart';
import 'package:oshi_log/core/widgets/sheets/gbt_bottom_sheet.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/community_moderation.dart';
import 'package:oshi_log/features/community/moderation/presentation/widgets/community_report_sheet.dart';
import 'package:oshi_log/features/community/posts/presentation/pages/post_detail_page.dart';
import 'package:oshi_log/features/titles/presentation/widgets/active_title_badge.dart';

class PostDetailRoute extends StatelessWidget {
  const PostDetailRoute({
    super.key,
    required this.postId,
    this.projectCodeHint,
  });

  final String postId;
  final String? projectCodeHint;

  static Future<(CommunityReportReason, String?)?> _showReportSheet(
    BuildContext context,
  ) async {
    final payload = await showGBTBottomSheet<CommunityReportPayload>(
      context: context,
      isScrollControlled: true,
      title: context.l10n(ko: '신고', en: 'Report', ja: '通報'),
      child: const CommunityReportSheet(),
    );
    if (payload == null) return null;
    return (payload.reason, payload.description);
  }

  @override
  Widget build(BuildContext context) {
    return PostDetailPage(
      postId: postId,
      projectCodeHint: projectCodeHint,
      reportSheetBuilder: _showReportSheet,
      titleBadgeBuilder: (context, item) =>
          ActiveTitleBadge.fromActiveItem(item),
    );
  }
}
