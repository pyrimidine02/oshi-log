/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/member_dto.dart';
import '../dto/project_dto.dart';
import '../dto/unit_dto.dart';
import '../dto/voice_actor_dto.dart';
import '../../domain/entities/project_entities.dart';

extension ProjectDtoDomainMapper on ProjectDto {
  Project toDomain() {
    final dto = this;

    return Project(
      id: dto.id,
      code: dto.code,
      name: dto.name,
      status: dto.status,
      defaultTimezone: dto.defaultTimezone,
    );
  }
}

extension UnitDtoDomainMapper on UnitDto {
  Unit toDomain() {
    final dto = this;

    return Unit(
      id: dto.id,
      code: dto.slug,
      displayName: dto.name,
      description: dto.description,
      status: dto.status,
      logoUrl: dto.logoUrl,
      colorHex: dto.colorHex,
      debutDate: dto.debutDate,
      memberCount: dto.memberCount,
      memberSummaries: List.unmodifiable(
        dto.members.map((value) => value.toDomain()).toList(growable: false),
      ),
    );
  }
}

extension UnitMemberSummaryDtoDomainMapper on UnitMemberSummaryDto {
  UnitMemberSummary toDomain() {
    final dto = this;

    return UnitMemberSummary(
      id: dto.id,
      characterName: dto.characterName,
      position: dto.position,
      isLeader: dto.isLeader,
      characterImageUrl: dto.characterImageUrl,
      displayOrder: dto.displayOrder,
    );
  }
}

extension MemberVoiceActorDtoDomainMapper on MemberVoiceActorDto {
  VoiceActorRole toDomain() {
    final dto = this;

    return VoiceActorRole(
      id: dto.id,
      displayName: dto.displayName,
      roleType: dto.roleType,
      profileImageUrl: dto.profileImageUrl,
    );
  }
}

extension MemberDtoDomainMapper on MemberDto {
  UnitMember toDomain() {
    final dto = this;

    final roles = List<VoiceActorRole>.unmodifiable(
      dto.voiceActors.map((value) => value.toDomain()).toList(growable: false),
    );
    return UnitMember(
      id: dto.id,
      name: dto.name,
      unitId: dto.unitId.isEmpty ? null : dto.unitId,
      characterNameKana: dto.characterNameKana,
      role: dto.role,
      voiceActorName: dto.voiceActorName,
      imageUrl: dto.imageUrl,
      order: dto.order,
      birthdate: dto.birthdate,
      hometown: dto.hometown,
      description: dto.description,
      instrument: dto.instrument,
      isLeader: dto.isLeader,
      isActive: dto.isActive,
      voiceActors: roles,
    );
  }
}

extension VoiceActorListItemDtoDomainMapper on VoiceActorListItemDto {
  VoiceActorListItem toDomain() {
    final dto = this;

    return VoiceActorListItem(
      id: dto.id,
      displayName: dto.displayName,
      realName: dto.realName,
      stageName: dto.stageName,
      agency: dto.agency,
      profileImageUrl: dto.profileImageUrl,
    );
  }
}

extension VoiceActorDetailDtoDomainMapper on VoiceActorDetailDto {
  VoiceActorDetail toDomain() {
    final dto = this;

    return VoiceActorDetail(
      id: dto.id,
      displayName: dto.displayName,
      realName: dto.realName,
      stageName: dto.stageName,
      birthDate: dto.birthDate,
      agency: dto.agency,
      debutDate: dto.debutDate,
      bio: dto.bio,
      profileImageUrl: dto.profileImageUrl,
      officialWebsite: dto.officialWebsite,
      twitterHandle: dto.twitterHandle,
      instagramHandle: dto.instagramHandle,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}

extension VoiceActorMemberSummaryDtoDomainMapper on VoiceActorMemberSummaryDto {
  VoiceActorMemberSummary toDomain() {
    final dto = this;

    return VoiceActorMemberSummary(
      memberId: dto.memberId,
      unitId: dto.unitId,
      unitSlug: dto.unitSlug,
      unitName: dto.unitName,
      characterName: dto.characterName,
      characterImageUrl: dto.characterImageUrl,
      position: dto.position,
      isLeader: dto.isLeader,
      roleType: dto.roleType,
      rolePriority: dto.rolePriority,
      startDate: dto.startDate,
      endDate: dto.endDate,
    );
  }
}

extension VoiceActorCreditSummaryDtoDomainMapper on VoiceActorCreditSummaryDto {
  VoiceActorCreditSummary toDomain() {
    final dto = this;

    return VoiceActorCreditSummary(
      projectId: dto.projectId,
      projectSlug: dto.projectSlug,
      projectName: dto.projectName,
      unitId: dto.unitId,
      unitSlug: dto.unitSlug,
      unitName: dto.unitName,
      memberId: dto.memberId,
      characterName: dto.characterName,
      characterImageUrl: dto.characterImageUrl,
      position: dto.position,
      isLeader: dto.isLeader,
      roleType: dto.roleType,
      rolePriority: dto.rolePriority,
      startDate: dto.startDate,
      endDate: dto.endDate,
      notes: dto.notes,
    );
  }
}
