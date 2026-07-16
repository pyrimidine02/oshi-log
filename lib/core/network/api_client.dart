/// EN: Dio-based API client with JWT interceptor and error handling
/// KO: JWT 인터셉터와 에러 처리를 포함한 Dio 기반 API 클라이언트
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../error/error_handler.dart';
import '../error/failure.dart';
import '../logging/app_logger.dart';
import '../security/secure_storage.dart';
import '../utils/result.dart';
import 'network_log_sanitizer.dart';

/// EN: API client for making HTTP requests
/// KO: HTTP 요청을 위한 API 클라이언트
class ApiClient {
  ApiClient({
    required SecureStorage secureStorage,
    VoidCallback? onUnauthorized,
    VoidCallback? onTokenRefreshed,
    Dio? dio,
  }) : _secureStorage = secureStorage,
       _onUnauthorized = onUnauthorized,
       _onTokenRefreshed = onTokenRefreshed,
       _dio = dio ?? Dio() {
    _setupDio();
  }

  final Dio _dio;
  final SecureStorage _secureStorage;
  final VoidCallback? _onUnauthorized;
  final VoidCallback? _onTokenRefreshed;
  late final _AuthInterceptor _authInterceptor;

  /// EN: Setup Dio with base configuration and interceptors
  /// KO: 기본 구성 및 인터셉터로 Dio 설정
  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.instance.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiTimeouts.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiTimeouts.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiTimeouts.sendTimeout),
      headers: {
        ApiHeaders.accept: ApiHeaders.applicationJson,
        ApiHeaders.contentType: ApiHeaders.applicationJson,
        ApiHeaders.clientType: ApiHeaders.clientTypeMobile,
      },
    );

    _authInterceptor = _AuthInterceptor(
      _secureStorage,
      _dio,
      onUnauthorized: _onUnauthorized,
      onTokenRefreshed: _onTokenRefreshed,
    );
    _dio.interceptors.addAll([_authInterceptor, _LoggingInterceptor()]);
  }

  /// EN: Proactively refresh the access token if it is known to have expired.
  /// EN: Returns true when the token is valid (or was successfully refreshed).
  /// EN: Used by non-Dio transports (e.g. SSE) that bypass the Dio interceptor.
  /// KO: 액세스 토큰이 만료된 경우 선제적으로 갱신합니다.
  /// KO: 토큰이 유효하거나 갱신에 성공하면 true를 반환합니다.
  /// KO: Dio 인터셉터를 거치지 않는 전송(예: SSE)에서 사용됩니다.
  Future<bool> proactiveRefreshIfExpired() {
    return _authInterceptor.proactiveRefreshIfExpired();
  }

  // ========================================
  // EN: GET Request
  // KO: GET 요청
  // ========================================
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return Result.failure(ErrorHandler.mapDioError(e));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  // ========================================
  // EN: POST Request
  // KO: POST 요청
  // ========================================
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return Result.failure(ErrorHandler.mapDioError(e));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  // ========================================
  // EN: PUT Request
  // KO: PUT 요청
  // ========================================
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return Result.failure(ErrorHandler.mapDioError(e));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  // ========================================
  // EN: PATCH Request
  // KO: PATCH 요청
  // ========================================
  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return Result.failure(ErrorHandler.mapDioError(e));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  // ========================================
  // EN: DELETE Request
  // KO: DELETE 요청
  // ========================================
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return Result.failure(ErrorHandler.mapDioError(e));
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  // ========================================
  // EN: Response Handler
  // KO: 응답 핸들러
  // ========================================
  Result<T> _handleResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? fromJson,
  ) {
    final data = response.data;

    // EN: Handle ApiResponse wrapper
    // KO: ApiResponse 래퍼 처리
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? true;
      if (!success) {
        final error = data['error'];
        final message = error?['message'] as String? ?? 'Unknown error';
        final code = error?['code'] as String?;
        return Result.failure(ServerFailure(message, code: code));
      }

      // EN: Extract data from wrapper if present
      // KO: 래퍼에서 데이터 추출
      final responseData = data['data'] ?? data;

      if (fromJson != null) {
        try {
          return Result.success(fromJson(responseData));
        } catch (e, stackTrace) {
          AppLogger.error(
            'JSON parsing error',
            error: e,
            stackTrace: stackTrace,
          );
          return Result.failure(
            ValidationFailure(
              'Failed to parse response',
              stackTrace: stackTrace,
            ),
          );
        }
      }

      return Result.success(responseData as T);
    }

    if (fromJson != null) {
      return Result.success(fromJson(data));
    }

    return Result.success(data as T);
  }
}

/// EN: Auth interceptor for JWT token management
/// KO: JWT 토큰 관리를 위한 인증 인터셉터
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(
    this._secureStorage,
    this._dio, {
    this.onUnauthorized,
    this.onTokenRefreshed,
  });

  final SecureStorage _secureStorage;
  final Dio _dio;
  final VoidCallback? onUnauthorized;
  final VoidCallback? onTokenRefreshed;
  Future<_RefreshOutcome>? _refreshFuture;

  static const Set<String> _invalidRefreshErrorCodes = {
    'INVALID_REFRESH_TOKEN',
    'REFRESH_TOKEN_EXPIRED',
    'TOKEN_EXPIRED',
    'UNAUTHORIZED',
    'AUTHENTICATION_FAILED',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // EN: Skip auth for public endpoints
    // KO: 공개 엔드포인트는 인증 건너뛰기
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // EN: Proactively refresh the access token when it is known to be expired.
    // EN: This prevents a 401 round-trip on the very first request after the
    // EN: token silently expires while the app is backgrounded or idle.
    // EN: Deduplication is provided by _refreshOrWait(), so concurrent requests
    // EN: only trigger a single refresh call.
    // KO: 액세스 토큰이 만료된 것으로 확인되면 요청 전에 선제 갱신합니다.
    // KO: 앱 백그라운드/유휴 상태에서 토큰이 조용히 만료된 직후
    // KO: 첫 번째 요청에서 불필요한 401 왕복을 방지합니다.
    // KO: _refreshOrWait()이 중복 제거를 처리하므로 동시 요청은
    // KO: 하나의 갱신 호출만 트리거합니다.
    if (await _secureStorage.isTokenExpired()) {
      final outcome = await _refreshOrWait();
      if (outcome == _RefreshOutcome.invalidSession) {
        await _secureStorage.clearTokens();
        onUnauthorized?.call();
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Session invalidated; re-login required.',
            type: DioExceptionType.cancel,
          ),
          true,
        );
      }
      // EN: On transient refresh failure continue with the current (stale) token;
      // EN: onError will attempt another refresh on the resulting 401.
      // KO: 일시적 갱신 실패 시 현재 (만료) 토큰으로 계속 진행합니다;
      // KO: 발생하는 401에서 onError가 재갱신을 시도합니다.
    }

    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers[ApiHeaders.authorization] = '${ApiHeaders.bearer} $token';
    }

    handler.next(options);
  }

  /// EN: Proactively refresh the access token if it is known to have expired.
  /// EN: Returns true when the token is valid or was successfully refreshed.
  /// KO: 만료된 경우 액세스 토큰을 선제 갱신합니다.
  /// KO: 토큰이 유효하거나 갱신에 성공하면 true를 반환합니다.
  Future<bool> proactiveRefreshIfExpired() async {
    final isExpired = await _secureStorage.isTokenExpired();
    if (!isExpired) return true;
    final outcome = await _refreshOrWait();
    return outcome == _RefreshOutcome.refreshed;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // EN: Never attempt token refresh for refresh endpoint errors.
    // KO: refresh 엔드포인트 오류에서는 토큰 갱신을 재시도하지 않습니다.
    if (err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 403 && _isCsrfFailure(err.response?.data)) {
      // EN: CSRF errors do not always mean session invalidation on mobile.
      // KO: 모바일에서 CSRF 에러가 항상 세션 무효화를 의미하지는 않습니다.
      AppLogger.warning(
        'Detected CSRF-like 403 response; preserving tokens',
        tag: 'AuthInterceptor',
      );
      return handler.next(err);
    }

    // EN: Handle 401 Unauthorized and 403 Forbidden - try to refresh token (deduplicated).
    // EN: Some servers return 403 for expired tokens instead of 401.
    // EN: Guard with _authRetried flag to prevent infinite retry loops.
    // KO: 401 Unauthorized 및 403 Forbidden 처리 - 토큰 갱신 시도(중복 방지).
    // KO: 일부 서버는 만료된 토큰에 대해 401 대신 403을 반환합니다.
    // KO: 무한 재시도 루프 방지를 위해 _authRetried 플래그를 사용합니다.
    final alreadyRetried = err.requestOptions.extra['_authRetried'] == true;
    if (!alreadyRetried &&
        (err.response?.statusCode == 401 || err.response?.statusCode == 403)) {
      try {
        final refreshOutcome = await _refreshOrWait();
        if (refreshOutcome == _RefreshOutcome.refreshed) {
          // EN: Retry original request with new token (mark to prevent re-retry).
          // KO: 새 토큰으로 원래 요청 재시도 (재재시도 방지 마킹).
          final token = await _secureStorage.getAccessToken();
          err.requestOptions.headers[ApiHeaders.authorization] =
              '${ApiHeaders.bearer} $token';
          err.requestOptions.extra['_authRetried'] = true;
          try {
            final response = await _dio.fetch(err.requestOptions);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            // EN: Refresh succeeded but retried request failed (for example 5xx).
            // EN: Propagate the retried request error itself instead of the original
            // EN: 401/403, so the UI receives the real failure cause.
            // KO: 토큰 갱신은 성공했지만 재시도 요청이 실패한 경우(예: 5xx),
            // KO: 원본 401/403이 아닌 재시도 요청 오류를 그대로 전달합니다.
            AppLogger.error(
              'Retried request failed after token refresh',
              error: retryError,
            );
            return handler.next(retryError);
          }
        }

        if (refreshOutcome == _RefreshOutcome.invalidSession) {
          // EN: Clear tokens only when refresh token is definitively invalid.
          // KO: 리프레시 토큰이 확실히 무효할 때만 토큰을 삭제합니다.
          AppLogger.warning(
            'Refresh token invalid; clearing local auth tokens',
            tag: 'AuthInterceptor',
          );
          await _secureStorage.clearTokens();
          onUnauthorized?.call();
        } else {
          AppLogger.warning(
            'Token refresh failed transiently; keeping current session',
            tag: 'AuthInterceptor',
          );
        }
      } catch (e) {
        AppLogger.error('Token refresh flow failed', error: e);
      }
    }

    handler.next(err);
  }

  bool _isCsrfFailure(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.toLowerCase().contains('csrf')) {
        return true;
      }
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

  /// EN: Refresh access token using refresh token
  /// KO: 리프레시 토큰을 사용하여 액세스 토큰 갱신
  Future<_RefreshOutcome> _refreshOrWait() async {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final created = _refreshToken();
    _refreshFuture = created;
    try {
      return await created;
    } finally {
      if (identical(_refreshFuture, created)) {
        _refreshFuture = null;
      }
    }
  }

  Future<_RefreshOutcome> _refreshToken({bool hasRetried = false}) async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      return _RefreshOutcome.invalidSession;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data != null) {
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _secureStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          // EN: Update token expiry so checkAuthStatus stays consistent
          //     after a background refresh (expiresAt or expiresIn).
          // KO: 백그라운드 갱신 후 checkAuthStatus가 일관성을 유지하도록
          //     토큰 만료 시간을 업데이트합니다.
          final expiresAtRaw = data['expiresAt'] ?? data['expires_at'];
          final expiresInRaw = data['expiresIn'] ?? data['expires_in'];
          DateTime? newExpiry;
          if (expiresAtRaw is String) {
            newExpiry = DateTime.tryParse(expiresAtRaw);
          } else if (expiresInRaw is int && expiresInRaw > 0) {
            newExpiry = DateTime.now().add(Duration(seconds: expiresInRaw));
          } else if (expiresInRaw is String) {
            final seconds = int.tryParse(expiresInRaw);
            if (seconds != null && seconds > 0) {
              newExpiry = DateTime.now().add(Duration(seconds: seconds));
            }
          }
          if (newExpiry != null) {
            await _secureStorage.saveTokenExpiry(newExpiry);
          }
          onTokenRefreshed?.call();
          return _RefreshOutcome.refreshed;
        }
      }

      return _RefreshOutcome.transientFailure;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429 && !hasRetried) {
        final retryAfter = _extractRetryAfter(e.response);
        if (retryAfter != null &&
            retryAfter > Duration.zero &&
            retryAfter <= const Duration(seconds: 3)) {
          AppLogger.warning(
            'Refresh rate-limited; retrying once after '
            '${retryAfter.inMilliseconds}ms',
            tag: 'AuthInterceptor',
          );
          await Future<void>.delayed(retryAfter);
          return _refreshToken(hasRetried: true);
        }
      }

      if (_isInvalidRefreshFailure(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
      )) {
        return _RefreshOutcome.invalidSession;
      }
      AppLogger.error('Token refresh request failed', error: e);
      return _RefreshOutcome.transientFailure;
    } catch (e) {
      AppLogger.error('Token refresh request failed', error: e);
      return _RefreshOutcome.transientFailure;
    }
  }

  Duration? _extractRetryAfter(Response<dynamic>? response) {
    if (response == null) return null;

    final headerValue = response.headers.value('retry-after');
    final parsedHeader = _parseRetryAfterValue(headerValue);
    if (parsedHeader != null) {
      return parsedHeader;
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      return _parseRetryAfterValue(body['retryAfter']?.toString());
    }
    return null;
  }

  Duration? _parseRetryAfterValue(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final numeric = num.tryParse(rawValue);
    if (numeric == null || numeric <= 0) {
      return null;
    }

    // EN: Backend currently returns body retryAfter in milliseconds
    // (e.g., 770). Keep small values usable while supporting second-based
    // header values.
    // KO: 백엔드는 body retryAfter를 밀리초(예: 770)로 반환합니다.
    // 작은 값은 초 단위 헤더 값도 지원하도록 처리합니다.
    if (numeric <= 10) {
      return Duration(seconds: numeric.ceil());
    }

    return Duration(milliseconds: numeric.ceil());
  }

  bool _isInvalidRefreshFailure({
    required int? statusCode,
    required dynamic data,
  }) {
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    if (statusCode != 400 || data is! Map<String, dynamic>) {
      return false;
    }

    final error = data['error'];
    String? rawCode;
    if (error is Map<String, dynamic>) {
      rawCode = error['code']?.toString();
    } else if (error is String) {
      rawCode = error;
    }

    final code = rawCode?.toUpperCase();
    if (code != null && _invalidRefreshErrorCodes.contains(code)) {
      return true;
    }

    final message =
        (error is Map<String, dynamic> ? error['message'] : data['message'])
            ?.toString()
            .toLowerCase();
    return message?.contains('refresh token') == true &&
        message?.contains('expire') == true;
  }

  /// EN: Check if endpoint is public (no auth required)
  /// KO: 엔드포인트가 공개인지 확인 (인증 불필요)
  bool _isPublicEndpoint(String path) {
    const publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refresh,
      ApiEndpoints.accountRecovery,
      ApiEndpoints.health,
    ];

    return publicPaths.any((p) => path.contains(p));
  }
}

enum _RefreshOutcome { refreshed, invalidSession, transientFailure }

/// EN: Logging interceptor for debugging
/// KO: 디버깅을 위한 로깅 인터셉터
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final startTime = DateTime.now();
    options.extra['startTime'] = startTime;

    AppLogger.network(
      options.method,
      sanitizeNetworkLogUri(options.uri).toString(),
      tag: 'Request',
    );
    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug(
        'Query: ${sanitizeNetworkLogData(options.queryParameters)}',
        tag: 'Request',
      );
    }
    if (options.data != null) {
      AppLogger.debug(
        'Body: ${sanitizeNetworkLogData(options.data)}',
        tag: 'Request',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['startTime'] as DateTime?;
    final responseTime = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;

    AppLogger.network(
      response.requestOptions.method,
      sanitizeNetworkLogUri(response.requestOptions.uri).toString(),
      statusCode: response.statusCode,
      responseTimeMs: responseTime,
      tag: 'Response',
    );
    if (response.data != null) {
      AppLogger.debug(
        'Body: ${sanitizeNetworkLogData(response.data)}',
        tag: 'Response',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.network(
      err.requestOptions.method,
      sanitizeNetworkLogUri(err.requestOptions.uri).toString(),
      statusCode: err.response?.statusCode,
      tag: 'Error',
    );
    if (err.response?.data != null) {
      AppLogger.debug(
        'Body: ${sanitizeNetworkLogData(err.response?.data)}',
        tag: 'Error',
      );
    }

    handler.next(err);
  }
}
