/// EN: Maps the fan-subject wire contract into immutable domain objects.
/// KO: 팬 대상 전송 계약을 불변 도메인 객체로 변환합니다.
library;

import '../../../../core/utils/result.dart';
import '../../domain/entities/fan_subject.dart';
import '../../domain/repositories/fan_subjects_repository.dart';
import '../datasources/fan_subjects_remote_data_source.dart';

class FanSubjectsRepositoryImpl implements FanSubjectsRepository {
  const FanSubjectsRepositoryImpl(this._remoteDataSource);

  final FanSubjectsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<FanSubject>> getSubject(String identifier) async {
    final result = await _remoteDataSource.fetchSubject(identifier);
    return result.map(FanSubject.fromDto);
  }

  @override
  Future<Result<List<FanSubject>>> getSubjects(FanSubjectQuery query) async {
    final result = await _remoteDataSource.fetchSubjects(query);
    return result.map(
      (items) => items.map(FanSubject.fromDto).toList(growable: false),
    );
  }

  @override
  Future<Result<List<FanSubjectSubscription>>> getMySubjects() async {
    final result = await _remoteDataSource.fetchMySubjects();
    return result.map(
      (items) =>
          items.map(FanSubjectSubscription.fromDto).toList(growable: false),
    );
  }

  @override
  Future<Result<FanSubjectSubscription>> subscribe(String subjectId) async {
    final result = await _remoteDataSource.subscribe(subjectId);
    return result.map(FanSubjectSubscription.fromDto);
  }

  @override
  Future<Result<void>> unsubscribe(String subjectId) {
    return _remoteDataSource.unsubscribe(subjectId);
  }
}
