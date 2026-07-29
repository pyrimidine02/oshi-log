import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/feed/application/community_translation_controller.dart';

void main() {
  group('normalizeTranslationLanguageCode', () {
    test('returns allowed language codes as-is', () {
      expect(normalizeTranslationLanguageCode('ko'), 'ko');
      expect(normalizeTranslationLanguageCode('en'), 'en');
      expect(normalizeTranslationLanguageCode('ja'), 'ja');
    });

    test('normalizes casing and falls back to en for unsupported code', () {
      expect(normalizeTranslationLanguageCode('JA'), 'ja');
      expect(normalizeTranslationLanguageCode('fr'), 'en');
      expect(normalizeTranslationLanguageCode(null), 'en');
    });
  });

  group('detectLikelyTranslationLanguage', () {
    test('detects Korean, Japanese, and English text', () {
      expect(detectLikelyTranslationLanguage('오늘 라이브 최고'), 'ko');
      expect(detectLikelyTranslationLanguage('ライブ最高です'), 'ja');
      expect(detectLikelyTranslationLanguage('Best live ever'), 'en');
    });

    test('returns null for empty or unknown script text', () {
      expect(detectLikelyTranslationLanguage('   '), isNull);
      expect(detectLikelyTranslationLanguage('12345 !!!'), isNull);
    });
  });

  test('CommunityTranslationCacheKey builds deterministic storage key', () {
    const key = CommunityTranslationCacheKey(
      contentId: 'post:123',
      targetLanguage: 'ko',
    );
    expect(key.storageKey, 'post:123::ko');
  });
}
