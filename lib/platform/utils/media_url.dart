/// EN: Media URL resolver for public CDN access.
/// KO: 공개 CDN 접근을 위한 미디어 URL 변환기.
library;

import '../config/app_config.dart';

const _publicMediaHost = 'r2.noraneko.cc';
const _legacyR2Suffix = 'r2.cloudflarestorage.com';
const _legacyBuckets = <String>{'girlsbandtabi', 'girlsbandtabi-dev'};
final _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
final _hostLikePattern = RegExp(r'^[^/\s]+\.[^/\s]+(/.*)?$');

/// EN: Normalize legacy R2 URLs into public CDN URLs.
/// KO: 레거시 R2 URL을 공개 CDN URL로 정규화합니다.
String resolveMediaUrl(String rawUrl) {
  if (rawUrl.isEmpty) return rawUrl;
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  final normalizedInput = _normalizeInputUrl(trimmed);
  final uri = Uri.tryParse(normalizedInput);
  if (uri == null || uri.host.isEmpty) return normalizedInput;

  final isLegacyR2 = uri.host.endsWith(_legacyR2Suffix);
  final isPublicR2 = uri.host == _publicMediaHost;
  if (!isLegacyR2 && !isPublicR2) return normalizedInput;

  final decodedPath = Uri.decodeFull(uri.path);
  final segments = decodedPath
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) return normalizedInput;

  if (_legacyBuckets.contains(segments.first)) {
    segments.removeAt(0);
  }

  final normalizedPath = '/${segments.join('/')}';
  return Uri(
    scheme: 'https',
    host: _publicMediaHost,
    path: normalizedPath,
  ).toString();
}

String _normalizeInputUrl(String rawUrl) {
  // EN: Keep absolute URLs untouched.
  // KO: 절대 URL은 그대로 유지합니다.
  if (_schemePattern.hasMatch(rawUrl)) {
    return rawUrl;
  }

  // EN: Support scheme-relative URLs from mixed payloads.
  // KO: 혼합 응답에서 내려오는 scheme-relative URL을 지원합니다.
  if (rawUrl.startsWith('//')) {
    return 'https:$rawUrl';
  }

  // EN: Support public host without scheme (e.g. r2.noraneko.cc/...).
  // KO: 스킴 없는 공개 호스트 URL(r2.noraneko.cc/...)을 지원합니다.
  if (rawUrl.startsWith('$_publicMediaHost/')) {
    return 'https://$rawUrl';
  }

  // EN: Resolve root-relative media paths against API base origin.
  // KO: 루트 상대 미디어 경로를 API base origin 기준으로 절대 경로화합니다.
  if (rawUrl.startsWith('/')) {
    if (_looksLikeR2ObjectKey(rawUrl)) {
      final objectKey = _normalizeR2ObjectKey(rawUrl);
      if (objectKey != null) {
        return _buildPublicMediaUrl(objectKey);
      }
    }
    return _resolveAgainstApiOrigin(rawUrl) ?? rawUrl;
  }

  // EN: Normalize host-like URLs with missing scheme.
  // KO: 스킴이 빠진 host 형태 URL을 정규화합니다.
  if (_hostLikePattern.hasMatch(rawUrl)) {
    return 'https://$rawUrl';
  }

  // EN: Some APIs return relative upload paths (uploads/...).
  // KO: 일부 API는 상대 업로드 경로(uploads/...)를 반환합니다.
  if (_looksLikeRelativeMediaPath(rawUrl)) {
    if (_looksLikeR2ObjectKey(rawUrl)) {
      final objectKey = _normalizeR2ObjectKey(rawUrl);
      if (objectKey != null) {
        return _buildPublicMediaUrl(objectKey);
      }
    }
    return _resolveAgainstApiOrigin('/$rawUrl') ?? rawUrl;
  }

  return rawUrl;
}

bool _looksLikeRelativeMediaPath(String value) {
  return value.startsWith('uploads/') ||
      value.startsWith('uploads%2F') ||
      value.startsWith('api/') ||
      value.startsWith('media/');
}

bool _looksLikeR2ObjectKey(String value) {
  final normalized = value.startsWith('/') ? value.substring(1) : value;
  return normalized.startsWith('uploads/') ||
      normalized.startsWith('uploads%2F');
}

String? _normalizeR2ObjectKey(String raw) {
  final withoutLeadingSlash = raw.startsWith('/') ? raw.substring(1) : raw;
  final decoded = Uri.decodeFull(withoutLeadingSlash).trim();
  if (decoded.isEmpty) return null;
  return decoded;
}

String _buildPublicMediaUrl(String objectKey) {
  final trimmed = objectKey.startsWith('/')
      ? objectKey.substring(1)
      : objectKey;
  return Uri(
    scheme: 'https',
    host: _publicMediaHost,
    path: '/$trimmed',
  ).toString();
}

String? _resolveAgainstApiOrigin(String path) {
  try {
    final baseUrl = AppConfig.instance.baseUrl;
    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null || baseUri.scheme.isEmpty || baseUri.host.isEmpty) {
      return null;
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.resolveUri(Uri(path: normalizedPath)).toString();
  } on Object {
    // EN: AppConfig may be uninitialized in isolated tests.
    // KO: 격리 테스트에서는 AppConfig가 초기화되지 않았을 수 있습니다.
    return null;
  }
}
