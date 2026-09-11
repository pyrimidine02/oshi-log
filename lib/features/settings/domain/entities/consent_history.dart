/// EN: Domain entity for consent history entries.
/// KO: 동의 이력 항목 도메인 엔티티입니다.
library;

class ConsentHistoryItem {
  const ConsentHistoryItem({
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
}
