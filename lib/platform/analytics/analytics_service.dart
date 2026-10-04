/// EN: Analytics wrapper for app event tracking (Firebase Analytics).
/// KO: 앱 이벤트 추적을 위한 분석 래퍼(Firebase Analytics).
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import '../logging/app_logger.dart';
import '../notifications/firebase_runtime_options.dart';

/// EN: Analytics service singleton.
/// KO: 분석 서비스 싱글톤.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();
  FirebaseAnalytics? _analytics;
  Future<void>? _initializeFuture;

  /// EN: Access the analytics service instance.
  /// KO: 분석 서비스 인스턴스 접근.
  static AnalyticsService get instance => _instance;

  /// EN: Whether analytics is enabled.
  /// KO: 분석 기능이 활성화되어 있는지 여부.
  bool get isEnabled => _analytics != null;

  /// EN: Log screen view.
  /// KO: 화면 조회 이벤트 기록.
  Future<void> logScreenView(String screenName) async {
    final analytics = await _resolveAnalytics();
    if (analytics == null) {
      AppLogger.debug('Screen view: $screenName', tag: 'Analytics');
      return;
    }

    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to send screen view',
        error: error,
        stackTrace: stackTrace,
        tag: 'Analytics',
      );
    }
  }

  /// EN: Log a custom event.
  /// KO: 커스텀 이벤트 기록.
  Future<void> logEvent(String name, Map<String, Object?>? params) async {
    final analytics = await _resolveAnalytics();
    final normalizedParams = _normalizeParams(params);
    if (analytics == null) {
      AppLogger.debug(
        'Event: $name, params: $normalizedParams',
        tag: 'Analytics',
      );
      return;
    }

    try {
      await analytics.logEvent(name: name, parameters: normalizedParams);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to send analytics event: $name',
        error: error,
        stackTrace: stackTrace,
        tag: 'Analytics',
      );
    }
  }

  /// EN: Log place visit event.
  /// KO: 장소 방문 이벤트 기록.
  Future<void> logPlaceVisit(String placeId, {String? placeName}) async {
    await logEvent('place_visit', {
      'place_id': placeId,
      if (placeName != null) 'place_name': placeName,
    });
  }

  /// EN: Log live event view.
  /// KO: 라이브 이벤트 조회 기록.
  Future<void> logLiveEventView(String eventId, {String? eventName}) async {
    await logEvent('live_event_view', {
      'event_id': eventId,
      if (eventName != null) 'event_name': eventName,
    });
  }

  /// EN: Log verification completion.
  /// KO: 인증 완료 이벤트 기록.
  Future<void> logVerificationComplete(String type, String entityId) async {
    await logEvent('verification_complete', {
      'type': type,
      'entity_id': entityId,
    });
  }

  /// EN: Log verification failure.
  /// KO: 인증 실패 이벤트 기록.
  Future<void> logVerificationFailed(String type, String errorCode) async {
    await logEvent('verification_failed', {
      'type': type,
      'error_code': errorCode,
    });
  }

  /// EN: Log search event.
  /// KO: 검색 이벤트 기록.
  Future<void> logSearch(String query, {int? resultCount}) async {
    await logEvent('search', {
      'query': query,
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  /// EN: Log favorite add/remove.
  /// KO: 즐겨찾기 추가/삭제 이벤트 기록.
  Future<void> logFavoriteChange({
    required String entityType,
    required String entityId,
    required bool added,
  }) async {
    await logEvent(added ? 'favorite_add' : 'favorite_remove', {
      'entity_type': entityType,
      'entity_id': entityId,
    });
  }

  /// EN: Log post creation event.
  /// KO: 게시글 작성 이벤트 기록.
  Future<void> logPostCreate(String category) async {
    await logEvent('post_create', {'category': category});
  }

  /// EN: Log login event.
  /// KO: 로그인 이벤트 기록.
  Future<void> logLogin(String method) async {
    await logEvent('login', {'method': method});
  }

  /// EN: Log signup event.
  /// KO: 회원가입 이벤트 기록.
  Future<void> logSignup(String method) async {
    await logEvent('signup', {'method': method});
  }

  Future<FirebaseAnalytics?> _resolveAnalytics() async {
    await _ensureInitialized();
    return _analytics;
  }

  Future<void> _ensureInitialized() async {
    if (_analytics != null) {
      return;
    }

    if (_initializeFuture != null) {
      await _initializeFuture;
      return;
    }

    _initializeFuture = _initializeFirebaseAnalytics();
    try {
      await _initializeFuture;
    } finally {
      _initializeFuture = null;
    }
  }

  Future<void> _initializeFirebaseAnalytics() async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (_) {
          final runtimeOptions =
              FirebaseRuntimeOptions.resolveForCurrentPlatform();
          if (runtimeOptions == null) {
            AppLogger.warning(
              'Analytics disabled: Firebase options are missing',
              tag: 'Analytics',
            );
            return;
          }
          await Firebase.initializeApp(options: runtimeOptions);
        }
      }

      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      _analytics = analytics;
      AppLogger.info('Firebase Analytics initialized', tag: 'Analytics');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Analytics initialization failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'Analytics',
      );
    }
  }

  Map<String, Object>? _normalizeParams(Map<String, Object?>? params) {
    if (params == null || params.isEmpty) {
      return null;
    }

    final normalized = <String, Object>{};
    for (final entry in params.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String || value is int || value is double || value is bool) {
        normalized[entry.key] = value;
      } else if (value is num) {
        normalized[entry.key] = value.toDouble();
      } else {
        normalized[entry.key] = value.toString();
      }
    }

    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
