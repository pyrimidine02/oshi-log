/// EN: Redaction helpers for network diagnostics.
/// KO: 네트워크 진단 로그용 마스킹 도우미입니다.
library;

import 'dart:convert';

/// EN: Stable placeholder used in place of sensitive network values.
/// KO: 민감한 네트워크 값을 대신하는 고정 표시자입니다.
const String redactedNetworkLogValue = '***';

final RegExp _nonAlphaNumeric = RegExp('[^a-z0-9]');
final RegExp _plainTextSensitiveKey = RegExp(
  r'\b(?:access[\s_-]*token|refresh[\s_-]*token|id[\s_-]*token|authorization|password|passwd|client[\s_-]*secret|api[\s_-]*key|cookie|session[\s_-]*id)\b',
  caseSensitive: false,
);
final RegExp _bearerCredential = RegExp(
  r'\bBearer\s+[A-Za-z0-9._~+/=-]+',
  caseSensitive: false,
);
final RegExp _jwtCredential = RegExp(
  r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
);

/// EN: Return a recursively redacted copy suitable for diagnostic logs.
/// KO: 진단 로그에 사용할 수 있도록 재귀적으로 마스킹한 복사본을 반환합니다.
dynamic sanitizeNetworkLogData(dynamic data) {
  if (data is Map) {
    return <dynamic, dynamic>{
      for (final entry in data.entries)
        entry.key: _isSensitiveKey(entry.key)
            ? redactedNetworkLogValue
            : sanitizeNetworkLogData(entry.value),
    };
  }

  if (data is List) {
    return <dynamic>[for (final value in data) sanitizeNetworkLogData(value)];
  }

  if (data is String) {
    return _sanitizeNetworkLogString(data);
  }

  return data;
}

/// EN: Return a bounded structural summary for potentially large bodies.
/// KO: 큰 본문을 위해 크기가 제한된 구조 요약을 반환합니다.
dynamic summarizeNetworkLogData(dynamic data, {int depth = 0}) {
  if (depth >= 3) return _summaryLeaf(data);

  if (data is Map) {
    final entries = data.entries.take(12);
    return <dynamic, dynamic>{
      for (final entry in entries)
        entry.key: _isSensitiveKey(entry.key)
            ? redactedNetworkLogValue
            : summarizeNetworkLogData(entry.value, depth: depth + 1),
      if (data.length > 12) '...': '${data.length - 12} more keys',
    };
  }

  if (data is List) return 'List(${data.length})';
  if (data is String) {
    if (data.length > 4096) return 'String(${data.length})';
    final sanitized = _sanitizeNetworkLogString(data);
    if (sanitized is! String) {
      return summarizeNetworkLogData(sanitized, depth: depth);
    }
    if (sanitized.length <= 160) return sanitized;
    return '${sanitized.substring(0, 160)}… (${sanitized.length} chars)';
  }

  return data == null || data is num || data is bool
      ? data
      : data.runtimeType.toString();
}

dynamic _summaryLeaf(dynamic data) {
  if (data is Map) return 'Map(${data.length})';
  if (data is List) return 'List(${data.length})';
  if (data is String) {
    if (data.length > 4096) return 'String(${data.length})';
    final sanitized = _sanitizeNetworkLogString(data);
    if (sanitized is! String) return _summaryLeaf(sanitized);
    if (sanitized.length > 80) {
      return '${sanitized.substring(0, 80)}… (${sanitized.length} chars)';
    }
    return sanitized;
  }
  return data == null || data is num || data is bool
      ? data
      : data.runtimeType.toString();
}

dynamic _sanitizeNetworkLogString(String value) {
  final trimmed = value.trimLeft();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      // EN: Plain-text proxy responses can still contain JSON credentials.
      // KO: 평문 프록시 응답에도 JSON 인증 정보가 담길 수 있습니다.
      return sanitizeNetworkLogData(jsonDecode(value));
    } on FormatException {
      // EN: Continue with conservative plain-text redaction.
      // KO: 보수적인 평문 마스킹으로 계속합니다.
    }
  }

  final withoutBearer = value.replaceAll(_bearerCredential, 'Bearer ***');
  final withoutJwt = withoutBearer.replaceAll(
    _jwtCredential,
    redactedNetworkLogValue,
  );
  if (_plainTextSensitiveKey.hasMatch(withoutJwt)) {
    // EN: For unstructured bodies, dropping the whole value is safer than
    //     guessing where an HTML or vendor-specific credential ends.
    // KO: 비정형 본문은 HTML이나 벤더별 인증 값의 끝을
    //     추측하기보다 전체 값을 숨기는 편이 안전합니다.
    return redactedNetworkLogValue;
  }
  return withoutJwt;
}

/// EN: Return a URI copy with sensitive query values redacted.
/// KO: 민감한 쿼리 값을 마스킹한 URI 복사본을 반환합니다.
Uri sanitizeNetworkLogUri(Uri uri) {
  if (!uri.hasQuery) return uri;

  final sanitizedQuery = <String, dynamic>{
    for (final entry in uri.queryParametersAll.entries)
      entry.key: _isSensitiveKey(entry.key)
          ? <String>[
              for (var index = 0; index < entry.value.length; index++)
                redactedNetworkLogValue,
            ]
          : List<String>.of(entry.value),
  };

  return uri.replace(queryParameters: sanitizedQuery);
}

bool _isSensitiveKey(dynamic key) {
  if (key is! String) return false;

  final normalized = key.toLowerCase().replaceAll(_nonAlphaNumeric, '');
  return normalized.contains('token') ||
      normalized.contains('authorization') ||
      normalized.contains('password') ||
      normalized.contains('passwd') ||
      normalized.contains('secret') ||
      normalized.contains('credential') ||
      normalized == 'cookie' ||
      normalized == 'cookies' ||
      normalized == 'setcookie' ||
      normalized == 'apikey' ||
      normalized == 'privatekey' ||
      normalized == 'sessionid';
}
