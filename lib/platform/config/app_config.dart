/// EN: Application configuration with environment-specific settings.
/// KO: 환경별 설정을 포함한 앱 구성입니다.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// EN: Supported API environments.
/// KO: 지원하는 API 환경입니다.
enum Environment { development, staging, production }

const String _appEnvironment = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'development',
);
const String _developmentBaseUrl = String.fromEnvironment(
  'DEVELOPMENT_BASE_URL',
  defaultValue: 'https://dev.oshilog.org',
);
const String _stagingBaseUrl = String.fromEnvironment(
  'STAGING_BASE_URL',
  defaultValue: 'https://dev.oshilog.org',
);
const String _productionBaseUrl = String.fromEnvironment(
  'PRODUCTION_BASE_URL',
  defaultValue: 'https://api.oshilog.org',
);

/// EN: Application configuration singleton.
/// KO: 앱 구성 싱글톤입니다.
class AppConfig {
  AppConfig._() {
    // EN: Resolve the compile-time channel for every instance. Missing APP_ENV
    //     remains development, including release builds.
    // KO: 모든 인스턴스에서 컴파일 시 채널을 해석합니다. APP_ENV가 없으면
    //     릴리스 빌드를 포함해 development를 사용합니다.
    init(environment: environmentFromBuild());
  }

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  late Environment _environment;
  late String _baseUrl;
  late String _storageNamespace;
  late String _projectId;
  String? _projectCode;
  late Map<String, String> _oauthAuthorizeUrls;

  /// EN: Parse a build-time environment value and reject unknown channels.
  /// KO: 빌드 환경 값을 해석하고 알 수 없는 채널은 거부합니다.
  static Environment parseEnvironment(String value) {
    switch (value.trim().toLowerCase()) {
      case 'development':
        return Environment.development;
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      default:
        throw FormatException('Unknown APP_ENV: $value');
    }
  }

  /// EN: Resolve the compile-time APP_ENV. Development is the safe default,
  ///     including release builds, so a missing define cannot hit production.
  /// KO: 컴파일 시 APP_ENV를 해석합니다. 릴리스 빌드에서도 기본값은
  ///     development로 유지해 정의 누락이 운영 API로 연결되지 않게 합니다.
  static Environment environmentFromBuild() {
    return parseEnvironment(_appEnvironment);
  }

  /// EN: Initialize configuration for an environment.
  /// KO: 환경에 맞게 구성을 초기화합니다.
  void init({
    Environment environment = Environment.development,
    String? baseUrl,
    String? projectId,
    String? projectCode,
    Map<String, String>? oauthAuthorizeUrls,
  }) {
    final resolvedBaseUrl = _validateBaseUrl(
      baseUrl ?? _getDefaultBaseUrl(environment),
      environment,
    );
    _environment = environment;
    _baseUrl = resolvedBaseUrl;
    _storageNamespace = storageNamespaceForOrigin(resolvedBaseUrl);
    _projectId = projectId ?? _getDefaultProjectId(environment);
    _projectCode = projectCode;
    _oauthAuthorizeUrls = Map<String, String>.unmodifiable(
      oauthAuthorizeUrls ?? <String, String>{},
    );
  }

  Environment get environment => _environment;
  String get baseUrl => _baseUrl;
  String get projectId => _projectId;
  String? get projectCode => _projectCode;
  Map<String, String> get oauthAuthorizeUrls => _oauthAuthorizeUrls;

  /// EN: Stable namespace captured from the API origin.
  /// KO: API 오리진에서 고정적으로 계산한 저장소 네임스페이스입니다.
  String get storageNamespace => _storageNamespace;

  /// EN: Return the namespace used for a URL origin. Paths and query strings
  ///     are intentionally ignored so endpoint changes do not split storage.
  /// KO: URL 오리진에서 저장소 네임스페이스를 계산합니다. 엔드포인트 경로와
  ///     쿼리는 의도적으로 제외해 API 경로 변경으로 저장소가 분리되지 않게 합니다.
  static String storageNamespaceForOrigin(String baseUrl) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null || uri.host.trim().isEmpty) {
      throw const FormatException('Invalid API origin');
    }
    final host = uri.host.toLowerCase();
    final port = uri.hasPort ? ':${uri.port}' : '';
    final scheme = uri.scheme.toLowerCase();
    final normalizedPort =
        (scheme == 'https' && uri.port == 443) ||
            (scheme == 'http' && uri.port == 80)
        ? ''
        : port;
    final hostWithBrackets = host.contains(':') ? '[$host]' : host;
    final origin = '$scheme://$hostWithBrackets$normalizedPort';
    // EN: Base64url preserves a one-to-one mapping without exposing a raw
    //     hostname as a preference-key prefix.
    // KO: Base64url로 일대일 매핑을 보장하면서 환경 호스트를 키 접두사에
    //     그대로 노출하지 않습니다.
    final encoded = base64Url.encode(utf8.encode(origin)).replaceAll('=', '');
    return 'api_$encoded';
  }

  /// EN: Check if running in debug mode.
  /// KO: 디버그 모드 여부입니다.
  bool get isDebug => kDebugMode;

  /// EN: Check if running in production.
  /// KO: 운영 환경 여부입니다.
  bool get isProduction => _environment == Environment.production;

  String _getDefaultBaseUrl(Environment env) {
    return switch (env) {
      Environment.development => _developmentBaseUrl,
      Environment.staging => _stagingBaseUrl,
      Environment.production => _productionBaseUrl,
    };
  }

  String _validateBaseUrl(String value, Environment environment) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.trim().isEmpty) {
      throw const FormatException('Invalid API base URL');
    }

    final scheme = uri.scheme.toLowerCase();
    final isDebugLoopback =
        kDebugMode &&
        environment == Environment.development &&
        scheme == 'http' &&
        _isLoopbackHost(uri.host);
    if (scheme != 'https' && !isDebugLoopback) {
      throw FormatException(
        'API base URL must use HTTPS outside a debug loopback',
      );
    }
    if (uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw FormatException(
        'API base URL must not contain credentials, query, or fragment',
      );
    }
    return normalized;
  }

  bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1' ||
        normalized == '10.0.2.2';
  }

  String _getDefaultProjectId(Environment env) {
    return switch (env) {
      Environment.development => '10000000-0000-0000-0000-000000000001',
      Environment.staging => '10000000-0000-0000-0000-000000000001',
      Environment.production => '10000000-0000-0000-0000-000000000001',
    };
  }
}
