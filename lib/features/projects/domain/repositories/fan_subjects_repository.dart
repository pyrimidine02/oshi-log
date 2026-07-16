/// EN: Repository contract for generalized fan-subject discovery and selection.
/// KO: 일반화된 팬 대상 탐색·선택 저장소 계약입니다.
library;

import '../../../../core/utils/result.dart';
import '../entities/fan_subject.dart';

abstract interface class FanSubjectsRepository {
  Future<Result<FanSubject>> getSubject(String identifier);

  Future<Result<List<FanSubject>>> getSubjects(FanSubjectQuery query);

  Future<Result<List<FanSubjectSubscription>>> getMySubjects();

  Future<Result<FanSubjectSubscription>> subscribe(String subjectId);

  Future<Result<void>> unsubscribe(String subjectId);
}
