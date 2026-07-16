/// EN: User visit domain entities.
/// KO: 사용자 방문 도메인 엔티티.
library;

import 'package:intl/intl.dart';

import '../../data/dto/user_ranking_dto.dart';
import '../../data/dto/visit_dto.dart';

/// EN: Canonical visit verification states understood by the app.
/// KO: 앱이 이해하는 표준 방문 인증 상태입니다.
class VisitVerificationStatus {
  const VisitVerificationStatus._();

  static const String verified = 'VERIFIED';
  static const String unknown = 'UNKNOWN';

  static String normalize(String raw) {
    final normalized = raw.trim().toUpperCase();
    return normalized.isEmpty ? unknown : normalized;
  }
}

class VisitEvent {
  const VisitEvent({
    required this.id,
    required this.placeId,
    required this.visitedAt,
    this.status = VisitVerificationStatus.unknown,
    this.distanceM,
    this.accuracy,
  });

  final String id;
  final String placeId;
  final DateTime? visitedAt;
  final String status;

  /// EN: Distance from the place at verification time, in meters (optional).
  /// KO: 인증 시 장소로부터의 거리 (미터 단위, 선택적).
  final double? distanceM;

  /// EN: GPS accuracy in meters (optional, nullable after 30 days).
  /// KO: GPS 정확도 (미터 단위, 30일 후 null이 될 수 있음).
  final double? accuracy;

  /// EN: Whether the server currently recognizes this visit as verified.
  /// KO: 서버가 현재 이 방문을 인증 완료로 인정하는지 여부입니다.
  bool get isVerified => status == VisitVerificationStatus.verified;

  /// EN: Backward-compatible UI alias; proof never depends on distance.
  /// KO: UI 호환 별칭이며, 증빙 여부는 거리 값에 의존하지 않습니다.
  bool get hasGpsVerification => isVerified;

  factory VisitEvent.fromDto(VisitEventDto dto) {
    return VisitEvent(
      id: dto.id,
      placeId: dto.placeId,
      visitedAt: dto.visitedAt,
      status: VisitVerificationStatus.normalize(dto.status),
      distanceM: dto.distanceM,
    );
  }

  factory VisitEvent.fromDetailDto(VisitEventDetailDto dto) {
    return VisitEvent(
      id: dto.id,
      placeId: dto.placeId,
      visitedAt: dto.visitedAt,
      status: VisitVerificationStatus.normalize(dto.status),
      distanceM: dto.distanceM,
      accuracy: dto.accuracy,
    );
  }

  String get visitedAtLabel {
    if (visitedAt == null) return '';
    return DateFormat('yyyy.MM.dd HH:mm').format(visitedAt!.toLocal());
  }
}

class VisitSummary {
  const VisitSummary({
    required this.placeId,
    required this.visitCount,
    required this.firstVisitedAt,
    required this.lastVisitedAt,
  });

  final String placeId;
  final int visitCount;
  final DateTime? firstVisitedAt;
  final DateTime? lastVisitedAt;

  factory VisitSummary.fromDto(VisitSummaryDto dto) {
    return VisitSummary(
      placeId: dto.placeId,
      visitCount: dto.visitCount,
      firstVisitedAt: dto.firstVisitedAt,
      lastVisitedAt: dto.lastVisitedAt,
    );
  }

  String get firstVisitedLabel {
    if (firstVisitedAt == null) return '';
    return DateFormat('yyyy.MM.dd').format(firstVisitedAt!.toLocal());
  }

  String get lastVisitedLabel {
    if (lastVisitedAt == null) return '';
    return DateFormat('yyyy.MM.dd').format(lastVisitedAt!.toLocal());
  }
}

/// EN: User ranking entity with visit statistics.
/// KO: 방문 통계가 포함된 사용자 랭킹 엔티티.
class UserRanking {
  const UserRanking({
    required this.rank,
    required this.totalVisits,
    required this.uniquePlaces,
    required this.totalUsers,
  });

  /// EN: The user's rank position (1-based).
  /// KO: 사용자의 순위 (1부터 시작).
  final int rank;

  /// EN: Total number of visits by the user.
  /// KO: 사용자의 총 방문 횟수.
  final int totalVisits;

  /// EN: Number of unique places visited.
  /// KO: 방문한 고유 장소 수.
  final int uniquePlaces;

  /// EN: Total number of ranked users.
  /// KO: 랭킹에 참여한 전체 사용자 수.
  final int totalUsers;

  factory UserRanking.fromDto(UserRankingDto dto) {
    return UserRanking(
      rank: dto.rank,
      totalVisits: dto.totalVisits,
      uniquePlaces: dto.uniquePlaces,
      totalUsers: dto.totalUsers,
    );
  }
}
