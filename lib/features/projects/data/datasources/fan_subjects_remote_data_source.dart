/// EN: Remote data source for generalized fan subjects.
/// KO: 일반화된 팬 대상 원격 데이터 소스입니다.
library;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/fan_subject.dart';
import '../dto/fan_subject_dto.dart';

class FanSubjectsRemoteDataSource {
  const FanSubjectsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Result<FanSubjectDto>> fetchSubject(String identifier) {
    return _apiClient.get<FanSubjectDto>(
      ApiEndpoints.fanSubject(identifier.trim()),
      fromJson: (json) => FanSubjectDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<List<FanSubjectDto>>> fetchSubjects(FanSubjectQuery query) {
    return _apiClient.get<List<FanSubjectDto>>(
      ApiEndpoints.fanSubjects,
      queryParameters: {
        if (query.kind != null && query.kind != FanSubjectKind.unknown)
          'type': query.kind!.wireName,
        if (_hasText(query.scopeSubjectId))
          'scopeSubjectId': query.scopeSubjectId!.trim(),
        if (_hasText(query.parentSubjectId))
          'parentSubjectId': query.parentSubjectId!.trim(),
        if (_hasText(query.projectId)) 'projectId': query.projectId!.trim(),
        if (_hasText(query.query)) 'q': query.query!.trim(),
        'page': query.page.coerceAtLeast(0),
        'size': query.size.clamp(1, 100),
      },
      fromJson: (json) => _decodeList(json, FanSubjectDto.fromJson),
    );
  }

  Future<Result<List<FanSubjectSubscriptionDto>>> fetchMySubjects() {
    return _apiClient.get<List<FanSubjectSubscriptionDto>>(
      ApiEndpoints.myFanSubjects,
      queryParameters: const {'size': 100},
      fromJson: (json) => _decodeList(json, FanSubjectSubscriptionDto.fromJson),
    );
  }

  Future<Result<FanSubjectSubscriptionDto>> subscribe(String subjectId) {
    return _apiClient.put<FanSubjectSubscriptionDto>(
      ApiEndpoints.myFanSubject(subjectId),
      fromJson: (json) =>
          FanSubjectSubscriptionDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Result<void>> unsubscribe(String subjectId) {
    return _apiClient.delete<void>(
      ApiEndpoints.myFanSubject(subjectId),
      fromJson: (_) {},
    );
  }
}

List<T> _decodeList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final source = json is List
      ? json
      : json is Map<String, dynamic>
      ? json['items'] ?? json['content'] ?? json['data']
      : null;
  if (source is! List) return <T>[];
  return source
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

extension on int {
  int coerceAtLeast(int minimum) => this < minimum ? minimum : this;
}
