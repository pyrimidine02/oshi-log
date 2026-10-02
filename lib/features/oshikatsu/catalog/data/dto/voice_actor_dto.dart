/// EN: Voice actor DTO models.
/// KO: 성우 DTO 모델.
library;

class VoiceActorListItemDto {
  const VoiceActorListItemDto({
    required this.id,
    required this.displayName,
    this.realName,
    this.stageName,
    this.agency,
    this.profileImageUrl,
  });

  final String id;
  final String displayName;
  final String? realName;
  final String? stageName;
  final String? agency;
  final String? profileImageUrl;

  factory VoiceActorListItemDto.fromJson(Map<String, dynamic> json) {
    final displayName =
        _string(json, ['displayName']) ??
        _string(json, ['stageName']) ??
        _string(json, ['realName']) ??
        '';
    return VoiceActorListItemDto(
      id: _string(json, ['id', 'voiceActorId']) ?? '',
      displayName: displayName,
      realName: _string(json, ['realName']),
      stageName: _string(json, ['stageName']),
      agency: _string(json, ['agency']),
      profileImageUrl: _string(json, [
        'profileImageUrl',
        'imageUrl',
        'avatarUrl',
      ]),
    );
  }
}

class VoiceActorDetailDto {
  const VoiceActorDetailDto({
    required this.id,
    required this.displayName,
    this.realName,
    this.stageName,
    this.birthDate,
    this.agency,
    this.debutDate,
    this.bio,
    this.profileImageUrl,
    this.officialWebsite,
    this.twitterHandle,
    this.instagramHandle,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String? realName;
  final String? stageName;
  final String? birthDate;
  final String? agency;
  final String? debutDate;
  final String? bio;
  final String? profileImageUrl;
  final String? officialWebsite;
  final String? twitterHandle;
  final String? instagramHandle;
  final String? createdAt;
  final String? updatedAt;

  factory VoiceActorDetailDto.fromJson(Map<String, dynamic> json) {
    final displayName =
        _string(json, ['displayName']) ??
        _string(json, ['stageName']) ??
        _string(json, ['realName']) ??
        '';
    return VoiceActorDetailDto(
      id: _string(json, ['id', 'voiceActorId']) ?? '',
      displayName: displayName,
      realName: _string(json, ['realName']),
      stageName: _string(json, ['stageName']),
      birthDate: _string(json, ['birthDate']),
      agency: _string(json, ['agency']),
      debutDate: _string(json, ['debutDate']),
      bio: _string(json, ['bio', 'description']),
      profileImageUrl: _string(json, [
        'profileImageUrl',
        'imageUrl',
        'avatarUrl',
      ]),
      officialWebsite: _string(json, ['officialWebsite']),
      twitterHandle: _string(json, ['twitterHandle']),
      instagramHandle: _string(json, ['instagramHandle']),
      createdAt: _string(json, ['createdAt']),
      updatedAt: _string(json, ['updatedAt']),
    );
  }
}

class VoiceActorMemberSummaryDto {
  const VoiceActorMemberSummaryDto({
    required this.memberId,
    required this.unitId,
    required this.unitSlug,
    required this.unitName,
    required this.characterName,
    this.characterImageUrl,
    this.position,
    this.isLeader,
    this.roleType,
    this.rolePriority,
    this.startDate,
    this.endDate,
  });

  final String memberId;
  final String unitId;
  final String unitSlug;
  final String unitName;
  final String characterName;
  final String? characterImageUrl;
  final String? position;
  final bool? isLeader;
  final String? roleType;
  final int? rolePriority;
  final String? startDate;
  final String? endDate;

  factory VoiceActorMemberSummaryDto.fromJson(Map<String, dynamic> json) {
    return VoiceActorMemberSummaryDto(
      memberId: _string(json, ['memberId', 'id']) ?? '',
      unitId: _string(json, ['unitId']) ?? '',
      unitSlug: _string(json, ['unitSlug']) ?? '',
      unitName: _string(json, ['unitName']) ?? '',
      characterName: _string(json, ['characterName', 'name']) ?? '',
      characterImageUrl: _string(json, ['characterImageUrl', 'imageUrl']),
      position: _string(json, ['position']),
      isLeader: _bool(json, ['isLeader']),
      roleType: _string(json, ['roleType']),
      rolePriority: _int(json, ['rolePriority']),
      startDate: _string(json, ['startDate']),
      endDate: _string(json, ['endDate']),
    );
  }
}

class VoiceActorCreditSummaryDto {
  const VoiceActorCreditSummaryDto({
    required this.projectId,
    required this.projectSlug,
    required this.projectName,
    required this.unitId,
    required this.unitSlug,
    required this.unitName,
    required this.memberId,
    required this.characterName,
    this.characterImageUrl,
    this.position,
    this.isLeader,
    this.roleType,
    this.rolePriority,
    this.startDate,
    this.endDate,
    this.notes,
  });

  final String projectId;
  final String projectSlug;
  final String projectName;
  final String unitId;
  final String unitSlug;
  final String unitName;
  final String memberId;
  final String characterName;
  final String? characterImageUrl;
  final String? position;
  final bool? isLeader;
  final String? roleType;
  final int? rolePriority;
  final String? startDate;
  final String? endDate;
  final String? notes;

  factory VoiceActorCreditSummaryDto.fromJson(Map<String, dynamic> json) {
    return VoiceActorCreditSummaryDto(
      projectId: _string(json, ['projectId']) ?? '',
      projectSlug: _string(json, ['projectSlug']) ?? '',
      projectName: _string(json, ['projectName']) ?? '',
      unitId: _string(json, ['unitId']) ?? '',
      unitSlug: _string(json, ['unitSlug']) ?? '',
      unitName: _string(json, ['unitName']) ?? '',
      memberId: _string(json, ['memberId']) ?? '',
      characterName: _string(json, ['characterName']) ?? '',
      characterImageUrl: _string(json, ['characterImageUrl', 'imageUrl']),
      position: _string(json, ['position']),
      isLeader: _bool(json, ['isLeader']),
      roleType: _string(json, ['roleType']),
      rolePriority: _int(json, ['rolePriority']),
      startDate: _string(json, ['startDate']),
      endDate: _string(json, ['endDate']),
      notes: _string(json, ['notes']),
    );
  }
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
