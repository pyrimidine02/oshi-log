import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/data/dto/post_comment_dto.dart';

void main() {
  test('PostCreateRequestDto sends v3 required fields', () {
    const dto = PostCreateRequestDto(
      title: '제목',
      content: '본문',
      imageUploadIds: ['upload-1'],
    );

    final json = dto.toJson();
    expect(json['title'], '제목');
    expect(json['content'], '본문');
    expect(json['imageUploadIds'], ['upload-1']);
    expect(json['conversationControl'], 'EVERYONE');
    expect(json['mentionedUserIds'], isA<List<dynamic>>());
  });

  test('PostCreateRequestDto includes topic and tags when selected', () {
    const dto = PostCreateRequestDto(
      title: '제목',
      content: '본문',
      topic: '정보',
      tags: ['라이브', '굿즈'],
    );

    final json = dto.toJson();
    expect(json['topic'], '정보');
    expect(json['tags'], ['라이브', '굿즈']);
  });

  test(
    'PostCommentCreateRequestDto includes parentCommentId when provided',
    () {
      const dto = PostCommentCreateRequestDto(
        content: '답글',
        parentCommentId: 'comment-1',
      );

      final json = dto.toJson();
      expect(json['content'], '답글');
      expect(json['parentCommentId'], 'comment-1');
    },
  );

  test('CommentThreadNodeDto parses nested thread payload', () {
    final json = {
      'comment': {
        'id': 'c1',
        'postId': 'p1',
        'projectId': 'proj',
        'authorId': 'u1',
        'content': 'root',
        'createdAt': '2026-02-01T00:00:00Z',
        'replyCount': 1,
      },
      'replies': [
        {
          'comment': {
            'id': 'c2',
            'postId': 'p1',
            'projectId': 'proj',
            'authorId': 'u2',
            'content': 'reply',
            'createdAt': '2026-02-01T01:00:00Z',
            'parentCommentId': 'c1',
            'depth': 1,
            'replyCount': 0,
          },
          'replies': [],
          'hasMoreReplies': false,
        },
      ],
      'hasMoreReplies': false,
    };

    final dto = CommentThreadNodeDto.fromJson(json);
    expect(dto.comment.id, 'c1');
    expect(dto.comment.replyCount, 1);
    expect(dto.replies, hasLength(1));
    expect(dto.replies.first.comment.parentCommentId, 'c1');
    expect(dto.replies.first.comment.depth, 1);
  });
}
