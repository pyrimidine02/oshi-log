/// EN: Projects repository implementation with caching.
/// KO: 캐시를 포함한 프로젝트 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/project_entities.dart';
import '../../domain/repositories/projects_repository.dart';
import '../datasources/projects_remote_data_source.dart';
import '../dto/member_dto.dart';
import '../dto/project_dto.dart';
import '../dto/unit_dto.dart';
import '../dto/voice_actor_dto.dart';
import '../mappers/project_entities_mappers.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  ProjectsRepositoryImpl({
    required ProjectsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final ProjectsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;
  Future<Result<List<Project>>>? _projectsRequest;

  @override
  Future<Result<List<Project>>> getProjects({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final inFlight = _projectsRequest;
      if (inFlight != null) return inFlight;
    }

    final request = _getProjects(forceRefresh: forceRefresh);
    if (!forceRefresh) {
      _projectsRequest = request;
    }

    return request.whenComplete(() {
      if (_projectsRequest == request) {
        _projectsRequest = null;
      }
    });
  }

  Future<Result<List<Project>>> _getProjects({
    required bool forceRefresh,
  }) async {
    final profile = CacheProfiles.projectsList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<ProjectDto>>(
        key: _projectsCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: _fetchProjects,
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(ProjectDto.fromJson)
                .toList(growable: false);
          }
          return <ProjectDto>[];
        },
      );

      final entities = cacheResult.data
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<Unit>>> getUnits({
    required String projectId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.projectUnits;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<UnitDto>>(
        key: _unitsCacheKey(projectId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchUnits(projectId),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(UnitDto.fromJson)
                .toList(growable: false);
          }
          return <UnitDto>[];
        },
      );

      final entities = cacheResult.data
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<Unit>> getUnitDetail({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.projectUnits;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<UnitDto>(
        key: _unitDetailCacheKey(projectId, unitIdentifier),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchUnitDetail(projectId, unitIdentifier),
        toJson: (dto) => dto.toJson(),
        fromJson: UnitDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<UnitMember>>> getUnitMembers({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.projectUnitMembers;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<MemberDto>>(
        key: _membersCacheKey(projectId, unitIdentifier),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchUnitMembers(projectId, unitIdentifier),
        toJson: (dtos) => {'items': dtos.map((dto) => dto.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(MemberDto.fromJson)
                .toList(growable: false);
          }
          return <MemberDto>[];
        },
      );

      final entities = cacheResult.data
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Result.success(entities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<UnitMember>> getUnitMemberDetail({
    required String projectId,
    required String unitIdentifier,
    required String memberId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.projectUnitMembers;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<MemberDto>(
        key: _memberDetailCacheKey(projectId, unitIdentifier, memberId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () =>
            _fetchUnitMemberDetail(projectId, unitIdentifier, memberId),
        toJson: (dto) => dto.toJson(),
        fromJson: MemberDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<VoiceActorListItem>>> searchVoiceActors({
    required String projectId,
    String query = '',
    int page = 0,
    int size = 20,
    String? sort,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.voiceActorsList;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<VoiceActorListItemDto>>(
            key: _voiceActorsCacheKey(projectId, query, page, size, sort),
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () =>
                _fetchVoiceActors(projectId, query, page, size, sort),
            toJson: (dtos) => {
              'items': dtos.map(_voiceActorListDtoToJson).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(VoiceActorListItemDto.fromJson)
                    .toList(growable: false);
              }
              return <VoiceActorListItemDto>[];
            },
          );

      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<VoiceActorDetail>> getVoiceActorDetail({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.voiceActorDetail;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<VoiceActorDetailDto>(
        key: _voiceActorDetailCacheKey(projectId, voiceActorId),
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchVoiceActorDetail(projectId, voiceActorId),
        toJson: _voiceActorDetailDtoToJson,
        fromJson: VoiceActorDetailDto.fromJson,
      );
      return Result.success(cacheResult.data.toDomain());
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<VoiceActorMemberSummary>>> getVoiceActorMembers({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.voiceActorMembers;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<VoiceActorMemberSummaryDto>>(
            key: _voiceActorMembersCacheKey(projectId, voiceActorId),
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchVoiceActorMembers(projectId, voiceActorId),
            toJson: (dtos) => {
              'items': dtos.map(_voiceActorMemberDtoToJson).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(VoiceActorMemberSummaryDto.fromJson)
                    .toList(growable: false);
              }
              return <VoiceActorMemberSummaryDto>[];
            },
          );

      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<List<VoiceActorCreditSummary>>> getVoiceActorCredits({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.voiceActorCredits;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager
          .resolve<List<VoiceActorCreditSummaryDto>>(
            key: _voiceActorCreditsCacheKey(projectId, voiceActorId),
            policy: policy,
            ttl: profile.ttl,
            revalidateAfter: profile.revalidateAfter,
            fetcher: () => _fetchVoiceActorCredits(projectId, voiceActorId),
            toJson: (dtos) => {
              'items': dtos.map(_voiceActorCreditDtoToJson).toList(),
            },
            fromJson: (json) {
              final items = json['items'];
              if (items is List) {
                return items
                    .whereType<Map<String, dynamic>>()
                    .map(VoiceActorCreditSummaryDto.fromJson)
                    .toList(growable: false);
              }
              return <VoiceActorCreditSummaryDto>[];
            },
          );

      return Result.success(
        cacheResult.data
            .map((value) => value.toDomain())
            .toList(growable: false),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.mapException(e, stackTrace);
      return Result.failure(failure);
    }
  }

  Future<List<ProjectDto>> _fetchProjects() async {
    final result = await _remoteDataSource.fetchProjects();

    if (result is Success<List<ProjectDto>>) {
      return result.data;
    }
    if (result is Err<List<ProjectDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown projects result',
      code: 'unknown_projects',
    );
  }

  Future<List<UnitDto>> _fetchUnits(String projectId) async {
    final result = await _remoteDataSource.fetchUnits(projectId: projectId);

    if (result is Success<List<UnitDto>>) {
      return result.data;
    }
    if (result is Err<List<UnitDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure('Unknown units result', code: 'unknown_units');
  }

  Future<UnitDto> _fetchUnitDetail(
    String projectId,
    String unitIdentifier,
  ) async {
    final result = await _remoteDataSource.fetchUnitDetail(
      projectId: projectId,
      unitIdentifier: unitIdentifier,
    );
    if (result is Success<UnitDto>) {
      return result.data;
    }
    if (result is Err<UnitDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown unit detail result',
      code: 'unknown_unit_detail',
    );
  }

  Future<List<MemberDto>> _fetchUnitMembers(
    String projectId,
    String unitIdentifier,
  ) async {
    final result = await _remoteDataSource.fetchUnitMembers(
      projectId: projectId,
      unitIdentifier: unitIdentifier,
    );

    if (result is Success<List<MemberDto>>) {
      return result.data;
    }
    if (result is Err<List<MemberDto>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown members result',
      code: 'unknown_members',
    );
  }

  Future<MemberDto> _fetchUnitMemberDetail(
    String projectId,
    String unitIdentifier,
    String memberId,
  ) async {
    final result = await _remoteDataSource.fetchUnitMemberDetail(
      projectId: projectId,
      unitIdentifier: unitIdentifier,
      memberId: memberId,
    );

    if (result is Success<MemberDto>) {
      return result.data;
    }
    if (result is Err<MemberDto>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown member detail result',
      code: 'unknown_member_detail',
    );
  }

  Future<List<VoiceActorListItemDto>> _fetchVoiceActors(
    String projectId,
    String query,
    int page,
    int size,
    String? sort,
  ) async {
    final result = await _remoteDataSource.fetchVoiceActors(
      projectId: projectId,
      query: query,
      page: page,
      size: size,
      sort: sort,
    );
    if (result is Success<List<VoiceActorListItemDto>>) {
      return result.data;
    }
    if (result is Err<List<VoiceActorListItemDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown voice actor list result',
      code: 'unknown_voice_actor_list',
    );
  }

  Future<VoiceActorDetailDto> _fetchVoiceActorDetail(
    String projectId,
    String voiceActorId,
  ) async {
    final result = await _remoteDataSource.fetchVoiceActorDetail(
      projectId: projectId,
      voiceActorId: voiceActorId,
    );
    if (result is Success<VoiceActorDetailDto>) {
      return result.data;
    }
    if (result is Err<VoiceActorDetailDto>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown voice actor detail result',
      code: 'unknown_voice_actor_detail',
    );
  }

  Future<List<VoiceActorMemberSummaryDto>> _fetchVoiceActorMembers(
    String projectId,
    String voiceActorId,
  ) async {
    final result = await _remoteDataSource.fetchVoiceActorMembers(
      projectId: projectId,
      voiceActorId: voiceActorId,
    );
    if (result is Success<List<VoiceActorMemberSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<VoiceActorMemberSummaryDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown voice actor members result',
      code: 'unknown_voice_actor_members',
    );
  }

  Future<List<VoiceActorCreditSummaryDto>> _fetchVoiceActorCredits(
    String projectId,
    String voiceActorId,
  ) async {
    final result = await _remoteDataSource.fetchVoiceActorCredits(
      projectId: projectId,
      voiceActorId: voiceActorId,
    );
    if (result is Success<List<VoiceActorCreditSummaryDto>>) {
      return result.data;
    }
    if (result is Err<List<VoiceActorCreditSummaryDto>>) {
      throw result.failure;
    }
    throw const UnknownFailure(
      'Unknown voice actor credits result',
      code: 'unknown_voice_actor_credits',
    );
  }

  static const String _projectsCacheKey = 'projects_list';

  String _unitsCacheKey(String projectId) => 'project_units:$projectId';

  String _unitDetailCacheKey(String projectId, String unitIdentifier) =>
      'unit_detail:$projectId:$unitIdentifier';

  String _membersCacheKey(String projectId, String unitIdentifier) =>
      'unit_members:$projectId:$unitIdentifier';

  String _memberDetailCacheKey(
    String projectId,
    String unitIdentifier,
    String memberId,
  ) => 'unit_member_detail:$projectId:$unitIdentifier:$memberId';

  String _voiceActorsCacheKey(
    String projectId,
    String query,
    int page,
    int size,
    String? sort,
  ) => 'voice_actors:$projectId:q=$query:p=$page:s=$size:sort=${sort ?? ''}';

  String _voiceActorDetailCacheKey(String projectId, String voiceActorId) =>
      'voice_actor_detail:$projectId:$voiceActorId';

  String _voiceActorMembersCacheKey(String projectId, String voiceActorId) =>
      'voice_actor_members:$projectId:$voiceActorId';

  String _voiceActorCreditsCacheKey(String projectId, String voiceActorId) =>
      'voice_actor_credits:$projectId:$voiceActorId';
}

Map<String, dynamic> _voiceActorListDtoToJson(VoiceActorListItemDto dto) {
  return {
    'id': dto.id,
    'displayName': dto.displayName,
    if (dto.realName != null) 'realName': dto.realName,
    if (dto.stageName != null) 'stageName': dto.stageName,
    if (dto.agency != null) 'agency': dto.agency,
    if (dto.profileImageUrl != null) 'profileImageUrl': dto.profileImageUrl,
  };
}

Map<String, dynamic> _voiceActorDetailDtoToJson(VoiceActorDetailDto dto) {
  return {
    'id': dto.id,
    'displayName': dto.displayName,
    if (dto.realName != null) 'realName': dto.realName,
    if (dto.stageName != null) 'stageName': dto.stageName,
    if (dto.birthDate != null) 'birthDate': dto.birthDate,
    if (dto.agency != null) 'agency': dto.agency,
    if (dto.debutDate != null) 'debutDate': dto.debutDate,
    if (dto.bio != null) 'bio': dto.bio,
    if (dto.profileImageUrl != null) 'profileImageUrl': dto.profileImageUrl,
    if (dto.officialWebsite != null) 'officialWebsite': dto.officialWebsite,
    if (dto.twitterHandle != null) 'twitterHandle': dto.twitterHandle,
    if (dto.instagramHandle != null) 'instagramHandle': dto.instagramHandle,
    if (dto.createdAt != null) 'createdAt': dto.createdAt,
    if (dto.updatedAt != null) 'updatedAt': dto.updatedAt,
  };
}

Map<String, dynamic> _voiceActorMemberDtoToJson(
  VoiceActorMemberSummaryDto dto,
) {
  return {
    'memberId': dto.memberId,
    'unitId': dto.unitId,
    'unitSlug': dto.unitSlug,
    'unitName': dto.unitName,
    'characterName': dto.characterName,
    if (dto.characterImageUrl != null)
      'characterImageUrl': dto.characterImageUrl,
    if (dto.position != null) 'position': dto.position,
    if (dto.isLeader != null) 'isLeader': dto.isLeader,
    if (dto.roleType != null) 'roleType': dto.roleType,
    if (dto.rolePriority != null) 'rolePriority': dto.rolePriority,
    if (dto.startDate != null) 'startDate': dto.startDate,
    if (dto.endDate != null) 'endDate': dto.endDate,
  };
}

Map<String, dynamic> _voiceActorCreditDtoToJson(
  VoiceActorCreditSummaryDto dto,
) {
  return {
    'projectId': dto.projectId,
    'projectSlug': dto.projectSlug,
    'projectName': dto.projectName,
    'unitId': dto.unitId,
    'unitSlug': dto.unitSlug,
    'unitName': dto.unitName,
    'memberId': dto.memberId,
    'characterName': dto.characterName,
    if (dto.characterImageUrl != null)
      'characterImageUrl': dto.characterImageUrl,
    if (dto.position != null) 'position': dto.position,
    if (dto.isLeader != null) 'isLeader': dto.isLeader,
    if (dto.roleType != null) 'roleType': dto.roleType,
    if (dto.rolePriority != null) 'rolePriority': dto.rolePriority,
    if (dto.startDate != null) 'startDate': dto.startDate,
    if (dto.endDate != null) 'endDate': dto.endDate,
    if (dto.notes != null) 'notes': dto.notes,
  };
}
