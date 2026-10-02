/// EN: Client-side rate limiter for community reports.
/// KO: 커뮤니티 신고용 클라이언트 레이트리밋 서비스.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// EN: In-memory report cooldown tracker.
/// KO: 메모리 기반 신고 쿨다운 추적기.
class ReportRateLimiter {
  ReportRateLimiter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const Duration cooldown = Duration(minutes: 5);

  final DateTime Function() _now;
  final Map<String, DateTime> _lastReportAt = {};

  /// EN: Returns whether reporting this target is currently allowed.
  /// KO: 현재 이 대상을 신고할 수 있는지 반환합니다.
  bool canReport(String targetId) {
    final last = _lastReportAt[targetId];
    if (last == null) {
      return true;
    }
    return _now().difference(last) >= cooldown;
  }

  /// EN: Returns remaining cooldown (zero when reporting is allowed).
  /// KO: 남은 쿨다운을 반환합니다 (신고 가능 시 zero).
  Duration remainingCooldown(String targetId) {
    final last = _lastReportAt[targetId];
    if (last == null) {
      return Duration.zero;
    }
    final elapsed = _now().difference(last);
    if (elapsed >= cooldown) {
      return Duration.zero;
    }
    return cooldown - elapsed;
  }

  /// EN: Records a report submission timestamp for target.
  /// KO: 대상 신고 제출 시각을 기록합니다.
  void recordReport(String targetId) {
    _lastReportAt[targetId] = _now();
  }
}

/// EN: Global provider for report cooldown checks.
/// KO: 신고 쿨다운 검사용 글로벌 프로바이더.
final reportRateLimiterProvider = Provider<ReportRateLimiter>((_) {
  return ReportRateLimiter();
});
