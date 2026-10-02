/// EN: Search item DTO for unified search responses.
/// KO: 통합 검색 응답용 검색 아이템 DTO.
library;

class SearchItemDto {
  const SearchItemDto({required this.type, required this.item});

  final String type;
  final Map<String, dynamic> item;

  factory SearchItemDto.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    final itemMap = item is Map<String, dynamic> ? item : <String, dynamic>{};
    return SearchItemDto(type: _string(json, ['type']) ?? '', item: itemMap);
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'item': item};
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}
