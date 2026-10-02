/// EN: DTO for user consent history item.
/// KO: 사용자 동의 이력 항목 DTO입니다.
library;

class ConsentHistoryItemDto {
  const ConsentHistoryItemDto({
    required this.type,
    required this.version,
    required this.agreed,
    this.agreedAt,
    this.label,
  });

  final String type;
  final String version;
  final bool agreed;
  final DateTime? agreedAt;
  final String? label;

  factory ConsentHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final agreedAtRaw = json['agreedAt'];
    return ConsentHistoryItemDto(
      type: (json['type'] as String?) ?? 'UNKNOWN',
      version: (json['version'] as String?) ?? '-',
      agreed: (json['agreed'] as bool?) ?? false,
      agreedAt: agreedAtRaw is String ? DateTime.tryParse(agreedAtRaw) : null,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'version': version,
      'agreed': agreed,
      if (agreedAt != null) 'agreedAt': agreedAt!.toIso8601String(),
      if (label != null) 'label': label,
    };
  }
}
