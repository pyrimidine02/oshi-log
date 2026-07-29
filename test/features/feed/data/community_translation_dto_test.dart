import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/data/dto/community_translation_dto.dart';

void main() {
  test(
    'CommunityTranslationRequestDto serializes optional source language',
    () {
      const dto = CommunityTranslationRequestDto(
        text: '今日のライブ最高でした！',
        targetLanguage: 'ko',
        sourceLanguage: 'ja',
      );

      final json = dto.toJson();
      expect(json['text'], '今日のライブ最高でした！');
      expect(json['targetLanguage'], 'ko');
      expect(json['sourceLanguage'], 'ja');
    },
  );

  test('CommunityTranslationDto parses response payload', () {
    final json = {
      'originalText': '今日のライブ最高でした！',
      'translatedText': '오늘 라이브 정말 최고였어요!',
      'sourceLanguage': 'ja',
      'targetLanguage': 'ko',
      'translated': true,
    };

    final dto = CommunityTranslationDto.fromJson(json);
    expect(dto.originalText, '今日のライブ最高でした！');
    expect(dto.translatedText, '오늘 라이브 정말 최고였어요!');
    expect(dto.sourceLanguage, 'ja');
    expect(dto.targetLanguage, 'ko');
    expect(dto.translated, isTrue);
  });
}
