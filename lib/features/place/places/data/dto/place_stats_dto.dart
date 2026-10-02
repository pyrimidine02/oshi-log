/// EN: Place stats DTO for visit/favorite counts.
/// KO: 방문/즐겨찾기 카운트를 위한 장소 통계 DTO.
library;

class PlaceStatsDto {
  const PlaceStatsDto({this.visitCount, this.favoriteCount});

  final int? visitCount;
  final int? favoriteCount;

  factory PlaceStatsDto.fromJson(Map<String, dynamic> json) {
    return PlaceStatsDto(
      visitCount: _intOrNull(json['visitCount']),
      favoriteCount: _intOrNull(json['favoriteCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'visitCount': visitCount, 'favoriteCount': favoriteCount};
  }
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
