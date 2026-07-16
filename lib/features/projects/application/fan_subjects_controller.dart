/// EN: Riverpod boundaries for generalized fandom subjects.
/// KO: 일반화된 팬 대상을 위한 Riverpod 경계입니다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/result.dart';
import '../data/datasources/fan_subjects_remote_data_source.dart';
import '../data/repositories/fan_subjects_repository_impl.dart';
import '../domain/entities/fan_subject.dart';
import '../domain/repositories/fan_subjects_repository.dart';

final fanSubjectsRepositoryProvider = Provider<FanSubjectsRepository>((ref) {
  return FanSubjectsRepositoryImpl(
    FanSubjectsRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final fanSubjectsProvider = FutureProvider.autoDispose
    .family<List<FanSubject>, FanSubjectQuery>((ref, query) async {
      final result = await ref
          .watch(fanSubjectsRepositoryProvider)
          .getSubjects(query);
      return switch (result) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };
    });

final fanSubjectDetailProvider = FutureProvider.autoDispose
    .family<FanSubject, String>((ref, identifier) async {
      final result = await ref
          .watch(fanSubjectsRepositoryProvider)
          .getSubject(identifier);
      return switch (result) {
        Success(:final data) => data,
        Err(:final failure) => throw failure,
      };
    });

final myFanSubjectsControllerProvider =
    StateNotifierProvider<
      MyFanSubjectsController,
      AsyncValue<List<FanSubjectSubscription>>
    >((ref) => MyFanSubjectsController(ref));

class MyFanSubjectsController
    extends StateNotifier<AsyncValue<List<FanSubjectSubscription>>> {
  MyFanSubjectsController(this._ref) : super(const AsyncLoading()) {
    unawaited(load());
  }

  final Ref _ref;

  Future<void> load() async {
    final result = await _ref
        .read(fanSubjectsRepositoryProvider)
        .getMySubjects();
    if (!mounted) return;
    state = switch (result) {
      Success(:final data) => AsyncData(data),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  Future<Result<void>> setSelected({
    required String subjectId,
    required bool selected,
  }) async {
    final repository = _ref.read(fanSubjectsRepositoryProvider);
    final result = selected
        ? (await repository.subscribe(subjectId)).map<void>((_) {})
        : await repository.unsubscribe(subjectId);
    if (result is Success<void>) {
      await load();
    }
    return result;
  }
}

Failure? fanSubjectSelectionFailure(
  AsyncValue<List<FanSubjectSubscription>> value,
) {
  final error = value.error;
  return error is Failure ? error : null;
}
