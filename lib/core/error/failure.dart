/// EN: Failure types for error handling using sealed class pattern
/// KO: sealed class 패턴을 사용한 에러 처리용 Failure 타입
library;

/// EN: Base sealed class for all failure types
/// KO: 모든 실패 타입의 기본 sealed 클래스
sealed class Failure {
  const Failure(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  /// EN: Returns user-friendly error message for UI display
  /// KO: UI 표시용 사용자 친화적 에러 메시지 반환
  String get userMessage;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// EN: Network-related failures (timeout, connection issues)
/// KO: 네트워크 관련 실패 (타임아웃, 연결 문제)
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage => '네트워크 연결을 확인해주세요';
}

/// EN: Authentication/Authorization failures
/// KO: 인증/인가 관련 실패
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage {
    return switch (code) {
      '401' => '로그인이 필요합니다',
      '403' => '접근 권한이 없습니다',
      'auth_required' => '로그인이 필요합니다',
      'token_expired' => '세션이 만료되었습니다. 다시 로그인해주세요',
      _ => '인증 오류가 발생했습니다',
    };
  }
}

/// EN: Server-side failures (5xx errors)
/// KO: 서버 측 실패 (5xx 에러)
final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.code,
    super.stackTrace,
    this.retryAfterMs,
  });

  /// EN: Optional server-provided retry hint in milliseconds.
  /// KO: 서버가 제공한 선택적 재시도 힌트(밀리초)입니다.
  final int? retryAfterMs;

  @override
  String get userMessage {
    return switch (code) {
      '500' => '서버 오류가 발생했습니다',
      '502' => '서버가 일시적으로 사용 불가능합니다',
      '503' => '서버 점검 중입니다',
      '429' => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요',
      _ => '서버 오류가 발생했습니다',
    };
  }
}

/// EN: Validation failures (invalid input, 422 errors)
/// KO: 유효성 검증 실패 (잘못된 입력, 422 에러)
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.code,
    super.stackTrace,
    this.fieldErrors,
    this.details,
  });

  final Map<String, List<String>>? fieldErrors;
  final Map<String, dynamic>? details;

  @override
  String get userMessage => switch (code) {
    'LIVE_EVENT_NOT_ATTENDABLE' => '취소되었거나 일정이 변경된 공연이라 참여할 수 없습니다',
    _ => '입력값이 올바르지 않습니다',
  };

  /// EN: Get error message for specific field
  /// KO: 특정 필드의 에러 메시지 반환
  String? getFieldError(String field) {
    return fieldErrors?[field]?.firstOrNull;
  }
}

/// EN: Cache-related failures
/// KO: 캐시 관련 실패
final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage {
    return switch (code) {
      'offline_cache_miss' => '오프라인 상태라 저장된 데이터를 찾을 수 없습니다',
      _ => '데이터를 불러올 수 없습니다',
    };
  }
}

/// EN: Location/Permission-related failures
/// KO: 위치/권한 관련 실패
final class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage {
    return switch (code) {
      'permission_denied' => '위치 권한을 허용해주세요',
      'permission_denied_forever' => '설정에서 위치 권한을 허용해주세요',
      'service_disabled' => '위치 서비스를 활성화해주세요',
      _ => '위치 정보를 가져올 수 없습니다',
    };
  }
}

/// EN: Not found failures (404 errors)
/// KO: 리소스 없음 실패 (404 에러)
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage => '요청하신 정보를 찾을 수 없습니다';
}

/// EN: Unknown/Unexpected failures
/// KO: 알 수 없는/예상치 못한 실패
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code, super.stackTrace});

  @override
  String get userMessage => '알 수 없는 오류가 발생했습니다';
}
