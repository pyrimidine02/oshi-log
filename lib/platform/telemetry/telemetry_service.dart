/// EN: Telemetry service — device fingerprinting, event queuing, and batch upload.
/// KO: 텔레메트리 서비스 — 기기 지문 생성, 이벤트 큐잉, 배치 업로드.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

const String _kDeviceBannedKey = 'telemetry_device_banned';
const int _kMaxBatchSize = 50;

/// EN: Single telemetry event to be queued and sent.
/// KO: 큐에 추가하고 전송할 단일 텔레메트리 이벤트.
class TelemetryEvent {
  const TelemetryEvent({
    required this.type,
    required this.occurredAt,
    this.payload,
  });

  final String type;

  /// EN: ISO 8601 timestamp with timezone offset (e.g. 2026-03-20T10:00:00+09:00).
  /// KO: 타임존 오프셋 포함 ISO 8601 타임스탬프 (예: 2026-03-20T10:00:00+09:00).
  final String occurredAt;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
    'type': type,
    'occurredAt': occurredAt,
    if (payload != null) 'payload': payload,
  };
}

/// EN: Telemetry service singleton.
///     All public methods are no-ops when the device is banned.
/// KO: 텔레메트리 서비스 싱글톤.
///     기기가 차단된 경우 모든 공개 메서드는 no-op입니다.
class TelemetryService {
  TelemetryService._internal();

  static final TelemetryService _instance = TelemetryService._internal();

  /// EN: Access the singleton instance.
  /// KO: 싱글톤 인스턴스 접근.
  static TelemetryService get instance => _instance;

  final List<TelemetryEvent> _queue = [];
  bool _deviceBanned = false;
  String? _cachedDeviceHash;
  Map<String, dynamic>? _cachedFingerprint;

  // ──────────────────────────────────────────────────────────
  // EN: Initialization
  // KO: 초기화
  // ──────────────────────────────────────────────────────────

  /// EN: Load persisted device-banned state from SharedPreferences.
  ///     Call once during app bootstrap before using any other methods.
  /// KO: SharedPreferences에서 기기 차단 상태를 불러옵니다.
  ///     다른 메서드를 사용하기 전에 앱 부트스트랩 중 1회 호출합니다.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceBanned = prefs.getBool(_kDeviceBannedKey) ?? false;
    if (_deviceBanned) {
      AppLogger.warning(
        'Device is banned — telemetry disabled',
        tag: 'Telemetry',
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // EN: Public API
  // KO: 공개 API
  // ──────────────────────────────────────────────────────────

  /// EN: Whether this device has been banned from submitting telemetry.
  /// KO: 이 기기가 텔레메트리 제출에서 차단되었는지 여부.
  bool get isDeviceBanned => _deviceBanned;

  /// EN: Add an event to the in-memory queue (sent on next flush).
  ///     No-op when [isDeviceBanned] is true.
  /// KO: 이벤트를 인메모리 큐에 추가합니다 (다음 flush 시 전송).
  ///     [isDeviceBanned]가 true이면 no-op입니다.
  void enqueue(String type, {Map<String, dynamic>? payload}) {
    if (_deviceBanned) return;
    _queue.add(
      TelemetryEvent(type: type, occurredAt: _nowIso8601(), payload: payload),
    );
  }

  /// EN: Send a single event immediately (for security events).
  ///     No-op when [isDeviceBanned] is true.
  ///     [authToken] is optional — attaches subject ID on the server when provided.
  /// KO: 단일 이벤트를 즉시 전송합니다 (보안 이벤트용).
  ///     [isDeviceBanned]가 true이면 no-op입니다.
  ///     [authToken]은 선택사항 — 제공 시 서버에서 subject ID를 연결합니다.
  Future<void> sendImmediately(
    String type, {
    Map<String, dynamic>? payload,
    String? authToken,
  }) async {
    if (_deviceBanned) return;
    await _sendBatch([
      TelemetryEvent(type: type, occurredAt: _nowIso8601(), payload: payload),
    ], authToken: authToken);
  }

  /// EN: Flush the queue — send all queued events in batches of 50.
  ///     Typically called on app-background transition.
  ///     No-op when [isDeviceBanned] is true or queue is empty.
  /// KO: 큐를 비웁니다 — 대기 중인 이벤트를 50개씩 배치로 전송합니다.
  ///     앱 백그라운드 전환 시 호출합니다.
  ///     [isDeviceBanned]가 true이거나 큐가 비어 있으면 no-op입니다.
  Future<void> flush({String? authToken}) async {
    if (_deviceBanned || _queue.isEmpty) return;
    final events = List<TelemetryEvent>.from(_queue);
    _queue.clear();

    for (var i = 0; i < events.length; i += _kMaxBatchSize) {
      final end = (i + _kMaxBatchSize).clamp(0, events.length);
      await _sendBatch(events.sublist(i, end), authToken: authToken);
    }
  }

  // ──────────────────────────────────────────────────────────
  // EN: Internal helpers
  // KO: 내부 헬퍼
  // ──────────────────────────────────────────────────────────

  Future<void> _sendBatch(
    List<TelemetryEvent> events, {
    String? authToken,
  }) async {
    if (events.isEmpty) return;
    try {
      final fp = await _buildFingerprint();
      final body = jsonEncode({
        'deviceFingerprint': fp,
        'events': events.map((e) => e.toJson()).toList(),
      });

      final baseUrl = AppConfig.instance.baseUrl;
      final uri = Uri.parse('$baseUrl/api/v1/telemetry/events');
      final request = await HttpClient().postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Client-Type', 'mobile');
      if (authToken != null && authToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $authToken');
      }
      request.write(body);
      final response = await request.close();

      if (response.statusCode == 403) {
        // EN: Device banned — disable all future telemetry.
        // KO: 기기 차단 — 이후 모든 텔레메트리 비활성화.
        _deviceBanned = true;
        await _persistBannedState();
        AppLogger.warning(
          'Device banned by server — telemetry disabled',
          tag: 'Telemetry',
        );
      } else if (response.statusCode == 200) {
        AppLogger.debug(
          'Telemetry batch accepted (${events.length} events)',
          tag: 'Telemetry',
        );
      } else {
        // EN: Non-200/403 — restore events to front of queue for retry.
        // KO: 200/403 이외 — 재시도를 위해 이벤트를 큐 앞에 복원합니다.
        _queue.insertAll(0, events);
        AppLogger.warning(
          'Telemetry batch failed: HTTP ${response.statusCode}',
          tag: 'Telemetry',
        );
      }

      // EN: Drain the response body to release the socket.
      // KO: 소켓을 해제하기 위해 응답 바디를 소비합니다.
      await response.drain<void>();
    } catch (error) {
      // EN: Network failure — restore events for retry on next flush.
      // KO: 네트워크 오류 — 다음 flush 시 재시도를 위해 이벤트를 복원합니다.
      _queue.insertAll(0, events);
      AppLogger.warning('Telemetry send failed: $error', tag: 'Telemetry');
    }
  }

  Future<Map<String, dynamic>> _buildFingerprint() async {
    if (_cachedFingerprint != null) return _cachedFingerprint!;
    final hash = await _getDeviceHash();
    final info = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();

    if (!kIsWeb && Platform.isAndroid) {
      final d = await info.androidInfo;
      _cachedFingerprint = {
        'deviceHash': hash,
        'platform': 'android',
        'model': d.model,
        'osVersion': d.version.release,
        'appVersion': pkg.version,
      };
    } else if (!kIsWeb && Platform.isIOS) {
      final d = await info.iosInfo;
      _cachedFingerprint = {
        'deviceHash': hash,
        'platform': 'ios',
        'model': d.utsname.machine,
        'osVersion': d.systemVersion,
        'appVersion': pkg.version,
      };
    } else {
      // EN: Fallback for unsupported platforms (simulator, web).
      // KO: 지원되지 않는 플랫폼(시뮬레이터, 웹) 폴백.
      _cachedFingerprint = {
        'deviceHash': hash,
        'platform': 'unknown',
        'appVersion': pkg.version,
      };
    }
    return _cachedFingerprint!;
  }

  Future<String> _getDeviceHash() async {
    if (_cachedDeviceHash != null) return _cachedDeviceHash!;

    String raw;
    if (!kIsWeb && Platform.isAndroid) {
      final d = await DeviceInfoPlugin().androidInfo;
      // EN: Combine androidId + model + OS version for the fingerprint.
      // KO: 지문 생성을 위해 androidId + 모델 + OS 버전을 조합합니다.
      raw = '${d.id}:${d.model}:${d.version.release}';
    } else if (!kIsWeb && Platform.isIOS) {
      final d = await DeviceInfoPlugin().iosInfo;
      // EN: Combine identifierForVendor + model + OS version for the fingerprint.
      // KO: 지문 생성을 위해 identifierForVendor + 모델 + OS 버전을 조합합니다.
      raw = '${d.identifierForVendor}:${d.model}:${d.systemVersion}';
    } else {
      raw = 'unknown:unknown:unknown';
    }

    // EN: SHA-256 hash — never transmit raw device identifiers.
    // KO: SHA-256 해시 — 원본 기기 ID는 절대 전송하지 않습니다.
    _cachedDeviceHash = sha256.convert(utf8.encode(raw)).toString();
    return _cachedDeviceHash!;
  }

  Future<void> _persistBannedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeviceBannedKey, true);
  }

  /// EN: ISO 8601 timestamp with UTC offset (e.g. 2026-03-20T10:00:00+09:00).
  /// KO: UTC 오프셋 포함 ISO 8601 타임스탬프 (예: 2026-03-20T10:00:00+09:00).
  static String _nowIso8601() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return '$year-$month-${day}T$hour:$minute:$second$sign$hours:$minutes';
  }
}
