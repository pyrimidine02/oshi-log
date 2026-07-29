import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/data/dto/post_dto.dart';

void main() {
  test('PostSummaryDto parses swagger keys', () {
    final json = {
      'id': 'post-1',
      'projectId': 'proj-1',
      'authorId': 'user-1',
      'title': '커뮤니티 글 제목',
      'createdAt': '2026-01-28T03:00:00Z',
      'moderationStatus': 'QUARANTINED',
    };

    final dto = PostSummaryDto.fromJson(json);
    expect(dto.id, 'post-1');
    expect(dto.projectId, 'proj-1');
    expect(dto.authorId, 'user-1');
    expect(dto.title, '커뮤니티 글 제목');
    expect(dto.createdAt, isNotNull);
    expect(dto.moderationStatus, 'QUARANTINED');
  });

  test('PostSummaryDto parses topic and tags', () {
    final json = {
      'id': 'post-topic-1',
      'projectId': 'proj-1',
      'authorId': 'user-1',
      'title': '토픽/태그 테스트',
      'createdAt': '2026-03-08T00:00:00Z',
      'topic': '정보',
      'tags': ['라이브', '굿즈'],
    };

    final dto = PostSummaryDto.fromJson(json);
    expect(dto.topic, '정보');
    expect(dto.tags, ['라이브', '굿즈']);
  });

  test('PostSummaryDto parses alternate thumbnail keys from project feed', () {
    final json = {
      'id': 'post-alt-1',
      'projectId': 'proj-1',
      'authorId': 'user-1',
      'title': '대체 키 테스트',
      'createdAt': '2026-03-07T00:00:00Z',
      'coverImage': {'image_url': 'https://example.com/cover-from-object.webp'},
      'image_urls': [
        {'file_url': 'https://example.com/list-image-1.webp'},
      ],
    };

    final dto = PostSummaryDto.fromJson(json);
    expect(dto.thumbnailUrl, 'https://example.com/cover-from-object.webp');
    expect(dto.imageUrls, ['https://example.com/list-image-1.webp']);
  });

  test('PostSummaryDto falls back to thumbnail when image array is absent', () {
    final json = {
      'id': 'post-alt-2',
      'projectId': 'proj-1',
      'authorId': 'user-1',
      'title': 'thumbnail fallback',
      'createdAt': '2026-03-07T00:00:00Z',
      'thumbnail_image_url': 'https://example.com/thumb.webp',
    };

    final dto = PostSummaryDto.fromJson(json);
    expect(dto.thumbnailUrl, 'https://example.com/thumb.webp');
    expect(dto.imageUrls, ['https://example.com/thumb.webp']);
  });

  test('PostSummaryDto trims and filters invalid image URL entries', () {
    final json = {
      'id': 'post-alt-3',
      'projectId': 'proj-1',
      'authorId': 'user-1',
      'title': 'sanitize image urls',
      'createdAt': '2026-03-07T00:00:00Z',
      'imageUrls': [
        '   ',
        'null',
        ' https://example.com/a.webp ',
        {'file_url': ' https://example.com/b.webp '},
        {'cdn_url': 'null'},
      ],
    };

    final dto = PostSummaryDto.fromJson(json);
    expect(dto.imageUrls, [
      'https://example.com/a.webp',
      'https://example.com/b.webp',
    ]);
  });

  test(
    'PostSummaryDto falls back to thumbnail when image array has only invalid entries',
    () {
      final json = {
        'id': 'post-alt-4',
        'projectId': 'proj-1',
        'authorId': 'user-1',
        'title': 'thumbnail fallback from invalid image list',
        'createdAt': '2026-03-07T00:00:00Z',
        'thumbnailUrl': 'https://example.com/thumb.webp',
        'imageUrls': [
          ' ',
          'null',
          {'url': 'null'},
        ],
      };

      final dto = PostSummaryDto.fromJson(json);
      expect(dto.thumbnailUrl, 'https://example.com/thumb.webp');
      expect(dto.imageUrls, ['https://example.com/thumb.webp']);
    },
  );

  test('PostDetailDto parses swagger keys', () {
    final json = {
      'id': 'post-2',
      'projectId': 'proj-2',
      'authorId': 'user-2',
      'title': '상세 글 제목',
      'content': '상세 글 내용',
      'createdAt': '2026-01-28T05:00:00Z',
      'updatedAt': '2026-01-28T06:00:00Z',
      'moderationStatus': 'DELETED',
    };

    final dto = PostDetailDto.fromJson(json);
    expect(dto.id, 'post-2');
    expect(dto.projectId, 'proj-2');
    expect(dto.authorId, 'user-2');
    expect(dto.title, '상세 글 제목');
    expect(dto.content, '상세 글 내용');
    expect(dto.updatedAt, isNotNull);
    expect(dto.moderationStatus, 'DELETED');
  });

  test('PostCursorPageDto parses cursor payload', () {
    final json = {
      'items': [
        {
          'id': 'post-3',
          'projectId': 'proj-3',
          'authorId': 'user-3',
          'title': '커서 글',
          'createdAt': '2026-02-01T00:00:00Z',
          'commentCount': 1,
          'likeCount': 2,
        },
      ],
      'nextCursor': '2026-02-01T00:00:00Z',
      'hasNext': true,
    };

    final dto = PostCursorPageDto.fromJson(json);
    expect(dto.items, hasLength(1));
    expect(dto.items.first.id, 'post-3');
    expect(dto.nextCursor, '2026-02-01T00:00:00Z');
    expect(dto.hasNext, isTrue);
  });

  test('PostBookmarkStatusDto parses bookmark payload', () {
    final json = {
      'postId': 'post-4',
      'isBookmarked': true,
      'bookmarkedAt': '2026-02-01T03:00:00Z',
    };

    final dto = PostBookmarkStatusDto.fromJson(json);
    expect(dto.postId, 'post-4');
    expect(dto.isBookmarked, isTrue);
    expect(dto.bookmarkedAt, isNotNull);
  });

  test('PostBookmarkStatusDto serializes payload', () {
    final dto = PostBookmarkStatusDto(
      postId: 'post-serialize',
      isBookmarked: true,
      bookmarkedAt: DateTime.parse('2026-03-08T00:00:00Z'),
    );

    final json = dto.toJson();
    expect(json['postId'], 'post-serialize');
    expect(json['isBookmarked'], true);
    expect(json['bookmarkedAt'], '2026-03-08T00:00:00.000Z');
  });

  test('ProjectSubscriptionSummaryDto parses payload', () {
    final json = {
      'projectId': 'proj-id',
      'projectCode': 'bangdream',
      'projectName': 'BanG Dream',
      'subscribedAt': '2026-02-01T04:00:00Z',
    };

    final dto = ProjectSubscriptionSummaryDto.fromJson(json);
    expect(dto.projectId, 'proj-id');
    expect(dto.projectCode, 'bangdream');
    expect(dto.projectName, 'BanG Dream');
    expect(dto.subscribedAt, isNotNull);
  });

  test('PostComposeOptionsDto parses topic/tag catalogs', () {
    final json = {
      'topics': [
        {'id': 'topic-1', 'name': '정보', 'sortOrder': 10},
      ],
      'tags': [
        {'id': 'tag-1', 'name': '라이브', 'sortOrder': 20},
      ],
    };

    final dto = PostComposeOptionsDto.fromJson(json);
    expect(dto.topics, hasLength(1));
    expect(dto.tags, hasLength(1));
    expect(dto.topics.first.id, 'topic-1');
    expect(dto.topics.first.name, '정보');
    expect(dto.tags.first.id, 'tag-1');
    expect(dto.tags.first.name, '라이브');
  });

  test(
    'PostComposeOptionsDto keeps server ordering without client re-sort',
    () {
      final json = {
        'topics': [
          {'id': 'topic-b', 'name': '후기', 'sortOrder': 20},
          {'id': 'topic-a', 'name': '정보', 'sortOrder': 10},
        ],
        'tags': [
          {'id': 'tag-c', 'name': '굿즈', 'sortOrder': 30},
          {'id': 'tag-a', 'name': '라이브', 'sortOrder': 10},
        ],
      };

      final dto = PostComposeOptionsDto.fromJson(json);
      expect(dto.topics.map((item) => item.id), ['topic-b', 'topic-a']);
      expect(dto.tags.map((item) => item.id), ['tag-c', 'tag-a']);
    },
  );
}
