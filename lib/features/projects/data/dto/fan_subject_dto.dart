/// EN: DTOs for generalized fandom subjects across people and media.
/// KO: 인물과 미디어를 포괄하는 일반화된 팬 대상 계약 DTO입니다.
library;

enum FanSubjectKind {
  project,
  unit,
  voiceActor,
  artist,
  anime,
  unknown;

  static FanSubjectKind fromWire(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'PROJECT' => FanSubjectKind.project,
      'UNIT' => FanSubjectKind.unit,
      'VOICE_ACTOR' => FanSubjectKind.voiceActor,
      'ARTIST' => FanSubjectKind.artist,
      'ANIME' => FanSubjectKind.anime,
      _ => FanSubjectKind.unknown,
    };
  }

  String get wireName => switch (this) {
    FanSubjectKind.project => 'PROJECT',
    FanSubjectKind.unit => 'UNIT',
    FanSubjectKind.voiceActor => 'VOICE_ACTOR',
    FanSubjectKind.artist => 'ARTIST',
    FanSubjectKind.anime => 'ANIME',
    FanSubjectKind.unknown => 'UNKNOWN',
  };
}

class FanSubjectDto {
  const FanSubjectDto({
    required this.id,
    required this.type,
    required this.entityId,
    required this.key,
    required this.name,
    this.description,
    this.imageUrl,
  });

  final String id;
  final FanSubjectKind type;
  final String entityId;
  final String key;
  final String name;
  final String? description;
  final String? imageUrl;

  factory FanSubjectDto.fromJson(Map<String, dynamic> json) {
    return FanSubjectDto(
      id: _string(json['id']),
      type: FanSubjectKind.fromWire(json['type'] as String?),
      entityId: _string(json['entityId'] ?? json['sourceId']),
      key: _string(json['key'] ?? json['canonicalKey']),
      name: _string(json['name'] ?? json['displayName']),
      description: _nullableString(json['description']),
      imageUrl: _nullableString(json['imageUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.wireName,
    'entityId': entityId,
    'key': key,
    'name': name,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

class FanSubjectSubscriptionDto {
  const FanSubjectSubscriptionDto({
    required this.subject,
    required this.subscribed,
    this.subscribedAt,
  });

  final FanSubjectDto subject;
  final bool subscribed;
  final DateTime? subscribedAt;

  factory FanSubjectSubscriptionDto.fromJson(Map<String, dynamic> json) {
    final subjectJson = json['subject'];
    return FanSubjectSubscriptionDto(
      subject: FanSubjectDto.fromJson(
        subjectJson is Map<String, dynamic>
            ? subjectJson
            : const <String, dynamic>{},
      ),
      subscribed: json['subscribed'] == true,
      subscribedAt: DateTime.tryParse(_string(json['subscribedAt'])),
    );
  }
}

String _string(dynamic value) => value?.toString() ?? '';

String? _nullableString(dynamic value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
