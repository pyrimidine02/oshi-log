import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/data/dto/news_dto.dart';

void main() {
  test('NewsSummaryDto parses swagger keys', () {
    final json = {
      'id': 'news-1',
      'title': '새 앨범 발표',
      'thumbnailUrl': 'https://example.com/news.png',
      'publishedAt': '2026-01-28T00:00:00Z',
    };

    final dto = NewsSummaryDto.fromJson(json);
    expect(dto.id, 'news-1');
    expect(dto.title, '새 앨범 발표');
    expect(dto.thumbnailUrl, 'https://example.com/news.png');
    expect(dto.publishedAt, isNotNull);
  });

  test('NewsDetailDto parses swagger keys', () {
    final json = {
      'id': 'news-2',
      'title': '투어 일정 공개',
      'body': '새 투어 일정이 공개되었습니다.',
      'status': 'PUBLISHED',
      'publishedAt': '2026-01-27T12:00:00Z',
      'images': [
        {
          'imageId': 'img-1',
          'url': 'https://example.com/detail.png',
          'filename': 'detail.png',
          'contentType': 'image/png',
          'fileSize': 1234,
          'uploadedAt': '2026-01-27T12:00:00Z',
          'isPrimary': true,
        },
      ],
    };

    final dto = NewsDetailDto.fromJson(json);
    expect(dto.id, 'news-2');
    expect(dto.title, '투어 일정 공개');
    expect(dto.body, '새 투어 일정이 공개되었습니다.');
    expect(dto.images.first.url, 'https://example.com/detail.png');
    expect(dto.publishedAt, isNotNull);
  });
}
