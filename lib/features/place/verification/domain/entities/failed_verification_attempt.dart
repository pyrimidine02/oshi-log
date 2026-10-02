/// EN: Local entity for a failed verification attempt stored on device.
/// KO: 기기에 저장되는 인증 실패 기록 로컬 엔티티.
library;

import 'dart:math';

/// EN: Represents a single failed verification attempt persisted locally.
/// EN: Retained for 30 days to allow the user to file an appeal.
/// KO: 로컬에 저장되는 인증 실패 1건을 나타냅니다.
/// KO: 이의제기 제출을 위해 30일간 보관합니다.
class FailedVerificationAttempt {
  const FailedVerificationAttempt({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.failureCode,
    required this.failureMessage,
    required this.attemptedAt,
    this.projectId,
    this.targetName,
  });

  /// EN: Locally generated unique identifier.
  /// KO: 로컬에서 생성한 고유 식별자.
  final String id;

  /// EN: Target type: 'PLACE_VISIT' or 'LIVE_EVENT'.
  /// KO: 대상 유형: 'PLACE_VISIT' 또는 'LIVE_EVENT'.
  final String targetType;

  /// EN: Target identifier — placeId for PLACE_VISIT, liveEventId for LIVE_EVENT.
  /// KO: 대상 식별자 — PLACE_VISIT은 placeId, LIVE_EVENT는 liveEventId.
  final String targetId;

  /// EN: Project identifier associated with this attempt.
  /// KO: 이 시도와 관련된 프로젝트 식별자.
  final String? projectId;

  /// EN: Denormalized display name (place name or event title).
  /// KO: 표시용 이름 (장소명 또는 이벤트 제목).
  final String? targetName;

  /// EN: Short error code from the server or local failure mapping.
  /// KO: 서버 또는 로컬 실패 매핑에서 온 짧은 오류 코드.
  final String failureCode;

  /// EN: Human-readable failure message.
  /// KO: 사람이 읽을 수 있는 실패 메시지.
  final String failureMessage;

  /// EN: Timestamp when the attempt occurred.
  /// KO: 시도가 발생한 시각.
  final DateTime attemptedAt;

  /// EN: Serialise to JSON for SharedPreferences storage.
  /// KO: SharedPreferences 저장을 위해 JSON으로 직렬화.
  Map<String, dynamic> toJson() => {
    'id': id,
    'targetType': targetType,
    'targetId': targetId,
    'projectId': projectId,
    'targetName': targetName,
    'failureCode': failureCode,
    'failureMessage': failureMessage,
    'attemptedAt': attemptedAt.millisecondsSinceEpoch,
  };

  /// EN: Deserialise from JSON.
  /// KO: JSON에서 역직렬화.
  factory FailedVerificationAttempt.fromJson(Map<String, dynamic> json) {
    return FailedVerificationAttempt(
      id: json['id'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'PLACE_VISIT',
      targetId: json['targetId'] as String? ?? '',
      projectId: json['projectId'] as String?,
      targetName: json['targetName'] as String?,
      failureCode: json['failureCode'] as String? ?? 'UNKNOWN',
      failureMessage: json['failureMessage'] as String? ?? '',
      attemptedAt: DateTime.fromMillisecondsSinceEpoch(
        json['attemptedAt'] as int? ?? 0,
      ),
    );
  }

  /// EN: Generate a local unique ID (no external package required).
  /// KO: 외부 패키지 없이 로컬 고유 ID를 생성합니다.
  static String generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rand = Random.secure()
        .nextInt(0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    return '$ms-$rand';
  }
}
