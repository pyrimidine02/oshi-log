/// EN: Error handler for mapping various exceptions to Failure types
/// KO: 다양한 예외를 Failure 타입으로 매핑하는 에러 핸들러
library;

import 'dart:io';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import 'failure.dart';

/// EN: Centralized error handler for the application
/// KO: 앱의 중앙화된 에러 핸들러
class ErrorHandler {
  ErrorHandler._();

  /// EN: Map DioException to appropriate Failure type
  /// KO: DioException을 적절한 Failure 타입으로 매핑
  static Failure mapDioError(DioException e) {
    AppLogger.error('DioError occurred', error: e, stackTrace: e.stackTrace);

    return switch (e.type) {
      DioExceptionType.connectionTimeout => NetworkFailure(
        'Connection timeout',
        code: 'connection_timeout',
        stackTrace: e.stackTrace,
      ),
      DioExceptionType.receiveTimeout => NetworkFailure(
        'Receive timeout',
        code: 'receive_timeout',
        stackTrace: e.stackTrace,
      ),
      DioExceptionType.sendTimeout => NetworkFailure(
        'Send timeout',
        code: 'send_timeout',
        stackTrace: e.stackTrace,
      ),
      DioExceptionType.badResponse => _mapStatusCode(
        e.response?.statusCode,
        e.response?.data,
        e.response?.headers,
        e.stackTrace,
      ),
      DioExceptionType.connectionError => NetworkFailure(
        'Connection error',
        code: 'connection_error',
        stackTrace: e.stackTrace,
      ),
      DioExceptionType.cancel => NetworkFailure(
        'Request cancelled',
        code: 'cancelled',
        stackTrace: e.stackTrace,
      ),
      _ => NetworkFailure(
        e.message ?? 'Network error',
        stackTrace: e.stackTrace,
      ),
    };
  }

  /// EN: Map HTTP status code to appropriate Failure type
  /// KO: HTTP 상태 코드를 적절한 Failure 타입으로 매핑
  static Failure _mapStatusCode(
    int? code,
    dynamic data,
    Headers? headers,
    StackTrace? stackTrace,
  ) {
    final message = _extractErrorMessage(data);
    final errorCode = _extractErrorCode(data);
    final isCsrfFailure = _isCsrfFailure(message, data);

    return switch (code) {
      400 => ValidationFailure(
        message ?? 'Bad request',
        code: errorCode ?? '400',
        stackTrace: stackTrace,
        fieldErrors: _extractFieldErrors(data),
        details: _extractErrorDetails(data),
      ),
      401 => AuthFailure(
        message ?? 'Unauthorized',
        code: '401',
        stackTrace: stackTrace,
      ),
      403 => AuthFailure(
        message ?? 'Forbidden',
        code: isCsrfFailure ? 'auth_required' : (errorCode ?? '403'),
        stackTrace: stackTrace,
      ),
      404 => NotFoundFailure(
        message ?? 'Not found',
        code: '404',
        stackTrace: stackTrace,
      ),
      409 => ValidationFailure(
        message ?? 'Conflict',
        code: errorCode ?? '409',
        stackTrace: stackTrace,
        fieldErrors: _extractFieldErrors(data),
        details: _extractErrorDetails(data),
      ),
      422 => ValidationFailure(
        message ?? 'Validation error',
        code: errorCode ?? '422',
        stackTrace: stackTrace,
        fieldErrors: _extractFieldErrors(data),
        details: _extractErrorDetails(data),
      ),
      429 => ServerFailure(
        message ?? 'Too many requests',
        code: '429',
        stackTrace: stackTrace,
        retryAfterMs: _extractRetryAfterMs(data, headers),
      ),
      500 => ServerFailure(
        message ?? 'Internal server error',
        code: '500',
        stackTrace: stackTrace,
      ),
      502 => ServerFailure(
        message ?? 'Bad gateway',
        code: '502',
        stackTrace: stackTrace,
      ),
      503 => ServerFailure(
        message ?? 'Service unavailable',
        code: '503',
        stackTrace: stackTrace,
      ),
      _ => ServerFailure(
        message ?? 'Unknown error ($code)',
        code: code?.toString(),
        stackTrace: stackTrace,
      ),
    };
  }

  /// EN: Extract error message from response data
  /// KO: 응답 데이터에서 에러 메시지 추출
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      // EN: Try common error message fields.
      // KO: 일반적인 에러 메시지 필드 시도.
      final message = data['message'];
      if (message is String) return message;

      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final nested = error['message'];
        if (nested is String) return nested;
      }
      if (error is String) return error;
    }
    return null;
  }

  /// EN: Check if response indicates CSRF failure.
  /// KO: 응답이 CSRF 실패를 나타내는지 확인합니다.
  static bool _isCsrfFailure(String? message, dynamic data) {
    final messageLower = message?.toLowerCase();
    if (messageLower != null && messageLower.contains('csrf')) {
      return true;
    }

    if (data is Map<String, dynamic>) {
      final details = data['details'];
      if (details is List) {
        return details.whereType<String>().any(
          (detail) => detail.toLowerCase().contains('csrf'),
        );
      }
      if (details is String && details.toLowerCase().contains('csrf')) {
        return true;
      }
    }

    return false;
  }

  /// EN: Extract error code from response data
  /// KO: 응답 데이터에서 에러 코드를 추출
  static String? _extractErrorCode(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return null;

    final code = data['code'];
    if (code is String && code.isNotEmpty) return code;

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final nested = error['code'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    return null;
  }

  /// EN: Extract field-specific validation errors
  /// KO: 필드별 유효성 검증 에러 추출
  static Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return null;

    final fieldErrors = data['error']?['fieldErrors'] ?? data['fieldErrors'];
    if (fieldErrors == null || fieldErrors is! Map<String, dynamic>) {
      return null;
    }

    return fieldErrors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.cast<String>());
      }
      if (value is String) {
        return MapEntry(key, [value]);
      }
      return MapEntry(key, <String>[]);
    });
  }

  /// EN: Extract structured error details payload when present.
  /// KO: 구조화된 에러 상세(details) 페이로드가 있으면 추출합니다.
  static Map<String, dynamic>? _extractErrorDetails(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final nestedDetails = error['details'];
      if (nestedDetails is Map<String, dynamic>) {
        return nestedDetails;
      }
      if (nestedDetails is Map) {
        return nestedDetails.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    final directDetails = data['details'];
    if (directDetails is Map<String, dynamic>) {
      return directDetails;
    }
    if (directDetails is Map) {
      return directDetails.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  /// EN: Extract rate-limit retry delay in milliseconds from body/headers.
  /// KO: 응답 본문/헤더에서 속도 제한 재시도 대기 시간(밀리초)을 추출합니다.
  static int? _extractRetryAfterMs(dynamic data, Headers? headers) {
    final bodyMs = _extractRetryAfterFromBody(data);
    if (bodyMs != null && bodyMs > 0) {
      return bodyMs;
    }

    final retryAfterHeader = headers?.value('retry-after');
    final retryAfterMsFromHeader = _parseRetryAfterHeader(retryAfterHeader);
    if (retryAfterMsFromHeader != null && retryAfterMsFromHeader > 0) {
      return retryAfterMsFromHeader;
    }

    final rateLimitResetHeader =
        headers?.value('x-ratelimit-reset') ??
        headers?.value('x-rate-limit-reset');
    final rateLimitResetMs = _parseRateLimitResetHeader(rateLimitResetHeader);
    if (rateLimitResetMs != null && rateLimitResetMs > 0) {
      return rateLimitResetMs;
    }

    return null;
  }

  /// EN: Parse retry-after hint from JSON response body.
  /// KO: JSON 응답 본문의 retry-after 힌트를 파싱합니다.
  static int? _extractRetryAfterFromBody(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final nested = _parseRetryAfterValue(error['retryAfter']);
      if (nested != null) return nested;
      final nestedMs = _parseRetryAfterValue(error['retryAfterMs']);
      if (nestedMs != null) return nestedMs;
    }

    final direct = _parseRetryAfterValue(data['retryAfter']);
    if (direct != null) return direct;
    return _parseRetryAfterValue(data['retryAfterMs']);
  }

  /// EN: Parse retry-after field as milliseconds.
  /// KO: retry-after 필드를 밀리초로 파싱합니다.
  static int? _parseRetryAfterValue(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      if (value <= 0) return null;
      // EN: Backend body currently provides retryAfter in milliseconds.
      // KO: 현재 백엔드 본문 retryAfter는 밀리초 단위를 사용합니다.
      return value.round();
    }
    if (value is! String) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// EN: Parse `Retry-After` header as milliseconds.
  /// KO: `Retry-After` 헤더를 밀리초로 파싱합니다.
  static int? _parseRetryAfterHeader(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();

    final seconds = int.tryParse(trimmed);
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds).inMilliseconds;
    }

    DateTime? parsedDate;
    try {
      parsedDate = HttpDate.parse(trimmed);
    } catch (_) {
      parsedDate = DateTime.tryParse(trimmed);
    }
    if (parsedDate == null) return null;
    final now = DateTime.now().toUtc();
    final delay = parsedDate.toUtc().difference(now);
    if (delay <= Duration.zero) return null;
    return delay.inMilliseconds;
  }

  /// EN: Parse `X-RateLimit-Reset` header as milliseconds until retry.
  /// KO: `X-RateLimit-Reset` 헤더를 재시도까지 남은 밀리초로 파싱합니다.
  static int? _parseRateLimitResetHeader(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;

    final now = DateTime.now();
    // EN: Epoch milliseconds.
    // KO: epoch 밀리초.
    if (parsed > 1000000000000) {
      final target = DateTime.fromMillisecondsSinceEpoch(parsed, isUtc: true);
      final delay = target.difference(now.toUtc());
      return delay > Duration.zero ? delay.inMilliseconds : null;
    }
    // EN: Epoch seconds.
    // KO: epoch 초.
    if (parsed > 1000000000) {
      final target = DateTime.fromMillisecondsSinceEpoch(
        parsed * 1000,
        isUtc: true,
      );
      final delay = target.difference(now.toUtc());
      return delay > Duration.zero ? delay.inMilliseconds : null;
    }
    // EN: Seconds until reset.
    // KO: reset까지 남은 초.
    return Duration(seconds: parsed).inMilliseconds;
  }

  /// EN: Map general exceptions to Failure type
  /// KO: 일반 예외를 Failure 타입으로 매핑
  static Failure mapException(Object e, [StackTrace? stackTrace]) {
    AppLogger.error('Exception occurred', error: e, stackTrace: stackTrace);

    if (e is DioException) {
      return mapDioError(e);
    }

    if (e is SocketException) {
      return NetworkFailure(
        'No internet connection',
        code: 'no_internet',
        stackTrace: stackTrace,
      );
    }

    if (e is FormatException) {
      return ValidationFailure(
        'Invalid data format',
        code: 'format_error',
        stackTrace: stackTrace,
      );
    }

    if (e is Failure) {
      return e;
    }

    return UnknownFailure(e.toString(), stackTrace: stackTrace);
  }
}
