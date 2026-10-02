/// EN: Offline pending mutation model for live attendance toggles.
/// KO: 라이브 출석 토글 오프라인 대기 작업 모델입니다.
library;

class PendingLiveAttendanceMutation {
  const PendingLiveAttendanceMutation({
    required this.projectKey,
    required this.eventId,
    required this.attended,
    required this.queuedAt,
  });

  final String projectKey;
  final String eventId;
  final bool attended;
  final DateTime queuedAt;

  factory PendingLiveAttendanceMutation.fromJson(Map<String, dynamic> json) {
    final queuedRaw = json['queuedAt'];
    final queuedAt = queuedRaw is String ? DateTime.tryParse(queuedRaw) : null;

    return PendingLiveAttendanceMutation(
      projectKey: (json['projectKey'] as String? ?? '').trim(),
      eventId: (json['eventId'] as String? ?? '').trim(),
      attended: json['attended'] == true,
      queuedAt: queuedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectKey': projectKey,
      'eventId': eventId,
      'attended': attended,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
    };
  }
}
