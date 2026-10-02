/// EN: DTO for unit member (character) responses including voice actors.
/// KO: 성우 정보를 포함한 유닛 멤버(캐릭터) 응답 DTO.
library;

class MemberVoiceActorDto {
  const MemberVoiceActorDto({
    required this.id,
    required this.displayName,
    this.roleType,
    this.profileImageUrl,
  });

  final String id;
  final String displayName;
  final String? roleType;
  final String? profileImageUrl;

  factory MemberVoiceActorDto.fromJson(Map<String, dynamic> json) {
    return MemberVoiceActorDto(
      id: _string(json, ['id', 'voiceActorId']) ?? '',
      displayName: _string(json, ['displayName', 'name', 'stageName']) ?? '',
      roleType: _string(json, ['roleType', 'voiceRole']),
      profileImageUrl: _string(json, [
        'profileImageUrl',
        'imageUrl',
        'avatarUrl',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      if (roleType != null) 'roleType': roleType,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}

class MemberDto {
  const MemberDto({
    required this.id,
    required this.unitId,
    required this.name,
    this.characterNameKana,
    this.role,
    this.voiceActorName,
    this.imageUrl,
    this.order,
    this.birthdate,
    this.hometown,
    this.description,
    this.instrument,
    this.isLeader,
    this.isActive,
    this.voiceActors = const [],
  });

  final String id;
  final String unitId;
  final String name;
  final String? characterNameKana;
  final String? role;
  final String? voiceActorName;
  final String? imageUrl;
  final int? order;
  final String? birthdate;
  final String? hometown;
  final String? description;
  final String? instrument;
  final bool? isLeader;
  final bool? isActive;
  final List<MemberVoiceActorDto> voiceActors;

  factory MemberDto.fromJson(Map<String, dynamic> json) {
    final voiceActors = _voiceActorsFromAny(json['voiceActors']);
    final firstVoiceActorName = voiceActors.isNotEmpty
        ? voiceActors.first.displayName
        : null;
    final position = _string(json, ['position', 'role', 'type']);
    final instrument = _string(json, ['instrument', 'part']);

    return MemberDto(
      id: _string(json, ['id', 'memberId']) ?? '',
      unitId: _string(json, ['unitId']) ?? '',
      name: _string(json, ['characterName', 'name', 'displayName']) ?? '?',
      characterNameKana: _string(json, ['characterNameKana']),
      role: position,
      voiceActorName:
          _string(json, ['voiceActorName', 'voiceActor', 'cv', 'seiyuu']) ??
          firstVoiceActorName,
      imageUrl: _string(json, [
        'characterImageUrl',
        'imageUrl',
        'image',
        'avatarUrl',
        'photoUrl',
      ]),
      order: _int(json, ['displayOrder', 'order']),
      birthdate: _string(json, ['birthDate', 'birthdate', 'birthday']),
      hometown: _string(json, ['hometown']),
      description: _string(json, [
        'characterDescription',
        'description',
        'bio',
      ]),
      instrument: instrument ?? position,
      isLeader: _bool(json, ['isLeader', 'leader', 'captain']),
      isActive: _bool(json, ['active', 'isActive']),
      voiceActors: voiceActors,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'unitId': unitId,
    'characterName': name,
    if (characterNameKana != null) 'characterNameKana': characterNameKana,
    if (role != null) 'position': role,
    if (voiceActorName != null) 'voiceActorName': voiceActorName,
    if (imageUrl != null) 'characterImageUrl': imageUrl,
    if (order != null) 'displayOrder': order,
    if (birthdate != null) 'birthDate': birthdate,
    if (hometown != null) 'hometown': hometown,
    if (description != null) 'characterDescription': description,
    if (instrument != null) 'instrument': instrument,
    if (isLeader != null) 'isLeader': isLeader,
    if (isActive != null) 'isActive': isActive,
    if (voiceActors.isNotEmpty)
      'voiceActors': voiceActors.map((item) => item.toJson()).toList(),
  };
}

List<MemberVoiceActorDto> _voiceActorsFromAny(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MemberVoiceActorDto.fromJson)
        .where(
          (item) => item.displayName.trim().isNotEmpty || item.id.isNotEmpty,
        )
        .toList(growable: false);
  }
  return const <MemberVoiceActorDto>[];
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

bool? _bool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
  }
  return null;
}
