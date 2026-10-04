/// EN: Utilities for extracting and stripping image URLs from content.
/// KO: 콘텐츠에서 이미지 URL을 추출·제거하는 유틸리티.
library;

import 'media_url.dart';

// ========================================
// EN: Constants and patterns
// KO: 상수 및 패턴
// ========================================

const _publicR2Host = 'r2.noraneko.cc';
const _legacyR2Suffix = 'r2.cloudflarestorage.com';
const _imageExtensions = <String>{
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
  '.bmp',
  '.heic',
  '.heif',
};

final _markdownImagePattern = RegExp(r'!\[[^\]]*\]\(([^)\s]+)[^)]*\)');
final _htmlImagePattern = RegExp(
  r'''<img[^>]*src=["']([^"']+)["']''',
  caseSensitive: false,
);
final _urlPattern = RegExp(r'''(https?://[^\s)<>"']+)''');
final _bareR2Pattern = RegExp(
  r'''(?<!https://)(?<!http://)(r2\.noraneko\.cc/[^\s)<>"']+)''',
  caseSensitive: false,
);

// ========================================
// EN: Extract image URLs from content
// KO: 콘텐츠에서 이미지 URL 추출
// ========================================

/// EN: Extract all image URLs from content (markdown, HTML, inline).
/// KO: 콘텐츠에서 모든 이미지 URL을 추출합니다 (마크다운, HTML, 인라인).
List<String> extractImageUrls(String? content) {
  if (content == null || content.isEmpty) return const [];
  final urls = <String>{};
  urls.addAll(_extractMarkdownImageUrls(content));
  urls.addAll(_extractHtmlImageUrls(content));
  urls.addAll(_extractInlineImageUrls(content));
  return urls.toList();
}

/// EN: Strip image markdown/HTML/inline URLs from content text.
/// KO: 콘텐츠 텍스트에서 이미지 마크다운/HTML/인라인 URL을 제거합니다.
String stripImageMarkdown(String content) {
  if (content.isEmpty) return content;
  var sanitized = content
      .replaceAll(_markdownImagePattern, '')
      .replaceAll(_htmlImagePattern, '');
  sanitized = _stripInlineImageUrls(sanitized);
  sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  sanitized = sanitized.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return sanitized.trim();
}

// ========================================
// EN: Internal helpers
// KO: 내부 헬퍼
// ========================================

List<String> _extractMarkdownImageUrls(String content) {
  return _markdownImagePattern
      .allMatches(content)
      .map((match) => match.group(1) ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
}

List<String> _extractHtmlImageUrls(String content) {
  return _htmlImagePattern
      .allMatches(content)
      .map((match) => match.group(1) ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
}

List<String> _extractInlineImageUrls(String content) {
  final urls = <String>[];
  urls.addAll(
    _urlPattern
        .allMatches(content)
        .map((match) => match.group(1) ?? '')
        .where(_isLikelyImageUrl),
  );
  urls.addAll(
    _bareR2Pattern
        .allMatches(content)
        .map((match) => match.group(1) ?? '')
        .where((url) => _isLikelyImageUrl(_ensureScheme(url))),
  );
  return urls;
}

String _stripInlineImageUrls(String content) {
  var sanitized = content.replaceAllMapped(_urlPattern, (match) {
    final url = match.group(1) ?? '';
    return _isLikelyImageUrl(url) ? '' : url;
  });
  sanitized = sanitized.replaceAllMapped(_bareR2Pattern, (match) {
    final url = match.group(1) ?? '';
    return _isLikelyImageUrl(_ensureScheme(url)) ? '' : url;
  });
  return sanitized;
}

bool _isLikelyImageUrl(String value) {
  if (value.isEmpty) return false;
  final resolvedValue = resolveMediaUrl(_ensureScheme(value));
  final uri = Uri.tryParse(resolvedValue);
  if (uri == null || uri.host.isEmpty) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  if (host == _publicR2Host || host.endsWith(_legacyR2Suffix)) {
    return true;
  }

  final path = uri.path.toLowerCase();
  return _imageExtensions.any(path.endsWith);
}

String _ensureScheme(String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('r2.noraneko.cc/')) {
    return 'https://$value';
  }
  return value;
}
