/// EN: Projects repository interface.
/// KO: 프로젝트 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import '../entities/project_entities.dart';

abstract class ProjectsRepository {
  Future<Result<List<Project>>> getProjects({bool forceRefresh = false});

  Future<Result<List<Unit>>> getUnits({
    required String projectId,
    bool forceRefresh = false,
  });

  Future<Result<Unit>> getUnitDetail({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  });

  /// EN: Returns members for a given unit, including voice actor info.
  /// KO: 주어진 유닛의 멤버 목록(성우 정보 포함)을 반환합니다.
  Future<Result<List<UnitMember>>> getUnitMembers({
    required String projectId,
    required String unitIdentifier,
    bool forceRefresh = false,
  });

  Future<Result<UnitMember>> getUnitMemberDetail({
    required String projectId,
    required String unitIdentifier,
    required String memberId,
    bool forceRefresh = false,
  });

  Future<Result<List<VoiceActorListItem>>> searchVoiceActors({
    required String projectId,
    String query = '',
    int page = 0,
    int size = 20,
    String? sort,
    bool forceRefresh = false,
  });

  Future<Result<VoiceActorDetail>> getVoiceActorDetail({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  });

  Future<Result<List<VoiceActorMemberSummary>>> getVoiceActorMembers({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  });

  Future<Result<List<VoiceActorCreditSummary>>> getVoiceActorCredits({
    required String projectId,
    required String voiceActorId,
    bool forceRefresh = false,
  });
}
