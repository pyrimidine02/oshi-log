/// EN: Composition root wiring [PostEditPage] to its cross-feature slots.
/// KO: [PostEditPage]를 feature 간 슬롯에 연결하는 composition root.
library;

import 'package:flutter/material.dart';

import 'package:oshi_log/features/community/posts/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/community/posts/presentation/pages/post_edit_page.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/project_selector.dart';

class PostEditRoute extends StatelessWidget {
  const PostEditRoute({super.key, required this.post});

  final PostDetail post;

  @override
  Widget build(BuildContext context) {
    return PostEditPage(
      post: post,
      projectSelectorBuilder: (context) =>
          const ProjectAudienceSelectorCompact(dense: true),
    );
  }
}
