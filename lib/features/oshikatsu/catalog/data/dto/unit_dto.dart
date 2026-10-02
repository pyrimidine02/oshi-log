/// EN: Unit DTO for project unit list/detail responses.
/// KO: 프로젝트 유닛 목록/상세 응답 DTO.
library;

class UnitMemberSummaryDto {
  const UnitMemberSummaryDto({
    required this.id,
    required this.characterName,
    this.position,
    this.isLeader,
    this.characterImageUrl,
    this.displayOrder,
  });

  final String id;
  final String characterName;
  final String? position;
  final bool? isLeader;
  final String? characterImageUrl;
  final int? displayOrder;

  factory UnitMemberSummaryDto.fromJson(Map<String, dynamic> json) {
    return UnitMemberSummaryDto(
      id: _string(json, ['id', 'memberId']) ?? '',
      characterName:
          _string(json, ['characterName', 'name', 'displayName']) ?? '?',
      position: _string(json, ['position', 'role']),
      isLeader: _bool(json, ['isLeader', 'leader', 'captain']),
      characterImageUrl: _string(json, [
        'characterImageUrl',
        'imageUrl',
        'avatarUrl',
      ]),
      displayOrder: _int(json, ['displayOrder', 'order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterName': characterName,
      if (position != null) 'position': position,
      if (isLeader != null) 'isLeader': isLeader,
      if (characterImageUrl != null) 'characterImageUrl': characterImageUrl,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
  }
}

class UnitDto {
  const UnitDto({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.colorHex,
    this.logoUrl,
    this.debutDate,
    this.status,
    this.memberCount,
    this.members = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? colorHex;
  final String? logoUrl;
  final String? debutDate;
  final String? status;
  final int? memberCount;
  final List<UnitMemberSummaryDto> members;

  // EN: Backward-compatible aliases for existing UI code.
  // KO: 기존 UI 코드 호환을 위한 별칭 필드.
  String get code => slug;
  String get displayName => name;

  factory UnitDto.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = _membersFromAny(rawMembers);
    return UnitDto(
      id: _string(json, ['id', 'unitId']) ?? '',
      slug: _string(json, ['slug', 'code', 'bandCode']) ?? '',
      name: _string(json, ['name', 'displayName', 'title']) ?? '유닛',
      description: _string(json, ['description', 'summary']),
      colorHex: _string(json, ['colorHex', 'color', 'themeColor']),
      logoUrl: _string(json, ['logoUrl', 'logoImageUrl']),
      debutDate: _string(json, ['debutDate']),
      status: _string(json, ['status']),
      memberCount:
          _int(json, ['memberCount', 'membersCount', 'member_count']) ??
          (rawMembers is List ? members.length : null),
      members: members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      if (description != null) 'description': description,
      if (colorHex != null) 'colorHex': colorHex,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (debutDate != null) 'debutDate': debutDate,
      if (status != null) 'status': status,
      if (memberCount != null) 'memberCount': memberCount,
      if (members.isNotEmpty)
        'members': members.map((item) => item.toJson()).toList(),
    };
  }
}

List<UnitMemberSummaryDto> _membersFromAny(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UnitMemberSummaryDto.fromJson)
        .toList(growable: false);
  }
  return const <UnitMemberSummaryDto>[];
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
