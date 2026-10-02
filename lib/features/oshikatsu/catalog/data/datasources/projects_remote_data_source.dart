/// EN: Remote data source for projects and units.
/// KO: 프로젝트/유닛 원격 데이터 소스.
library;

import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/utils/result.dart';
import '../dto/member_dto.dart';
import '../dto/project_dto.dart';
import '../dto/unit_dto.dart';
import '../dto/voice_actor_dto.dart';

class ProjectsRemoteDataSource {
  ProjectsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<List<ProjectDto>>> fetchProjects() {
    return _apiClient.get<List<ProjectDto>>(
      ApiEndpoints.projects,
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(ProjectDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['results'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(ProjectDto.fromJson)
                .toList();
          }
        }
        return <ProjectDto>[];
      },
    );
  }

  Future<Result<List<UnitDto>>> fetchUnits({
    required String projectId,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) {
    return _apiClient.get<List<UnitDto>>(
      ApiEndpoints.projectUnits(projectId),
      queryParameters: {
        'page': page,
        'size': size,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(UnitDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['results'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(UnitDto.fromJson)
                .toList();
          }
        }
        return <UnitDto>[];
      },
    );
  }

  Future<Result<UnitDto>> fetchUnitDetail({
    required String projectId,
    required String unitIdentifier,
  }) {
    return _apiClient.get<UnitDto>(
      ApiEndpoints.projectUnit(projectId, unitIdentifier),
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return UnitDto.fromJson(json);
        }
        return const UnitDto(id: '', slug: '', name: '유닛');
      },
    );
  }

  /// EN: Fetches members for a unit including voice actor info.
  /// KO: 유닛의 멤버 목록(성우 정보 포함)을 불러옵니다.
  Future<Result<List<MemberDto>>> fetchUnitMembers({
    required String projectId,
    required String unitIdentifier,
    int page = 0,
    int size = 50,
  }) {
    return _apiClient.get<List<MemberDto>>(
      ApiEndpoints.unitMembers(projectId, unitIdentifier),
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(MemberDto.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          final items =
              json['items'] ??
              json['data'] ??
              json['results'] ??
              json['members'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(MemberDto.fromJson)
                .toList();
          }
        }
        return <MemberDto>[];
      },
    );
  }

  Future<Result<MemberDto>> fetchUnitMemberDetail({
    required String projectId,
    required String unitIdentifier,
    required String memberId,
  }) {
    return _apiClient.get<MemberDto>(
      ApiEndpoints.unitMember(projectId, unitIdentifier, memberId),
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return MemberDto.fromJson(json);
        }
        return const MemberDto(id: '', unitId: '', name: '?');
      },
    );
  }

  Future<Result<List<VoiceActorListItemDto>>> fetchVoiceActors({
    required String projectId,
    String query = '',
    int page = 0,
    int size = 20,
    String? sort,
  }) {
    return _apiClient.get<List<VoiceActorListItemDto>>(
      ApiEndpoints.projectVoiceActors(projectId),
      queryParameters: {
        'q': query,
        'page': page,
        'size': size,
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
      },
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(VoiceActorListItemDto.fromJson)
              .toList(growable: false);
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['results'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(VoiceActorListItemDto.fromJson)
                .toList(growable: false);
          }
        }
        return const <VoiceActorListItemDto>[];
      },
    );
  }

  Future<Result<VoiceActorDetailDto>> fetchVoiceActorDetail({
    required String projectId,
    required String voiceActorId,
  }) {
    return _apiClient.get<VoiceActorDetailDto>(
      ApiEndpoints.projectVoiceActor(projectId, voiceActorId),
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return VoiceActorDetailDto.fromJson(json);
        }
        return const VoiceActorDetailDto(id: '', displayName: '');
      },
    );
  }

  Future<Result<List<VoiceActorMemberSummaryDto>>> fetchVoiceActorMembers({
    required String projectId,
    required String voiceActorId,
  }) {
    return _apiClient.get<List<VoiceActorMemberSummaryDto>>(
      ApiEndpoints.projectVoiceActorMembers(projectId, voiceActorId),
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(VoiceActorMemberSummaryDto.fromJson)
              .toList(growable: false);
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['results'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(VoiceActorMemberSummaryDto.fromJson)
                .toList(growable: false);
          }
        }
        return const <VoiceActorMemberSummaryDto>[];
      },
    );
  }

  Future<Result<List<VoiceActorCreditSummaryDto>>> fetchVoiceActorCredits({
    required String projectId,
    required String voiceActorId,
  }) {
    return _apiClient.get<List<VoiceActorCreditSummaryDto>>(
      ApiEndpoints.projectVoiceActorCredits(projectId, voiceActorId),
      fromJson: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(VoiceActorCreditSummaryDto.fromJson)
              .toList(growable: false);
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? json['results'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(VoiceActorCreditSummaryDto.fromJson)
                .toList(growable: false);
          }
        }
        return const <VoiceActorCreditSummaryDto>[];
      },
    );
  }
}
