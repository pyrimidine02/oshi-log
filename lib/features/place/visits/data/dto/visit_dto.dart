/// EN: Visit DTOs for user visit history and summary.
/// KO: 사용자 방문 기록 및 요약 DTO.
library;

class VisitEventDto {
  const VisitEventDto({
    required this.id,
    required this.placeId,
    required this.visitedAt,
    this.status = '',
    this.distanceM,
  });

  final String id;
  final String placeId;
  final DateTime? visitedAt;

  /// EN: Server-owned verification status. Missing values fail closed.
  /// KO: 서버가 관리하는 인증 상태입니다. 누락된 값은 실패-폐쇄로 처리합니다.
  final String status;

  /// EN: Distance from the place at verification time, in meters (optional).
  /// KO: 인증 시 장소로부터의 거리 (미터 단위, 선택적).
  final double? distanceM;

  factory VisitEventDto.fromJson(Map<String, dynamic> json) {
    return VisitEventDto(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      visitedAt: _dateTime(json['visitedAt']),
      status: (json['status'] as String? ?? '').trim(),
      distanceM: _double(json['distanceM']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'visitedAt': visitedAt?.toIso8601String(),
      'status': status,
      if (distanceM != null) 'distanceM': distanceM,
    };
  }
}

class VisitEventDetailDto {
  const VisitEventDetailDto({
    required this.id,
    required this.placeId,
    required this.visitedAt,
    this.status = '',
    this.distanceM,
    this.accuracy,
  });

  final String id;
  final String placeId;
  final DateTime? visitedAt;

  /// EN: Server-owned verification status. Missing values fail closed.
  /// KO: 서버가 관리하는 인증 상태입니다. 누락된 값은 실패-폐쇄로 처리합니다.
  final String status;

  /// EN: Distance from the place at verification time, in meters (optional).
  /// KO: 인증 시 장소로부터의 거리 (미터 단위, 선택적).
  final double? distanceM;

  /// EN: GPS accuracy in meters (optional, nullable after 30 days).
  /// KO: GPS 정확도 (미터 단위, 30일 후 null이 될 수 있음).
  final double? accuracy;

  factory VisitEventDetailDto.fromJson(Map<String, dynamic> json) {
    return VisitEventDetailDto(
      id: json['id'] as String? ?? '',
      placeId: json['placeId'] as String? ?? '',
      visitedAt: _dateTime(json['visitedAt']),
      status: (json['status'] as String? ?? '').trim(),
      distanceM: _double(json['distanceM']),
      accuracy: _double(json['accuracy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'visitedAt': visitedAt?.toIso8601String(),
      'status': status,
      if (distanceM != null) 'distanceM': distanceM,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }
}

class VisitSummaryDto {
  const VisitSummaryDto({
    required this.placeId,
    required this.visitCount,
    required this.firstVisitedAt,
    required this.lastVisitedAt,
  });

  final String placeId;
  final int visitCount;
  final DateTime? firstVisitedAt;
  final DateTime? lastVisitedAt;

  factory VisitSummaryDto.fromJson(Map<String, dynamic> json) {
    return VisitSummaryDto(
      placeId: json['placeId'] as String? ?? '',
      visitCount: _int(json['visitCount']),
      firstVisitedAt: _dateTime(json['firstVisitedAt']),
      lastVisitedAt: _dateTime(json['lastVisitedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'visitCount': visitCount,
      'firstVisitedAt': firstVisitedAt?.toIso8601String(),
      'lastVisitedAt': lastVisitedAt?.toIso8601String(),
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
