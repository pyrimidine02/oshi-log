/// EN: Composition root wiring [PostCreatePage] to its cross-feature slots.
/// KO: [PostCreatePage]를 feature 간 슬롯에 연결하는 composition root.
library;

import 'package:flutter/material.dart';

import 'package:oshi_log/features/community/posts/presentation/pages/post_create_page.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/project_selector.dart';

class PostCreateRoute extends StatelessWidget {
  const PostCreateRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return PostCreatePage(
      projectSelectorBuilder: (context) =>
          const ProjectAudienceSelectorCompact(),
    );
  }
}
