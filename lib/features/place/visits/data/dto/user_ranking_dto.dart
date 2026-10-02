/// EN: User ranking DTO for visit-based leaderboard data.
/// KO: 방문 기반 리더보드 데이터를 위한 사용자 랭킹 DTO.
library;

/// EN: Data transfer object representing a user's ranking position.
/// KO: 사용자의 랭킹 순위를 나타내는 데이터 전송 객체.
class UserRankingDto {
  const UserRankingDto({
    required this.rank,
    required this.userId,
    required this.totalVisits,
    required this.uniquePlaces,
    required this.totalUsers,
  });

  /// EN: The user's rank position (1-based).
  /// KO: 사용자의 순위 (1부터 시작).
  final int rank;

  /// EN: The ranked user's unique identifier.
  /// KO: 랭킹 대상 사용자의 고유 식별자.
  final String userId;

  /// EN: Total number of visits by the user.
  /// KO: 사용자의 총 방문 횟수.
  final int totalVisits;

  /// EN: Number of unique places visited.
  /// KO: 방문한 고유 장소 수.
  final int uniquePlaces;

  /// EN: Total number of ranked users.
  /// KO: 랭킹에 참여한 전체 사용자 수.
  final int totalUsers;

  factory UserRankingDto.fromJson(Map<String, dynamic> json) {
    return UserRankingDto(
      rank: _int(json['rank']),
      userId: json['userId'] as String? ?? '',
      totalVisits: _int(json['totalVisits']),
      uniquePlaces: _int(json['uniquePlaces']),
      totalUsers: _int(json['totalUsers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'totalVisits': totalVisits,
      'uniquePlaces': uniquePlaces,
      'totalUsers': totalUsers,
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
