/// EN: Application logger for consistent logging across the app
/// KO: 앱 전체에서 일관된 로깅을 위한 앱 로거
library;

import 'package:flutter/foundation.dart';

/// EN: Log level enumeration
/// KO: 로그 레벨 열거형
enum LogLevel { debug, info, warning, error }

/// EN: Application-wide logger with structured logging
/// KO: 구조화된 로깅을 제공하는 앱 전역 로거
class AppLogger {
  AppLogger._();

  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// EN: Set minimum log level
  /// KO: 최소 로그 레벨 설정
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// EN: Log debug message (only in debug mode)
  /// KO: 디버그 메시지 로깅 (디버그 모드에서만)
  static void debug(String message, {dynamic data, String? tag}) {
    if (!kDebugMode) return;
    _log(LogLevel.debug, message, data: data, tag: tag);
  }

  /// EN: Log info message
  /// KO: 정보 메시지 로깅
  static void info(String message, {dynamic data, String? tag}) {
    _log(LogLevel.info, message, data: data, tag: tag);
  }

  /// EN: Log warning message
  /// KO: 경고 메시지 로깅
  static void warning(String message, {dynamic data, String? tag}) {
    _log(LogLevel.warning, message, data: data, tag: tag);
  }

  /// EN: Log error message with optional error object and stack trace
  /// KO: 선택적 에러 객체와 스택 트레이스를 포함한 에러 메시지 로깅
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(
      LogLevel.error,
      message,
      data: error,
      stackTrace: stackTrace,
      tag: tag,
    );
  }

  /// EN: Log network request
  /// KO: 네트워크 요청 로깅
  static void network(
    String method,
    String url, {
    int? statusCode,
    int? responseTimeMs,
    String? tag,
  }) {
    if (!kDebugMode) return;
    final status = statusCode != null ? '[$statusCode]' : '';
    final time = responseTimeMs != null ? '(${responseTimeMs}ms)' : '';
    debug('$method $url $status $time', tag: tag ?? 'Network');
  }

  /// EN: Internal log implementation
  /// KO: 내부 로그 구현
  static void _log(
    LogLevel level,
    String message, {
    dynamic data,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';

    final logMessage = '$timestamp $levelStr $tagStr$message';

    // EN: Color-coded console output is restricted to debug builds only.
    // KO: 색상 코드 콘솔 출력은 디버그 빌드에서만 출력됩니다.
    if (kDebugMode) {
      final colorCode = switch (level) {
        LogLevel.debug => '\x1B[37m', // White
        LogLevel.info => '\x1B[34m', // Blue
        LogLevel.warning => '\x1B[33m', // Yellow
        LogLevel.error => '\x1B[31m', // Red
      };
      const reset = '\x1B[0m';
      // ignore: avoid_print
      print('$colorCode$logMessage$reset');

      // EN: Print additional data if present
      // KO: 추가 데이터가 있으면 출력
      if (data != null) {
        // ignore: avoid_print
        print('  Data: $data');
      }

      // EN: Print stack trace for errors
      // KO: 에러의 경우 스택 트레이스 출력
      if (stackTrace != null) {
        // ignore: avoid_print
        print('  StackTrace:\n$stackTrace');
      }
    }

    // EN: Forward error-level logs to crash reporter in release mode.
    // KO: 릴리스 모드에서 에러 레벨 로그를 크래시 리포터로 전달합니다.
    if (!kDebugMode && level == LogLevel.error) {
      // TODO(infra): Wire Sentry.captureException / FirebaseCrashlytics here.
    }
  }
}

/// EN: Mixin for adding logging capability to classes
/// KO: 클래스에 로깅 기능을 추가하는 믹스인
mixin Loggable {
  String get logTag => runtimeType.toString();

  void logDebug(String message, {dynamic data}) {
    AppLogger.debug(message, data: data, tag: logTag);
  }

  void logInfo(String message, {dynamic data}) {
    AppLogger.info(message, data: data, tag: logTag);
  }

  void logWarning(String message, {dynamic data}) {
    AppLogger.warning(message, data: data, tag: logTag);
  }

  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    AppLogger.error(message, error: error, stackTrace: stackTrace, tag: logTag);
  }
}
