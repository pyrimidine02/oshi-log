/// EN: Location service wrapper for current device position.
/// KO: 현재 기기 위치를 가져오는 위치 서비스 래퍼.
library;

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../error/failure.dart';
import '../logging/app_logger.dart';
import '../telemetry/telemetry_event_types.dart';
import '../telemetry/telemetry_service.dart';

/// EN: Snapshot of a device location reading.
/// KO: 디바이스 위치 스냅샷.
class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMocked,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMocked;
  final DateTime timestamp;
}

/// EN: Service for resolving current device location with permission checks.
///     Emits telemetry events for GPS mock detection and accuracy anomalies.
/// KO: 권한 확인과 함께 현재 위치를 조회하는 서비스.
///     GPS 모의 위치 감지 및 정확도 이상값에 대한 텔레메트리 이벤트를 전송합니다.
class LocationService {
  LocationService({TelemetryService? telemetry})
      : _telemetry = telemetry ?? TelemetryService.instance;

  final TelemetryService _telemetry;

  /// EN: Fetches current location or throws a [LocationFailure].
  ///     Sends [TelemetryEventTypes.gpsMockDetected] immediately when mock
  ///     location is detected, and queues [TelemetryEventTypes.gpsAccuracyAnomaly]
  ///     when accuracy ≤ 0.
  ///     [authToken] is forwarded to the telemetry service for security events.
  ///     When [requestPermission] is false, never triggers the OS permission
  ///     dialog — throws [LocationFailure] instead if permission is missing.
  ///     Passive callers (e.g. screen-entry auto-fetch) must pass false so the
  ///     system prompt only appears after an explicit user action.
  /// KO: 현재 위치를 조회하거나 [LocationFailure]를 발생시킵니다.
  ///     모의 위치 감지 시 [TelemetryEventTypes.gpsMockDetected]를 즉시 전송하고,
  ///     정확도 ≤ 0이면 [TelemetryEventTypes.gpsAccuracyAnomaly]를 큐에 추가합니다.
  ///     [authToken]은 보안 이벤트 전송 시 텔레메트리 서비스로 전달됩니다.
  ///     [requestPermission]이 false면 OS 권한 팝업을 절대 띄우지 않습니다 —
  ///     권한이 없으면 [LocationFailure]를 던집니다. 화면 진입 시 자동 조회 같은
  ///     수동적 호출은 false를 전달해 사용자의 명시적 행동 이후에만
  ///     시스템 권한 요청이 노출되도록 해야 합니다.
  Future<LocationSnapshot> getCurrentLocation({
    String? authToken,
    bool requestPermission = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Location services disabled',
        code: 'service_disabled',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Location permission denied',
        code: 'permission_denied',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission denied forever',
        code: 'permission_denied_forever',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // EN: Prevent false-positives on older OS versions.
    // KO: 구형 OS 버전에서의 오탐지를 방지합니다.
    bool finalIsMocked = position.isMocked;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 30) {
          finalIsMocked = false; // API 30 이하는 서버 탐지에 맡기고 false 고정
        }
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final versionParts = iosInfo.systemVersion.split('.');
        if (versionParts.isNotEmpty) {
          final majorVersion = int.tryParse(versionParts[0]) ?? 0;
          if (majorVersion <= 14) {
            finalIsMocked = false; // iOS 14 이하는 false 고정
          }
        }
      }
      // EN: If OS-level detection was suppressed due to unreliable API,
      //     log a low-confidence warning so the server side can apply
      //     additional checks.
      // KO: OS 레벨 탐지가 신뢰도 낮은 API로 억제된 경우, 서버가 추가
      //     검증을 적용할 수 있도록 낮은 신뢰도 경고를 로깅합니다.
      if (position.isMocked && !finalIsMocked) {
        AppLogger.warning(
          'isMocked suppressed (low-confidence OS API) — '
          'accuracy=${position.accuracy}m',
          tag: 'LocationService',
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to verify OS version for isMocked: $e',
        tag: 'LocationService',
      );
    }

    // EN: Log location metadata for debugging mocked-location false-positives.
    // KO: 모의 위치 오탐 디버깅을 위해 위치 메타데이터를 로깅합니다.
    if (finalIsMocked) {
      AppLogger.warning(
        'isMocked=true detected on device — '
        'accuracy=${position.accuracy}m, '
        'speed=${position.speed}, '
        'altitude=${position.altitude}',
        tag: 'LocationService',
      );
      // EN: Immediately send GPS_MOCK_DETECTED telemetry — triggers Loki alert.
      // KO: GPS_MOCK_DETECTED 텔레메트리를 즉시 전송합니다 — Loki 알림 트리거.
      unawaited(_telemetry.sendImmediately(
        TelemetryEventTypes.gpsMockDetected,
        payload: {
          'provider': 'mock',
          'accuracy': position.accuracy,
        },
        authToken: authToken,
      ));
    } else {
      AppLogger.info(
        'Location acquired: isMocked=false, accuracy=${position.accuracy}m',
        tag: 'LocationService',
      );
    }

    // EN: Enqueue GPS_ACCURACY_ANOMALY when accuracy is 0 or negative.
    // KO: 정확도가 0 이하이면 GPS_ACCURACY_ANOMALY를 큐에 추가합니다.
    if (position.accuracy <= 0) {
      _telemetry.enqueue(TelemetryEventTypes.gpsAccuracyAnomaly, payload: {
        'accuracy': position.accuracy,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    }

    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      isMocked: finalIsMocked,
      timestamp: position.timestamp,
    );
  }
}
