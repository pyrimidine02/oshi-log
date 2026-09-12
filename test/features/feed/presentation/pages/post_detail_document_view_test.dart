import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/domain/entities/feed_entities.dart';
import 'package:oshi_log/features/feed/presentation/pages/post_detail_page.dart';
import 'package:oshi_log/features/titles/application/titles_controller.dart';

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
    expect(find.text('COMMUNITY FIELD NOTE'), findsNothing);
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

    await tester.pumpWidget(_buildSubject(isAuthenticated: true, textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('field-note-composer'))).height,
      greaterThanOrEqualTo(48),
    );
  });
  testWidgets('logged-out comment prompt wraps at 320dp and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildSubject(textScale: 2));
    await tester.pump();
    expect(find.text('댓글을 작성하려면 로그인하세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post actions have labels and remain tappable at large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var likes = 0;
    var saves = 0;
    await tester.pumpWidget(
      _buildSubject(textScale: 2, onLike: () => likes++, onSave: () => saves++),
    );
    await tester.pump();
    for (final label in ['좋아요 12', '저장']) {
      final action = find.widgetWithText(TextButton, label);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await tester.tap(action);
    }
    expect(likes, 1);
    expect(saves, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native comment sort changes visible root order', (tester) async {
    final newer = PostComment(
      id: 'comment-new',
      postId: 'post-1',
      projectId: 'bandori',
      authorId: 'reader-2',
      authorName: 'Saki',
      content: '나중 댓글',
      createdAt: DateTime.utc(2026, 7, 16),
    );
    await tester.pumpWidget(_buildSubject(comments: [_comments.first, newer]));
    await tester.pump();
    await tester.ensureVisible(find.text('등록순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록순'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('첫 댓글')).dy,
      lessThan(tester.getTopLeft(find.text('나중 댓글')).dy),
    );
    await tester.tap(find.text('최신순'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('나중 댓글')).dy,
      lessThan(tester.getTopLeft(find.text('첫 댓글')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('comment composer submits typed text with keyboard visible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var submissions = 0;
    await tester.pumpWidget(
      _buildSubject(
        isAuthenticated: true,
        textScale: 2,
        keyboardInset: 280,
        onSubmit: () => submissions++,
      ),
    );
    await tester.pump();
    final send = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '댓글 등록',
    );
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '공연장 가는 길이 궁금해요');
    await tester.pumpAndSettle();
    expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
    await tester.tap(send);
    expect(submissions, 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _buildSubject({
  bool isAuthenticated = false,
  double textScale = 1,
  double keyboardInset = 0,
  List<PostComment>? comments,
  VoidCallback? onSubmit,
  VoidCallback? onLike,
  VoidCallback? onSave,
}) {
  final commentController = TextEditingController();
  final commentFocusNode = FocusNode();
  final scrollController = ScrollController();

  addTearDown(commentController.dispose);
  addTearDown(commentFocusNode.dispose);
  addTearDown(scrollController.dispose);
  return ProviderScope(
    overrides: [
      userActiveTitleProvider(_post.authorId).overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      theme: GBTTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: PostDetailDocumentView(
          post: _post,
          commentsState: AsyncData(comments ?? _comments),
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
          onToggleLike: onLike ?? () {},
          onToggleBookmark: onSave ?? () {},
          onSubmitComment: onSubmit ?? () {},
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
