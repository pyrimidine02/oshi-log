/// EN: Shared date utility helpers.
/// KO: 공통 날짜 유틸리티 헬퍼.
library;

/// EN: Parse a birthdate string and return days until next birthday.
/// EN: Supported examples: `MM-DD`, `MM/DD`, `YYYY-MM-DD`, `YYYY/MM/DD`.
/// KO: 생일 문자열을 파싱해 다음 생일까지 남은 일수를 반환합니다.
/// KO: 지원 예시: `MM-DD`, `MM/DD`, `YYYY-MM-DD`, `YYYY/MM/DD`.
int? daysUntilBirthday(String? birthdate) {
  if (birthdate == null || birthdate.isEmpty) return null;

  try {
    final parts = birthdate.replaceAll('/', '-').split('-');
    if (parts.length < 2) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = int.parse(parts.length >= 3 ? parts[1] : parts[0]);
    final day = int.parse(parts.length >= 3 ? parts[2] : parts[1]);

    var next = DateTime(now.year, month, day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, month, day);
    }

    return next.difference(today).inDays;
  } catch (_) {
    return null;
  }
}
