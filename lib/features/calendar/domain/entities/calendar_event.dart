/// EN: Domain entities for calendar events.
/// KO: 캘린더 이벤트의 도메인 엔티티.
library;

/// EN: Type of calendar event.
/// KO: 캘린더 이벤트 유형.
enum CalendarEventType {
  /// EN: Character birthday.
  /// KO: 캐릭터 생일.
  characterBirthday,

  /// EN: Voice actor birthday.
  /// KO: 성우 생일.
  voiceActorBirthday,

  /// EN: CD/BD/merchandise release.
  /// KO: CD/BD/굿즈 발매.
  release,

  /// EN: Live concert or event.
  /// KO: 라이브 콘서트 또는 이벤트.
  live,

  /// EN: Ticket sale opening.
  /// KO: 티켓 판매 시작.
  ticketSale,

  /// EN: Streaming or broadcast start.
  /// KO: 스트리밍 또는 방송 시작.
  streaming,

  /// EN: General event or announcement.
  /// KO: 일반 이벤트 또는 공지.
  general;

  /// EN: Creates a [CalendarEventType] from a raw string value.
  /// KO: 원시 문자열 값으로 [CalendarEventType]을 생성합니다.
  static CalendarEventType fromString(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'birthday_character' ||
      'character_birthday' ||
      'characterbirthday' => CalendarEventType.characterBirthday,
      'birthday_voice_actor' ||
      'voice_actor_birthday' ||
      'voiceactorbirthday' => CalendarEventType.voiceActorBirthday,
      'release' => CalendarEventType.release,
      'live' => CalendarEventType.live,
      'ticket' || 'ticket_sale' || 'ticketsale' => CalendarEventType.ticketSale,
      'streaming' => CalendarEventType.streaming,
      _ => CalendarEventType.general,
    };
  }
}

/// EN: A single calendar event.
/// KO: 단일 캘린더 이벤트.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    this.imageUrl,
    this.projectId,
    this.projectCode,
    this.relatedEntityId,
    this.relatedEntityType,
    this.isRecurringAnnually = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final CalendarEventType type;
  final String? description;
  final String? imageUrl;
  final String? projectId;
  final String? projectCode;

  /// EN: Related entity ID (e.g. character ID, live event ID).
  /// KO: 연관 엔티티 ID (예: 캐릭터 ID, 라이브 이벤트 ID).
  final String? relatedEntityId;
  final String? relatedEntityType;

  /// EN: True for annual recurring events like birthdays.
  /// KO: 생일 같은 연간 반복 이벤트는 true.
  final bool isRecurringAnnually;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
