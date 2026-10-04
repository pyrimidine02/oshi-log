/// EN: Telemetry event type string constants used by [TelemetryService].
/// KO: [TelemetryService]에서 사용하는 텔레메트리 이벤트 타입 문자열 상수.
library;

/// EN: Security / abuse-detection events.
///     Server immediately records a SUSPICIOUS_ACTIVITY entry in Loki
///     for [gpsMockDetected], [teleportDetected], [rapidPlaceVisit].
/// KO: 보안 / 어뷰징 탐지 이벤트.
///     서버는 [gpsMockDetected], [teleportDetected], [rapidPlaceVisit] 수신 즉시
///     Loki 보안 채널에 SUSPICIOUS_ACTIVITY 이벤트를 기록합니다.
class TelemetryEventTypes {
  const TelemetryEventTypes._();

  // ── Security / abuse ──────────────────────────────────────
  /// EN: Mock location provider detected.
  /// KO: 모의 위치 앱 감지.
  static const String gpsMockDetected = 'GPS_MOCK_DETECTED';

  /// EN: Abnormally large location jump in a short time.
  /// KO: 비정상적으로 급격한 위치 이동 감지.
  static const String teleportDetected = 'TELEPORT_DETECTED';

  /// EN: Multiple place-visit attempts within a short window.
  /// KO: 단시간 다수 장소 방문 시도.
  static const String rapidPlaceVisit = 'RAPID_PLACE_VISIT';

  /// EN: GPS accuracy value is 0.0 or negative (stored only, no Loki alert).
  /// KO: GPS 정확도가 0.0 이하 (DB 저장만, Loki 알림 없음).
  static const String gpsAccuracyAnomaly = 'GPS_ACCURACY_ANOMALY';

  // ── App lifecycle ─────────────────────────────────────────
  /// EN: App entered foreground.
  /// KO: 앱 포그라운드 진입.
  static const String appForeground = 'APP_FOREGROUND';

  /// EN: App moved to background.
  /// KO: 앱 백그라운드 전환.
  static const String appBackground = 'APP_BACKGROUND';

  // ── User behaviour ────────────────────────────────────────
  /// EN: Search query completed. Server checks for banned keywords.
  /// KO: 검색어 입력 완료. 서버에서 금칙어 자동 검사.
  static const String searchQuery = 'SEARCH_QUERY';

  /// EN: Content report submitted.
  /// KO: 콘텐츠 신고 제출.
  static const String reportSubmitted = 'REPORT_SUBMITTED';

  /// EN: Screen entered / viewed.
  /// KO: 화면 진입.
  static const String screenView = 'SCREEN_VIEW';
}
