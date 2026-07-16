import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/feed/domain/entities/feed_entities.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/post_detail_page.dart';
import 'package:girlsbandtabi_app/features/titles/application/titles_controller.dart';

void main() {
  testWidgets('post detail reads as one ordered field-note document', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();

    const orderedSections = <Key>[
      Key('field-note-header'),
      Key('field-note-body'),
      Key('field-note-actions'),
      Key('field-note-comment-log'),
    ];

    expect(find.byKey(const Key('field-note-document')), findsOneWidget);
    expect(find.text('COMMUNITY FIELD NOTE'), findsOneWidget);
    expect(find.text('시모키타자와 공연장 기록'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    final sectionTops = orderedSections
        .map((key) => tester.getTopLeft(find.byKey(key)).dy)
        .toList(growable: false);
    expect(sectionTops, orderedEquals([...sectionTops]..sort()));
  });

  testWidgets('comment log keeps replies collapsed behind one level', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();

    expect(find.text('첫 댓글'), findsOneWidget);
    expect(find.textContaining('첫 답글', findRichText: true), findsNothing);
    expect(find.textContaining('두 번째 답글', findRichText: true), findsNothing);
    expect(find.text('답글 2개 보기'), findsOneWidget);

    await tester.ensureVisible(find.text('답글 2개 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('답글 2개 보기'));
    await tester.pumpAndSettle();

    final firstReply = find.textContaining('첫 답글', findRichText: true);
    expect(firstReply, findsOneWidget);
    expect(find.textContaining('두 번째 답글', findRichText: true), findsOneWidget);
    expect(
      tester.getTopLeft(firstReply).dx,
      greaterThan(tester.getTopLeft(find.text('첫 댓글')).dx),
    );
  });

  testWidgets('field note remains usable at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: _buildSubject(isAuthenticated: true),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('field-note-composer'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}

Widget _buildSubject({bool isAuthenticated = false}) {
  final commentController = TextEditingController();
  final commentFocusNode = FocusNode();
  final scrollController = ScrollController();

  return ProviderScope(
    overrides: [
      userActiveTitleProvider(_post.authorId).overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      theme: GBTTheme.light,
      home: Scaffold(
        body: PostDetailDocumentView(
          post: _post,
          commentsState: AsyncData(_comments),
          likeState: const AsyncData(
            PostLikeStatus(postId: 'post-1', isLiked: false, likeCount: 12),
          ),
          bookmarkState: const AsyncData(
            PostBookmarkStatus(postId: 'post-1', isBookmarked: false),
          ),
          currentUserId: isAuthenticated ? 'current-user' : null,
          isAdmin: false,
          isAuthenticated: isAuthenticated,
          isSubmitting: false,
          scrollController: scrollController,
          commentController: commentController,
          commentFocusNode: commentFocusNode,
          onToggleLike: () {},
          onToggleBookmark: () {},
          onSubmitComment: () {},
          onEditComment: (_) {},
          onDeleteComment: (_) {},
          onReportComment: (_) {},
          onOpenCommentThread: (_) {},
          onAppealPost: () {},
          onTapAuthor: (_) {},
          onFocusComment: () {},
          authorBlockStatus: null,
          authorFollowState: null,
          onToggleFollowAuthor: null,
          replyTarget: null,
          onReplyToComment: (_) {},
          onCancelReply: () {},
          onRefresh: () async {},
        ),
      ),
    ),
  );
}

final _post = PostDetail(
  id: 'post-1',
  projectId: 'bandori',
  authorId: 'author-1',
  title: '시모키타자와 공연장 기록',
  content: '북쪽 출구에서 만나면 공연장까지 가는 길이 가장 짧었다.',
  authorName: 'Mina',
  topic: 'LIVE',
  tags: const ['시모키타자와', '공연'],
  commentCount: 3,
  likeCount: 12,
  createdAt: DateTime.utc(2026, 7, 15, 6),
);

final _comments = <PostComment>[
  PostComment(
    id: 'comment-1',
    postId: 'post-1',
    projectId: 'bandori',
    authorId: 'reader-1',
    authorName: 'Rin',
    content: '첫 댓글',
    replyCount: 2,
    createdAt: DateTime.utc(2026, 7, 15, 7),
  ),
  PostComment(
    id: 'reply-1',
    postId: 'post-1',
    projectId: 'bandori',
    authorId: 'author-1',
    authorName: 'Mina',
    content: '첫 답글',
    parentCommentId: 'comment-1',
    depth: 1,
    createdAt: DateTime.utc(2026, 7, 15, 8),
  ),
  PostComment(
    id: 'reply-2',
    postId: 'post-1',
    projectId: 'bandori',
    authorId: 'reader-2',
    authorName: 'Saki',
    content: '두 번째 답글',
    parentCommentId: 'reply-1',
    depth: 2,
    createdAt: DateTime.utc(2026, 7, 15, 9),
  ),
];
